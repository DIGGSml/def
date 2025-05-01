/**
 * DIGGS CodeSpace Validator JavaScript - Updated
 * 
 * This file contains all the JavaScript functionality for the DIGGS CodeSpace Validator.
 * It handles file loading, XML validation, result display, filtering, and exporting.
 */

// Global variables
let xmlFileContent = null;
let xmlDoc = null;

/**
 * Initialize the application when the DOM is fully loaded
 */
document.addEventListener('DOMContentLoaded', function() {
    // Set up event listeners
    document.getElementById('file-upload').addEventListener('change', handleFileSelected);
    document.getElementById('validate-button').addEventListener('click', validateXML);
    document.getElementById('level-filter').addEventListener('change', filterResults);
    document.getElementById('debug-toggle').addEventListener('change', toggleDebug);
    document.getElementById('export-csv').addEventListener('click', function() { exportResults('csv'); });
    document.getElementById('export-html').addEventListener('click', function() { exportResults('html'); });
    
    // Set up drag and drop functionality
    setupDragAndDrop();
});

/**
 * Handle file selection from the file input
 */
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
            
            // Pre-parse the XML to store as a DOM for line number extraction
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

/**
 * Filter results by severity level
 */
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

/**
 * Toggle display of debug information
 */
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

/**
 * Update validation summary counts
 */
function updateSummary() {
    const errors = document.querySelectorAll('#results-body tr.error:not([style*="display: none"])').length;
    const warnings = document.querySelectorAll('#results-body tr.warning:not([style*="display: none"])').length;
    const infos = document.querySelectorAll('#results-body tr.info:not([style*="display: none"])').length;
    const debugs = document.querySelectorAll('#results-body tr.debug:not([style*="display: none"])').length;
    
    const summary = `Found ${errors} errors, ${warnings} warnings, ${infos} information messages${debugs > 0 ? ` and ${debugs} debug messages` : ''}.`;
    document.getElementById('summary-text').textContent = summary;
}

/**
 * Export validation results as CSV or HTML
 * @param {string} format - Export format ('csv' or 'html')
 */
function exportResults(format) {
    const results = collectResults();
    
    if (format === 'csv') {
        // Create CSV content
        let csvContent = "Line,Source XML,Severity,Message\n";
        results.forEach(result => {
            const lineNumber = result.lineNumber.trim();
            const sourceXml = result.sourceXml.trim().replace(/"/g, '""');
            const severity = result.severity.trim();
            const message = result.message.trim().replace(/"/g, '""');
            
            csvContent += `"${lineNumber}","${sourceXml}","${severity}","${message}"\n`;
        });
        
        // Download CSV file
        downloadFile(csvContent, 'validation-results.csv', 'text/csv');
    } else if (format === 'html') {
        // Create HTML content
        const tableRows = results.map(result => {
            return `<tr class="${result.level.toLowerCase()}">
                <td>${result.lineNumber}</td>
                <td><pre class="source-xml">${escapeHtml(result.sourceXml)}</pre></td>
                <td><span class="severity-badge ${result.level.toLowerCase()}">${result.severity}</span></td>
                <td>${result.message}</td>
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
                                <th>Line #</th>
                                <th>Source XML</th>
                                <th>Severity</th>
                                <th>Message</th>
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
        downloadFile(htmlContent, 'validation-report.html', 'text/html');
    }
}

/**
 * Helper function to escape HTML special characters
 * @param {string} unsafe - Text to escape
 * @returns {string} - Escaped text
 */
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

/**
 * Collect all visible validation results
 * @returns {Array} - Array of result objects
 */
function collectResults() {
    const results = [];
    const rows = document.querySelectorAll('#results-body tr:not([style*="display: none"])');
    
    rows.forEach(row => {
        const cells = row.querySelectorAll('td');
        if (cells.length >= 4) {
            results.push({
                lineNumber: cells[0].textContent,
                sourceXml: cells[1].textContent,
                severity: cells[2].textContent,
                message: cells[3].textContent,
                level: row.className
            });
        }
    });
    
    return results;
}

/**
 * Download a file to the user's device
 * @param {string} content - File content
 * @param {string} filename - Name for the downloaded file
 * @param {string} contentType - MIME type of the file
 */
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

/**
 * Process XSLT validation results and update the UI
 * @param {Array} results - Validation result objects
 */
function processValidationResults(results) {
    // Clear previous results
    const resultsBody = document.getElementById('results-body');
    resultsBody.innerHTML = '';
    
    // Add results to table
    results.forEach(result => {
        const row = document.createElement('tr');
        row.className = result.level.toLowerCase();
        
        // Create cells with the improved display format
        row.innerHTML = `
            <td class="line-number">${result.lineNumber}</td>
            <td><pre class="source-xml">${escapeHtml(result.sourceXml)}</pre></td>
            <td><span class="severity-badge ${result.level.toLowerCase()}">${result.severity}</span></td>
            <td>${result.message}</td>
        `;
        
        resultsBody.appendChild(row);
    });
    
    // Show results and update summary
    document.getElementById('validation-results').style.display = 'block';
    updateSummary();
}

/**
 * Copy text to clipboard
 * @param {string} text - Text to copy
 */
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(function() {
        // Success - could add a visual indication here
        console.log('Copied to clipboard');
    });
}

/**
 * Validate the XML using the external XSLT
 */
function validateXML() {
    if (!xmlFileContent) {
        document.getElementById('error-message').textContent = 'Please select an XML file first';
        document.getElementById('error-message').style.display = 'block';
        return;
    }
    
    // Show loading spinner
    document.getElementById('loading').style.display = 'block';
    document.getElementById('error-message').style.display = 'none';
    document.getElementById('validation-results').style.display = 'none';
    
    try {
        // Parse the XML
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlFileContent, 'text/xml');
        
        // Check for XML parsing errors
        if (xmlDoc.getElementsByTagName('parsererror').length > 0) {
            throw new Error('XML parsing error: Invalid XML format');
        }
        
        // Fetch the XSLT file using the fetch API
        fetch('https://diggsml.org/def/stylesheets/cs_validator.xsl')
            .then(response => {
                if (!response.ok) {
                    throw new Error(`Failed to load XSLT stylesheet: ${response.status} ${response.statusText}`);
                }
                return response.text();
            })
            .then(xsltContent => {
                // Parse the XSLT
                const xsltDoc = parser.parseFromString(xsltContent, 'text/xml');
                
                // Check for XSLT parsing errors
                if (xsltDoc.getElementsByTagName('parsererror').length > 0) {
                    throw new Error('XSLT parsing error: Invalid XSLT format');
                }
                
                // Perform the XSLT transformation
                let resultDoc;
                
                if (window.XSLTProcessor) {
                    // Modern browsers (Firefox, Chrome, Safari)
                    const xsltProcessor = new XSLTProcessor();
                    xsltProcessor.importStylesheet(xsltDoc);
                    resultDoc = xsltProcessor.transformToDocument(xmlDoc);
                } else if (window.ActiveXObject || "ActiveXObject" in window) {
                    // Internet Explorer
                    const xslt = new ActiveXObject("Msxml2.XSLTemplate.6.0");
                    const xslDoc = new ActiveXObject("Msxml2.FreeThreadedDOMDocument.6.0");
                    xslDoc.loadXML(xsltContent);
                    xslt.stylesheet = xslDoc;
                    const xslProc = xslt.createProcessor();
                    xslProc.input = xmlDoc;
                    xslProc.transform();
                    
                    // Parse the output from IE's transform
                    const ieResult = xslProc.output;
                    resultDoc = parser.parseFromString(ieResult, 'application/xml');
                } else {
                    throw new Error('Your browser does not support XSLT processing');
                }
                
                // Extract validation results from the transformed document
                const validationResults = [];
                
                // Get all validation entries from the result
                const validationEntries = resultDoc.querySelectorAll('validationEntry');
                
                validationEntries.forEach(entry => {
                    validationResults.push({
                        lineNumber: entry.getAttribute('lineNumber') || 'Unknown',
                        elementPath: entry.getAttribute('elementPath') || '',
                        value: entry.getAttribute('value') || '',
                        codeSpace: entry.getAttribute('codeSpace') || '',
                        level: entry.getAttribute('level') || 'INFO',
                        severity: entry.getAttribute('severity') || 'Information',
                        sourceXml: entry.getAttribute('sourceXml') || '',
                        message: entry.getAttribute('message') || ''
                    });
                });
                
                // Process the results
                processValidationResults(validationResults);
                
                // Hide loading spinner
                document.getElementById('loading').style.display = 'none';
            })
            .catch(error => {
                handleError(error.message);
            });
    } catch (error) {
        handleError('Validation error: ' + error.message);
    }
}

/**
 * Handle and display errors
 * @param {string} message - Error message to display
 */
function handleError(message) {
    // Display error and hide loading spinner
    document.getElementById('loading').style.display = 'none';
    document.getElementById('error-message').textContent = message;
    document.getElementById('error-message').style.display = 'block';
    console.error(message);
}

/**
 * Setup drag and drop functionality for file upload
 */
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