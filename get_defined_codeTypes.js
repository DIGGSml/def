// get_defined_codeTypes.js - Simplified version using only JavaScript (no XSLT)
const fs = require('fs').promises;
const path = require('path');
const axios = require('axios');
const { DOMParser } = require('xmldom');

// Configuration
const GITHUB_API_URL = 'https://api.github.com/repos/diggsml/def/contents/docs/codes/DIGGS/0.1';
const BASE_DICTIONARY_URL = 'https://diggsml.org/def/codes/DIGGS/0.1/';
const OUTPUT_FILE = 'docs/validation/definedCodeTypes.xml';

// Fetch the list of dictionary files from GitHub
async function fetchDictionaryFilesList() {
    try {
        console.log('Fetching dictionary files list from GitHub...');
        const response = await axios.get(GITHUB_API_URL, {
            headers: { 'User-Agent': 'DIGGS-Dictionary-Processor' }
        });
        
        // Extract XML file names
        const xmlFiles = response.data
            .filter(item => item.type === 'file' && item.name.endsWith('.xml'))
            .map(item => item.name);
        
        console.log(`Found ${xmlFiles.length} XML dictionary files`);
        return xmlFiles;
    } catch (error) {
        console.error('Error fetching dictionary files list:', error.message);
        throw error;
    }
}

// Function to convert ID to XPath (same logic as the original XSLT function)
function constructXPath(id) {
    if (!id.includes('_')) {
        // Simple case: just a single element name
        return `//*[local-name() = '${id}']`;
    } else {
        // Complex case: path with segments
        const segments = id.split('_');
        return segments.map(segment => 
            `/*[local-name() = '${segment}']`
        ).join('');
    }
}

// Process a single dictionary file
async function processDictionaryFile(fileName) {
    const fileUrl = `${BASE_DICTIONARY_URL}${fileName}`;
    try {
        console.log(`Processing ${fileUrl}...`);
        const response = await axios.get(fileUrl, {
            headers: { 'User-Agent': 'DIGGS-Dictionary-Processor' },
            responseType: 'text'
        });
        
        // Parse the XML
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(response.data, 'text/xml');
        
        // Find Dictionary element by examining all elements and checking local name
        const allElements = xmlDoc.getElementsByTagName('*');
        let dictionaryElement = null;
        
        for (let i = 0; i < allElements.length; i++) {
            const element = allElements[i];
            const nodeName = element.nodeName;
            
            // Get the local name (part after colon if present)
            const localName = nodeName.includes(':') 
                ? nodeName.split(':').pop() 
                : nodeName;
                
            if (localName === 'Dictionary') {
                dictionaryElement = element;
                break;
            }
        }
        
        if (!dictionaryElement) {
            console.log(`No Dictionary element found in ${fileName}`);
            return null;
        }
        
        // Get id attribute - also handling namespace prefixes on attributes if necessary
        let dictId = null;
        
        // First try without namespace
        dictId = dictionaryElement.getAttribute('id');
        
        // If not found, try with all attributes to find one ending with "id"
        if (!dictId) {
            for (let i = 0; i < dictionaryElement.attributes.length; i++) {
                const attr = dictionaryElement.attributes[i];
                const attrName = attr.name;
                const localAttrName = attrName.includes(':') 
                    ? attrName.split(':').pop() 
                    : attrName;
                    
                if (localAttrName === 'id') {
                    dictId = attr.value;
                    break;
                }
            }
        }
        
        if (!dictId) {
            console.log(`No id attribute found on Dictionary element in ${fileName}`);
            return null;
        }
        
        return {
            id: dictId,
            xpath: constructXPath(dictId),
            url: fileUrl
        };
    } catch (error) {
        console.error(`Error processing ${fileUrl}:`, error.message);
        return null;
    }
}

// Process all dictionary files and generate the output XML
async function processAllDictionaries() {
    try {
        // Get the list of dictionary files
        const xmlFiles = await fetchDictionaryFilesList();
        
        // Process each file to extract dictionary information
        const dictionaries = [];
        for (const fileName of xmlFiles) {
            const result = await processDictionaryFile(fileName);
            if (result) {
                dictionaries.push(result);
            }
        }
        
        console.log(`Successfully processed ${dictionaries.length} dictionaries`);
        
        // Group dictionaries by ID
        const groupedDictionaries = {};
        for (const dict of dictionaries) {
            if (!groupedDictionaries[dict.id]) {
                groupedDictionaries[dict.id] = {
                    xpath: dict.xpath,
                    dictionaryURLs: []
                };
            }
            groupedDictionaries[dict.id].dictionaryURLs.push(dict.url);
        }
        
        // Generate the output XML
        let outputXml = '<?xml version="1.0" encoding="UTF-8"?>\n<codeTypeElements>\n';
        
        for (const id in groupedDictionaries) {
            const group = groupedDictionaries[id];
            outputXml += `  <codeType>\n`;
            outputXml += `    <xpath>${group.xpath}</xpath>\n`;
            
            for (const url of group.dictionaryURLs) {
                outputXml += `    <dictionaryURL>${url}</dictionaryURL>\n`;
            }
            
            outputXml += `  </codeType>\n`;
        }
        
        outputXml += '</codeTypeElements>';
        
        // Ensure the output directory exists
        const outputDir = path.dirname(OUTPUT_FILE);
        await fs.mkdir(outputDir, { recursive: true }).catch(() => {});
        
        // Write the output file
        await fs.writeFile(OUTPUT_FILE, outputXml);
        console.log(`Output written to ${OUTPUT_FILE}`);
        
        return dictionaries.length;
    } catch (error) {
        console.error('Error processing dictionaries:', error);
        throw error;
    }
}

// Main function
async function main() {
    try {
        console.log('Starting Get Defined CodeTypes (JavaScript-only Approach)...');
        
        const processedCount = await processAllDictionaries();
        
        console.log(`Processing complete! Processed ${processedCount} dictionaries.`);
    } catch (error) {
        console.error('An error occurred during processing:', error);
        process.exit(1);
    }
}

// Run the application
main();