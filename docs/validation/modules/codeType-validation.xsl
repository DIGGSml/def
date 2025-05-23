<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs map diggs gml err">
    
    <!-- Main template for codeType validation -->
    <xsl:template name="codeTypeValidation">
        <xsl:param name="sourceDocument"/>
        
        <messageSet>
            <step>CodeType Validation</step>
            
            <!-- Step 1: Load the resource file containing codeType definitions -->
            <xsl:variable name="resourceUrl" select="'https://diggsml.org/def/validation/definedCodeTypes.xml'"/>
            
            <!-- Get the resource using the same pattern as dictionary validation -->
            <xsl:variable name="codeTypeResource" select="diggs:getResource($resourceUrl, base-uri(/))"/>
            
            <xsl:choose>
                <xsl:when test="empty($codeTypeResource)">
                    <!-- If resource cannot be loaded, create a warning message and terminate -->
                    <xsl:sequence select="diggs:createMessage(
                        'WARNING',
                        '/',
                        concat('CodeType validation could not be performed. The resource at &quot;', $resourceUrl, '&quot; could not be accessed.'),
                        /
                        )"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Step 2: Process each codeType definition in the resource -->
                    <xsl:for-each select="$codeTypeResource//codeType">
                        <xsl:variable name="currentCodeTypeDefinition" select="."/>
                        <xsl:variable name="xpathSelector" select="string(xpath)"/>
                        <xsl:variable name="dictionaryUrls" select="dictionaryURL"/>
                        
                        <!-- Step 3: Use xsl:evaluate with explicit reference to original document -->
                        <xsl:try>
                            <xsl:variable name="selectedElements" as="element()*">
                                <!-- FIX: Use $originalDocument instead of / -->
                                <xsl:evaluate context-item="$sourceDocument" xpath="$xpathSelector"/>
                            </xsl:variable>
                            
                            <!-- Step 4: Check each selected element -->
                            <xsl:for-each select="$selectedElements">
                                <xsl:variable name="currentElement" select="."/>
                                <xsl:variable name="elementPath" select="diggs:get-path(.)"/>
                                <xsl:variable name="elementName" select="name()"/>
                                <xsl:variable name="codeSpaceValue" select="@codeSpace"/>
                                
                                <xsl:choose>
                                    <!-- Check if codeSpace attribute exists -->
                                    <xsl:when test="not(@codeSpace)">
                                        <!-- Create error message for missing codeSpace -->
                                        <xsl:variable name="dictionaryList">
                                            <xsl:for-each select="$dictionaryUrls">
                                                <xsl:text>&#10;     </xsl:text>
                                                <xsl:value-of select="."/>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        
                                        <xsl:sequence select="diggs:createMessage(
                                            'ERROR',
                                            $elementPath,
                                            concat('&lt;', $elementName, '&gt; should reference a DIGGS Standard code list dictionary using a codeSpace attribute. Consider using one of these dictionaries:', $dictionaryList),
                                            $currentElement
                                            )"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- codeSpace attribute exists, check if it references a DIGGS standard dictionary -->
                                        <xsl:choose>
                                            <xsl:when test="starts-with($codeSpaceValue, 'https://diggsml.org/def/codes/')">
                                                <!-- Element passes validation - no message needed -->
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <!-- Create warning message for non-standard dictionary -->
                                                <xsl:variable name="dictionaryList">
                                                    <xsl:for-each select="$dictionaryUrls">
                                                        <xsl:text>&#10;     </xsl:text>
                                                        <xsl:value-of select="."/>
                                                    </xsl:for-each>
                                                </xsl:variable>
                                                
                                                <xsl:sequence select="diggs:createMessage(
                                                    'WARNING',
                                                    $elementPath,
                                                    concat('&lt;', $elementName, '&gt; references a custom dictionary (&quot;', $codeSpaceValue, '&quot;) which may limit interoperability. Consider using a DIGGS Standard code list dictionary:', $dictionaryList),
                                                    $currentElement
                                                    )"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            
                            <xsl:catch>
                                <!-- If xsl:evaluate fails, create an error message -->
                                <xsl:sequence select="diggs:createMessage(
                                    'WARNING',
                                    '/',
                                    concat('XPath evaluation failed for: ', $xpathSelector, ' - Error: ', $err:description),
                                    $sourceDocument
                                    )"/>
                            </xsl:catch>
                        </xsl:try>
                        
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </messageSet>
    </xsl:template>
    
</xsl:stylesheet>