<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs map diggs gml xsi err">
    
    <!-- Main template for schema location checking -->
    <xsl:template name="schemaCheck">
        <!-- Declare the whitelist parameter -->
        <xsl:param name="whiteList" as="node()*"/>
        
        <messageSet>
            <step>Schema Location</step>
            
            <!-- Check if the root element has schemaLocation attribute -->
            <xsl:variable name="schemaLocationElements" select="//*[@xsi:schemaLocation]"/>
            <xsl:variable name="hasSchemaLocation" select="exists($schemaLocationElements)" as="xs:boolean"/>
            
            <!-- Extract schema information -->
            <xsl:variable name="schemaInfo">
                <xsl:if test="$hasSchemaLocation">
                    <xsl:variable name="schemaLocation" select="$schemaLocationElements[1]/@xsi:schemaLocation"/>
                    <xsl:variable name="tokens" select="tokenize(normalize-space($schemaLocation), '\s+')"/>
                    <xsl:for-each select="1 to (count($tokens) idiv 2)">
                        <xsl:variable name="i" select="."/>
                        <pair>
                            <namespace><xsl:value-of select="$tokens[2*$i - 1]"/></namespace>
                            <location><xsl:value-of select="$tokens[2*$i]"/></location>
                        </pair>
                    </xsl:for-each>
                </xsl:if>
            </xsl:variable>
            
            <!-- Create a dummy schema location attribute element to use as source -->
            <xsl:variable name="schemaLocElement">
                <xsl:if test="$hasSchemaLocation">
                    <schemaLocation>
                        <xsl:value-of select="$schemaLocationElements[1]/@xsi:schemaLocation"/>
                    </schemaLocation>
                </xsl:if>
                <xsl:if test="not($hasSchemaLocation)">
                    <schemaLocation/>
                </xsl:if>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="not($hasSchemaLocation)">
                    <!-- Generate warning message for missing schemaLocation using the helper function -->
                    <xsl:sequence select="diggs:createMessage(
                        'WARNING',
                        '/Diggs[1]',
                        'The file requires a schemaLocation attribute for complete validation. Add xsi:schemaLocation attribute to the root Diggs element, run schema validation, and then recheck.',
                        $schemaLocElement/*
                        )"/>
                    <!-- Set continuable flag to false -->
                    <continuable>false</continuable>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Get the schema URL -->
                    <xsl:variable name="schema-url" select="$schemaInfo/pair[1]/location"/>
                    
                    <!-- NEW STEP: Check if schema URL is in the whitelist -->
                    <xsl:choose>
                        <xsl:when test="not(diggs:isWhitelisted($schema-url, $whiteList))">
                            <!-- Generate error for schema URL not on whitelist -->
                            <xsl:sequence select="diggs:createMessage(
                                'WARNING',
                                '/Diggs[1]',
                                concat('schemaLocation ', $schema-url, ' is not on the white list of approved URL''s. Choose schemaLocation in the Diggs domain or add to the whiteList.xml parameter file.'),
                                $schemaLocElement/*
                                )"/>
                            <continuable>false</continuable>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Check that the namespace matches the document namespace -->
                            <xsl:variable name="namespace-match" select="$schemaInfo/pair[1]/namespace = namespace-uri(/*)"/>
                            
                            <xsl:choose>
                                <xsl:when test="not($namespace-match)">
                                    <!-- Generate error for namespace mismatch -->
                                    <xsl:sequence select="diggs:createMessage(
                                        'ERROR',
                                        '/Diggs[1]',
                                        concat('The namespace in the schemaLocation attribute does not match the document namespace.
Document namespace: ', namespace-uri(/*), '
SchemaLocation namespace: ', $schemaInfo/pair[1]/namespace),
                                        $schemaLocElement/*
                                        )"/>
                                    <continuable>false</continuable>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- Try to load the schema -->
                                    <xsl:try>
                                        <!-- Attempt to read the schema content -->
                                        <xsl:variable name="schema-content">
                                            <xsl:try>
                                                <xsl:sequence select="unparsed-text($schema-url)"/>
                                                
                                                <xsl:catch errors="*">
                                                    <e><xsl:value-of select="$err:description"/></e>
                                                </xsl:catch>
                                            </xsl:try>
                                        </xsl:variable>
                                        
                                        <xsl:choose>
                                            <xsl:when test="$schema-content/e">
                                                <!-- Report schema loading error -->
                                                <xsl:sequence select="diggs:createMessage(
                                                    'ERROR',
                                                    '/Diggs[1]',
                                                    concat('Error: ', $schema-content/e),
                                                    $schemaLocElement/*
                                                    )"/>
                                                <continuable>false</continuable>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <!-- Check multiple schema patterns - including default namespace case -->
                                                <xsl:variable name="looks-like-schema" select="
                                                    contains($schema-content, 'xs:schema') or 
                                                    contains($schema-content, 'xsd:schema') or
                                                    contains($schema-content, '&lt;schema') or  
                                                    contains($schema-content, 'xmlns=&quot;http://www.w3.org/2001/XMLSchema&quot;')"/>
                                                
                                                <xsl:choose>
                                                    <xsl:when test="not($looks-like-schema)">
                                                        <!-- Doesn't look like a schema -->
                                                        <xsl:sequence select="diggs:createMessage(
                                                            'ERROR',
                                                            '/Diggs[1]',
                                                            concat('The referenced URL does not appear to contain a valid XML Schema: ', $schema-url),
                                                            $schemaLocElement/*
                                                            )"/>
                                                        <continuable>false</continuable>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <!-- Extract targetNamespace from schema -->
                                                        <xsl:variable name="target-namespace">
                                                            <xsl:analyze-string select="$schema-content" regex="targetNamespace=&quot;([^&quot;]*)&quot;">
                                                                <xsl:matching-substring>
                                                                    <xsl:value-of select="regex-group(1)"/>
                                                                </xsl:matching-substring>
                                                            </xsl:analyze-string>
                                                        </xsl:variable>
                                                        
                                                        <!-- Compare schemaLocation namespace with targetNamespace -->
                                                        <xsl:variable name="target-ns-match" select="string($target-namespace) = $schemaInfo/pair[1]/namespace"/>
                                                        
                                                        <xsl:choose>
                                                            <xsl:when test="not($target-ns-match)">
                                                                <!-- Schema namespace mismatch -->
                                                                <xsl:sequence select="diggs:createMessage(
                                                                    'ERROR',
                                                                    '/Diggs[1]',
                                                                    concat('The namespace in the schemaLocation attribute does not match the targetNamespace in the schema.
SchemaLocation namespace: ', $schemaInfo/pair[1]/namespace, '
Schema targetNamespace: ', $target-namespace),
                                                                    $schemaLocElement/*
                                                                    )"/>
                                                                <continuable>false</continuable>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <!-- All preliminary validations passed -->
                                                                <!-- Output schema URL for the next module to use -->
                                                                <schema-url><xsl:value-of select="$schema-url"/></schema-url>
                                                                <continuable>true</continuable>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        
                                        <xsl:catch errors="*">
                                            <!-- Report general error -->
                                            <xsl:sequence select="diggs:createMessage(
                                                'ERROR',
                                                '/Diggs[1]',
                                                concat('Error during schema checks: ', $err:description),
                                                $schemaLocElement/*
                                                )"/>
                                            <continuable>false</continuable>
                                        </xsl:catch>
                                    </xsl:try>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </messageSet>
    </xsl:template>
    
</xsl:stylesheet>