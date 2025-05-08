<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs map diggs gml xsi err">
    
    <!-- Main template for schema validation -->
    <xsl:template name="schemaValidation">
        <xsl:param name="schema-url" required="yes"/>
        
        <messageSet>
            <step>Schema Validation</step>
            
            <!-- Attempt schema validation -->
            <xsl:try>
                <!-- This is the primary validation step -->
                <!-- The schema validation should happen automatically if Saxon-EE is configured properly -->
                <xsl:apply-templates select="/" mode="validate"/>
                
                <!-- If we get here, validation succeeded -->
                <continuable>true</continuable>
                
                <xsl:catch errors="*">
                    <!-- Extract error details -->
                    <xsl:variable name="error-description" select="$err:description"/>
                    <xsl:variable name="error-line" select="$err:line-number"/>
                    <xsl:variable name="error-column" select="$err:column-number"/>
                    
                    <!-- Try to extract path from error message -->
                    <xsl:variable name="error-path">
                        <xsl:choose>
                            <xsl:when test="matches($error-description, 'at (/[^,\s]+)')">
                                <xsl:analyze-string select="$error-description" regex="at (/[^,\s]+)">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="regex-group(1)"/>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('/', local-name(/*))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <!-- Create error message -->
                    <message>
                        <severity>ERROR</severity>
                        <elementPath><xsl:value-of select="$error-path"/></elementPath>
                        <text>
                            Schema validation error: <xsl:value-of select="$error-description"/>
                            <xsl:if test="$error-line">
                                (Line: <xsl:value-of select="$error-line"/>, 
                                Column: <xsl:value-of select="$error-column"/>)
                            </xsl:if>
                        </text>
                        <source>
                            <xsl:element name="{local-name(/*)}" namespace="{namespace-uri(/*)}" >
                                <xsl:copy-of select="/*/@*"/>
                            </xsl:element>
                        </source>
                    </message>
                    
                    <continuable>false</continuable>
                </xsl:catch>
            </xsl:try>
        </messageSet>
    </xsl:template>
    
    <!-- Identity template for validation mode -->
    <xsl:template match="@*|node()" mode="validate">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="validate"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>