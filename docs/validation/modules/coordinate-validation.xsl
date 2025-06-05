<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Main template for coordinate validation -->
    <xsl:template name="coordinateValidation">
        <xsl:param name="sourceDocument" select="/"/>
        
        <messageSet>
            <step>Coordinate Validation</step>
            
            <!-- Select all elements that contain srsDimension attribute -->
            <xsl:variable name="elementsWithSrsDimension" select="
                $sourceDocument//*[@*[local-name() = 'srsDimension']]"/>
            
            <!-- Process each element with srsDimension attribute -->
            <xsl:for-each select="$elementsWithSrsDimension">
                <xsl:call-template name="validateSrsDimension">
                    <xsl:with-param name="element" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </messageSet>
    </xsl:template>
    
    <!-- Template to validate individual srsDimension attribute -->
    <xsl:template name="validateSrsDimension">
        <xsl:param name="element"/>
        
        <xsl:variable name="elementName" select="local-name($element)"/>
        <xsl:variable name="elementPath" select="diggs:get-path($element)"/>
        <xsl:variable name="srsDimensionValue" select="xs:integer($element/@*[local-name() = 'srsDimension'])"/>
        
        <!-- Check if the element itself is pos or posList -->
        <xsl:choose>
            <xsl:when test="$elementName = 'pos' or $elementName = 'posList'">
                <!-- Validate the element itself -->
                <xsl:call-template name="validateCoordinateElement">
                    <xsl:with-param name="coordinateElement" select="$element"/>
                    <xsl:with-param name="srsDimension" select="$srsDimensionValue"/>
                    <xsl:with-param name="parentPath" select="$elementPath"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- Find descendant pos or posList elements -->
                <xsl:variable name="descendantCoordinateElements" select="
                    $element//*[local-name() = 'pos' or local-name() = 'posList']"/>
                
                <!-- Validate each descendant coordinate element -->
                <xsl:for-each select="$descendantCoordinateElements">
                    <xsl:call-template name="validateCoordinateElement">
                        <xsl:with-param name="coordinateElement" select="."/>
                        <xsl:with-param name="srsDimension" select="$srsDimensionValue"/>
                        <xsl:with-param name="parentPath" select="$elementPath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to validate individual pos or posList element -->
    <xsl:template name="validateCoordinateElement">
        <xsl:param name="coordinateElement"/>
        <xsl:param name="srsDimension" as="xs:integer"/>
        <xsl:param name="parentPath"/>
        
        <xsl:variable name="coordinateElementName" select="local-name($coordinateElement)"/>
        <xsl:variable name="coordinateElementPath" select="diggs:get-path($coordinateElement)"/>
        <xsl:variable name="coordinateText" select="normalize-space($coordinateElement)"/>
        
        <!-- Skip empty elements -->
        <xsl:if test="$coordinateText != ''">
            <!-- Tokenize the coordinate values by whitespace -->
            <xsl:variable name="coordinateValues" select="tokenize($coordinateText, '\s+')"/>
            <xsl:variable name="valueCount" select="count($coordinateValues)"/>
            
            <!-- Validate based on element type -->
            <xsl:choose>
                <xsl:when test="$coordinateElementName = 'pos'">
                    <!-- For pos elements: valueCount must equal srsDimension -->
                    <xsl:if test="$valueCount != $srsDimension">
                        <xsl:sequence select="
                            diggs:createMessage(
                            'ERROR',
                            $coordinateElementPath,
                            concat('The &lt;pos&gt; element contains ', $valueCount, ' coordinate values but the srsDimension attribute specifies ', $srsDimension, '. The number of coordinate values in a pos element must equal the srsDimension value.'),
                            $coordinateElement
                            )"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$coordinateElementName = 'posList'">
                    <!-- For posList elements: valueCount must be >= 2*srsDimension and evenly divisible by srsDimension -->
                    <xsl:variable name="minimumValues" select="2 * $srsDimension"/>
                    <xsl:variable name="isEvenlyDivisible" select="$valueCount mod $srsDimension = 0"/>
                    
                    <xsl:choose>
                        <xsl:when test="$valueCount &lt; $minimumValues">
                            <xsl:sequence select="
                                diggs:createMessage(
                                'ERROR',
                                $coordinateElementPath,
                                concat('The &lt;posList&gt; element contains ', $valueCount, ' coordinate values but requires a minimum of ', $minimumValues, ' values (2 × srsDimension of ', $srsDimension, ') to define at least one complete coordinate tuple.'),
                                $coordinateElement
                                )"/>
                        </xsl:when>
                        <xsl:when test="not($isEvenlyDivisible)">
                            <xsl:sequence select="
                                diggs:createMessage(
                                'ERROR',
                                $coordinateElementPath,
                                concat('The &lt;posList&gt; element contains ', $valueCount, ' coordinate values, which is not evenly divisible by the srsDimension value of ', $srsDimension, '. The number of coordinate values must be a multiple of srsDimension to form complete coordinate tuples.'),
                                $coordinateElement
                                )"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Validation passed - no message needed (pass silently) -->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>