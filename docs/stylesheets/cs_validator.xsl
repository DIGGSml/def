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
                    .info { color: #3498db; }
                    .warning { color: #f39c12; }
                    .error { color: #e74c3c; }
                    .success { color: #2ecc71; }
                    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
                    th { background-color: #f2f2f2; }
                    tr:hover { background-color: #f5f5f5; }
                    .validation-summary { margin-top: 20px; padding: 10px; background-color: #f8f9fa; border-radius: 4px; }
                    .code { font-family: monospace; background-color: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
                </style>
            </head>
            <body>
                <h1>DIGGS CodeSpace Validation Report</h1>
                
                <!-- Display validation summary -->
                <xsl:variable name="elementsWithCodeSpace" select="//*[@codeSpace]"/>
                
                <div class="validation-summary">
                    <p>
                        <strong>Total elements with codeSpace:</strong>
                        <xsl:value-of select="count($elementsWithCodeSpace)"/>
                    </p>
                    <!-- Error counts will be calculated during processing -->
                </div>
                
                <!-- Display validation results -->
                <table>
                    <tr>
                        <th>Element Path</th>
                        <th>Value</th>
                        <th>CodeSpace</th>
                        <th>Level</th>
                        <th>Message</th>
                    </tr>
                    <xsl:apply-templates select="//*[@codeSpace]" mode="validate"/>
                </table>
            </body>
        </html>
    </xsl:template>
    
    <!-- Validation template for elements with codeSpace -->
    <xsl:template match="*[@codeSpace]" mode="validate">
        <xsl:variable name="element" select="."/>
        <xsl:variable name="element-name" select="local-name(.)"/>
        <xsl:variable name="element-value" select="normalize-space(.)"/>
        <xsl:variable name="codeSpace" select="@codeSpace"/>
        
        <!-- Build element path for error reporting -->
        <xsl:variable name="element-path">
            <xsl:for-each select="ancestor-or-self::*">
                <xsl:text>/</xsl:text>
                <xsl:choose>
                    <xsl:when test="namespace-uri() != ''">
                        <xsl:choose>
                            <xsl:when test="namespace-uri() = 'http://diggsml.org/schema-dev'">diggs:</xsl:when>
                            <xsl:when test="namespace-uri() = 'http://www.opengis.net/gml/3.2'">gml:</xsl:when>
                            <xsl:when test="namespace-uri() = 'http://www.opengis.net/gml/3.3/ce'">g3.3:</xsl:when>
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
                    <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                    <td><xsl:value-of select="$element-value"/></td>
                    <td><xsl:value-of select="$codeSpace"/></td>
                    <td>INFO</td>
                    <td>
                        INFO: The value of <xsl:value-of select="$element-name"/> cannot be validated. 
                        If codeSpace attribute "<xsl:value-of select="$codeSpace"/>" references an authority, 
                        be sure that the value "<xsl:value-of select="$element-value"/>" is a valid term 
                        controlled by "<xsl:value-of select="$codeSpace"/>"
                    </td>
                </tr>
            </xsl:when>
            <xsl:otherwise>
                <!-- URL format is valid, extract parts -->
                <xsl:variable name="rawUrl">
                    <xsl:value-of select="substring-before($codeSpace, '#')"/>
                </xsl:variable>
                <xsl:variable name="fragmentId">
                    <xsl:value-of select="substring-after($codeSpace, '#')"/>
                </xsl:variable>
                
                <!-- Handle relative paths - simplified for XSLT 1.0 -->
                <xsl:variable name="dictionaryUrl">
                    <xsl:choose>
                        <xsl:when test="starts-with($rawUrl, 'http') or starts-with($rawUrl, 'file:///')">
                            <xsl:value-of select="$rawUrl"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- In XSLT 1.0, we don't have resolve-uri(), so we use a simpler approach -->
                            <xsl:value-of select="$rawUrl"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- Step 2: Try to access the document -->
                <xsl:variable name="dictionaryDoc" select="document($dictionaryUrl, /)"/>
                
                <xsl:choose>
                    <xsl:when test="not($dictionaryDoc)">
                        <tr class="error">
                            <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                            <td><xsl:value-of select="$element-value"/></td>
                            <td><xsl:value-of select="$codeSpace"/></td>
                            <td>ERROR</td>
                            <td>
                                ERROR: The URL "<xsl:value-of select="$dictionaryUrl"/>" referenced in the 
                                codeSpace attribute could not be accessed.
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
                                    <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                                    <td><xsl:value-of select="$element-value"/></td>
                                    <td><xsl:value-of select="$codeSpace"/></td>
                                    <td>WARNING</td>
                                    <td>
                                        WARNING: The resource at "<xsl:value-of select="$dictionaryUrl"/>" is not a valid DIGGS dictionary. 
                                        If this value is intended to reference an authority rather than a DIGGS dictionary, 
                                        be sure that the value "<xsl:value-of select="$element-value"/>" is a valid term 
                                        controlled by "<xsl:value-of select="$codeSpace"/>"
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
                                            <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                                            <td><xsl:value-of select="$element-value"/></td>
                                            <td><xsl:value-of select="$codeSpace"/></td>
                                            <td>ERROR</td>
                                            <td>
                                                ERROR: No Definition with id="<xsl:value-of select="$fragmentId"/>" found in the 
                                                dictionary at "<xsl:value-of select="$dictionaryUrl"/>".
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
                                                    <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                                                    <td><xsl:value-of select="$element-value"/></td>
                                                    <td><xsl:value-of select="$codeSpace"/></td>
                                                    <td>ERROR</td>
                                                    <td>
                                                        ERROR: The element <xsl:value-of select="$element-name"/> with value "<xsl:value-of select="$element-value"/>" 
                                                        references a definition that is not allowed at this location in the XML instance. 
                                                        Current path: "<xsl:value-of select="$currentElementPath"/>"
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
                                                        <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                                                        <td><xsl:value-of select="$element-value"/></td>
                                                        <td><xsl:value-of select="$codeSpace"/></td>
                                                        <td>WARNING</td>
                                                        <td>
                                                            WARNING: The value "<xsl:value-of select="$element-value"/>" in element 
                                                            <xsl:value-of select="$element-name"/> is a name that does not match 
                                                            the names in the referenced Definition. Be sure that 
                                                            "<xsl:value-of select="$element-value"/>" is a synonymous name.
                                                        </td>
                                                    </tr>
                                                </xsl:if>
                                                
                                                <!-- Add debug info -->
                                                <tr class="info">
                                                    <td><span class="code"><xsl:value-of select="$element-path"/></span></td>
                                                    <td><xsl:value-of select="$element-value"/></td>
                                                    <td><xsl:value-of select="$codeSpace"/></td>
                                                    <td>INFO</td>
                                                    <td>
                                                        DEBUG: Successfully validated element at path "<xsl:value-of select="$currentElementPath"/>"
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