<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Main template for geometry validation -->
    <xsl:template name="geometryValidation">
        <xsl:param name="sourceDocument" select="/"/>
        
        <messageSet>
            <step>Geometry Validation</step>
            
            <!-- Select all geometry elements by local-name -->
            <xsl:variable name="geometryElements" select="
                $sourceDocument//*[local-name() = 'LinearExtent' or 
                local-name() = 'MultiPointLocation' or 
                local-name() = 'MultiCurve' or 
                local-name() = 'Solid' or 
                local-name() = 'PointLocation' or 
                local-name() = 'PlanarObservationRepresentation' or 
                local-name() = 'PlanarSurface' or 
                local-name() = 'MultiPlanarSurface' or 
                local-name() = 'RectifiedGrid']"/>
            
            <!-- Process each geometry element -->
            <xsl:for-each select="$geometryElements">
                <xsl:call-template name="validateGeometryElement">
                    <xsl:with-param name="element" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </messageSet>
    </xsl:template>
    
    <!-- Template to validate individual geometry element -->
    <xsl:template name="validateGeometryElement">
        <xsl:param name="element"/>
        
        <xsl:variable name="elementName" select="local-name($element)"/>
        <xsl:variable name="elementPath" select="diggs:get-path($element)"/>
        
        <!-- Test 1: Element has both attributes → pass silently -->
        <xsl:variable name="elementHasBoth" select="
            exists($element/@srsName) and exists($element/@srsDimension)"/>
        
        <xsl:choose>
            <xsl:when test="$elementHasBoth">
                <!-- Pass silently - no message -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Test 2: Element fails Test 1 but has ancestor that has both srs attributes → pass silently -->
                <xsl:variable name="ancestorHasBoth" select="
                    some $ancestor in $element/ancestor::* satisfies 
                    (exists($ancestor/@srsName) and exists($ancestor/@srsDimension))"/>
                
                <xsl:choose>
                    <xsl:when test="$ancestorHasBoth">
                        <!-- Pass silently - no message -->
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Test 3: Element fails Test 2 but has at least one child element that has both srs attributes → write INFO message -->
                        <xsl:variable name="childHasBoth" select="
                            some $child in $element//* satisfies 
                            (exists($child/@srsName) and exists($child/@srsDimension))"/>
                        
                        <xsl:choose>
                            <xsl:when test="$childHasBoth">
                                <!-- Write WARNING message -->
                                <xsl:sequence select="
                                    diggs:createMessage(
                                    'WARNING',
                                    $elementPath,
                                    concat('Geometry object &lt;', $elementName, '&gt; should contain valid SRS attributes, but instead they are found in child elements, Best practice is to place srsName and srsDimension in the parent geometry object.'),
                                    $element
                                    )"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- Test 4: Element fails Test 3 → write ERROR -->
                                <xsl:sequence select="
                                    diggs:createMessage(
                                    'ERROR',
                                    $elementPath,
                                    concat('Geometry object &lt;', $elementName, '&gt; is missing required srsName and srsDimension attributes. Both attributes must be present together in the object itself, or in a parent geometry object.'),
                                    $element
                                    )"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>