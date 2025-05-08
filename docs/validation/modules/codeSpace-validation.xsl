<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Main template for codeSpace validation with parameter declaration -->
    <xsl:template name="codeSpaceValidation">
        <!-- Declare the whitelist parameter -->
        <xsl:param name="whiteList" as="node()*"/>
        
        <messageSet>
            <step>codeSpace Validation</step>
            
            <!-- Find all elements with codeSpace attribute and start validation -->
            <xsl:apply-templates select="//*[@codeSpace]" mode="step1">
                <!-- Pass the whitelist down the template chain -->
                <xsl:with-param name="whiteList" select="$whiteList"/>
            </xsl:apply-templates>
        </messageSet>
    </xsl:template>
    
    <!-- Step 1: Check if codeSpace attribute value is a URL to a dictionary definition -->
    <xsl:template match="*[@codeSpace]" mode="step1">
        <!-- Receive the whitelist parameter -->
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="codeSpaceValue" select="@codeSpace"/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        <xsl:variable name="elementPath" select="diggs:get-path(.)"/>
        
        <xsl:variable name="isValidUrl" as="xs:boolean" select="
            (starts-with($codeSpaceValue, 'http:') or
            starts-with($codeSpaceValue, 'https:') or
            starts-with($codeSpaceValue, 'file:')) or
            starts-with($codeSpaceValue, './') or
            starts-with($codeSpaceValue, '../') and
            contains($codeSpaceValue, '#')
            "/>
        
        <xsl:choose>
            <xsl:when test="not($isValidUrl)">
                <!-- Using the helper function for message creation -->
                <xsl:sequence select="diggs:createMessage(
                    'INFO',
                    $elementPath,
                    concat('The value of ', $elementName, ' cannot be validated as it does not reference a code list dictionary. If codeSpace attribute &quot;', $codeSpaceValue, '&quot; references an authority,be sure that the value &quot;', $elementValue, '&quot; is a valid term controlled by &quot;', $codeSpaceValue, '&quot;.'),
                    $currentElement
                )"/>
                <!-- Step 1 fails - no further processing for this element -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 1 passes - continue to Step 2 -->
                <xsl:apply-templates select="." mode="step2">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 2: Check if codeSpace URL passes whitelist check -->
    <xsl:template match="*[@codeSpace]" mode="step2">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        <xsl:variable name="baseUrl" select="substring-before($codeSpaceValue, '#')"/>
        
        <xsl:choose>
            <xsl:when test="not(diggs:isWhitelisted($baseUrl, $whiteList))">
                <!-- Using the helper function for message creation -->
                <xsl:sequence select="diggs:createMessage(
                    'WARNING',
                    $elementPath,
                    concat('The code list dictionary referenced for ', $elementName, ' at ', $baseUrl, ' is not on the white list of approved URL''s. Choose a DIGGS standard resource at https://diggsml.org/def/ or add this URL to the whiteList.xml parameter file (local implementations only).'),
                    $currentElement
                )"/>
                <!-- Step 2 fails - no further processing for this element -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 2 passes - continue to Step 3 -->
                <xsl:apply-templates select="." mode="step3">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 3: Check if dictionary file can be accessed -->
    <xsl:template match="*[@codeSpace]" mode="step3">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        
        <!-- Pass the document URI to getResource function -->
        <xsl:variable name="dictionaryResource" select="diggs:getResource($baseUrl, document-uri(/))"/>
        
        <xsl:choose>
            <xsl:when test="empty($dictionaryResource)">
                <!-- Using the helper function for message creation -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('The code list dictionary referenced at ', $baseUrl, ' could not be accessed.'),
                    $currentElement
                )"/>
                <!-- Step 3 fails - no further processing for this element -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 3 passes - continue to Step 4 -->
                <xsl:apply-templates select="." mode="step4">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>