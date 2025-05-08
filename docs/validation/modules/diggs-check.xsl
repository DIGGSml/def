<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Template for DIGGS structure validation -->
    <xsl:template name="diggsCheck">
        <messageSet>
            <step>DIGGS Structure</step>
            
            <!-- Check for Diggs root element regardless of namespace -->
            <xsl:variable name="rootElement" select="/*"/>
            <xsl:variable name="isDiggsRoot" select="local-name($rootElement) = 'Diggs'"/>
            
            <!-- Check for DocumentInformation element in the specific correct path -->
            <xsl:variable name="docInfoCount" select="count(/*[local-name() = 'Diggs']/*[local-name() = 'documentInformation']/*[local-name() = 'DocumentInformation'])"/>
            
            <!-- Create a custom element to use as the source in the message -->
            <xsl:variable name="sourceElement">
                <rootElement>
                    <xsl:value-of select="local-name($rootElement)"/>
                </rootElement>
            </xsl:variable>
            
            <xsl:choose>
                <!-- Check if the file has exactly one Diggs root element and one DocumentInformation element in the correct path -->
                <xsl:when test="$isDiggsRoot and $docInfoCount = 1">
                    <!-- Validation passes, set continuable to true -->
                    <continuable>true</continuable>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Validation fails, output error message using the helper function -->
                    <xsl:variable name="errorText">
                        <xsl:text>File selected for validation is not a DIggs file.</xsl:text>
                        <xsl:if test="not($isDiggsRoot)">
                            <xsl:text> Expected Diggs as root element, found '</xsl:text>
                            <xsl:value-of select="local-name($rootElement)"/>
                            <xsl:text>'.</xsl:text>
                        </xsl:if>
                        <xsl:if test="$docInfoCount != 1">
                            <xsl:text> Expected exactly 1 DocumentInformation element in the specific path /Diggs/documentInformation/DocumentInformation, found </xsl:text>
                            <xsl:value-of select="$docInfoCount"/>
                            <xsl:text>.</xsl:text>
                        </xsl:if>
                    </xsl:variable>
                    
                    <xsl:sequence select="diggs:createMessage(
                        'ERROR',
                        '/',
                        $errorText,
                        $sourceElement/*
                        )"/>
                    
                    <!-- Validation fails, set continuable to false to stop further validation -->
                    <continuable>false</continuable>
                </xsl:otherwise>
            </xsl:choose>
        </messageSet>
    </xsl:template>
</xsl:stylesheet>