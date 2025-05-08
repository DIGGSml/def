<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:saxon="http://saxon.sf.net"
    exclude-result-prefixes="xs map diggs gml">
    
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
        
        <message>
            <severity><xsl:value-of select="$severity"/></severity>
            <elementPath><xsl:value-of select="$elementPath"/></elementPath>
            <text><xsl:value-of select="$text"/></text>
            <xsl:if test="exists($sourceElement)">
                <source>
                    <xsl:element name="{local-name($sourceElement)}" namespace="{namespace-uri($sourceElement)}">
                        <xsl:copy-of select="$sourceElement/@*"/>
                        <xsl:value-of select="$sourceElement"/>
                    </xsl:element>
                </source>
            </xsl:if>
        </message>
    </xsl:function>
    
</xsl:stylesheet>