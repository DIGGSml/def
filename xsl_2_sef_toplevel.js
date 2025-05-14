// xsl_to_sef_toplevel.js - Compile XSL to SEF files in top level directory only

const fs = require('fs');
const path = require('path');
const { execSync, exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// Configuration
const INPUT_DIR = '/workspaces/def/docs/validation';
const OUTPUT_DIR = '/workspaces/def/docs/validation';
const LOG_FILE = path.join(OUTPUT_DIR, 'compilation_log.txt');
const SAXON_DIR = path.join(process.cwd(), 'saxon');
const XSLT3_BIN = path.join(SAXON_DIR, 'node_modules', '.bin', 'xslt3-he');

// Verify Saxon installation
try {
    if (!fs.existsSync(XSLT3_BIN)) {
        console.error(`SaxonJS XSLT3 tool not found at ${XSLT3_BIN}`);
        console.error('Please ensure you have installed SaxonJS 3 packages first.');
        process.exit(1);
    }
} catch (error) {
    console.error('Error verifying SaxonJS installation:', error.message);
    process.exit(1);
}

// Create output directory if it doesn't exist
console.log(`Creating output directory at ${OUTPUT_DIR}...`);
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Initialize log file
const logHeader = `XSL to SEF Compilation Log (Top Level Only)
Run Date: ${new Date().toISOString()}
----------------------------------------

`;
fs.writeFileSync(LOG_FILE, logHeader);

// Function to find XSL files in top level directory only
function findTopLevelXslFiles(dir) {
    const results = [];
    
    try {
        const files = fs.readdirSync(dir);
        
        for (const file of files) {
            const filePath = path.join(dir, file);
            const stat = fs.statSync(filePath);
            
            if (!stat.isDirectory() && (file.endsWith('.xsl') || file.endsWith('.xslt'))) {
                results.push(filePath);
            }
        }
    } catch (error) {
        console.error(`Error reading directory ${dir}:`, error.message);
    }
    
    return results;
}

// Process an XSL file
async function processXslFile(xslFile) {
    const fileName = path.basename(xslFile);
    const sefName = fileName.replace(/\.xslt?$/, '.sef.json');
    const outputFile = path.join(OUTPUT_DIR, sefName);
    
    console.log(`Processing: ${fileName}`);
    fs.appendFileSync(LOG_FILE, `Processing: ${fileName}\n`);
    
    try {
        // Run the xslt3-he command to compile the XSL file to SEF
        const { stdout, stderr } = await execAsync(
            `"${XSLT3_BIN}" -xsl:"${xslFile}" -export:"${outputFile}" -t -nogo`
        );
        
        // Log any output
        if (stdout) {
            fs.appendFileSync(LOG_FILE, `Command output: ${stdout}\n`);
        }
        
        // Check if compilation was successful
        if (fs.existsSync(outputFile)) {
            console.log(`✓ Successfully compiled to ${outputFile}`);
            fs.appendFileSync(LOG_FILE, `✓ Successfully compiled to ${outputFile}\n\n`);
            return true;
        } else {
            console.log(`✗ Failed to compile ${xslFile}`);
            fs.appendFileSync(LOG_FILE, `✗ Failed to compile ${xslFile}\n`);
            
            if (stderr) {
                console.error(`Error: ${stderr}`);
                fs.appendFileSync(LOG_FILE, `Error: ${stderr}\n\n`);
            }
            
            return false;
        }
    } catch (error) {
        console.error(`✗ Failed to compile ${xslFile}`);
        console.error(`Error: ${error.message}`);
        fs.appendFileSync(LOG_FILE, `✗ Failed to compile ${xslFile}\nError: ${error.message}\n\n`);
        return false;
    }
}

// Main function
async function main() {
    console.log(`Finding XSL files in top level of ${INPUT_DIR}...`);
    fs.appendFileSync(LOG_FILE, `Finding XSL files in top level of ${INPUT_DIR}...\n`);
    
    const xslFiles = findTopLevelXslFiles(INPUT_DIR);
    const totalCount = xslFiles.length;
    
    console.log(`Found ${totalCount} XSL files to process`);
    
    let successCount = 0;
    let failureCount = 0;
    
    // Process each file
    for (const xslFile of xslFiles) {
        const success = await processXslFile(xslFile);
        if (success) {
            successCount++;
        } else {
            failureCount++;
        }
    }
    
    // Print summary
    const summary = `
===== Compilation Summary =====
Total files processed: ${totalCount}
Successfully compiled: ${successCount}
Failed to compile: ${failureCount}
Log file: ${LOG_FILE}
`;
    
    console.log(summary);
    fs.appendFileSync(LOG_FILE, summary);
    
    console.log('Done!');
}

// Run the main function
main().catch(error => {
    console.error('Unhandled error:', error);
    process.exit(1);
});