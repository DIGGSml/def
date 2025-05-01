/**
 * DIGGS CodeSpace Validator JavaScript - Modular Architecture
 * 
 * This file contains all the JavaScript functionality for the DIGGS CodeSpace Validator.
 * It uses a modular architecture to separate concerns and make adding new validation
 * rules easier.
 */

// ====================================
// Module: Core Application
// ====================================
const DiggsCoreApp = (function() {
    // Private variables
    let xmlFileContent = null;
    let xmlDoc = null;
    
    // Initialize the application
    function init() {
        // Set up event listeners
        document.getElementById('file-upload').addEventListener('change', handleFileSelected);
        document.getElementById('validate-button').addEventListener('click', validateXML);
        document.getElementById('level-filter').addEventListener('change', UIManager.filterResults);
        document.getElementById('debug-toggle').addEventListener('change', UIManager.toggleDebug);
        document.getElementById('export-csv').addEventListener('click', function() { UIManager.exportResults('csv'); });
        document.getElementById('export-html').addEventListener('click', function() { UIManager.exportResults('html'); });
        
        // Set up drag and drop functionality
        setupDragAndDrop();
    }
    
    // Handle file selection
    function handleFileSelected() {
        const fileInput = document.getElementById('file-upload');
        const filenameDisplay = document.getElementById('filename-display');
        const validateButton = document.getElementById('validate-button');
        
        if (fileInput.files.length > 0) {
            const file = fileInput.files[0];
            filenameDisplay.textContent = `Selected file: ${file.name}`;
            validateButton.style.display = 'block';
            
            // Read the file
            const reader = new FileReader();
            reader.onload = function (e) {
                xmlFileContent = e.target.result;
                
                // Pre-parse the XML to store as a DOM
                try {
                    const parser = new DOMParser();
                    xmlDoc = parser.parseFromString(xmlFileContent, 'text/xml');
                    
                    // Check for parsing errors
                    if (xmlDoc.getElementsByTagName('parsererror').length > 0) {
                        console.warn("XML parsing warning - will try again during validation");
                    }
                } catch (error) {
                    console.warn("XML pre-parsing warning:", error);
                }
            };
            reader.readAsText(file);
        } else {
            filenameDisplay.textContent = '';
            validateButton.style.display = 'none';
            xmlFileContent = null;
            xmlDoc = null;
        }
    }
    
    // Set up drag and drop functionality
    function setupDragAndDrop() {
        const dropZone = document.querySelector('.upload-container');
        
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.style.backgroundColor = '#e3f2fd';
        });
        
        dropZone.addEventListener('dragleave', () => {
            dropZone.style.backgroundColor = '#f8f9fa';
        });
        
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.style.backgroundColor = '#f8f9fa';
            
            const fileInput = document.getElementById('file-upload');
            fileInput.files = e.dataTransfer.files;
            handleFileSelected();
        });
    }
    
    // Validate XML
    function validateXML() {
        if (!xmlFileContent) {
            UIManager.showError('Please select an XML file first');
            return;
        }
        
        // Show loading spinner
        UIManager.showLoading();
        
        try {
            // Parse the XML
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(xmlFileContent, 'text/xml');
            
            // Check for XML parsing errors
            if (xmlDoc.getElementsByTagName('parsererror').length > 0) {
                throw new Error('XML parsing error: Invalid XML format');
            }
            
            // Initialize the validation context
            const validationContext = {
                xmlDoc: xmlDoc,
                validationResults: [],
                validationPromises: []
            };
            
            // Execute validators in the validation pipeline
            ValidationManager.runValidators(validationContext)
                .then(results => {
                    // Process the results
                    UIManager.showResults(results);
                })
                .catch(error => {
                    UIManager.showError(`Validation error: ${error.message}`);
                });
        } catch (error) {
            UIManager.showError(`Validation error: ${error.message}`);
        }
    }
    
    // Public API
    return {
        init: init
    };
})();

// ====================================
// Module: UI Manager
// ====================================
const UIManager = (function() {
    // Show loading state
    function showLoading() {
        document.getElementById('loading').style.display = 'block';
        document.getElementById('error-message').style.display = 'none';
        document.getElementById('validation-results').style.display = 'none';
    }
    
    // Show error message
    function showError(message) {
        document.getElementById('loading').style.display = 'none';
        document.getElementById('error-message').textContent = message;
        document.getElementById('error-message').style.display = 'block';
        console.error(message);
    }
    
    // Show validation results
    function showResults(results) {
        // Clear previous results
        const resultsBody = document.getElementById('results-body');
        resultsBody.innerHTML = '';
        
        // Add results to table
        results.forEach(result => {
            const row = document.createElement('tr');
            row.className = result.level.toLowerCase();
            
            // Create cells
            row.innerHTML = `
                <td><span class="severity-badge ${result.level.toLowerCase()}">${result.severity}</span></td>
                <td>${result.message}</td>
                <td class="line-number">${result.lineNumber}</td>
                <td><pre class="source-xml">${Utils.escapeHtml(result.sourceXml)}</pre></td>
            `;
            
            resultsBody.appendChild(row);
        });
        
        // Show results and update summary
        document.getElementById('validation-results').style.display = 'block';
        document.getElementById('loading').style.display = 'none';
        updateSummary();
    }
    
    // Filter results by severity level
    function filterResults() {
        const levelFilter = document.getElementById('level-filter').value;
        const rows = document.querySelectorAll('#results-body tr');
        
        // Apply filters
        if (levelFilter === 'all') {
            rows.forEach(row => {
                if (!row.classList.contains('debug') || document.getElementById('debug-toggle').checked) {
                    row.style.display = '';
                }
            });
        } else {
            rows.forEach(row => {
                if (row.classList.contains(levelFilter)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }
        
        // Update summary
        updateSummary();
    }
    
    // Toggle display of debug information
    function toggleDebug() {
        const debugToggle = document.getElementById('debug-toggle');
        const debugRows = document.querySelectorAll('#results-body tr.debug');
        
        // Apply toggle
        debugRows.forEach(row => {
            row.style.display = debugToggle.checked ? '' : 'none';
        });
        
        // Update summary
        updateSummary();
    }
    
    // Update validation summary counts
    function updateSummary() {
        const errors = document.querySelectorAll('#results-body tr.error:not([style*="display: none"])').length;
        const warnings = document.querySelectorAll('#results-body tr.warning:not([style*="display: none"])').length;
        const infos = document.querySelectorAll('#results-body tr.info:not([style*="display: none"])').length;
        const debugs = document.querySelectorAll('#results-body tr.debug:not([style*="display: none"])').length;
        
        const summary = `Found ${errors} errors, ${warnings} warnings, ${infos} information messages${debugs > 0 ? ` and ${debugs} debug messages` : ''}.`;
        document.getElementById('summary-text').textContent = summary;
    }
    
    // Export validation results
    function exportResults(format) {
        const results = collectResults();
        
        if (format === 'csv') {
            exportAsCsv(results);
        } else if (format === 'html') {
            exportAsHtml(results);
        }
    }
    
    // Export as CSV
    function exportAsCsv(results) {
        // Create CSV content
        let csvContent = "Severity,Message,Line,Source XML\n";
        results.forEach(result => {
            const severity = result.severity.trim();
            const message = result.message.trim().replace(/"/g, '""');
            const lineNumber = result.lineNumber.trim();
            const sourceXml = result.sourceXml.trim().replace(/"/g, '""');
            
            csvContent += `"${severity}","${message}","${lineNumber}","${sourceXml}"\n`;
        });
        
        // Download CSV file
        Utils.downloadFile(csvContent, 'validation-results.csv', 'text/csv');
    }
    
    // Export as HTML
    function exportAsHtml(results) {
        // Create HTML content
        const tableRows = results.map(result => {
            return `<tr class="${result.level.toLowerCase()}">
                <td><span class="severity-badge ${result.level.toLowerCase()}">${result.severity}</span></td>
                <td>${result.message}</td>
                <td>${result.lineNumber}</td>
                <td><pre class="source-xml">${Utils.escapeHtml(result.sourceXml)}</pre></td>
            </tr>`;
        }).join('');
        
        const htmlContent = `
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>DIGGS CodeSpace Validation Report</title>
                <link rel="stylesheet" href="https://diggsml.org/def/stylesheets/cs_validator.css">
                <style>
                    .source-xml {
                        font-family: monospace;
                        white-space: pre-wrap;
                        word-break: break-all;
                        background-color: #f5f5f5;
                        padding: 8px;
                        border-radius: 4px;
                        margin: 0;
                        max-width: 600px;
                    }
                    .severity-badge {
                        display: inline-block;
                        padding: 4px 8px;
                        border-radius: 4px;
                        font-weight: bold;
                        color: white;
                    }
                    .severity-badge.error {
                        background-color: #e74c3c;
                    }
                    .severity-badge.warning {
                        background-color: #f39c12;
                    }
                    .severity-badge.info {
                        background-color: #3498db;
                    }
                    .severity-badge.debug {
                        background-color: #7f8c8d;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>DIGGS CodeSpace Validation Report</h1>
                    <div class="validation-summary">
                        <p><strong>Summary:</strong> ${document.getElementById('summary-text').textContent}</p>
                        <p><strong>Generated:</strong> ${new Date().toLocaleString()}</p>
                    </div>
                    <table>
                        <thead>
                            <tr class="header-row">
                                <th>Severity</th>
                                <th>Message</th>
                                <th>Line #</th>
                                <th>Source XML</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${tableRows}
                        </tbody>
                    </table>
                </div>
            </body>
            </html>
        `;
        
        // Download HTML file
        Utils.downloadFile(htmlContent, 'validation-report.html', 'text/html');
    }
    
    // Collect visible results
    function collectResults() {
        const results = [];
        const rows = document.querySelectorAll('#results-body tr:not([style*="display: none"])');
        
        rows.forEach(row => {
            const cells = row.querySelectorAll('td');
            if (cells.length >= 4) {
                results.push({
                    severity: cells[0].textContent,
                    message: cells[1].textContent,
                    lineNumber: cells[2].textContent,
                    sourceXml: cells[3].textContent,
                    level: row.className
                });
            }
        });
        
        return results;
    }
    
    // Public API
    return {
        showLoading: showLoading,
        showError: showError,
        showResults: showResults,
        filterResults: filterResults,
        toggleDebug: toggleDebug,
        exportResults: exportResults
    };
})();

// ====================================
// Module: Validation Manager
// ====================================
const ValidationManager = (function() {
    // Dictionary cache
    const dictionaryCache = {};
    
    // Validation pipeline - add new validators here
    const validators = [
        validateCodeSpaceElements
    ];
    
    // Run all validators
    async function runValidators(context) {
        // Find elements to validate
        const elementsWithCodeSpace = context.xmlDoc.querySelectorAll('*[codeSpace]');
        console.log(`Found ${elementsWithCodeSpace.length} elements with codeSpace attributes`);
        
        if (elementsWithCodeSpace.length === 0) {
            // No elements to validate
            return [{
                lineNumber: 'N/A',
                elementPath: '',
                value: '',
                codeSpace: '',
                level: 'INFO',
                severity: 'Information',
                sourceXml: '',
                message: 'No elements with codeSpace attributes were found for validation.'
            }];
        }
        
        // Process each element
        for (const validator of validators) {
            await validator(context, elementsWithCodeSpace);
        }
        
        // Wait for all promises to complete
        if (context.validationPromises.length > 0) {
            const promiseResults = await Promise.all(context.validationPromises);
            // Flatten and add promise results to validationResults
            promiseResults.flat().forEach(result => {
                context.validationResults.push(result);
            });
        }
        
        return context.validationResults;
    }
    
    // Validator: CodeSpace Elements
    async function validateCodeSpaceElements(context, elementsWithCodeSpace) {
        // Process each element with codeSpace attribute
        elementsWithCodeSpace.forEach((element, index) => {
            const elementName = element.localName;
            const elementValue = element.textContent.trim();
            const codeSpace = element.getAttribute('codeSpace');
            
            // Approximate line number (not accurate, but helpful for reporting)
            const lineNumber = index + 1;
            
            // Build simplified element path
            const elementPath = Utils.buildElementPath(element, context.xmlDoc);
            
            // Get serialized XML for the current element
            const sourceXml = Utils.getElementOuterXML(element);
            
            // Validation logic: check URL format
            if (!codeSpace.includes('#')) {
                context.validationResults.push({
                    lineNumber: String(lineNumber),
                    elementPath: elementPath,
                    value: elementValue,
                    codeSpace: codeSpace,
                    level: 'INFO',
                    severity: 'Information',
                    sourceXml: sourceXml,
                    message: `The value of ${elementName} cannot be validated. If codeSpace attribute '${codeSpace}' references an authority, be sure that the value '${elementValue}' is a valid term controlled by '${codeSpace}'`
                });
            } else {
                // Extract dictionary URL and fragment
                const dictionaryUrl = codeSpace.split('#')[0];
                const fragmentId = codeSpace.split('#')[1];
                
                // Create a promise to fetch and validate against the dictionary
                const validationPromise = validateAgainstDictionary(
                    dictionaryUrl, 
                    fragmentId, 
                    elementName, 
                    elementValue, 
                    codeSpace, 
                    lineNumber, 
                    elementPath, 
                    sourceXml
                );
                
                context.validationPromises.push(validationPromise);
            }
        });
    }
    
    // Validate against a dictionary
    async function validateAgainstDictionary(dictionaryUrl, fragmentId, elementName, elementValue, codeSpace, lineNumber, elementPath, sourceXml) {
        const results = [];
        
        try {
            // Try to fetch the dictionary if not already in cache
            let dictionaryDoc = await fetchDictionary(dictionaryUrl);
            
            // Check if the document is a dictionary
            const dictionaries = dictionaryDoc.getElementsByTagName('Dictionary');
            if (dictionaries.length === 0) {
                results.push({
                    lineNumber: String(lineNumber),
                    elementPath: elementPath,
                    value: elementValue,
                    codeSpace: codeSpace,
                    level: 'WARNING',
                    severity: 'Warning',
                    sourceXml: sourceXml,
                    message: `The resource at '${dictionaryUrl}' is not a valid DIGGS dictionary. If this value is intended to reference an authority rather than a DIGGS dictionary, be sure that the value '${elementValue}' is a valid term controlled by '${codeSpace}'`
                });
                return results;
            }
            
            // Find the definition with the specified ID
            const definitions = Array.from(dictionaryDoc.getElementsByTagName('Definition'));
            const definition = definitions.find(def => def.getAttribute('id') === fragmentId);
            
            if (!definition) {
                results.push({
                    lineNumber: String(lineNumber),
                    elementPath: elementPath,
                    value: elementValue,
                    codeSpace: codeSpace,
                    level: 'ERROR',
                    severity: 'Error',
                    sourceXml: sourceXml,
                    message: `No Definition with id='${fragmentId}' found in the dictionary at '${dictionaryUrl}'.`
                });
                return results;
            }
            
            // Check if the definition contains sourceElementXpath elements
            const sourceElementXpaths = Array.from(definition.getElementsByTagName('sourceElementXpath'));
            
            if (sourceElementXpaths.length > 0) {
                // Check if any of the sourceElementXpaths match the current element path
                const hasMatchingPath = sourceElementXpaths.some(xpath => {
                    const xpathValue = xpath.textContent.trim();
                    
                    // Handle simplified XPath matching
                    if (xpathValue.startsWith('//')) {
                        const pathElement = xpathValue.substring(2);
                        return elementPath.includes(`/${pathElement}`) || 
                               elementPath.endsWith(`/${pathElement}`);
                    }
                    
                    return false;
                });
                
                if (!hasMatchingPath) {
                    results.push({
                        lineNumber: String(lineNumber),
                        elementPath: elementPath,
                        value: elementValue,
                        codeSpace: codeSpace,
                        level: 'ERROR',
                        severity: 'Error',
                        sourceXml: sourceXml,
                        message: `The element ${elementName} with value '${elementValue}' references a definition that is not allowed at this location in the XML instance. Current path: '${elementPath}'`
                    });
                    return results;
                }
            }
            
            // Check if the definition contains name elements
            const nameElements = Array.from(definition.getElementsByTagName('name'));
            
            if (nameElements.length > 0) {
                // Check if any of the names match the current value (case-insensitive)
                const currentValueLower = elementValue.toLowerCase();
                const hasNameMatch = nameElements.some(name => 
                    name.textContent.trim().toLowerCase() === currentValueLower
                );
                
                if (!hasNameMatch) {
                    results.push({
                        lineNumber: String(lineNumber),
                        elementPath: elementPath,
                        value: elementValue,
                        codeSpace: codeSpace,
                        level: 'WARNING',
                        severity: 'Warning',
                        sourceXml: sourceXml,
                        message: `The value '${elementValue}' in element ${elementName} is a name that does not match the names in the referenced Definition. Be sure that '${elementValue}' is a synonymous name.`
                    });
                    return results;
                }
            }
            
            // If we get here, the validation passed
            results.push({
                lineNumber: String(lineNumber),
                elementPath: elementPath,
                value: elementValue,
                codeSpace: codeSpace,
                level: 'DEBUG',
                severity: 'Debug',
                sourceXml: sourceXml,
                message: `Successfully validated element at path '${elementPath}'`
            });
            
        } catch (error) {
            console.error(`Error validating against dictionary: ${error.message}`);
            results.push({
                lineNumber: String(lineNumber),
                elementPath: elementPath,
                value: elementValue,
                codeSpace: codeSpace,
                level: 'ERROR',
                severity: 'Error',
                sourceXml: sourceXml,
                message: `Error validating against dictionary: ${error.message}`
            });
        }
        
        return results;
    }
    
    // Fetch and cache dictionary
    async function fetchDictionary(dictionaryUrl) {
        // Try to fetch the dictionary if not already in cache
        if (dictionaryCache[dictionaryUrl]) {
            console.log(`Using cached dictionary: ${dictionaryUrl}`);
            return dictionaryCache[dictionaryUrl];
        }
        
        console.log(`Fetching dictionary: ${dictionaryUrl}`);
        
        try {
            const response = await fetch(dictionaryUrl, {
                method: 'GET',
                headers: {
                    'Accept': 'application/xml, text/xml, */*',
                },
                mode: 'cors',
                cache: 'force-cache'
            });
            
            if (!response.ok) {
                throw new Error(`Failed to fetch dictionary: ${response.status} ${response.statusText}`);
            }
            
            const xmlText = await response.text();
            const parser = new DOMParser();
            const dictionaryDoc = parser.parseFromString(xmlText, 'text/xml');
            
            // Check for XML parsing errors
            if (dictionaryDoc.getElementsByTagName('parsererror').length > 0) {
                throw new Error('XML parsing error in dictionary');
            }
            
            // Cache the parsed dictionary
            dictionaryCache[dictionaryUrl] = dictionaryDoc;
            return dictionaryDoc;
        } catch (error) {
            throw new Error(`Dictionary fetch error: ${error.message}`);
        }
    }
    
    // Public API
    return {
        runValidators: runValidators,
        // Export these for test purposes or custom validation implementation
        validators: validators,
        fetchDictionary: fetchDictionary
    };
})();

// ====================================
// Module: Utilities
// ====================================
const Utils = (function() {
    // Escape HTML special characters
    function escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }
    
    // Download a file
    function downloadFile(content, filename, contentType) {
        const blob = new Blob([content], { type: contentType });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        setTimeout(() => {
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }, 100);
    }
    
    // Get namespace prefix for a given namespace URI
    function getNamespacePrefix(namespaceURI) {
        if (!namespaceURI) return '';
        
        const prefixMap = {
            'http://diggsml.org/schema-dev': 'diggs',
            'http://www.opengis.net/gml/3.2': 'gml',
            'http://www.opengis.net/gml/3.3/ce': 'g3',
            'http://www.opengis.net/gml/3.3/lr': 'glr',
            'http://www.opengis.net/gml/3.3/lrov': 'glrov'
        };
        
        return prefixMap[namespaceURI] || '';
    }
    
    // Build element path
    function buildElementPath(element, xmlDoc) {
        let elementPath = '';
        let node = element;
        
        while (node && node !== xmlDoc) {
            const prefix = getNamespacePrefix(node.namespaceURI);
            elementPath = `/${prefix ? prefix + ':' : ''}${node.localName}${elementPath}`;
            node = node.parentNode;
        }
        
        return elementPath;
    }
    
    // Get serialized XML for an element
    function getElementOuterXML(element) {
        const serializer = new XMLSerializer();
        return serializer.serializeToString(element);
    }
    
    // Public API
    return {
        escapeHtml: escapeHtml,
        downloadFile: downloadFile,
        getNamespacePrefix: getNamespacePrefix,
        buildElementPath: buildElementPath,
        getElementOuterXML: getElementOuterXML
    };
})();

// ====================================
// Extension: Sample Custom Validator
// ====================================

// Here's an example of how to add a new validator to the validation pipeline
// Uncomment and modify this to implement your custom validation logic

/*
// Custom validator for empty element values
async function validateEmptyValues(context, elementsWithCodeSpace) {
    elementsWithCodeSpace.forEach((element, index) => {
        const elementName = element.localName;
        const elementValue = element.textContent.trim();
        
        // Skip elements that already have validation results
        const hasExistingValidation = context.validationResults.some(result => 
            result.sourceXml === Utils.getElementOuterXML(element)
        );
        
        if (!hasExistingValidation && elementValue === '') {
            const lineNumber = index + 1;
            const elementPath = Utils.buildElementPath(element, context.xmlDoc);
            const sourceXml = Utils.getElementOuterXML(element);
            const codeSpace = element.getAttribute('codeSpace');
            
            context.validationResults.push({
                lineNumber: String(lineNumber),
                elementPath: elementPath,
                value: elementValue,
                codeSpace: codeSpace,
                level: 'ERROR',
                severity: 'Error',
                sourceXml: sourceXml,
                message: `Empty value found in element ${elementName}.`
            });
        }
    });
}

// Add the custom validator to the validation pipeline
ValidationManager.validators.push(validateEmptyValues);
*/

// Initialize the application when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    DiggsCoreApp.init();
});