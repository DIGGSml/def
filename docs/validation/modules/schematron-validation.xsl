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
                <!-- Step 1: Load and compile the Schematron rules -->
                <xsl:variable name="schematronRulesPath" select="resolve-uri('modules/diggs_validation_rules.sch', base-uri(/))"/>
                <xsl:variable name="pipelineStylesheetPath" select="resolve-uri('modules/schxslt_2.0/pipeline-for-svrl.xsl', base-uri(/))"/>
                
                <!-- Check if the Schematron rules file exists -->
                <xsl:choose>
                    <xsl:when test="not(doc-available($schematronRulesPath))">
                        <xsl:sequence select="
                            diggs:createMessage(
                            'WARNING',
                            '/',
                            concat('Schematron validation could not be performed. The Schematron rules file at &quot;', $schematronRulesPath, '&quot; could not be accessed.'),
                            $sourceDocument
                            )"/>
                    </xsl:when>
                    <xsl:when test="not(doc-available($pipelineStylesheetPath))">
                        <xsl:sequence select="
                            diggs:createMessage(
                            'WARNING',
                            '/',
                            concat('Schematron validation could not be performed. The SchXslt pipeline stylesheet at &quot;', $pipelineStylesheetPath, '&quot; could not be accessed.'),
                            $sourceDocument
                            )"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Load the Schematron rules and pipeline stylesheet -->
                        <xsl:variable name="schematronRules" select="doc($schematronRulesPath)"/>
                        <xsl:variable name="pipelineStylesheet" select="doc($pipelineStylesheetPath)"/>
                        
                        <!-- Step 1: Transform Schematron rules using SchXslt pipeline -->
                        <xsl:variable name="compiledSchematron">
                            <xsl:apply-templates select="$schematronRules" mode="schxslt-compile">
                                <xsl:with-param name="pipeline" select="$pipelineStylesheet" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        <!-- Step 2: Apply compiled Schematron to source document -->
                        <xsl:variable name="svrlOutput">
                            <xsl:apply-templates select="$sourceDocument" mode="schematron-validate">
                                <xsl:with-param name="compiledSchematron" select="$compiledSchematron" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        <!-- Step 3: Parse SVRL output and generate messages -->
                        <xsl:call-template name="processSvrlOutput">
                            <xsl:with-param name="svrlOutput" select="$svrlOutput"/>
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
                        concat('Schematron validation failed with error: ', $err:description),
                        $sourceDocument
                        )"/>
                </xsl:catch>
            </xsl:try>
        </messageSet>
    </xsl:template>
    
    <!-- Template to compile Schematron rules using SchXslt -->
    <xsl:template match="/" mode="schxslt-compile">
        <xsl:param name="pipeline" tunnel="yes"/>
        
        <!-- This is a simplified approach - in practice, you would use the actual SchXslt transformation -->
        <!-- For now, we'll simulate the compilation process -->
        <xsl:variable name="compiledStylesheet">
            <!-- Here you would apply the SchXslt pipeline transformation -->
            <!-- transform($schematronRules, $pipelineStylesheet) -->
            <xsl:copy-of select="."/>
        </xsl:variable>
        
        <xsl:sequence select="$compiledStylesheet"/>
    </xsl:template>
    
    <!-- Template to apply compiled Schematron to source document -->
    <xsl:template match="/" mode="schematron-validate">
        <xsl:param name="compiledSchematron" tunnel="yes"/>
        
        <!-- Apply the compiled Schematron stylesheet to generate SVRL output -->
        <!-- In practice, this would use transform() function with the compiled stylesheet -->
        <!-- For now, we'll simulate by creating a mock SVRL structure -->
        <svrl:schematron-output>
            <!-- This would be the actual SVRL output from SchXslt processing -->
            <xsl:copy-of select="$compiledSchematron"/>
        </svrl:schematron-output>
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
            
            <!-- Try to find the element in the source document using the location XPath -->
            <xsl:variable name="targetElement">
                <xsl:try>
                    <!-- Convert the location path to a simpler XPath that can be evaluated -->
                    <xsl:variable name="simplifiedPath" select="
                        replace(
                        replace($location, 'Q\{[^}]+\}', ''),
                        '\[[0-9]+\]', ''
                        )"/>
                    
                    <!-- Evaluate the XPath against the source document -->
                    <xsl:evaluate context-item="$sourceDocument" xpath="$simplifiedPath"/>
                    
                    <xsl:catch>
                        <!-- If XPath evaluation fails, use the source document root -->
                        <xsl:sequence select="$sourceDocument"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:variable>
            
            <!-- Check if this message should be filtered by whitelist -->
            <xsl:variable name="shouldCreateMessage">
                <xsl:choose>
                    <xsl:when test="empty($whiteList)">
                        <xsl:value-of select="true()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Check if this specific assertion is whitelisted -->
                        <xsl:variable name="isWhitelisted" select="
                            $whiteList//schematronException[
                            @location = $location and 
                            normalize-space(text) = normalize-space($assertionText)
                            ]"/>
                        <xsl:value-of select="empty($isWhitelisted)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- Create the message if not whitelisted -->
            <xsl:if test="$shouldCreateMessage = 'true'">
                <xsl:sequence select="
                    diggs:createMessage(
                    $messageType,
                    $location,
                    $assertionText,
                    if (exists($targetElement)) then $targetElement else $sourceDocument
                    )"/>
            </xsl:if>
        </xsl:for-each>
        
        <!-- Also process successful fired rules for informational purposes if needed -->
        <xsl:variable name="totalRulesFired" select="count($svrlOutput//svrl:fired-rule)"/>
        <xsl:variable name="totalFailedAsserts" select="count($svrlOutput//svrl:failed-assert)"/>
        
        <!-- Create summary message -->
        <xsl:if test="$totalRulesFired > 0">
            <xsl:sequence select="
                diggs:createMessage(
                'INFO',
                '/',
                concat('Schematron validation completed. Rules fired: ', $totalRulesFired, ', Failed assertions: ', $totalFailedAsserts),
                $sourceDocument
                )"/>
        </xsl:if>
    </xsl:template>
    
    <!-- Alternative implementation using actual SchXslt transform functions -->
    <xsl:template name="schematronValidationWithTransform">
        <xsl:param name="whiteList"/>
        <xsl:param name="sourceDocument"/>
        
        <messageSet>
            <step>Schematron Validation (Transform-based)</step>
            
            <xsl:try>
                <!-- Step 1: Compile Schematron rules -->
                <xsl:variable name="schematronRulesUri" select="resolve-uri('diggs-schematron-rules.sch', base-uri(/))"/>
                <xsl:variable name="pipelineUri" select="resolve-uri('schxslt_2.0/pipeline-for-svrl.xsl', base-uri(/))"/>
                
                <xsl:variable name="schematronDoc" select="doc($schematronRulesUri)"/>
                <xsl:variable name="pipelineDoc" select="doc($pipelineUri)"/>
                
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
                
                <xsl:catch>
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
    
</xsl:stylesheet>