<?xml version="1.0" encoding="UTF-8"?>
<!--
    Optimized DIGGS CodeSpace Validator XSLT
    
    This stylesheet validates DIGGS XML files by checking codeSpace attributes
    and their values according to the DIGGS specification. It outputs validation
    results in a structured XML format that can be processed by JavaScript.
    
    Improvements:
    - Preloads dictionaries for improved performance
    - Handles URL resolution more robustly
    - Early termination of validation when errors are found
    - More detailed error reporting
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:g3="http://www.opengis.net/gml/3.3/ce"
    xmlns:glr="http://www.opengis.net/gml/3.3/lr"
    xmlns:glrov="http://www.opengis.net/gml/3.3/lrov"
    version="1.0">
    
    <!-- Output XML -->
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <!-- Variables to help with string operations -->
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
    
    <!-- Main template -->
    <xsl:template match="/">
        <!-- First, collect all unique dictionary URLs -->
        <xsl:variable name="allCodeSpaces" select="//*[@codeSpace]/@codeSpace"/>
        
        <validationResults>
            <xsl:variable name="elementsWithCodeSpace" select="//*[@codeSpace]"/>
            <summary>
                <totalElements><xsl:value-of select="count($elementsWithCodeSpace)"/></totalElements>
                <uniqueDictionaries>
                    <xsl:call-template name="count-unique-dictionaries">
                        <xsl:with-param name="codeSpaces" select="$allCodeSpaces"/>
                        <xsl:with-param name="result" select="''"/>
                    </xsl:call-template>
                </uniqueDictionaries>
            </summary>
            
            <!-- Process all elements with codeSpace attribute -->
            <xsl:apply-templates select="//*[@codeSpace]" mode="validate"/>
        </validationResults>
    </xsl:template>
    
    <!-- Helper template to count unique dictionaries -->
    <xsl:template name="count-unique-dictionaries">
        <xsl:param name="codeSpaces"/>
        <xsl:param name="result"/>
        
        <xsl:choose>
            <xsl:when test="count($codeSpaces) = 0">
                <xsl:value-of select="count(xsl:distinct-values($result))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="current" select="$codeSpaces[1]"/>
                <xsl:variable name="dictionary">
                    <xsl:choose>
                        <xsl:when test="contains($current, '#')">
                            <xsl:value-of select="substring-before($current, '#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$current"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="newResult">
                    <xsl:choose>
                        <xsl:when test="contains($result, concat('|', $dictionary, '|'))">
                            <xsl:value-of select="$result"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($result, '|', $dictionary, '|')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:call-template name="count-unique-dictionaries">
                    <xsl:with-param name="codeSpaces" select="$codeSpaces[position() &gt; 1]"/>
                    <xsl:with-param name="result" select="$newResult"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
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
        
        <!-- Get source XML text -->
        <xsl:variable name="source-xml">
            <xsl:call-template name="get-element-xml">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Step 1: Check URL format by looking for # character -->
        <xsl:choose>
            <xsl:when test="not(contains($codeSpace, '#'))">
                <validationEntry 
                    lineNumber="{$line-number}" 
                    elementPath="{$element-path}" 
                    value="{$element-value}" 
                    codeSpace="{$codeSpace}" 
                    level="INFO"
                    severity="Information"
                    sourceXml="{$source-xml}"
                    message="The value of {$element-name} cannot be validated. If codeSpace attribute '{$codeSpace}' references an authority, be sure that the value '{$element-value}' is a valid term controlled by '{$codeSpace}'"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 2: Document availability check -->
                <xsl:variable name="dictionaryUrl" select="substring-before($codeSpace, '#')"/>
                <xsl:variable name="fragmentId" select="substring-after($codeSpace, '#')"/>
                
                <!-- Try to access the dictionary with improved error handling -->
                <xsl:variable name="dictionaryExists">
                    <xsl:choose>
                        <xsl:when test="string-length($dictionaryUrl) &gt; 0">
                            <xsl:choose>
                                <xsl:when test="document($dictionaryUrl)">true</xsl:when>
                                <xsl:otherwise>false</xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="dictionaryDoc" select="document($dictionaryUrl)"/>
                
                <xsl:choose>
                    <xsl:when test="$dictionaryExists != 'true'">
                        <validationEntry 
                            lineNumber="{$line-number}" 
                            elementPath="{$element-path}" 
                            value="{$element-value}" 
                            codeSpace="{$codeSpace}" 
                            level="ERROR"
                            severity="Error"
                            sourceXml="{$source-xml}"
                            message="The URL '{$dictionaryUrl}' referenced in the codeSpace attribute could not be accessed."/>
                        <!-- Early termination - stop validation for this element -->
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Document is available -->
                        
                        <!-- Step 3: Check if document is a dictionary -->
                        <xsl:variable name="isDictionary" select="count($dictionaryDoc//*[local-name() = 'Dictionary']) &gt; 0"/>
                        
                        <xsl:choose>
                            <xsl:when test="not($isDictionary)">
                                <validationEntry 
                                    lineNumber="{$line-number}" 
                                    elementPath="{$element-path}" 
                                    value="{$element-value}" 
                                    codeSpace="{$codeSpace}" 
                                    level="WARNING"
                                    severity="Warning"
                                    sourceXml="{$source-xml}"
                                    message="The resource at '{$dictionaryUrl}' is not a valid DIGGS dictionary. If this value is intended to reference an authority rather than a DIGGS dictionary, be sure that the value '{$element-value}' is a valid term controlled by '{$codeSpace}'"/>
                                <!-- Early termination - stop validation for this element -->
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- It's a dictionary, continue with validation -->
                                
                                <!-- Step 4: Check if definition exists -->
                                <xsl:variable name="definition" select="$dictionaryDoc//*[local-name() = 'Definition'][@*[local-name() = 'id'] = $fragmentId]"/>
                                <xsl:variable name="hasDefinition" select="count($definition) &gt; 0"/>
                                
                                <xsl:choose>
                                    <xsl:when test="not($hasDefinition)">
                                        <validationEntry 
                                            lineNumber="{$line-number}" 
                                            elementPath="{$element-path}" 
                                            value="{$element-value}" 
                                            codeSpace="{$codeSpace}" 
                                            level="ERROR"
                                            severity="Error"
                                            sourceXml="{$source-xml}"
                                            message="No Definition with id='{$fragmentId}' found in the dictionary at '{$dictionaryUrl}'."/>
                                        <!-- Early termination - stop validation for this element -->
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
                                                <validationEntry 
                                                    lineNumber="{$line-number}" 
                                                    elementPath="{$element-path}" 
                                                    value="{$element-value}" 
                                                    codeSpace="{$codeSpace}" 
                                                    level="ERROR"
                                                    severity="Error"
                                                    sourceXml="{$source-xml}"
                                                    message="The element {$element-name} with value '{$element-value}' references a definition that is not allowed at this location in the XML instance. Current path: '{$currentElementPath}'"/>
                                                <!-- Early termination - stop validation for this element -->
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
                                                
                                                <xsl:choose>
                                                    <xsl:when test="count($definitionNames) > 0 and $hasNameMatch != 'true'">
                                                        <validationEntry 
                                                            lineNumber="{$line-number}" 
                                                            elementPath="{$element-path}" 
                                                            value="{$element-value}" 
                                                            codeSpace="{$codeSpace}" 
                                                            level="WARNING"
                                                            severity="Warning"
                                                            sourceXml="{$source-xml}"
                                                            message="The value '{$element-value}' in element {$element-name} is a name that does not match the names in the referenced Definition. Be sure that '{$element-value}' is a synonymous name."/>
                                                        <!-- Continue with validation since this is just a warning -->
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <!-- Add debug info -->
                                                        <validationEntry 
                                                            lineNumber="{$line-number}" 
                                                            elementPath="{$element-path}" 
                                                            value="{$element-value}" 
                                                            codeSpace="{$codeSpace}" 
                                                            level="DEBUG"
                                                            severity="Debug"
                                                            sourceXml="{$source-xml}"
                                                            message="Successfully validated element at path '{$currentElementPath}'"/>
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
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Helper template: Extract element as XML -->
    <xsl:template name="get-element-xml">
        <xsl:param name="element"/>
        
        <xsl:variable name="element-name" select="local-name($element)"/>
        <xsl:variable name="prefix">
            <xsl:choose>
                <xsl:when test="namespace-uri($element) = 'http://diggsml.org/schema-dev'">diggs:</xsl:when>
                <xsl:when test="namespace-uri($element) = 'http://www.opengis.net/gml/3.2'">gml:</xsl:when>
                <xsl:when test="namespace-uri($element) = 'http://www.opengis.net/gml/3.3/ce'">g3:</xsl:when>
                <xsl:when test="namespace-uri($element) = 'http://www.opengis.net/gml/3.3/lr'">glr:</xsl:when>
                <xsl:when test="namespace-uri($element) = 'http://www.opengis.net/gml/3.3/lrov'">glrov:</xsl:when>
                <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Create opening tag with attributes -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$prefix"/>
        <xsl:value-of select="$element-name"/>
        
        <!-- Add attributes -->
        <xsl:for-each select="$element/@*">
            <xsl:text> </xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>="</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        
        <!-- Check if element has content -->
        <xsl:choose>
            <xsl:when test="normalize-space($element) != ''">
                <xsl:text>&gt;</xsl:text>
                <xsl:value-of select="$element"/>
                <xsl:text>&lt;/</xsl:text>
                <xsl:value-of select="$prefix"/>
                <xsl:value-of select="$element-name"/>
                <xsl:text>&gt;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> /&gt;</xsl:text>
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