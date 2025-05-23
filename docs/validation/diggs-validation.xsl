<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- 
         ************ Master stylesheet for DIGGS context validation **************
         *                                                                        *
         *            DIGGS files should be schema valid before                   * 
         *            running context validation                                  *
         *                                                                        *
         **************************************************************************
     -->
    
    <!-- Output method -->
    <xsl:output method="xml" indent="yes"/>
    
   
    <!-- Global variables -->
    <xsl:variable name="whiteListFile" select="'./whiteList.xml'"/>   
    
       <xsl:variable name="whiteList" select="if (doc-available($whiteListFile)) then doc($whiteListFile) else ()"/>
   
    <!-- Store the original XML document -->
    <xsl:variable name="originalXml" select="/"/>
    
    <!-- Convert the XML to a string -->
    <xsl:variable name="originalXmlString">
        <xsl:value-of select="serialize($originalXml)"/>
    </xsl:variable>
    
    <!-- Import function module first -->
    <xsl:import href="modules/diggs-functions.xsl"/>
    

    <!-- Import DIGGS structure check module -->
    <xsl:import href="modules/diggs-check.xsl"/>
    
    <!-- Import schema validation module -->
    <xsl:import href="modules/schema-check.xsl"/>
    
    <!-- Import codeType-validation module -->
    <xsl:import href="modules/codeType-validation.xsl"/>
    
    <!-- Import dictionary-validation module -->
    <xsl:import href="modules/dictionary-validation.xsl"/>
 
    <!-- Import schematron-validation module 
    <xsl:import href="modules/schematron-validation.xsl"/>
    -->
 
    <!-- Import other modules here once they are developed -->
    
    <!-- Main template -->
    <xsl:template match="/">
        <validationReport>
            <timestamp><xsl:value-of select="current-dateTime()"/></timestamp>
            <fileName><xsl:value-of select="tokenize(document-uri(/), '/')[last()]"/></fileName>
            <originalXml><xsl:value-of select="$originalXmlString"/></originalXml>
            
            <!-- Run DIGGS structure check first -->
            <xsl:variable name="diggsCheckResults">
                <xsl:call-template name="diggsCheck"/>
            </xsl:variable>
            
            <!-- Include DIGGS structure check results in the report -->
            <xsl:copy-of select="$diggsCheckResults"/>
            
            <!-- Only proceed with other validations if DIGGS structure check allows continuation -->
            <xsl:if test="$diggsCheckResults/messageSet/continuable = 'true'">
                
                <!-- Run schema validation, passing the whitelist -->
                <xsl:variable name="schemaCheckResults">
                    <xsl:call-template name="schemaCheck">
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Include schema validation results in the report -->
                <xsl:copy-of select="$schemaCheckResults"/>
                
                <!-- Only proceed with other validations if schema validation allows continuation -->
                <xsl:if test="$schemaCheckResults/messageSet/continuable = 'true'">
                    
                    <!-- Run codeType validation -->
                    <xsl:call-template name="codeTypeValidation">
                        <xsl:with-param name="sourceDocument" select="$originalXml"/>
                    </xsl:call-template>
                    
                    <!-- Run  dictionary validation, passing the whitelist -->
                    <xsl:call-template name="dictionaryValidation">
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                    </xsl:call-template>
                    
                    <!-- Run schematron validation, passing the whitelist
                    <xsl:call-template name="schematronValidation">
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                    </xsl:call-template>
                     -->
                   
                    <!-- Other validation modules will be called here as they are developed -->
                </xsl:if>
            </xsl:if>
        </validationReport>
    </xsl:template>
</xsl:stylesheet>