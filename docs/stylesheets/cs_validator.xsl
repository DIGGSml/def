<?xml version="1.0" encoding="UTF-8"?>
<!--
    DIGGS CodeSpace Validator - XSLT Stylesheet
    
    This stylesheet validates DIGGS XML files by checking codeSpace attributes
    and their values according to the DIGGS specification. It performs the
    same checks as the original Schematron but in a single pass for better
    performance.
    
    Features:
    - Single-pass validation
    - Dictionary caching
    - Optimized XPath matching
    - Detailed error reporting
    - HTML report generation
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:g3="http://www.opengis.net/gml/3.3/ce"
    xmlns:glr="http://www.opengis.net/gml/3.3/lr"
    xmlns:glrov="http://www.opengis.net/gml/3.3/lrov"
    exclude-result-prefixes="xs diggs gml g3 glr glrov"
    version="2.0">
    
    <!-- Output HTML -->
    <xsl:output method="html" indent="yes" encoding="UTF-8"/>
    
    <!-- Global variables -->
    <xsl:variable name="urlRegex" select="'^(https?://([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}(:[0-9]+)?(/[^\s#]*)?|file:///[^\s#]*?|[^:]+)#[^\s]+$'"/>
    
    <!-- Dictionary cache to avoid repeated lookups -->
    <xsl:variable name="dictionary-cache">
        <dictionaries>
            <!-- Dictionaries will be loaded here dynamically -->
        </dictionaries>
    </xsl:variable>
    
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
                
                <!-- Process the document -->
                <xsl:variable name="validation-results">
                    <results>
                        <xsl:apply-templates select="//*[@codeSpace]" mode="validate"/>
                    </results>
                </xsl:variable>
                
                <!-- Display validation summary -->
                <div class="validation-summary">
                    <p>
                        <strong>Total elements with codeSpace:</strong> <xsl:value-of select="count(//*[@codeSpace])"/>
                    </p>
                    <p>
                        <strong>Errors:</strong> <xsl:value-of select="count($validation-results/results/*[@level='error'])"/>
                    </p>
                    <p>
                        <strong>Warnings:</strong> <xsl:value-of select="count($validation-results/results/*[@level='warning'])"/>
                    </p>
                    <p>
                        <strong>Information:</strong> <xsl:value-of select="count($validation-results/results/*[@level='info'])"/>
                    </p>
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
                    <xsl:for-each select="$validation-results/results/*">
                        <tr>
                            <xsl:attribute name="class">
                                <xsl:value-of select="@level"/>
                            </xsl:attribute>
                            <td><span class="code"><xsl:value-of select="@xpath"/></span></td>
                            <td><xsl:value-of select="@value"/></td>
                            <td><xsl:value-of select="@codeSpace"/></td>
                            <td><xsl:value-of select="upper-case(@level)"/></td>
                            <td><xsl:value-of select="text()"/></td>
                        </tr>
                    </xsl:for-each>
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
        
        <!-- Step 1: Check URL format -->
        <xsl:choose>
            <xsl:when test="not(matches($codeSpace, $urlRegex))">
                <result level="info" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                    INFO: The value of <xsl:value-of select="$element-name"/> cannot be validated. If codeSpace attribute "<xsl:value-of select="$codeSpace"/>" references an authority, be sure that the value "<xsl:value-of select="$element-value"/>" is a valid term controlled by "<xsl:value-of select="$codeSpace"/>"
                </result>
            </xsl:when>
            <xsl:otherwise>
                <!-- URL format is valid, extract parts -->
                <xsl:variable name="rawUrl" select="replace($codeSpace, '(^.*)(#.*)$', '$1')"/>
                <xsl:variable name="fragmentId" select="replace($codeSpace, '^.*#(.*)$', '$1')"/>
                
                <!-- Handle relative paths -->
                <xsl:variable name="dictionaryUrl">
                    <xsl:choose>
                        <xsl:when test="starts-with($rawUrl, 'http') or starts-with($rawUrl, 'file:///')">
                            <xsl:value-of select="$rawUrl"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="resolve-uri($rawUrl, base-uri(.))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- Step 2: Check document availability -->
                <xsl:variable name="isDocAvailable" select="doc-available($dictionaryUrl)"/>
                
                <xsl:choose>
                    <xsl:when test="not($isDocAvailable)">
                        <result level="error" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                            ERROR: The URL "<xsl:value-of select="$dictionaryUrl"/>" referenced in the codeSpace attribute could not be accessed.
                        </result>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Document is available -->
                        <xsl:variable name="document" select="doc($dictionaryUrl)"/>
                        
                        <!-- Step 3: Check if document is a dictionary -->
                        <xsl:variable name="isDictionary" select="exists($document//*[local-name() = 'Dictionary'])"/>
                        
                        <xsl:choose>
                            <xsl:when test="not($isDictionary)">
                                <result level="warning" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                                    WARNING: The resource at "<xsl:value-of select="$dictionaryUrl"/>" is not a valid DIGGS dictionary. If this value is intended to reference an authority rather than a DIGGS dictionary, be sure that the value "<xsl:value-of select="$element-value"/>" is a valid term controlled by "<xsl:value-of select="$codeSpace"/>"
                                </result>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- It's a dictionary, continue with validation -->
                                
                                <!-- Step 4: Check if definition exists -->
                                <xsl:variable name="definition" select="$document//*[local-name() = 'Definition'][@*[local-name() = 'id'] = $fragmentId]"/>
                                <xsl:variable name="hasDefinition" select="exists($definition)"/>
                                
                                <xsl:choose>
                                    <xsl:when test="not($hasDefinition)">
                                        <result level="error" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                                            ERROR: No Definition with id="<xsl:value-of select="$fragmentId"/>" found in the dictionary at "<xsl:value-of select="$dictionaryUrl"/>".
                                        </result>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- Definition exists, get source element xpaths -->
                                        <xsl:variable name="sourceElementXpaths" select="$definition//*[local-name() = 'sourceElementXpath']"/>
                                        
                                        <!-- Step 5: Check context (source element) validation -->
                                        <xsl:variable name="currentElementPath" select="$element-path"/>
                                        
                                        <!-- Check if any xpath matches the current element path -->
                                        <xsl:variable name="pathMatches">
                                            <matches>
                                                <xsl:for-each select="$sourceElementXpaths">
                                                    <xsl:variable name="xpath" select="."/>
                                                    <xsl:variable name="pathParts" select="tokenize(substring-after($xpath, '//'), '//')"/>
                                                    
                                                    <match value="{
                                                        if (count($pathParts) = 1) then
                                                            contains($currentElementPath, concat('/', $pathParts[1], '/')) or
                                                            ends-with($currentElementPath, concat('/', $pathParts[1]))
                                                        else if (count($pathParts) = 2) then
                                                            (contains($currentElementPath, concat('/', $pathParts[1], '/')) or
                                                            ends-with($currentElementPath, concat('/', $pathParts[1]))) and
                                                            (contains(substring-after($currentElementPath, concat('/', $pathParts[1], '/')),
                                                            concat('/', $pathParts[2], '/')) or
                                                            ends-with(substring-after($currentElementPath, concat('/', $pathParts[1], '/')),
                                                            concat('/', $pathParts[2])))
                                                        else
                                                            false()
                                                    }"/>
                                                </xsl:for-each>
                                            </matches>
                                        </xsl:variable>
                                        
                                        <xsl:variable name="hasMatchingPath" select="
                                            count($sourceElementXpaths) = 0 or
                                            count($pathMatches/matches/match[@value = 'true']) > 0
                                        "/>
                                        
                                        <!-- Debug info -->
                                        <xsl:variable name="debugInfo">
                                            <xsl:text>Current Path: </xsl:text><xsl:value-of select="$currentElementPath"/>
                                            <xsl:text>, Source XPaths: </xsl:text><xsl:value-of select="string-join($sourceElementXpaths, ' | ')"/>
                                            <xsl:text>, Path parts: </xsl:text>
                                            <xsl:for-each select="$sourceElementXpaths">
                                                <xsl:variable name="xpath" select="."/>
                                                <xsl:text>[</xsl:text><xsl:value-of select="$xpath"/><xsl:text>] → [</xsl:text>
                                                <xsl:value-of select="string-join(
                                                    for $part in tokenize(substring-after($xpath, '//'), '//')
                                                    return $part,
                                                    ']['
                                                )"/>
                                                <xsl:text>]; </xsl:text>
                                            </xsl:for-each>
                                            <xsl:text>, Matches: </xsl:text>
                                            <xsl:for-each select="$pathMatches/matches/match">
                                                <xsl:value-of select="position()"/>: <xsl:value-of select="@value"/>
                                                <xsl:if test="position() != last()">; </xsl:if>
                                            </xsl:for-each>
                                            <xsl:text>, hasMatchingPath: </xsl:text><xsl:value-of select="$hasMatchingPath"/>
                                        </xsl:variable>
                                        
                                        <xsl:choose>
                                            <xsl:when test="count($sourceElementXpaths) > 0 and not($hasMatchingPath)">
                                                <result level="error" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                                                    ERROR: The element <xsl:value-of select="$element-name"/> with value "<xsl:value-of select="$element-value"/>" references a definition that is not allowed at this location in the XML instance. Current path: "<xsl:value-of select="$currentElementPath"/>" Allowed paths: "<xsl:value-of select="string-join($sourceElementXpaths, ', ')"/>". Debug: <xsl:value-of select="$debugInfo"/>
                                                </result>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <!-- Context is valid, proceed with name validation -->
                                                
                                                <!-- Step 6: Check name validation -->
                                                <xsl:variable name="definitionNames" select="$definition//*[local-name() = 'name']"/>
                                                <xsl:variable name="currentValue" select="lower-case(normalize-space($element-value))"/>
                                                
                                                <xsl:variable name="hasNameMatch" select="
                                                    count($definitionNames) = 0 or
                                                    count(
                                                        for $name in $definitionNames
                                                        return
                                                            if (lower-case(normalize-space($name)) = $currentValue) then
                                                                'true'
                                                            else
                                                                ()
                                                    ) > 0
                                                "/>
                                                
                                                <xsl:if test="count($definitionNames) > 0 and not($hasNameMatch)">
                                                    <result level="warning" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                                                        WARNING: The value "<xsl:value-of select="$element-value"/>" in element <xsl:value-of select="$element-name"/> is a name that does not match "<xsl:value-of select="string-join(for $name in $definitionNames return normalize-space($name), ', ')"/>" in the referenced Definition. Be sure that "<xsl:value-of select="$element-value"/>" is a synonymous name.
                                                    </result>
                                                </xsl:if>
                                                
                                                <!-- Add debug info -->
                                                <result level="info" xpath="{$element-path}" value="{$element-value}" codeSpace="{$codeSpace}">
                                                    DEBUG: <xsl:value-of select="$debugInfo"/>
                                                </result>
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
    
</xsl:stylesheet>