<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Main template for CRS validation -->
    <xsl:template name="crsValidation">
        <xsl:param name="sourceDocument" select="/"/>
        <xsl:param name="whiteList" as="node()?"/>
        
        <messageSet>
            <step>CRS Validation</step>
            
            <!-- Select all elements that contain srsName attribute -->
            <xsl:variable name="elementsWithSrsName" select="
                $sourceDocument//*[@*[local-name() = 'srsName']]"/>
            
            <!-- Process each element with srsName attribute -->
            <xsl:for-each select="$elementsWithSrsName">
                <xsl:call-template name="validateSrsName">
                    <xsl:with-param name="element" select="."/>
                    <xsl:with-param name="sourceDocument" select="$sourceDocument"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:call-template>
            </xsl:for-each>
        </messageSet>
    </xsl:template>
    
    <!-- Template to validate individual srsName attribute -->
    <xsl:template name="validateSrsName">
        <xsl:param name="element"/>
        <xsl:param name="sourceDocument"/>
        <xsl:param name="whiteList" as="node()?"/>
        
        <xsl:variable name="elementName" select="local-name($element)"/>
        <xsl:variable name="elementPath" select="diggs:get-path($element)"/>
        <xsl:variable name="srsNameValue" select="$element/@*[local-name() = 'srsName']"/>
        
        <!-- Call isCRS function to validate the srsName value -->
        <xsl:variable name="crsResult" select="diggs:isCRS($srsNameValue, $sourceDocument, $whiteList)"/>
        
        <!-- Extract CRS definition and message from the result -->
        <xsl:variable name="crsDefinition" select="$crsResult[1]"/>
        <xsl:variable name="messageText" select="$crsResult[2]"/>
        
        <!-- Check if validation failed (empty CRS definition or non-empty message) -->
        <xsl:choose>
            <xsl:when test="not($crsDefinition/*) or $messageText != ''">
                <!-- Validation failed - write ERROR message -->
                <xsl:variable name="errorMessage">
                    <xsl:choose>
                        <xsl:when test="$messageText != ''">
                            <!-- Use the message returned by isCRS function -->
                            <xsl:value-of select="$messageText"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Fallback message if no specific message returned -->
                            <xsl:value-of select="concat('The srsName attribute value &quot;', $srsNameValue, '&quot; in &lt;', $elementName, '&gt; does not reference a valid CRS definition.')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:sequence select="
                    diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    $errorMessage,
                    $element
                    )"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Validation passed - no message needed (pass silently) -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>