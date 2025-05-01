<?xml version="1.0" encoding="UTF-8"?>
<!--
    DIGGS CodeSpace Validator - XSLT 1.0 Stylesheet
    
    This stylesheet validates DIGGS XML files by checking codeSpace attributes
    and their values according to the DIGGS specification. It's a conversion
    of the XSLT 2.0 version to be compatible with XSLT 1.0 processors.
    
    Features:
    - Single-pass validation
    - Dictionary caching
    - HTML report generation
    - Line number estimation in error messages
    - Severity levels for messages
    - Filtering capabilities
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:g3="http://www.opengis.net/gml/3.3/ce"
    xmlns:glr="http://www.opengis.net/gml/3.3/lr"
    xmlns:glrov="http://www.opengis.net/gml/3.3/lrov"
    version="1.0">
    
    <!-- Output HTML -->
    <xsl:output method="html" indent="yes" encoding="UTF-8"/>
    
    <!-- Variables to help with string operations -->
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
    
    <!-- Main template -->
    <xsl:template match="/">
        <html>
            <head>
                <title>DIGGS CodeSpace Validation Report</title>
                <style type="text/css">
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    h1 { color: #2c3e50; }
                    .info { color: #3498db; background-color: #e8f4fc; border-left: 4px solid #3498db; }
                    .warning { color: #f39c12; background-color: #fef5e7; border-left: 4px solid #f39c12; }
                    .error { color: #e74c3c; background-color: #fdedeb; border-left: 4px solid #e74c3c; }
                    .success { color: #2ecc71; background-color: #e9f7ef; border-left: 4px solid #2ecc71; }
                    .debug { color: #7f8c8d; background-color: #f8f9f9; border-left: 4px solid #7f8c8d; display: none; }
                    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
                    th { background-color: #f2f2f2; position: sticky; top: 0; z-index: 10; }
                    tr:hover { background-color: #f5f5f5; }
                    .validation-summary { margin-top: 20px; padding: 15px; background-color: #f8f9fa; border-radius: 4px; border-left: 4px solid #2c3e50; }
                    .code { font-family: monospace; background-color: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
                    .element-path { max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
                    .element-path:hover { overflow: visible; white-space: normal; }
                    .controls { display: flex; justify-content: space-between; margin: 15px 0; padding: 10px; background-color: #f8f9fa; border-radius: 4px; }
                    .filter-controls, .debug-controls { display: flex; align-items: center; gap: 10px; }
                    .filter-controls select { padding: 5px; border-radius: 4px; border: 1px solid #ddd; }
                    .toggle-switch { position: relative; display: inline-block; width: 50px; height: 24px; }
                    .toggle-switch input { opacity: 0; width: 0; height: 0; }
                    .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #ccc; transition: .4s; border-radius: 24px; }
                    .slider:before { position: absolute; content: ""; height: 16px; width: 16px; left: 4px; bottom: 4px; background-color: white; transition: .4s; border-radius: 50%; }
                    input:checked + .slider { background-color: #3498db; }
                    input:checked + .slider:before { transform: translateX(26px); }
                    .line-number { color: #7f8c8d; font-size: 12px; }
                    .copy-button { background-color: transparent; border: none; cursor: pointer; color: #3498db; padding: 2px 5px; font-size: 12px; }
                    .copy-button:hover { color: #2980b9; }
                    .export-buttons { margin-top: 15px; text-align: right; }
                    .export-button { padding: 5px 10px; background-color: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer; margin-left: 5px; }
                </style>
                <script>
                    // Copy to clipboard functionality
                    function copyToClipboard(text) {
                        navigator.clipboard.writeText(text).then(function() {
                            // Success
                            const button = event.target;
                            const originalText = button.textContent;
                            button.textContent = 'Copied!';
                            setTimeout(function() {
                                button.textContent = originalText;
                            }, 1500);
                        });
                    }
                    
                    // Filter results by level
                    function filterResults() {
                        const levelFilter = document.getElementById('level-filter').value;
                        
                        // Apply filters
                        if (levelFilter === 'all') {
                            document.querySelectorAll('tr').forEach(row => {
                                if (!row.classList.contains('debug') || document.getElementById('debug-toggle').checked) {
                                    row.style.display = '';
                                }
                            });
                        } else {
                            document.querySelectorAll('tr').forEach(row => {
                                if (row.classList.contains(levelFilter)) {
                                    row.style.display = '';
                                } else if (!row.classList.contains('header-row')) {
                                    row.style.display = 'none';
                                }
                            });
                        }
                        
                        // Update summary
                        updateSummary();
                    }
                    
                    // Toggle debug info
                    function toggleDebug() {
                        const debugToggle = document.getElementById('debug-toggle');
                        
                        // Apply to iframe content
                        const debugRows = document.querySelectorAll('tr.debug');
                        debugRows.forEach(row => {
                            row.style.display = debugToggle.checked ? '' : 'none';
                        });
                        
                        // Update summary
                        updateSummary();
                    }
                    
                    // Update validation summary
                    function updateSummary() {
                        const errors = document.querySelectorAll('tr.error:not([style*="display: none"])').length;
                        const warnings = document.querySelectorAll('tr.warning:not([style*="display: none"])').length;
                        const infos = document.querySelectorAll('tr.info:not([style*="display: none"])').length;
                        const debugs = document.querySelectorAll('tr.debug:not([style*="display: none"])').length;
                        
                        const summary = `Found ${errors} errors, ${warnings} warnings, ${infos} information messages${debugs > 0 ? ` and ${debugs} debug messages` : ''}.`;
                        document.getElementById('summary-text').textContent = summary;
                    }
                </script>
            </head>
            <body>
                <h1>DIGGS CodeSpace Validation Report</h1>
                
                <!-- Filter controls -->
                <div class="controls">
                    <div class="filter-controls">
                        <label for="level-filter">Filter by level:</label>
                        <select id="level-filter" onchange="filterResults()">
                            <option value="all">All</option>
                            <option value="error">Errors</option>
                            <option value="warning">Warnings</option>
                            <option value="info">Info</option>
                        </select>
                    </div>
                    <div class="debug-controls">
                        <label for="debug-toggle">Show debug info:</label>
                        <label class="toggle-switch">
                            <input type="checkbox" id="debug-toggle" onchange="toggleDebug()"/>
                            <span class="slider"></span>
                        </label>
                    </div>
                </div>
                
                <!-- Display validation summary -->
                <xsl:variable name="elementsWithCodeSpace" select="//*[@codeSpace]"/>
                <xsl:variable name="errorCount" select="count(//*[@codeSpace][not(contains(@codeSpace, '#'))] | //*[@codeSpace][contains(@codeSpace, '#')][not(document(substring-before(@codeSpace, '#'), /))] | //*[@codeSpace][contains(@codeSpace, '#')][document(substring-before(@codeSpace, '#'), /)][not(document(substring-before(@codeSpace, '#'), /)//*[local-name() = 'Definition'][@*[local-name() = 'id'] = substring-after(current()/@codeSpace, '#')])])"/>
                <xsl:variable name="warningCount" select="count(//*[@codeSpace][contains(@codeSpace, '#')][document(substring-before(@codeSpace, '#'), /)][not(document(substring-before(@codeSpace, '#'), /)//*[local-name() = 'Dictionary'])])"/>
                
                <div class="validation-summary">
                    <p>
                        <strong>Total elements with codeSpace:</strong>
                        <xsl:value-of select="count($elementsWithCodeSpace)"/>
                    </p>
                    <p id="summary-text">
                        <strong>Summary:</strong> Results will be shown after filtering
                    </p>
                </div>
                
                <!-- Display validation results -->
                <table>
                    <tr class="header-row">
                        <th>Line #</th>
                        <th>Element Path</th>
                        <th>Value</th>
                        <th>CodeSpace</th>
                        <th>Level</th>
                        <th>Message</th>
                        <th>Actions</th>
                    </tr>
                    <xsl:apply-templates select="//*[@codeSpace]" mode="validate"/>
                </table>
                
                <!-- Initialize summary after page load -->
                <script>
                    document.addEventListener('DOMContentLoaded', function() {
                        updateSummary();
                    });
                </script>
            </body>
        </html>
    </xsl:template>
    
    <!-- Validation template for elements with codeSpace -->
    <xsl:template match="*[@codeSpace]" mode="validate">
        <xsl:variable name="element" select="."/>
        <xsl:variable name="element-name" select="local-name(.)"/>
        <xsl:variable name="element-value" select="normalize-space(.)"/>
        <xsl:variable name="codeSpace" select="@codeSpace"/>
        
        <!-- Calculate approximate line number for reporting -->
        <xsl:variable name="line-number">
            <xsl:number level="any" count="*"/>
        </xsl:variable>
        
        <!-- Build element path for error reporting -->
        <xsl:variable name="element-path">
            <xsl:for-each select="ancestor-or-self::*">
                <xsl:text>/</xsl:text>
                <xsl:choose>
                    <xsl:when test="namespace-uri() != ''">
                        <xsl:choose>
                            <xsl:when test="namespace-uri() = 'http://diggsml.org/schema-dev'">diggs:</xsl:when>
                            <xsl:when test="namespace-uri() = 'http://www.opengis.net/gml/3.2'">gml:</xsl:when>
                            <xsl:when test="namespace-uri() = 'http://www.opengis.net/gml/3.3/ce'">g3:</xsl:when>
                            <xsl:when test="namespace-uri() = 'http://www.opengis.net/gml/3.3/lr'">glr:</xsl:when>
                            <xsl:when test="namespace-uri() = 'http://www.opengis.net/gml/3.3/lrov'">glrov:</xsl:when>
                            <xsl:otherwise></xsl:otherwise>
                        </xsl:choose>
                        <xsl:value-of select="local-name()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="local-name()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- Step 1: Check URL format by looking for # character -->
        <xsl:choose>
            <xsl:when test="not(contains($codeSpace, '#'))">
                <tr class="info">
                    <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                    <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                    <td><xsl:value-of select="$element-value"/></td>
                    <td><xsl:value-of select="$codeSpace"/></td>
                    <td>INFO</td>
                    <td>
                        The value of <xsl:value-of select="$element-name"/> cannot be validated. 
                        If codeSpace attribute "<xsl:value-of select="$codeSpace"/>" references an authority, 
                        be sure that the value "<xsl:value-of select="$element-value"/>" is a valid term 
                        controlled by "<xsl:value-of select="$codeSpace"/>"
                    </td>
                    <td>
                        <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                    </td>
                </tr>
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 2: Document availability check -->
                <xsl:variable name="dictionaryUrl" select="substring-before($codeSpace, '#')"/>
                <xsl:variable name="fragmentId" select="substring-after($codeSpace, '#')"/>
                
                <xsl:variable name="dictionaryDoc" select="document($dictionaryUrl, /)"/>
                
                <xsl:choose>
                    <xsl:when test="not($dictionaryDoc)">
                        <tr class="error">
                            <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                            <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                            <td><xsl:value-of select="$element-value"/></td>
                            <td><xsl:value-of select="$codeSpace"/></td>
                            <td>ERROR</td>
                            <td>
                                The URL "<xsl:value-of select="$dictionaryUrl"/>" referenced in the 
                                codeSpace attribute could not be accessed.
                            </td>
                            <td>
                                <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                            </td>
                        </tr>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Document is available -->
                        
                        <!-- Step 3: Check if document is a dictionary -->
                        <xsl:variable name="isDictionary" select="count($dictionaryDoc//*[local-name() = 'Dictionary']) > 0"/>
                        
                        <xsl:choose>
                            <xsl:when test="not($isDictionary)">
                                <tr class="warning">
                                    <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                                    <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                                    <td><xsl:value-of select="$element-value"/></td>
                                    <td><xsl:value-of select="$codeSpace"/></td>
                                    <td>WARNING</td>
                                    <td>
                                        The resource at "<xsl:value-of select="$dictionaryUrl"/>" is not a valid DIGGS dictionary. 
                                        If this value is intended to reference an authority rather than a DIGGS dictionary, 
                                        be sure that the value "<xsl:value-of select="$element-value"/>" is a valid term 
                                        controlled by "<xsl:value-of select="$codeSpace"/>"
                                    </td>
                                    <td>
                                        <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                                    </td>
                                </tr>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- It's a dictionary, continue with validation -->
                                
                                <!-- Step 4: Check if definition exists -->
                                <xsl:variable name="definition" select="$dictionaryDoc//*[local-name() = 'Definition'][@*[local-name() = 'id'] = $fragmentId]"/>
                                <xsl:variable name="hasDefinition" select="count($definition) > 0"/>
                                
                                <xsl:choose>
                                    <xsl:when test="not($hasDefinition)">
                                        <tr class="error">
                                            <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                                            <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                                            <td><xsl:value-of select="$element-value"/></td>
                                            <td><xsl:value-of select="$codeSpace"/></td>
                                            <td>ERROR</td>
                                            <td>
                                                No Definition with id="<xsl:value-of select="$fragmentId"/>" found in the 
                                                dictionary at "<xsl:value-of select="$dictionaryUrl"/>".
                                            </td>
                                            <td>
                                                <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                                            </td>
                                        </tr>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- Definition exists, get source element xpaths -->
                                        <xsl:variable name="sourceElementXpaths" select="$definition//*[local-name() = 'sourceElementXpath']"/>
                                        
                                        <!-- Step 5: Check context (source element) validation -->
                                        <xsl:variable name="currentElementPath" select="$element-path"/>
                                        
                                        <!-- Check if sourceElementXpaths is empty or if any match the currentElementPath -->
                                        <xsl:variable name="hasMatchingPath">
                                            <xsl:choose>
                                                <xsl:when test="count($sourceElementXpaths) = 0">true</xsl:when>
                                                <xsl:otherwise>
                                                    <!-- In XSLT 1.0, we use a recursive approach to check paths -->
                                                    <xsl:call-template name="check-paths">
                                                        <xsl:with-param name="currentPath" select="$currentElementPath"/>
                                                        <xsl:with-param name="sourceXpaths" select="$sourceElementXpaths"/>
                                                    </xsl:call-template>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        
                                        <xsl:choose>
                                            <xsl:when test="$hasMatchingPath != 'true'">
                                                <tr class="error">
                                                    <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                                                    <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                                                    <td><xsl:value-of select="$element-value"/></td>
                                                    <td><xsl:value-of select="$codeSpace"/></td>
                                                    <td>ERROR</td>
                                                    <td>
                                                        The element <xsl:value-of select="$element-name"/> with value "<xsl:value-of select="$element-value"/>" 
                                                        references a definition that is not allowed at this location in the XML instance. 
                                                        Current path: "<xsl:value-of select="$currentElementPath"/>"
                                                    </td>
                                                    <td>
                                                        <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <!-- Context is valid, proceed with name validation -->
                                                
                                                <!-- Step 6: Check name validation -->
                                                <xsl:variable name="definitionNames" select="$definition//*[local-name() = 'name']"/>
                                                <xsl:variable name="currentValue">
                                                    <xsl:call-template name="to-lowercase">
                                                        <xsl:with-param name="text" select="normalize-space($element-value)"/>
                                                    </xsl:call-template>
                                                </xsl:variable>
                                                
                                                <xsl:variable name="hasNameMatch">
                                                    <xsl:choose>
                                                        <xsl:when test="count($definitionNames) = 0">true</xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:call-template name="check-names">
                                                                <xsl:with-param name="currentValue" select="$currentValue"/>
                                                                <xsl:with-param name="defNames" select="$definitionNames"/>
                                                            </xsl:call-template>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:variable>
                                                
                                                <xsl:if test="count($definitionNames) > 0 and $hasNameMatch != 'true'">
                                                    <tr class="warning">
                                                        <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                                                        <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                                                        <td><xsl:value-of select="$element-value"/></td>
                                                        <td><xsl:value-of select="$codeSpace"/></td>
                                                        <td>WARNING</td>
                                                        <td>
                                                            The value "<xsl:value-of select="$element-value"/>" in element 
                                                            <xsl:value-of select="$element-name"/> is a name that does not match 
                                                            the names in the referenced Definition. Be sure that 
                                                            "<xsl:value-of select="$element-value"/>" is a synonymous name.
                                                        </td>
                                                        <td>
                                                            <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                                                        </td>
                                                    </tr>
                                                </xsl:if>
                                                
                                                <!-- Add debug info -->
                                                <tr class="debug">
                                                    <td class="line-number">~<xsl:value-of select="$line-number"/></td>
                                                    <td><span class="code element-path"><xsl:value-of select="$element-path"/></span></td>
                                                    <td><xsl:value-of select="$element-value"/></td>
                                                    <td><xsl:value-of select="$codeSpace"/></td>
                                                    <td>DEBUG</td>
                                                    <td>
                                                        Successfully validated element at path "<xsl:value-of select="$currentElementPath"/>"
                                                    </td>
                                                    <td>
                                                        <button class="copy-button" onclick="copyToClipboard('{$element-path}')">Copy Path</button>
                                                    </td>
                                                </tr>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Helper template: Convert text to lowercase -->
    <xsl:template name="to-lowercase">
        <xsl:param name="text"/>
        <xsl:value-of select="translate($text, $uppercase, $lowercase)"/>
    </xsl:template>
    
    <!-- Helper template: Check if any sourceXpath matches the currentPath -->
    <xsl:template name="check-paths">
        <xsl:param name="currentPath"/>
        <xsl:param name="sourceXpaths"/>
        <xsl:param name="position" select="1"/>
        
        <xsl:choose>
            <xsl:when test="$position > count($sourceXpaths)">false</xsl:when>
            <xsl:otherwise>
                <xsl:variable name="currentXpath" select="$sourceXpaths[$position]"/>
                <xsl:variable name="xpath">
                    <xsl:value-of select="$currentXpath"/>
                </xsl:variable>
                
                <!-- Simplistic path matching for XSLT 1.0 -->
                <xsl:variable name="pathMatch">
                    <xsl:choose>
                        <!-- If the XPath starts with //, we only need to check for the element name -->
                        <xsl:when test="starts-with($xpath, '//')">
                            <xsl:variable name="pathElement" select="substring-after($xpath, '//')"/>
                            <xsl:variable name="searchPattern" select="concat('/', $pathElement, '/')"/>
                            <xsl:variable name="endPattern" select="concat('/', $pathElement)"/>
                            
                            <xsl:choose>
                                <xsl:when test="contains($currentPath, $searchPattern)">true</xsl:when>
                                <xsl:when test="substring($currentPath, string-length($currentPath) - string-length($endPattern) + 1) = $endPattern">true</xsl:when>
                                <xsl:otherwise>false</xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:choose>
                    <xsl:when test="$pathMatch = 'true'">true</xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="check-paths">
                            <xsl:with-param name="currentPath" select="$currentPath"/>
                            <xsl:with-param name="sourceXpaths" select="$sourceXpaths"/>
                            <xsl:with-param name="position" select="$position + 1"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Helper template: Check if any definition name matches the current value -->
    <xsl:template name="check-names">
        <xsl:param name="currentValue"/>
        <xsl:param name="defNames"/>
        <xsl:param name="position" select="1"/>
        
        <xsl:choose>
            <xsl:when test="$position > count($defNames)">false</xsl:when>
            <xsl:otherwise>
                <xsl:variable name="currentName">
                    <xsl:call-template name="to-lowercase">
                        <xsl:with-param name="text" select="normalize-space($defNames[$position])"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:choose>
                    <xsl:when test="$currentName = $currentValue">true</xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="check-names">
                            <xsl:with-param name="currentValue" select="$currentValue"/>
                            <xsl:with-param name="defNames" select="$defNames"/>
                            <xsl:with-param name="position" select="$position + 1"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>