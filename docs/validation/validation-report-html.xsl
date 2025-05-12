<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <xsl:template match="/">
    <html>
      <head>
        <title>DIGGS Validation Report</title>
        <!-- Add CodeMirror CSS -->
        <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/codemirror.min.css"/>
        <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/theme/eclipse.min.css"/>
        <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/dialog/dialog.min.css"/>
        <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/foldgutter.min.css"/>
        <style>
/* Base styles */
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
    background-color: #f5f5f5;
    color: #333;
    line-height: 1.6;
}

.container {
    max-width: 1400px;
    margin: 0 auto;
    background-color: white;
    padding: 20px 30px;
    border-radius: 8px;
    box-shadow: 0 2px 15px rgba(0, 0, 0, 0.1);
}

h1 {
    color: #2c3e50;
    text-align: center;
    margin-bottom: 10px;
    padding-bottom: 10px;
    width: 100%;
}

.header-container {
    position: relative;
    text-align: center;
    border-bottom: 2px solid #f0f0f0;
    padding-bottom: 10px;
    margin-bottom: 20px;
    height: 50px;
}

.header-logo {
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 200px;
}

/* Validation result styles - row shading colors */
.error {
    background-color: #fdd5d1;
    border-left: 4px solid #b02819
}

.warning {
    background-color: #fde5be;
    border-left: 4px solid #9c7008
}

.info {
    background-color: #d1e7f2;
    border-left: 4px solid #0b68a7

}

.success {
    background-color: #e9f7ef;
    border-left: 4px solid #2ecc71;
}

/* Summary banner */
.summary-banner {
    padding: 6px;
    margin: 15px 0;
    text-align: center;
    border-radius: 4px;
    font-weight: bold;
    font-size: 18px;
}

.summary-banner.success {
    background-color: #d4efdf;
}

.summary-banner.info {
    background-color: #d4e6f1;
}

.summary-banner.warning {
    background-color: #fae5d3;
}

.summary-banner.error {
    background-color: #f5b7b1;
}
/* Table with fixed layout */
table {
width: 100%;
border-collapse: collapse;
margin-top: 20px;
font-size: 13px; /* Slightly smaller font */
table-layout: fixed;
line-height: 1.2; /* Tighter line height */
}

.table-container {
max-height: 350px;
overflow-y: auto;
margin-bottom: 20px;
overflow-x: auto;
-webkit-overflow-scrolling: touch;
}

table th:nth-child(1), table td:nth-child(1) { width: 80px; }
table th:nth-child(2), table td:nth-child(2) { width: 100px; }
table th:nth-child(3), table td:nth-child(3) { width: 150px; }
table th:nth-child(4), table td:nth-child(4) { width: 650px; }
table th:nth-child(5), table td:nth-child(5) { width: auto; }

/* Cell styling with reduced spacing */
th, td {
padding: 2px 8px; /* Minimal vertical padding */
text-align: left;
border-bottom: 1px solid black;
vertical-align: middle;
word-wrap: break-word;
overflow-wrap: break-word;
line-height: 1.2; /* Tighter line spacing */
}

/* Message column with preserved line breaks and word wrapping */
table td:nth-child(4) {
text-align: left !important; /* Explicitly left-align */
white-space: pre-wrap;
word-wrap: break-word;
overflow-wrap: break-word;
word-break: break-word;
text-indent: 0 !important;
}

/* Headers */
th {
background-color: #f2f2f2;
position: sticky;
top: 0;
z-index: 10;
white-space: nowrap;
}

table td:nth-child(4) pre.source-xml {
font-family: sans-serif;
font-size: inherit;
white-space: pre-wrap;
word-wrap: break-word;
overflow-wrap: break-word;
word-break: break-word;
background-color: transparent;
padding: 0 !important;
margin: 0 !important;
border: none;
border-radius: 0;
max-width: 100%;
overflow-x: visible;
display: block; /* Changed from inline to block */
box-sizing: border-box;
text-indent: 0 !important;
line-height: 1.2;

/* Additional properties to prevent indentation */
text-align: left !important;
-webkit-text-indent: 0 !important;
-moz-text-indent: 0 !important;
text-decoration: none;
text-transform: none;
}

/* Severity badges */
.severity-badge {
    display: inline-block;
    padding: 4px 8px;
    border-radius: 4px;
    font-weight: bold;
    color: white;
    margin: 0 3px;
}

.severity-badge.error {
    background-color: #b02819;
}

.severity-badge.warning {
    background-color: #9c7008;
}

.severity-badge.info {
    background-color: #0b68a7;
}

/* Source XML in table - sans-serif and transparent background */
table td pre.source-xml {
    font-family: sans-serif;
    font-size: inherit;
    white-space: pre-wrap;
    word-wrap: break-word;
    overflow-wrap: break-word;
    word-break: break-word;
    background-color: transparent;
    padding: 0;
    margin: 0;
    border: none;
    border-radius: 0;
    max-width: 100%;
    overflow-x: visible;
    display: inline;
    box-sizing: border-box;
    text-indent: 0 !important; /* Remove first-line indent */
}

/* Source XML outside table (editor box) - monospace */
.source-xml {
    font-family: monospace;
    font-size: inherit;
    white-space: pre-wrap;
    word-break: break-all;
    background-color: #f5f5f5; /* Gray background for editor */
    padding: 8px;
    border-radius: 4px;
    margin: 0;
    max-width: 100%;
    overflow-x: auto;
    overflow-wrap: break-word;
}

/* Controls */
.controls {
    display: flex;
    justify-content: space-between;
    margin: 15px 0;
    padding: 10px;
    background-color: #f8f9fa;
    border-radius: 4px;
}

.filter-controls {
    display: flex;
    align-items: center;
}

.export-controls {
    display: flex;
    align-items: center;
}

.export-button {
    padding: 5px 10px;
    background-color: #3498db;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    margin-left: 10px;
}

.export-button:hover {
    background-color: #2980b9;
}

.validation-summary {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 0px;
    padding: 15px;
    background-color: #f8f9fa;
    border-radius: 4px;
}

.file-info {
    flex: 1;
    text-align: left;
}

.summary-badges {
    flex: 1;
    text-align: center;
}

.timestamp-info {
    flex: 1;
    text-align: right;
}

/* XML Editor styles */
.editor-container {
    margin-top: 20px;
    border: 1px solid #ddd;
    border-radius: 4px;
    overflow: hidden;
}

.editor-header {
    background-color: #f2f2f2;
    padding: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #ddd;
}

.editor-title {
    font-weight: bold;
    margin: 0;
}

.editor-actions {
    display: flex;
    gap: 10px;
}

.editor-button {
    padding: 5px 10px;
    background-color: #3498db;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.editor-button:hover {
    background-color: #2980b9;
}

.editor-body {
    padding: 0;
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.5s ease;
    position: relative;
}

.editor-body.open {
    max-height: 500px;
    overflow: visible;
    display: block;
}

/* CodeMirror customizations */
.CodeMirror {
    height: 500px;
    font-family: monospace;
    font-size: 14px;
    line-height: 1.5;
}

.editor-body:not(.open) .CodeMirror {
    display: none;
}

/* Editor status bar */
.editor-statusbar {
    display: flex;
    justify-content: space-between;
    background-color: #f0f0f0;
    padding: 5px 10px;
    border-top: 1px solid #ddd;
    font-size: 12px;
    color: #666;
}

/* CodeMirror highlighting */
.CodeMirror-activeline-background {
    background-color: rgba(255, 140, 0, 0.3);
}

.cm-matchhighlight {
    background-color: rgba(255, 140, 0, 0.3);
}

.CodeMirror-focused .cm-matchhighlight {
    background-color: rgba(255, 140, 0, 0.5);
}

.cm-highlight-element {
  //   background-color: #ffff99;
    background-color: #FF8C00;
}

.xpath-highlight {
    background-color: #FF8C00;
}

.cm-searching {
background-color: #ffff99; /* Pale yellow for all matches */
}

.cm-searching.CodeMirror-selectedtext, 
.CodeMirror-focused .cm-searching.CodeMirror-selectedtext {
background-color: #FF8C00 !important; /* Orange for selected match */
}

.xpath-link {
    color: #3498db;
    text-decoration: underline;
    cursor: pointer;
}

.xpath-link:hover {
    color: #2980b9;
}

/* Tooltip styling with auto width and max-width */
.tooltip {
    position: relative;
    display: inline-block;
}

.tooltip .tooltiptext {
    visibility: hidden;
    width: auto; /* Auto width */
    max-width: 500px; /* Max width constraint */
    background-color: #555;
    color: #fff;
    text-align: left;
    border-radius: 6px;
    padding: 5px 10px;
    position: absolute;
    z-index: 50;
    top: -5px;
    left: 105%;
    opacity: 0;
    transition: opacity 0.3s;
    white-space: normal;
    word-wrap: break-word;
    overflow-wrap: break-word;
    hyphens: auto;
}

.tooltip:hover .tooltiptext {
    visibility: visible;
    opacity: 1;
}

/* Dialog styles */
.dialog-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 1000;
    align-items: center;
    justify-content: center;
}

.dialog-container {
    background-color: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
    width: 500px;
    max-width: 90%;
}

.dialog-title {
    margin-top: 0;
    margin-bottom: 15px;
    font-size: 18px;
    color: #2c3e50;
}

.dialog-content {
    margin-bottom: 20px;
}

.dialog-form-group {
    margin-bottom: 15px;
}

.dialog-label {
    display: block;
    margin-bottom: 5px;
    font-weight: bold;
}

.dialog-input {
    width: 100%;
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
    box-sizing: border-box;
}

.dialog-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
}

.dialog-button {
    padding: 8px 16px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.dialog-button-primary {
    background-color: #3498db;
    color: white;
}

.dialog-button-secondary {
    background-color: #f2f2f2;
    color: #333;
}

/* Responsive design */
@media (max-width: 768px) {
    .editor-actions {
        flex-direction: column;
        gap: 5px;
    }
    
    .CodeMirror {
        font-size: 12px;
    }
}
        </style>
      </head>
      <body>
        <div class="container">
          <!-- Header with logo -->
          <div class="header-container">
            <img src="https://diggsml.org/def/img/diggs-logo.png" alt="DIGGS Logo"
              class="header-logo"/>
            <h1>DIGGS Validation Report</h1>
          </div>

          <!-- Summary statistics -->
          <xsl:variable name="errorCount" select="count(//message[severity = 'ERROR'])"/>
          <xsl:variable name="warningCount" select="count(//message[severity = 'WARNING'])"/>
          <xsl:variable name="infoCount" select="count(//message[severity = 'INFO'])"/>

          <div class="validation-summary">
            <div class="file-info">
              <strong>Document: </strong>
              <span>
                <xsl:value-of select="/validationReport/fileName"/>
              </span>
            </div>

            <div class="summary-badges">
              <span class="severity-badge error"><xsl:value-of select="$errorCount"/> Errors</span>
              <span class="severity-badge warning"><xsl:value-of select="$warningCount"/>
                Warnings</span>
              <span class="severity-badge info"><xsl:value-of select="$infoCount"/> Info</span>
            </div>

            <div class="timestamp-info">
              <strong>Timestamp: </strong>
              <xsl:value-of select="/validationReport/timestamp"/>
            </div>
          </div>

          <!-- Summary Banner -->
          <xsl:variable name="summaryClass">
            <xsl:choose>
              <xsl:when test="$errorCount > 0">error</xsl:when>
              <xsl:when test="$warningCount > 0">warning</xsl:when>
              <xsl:when test="$infoCount > 0">info</xsl:when>
              <xsl:otherwise>success</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="summaryMessage">
            <xsl:choose>
              <xsl:when test="$errorCount > 0">Result: Fail. Correct errors and rescan.</xsl:when>
              <xsl:when test="$warningCount > 0">Result: Possible Errors. Address Warnings to
                complete validation.</xsl:when>
              <xsl:when test="$infoCount > 0">Result: Success! Please review INFO
                messages.</xsl:when>
              <xsl:otherwise>Result: Success! No issues detected.</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <div class="summary-banner {$summaryClass}">
            <xsl:value-of select="$summaryMessage"/>
          </div>

          <div class="controls">
            <div class="filter-controls">
              <label for="severity-filter">Filter by severity:</label>
              <select id="severity-filter">
                <option value="all">All</option>
                <option value="error">Errors</option>
                <option value="warning">Warnings</option>
                <option value="info">Info</option>
              </select>
            </div>

            <div class="export-controls">
              <button id="export-csv" class="export-button">Export to CSV</button>
            </div>
          </div>

          <div class="table-container">
            <table id="validation-table">
              <thead>
                <tr>
                  <th>Severity</th>
                  <th>Location</th>
                  <th>Validation Check</th>
                  <th>Message</th>
                  <th>Element Value</th>
                </tr>
              </thead>
              <tbody>
                <xsl:for-each select="//message">
                  <xsl:variable name="severityClass">
                    <xsl:choose>
                      <xsl:when test="severity = 'ERROR'">error</xsl:when>
                      <xsl:when test="severity = 'WARNING'">warning</xsl:when>
                      <xsl:otherwise>info</xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>

                  <tr class="{$severityClass}">
                    <td>
                      <span class="severity-badge {$severityClass}">
                        <xsl:value-of select="severity"/>
                      </span>
                    </td>
                    <td>
                      <xsl:if test="elementPath">
                        <div class="tooltip">
                          <span class="xpath-link" data-xpath="{elementPath}"> View Element </span>
                          <span class="tooltiptext">
                            <xsl:value-of select="elementPath"/>
                          </span>
                        </div>
                      </xsl:if>
                    </td>
                    <td>
                      <xsl:value-of select="../step"/>
                    </td>
                    <td>
                      <pre class="source-xml"><xsl:value-of select="text"/></pre>
                    </td>
                    <td>
                      <pre class="source-xml"><xsl:value-of select="normalize-space(source)"/></pre>
                    </td>
                  </tr>
                </xsl:for-each>
              </tbody>
            </table>
          </div>

          <!-- CodeMirror XML Editor -->
          <div class="editor-container">
            <div class="editor-header">
              <h3 class="editor-title">XML Editor</h3>
              <div class="editor-actions">
                <button class="editor-button" id="toggle-editor">Show/Hide Editor</button>
                <button class="editor-button" id="save-xml">Save XML</button>
                <button class="editor-button" id="format-xml">Format XML</button>
                <button class="editor-button" id="find-xml">Find</button>
              </div>
            </div>

            <div class="editor-body" id="editor-body">
              <!-- Hidden textarea - CodeMirror will replace this -->
              <textarea id="xml-editor" style="display: none;">
                <xsl:value-of select="/validationReport/originalXml"/>
              </textarea>
            </div>

            <!-- Status bar for cursor position information -->
            <div class="editor-statusbar" id="editor-statusbar">
              <div id="cursor-position">Line: 1, Column: 1</div>
              <div id="xml-info">XML Mode</div>
            </div>
          </div>
        </div>

        <!-- Save File Dialog -->
        <div id="save-file-dialog" class="dialog-overlay">
          <div class="dialog-container">
            <h3 class="dialog-title">Save XML File</h3>
            <div class="dialog-content">
              <div class="dialog-form-group">
                <label for="file-name" class="dialog-label">File name:</label>
                <input type="text" id="file-name" class="dialog-input"/>
              </div>
              <div id="save-error-message" style="color: #e74c3c; margin-top: 10px; display: none;"
              />
            </div>
            <div class="dialog-actions">
              <button id="cancel-save" class="dialog-button dialog-button-secondary">Cancel</button>
              <button id="confirm-save" class="dialog-button dialog-button-primary">Save</button>
            </div>
          </div>
        </div>

        <!-- CodeMirror Library Scripts -->
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/codemirror.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/mode/xml/xml.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/edit/matchbrackets.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/xml-fold.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/edit/matchtags.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/selection/active-line.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/search.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/searchcursor.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/jump-to-line.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/match-highlighter.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/dialog/dialog.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/foldcode.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/foldgutter.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/display/placeholder.min.js"/>

        <!-- JavaScript for functionality -->
        <script>
        <![CDATA[
        // Ensure DOM is fully loaded before accessing elements
        document.addEventListener('DOMContentLoaded', function() {
          console.log('DOM content loaded - initializing JavaScript');
          
          // CodeMirror instance variable, make it globally accessible
          let codeMirror = null;
          let editorInitialized = false;
          
          // Function to filter table rows by severity
          function filterBySeverity(severity) {
            const table = document.getElementById('validation-table');
            if (!table) {
              console.error('Validation table not found');
              return;
            }
            
            const tbody = table.getElementsByTagName('tbody')[0];
            if (!tbody) {
              console.error('Table body not found');
              return;
            }
            
            const rows = tbody.getElementsByTagName('tr');
            
            for (let i = 0; i < rows.length; i++) {
              const row = rows[i];
              if (severity === 'all') {
                row.style.display = '';
              } else {
                const severityCell = row.getElementsByTagName('td')[0];
                if (!severityCell) continue;
                
                const badge = severityCell.querySelector('.severity-badge');
                if (!badge) continue;
                
                const severityText = badge.textContent.trim().toLowerCase();
                
                if (severityText === severity) {
                  row.style.display = '';
                } else {
                  row.style.display = 'none';
                }
              }
            }
          }
          
          // Set up the severity filter dropdown
          const severityFilter = document.getElementById('severity-filter');
          if (severityFilter) {
            severityFilter.addEventListener('change', function() {
              filterBySeverity(this.value);
            });
          } else {
            console.error('Severity filter dropdown not found');
          }
          
          // Initialize CodeMirror editor
          function initCodeMirror() {
            // If already initialized, just refresh
            if (editorInitialized && codeMirror) {
              codeMirror.refresh();
              return codeMirror;
            }
            
            const editor = document.getElementById('xml-editor');
            if (!editor) {
              console.error('XML editor element not found');
              return null;
            }
            
            try {
              // Create CodeMirror instance
              codeMirror = CodeMirror.fromTextArea(editor, {
                mode: 'application/xml', // XML mode
                lineNumbers: true, // Show line numbers
                matchBrackets: true, // Highlight matching brackets
                autoCloseTags: true, // Auto-close tags
                matchTags: {bothTags: true}, // Highlight matching tags
                indentUnit: 4, // Indentation unit is 4 spaces
                tabSize: 4, // Tab size is 4 spaces
                smartIndent: true, // Smart indentation
                lineWrapping: true, // Wrap long lines
                theme: 'eclipse', // Use the Eclipse theme
                styleActiveLine: true, // Highlight active line
                foldGutter: true, // Code folding
                gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
                extraKeys: {
                  "Ctrl-Space": "autocomplete", // Enable autocomplete
                  "Ctrl-Q": function(cm) { cm.foldCode(cm.getCursor()); }, // Fold code
                  "Ctrl-F": "findPersistent", // Find functionality
                  "Tab": function(cm) {
                    // Insert spaces instead of tab character
                    const spaces = Array(cm.getOption("indentUnit") + 1).join(" ");
                    cm.replaceSelection(spaces);
                  }
                }
              });
              
              // Update cursor position in status bar
              codeMirror.on('cursorActivity', function() {
                updateCursorPosition();
              });
              
              // Mark initialization as successful
              editorInitialized = true;
              
              // Ensure CodeMirror is refreshed when shown
              setTimeout(function() {
                if (codeMirror) {
                  codeMirror.refresh();
                  console.log('CodeMirror refreshed');
                }
              }, 100);
              
              return codeMirror;
            } catch (error) {
              console.error('Error initializing CodeMirror:', error);
              alert('Error initializing the XML editor. Fall back to basic editor functionality.');
              return null;
            }
          }
          
          // Update cursor position in status bar
          function updateCursorPosition() {
            if (!codeMirror) return;
            
            const cursorPosition = document.getElementById('cursor-position');
            if (!cursorPosition) return;
            
            const cursor = codeMirror.getCursor();
            cursorPosition.textContent = `Line: ${cursor.line + 1}, Column: ${cursor.ch + 1}`;
          }
          
          // Format XML function
          function formatXml() {
            if (!codeMirror) return;
            
            try {
              // Get the current XML content
              let xmlContent = codeMirror.getValue();
              
              // Basic XML formatting function
              function prettyPrint(xml) {
                let formatted = '';
                let indent = '';
                const tab = '  '; // 2 spaces for indentation
                
                xml = xml.replace(/(>)(<)(\/*)/g, '$1\n$2$3'); // Add line breaks
                
                const lines = xml.split('\n');
                
                lines.forEach(line => {
                  // Skip blank lines
                  if (line.trim() === '') return;
                  
                  const match = line.match(/^.*<(\/*)(.*?)(\s.*)?>/);
                  
                  if (match) {
                    const closing = match[1];
                    const opening = line.match(/<.*?>/g).length - (line.match(/<\/.*/g)?.length || 0);
                    
                    if (closing) {
                      // This is a closing tag, reduce indent
                      indent = indent.substring(tab.length);
                    }
                    
                    // Add the line with proper indentation
                    formatted += indent + line.trim() + '\n';
                    
                    if (!closing && opening === 1) {
                      // This is an opening tag, increase indent
                      indent += tab;
                    }
                  } else {
                    // This is content or a non-standard line, just add it with current indent
                    formatted += indent + line.trim() + '\n';
                  }
                });
                
                return formatted.trim();
              }
              
              // Format the XML
              const formattedXml = prettyPrint(xmlContent);
              
              // Update CodeMirror with formatted XML
              codeMirror.setValue(formattedXml);
              
              // Put cursor at the beginning
              codeMirror.setCursor(0, 0);
              
              console.log('XML formatted successfully');
            } catch (error) {
              console.error('Error formatting XML:', error);
              alert('There was an error formatting the XML. Please check if your XML is valid.');
            }
          }
          
          // Toggle CodeMirror editor visibility
          function toggleEditor() {
            const editorBody = document.getElementById('editor-body');
            if (!editorBody) {
              console.error('Editor body not found');
              return;
            }
            
            // Toggle the open class
            editorBody.classList.toggle('open');
            
            // Initialize or refresh CodeMirror when opening
            if (editorBody.classList.contains('open')) {
              if (!editorInitialized) {
                // First time initialization
                codeMirror = initCodeMirror();
              } else {
                // Refresh to ensure proper rendering
                setTimeout(() => {
                  if (codeMirror) {
                    codeMirror.refresh();
                  }
                }, 10);
              }
            }
            
            console.log('Editor toggled, open state:', editorBody.classList.contains('open'));
          }
          
          // Function to find text in CodeMirror
          function findInEditor() {
            if (!codeMirror) {
              // If editor is not initialized or visible, show it first
              const editorBody = document.getElementById('editor-body');
              if (editorBody && !editorBody.classList.contains('open')) {
                toggleEditor();
                
                // Wait for editor to be fully initialized
                setTimeout(() => {
                  if (codeMirror) {
                    codeMirror.execCommand('findPersistent');
                  }
                }, 200);
                return;
              }
              return;
            }
            
            // Use CodeMirror's built-in search functionality
            codeMirror.execCommand('findPersistent');
          }
          
          // Function to find and highlight XML element by XPath
          function findElementByXPath(xpath) {
            console.log('Finding element with XPath:', xpath);
            
            // First make sure editor is open and initialized
            const editorBody = document.getElementById('editor-body');
            if (!editorBody) {
              console.error('Editor body not found');
              return false;
            }
            
            // If editor is not already open, open it first
            if (!editorBody.classList.contains('open')) {
              console.log('Opening editor for XPath navigation');
              editorBody.classList.add('open');
              
              // Initialize CodeMirror if needed and then process XPath
              setTimeout(() => {
                // Initialize if needed
                if (!editorInitialized || !codeMirror) {
                  codeMirror = initCodeMirror();
                } else {
                  codeMirror.refresh();
                }
                
                // Now that editor is initialized, find the element
                setTimeout(() => {
                  processXPathNavigation(xpath);
                }, 200);
              }, 100);
              
              return true;
            } else {
              // Editor is already open, just find the element
              if (!editorInitialized || !codeMirror) {
                codeMirror = initCodeMirror();
              }
              
              // Find the element directly
              return processXPathNavigation(xpath);
            }
          }
          
          // Helper function to process XPath navigation once editor is ready
          function processXPathNavigation(xpath) {
            if (!codeMirror) {
              console.error('CodeMirror not initialized');
              return false;
            }
            
            // Parse the XPath to handle position indicators
            const xmlContent = codeMirror.getValue();
            const xpathParts = xpath.split('/').filter(part => part.length > 0);
            
            let searchPos = 0;
            let foundElement = false;
            
            for (let i = 0; i < xpathParts.length; i++) {
              const part = xpathParts[i];
              const tagName = part.replace(/\[\d+\]$/, '');
              const positionMatch = part.match(/\[(\d+)\]$/);
              const position = positionMatch ? parseInt(positionMatch[1]) : 1;
              
              // Find the nth occurrence of the tag
              let count = 0;
              let tagPos = -1;
              let match;
              const tagRegex = new RegExp('<' + tagName + '(?:\\s|/|>)', 'g');
              
              while ((match = tagRegex.exec(xmlContent.substring(searchPos))) !== null && count < position) {
                count++;
                tagPos = searchPos + match.index;
                
                if (count === position) {
                  searchPos = tagPos;
                  
                  // If this is the last part of the xpath, we've found our element
                  if (i === xpathParts.length - 1) {
                    foundElement = true;
                  }
                  break;
                }
              }
              
              // If we couldn't find the required occurrence, break
              if (count < position) {
                break;
              }
            }
            
            if (foundElement) {
              console.log('Element found, determining boundaries');
              // Find the closing tag to determine element boundaries
              const lastPart = xpathParts[xpathParts.length - 1];
              const elementName = lastPart.replace(/\[\d+\]$/, '');
              
              let depth = 1;
              let endPos = searchPos;
              
              // Search for closing tag, considering nesting
              for (let i = searchPos + 1; i < xmlContent.length && depth > 0; i++) {
                // Check for opening tag
                if (xmlContent.substring(i, i + elementName.length + 1).indexOf('<' + elementName) === 0) {
                  // Make sure it's a tag and not part of text
                  const nextChar = xmlContent.charAt(i + elementName.length + 1);
                  if (nextChar === ' ' || nextChar === '/' || nextChar === '>') {
                    depth++;
                  }
                }
                // Check for closing tag
                else if (xmlContent.substring(i, i + elementName.length + 2).indexOf('</' + elementName) === 0) {
                  depth--;
                  if (depth === 0) {
                    // Find the end of the closing tag
                    const closeTagEnd = xmlContent.indexOf('>', i);
                    if (closeTagEnd !== -1) {
                      endPos = closeTagEnd + 1; // Length of '>'
                    }
                    break;
                  }
                }
              }
              
              console.log('Setting CodeMirror selection');
              
              // Convert positions to line and character positions for CodeMirror
              const startPos = codeMirror.posFromIndex(searchPos);
              const endPosition = codeMirror.posFromIndex(endPos);
              
              // Select the element in CodeMirror
              codeMirror.setSelection(startPos, endPosition);
              
              // Scroll to make the selection visible
              const middleLine = Math.floor((startPos.line + endPosition.line) / 2);
              codeMirror.scrollIntoView({line: middleLine, ch: 0}, 100);
              
              // Add background highlight to the selected area
              const marker = codeMirror.markText(startPos, endPosition, {
                className: 'xpath-highlight'
              });
              
              // Remove highlight after a few seconds
              setTimeout(() => {
                if (marker) marker.clear();
              }, 3000);
              
              console.log('Element highlighted in editor');
              return true;
            } else {
              console.log('Element not found in XML content');
              alert('Could not find the specified element. The XML structure may have changed.');
              return false;
            }
          }
          
          // Helper function for direct file download
          function downloadFile(content, filename, mimeType) {
            try {
              const blob = new Blob([content], { type: mimeType });
              const url = URL.createObjectURL(blob);
              
              const a = document.createElement('a');
              a.href = url;
              a.download = filename;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              
              URL.revokeObjectURL(url);
              console.log('File downloaded via direct method');
              
              return true;
            } catch (err) {
              console.error('Error in download:', err);
              alert('Could not download the file: ' + err.message);
              return false;
            }
          }
          
          // Function to generate CSV content from the table
          function generateCsvContent() {
            const table = document.getElementById('validation-table');
            if (!table) {
              console.error('Validation table not found');
              return '';
            }
            
            const rows = table.querySelectorAll('tr');
            if (rows.length === 0) {
              console.error('No rows found in validation table');
              return '';
            }
            
            let csv = [];
            
            // Get headers
            const headers = [];
            const headerCells = rows[0].querySelectorAll('th');
            headerCells.forEach(cell => {
              headers.push('"' + cell.textContent.trim() + '"');
            });
            csv.push(headers.join(','));
            
            // Get table data
            for (let i = 1; i < rows.length; i++) {
              // Skip hidden rows (filtered out)
              if (rows[i].style.display === 'none') continue;
              
              const row = rows[i];
              const cells = row.querySelectorAll('td');
              const rowData = [];
              
              cells.forEach((cell, index) => {
                // Special case for severity column - extract text from badge
                if (index === 0) {
                  const badge = cell.querySelector('.severity-badge');
                  if (badge) {
                    rowData.push('"' + badge.textContent.trim() + '"');
                  } else {
                    rowData.push('""');
                  }
                } 
                // Special case for location column - extract path from tooltip
                else if (index === 1 && cell.querySelector('.tooltip')) {
                  const tooltip = cell.querySelector('.tooltiptext');
                  rowData.push('"' + (tooltip ? tooltip.textContent.trim() : '') + '"');
                }
                // Element value column - extract text without HTML
                else if (index === 4) {
                  const preElement = cell.querySelector('pre');
                  rowData.push('"' + (preElement ? preElement.textContent.replace(/"/g, '""') : '') + '"');
                }
                // Regular columns
                else {
                  rowData.push('"' + cell.textContent.trim().replace(/"/g, '""') + '"');
                }
              });
              
              csv.push(rowData.join(','));
            }
            
            return csv.join('\n');
          }
          
          // Function to directly save XML file using File System Access API
          async function saveXmlDirectly() {
            try {
              // Make sure editor is initialized
              if (!editorInitialized) {
                console.error('Editor not initialized');
                alert('Please open the editor first.');
                return;
              }
              
              if (!codeMirror) {
                console.error('CodeMirror editor not initialized');
                return;
              }
              
              // Get original filename and prepare default save name
              const fileInfoSpan = document.querySelector('.file-info span');
              if (!fileInfoSpan) {
                console.error('File info span not found');
                alert('Error: Could not find file info element');
                return;
              }
              
              const originalFileName = fileInfoSpan.textContent.trim();
              let suggestedName = 'edited_' + originalFileName;
              
              // Make sure extension is either .xml or .diggs
              if (!suggestedName.endsWith('.xml') && !suggestedName.endsWith('.diggs')) {
                suggestedName += '.xml';
              }
              
              // Get XML content from CodeMirror
              const xmlContent = codeMirror.getValue();
              
              // Try to use File System Access API
              if ('showSaveFilePicker' in window) {
                try {
                  console.log('Attempting to use File System Access API directly');
                  
                  const opts = {
                    suggestedName: suggestedName,
                    types: [{
                      description: 'XML Files',
                      accept: {
                        'application/xml': ['.xml', '.diggs']
                      }
                    }]
                  };
                  
                  // Show file picker dialog directly
                  const fileHandle = await window.showSaveFilePicker(opts);
                  console.log('File handle obtained:', fileHandle);
                  
                  // Create a writable stream
                  const writable = await fileHandle.createWritable();
                  console.log('Writable stream created');
                  
                  // Write the content
                  await writable.write(xmlContent);
                  console.log('Content written');
                  
                  // Close the stream
                  await writable.close();
                  console.log('File saved successfully');
                  
                  return true;
                } catch (err) {
                  console.error('Error using File System Access API:', err);
                  
                  // If user cancelled, just return
                  if (err.name === 'AbortError') {
                    console.log('User cancelled the file save operation');
                    return false;
                  }
                  
                  // Fall back to direct download without dialog
                  console.log('Falling back to direct download');
                  downloadFile(xmlContent, suggestedName, 'application/xml');
                }
              } else {
                // Fall back to direct download without dialog
                console.log('File System Access API not supported, using direct download');
                downloadFile(xmlContent, suggestedName, 'application/xml');
              }
            } catch (err) {
              console.error('Error in direct save operation:', err);
              alert('Error saving file: ' + err.message);
            }
          }
          
          // Function to directly save CSV file using File System Access API or direct download
          async function saveCsvDirectly() {
            try {
              // Get original filename and prepare default save name
              const fileInfoSpan = document.querySelector('.file-info span');
              if (!fileInfoSpan) {
                console.error('File info span not found');
                alert('Error: Could not find file info element');
                return;
              }
              
              const originalFileName = fileInfoSpan.textContent.trim();
              let suggestedName = originalFileName + '_validation_report.csv';
              
              // Make sure extension is csv
              if (!suggestedName.endsWith('.csv')) {
                suggestedName += '.csv';
              }
              
              // Get CSV content
              const csvData = generateCsvContent();
              if (!csvData || csvData.length === 0) {
                console.error('Failed to generate CSV content');
                alert('Error: Failed to generate CSV content. No data available.');
                return;
              }
              
              console.log('CSV Data generated:', csvData.substring(0, 100) + '...');
              
              // Try to use File System Access API
              if ('showSaveFilePicker' in window) {
                try {
                  console.log('Attempting to use File System Access API directly for CSV');
                  
                  const opts = {
                    suggestedName: suggestedName,
                    types: [{
                      description: 'CSV Files',
                      accept: {
                        'text/csv': ['.csv']
                      }
                    }]
                  };
                  
                  // Show file picker dialog directly
                  const fileHandle = await window.showSaveFilePicker(opts);
                  console.log('CSV file handle obtained:', fileHandle);
                  
                  // Create a writable stream
                  const writable = await fileHandle.createWritable();
                  console.log('CSV writable stream created');
                  
                  // Write the content
                  await writable.write(csvData);
                  console.log('CSV content written');
                  
                  // Close the stream
                  await writable.close();
                  console.log('CSV file saved successfully');
                  
                  return true;
                } catch (err) {
                  console.error('Error using File System Access API for CSV:', err);
                  
                  // If user cancelled, just return
                  if (err.name === 'AbortError') {
                    console.log('User cancelled the CSV file save operation');
                    return false;
                  }
                  
                  // Fall back to direct download without dialog
                  console.log('Falling back to direct download for CSV');
                  downloadFile(csvData, suggestedName, 'text/csv;charset=utf-8;');
                }
              } else {
                // Fall back to direct download without dialog
                console.log('File System Access API not supported, using direct download');
                downloadFile(csvData, suggestedName, 'text/csv;charset=utf-8;');
              }
            } catch (err) {
              console.error('Error in direct CSV save operation:', err);
              alert('Error saving CSV file: ' + err.message);
            }
          }
          
          // Set up event listeners for all buttons and links
          
          // Set up editor toggle button
          const toggleEditorBtn = document.getElementById('toggle-editor');
          if (toggleEditorBtn) {
            toggleEditorBtn.addEventListener('click', toggleEditor);
          } else {
            console.error('Toggle editor button not found');
          }
          
          // Set up save XML button
          const saveXmlBtn = document.getElementById('save-xml');
          if (saveXmlBtn) {
            saveXmlBtn.addEventListener('click', saveXmlDirectly);
          } else {
            console.error('Save XML button not found');
          }
          
          // Set up format XML button
          const formatXmlBtn = document.getElementById('format-xml');
          if (formatXmlBtn) {
            formatXmlBtn.addEventListener('click', formatXml);
          } else {
            console.error('Format XML button not found');
          }
          
          // Set up find button
          const findXmlBtn = document.getElementById('find-xml');
          if (findXmlBtn) {
            findXmlBtn.addEventListener('click', findInEditor);
          } else {
            console.error('Find XML button not found');
          }
          
          // Set up export CSV button
          const exportCsvBtn = document.getElementById('export-csv');
          if (exportCsvBtn) {
            exportCsvBtn.addEventListener('click', function() {
              console.log('Export CSV button clicked');
              saveCsvDirectly();
            });
          } else {
            console.error('Export CSV button not found');
          }
          
          // Set up XPath links - FIXED SELECTOR
          const xpathLinks = document.querySelectorAll('.xpath-link');
          console.log('Found XPath links:', xpathLinks.length);
          
          xpathLinks.forEach(function(link) {
            link.addEventListener('click', function(e) {
              console.log('XPath link clicked');
              // Prevent default link behavior
              e.preventDefault();
              
              const xpath = this.getAttribute('data-xpath');
              if (!xpath) {
                console.error('No XPath data attribute found');
                return;
              }
              
              console.log('Navigating to XPath:', xpath);
              findElementByXPath(xpath);
            });
          });
          
          // Set up cancel button for XML save dialog
          const saveDialog = document.getElementById('save-file-dialog');
          const cancelSaveButton = document.getElementById('cancel-save');
          
          if (cancelSaveButton && saveDialog) {
            cancelSaveButton.addEventListener('click', function() {
              saveDialog.style.display = 'none';
            });
          } else {
            console.warn('Save dialog or cancel button not found');
          }
          
          console.log('DOM fully loaded and JavaScript initialization completed');
        });
        ]]>
        </script>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>