<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <xsl:template match="/">
    <html>
      <head>
        <title>DIGGS Semantic Validation Report</title>
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
/* CSS Variables for consistent colors and spacing */
:root {
    /* Severity colors */
    --color-error-bg: #fdd5d1;
    --color-error-border: #b02819;
    --color-warning-bg: #fde5be;
    --color-warning-border: #9c7008;
    --color-info-bg: #d1e7f2;
    --color-info-border: #0b68a7;
    --color-success-bg: #e9f7ef;
    --color-success-border: #2ecc71;
    
    /* Banner specific variations */
    --color-error-banner: #f5b7b1;
    --color-warning-banner: #fae5d3;
    --color-info-banner: #d4e6f1;
    --color-success-banner: #d4efdf;

    /* Highlight Colors */
    --color-highlight-bg: rgba(111, 172, 202, 0.5); /* Blue-gray with 50% transparency for selection */
    --color-search-match: rgba(255, 140, 0, 0.3); /* Light orange for search matches */
    
    /* Common spacing values */
    --spacing-xs: 0px;
    --spacing-sm: 2px;
    --spacing-md: 5px;
    --spacing-lg: 10px;
    --spacing-xl: 20px;
    --spacing-xxl: 30px;
    
    /* Table dimensions */
    --col-1-width: 80px;
    --col-2-width: 100px;
    --col-3-width: 150px;
    --col-4-width: 600px;
}

/* Base styles */
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 0;
    background-color: #f5f5f5;
    color: #333;
    line-height: 1.6;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    background-color: white;
    padding: 0 var(--spacing-xxl) var(--spacing-xl);
    border-radius: 8px;
    box-shadow: 0 2px 15px rgba(0, 0, 0, 0.3);
}

/* Header styles */
h1 {
    color: #2c3e50;
    text-align: center;
    margin-bottom: var(--spacing-xs);
    padding-bottom: var(--spacing-xs);
    width: 100%;
}

.header-container {
    position: relative;
    text-align: center;
    border-bottom: 2px solid #f0f0f0;
    padding-bottom: var(--spacing-xs);
    margin-top: var(--spacing-xs);
    margin-bottom: var(--spacing-md);
    height: auto;
}

.header-logo {
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 150px;
}

/* Validation result styles - base classes for colors */
.error {
    background-color: var(--color-error-bg);
    border-left: 4px solid var(--color-error-border);
}

.warning {
    background-color: var(--color-warning-bg);
    border-left: 4px solid var(--color-warning-border);
}

.info {
    background-color: var(--color-info-bg);
    border-left: 4px solid var(--color-info-border);
}

.success {
    background-color: var(--color-success-bg);
    border-left: 4px solid var(--color-success-border);
}

/* Summary banner - override background colors */
.summary-banner {
    padding: var(--spacing-xs);
    margin: var(--spacing-sm);
    text-align: center;
    border-radius: 4px;
    font-weight: bold;
    font-size: 18px;
}

.summary-banner.success { background-color: var(--color-success-banner); }
.summary-banner.info { background-color: var(--color-info-banner); }
.summary-banner.warning { background-color: var(--color-warning-banner); }
.summary-banner.error { background-color: var(--color-error-banner); }

/* Table styles */
.table-container {
    max-height: 350px;
    overflow-y: auto;
    margin-bottom: var(--spacing-md);
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: var(--spacing-xs);
    font-size: 13px;
    table-layout: fixed;
    line-height: 1.2;
}

/* Column widths */
table th:nth-child(1), table td:nth-child(1) { width: var(--col-1-width); }
table th:nth-child(2), table td:nth-child(2) { width: var(--col-2-width); }
table th:nth-child(3), table td:nth-child(3) { width: var(--col-3-width); }
table th:nth-child(4), table td:nth-child(4) { width: var(--col-4-width); }
table th:nth-child(5), table td:nth-child(5) { width: auto; }

th, td {
    padding: 8px;
    text-align: left;
    border-bottom: 1px solid black;
    vertical-align: middle;
    word-wrap: break-word;
    overflow-wrap: break-word;
    line-height: 1.1;
}

/* Headers */
th {
    background-color: #f2f2f2;
    position: sticky;
    top: 0;
    z-index: 10;
    white-space: nowrap;
    padding: 5px 8px
    ;
}

/* Severity badges */
.severity-badge {
    display: inline-block;
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: bold;
    color: white;
    margin: 0 3px;
    line-height: 1;
}

.severity-badge.error { background-color: var(--color-error-border); }
.severity-badge.warning { background-color: var(--color-warning-border); }
.severity-badge.info { background-color: var(--color-info-border); }

/* XML content styles */
/* Source XML in table - sans-serif and transparent background */
table td pre.source-xml {
    font-family: sans-serif;
    font-size: inherit;
    white-space: pre-wrap;
    word-wrap: break-word;
    overflow-wrap: break-word;
    word-break: break-word;
    background-color: transparent;
    padding: 8px;
    margin: 0;
    display: inline;
    line-height: 1.1;
    text-indent:0
}

/* Source XML outside table (editor box) - monospace */
.source-xml {
    font-family: monospace;
    font-size: inherit;
    white-space: pre-wrap;
    word-break: break-all;
    background-color: #f5f5f5;
    padding: 0;
    border-radius: 4px;
    margin: 0;
    max-width: 100%;
    overflow-x: auto;
    overflow-wrap: break-word;
}

/* Controls and filter sections */
.controls {
    display: flex;
    justify-content: space-between;
    margin-top: var(--spacing-md);
    padding: var(--spacing-sm);
    background-color: #f8f9fa;
    border-radius: 4px;
    position: relative;
}

.filter-controls {
    display: flex;
    align-items: center;
    width: 100%;
    justify-content: center;
}

.section-title {
    font-weight: bold;
    margin-right: var(--spacing-xl);
    font-size: 16px;
    text-align: left;
    position: absolute;
    left: var(--spacing-sm);
}

.export-controls {
    position: absolute;
    right: var(--spacing-sm);
}

/* Common button styles */
.button-common {
    padding: 5px 10px;
    background-color: #3498db;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.button-common:hover {
    background-color: #2980b9;
}

.export-button {
    padding: 5px 10px;
    background-color: #3498db;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    margin-left: var(--spacing-lg);
    white-space: nowrap;
}

.export-button:hover {
    background-color: #2980b9;
}

/* Validation summary section */
.validation-summary {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: var(--spacing-xs);
    padding: var(--spacing-sm);
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
    margin-top: var(--spacing-xs);
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
    height: 350px;
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
/* Current line highlighting */
.CodeMirror-activeline-background {
background-color: rgba(255, 240, 220, 0.3); /* Light orange with transparency */
}

/* All search matches - make sure to use !important to override any conflicting styles */
.CodeMirror-matchingbracket,
.CodeMirror-matchhighlight, 
.cm-matchhighlight {
background-color: var(--color-search-match) !important; /* Light orange */
color: inherit !important;
}

/* Regular matching brackets */
.CodeMirror-matchingbracket {
color: inherit !important;
}

/* The current search match - these are the critical selectors */
.CodeMirror-selectedtext,
.cm-searching,
.CodeMirror-searching,
span.cm-searching,
.CodeMirror-focused .CodeMirror-selectedtext {
background-color: var(--color-highlight-bg) !important; /* Same as regular selection */
color: black !important;
text-decoration: none !important;
border-radius: 2px;
}

/* Regular selection */
.CodeMirror-selected {
background-color: var(--color-highlight-bg) !important;
}

/* XPath link styles */
.xpath-link {
    color: #3498db;
    text-decoration: underline;
    cursor: pointer;
}

.xpath-link:hover {
    color: #2980b9;
}

/* Tooltip styling */
.tooltip {
    position: relative;
    display: inline-block;
}

.tooltip .tooltiptext {
    visibility: hidden;
    width: auto;
    max-width: 500px;
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
            <h1>DIGGS Semantic Validation Report</h1>
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
              <xsl:when test="$warningCount > 0">Result: Possible Incompatibilities. Evaluate
                warnings and address potential interoperability issues.</xsl:when>
              <xsl:when test="$infoCount > 0">Result: Success! Please review INFO
                messages.</xsl:when>
              <xsl:otherwise>Result: Success! No issues detected.</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <div class="summary-banner {$summaryClass}">
            <xsl:value-of select="$summaryMessage"/>
          </div>

          <!-- Modified controls section to include title and center filter -->
          <div class="controls">
            <div class="filter-controls">
              <span class="section-title">Validation Report</span>
              <label for="severity-filter">Filter by severity:</label>
              <select id="severity-filter">
                <option value="all">All</option>
                <option value="error">Errors</option>
                <option value="warning">Warnings</option>
                <option value="info">Info</option>
              </select>
            </div>

            <div class="export-controls">
              <button id="export-csv" class="export-button">Save Report as CSV</button>
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

        <!-- CodeMirror Library Scripts -->
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/codemirror.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/mode/xml/xml.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/edit/matchbrackets.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/xml-fold.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/edit/matchtags.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/selection/active-line.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/search.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/searchcursor.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/jump-to-line.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/search/match-highlighter.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/dialog/dialog.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/foldcode.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/fold/foldgutter.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.5/addon/display/placeholder.min.js"></script>

        <!-- JavaScript for functionality -->
        <script>
<![CDATA[
document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM content loaded - initializing application');
  
  // Editor management object to centralize initialization and state
  const EditorManager = {
    // State properties
    instance: null,
    initialized: false,
    visible: false,
    persistentMarker: null, // Store reference to persistent highlight marker
    
    /**
     * Gets the CodeMirror instance, initializing it if needed
     * @param {boolean} [showEditor=false] - Whether to show the editor if it's hidden
     * @returns {CodeMirror|null} - The CodeMirror instance or null if initialization failed
     */
    getEditor: function(showEditor = false) {
      // If we need to show the editor and it's not visible, show it
      if (showEditor && !this.visible) {
        this.toggleVisibility(true);
      }
      
      // If not initialized, initialize
      if (!this.initialized) {
        this.initialize();
      }
      
      return this.instance;
    },
    
    /**
     * Initialize the CodeMirror editor
     * @returns {CodeMirror|null} - The CodeMirror instance or null if initialization failed
     */
    initialize: function() {
      if (this.initialized && this.instance) {
        this.refresh();
        return this.instance;
      }
      
      console.log('Initializing CodeMirror editor');
      const editor = document.getElementById('xml-editor');
      if (!editor) {
        console.error('XML editor element not found');
        return null;
      }
      
      try {
        // Create CodeMirror instance
        this.instance = CodeMirror.fromTextArea(editor, {
          mode: 'application/xml',
          lineNumbers: true,
          matchBrackets: true,
          autoCloseTags: true,
          matchTags: {bothTags: true},
          indentUnit: 4,
          tabSize: 4,
          smartIndent: true,
          lineWrapping: true,
          theme: 'eclipse',
          styleActiveLine: true,
          foldGutter: true,
          gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
          extraKeys: {
            "Ctrl-Space": "autocomplete",
            "Ctrl-Q": function(cm) { cm.foldCode(cm.getCursor()); },
            "Ctrl-F": "findPersistent",
            "Tab": function(cm) {
              // Insert spaces instead of tab character
              const spaces = Array(cm.getOption("indentUnit") + 1).join(" ");
              cm.replaceSelection(spaces);
            }
          }
        });
        
        // Set up cursor position tracking
        if (this.instance) {
          this.instance.on('cursorActivity', this.updateCursorPosition);
          this.initialized = true;
          
          // Ensure CodeMirror is refreshed when shown
          setTimeout(() => this.refresh(), 50);
          return this.instance;
        }
        
        return null;
      } catch (error) {
        console.error('Error initializing CodeMirror:', error);
        alert('Error initializing the XML editor. Some features may be limited.');
        return null;
      }
    },
    
    /**
     * Toggle editor visibility
     * @param {boolean} [show] - Force show (true) or hide (false)
     * @returns {boolean} - Whether the editor is now visible
     */
    toggleVisibility: function(show = null) {
      const editorBody = document.getElementById('editor-body');
      if (!editorBody) {
        console.error('Editor body not found');
        return false;
      }
      
      // If show parameter is provided, set visibility accordingly
      if (show !== null) {
        if (show) {
          editorBody.classList.add('open');
        } else {
          editorBody.classList.remove('open');
        }
      } else {
        // Otherwise toggle visibility
        editorBody.classList.toggle('open');
      }
      
      // Update state
      this.visible = editorBody.classList.contains('open');
      
      // If becoming visible, ensure initialization and refresh
      if (this.visible) {
        if (!this.initialized) {
          this.initialize();
        } else {
          this.refresh();
        }
      } else {
        // If hiding, clear any persistent highlights
        if (this.persistentMarker) {
          if (Array.isArray(this.persistentMarker)) {
            this.persistentMarker.forEach(marker => {
              if (marker) marker.clear();
            });
          } else if (this.persistentMarker.clear) {
            this.persistentMarker.clear();
          }
          this.persistentMarker = null;
        }
      }
      
      console.log('Editor toggled, visible:', this.visible);
      return this.visible;
    },
    
    /**
     * Refresh the CodeMirror instance to ensure proper rendering
     */
    refresh: function() {
      if (this.instance) {
        // Use timeout to ensure DOM updates first
        setTimeout(() => {
          this.instance.refresh();
          console.log('CodeMirror refreshed');
        }, 10);
      }
    },
    
    /**
     * Update cursor position in status bar
     */
    updateCursorPosition: function() {
      const cursorPosition = document.getElementById('cursor-position');
      if (!cursorPosition) return;
      
      const cursor = EditorManager.instance.getCursor();
      cursorPosition.textContent = `Line: ${cursor.line + 1}, Column: ${cursor.ch + 1}`;
    },
    
    /**
     * Format the XML content in the editor
     * @returns {boolean} - Success status
     */
    formatXml: function() {
      const editor = this.getEditor();
      if (!editor) return false;
      
      try {
        // Get the current XML content
        let xmlContent = editor.getValue();
        
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
        editor.setValue(formattedXml);
        
        // Put cursor at the beginning
        editor.setCursor(0, 0);
        
        console.log('XML formatted successfully');
        return true;
      } catch (error) {
        console.error('Error formatting XML:', error);
        alert('There was an error formatting the XML. Please check if your XML is valid.');
        return false;
      }
    },
    
    /**
     * Find text in the editor
     * @returns {boolean} - Success status
     */
    findInEditor: function() {
      const editor = this.getEditor(true); // Show editor if needed
      if (!editor) return false;
      
      // Use CodeMirror's built-in search functionality
      editor.execCommand('findPersistent');
      return true;
    }
  };
  
  //Function to find and select text based on View Element link in report record
function findElementByXPath(xpath) {
  console.log('Finding element with XPath:', xpath);
  
  // Get the editor, showing it if needed
  const editor = EditorManager.getEditor(true);
  if (!editor) {
    console.error('Could not initialize editor for XPath navigation');
    return false;
  }
  
  // Clear any existing selection before starting a new search
  editor.setCursor(editor.getCursor());
  
  // Parse the XPath to handle position indicators
  const xmlContent = editor.getValue();
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
    const startPos = editor.posFromIndex(searchPos);
    const endPosition = editor.posFromIndex(endPos);
    
    // Select the element in CodeMirror - this is all we need!
    editor.setSelection(startPos, endPosition);
    
    // Calculate line positions for better centering
    const selectionHeight = endPosition.line - startPos.line;
    const visibleLines = Math.floor(350 / editor.defaultTextHeight()) - 4; // Estimate visible lines in 350px - buffer
    
    // Scroll to show the selection
    if (selectionHeight > visibleLines) {
      // For large selections, focus on the start of the selection with some padding above
      const paddingLines = Math.min(Math.floor(visibleLines * 0.3), 5); // 30% of visible area or max 5 lines
      const targetLine = Math.max(0, startPos.line - paddingLines);
      
      // Use scrollTo instead of scrollIntoView for more control
      const targetPos = editor.heightAtLine(targetLine, "local");
      editor.scrollTo(null, targetPos);
    } else {
      // For smaller selections that fit in the window, center it
      const middleLine = Math.floor((startPos.line + endPosition.line) / 2);
      
      // Calculate the ideal position
      const middleHeight = editor.heightAtLine(middleLine, "local");
      const windowMiddle = editor.getScrollInfo().clientHeight / 2;
      const targetPos = middleHeight - windowMiddle;
      
      // Ensure we don't scroll beyond document boundaries
      const maxScroll = editor.getScrollInfo().height - editor.getScrollInfo().clientHeight;
      const scrollPos = Math.max(0, Math.min(targetPos, maxScroll));
      
      // Apply the scroll
      editor.scrollTo(null, scrollPos);
    }
    
    // Set up a one-time listener to clear the selection when the user interacts
    const clearSelectionOnInteraction = () => {
      editor.setCursor(editor.getCursor()); // This clears the selection
      editor.off('cursorActivity', clearSelectionOnInteraction);
    };
    
    editor.on('cursorActivity', clearSelectionOnInteraction);
    
    console.log('Element found and selected in editor');
    return true;
  } else {
    console.log('Element not found in XML content');
    alert('Could not find the specified element. The XML structure may have changed.');
    return false;
  }
}

  /**
   * Directly save XML file using File System Access API with fallback to direct download
   * @returns {Promise<boolean>} True if save was successful
   */
  async function saveXmlDirectly() {
    try {
      // Get the editor from the manager
      const editor = EditorManager.getEditor();
      if (!editor) {
        alert('Please open the editor first.');
        return false;
      }
      
      // Get original filename and prepare default save name
      const fileInfoSpan = document.querySelector('.file-info span');
      if (!fileInfoSpan) {
        console.error('File info span not found');
        alert('Error: Could not determine filename');
        return false;
      }
      
      // Prepare filename
      const originalFileName = fileInfoSpan.textContent.trim();
      let suggestedName = 'edited_' + originalFileName;
      
      // Ensure proper file extension
      if (!suggestedName.endsWith('.xml') && !suggestedName.endsWith('.diggs')) {
        suggestedName += '.xml';
      }
      
      // Get XML content from CodeMirror
      const xmlContent = editor.getValue();
      
      // Try to use File System Access API if available
      if ('showSaveFilePicker' in window) {
        try {
          console.log('Using File System Access API');
          
          const opts = {
            suggestedName: suggestedName,
            types: [{
              description: 'XML Files',
              accept: {
                'application/xml': ['.xml', '.diggs']
              }
            }]
          };
          
          // Show native file picker dialog
          const fileHandle = await window.showSaveFilePicker(opts);
          
          // Create a writable stream and write content
          const writable = await fileHandle.createWritable();
          await writable.write(xmlContent);
          await writable.close();
          
          console.log('XML file saved successfully via File System Access API');
          return true;
        } catch (err) {
          console.error('Error using File System Access API:', err);
          
          // If user cancelled, just return
          if (err.name === 'AbortError') {
            console.log('User cancelled the file save operation');
            return false;
          }
          
          // Fall back to direct download
          console.log('Falling back to direct download');
          return downloadFile(xmlContent, suggestedName, 'application/xml');
        }
      } else {
        // Fall back to direct download
        console.log('File System Access API not supported, using direct download');
        return downloadFile(xmlContent, suggestedName, 'application/xml');
      }
    } catch (err) {
      console.error('Error in save operation:', err);
      alert('Error saving XML file: ' + err.message);
      return false;
    }
  }
  
  /**
   * Directly save CSV report using File System Access API with fallback to direct download
   * @returns {Promise<boolean>} True if save was successful
   */
  async function saveCsvDirectly() {
    try {
      // Get original filename and prepare default save name
      const fileInfoSpan = document.querySelector('.file-info span');
      if (!fileInfoSpan) {
        console.error('File info span not found');
        alert('Error: Could not determine filename');
        return false;
      }
      
      // Prepare filename
      const originalFileName = fileInfoSpan.textContent.trim();
      let suggestedName = originalFileName.replace(/\.[^/.]+$/, '') + '_validation_report.csv';
      
      // Ensure proper file extension
      if (!suggestedName.endsWith('.csv')) {
        suggestedName += '.csv';
      }
      
      // Generate CSV content
      const csvData = generateCsvContent();
      if (!csvData || csvData.length === 0) {
        console.error('Failed to generate CSV content');
        alert('Error: No validation data available to export');
        return false;
      }
      
      // Try to use File System Access API if available
      if ('showSaveFilePicker' in window) {
        try {
          console.log('Using File System Access API for CSV');
          
          const opts = {
            suggestedName: suggestedName,
            types: [{
              description: 'CSV Files',
              accept: {
                'text/csv': ['.csv']
              }
            }]
          };
          
          // Show native file picker dialog
          const fileHandle = await window.showSaveFilePicker(opts);
          
          // Create a writable stream and write content
          const writable = await fileHandle.createWritable();
          await writable.write(csvData);
          await writable.close();
          
          console.log('CSV file saved successfully via File System Access API');
          return true;
        } catch (err) {
          console.error('Error using File System Access API for CSV:', err);
          
          // If user cancelled, just return
          if (err.name === 'AbortError') {
            console.log('User cancelled the CSV file save operation');
            return false;
          }
          
          // Fall back to direct download
          console.log('Falling back to direct download for CSV');
          return downloadFile(csvData, suggestedName, 'text/csv;charset=utf-8;');
        }
      } else {
        // Fall back to direct download
        console.log('File System Access API not supported, using direct download for CSV');
        return downloadFile(csvData, suggestedName, 'text/csv;charset=utf-8;');
      }
    } catch (err) {
      console.error('Error in CSV save operation:', err);
      alert('Error saving CSV file: ' + err.message);
      return false;
    }
  }
  
  /**
   * Helper function for direct file download when File System Access API is unavailable
   * @param {string} content - File content to download
   * @param {string} filename - Suggested filename
   * @param {string} mimeType - MIME type of the file
   * @returns {boolean} True if download was initiated successfully
   */
  function downloadFile(content, filename, mimeType) {
    try {
      // Create blob and download link
      const blob = new Blob([content], { type: mimeType });
      const url = URL.createObjectURL(blob);
      
      // Create and trigger download
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      
      // Clean up
      URL.revokeObjectURL(url);
      console.log(`File "${filename}" downloaded via direct method`);
      
      return true;
    } catch (err) {
      console.error('Error in download:', err);
      alert('Could not download the file: ' + err.message);
      return false;
    }
  }
  
  /**
   * Function to generate CSV content from the validation table
   * @returns {string} CSV content
   */
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
  
  /**
   * Filter table rows by severity
   * @param {string} severity - Severity to filter by ('all', 'error', 'warning', 'info')
   */
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
  
  // Set up event listeners for all interactive elements
  function setupEventListeners() {
    console.log('Setting up event listeners');
    
    // Editor toggle button
    const toggleEditorBtn = document.getElementById('toggle-editor');
    if (toggleEditorBtn) {
      toggleEditorBtn.addEventListener('click', () => EditorManager.toggleVisibility());
    } else {
      console.error('Toggle editor button not found');
    }
    
    // Save XML button
    const saveXmlBtn = document.getElementById('save-xml');
    if (saveXmlBtn) {
      saveXmlBtn.addEventListener('click', saveXmlDirectly);
    } else {
      console.error('Save XML button not found');
    }
    
    // Format XML button
    const formatXmlBtn = document.getElementById('format-xml');
    if (formatXmlBtn) {
      formatXmlBtn.addEventListener('click', () => EditorManager.formatXml());
    } else {
      console.error('Format XML button not found');
    }
    
    // Find button
    const findXmlBtn = document.getElementById('find-xml');
    if (findXmlBtn) {
      findXmlBtn.addEventListener('click', () => EditorManager.findInEditor());
    } else {
      console.error('Find XML button not found');
    }
    
    // Export CSV button
    const exportCsvBtn = document.getElementById('export-csv');
    if (exportCsvBtn) {
      exportCsvBtn.addEventListener('click', () => saveCsvDirectly());
    } else {
      console.error('Export CSV button not found');
    }
    
    // Set up XPath links
    const xpathLinks = document.querySelectorAll('.xpath-link');
    console.log('Found XPath links:', xpathLinks.length);
    
    xpathLinks.forEach(link => {
      link.addEventListener('click', e => {
        e.preventDefault();
        const xpath = link.getAttribute('data-xpath');
        if (xpath) {
          console.log('Navigating to XPath:', xpath);
          findElementByXPath(xpath);
        } else {
          console.error('No XPath data attribute found');
        }
      });
    });
    
    // Set up severity filter
    const severityFilter = document.getElementById('severity-filter');
    if (severityFilter) {
      severityFilter.addEventListener('change', function() {
        filterBySeverity(this.value);
      });
    } else {
      console.error('Severity filter dropdown not found');
    }
    
    console.log('Event listeners set up successfully');
  }
  
  // Initialize everything
  setupEventListeners();
  
  // Initial filter
  const severityFilter = document.getElementById('severity-filter');
  if (severityFilter) {
    filterBySeverity(severityFilter.value);
  } else {
    console.error('Severity filter dropdown not found');
  }
  
  console.log('Initialization complete');
});
]]>
        </script>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>