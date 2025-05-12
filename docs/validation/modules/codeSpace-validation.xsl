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
                    concat('Check 1&#10;The value of ', $elementName, ' cannot be validated as it does not reference a code list dictionary. If codeSpace attribute &quot;', $codeSpaceValue, '&quot; references an authority,be sure that the value &quot;', $elementValue, '&quot; is a valid term controlled by &quot;', $codeSpaceValue, '&quot;.'),
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
                    concat('Check 2&#10;The code list dictionary referenced for ', $elementName, ' at ', $baseUrl, ' is not on the white list of approved URL''s. Choose a DIGGS standard resource at https://diggsml.org/def/ or add this URL to the whiteList.xml parameter file (local implementations only).'),
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
                    'WARNING',
                    $elementPath,
                    concat('Check 3&#10;The code list dictionary at &quot;', $baseUrl, '&quot; could not be accessed.'),
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
    
    <!-- Step 4: Check Check that the resource is a dictionary file -->
    <xsl:template match="*[@codeSpace]" mode="step4">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        <xsl:variable name="rootElementName" select="local-name($dictionaryResource/*[1])"/>
        
        <xsl:choose>
            <xsl:when test="not($rootElementName = 'Dictionary')"> <!-- Checks that the root element is Dictionary, if not, fail and send message -->
                <!-- Using the helper function for message creation -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('Check 4&#10;The file at &quot;', $baseUrl, '&quot; &#10; is not a DIGGS dictionary.'),
                    $currentElement
                    )"/>
                <!-- Step 4 fails - no further processing for this element -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 4 passes - continue to Step 5 -->
                <xsl:apply-templates select="." mode="step5">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 5: Check if the codeSpace returns returns a definition object from the dictionary -->
    <xsl:template match="*[@codeSpace]" mode="step5">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        
        <!-- Extract fragment from URL for lookup -->
        <xsl:variable name="fragment" select="substring-after($codeSpaceValue, '#')"/>
        
        <!-- Find dictionary entry that matches this fragment ID -->
        <xsl:variable name="definitionNode" select="$dictionaryResource//*[@gml:id = $fragment]"/>
        
        <xsl:choose>
            <xsl:when test="empty($definitionNode)"> <!-- If the Definition is not present, fail and send message -->
                <!-- Using the helper function for message creation -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('Check 5&#10;The definition for ', $elementValue, ' cannot be found. The code &quot;', $fragment, '&quot; is not in the code list dictionary at ', $baseUrl, '.'),
                    $currentElement
                    )"/>
                <!-- Step 4 fails - no further processing for this element -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 5 passes - continue to Step 6 -->
                <xsl:apply-templates select="." mode="step6">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 6: Check if any sourceElementXpath elements will match current element -->
    <xsl:template match="*[@codeSpace]" mode="step6">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="local-name()"/>
        <xsl:variable name="elementValue" select="."/>
        <xsl:variable name="currentPath" select="$elementPath"/>
        <xsl:variable name="documentRoot" select="root(.)"/>
        
        <!-- Get all sourceElementXpath values from the definition -->
        <xsl:variable name="sourceXPaths" select="$definitionNode/*[local-name()='occurrences']/*[local-name()='Occurrence']/*[local-name()='sourceElementXpath']"/>
        
        <!-- Check if current element matches any of the XPath expressions -->
        <xsl:variable name="matchResults" as="xs:boolean*">
            <xsl:for-each select="$sourceXPaths">
                <xsl:sequence select="diggs:evaluateXPathMatch($documentRoot, string(.), $currentElement, false())"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="isValidLocation" select="some $result in $matchResults satisfies $result"/>
        
        <!-- Format the list of allowed XPaths with proper indentation -->
        <xsl:variable name="formattedXPaths">
            <xsl:text>&#10;Allowable xPath locations are:&#10;</xsl:text>
            <xsl:for-each select="$sourceXPaths">
                <xsl:text>  </xsl:text>
                <xsl:value-of select="."/>
                <xsl:if test="position() != last()">
                    <xsl:text>&#10;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="not($isValidLocation)">
                <!-- Create a well-formatted error message -->
                <xsl:variable name="errorMessage">
                    <xsl:text>Check 6&#10;The ID "</xsl:text>
                    <xsl:value-of select="$fragment"/>
                    <xsl:text>" cannot be used for this context of </xsl:text>
                    <xsl:value-of select="$elementName"/>
                    <xsl:text>.&#10;Its xPath location does not match with allowable xPaths locations.</xsl:text>
                    <xsl:value-of select="$formattedXPaths"/>
<!--
                    <xsl:text>&#10;&#10;This xPath location is: "</xsl:text>
                    <xsl:value-of select="$currentPath"/>
                    <xsl:text>"</xsl:text>
-->
                </xsl:variable>
                
                <!-- Call the helper function directly -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    $errorMessage,
                    $currentElement
                    )"/>
                
                <!-- Step 6 fails - no further processing for this element -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 6 passes - continue to Step 7 -->
                <xsl:apply-templates select="." mode="step7">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 7: Check if the current element's value matches any gml:name in the definition -->
    <xsl:template match="*[@codeSpace]" mode="step7">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementLocalName" select="local-name()"/>
        <xsl:variable name="elementValue" select="."/>
        
        <xsl:choose>
            <!-- Skip this check for propertyClass elements -->
            <xsl:when test="$elementLocalName = 'propertyClass'">
                <!-- Bypass the test for propertyClass and continue to Step 8 -->
                <xsl:apply-templates select="." mode="step8">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!-- For non-propertyClass elements, perform the name check -->
                <!-- Check if current element's value matches any name element in the definitionNode (case-insensitive) -->
                <xsl:variable name="matchesAnyName" select="
                    some $name in $definitionNode//*[local-name() = 'name']
                    satisfies lower-case($elementValue) = lower-case(string($name))
                    "/>
                
                <xsl:choose>
                    <xsl:when test="not($matchesAnyName)">
                        <!-- Using the helper function for message creation -->
                        <xsl:sequence select="diggs:createMessage(
                            'INFO',
                            $elementPath,
                            concat('Check 7&#10;WARNING: The value ', $elementValue, ' in ', $elementName, 
                            ' does not match any of the codes for the definition referenced in ', 
                            $baseUrl, '. Be sure that ', $elementValue, ' is a synonymous term.'),
                            $currentElement
                            )"/>
                        <!-- Step 7 fails - no further processing for this element -->
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Step 7 passes - continue to Step 8 -->
                        <xsl:apply-templates select="." mode="step8">
                            <xsl:with-param name="elementPath" select="$elementPath"/>
                            <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                            <xsl:with-param name="baseUrl" select="$baseUrl"/>
                            <xsl:with-param name="fragment" select="$fragment"/>
                            <xsl:with-param name="definitionNode" select="$definitionNode"/>
                            <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                            <xsl:with-param name="whiteList" select="$whiteList"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 8: Check if the element is propertyClass, which requires special handling -->
    <xsl:template match="*[@codeSpace]" mode="step8">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementLocalName" select="local-name()"/>
        
        <xsl:choose>
            <xsl:when test="$elementLocalName = 'propertyClass'">
                <!-- Element is propertyClass, continue to Step 9 -->
                <xsl:apply-templates select="." mode="step9">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!-- Element is not propertyClass, terminate processing without message -->
                <!-- No further steps for non-propertyClass elements -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 9: Check conditionalElementXpath for propertyClass elements -->
    <xsl:template match="*[@codeSpace]" mode="step9">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        <xsl:variable name="documentRoot" select="root(.)"/>
        
        <!-- Get all conditionalElementXpath values from the definition -->
        <xsl:variable name="conditionalXPaths" 
            select="$definitionNode//*[local-name()='occurrences']/*[local-name()='Occurrence']/*[local-name()='conditionalElementXpath']"/>
        <xsl:variable name="definitionName" 
            select="string(($definitionNode/*[local-name() = 'name'])[1])"/>
        
        <xsl:choose>
            <!-- Failure case 1: No conditionalElementXpath found in the definition -->
            <xsl:when test="empty($conditionalXPaths)">
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('Check 9&#10;The propertyClass definition fort (', $elementValue, ') is referencing a result property that does not exist.'),
                    $currentElement
                    )"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Check each XPath -->
                <xsl:variable name="matchResults" as="xs:boolean*">
                    <xsl:for-each select="$conditionalXPaths">
                        <xsl:variable name="xpath" select="string(.)"/>
                        <xsl:sequence select="diggs:evaluateXPathMatch($documentRoot, $xpath, $currentElement, true())"/>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:variable name="isValidLocation" select="some $result in $matchResults satisfies $result"/>
                
                <xsl:choose>
                    <!-- Failure case 2: conditionalElementXpaths exist but none match -->
                    <xsl:when test="not($isValidLocation)">
                        <!-- Extract target element names for error message -->
                        <xsl:variable name="targetElementNames">
                            <xsl:for-each select="$conditionalXPaths">
                                <xsl:variable name="xpath" select="string(.)"/>
                                <xsl:variable name="segments" select="tokenize($xpath, '//')"/>
                                <xsl:variable name="lastSegment" select="$segments[last()]"/>
                                
                                <!-- Handle namespace prefixes -->
                                <xsl:variable name="cleanName">
                                    <xsl:choose>
                                        <xsl:when test="contains($lastSegment, ':')">
                                            <xsl:value-of select="substring-after($lastSegment, ':')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$lastSegment"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <!-- Remove any predicates -->
                                <xsl:variable name="finalName">
                                    <xsl:choose>
                                        <xsl:when test="contains($cleanName, '[')">
                                            <xsl:value-of select="substring-before($cleanName, '[')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$cleanName"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <xsl:value-of select="$finalName"/>
                                <xsl:if test="position() != last()">
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:variable>
                        
                        <xsl:sequence select="diggs:createMessage(
                            'ERROR',
                            $elementPath,
                            concat('Check 9&#10;The propertyClass (', $definitionName, 
                            ') is in the wrong context. It instead is used in this/these measurement procedure(s): ', $targetElementNames,'.'),
                            $currentElement
                            )"/>
                    </xsl:when>
                    <xsl:otherwise>
                        
                        <!-- All checks passed, continue to next step -->
                    <xsl:apply-templates select="." mode="step10">
                        <xsl:with-param name="elementPath" select="$elementPath"/>
                        <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                        <xsl:with-param name="baseUrl" select="$baseUrl"/>
                        <xsl:with-param name="fragment" select="$fragment"/>
                        <xsl:with-param name="definitionNode" select="$definitionNode"/>
                        <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                        <xsl:with-param name="definitionName" select="$definitionName"/>
                    </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 10: Check if the sibling dataType element matches the dataType in the definition -->
    <xsl:template match="*[@codeSpace]" mode="step10">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        <xsl:param name="definitionName"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        
        <!-- Get the sibling dataType element value -->
        <xsl:variable name="siblingDataType" select="../*[local-name() = 'typeData']"/>
        
        <!-- Get the dataType element from the definition -->
        <xsl:variable name="definitionDataType" select="$definitionNode//*[local-name() = 'dataType']"/>
        
        <xsl:choose>
            <!-- If sibling t  ypeData doesn't exist, skip this check. Schema valid instances must have this element-->
            <xsl:when test="empty($siblingDataType)">
                <!-- Bypass this test and continue to step 11 if needed -->
                <xsl:apply-templates select="." mode="step11">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    
                </xsl:apply-templates>
            </xsl:when>
            <!-- If definition dataType doesn't exist, skip this check -->
            <xsl:when test="empty($definitionDataType)">
                <!-- Bypass this test and continue to step 11 if needed -->
                <xsl:apply-templates select="." mode="step11">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!-- Perform case-insensitive comparison -->
                <xsl:variable name="siblingDataTypeValue" select="string($siblingDataType)"/>
                <xsl:variable name="definitionDataTypeValue" select="string($definitionDataType)"/>
                <xsl:variable name="dataTypeMatch" select="
                    lower-case($siblingDataTypeValue) = lower-case($definitionDataTypeValue)
                    "/>
                
                <xsl:choose>
                    <xsl:when test="not($dataTypeMatch)">
                        <!-- Using the helper function for message creation -->
                        <xsl:sequence select="diggs:createMessage(
                            'ERROR',
                            $elementPath,
                            concat('Check 10&#10;The typeData value in the document (', $siblingDataTypeValue, 
                            ') does not match the dataType specified in the definition (', $definitionDataTypeValue,
                            '). The sibling typeData element should match the value defined in the dictionary.'),
                            $currentElement
                            )"/>
                        <!-- Step 10 fails - no further processing for this element -->
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Step 10 passes - continue to Step 11 if needed -->
                        <xsl:apply-templates select="." mode="step11">
                            <xsl:with-param name="elementPath" select="$elementPath"/>
                            <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                            <xsl:with-param name="baseUrl" select="$baseUrl"/>
                            <xsl:with-param name="fragment" select="$fragment"/>
                            <xsl:with-param name="definitionNode" select="$definitionNode"/>
                            <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                            <xsl:with-param name="whiteList" select="$whiteList"/>
                            <xsl:with-param name="definitionName" select="$definitionName"/>
                            
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 11: Check if definition is unitless and handle uom element accordingly -->
    <xsl:template match="*[@codeSpace]" mode="step11">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        <xsl:param name="definitionName"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        
        <!-- Check if there is a quantityClass element in the definition node -->
        <xsl:variable name="quantityClass" select="$definitionNode//*[local-name() = 'quantityClass']"/>
        <xsl:variable name="hasQuantityClass" select="exists($quantityClass) and normalize-space(string($quantityClass)) != ''"/>
        
        <!-- Check if there is a sibling uom element -->
        <xsl:variable name="siblingUom" select="../*[local-name() = 'uom']"/>
        <xsl:variable name="hasSiblingUom" select="exists($siblingUom)"/>
        
        <xsl:choose>
            <!-- If quantityClass doesn't exist or is empty -->
            <xsl:when test="not($hasQuantityClass)">
                <!-- Check if there is a sibling uom element -->
                <xsl:choose>
                    <xsl:when test="$hasSiblingUom">
                        <!-- Error: uom exists but property is unitless -->
                        <xsl:sequence select="diggs:createMessage(
                            'ERROR',
                            $elementPath,
                            concat('Check 11&#10;The definition of this property (', $definitionName,') is unitless. The &lt;uom&gt; element should be removed from the DIGGS instance.'),
                            $currentElement
                            )"/>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- No error: property is unitless and has no uom element -->
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Terminate processing if quantityClass is empty/missing, regardless of error or not -->
            </xsl:when>
            <xsl:otherwise>
                <!-- quantityClass exists and is not empty - continue to Step 12 -->
                <xsl:apply-templates select="." mode="step12">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    <xsl:with-param name="quantityClass" select="$quantityClass"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 12: Check if uom element exists for a property with quantityClass -->
    <xsl:template match="*[@codeSpace]" mode="step12">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        <xsl:param name="quantityClass"/>
        <xsl:param name="definitionName"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        
        <!-- Check if there is a sibling uom element -->
        <xsl:variable name="siblingUom" select="../*[local-name() = 'uom']"/>
        <xsl:variable name="hasSiblingUom" select="exists($siblingUom)"/>
        
        <xsl:choose>
            <!-- If uom element doesn't exist, but should because quantityClass exists -->
            <xsl:when test="not($hasSiblingUom)">
                <!-- Error: uom is missing but property has a quantityClass -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('Check 12&#10;The definition of property ', $definitionName, ' requires a unit of measure. Add a &lt;uom&gt; element to the DIGGS instance.'),
                    $currentElement
                    )"/>
                <!-- Terminate processing on error -->
            </xsl:when>
            <xsl:otherwise>
                <!-- uom element exists as required - continue to Step 13 -->
                <xsl:apply-templates select="." mode="step13">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="quantityClass" select="$quantityClass"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    <!-- Pass the siblingUom element to the next step since it will likely be needed -->
                    <xsl:with-param name="siblingUom" select="$siblingUom"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>