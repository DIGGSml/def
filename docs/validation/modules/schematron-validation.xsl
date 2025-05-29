<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev" 
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
    xmlns:err="http://www.w3.org/2005/xqt-errors" 
    exclude-result-prefixes="xs map diggs gml svrl err">
    
    <!-- Main template for schematron validation -->
    <xsl:template name="schematronValidation">
        <xsl:param name="whiteList"/>
        <xsl:param name="sourceDocument"/>
        
        <messageSet>
            <step>Schematron Validation</step>
            
            <xsl:try>
                <!-- Load and compile the Schematron rules -->
                <xsl:variable name="schematronRulesPath" select="'modules/diggs_schematron_rules.sch'"/>
                <xsl:variable name="pipelineStylesheetPath" select="'modules/schxslt_2.0/pipeline-for-svrl.xsl'"/>
                <xsl:variable name="schematronRulesFallback" select="'https://diggsml.org/def/validation/modules/diggs_schematron_rules.sch'"/>
                <xsl:variable name="pipelineStylesheetFallback" select="'https://diggsml.org/def/validation/modules/schxslt_2.0/pipeline-for-svrl.xsl'"/>
                
                <!-- Determine the actual paths to use (primary or fallback) -->
                <xsl:variable name="actualSchematronPath" select="
                    if (doc-available($schematronRulesPath)) 
                    then $schematronRulesPath 
                    else if (doc-available($schematronRulesFallback)) 
                    then $schematronRulesFallback 
                    else ''"/>
                
                <xsl:variable name="actualPipelinePath" select="
                    if (doc-available($pipelineStylesheetPath)) 
                    then $pipelineStylesheetPath 
                    else if (doc-available($pipelineStylesheetFallback)) 
                    then $pipelineStylesheetFallback 
                    else ''"/>
                
                <!-- Check if files are accessible (with fallback) -->
                <xsl:choose>
                    <xsl:when test="$actualSchematronPath = ''">
                        <xsl:sequence select="
                            diggs:createMessage(
                            'WARNING',
                            '/',
                            concat('Schematron validation could not be performed. The Schematron rules file could not be accessed at either &quot;', $schematronRulesPath, '&quot; or fallback location &quot;', $schematronRulesFallback, '&quot;.'),
                            $sourceDocument
                            )"/>
                    </xsl:when>
                    <xsl:when test="$actualPipelinePath = ''">
                        <xsl:sequence select="
                            diggs:createMessage(
                            'WARNING',
                            '/',
                            concat('Schematron validation could not be performed. The SchXslt pipeline stylesheet could not be accessed at either &quot;', $pipelineStylesheetPath, '&quot; or fallback location &quot;', $pipelineStylesheetFallback, '&quot;.'),
                            $sourceDocument
                            )"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Load the Schematron rules and pipeline stylesheet from actual locations -->
                        <xsl:variable name="schematronDoc" select="doc($actualSchematronPath)"/>
                        <xsl:variable name="pipelineDoc" select="doc($actualPipelinePath)"/> 
                        
                        <!-- Step 1: Transform Schematron rules using SchXslt pipeline -->
                        <xsl:variable name="compiledSchematron" select="transform(
                            map {
                            'source-node': $schematronDoc,
                            'stylesheet-node': $pipelineDoc
                            }
                            )?output"/>
                        
                        <!-- Step 2: Apply compiled Schematron to source document -->
                        <xsl:variable name="svrlResult" select="transform(
                            map {
                            'source-node': $sourceDocument,
                            'stylesheet-node': $compiledSchematron
                            }
                            )?output"/>
                        
                        <!-- Step 3: Process SVRL output -->
                        <xsl:call-template name="processSvrlOutput">
                            <xsl:with-param name="svrlOutput" select="$svrlResult"/>
                            <xsl:with-param name="sourceDocument" select="$sourceDocument"/>
                            <xsl:with-param name="whiteList" select="$whiteList"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:catch>
                    <!-- If any step fails, create an error message -->
                    <xsl:sequence select="
                        diggs:createMessage(
                        'ERROR',
                        '/',
                        concat('Schematron validation failed: ', $err:description),
                        $sourceDocument
                        )"/>
                </xsl:catch>
            </xsl:try>
        </messageSet>
    </xsl:template>
    
    
    
    <!-- Template to process SVRL output and generate validation messages -->
    <xsl:template name="processSvrlOutput">
        <xsl:param name="svrlOutput"/>
        <xsl:param name="sourceDocument"/>
        <xsl:param name="whiteList"/>
        
        <!-- Process each failed assertion in the SVRL output -->
        <xsl:for-each select="$svrlOutput//svrl:failed-assert">
            <xsl:variable name="currentFailedAssert" select="."/>
            <xsl:variable name="location" select="string(@location)"/>
            <xsl:variable name="assertionText" select="string(svrl:text)"/>
                        
            <!-- Find the preceding fired-rule to get the role -->
            <xsl:variable name="precedingFiredRule" select="
                $currentFailedAssert/preceding-sibling::svrl:fired-rule[1]"/>
            <xsl:variable name="role" select="
                if ($precedingFiredRule/@role) 
                then string($precedingFiredRule/@role) 
                else 'ERROR'"/>
            
            <!-- Convert role to uppercase for message type -->
            <xsl:variable name="messageType" select="upper-case($role)"/>
            
            <!-- Try to find the element in the source document using the cleaned location XPath -->
            <xsl:variable name="selectedElement" as="element()*">
                <xsl:evaluate context-item="$sourceDocument" xpath="$location"
                />
            </xsl:variable>
                <xsl:variable name="elementPath" select="diggs:get-path($selectedElement)"/>
            
             
             
            <!-- Create the message if not whitelisted -->

                <xsl:sequence select="
                    diggs:createMessage(
                    $messageType,
                    $elementPath,
                    $assertionText,
                    $selectedElement
                    )"/>
            
        </xsl:for-each>
        
    </xsl:template>
    
</xsl:stylesheet>