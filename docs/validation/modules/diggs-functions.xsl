<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:error="http://www.w3.org/2005/xqt-errors"
    xmlns:json="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="xs map diggs gml error json">

    
    <!-- Static variable to store the whitelist document - with required select attribute -->
    <xsl:variable name="diggs:storedWhiteList" as="item()*" static="yes" select="()"/>
    
    <!-- Function to set the whitelist from the main stylesheet -->
    <xsl:function name="diggs:setWhiteList">
        <xsl:param name="whiteListDoc" as="node()*"/>
        
        <!-- This approach directly uses the whitelist parameter without 
             storing it in the static variable -->
        
        <!-- Return a dummy value - this function is called for its side effect -->
        <xsl:sequence select="true()"/>
    </xsl:function>
    
    <!-- Function to get the whitelist (not actually used) -->
    <xsl:function name="diggs:getWhiteList" as="node()*">
        <xsl:sequence select="$diggs:storedWhiteList"/>
    </xsl:function>
    
    <!-- Cache for external resources -->
    <xsl:variable name="resourceCache" select="map:merge(())"/>
    
    <!-- Capture the original XML content as a string -->
    <xsl:variable name="originalXml">
        <xsl:copy-of select="/"/>
    </xsl:variable>
    
    <!-- Helper function to generate a simplified XPath for an element -->
    <xsl:function name="diggs:get-path" as="xs:string">
        <xsl:param name="node" as="node()"/>      
        <xsl:variable name="ancestors" as="xs:string*">
            <xsl:for-each select="$node/ancestor-or-self::*">
                <xsl:variable name="name" select="name()"/>
                <xsl:variable name="position" select="count(preceding-sibling::*[name() = $name]) + 1"/>
                <xsl:value-of select="concat($name, '[', $position, ']')"/>
            </xsl:for-each>
        </xsl:variable>      
        <xsl:value-of select="concat('/', string-join($ancestors, '/'))"/>
    </xsl:function>
    
    <!-- Helper function to get resources with document URI context -->
    <xsl:function name="diggs:getResource" as="item()*">
        <xsl:param name="url" as="xs:string"/>
        <xsl:param name="sourceDocUri" as="xs:string"/>
        
        <!-- Check cache using the original URL as key -->
        <xsl:variable name="cachedResource" select="map:get($resourceCache, $url)"/>
        
        <!-- If resource is in cache, return it immediately -->
        <xsl:if test="exists($cachedResource)">
            <xsl:sequence select="$cachedResource"/>
        </xsl:if>
        
        <!-- If not in cache, proceed with resolution and loading -->
        <xsl:if test="empty($cachedResource)">
            <!-- Split URL into path and fragment -->
            <xsl:variable name="fragment" select="
                if (contains($url, '#')) then
                concat('#', substring-after($url, '#'))
                else
                ''
                "/>
            
            <xsl:variable name="pathPart" select="
                if (contains($url, '#')) then
                substring-before($url, '#')
                else
                $url
                "/>
            
            <!-- Extract directory from source document URI -->
            <xsl:variable name="sourceDocDir" select="replace($sourceDocUri, '[^/]+$', '')"/>
            
            <!-- Resolve the path -->
            <xsl:variable name="resolvedPath">
                <xsl:choose>
                    <!-- Handle absolute URLs (including http, https, and file with 3 slashes) -->
                    <xsl:when test="matches($pathPart, '^(https?:|file:///).*')">
                        <xsl:value-of select="$pathPart"/>
                    </xsl:when>
                    
                    <!-- Handle file: with fewer than 3 slashes -->
                    <xsl:when test="starts-with($pathPart, 'file:')">
                        <!-- Ensure proper format with three slashes -->
                        <xsl:value-of select="replace($pathPart, '^file:(//?)?', 'file:///')"/>
                    </xsl:when>
                    
                    <!-- Handle parent directory references (../) -->
                    <xsl:when test="starts-with($pathPart, '../')">
                        <!-- Simply count how many ../ appear at the start -->
                        <xsl:variable name="parentDirCount" as="xs:integer">
                            <xsl:choose>
                                <xsl:when test="starts-with($pathPart, '../../../')">3</xsl:when>
                                <xsl:when test="starts-with($pathPart, '../../')">2</xsl:when>
                                <xsl:when test="starts-with($pathPart, '../')">1</xsl:when>
                                <xsl:otherwise>0</xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        
                        <!-- Initialize with the source document directory -->
                        <xsl:variable name="startDir" select="$sourceDocDir"/>
                        
                        <!-- Recursively remove one directory level for each ../ -->
                        <xsl:variable name="parentDir">
                            <xsl:call-template name="diggs:remove-dir-levels">
                                <xsl:with-param name="path" select="$startDir"/>
                                <xsl:with-param name="levels" select="$parentDirCount"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <!-- Remove all ../ segments from the path -->
                        <xsl:variable name="remainingPath">
                            <xsl:choose>
                                <xsl:when test="$parentDirCount = 1">
                                    <xsl:value-of select="substring-after($pathPart, '../')"/>
                                </xsl:when>
                                <xsl:when test="$parentDirCount = 2">
                                    <xsl:value-of select="substring-after($pathPart, '../../')"/>
                                </xsl:when>
                                <xsl:when test="$parentDirCount = 3">
                                    <xsl:value-of select="substring-after($pathPart, '../../../')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$pathPart"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        
                        <!-- Construct the final path -->
                        <xsl:value-of select="concat($parentDir, $remainingPath)"/>
                    </xsl:when>
                    
                    <!-- Handle current directory references (./) -->
                    <xsl:when test="starts-with($pathPart, './')">
                        <xsl:value-of select="concat($sourceDocDir, substring($pathPart, 3))"/>
                    </xsl:when>
                    
                    <!-- Handle simple relative paths (no ./ or ../ prefix) -->
                    <xsl:when test="not(contains($pathPart, ':'))">
                        <xsl:value-of select="concat($sourceDocDir, $pathPart)"/>
                    </xsl:when>
                    
                    <!-- Fallback for other URI schemes -->
                    <xsl:otherwise>
                        <xsl:value-of select="$pathPart"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- Add fragment back to create final resolved URL -->
            <xsl:variable name="resolvedUrl" select="concat($resolvedPath, $fragment)"/>
            
            <!-- Get URL for document check (without fragment) -->
            <xsl:variable name="checkUrl" select="
                if (contains($resolvedUrl, '#')) then
                substring-before($resolvedUrl, '#')
                else
                $resolvedUrl
                "/>
            
            <!-- Improved document existence check that correctly fails for non-existent files -->
            <xsl:variable name="docAvailable" as="xs:boolean">
                <xsl:try>
                    <!-- First try with unparsed-text-available -->
                    <xsl:variable name="unparsedAvailable" select="unparsed-text-available($checkUrl)"/>
                    
                    <!-- Then try with doc-available -->
                    <xsl:variable name="docIsAvailable" select="doc-available($checkUrl)"/>
                    
                    <!-- Only pass if either check succeeds -->
                    <xsl:sequence select="$unparsedAvailable or $docIsAvailable"/>
                    
                    <xsl:catch>
                        <xsl:sequence select="false()"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:variable>
            
            <!-- Double-check for ../ references -->
            <xsl:variable name="finalDocAvailable" as="xs:boolean">
                <xsl:choose>
                    <xsl:when test="contains($url, '../') and $docAvailable">
                        <!-- Try to read a small portion of the document to validate it truly exists -->
                        <xsl:variable name="canActuallyRead">
                            <xsl:try>
                                <xsl:variable name="testRead">
                                    <xsl:choose>
                                        <xsl:when test="unparsed-text-available($checkUrl)">
                                            <xsl:value-of select="substring(unparsed-text($checkUrl), 1, 10)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="string(doc($checkUrl)/*[1]/@*[1])"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:sequence select="string-length($testRead) > 0"/>
                                <xsl:catch>
                                    <xsl:sequence select="false()"/>
                                </xsl:catch>
                            </xsl:try>
                        </xsl:variable>
                        
                        <!-- Return true only if we can actually read the document -->
                        <xsl:sequence select="$canActuallyRead = 'true'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$docAvailable"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- Only load document if it's available -->
            <xsl:variable name="docResource">
                <xsl:if test="$finalDocAvailable">
                    <xsl:try>
                        <xsl:sequence select="doc($checkUrl)"/>
                        <xsl:catch>
                            <xsl:sequence select="()"/>
                        </xsl:catch>
                    </xsl:try>
                </xsl:if>
            </xsl:variable>
            
            <!-- Store in cache using original URL as key, and return the resource -->
            <xsl:choose>
                <xsl:when test="exists($docResource/*)">
                    <xsl:variable name="newCache" select="map:put($resourceCache, $url, $docResource)"/>
                    <xsl:sequence select="$docResource"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>
    
    <!-- Backward compatibility wrapper that doesn't require sourceDocUri -->
    <xsl:function name="diggs:getResource" as="item()*">
        <xsl:param name="url" as="xs:string"/>
        
        <!-- Use static-base-uri as fallback when no document URI is provided -->
        <xsl:variable name="fallbackUri" select="static-base-uri()"/>
        <xsl:sequence select="diggs:getResource($url, $fallbackUri)"/>
    </xsl:function>
    
    <!-- Helper template to recursively remove directory levels -->
    <xsl:template name="diggs:remove-dir-levels">
        <xsl:param name="path" as="xs:string"/>
        <xsl:param name="levels" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$levels &lt;= 0">
                <!-- No more levels to remove, return the path -->
                <xsl:value-of select="$path"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Remove one directory level -->
                <xsl:variable name="newPath" select="replace($path, '[^/]+/$', '')"/>
                
                <!-- Recursively remove the next level -->
                <xsl:call-template name="diggs:remove-dir-levels">
                    <xsl:with-param name="path" select="$newPath"/>
                    <xsl:with-param name="levels" select="$levels - 1"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Helper function to check if a URL is in the whitelist -->
    <xsl:function name="diggs:isWhitelisted" as="xs:boolean">
        <xsl:param name="url" as="xs:string"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <!-- Get all pattern elements from the whitelist -->
        <xsl:variable name="urlPatterns" select="$whiteList//resource/pattern/text()"/>
        
        <!-- Return true if any pattern matches the start of the URL -->
        <xsl:variable name="result" select="
            some $pattern in $urlPatterns
            satisfies starts-with($url, normalize-space($pattern))
            "/>
        
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <!-- Helper function to write messages to the result tree -->
    <xsl:function name="diggs:createMessage">
        <xsl:param name="severity" as="xs:string"/>        <!-- ERROR, WARNING, INFO -->
        <xsl:param name="elementPath" as="xs:string"/>     <!-- XPath to the element being validated -->
        <xsl:param name="text" as="xs:string"/>            <!-- Message text content -->
        <xsl:param name="sourceElement" as="node()?"/>     <!-- Source element to include in the message -->
        
        <!-- Debug output 
        <xsl:message>DEBUG: createMessage called with severity: <xsl:value-of select="$severity"/></xsl:message>
        <xsl:message>DEBUG: elementPath: <xsl:value-of select="$elementPath"/></xsl:message>
        <xsl:message>DEBUG: text: <xsl:value-of select="$text"/></xsl:message>
        <xsl:message>DEBUG: sourceElement exists: <xsl:value-of select="exists($sourceElement)"/></xsl:message>
        -->
        
        <message>
            <severity><xsl:value-of select="$severity"/></severity>
            <elementPath><xsl:value-of select="$elementPath"/></elementPath>
            <text><xsl:value-of select="$text"/></text>
            <xsl:if test="exists($sourceElement) and $sourceElement instance of element()">
                <source>
                    <xsl:try>
                        <xsl:choose>
                            <!-- If element has child elements, just output the element name -->
                            <xsl:when test="$sourceElement/*">
                                <xsl:value-of select="local-name($sourceElement)"/>
                            </xsl:when>
                            <!-- If element has no child elements, copy normally -->
                            <xsl:otherwise>
                                <xsl:element name="{local-name($sourceElement)}" namespace="{namespace-uri($sourceElement)}">
                                    <xsl:copy-of select="$sourceElement/@*"/>
                                    <xsl:value-of select="$sourceElement"/>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:catch>
                            <xsl:message>DEBUG: Error creating source element in createMessage</xsl:message>
                            <xsl:element name="error">
                                <xsl:attribute name="message">Failed to process source element</xsl:attribute>
                            </xsl:element>
                        </xsl:catch>
                    </xsl:try>
                </source>
            </xsl:if>
        </message>
    </xsl:function>

    <xsl:function name="diggs:evaluateXPathMatch" as="xs:boolean">
        <xsl:param name="documentNode" as="node()"/> <!-- Document root or context node -->
        <xsl:param name="xpathExpression" as="xs:string"/> <!-- XPath expression to evaluate -->
        <xsl:param name="nodeToCheck" as="node()"/> <!-- Node to check for in results -->
        <xsl:param name="isRelative" as="xs:boolean"/> <!-- Whether the XPath is relative to nodeToCheck -->
        
        <!-- Create a namespace-aware evaluation context -->
        <xsl:variable name="namespaceNode">
            <ns:context xmlns:ns="http://temp/ns">
                <xsl:namespace name="diggs">http://diggsml.org/schema-dev</xsl:namespace>
                <xsl:namespace name="gml">http://www.opengis.net/gml/3.2</xsl:namespace>
            </ns:context>
        </xsl:variable>
        
        <!-- For absolute paths, use original evaluation with namespaces -->
        <xsl:choose>
            <xsl:when test="not($isRelative)">
                <!-- This preserves the original behavior for absolute paths, which was working -->
                <xsl:variable name="directMatch" as="xs:boolean">
                    <xsl:choose>
                        <!-- For regular global XPath expressions -->
                        <xsl:when test="starts-with($xpathExpression, '//')">
                            <xsl:variable name="components" select="tokenize(replace($xpathExpression, '^//', ''), '//')"/>
                            <xsl:variable name="lastComponent" select="$components[last()]"/>
                            <xsl:variable name="elementName" select="
                                if (contains($lastComponent, ':')) 
                                then substring-after($lastComponent, ':') 
                                else $lastComponent
                                "/>
                            <xsl:variable name="elementNamespace" select="
                                if (contains($lastComponent, 'diggs:')) 
                                then 'http://diggsml.org/schema-dev'
                                else (if (contains($lastComponent, 'gml:'))
                                then 'http://www.opengis.net/gml/3.2'
                                else '*')
                                "/>
                            
                            <!-- Check if the basic element type matches -->
                            <xsl:sequence select="
                                local-name($nodeToCheck) = $elementName and 
                                (namespace-uri($nodeToCheck) = $elementNamespace or $elementNamespace = '*')
                                "/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="false()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- If the direct match indicates a potential match, do more detailed checking -->
                <xsl:choose>
                    <xsl:when test="$directMatch">
                        <!-- Additional ancestry checks based on XPath components -->
                        <xsl:variable name="needsAncestryCheck" as="xs:boolean" 
                            select="contains($xpathExpression, '//') and contains($xpathExpression, ':')"/>
                        
                        <xsl:choose>
                            <xsl:when test="$needsAncestryCheck">
                                <!-- Parse the components to check ancestors -->
                                <xsl:variable name="components" select="tokenize(replace($xpathExpression, '^//', ''), '//')"/>
                                
                                <!-- Check ancestors if there are multiple components -->
                                <xsl:choose>
                                    <xsl:when test="count($components) > 1">
                                        <xsl:variable name="ancestorChecks" as="xs:boolean*">
                                            <xsl:for-each select="$components[position() lt last()]">
                                                <xsl:variable name="ancestorName" select="
                                                    if (contains(., ':')) 
                                                    then substring-after(., ':') 
                                                    else .
                                                    "/>
                                                <xsl:variable name="ancestorNS" select="
                                                    if (contains(., 'diggs:')) 
                                                    then 'http://diggsml.org/schema-dev'
                                                    else (if (contains(., 'gml:'))
                                                    then 'http://www.opengis.net/gml/3.2'
                                                    else '*')
                                                    "/>
                                                
                                                <xsl:sequence select="
                                                    exists($nodeToCheck/ancestor::*[
                                                    local-name() = $ancestorName and 
                                                    (namespace-uri() = $ancestorNS or $ancestorNS = '*')
                                                    ])
                                                    "/>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        
                                        <!-- All ancestor checks must pass -->
                                        <xsl:sequence select="every $check in $ancestorChecks satisfies $check"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:sequence select="true()"/> <!-- No ancestor checks needed -->
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="true()"/> <!-- No ancestry checks needed -->
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- If direct match fails, try with dynamic evaluation -->
                        <xsl:try>
                            <xsl:variable name="matchNodes" as="node()*">
                                <xsl:evaluate xpath="$xpathExpression" 
                                    context-item="$documentNode" 
                                    namespace-context="$namespaceNode/*"/>
                            </xsl:variable>
                            
                            <xsl:sequence select="$nodeToCheck = $matchNodes"/>
                            
                            <xsl:catch>
                                <xsl:sequence select="false()"/>
                            </xsl:catch>
                        </xsl:try>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- For relative paths, convert to local-name() based expressions for reliability -->
                <xsl:variable name="localizedXPath">
                    <xsl:analyze-string select="$xpathExpression" regex="(ancestor::|parent::|child::|//|/)?([a-zA-Z0-9_]+):([a-zA-Z0-9_]+)">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                            <xsl:text>*[local-name()='</xsl:text>
                            <xsl:value-of select="regex-group(3)"/>
                            <xsl:text>']</xsl:text>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:value-of select="."/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                
                <!-- Try to evaluate the relative XPath -->
                <xsl:try>
                    <!-- For relative XPath, evaluate with nodeToCheck as context -->
                    <xsl:variable name="matchNodes">
                        <xsl:evaluate xpath="$localizedXPath" context-item="$nodeToCheck"/>
                    </xsl:variable>
                    
                    <!-- If we get here, there were results (success) -->
                    <xsl:sequence select="exists($matchNodes/*)"/>
                    
                    <xsl:catch>
                        <!-- Try alternate approach - use the original xpath with namespace context -->
                        <xsl:try>
                            <xsl:variable name="matchNodes">
                                <xsl:evaluate xpath="$xpathExpression" 
                                    context-item="$nodeToCheck" 
                                    namespace-context="$namespaceNode/*"/>
                            </xsl:variable>
                            
                            <xsl:sequence select="exists($matchNodes)"/>
                            
                            <xsl:catch>
                                <!-- Handle common patterns - e.g., check for ancestor nodes -->
                                <xsl:choose>
                                    <xsl:when test="contains($xpathExpression, 'ancestor') and contains($xpathExpression, 'procedure')">
                                        <!-- Extract the target element name -->
                                        <xsl:variable name="targetName">
                                            <xsl:analyze-string select="$xpathExpression" regex="([^/]+)$">
                                                <xsl:matching-substring>
                                                    <xsl:value-of select="
                                                        if (contains(regex-group(1), ':'))
                                                        then substring-after(regex-group(1), ':')
                                                        else regex-group(1)
                                                        "/>
                                                </xsl:matching-substring>
                                            </xsl:analyze-string>
                                        </xsl:variable>
                                        
                                        <!-- Check for target element in ancestors -->
                                        <xsl:sequence select="
                                            exists($nodeToCheck/ancestor::*[local-name()='Test']
                                            //*[local-name()='procedure']
                                            //*[local-name()=$targetName])
                                            "/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:sequence select="false()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:catch>
                        </xsl:try>
                    </xsl:catch>
                </xsl:try>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
    Function to extract values from a JSON API response based on a key
    Parameters:
      - url: The URL of the API endpoint
      - key: The name of the key to extract values for
    Returns:
      - A sequence of string values
  -->
    <xsl:function name="diggs:extractJsonValues" as="xs:string*">
        <xsl:param name="url" as="xs:string"/>
        <xsl:param name="key" as="xs:string"/>
        <xsl:variable name="response">
            <xsl:try>
                <xsl:sequence select="unparsed-text($url)"/>
                <xsl:catch>
                    <xsl:message terminate="no">Error fetching from URL: <xsl:value-of select="$url"/> - <xsl:value-of select="$error:description"/></xsl:message>
                    <xsl:sequence select="''"/>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>
        
        <xsl:if test="string-length($response) > 0">
            <xsl:variable name="jsonXml">
                <xsl:try>
                    <xsl:sequence select="json-to-xml($response)"/>
                    <xsl:catch>
                        <xsl:message terminate="no">Error parsing JSON: <xsl:value-of select="$error:description"/></xsl:message>
                        <xsl:sequence select="''"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:variable>
            
            <xsl:choose>
                <!-- Case 1: The key exists as an array directly in the root -->
                <xsl:when test="$jsonXml//json:array[@key = $key]">
                    <xsl:for-each select="$jsonXml//json:array[@key = $key]/*">
                        <xsl:choose>
                            <xsl:when test="self::json:string">
                                <xsl:sequence select="string()"/>
                            </xsl:when>
                            <xsl:when test="self::json:number">
                                <xsl:sequence select="string()"/>
                            </xsl:when>
                            <xsl:when test="self::json:boolean">
                                <xsl:sequence select="string()"/>
                            </xsl:when>
                            <xsl:when test="self::json:null">
                                <xsl:sequence select="'null'"/>
                            </xsl:when>
                            <!-- Handle objects in the array that have the key we want -->
                            <xsl:when test="self::json:map and ./*[@key = $key]">
                                <xsl:sequence select="./*[@key = $key]/string()"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                
                <!-- Case 2: Array directly in the root object (no specific key) -->
                <xsl:when test="$jsonXml/json:array">
                    <xsl:for-each select="$jsonXml/json:array/json:map">
                        <xsl:if test="./*[@key = $key]">
                            <xsl:sequence select="./*[@key = $key]/string()"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                
                <!-- Case 3: The key appears in multiple objects at any level -->
                <xsl:otherwise>
                    <xsl:for-each select="$jsonXml/descendant::*[@key = $key]">
                        <xsl:sequence select="string()"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>

</xsl:stylesheet>