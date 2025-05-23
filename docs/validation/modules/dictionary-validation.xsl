<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs map diggs gml err">
    
    <!-- Main template for dictionary validation. This module makes a number of progressive checks to validate codeType properties (elements with codeSpace attributes) against their referenced DiGGS code list dictionaries. -->
    <xsl:template name="dictionaryValidation">
        <!-- Declare the whitelist parameter -->
        <xsl:param name="whiteList" as="node()*"/>
        
        <messageSet>
            <step>Dictionary Validation</step>
            
            <!-- Find all elements with codeSpace attribute excluding identifier, internalIdentifier, axisDirection, and rangeMeaning, and start validation -->
            <xsl:apply-templates select="//*[@codeSpace][not(local-name()='identifier' or local-name()='internalIdentifier' or local-name()='axisDirection' or local-name()='rangeMeaning')]" mode="step1">
                <!-- Pass the whitelist down the template chain -->
                <xsl:with-param name="whiteList" select="$whiteList"/>
            </xsl:apply-templates>
        </messageSet>
    </xsl:template>
    
    <!-- Step 1: Check if codeSpace attribute value is a URL to a dictionary definition -->
    <xsl:template match="*" mode="step1">
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
                    concat('Check 1:&#10;The value of ', $elementName, ' cannot be validated against a code list dictionary. If &quot;', $codeSpaceValue, '&quot; references an authority, be sure that the value &quot;', $elementValue, '&quot; is a valid term controlled by ', $codeSpaceValue, '.'),
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
    <xsl:template match="*" mode="step2">
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
                    concat('Check 2:&#10;The code list dictionary &quot;', $baseUrl, '&quot; is not on the white list of approved URL''s. Choose a DIGGS standard code list dictionary or add this URL to a whiteList.xml parameter file and validate locally.'),
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
    <xsl:template match="*" mode="step3">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="whiteList" as="node()*"/>
        
        <xsl:variable name="currentElement" select="."/>
        
        <!-- Pass the document URI to getResource function -->
        <xsl:variable name="dictionaryResource" select="diggs:getResource($baseUrl, base-uri(/))"/>
        
        <xsl:choose>
            <xsl:when test="empty($dictionaryResource)">
                <!-- Using the helper function for message creation -->
                <xsl:sequence select="diggs:createMessage(
                    'WARNING',
                    $elementPath,
                    concat('Check 3:&#10;The resource at &quot;', $baseUrl, '&quot; could not be accessed.'),
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
    
    <!-- Step 4: Check that the resource is a dictionary file -->
    <xsl:template match="*" mode="step4">
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
                    concat('Check 4:&#10;The resource at &quot;', $baseUrl, '&quot; &#10; is not a DIGGS code list dictionary.'),
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
    <xsl:template match="*" mode="step5">
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
                    concat('Check 5:&#10;Code &quot;', $fragment, '&quot; is not found in the code list dictionary at &quot;', $baseUrl, '&quot;.'),
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
    <xsl:template match="*" mode="step6">
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
            <xsl:for-each select="$sourceXPaths">
                <xsl:text>&#10;     </xsl:text>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="not($isValidLocation)">
                <!-- Create a well-formatted error message -->
                <xsl:variable name="errorMessage">
                    <xsl:text>Check 6:&#10;"</xsl:text>
                    <xsl:value-of select="$fragment"/>
                    <xsl:text>" is not a valid code for  &lt;</xsl:text>
                    <xsl:value-of select="$elementName"/>
                    <xsl:text>&gt; in this specific context. This element is not matched by any of these allowable xPaths:</xsl:text>
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
    <xsl:template match="*" mode="step7">
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
                            concat('Check 7:&#10;The value &quot;', $elementValue, '&quot; in &lt;', $elementName, 
                            '&gt; does not match any of the names assigned to its definition in &quot;', 
                            $baseUrl, '&quot;. Be sure that &quot;', $elementValue, '&quot; is a synonymous term.'),
                            $currentElement
                            )"/>
                        <!-- Step 7 fails - since remaining checks are on propertyClass, no more checks -->
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
    
    <!-- Step 8: Check if the element is propertyClass, if so, continue to Step 9-->
    <xsl:template match="*" mode="step8">
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
    <xsl:template match="*" mode="step9">
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
        
        <!-- Check if there's a measurement ancestor but no procedure -->
        <xsl:variable name="noProcedure" as="xs:boolean">
            <xsl:variable name="hasMeasurementAncestor" 
                select="diggs:evaluateXPathMatch($documentRoot, 'ancestor::diggs:measurement', $currentElement, true())"/>
            <xsl:variable name="hasProcedureAncestor" 
                select="diggs:evaluateXPathMatch($documentRoot, 'ancestor::diggs:measurement//diggs:procedure', $currentElement, true())"/>
            <xsl:sequence select="$hasMeasurementAncestor and not($hasProcedureAncestor)"/>
        </xsl:variable>
        
        <xsl:choose>
            <!-- If no procedure is found in measurement ancestor, proceed to next step -->
            <xsl:when test="$noProcedure">
                <xsl:apply-templates select="." mode="step10">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    <xsl:with-param name="noProcedure" select="$noProcedure"/>
                </xsl:apply-templates>
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
                    <!-- Failure case: conditionalElementXpaths exist but none match -->
                    <xsl:when test="not($isValidLocation)">
                        <!-- Extract target element names for error message -->
                        <xsl:variable name="targetElementNames">
                            <xsl:for-each select="$conditionalXPaths">
                                <xsl:variable name="xpath" select="string(.)"/>
                                <xsl:variable name="postAncestor" select="tokenize($xpath,'::')"/>
                                <xsl:variable name="segments" select="tokenize($postAncestor[last()], '/')"/>
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
                                            <xsl:value-of select="concat('&#10;     ',substring-before($cleanName, '['))"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat('&#10;     ',$cleanName)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <xsl:value-of select="$finalName"/>

                            </xsl:for-each>
                        </xsl:variable>
                        
                        <xsl:sequence select="diggs:createMessage(
                            'ERROR',
                            $elementPath,
                            concat('Check 8:&#10;The property &quot;', $definitionName, 
                            '&quot; is invalid for this type of measurement. &quot;',  $definitionName, '&quot; is only allowed in the following types of measurements: ', $targetElementNames,'.'),
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
                            <xsl:with-param name="noProcedure" select="$noProcedure"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Step 10: Check if the sibling dataType element matches the dataType in the definition -->
    <xsl:template match="*" mode="step10">
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
            <!-- If sibling typeData doesn't exist, skip this check. Schema valid instances must have this element-->
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
                            concat('Check 9:&#10;The data type for &quot;', $definitionName, '&quot; should be &quot;', $definitionDataTypeValue, 
                            '&quot;, but instead is defined as &quot;', $siblingDataTypeValue,
                            '&quot;. The value of the sibling &lt;typeData&gt; element should match the data type defined in the dictionary.'),
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
    <xsl:template match="*" mode="step11">
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
                            concat('Check 10:&#10;&quot;', $definitionName,'&quot; is defined as unitless. The sibling &lt;uom&gt; element should be removed.'),
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
    <xsl:template match="*" mode="step12">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        <xsl:param name="definitionName"/>
        <xsl:param name="quantityClass"/>
  
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
                    concat('Check 11:&#10;&quot;', $definitionName, '&quot; requires a unit of measure. Add a &lt;uom&gt; element following this &lt;propertyClass&gt;.'),
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
    
    <!-- Step 13: Check if the uom value is a permitted unit symbol for the quantityClass -->
    <xsl:template match="*" mode="step13">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        <xsl:param name="quantityClass"/>
        <xsl:param name="definitionName"/>
        <xsl:param name="siblingUom"/>
        
        <xsl:variable name="currentElement" select="."/>
        <xsl:variable name="elementName" select="name()"/>
        <xsl:variable name="elementValue" select="."/>
        
        <!-- Get the uom value -->
        <xsl:variable name="uomValue" select="string($siblingUom)"/>
        
        <!-- Get the quantityClass value and encode spaces as %20 for the URL -->
        <xsl:variable name="quantityClassValue" select="string($quantityClass)"/>
        <xsl:variable name="encodedQuantityClass" select="replace($quantityClassValue, ' ', '%20')"/>
        
        <!-- Construct the API URL -->
        <xsl:variable name="apiUrl" select="concat('https://diggs.geosetta.org/api/units/classes/', $encodedQuantityClass)"/>
        
        <!-- Call the extractJsonValues function to get the allowed units -->
        <xsl:variable name="allowedUnits" select="diggs:extractJsonValues($apiUrl, 'units')"/>
        
        <!-- Check if the uom value matches any of the allowed units (case-sensitive) -->
        <xsl:variable name="isValidUnit" as="xs:boolean">
            <xsl:choose>
                <xsl:when test="empty($allowedUnits)">
                    <!-- If no units are returned, consider it valid to avoid false failures -->
                    <xsl:sequence select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Check if the uom value is in the allowed units -->
                    <xsl:sequence select="exists($allowedUnits[. = $uomValue])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <!-- If API call failed or returned no units, issue a warning but don't fail validation -->
            <xsl:when test="empty($allowedUnits)">
                <xsl:sequence select="diggs:createMessage(
                    'WARNING',
                    $elementPath,
                    concat('Check 12:&#10;Unable to validate unit of measure &quot;', $uomValue, '&quot; for quantity class &quot;', 
                    $quantityClassValue, '&quot;. The units API could not be accessed at &quot;', $apiUrl, '&quot;.'),
                    $currentElement
                    )"/>
                <!-- Continue to Step 14 despite the warning -->
                <xsl:apply-templates select="." mode="step14">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="quantityClass" select="$quantityClass"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    <xsl:with-param name="siblingUom" select="$siblingUom"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- If the uom value is not in the list of allowed units -->
            <xsl:when test="not($isValidUnit)">
                <!-- Format the list of allowed units for readable error message -->
                <xsl:variable name="formattedAllowedUnits">
                    <xsl:for-each select="$allowedUnits[position() &lt;= 10]">
                        <xsl:if test="position() > 1">, </xsl:if>
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                    <xsl:if test="count($allowedUnits) > 10">
                        <xsl:text>, ... and </xsl:text>
                        <xsl:value-of select="count($allowedUnits) - 10"/>
                        <xsl:text> more</xsl:text>
                    </xsl:if>
                </xsl:variable>
                
                <!-- Error: uom value is not in the list of allowed units -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('Check 12:&#10;The unit of measure &quot;', $uomValue, '&quot; is not valid for quantity class &quot;', 
                    $quantityClassValue, '&quot;. Valid units include: ', $formattedAllowedUnits, '.'),
                    $currentElement
                    )"/>
                <!-- Terminate processing on error -->
            </xsl:when>
            <xsl:otherwise>
                <!-- uom value is in the list of allowed units - continue to Step 14 -->
                <xsl:apply-templates select="." mode="step14">
                    <xsl:with-param name="elementPath" select="$elementPath"/>
                    <xsl:with-param name="codeSpaceValue" select="$codeSpaceValue"/>
                    <xsl:with-param name="baseUrl" select="$baseUrl"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="definitionNode" select="$definitionNode"/>
                    <xsl:with-param name="dictionaryResource" select="$dictionaryResource"/>
                    <xsl:with-param name="whiteList" select="$whiteList"/>
                    <xsl:with-param name="quantityClass" select="$quantityClass"/>
                    <xsl:with-param name="definitionName" select="$definitionName"/>
                    <xsl:with-param name="siblingUom" select="$siblingUom"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Placeholder for Step 14 (if needed) -->
    <xsl:template match="*" mode="step14">
        <xsl:param name="elementPath"/>
        <xsl:param name="codeSpaceValue"/>
        <xsl:param name="baseUrl"/>
        <xsl:param name="fragment"/>
        <xsl:param name="definitionNode"/>
        <xsl:param name="dictionaryResource"/>
        <xsl:param name="whiteList" as="node()*"/>
        <xsl:param name="quantityClass"/>
        <xsl:param name="definitionName"/>
        <xsl:param name="siblingUom"/>
        
        <!-- All validation steps have passed successfully -->
        <!-- This template can be expanded in the future if additional validation steps are needed -->
    </xsl:template>
    
</xsl:stylesheet>