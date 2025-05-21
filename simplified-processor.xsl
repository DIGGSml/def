
        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      xmlns:diggs="http://diggsml.org/ns/functions"
                      exclude-result-prefixes="xs diggs"
                      version="3.0">
                      
        <xsl:output method="xml" indent="yes"/>
        
        <!-- Embedded file list with local paths -->
        <xsl:variable name="dictionary-files">
          <file><name>USCSSoilComponents.xml</name><path>/workspaces/def/temp_dictionaries/USCSSoilComponents.xml</path></file>
      <file><name>aashtoM145.xml</name><path>/workspaces/def/temp_dictionaries/aashtoM145.xml</path></file>
      <file><name>abundance.xml</name><path>/workspaces/def/temp_dictionaries/abundance.xml</path></file>
      <file><name>abundanceUSDA.xml</name><path>/workspaces/def/temp_dictionaries/abundanceUSDA.xml</path></file>
      <file><name>astm2488Brdr.xml</name><path>/workspaces/def/temp_dictionaries/astm2488Brdr.xml</path></file>
      <file><name>astmD2487.xml</name><path>/workspaces/def/temp_dictionaries/astmD2487.xml</path></file>
      <file><name>astmD2488.xml</name><path>/workspaces/def/temp_dictionaries/astmD2488.xml</path></file>
      <file><name>astmD5715.xml</name><path>/workspaces/def/temp_dictionaries/astmD5715.xml</path></file>
      <file><name>boreholeMethod.xml</name><path>/workspaces/def/temp_dictionaries/boreholeMethod.xml</path></file>
      <file><name>boreholePurpose.xml</name><path>/workspaces/def/temp_dictionaries/boreholePurpose.xml</path></file>
      <file><name>boreholeType.xml</name><path>/workspaces/def/temp_dictionaries/boreholeType.xml</path></file>
      <file><name>gp_properties.xml</name><path>/workspaces/def/temp_dictionaries/gp_properties.xml</path></file>
      <file><name>gr_inj_properties.xml</name><path>/workspaces/def/temp_dictionaries/gr_inj_properties.xml</path></file>
      <file><name>grp-aashtoM145.xml</name><path>/workspaces/def/temp_dictionaries/grp-aashtoM145.xml</path></file>
      <file><name>grp-astm2487.xml</name><path>/workspaces/def/temp_dictionaries/grp-astm2487.xml</path></file>
      <file><name>grp-astm2488.xml</name><path>/workspaces/def/temp_dictionaries/grp-astm2488.xml</path></file>
      <file><name>grp-astmD2487.xml</name><path>/workspaces/def/temp_dictionaries/grp-astmD2487.xml</path></file>
      <file><name>grp-astmD2488Brdr.xml</name><path>/workspaces/def/temp_dictionaries/grp-astmD2488Brdr.xml</path></file>
      <file><name>measurand.xml</name><path>/workspaces/def/temp_dictionaries/measurand.xml</path></file>
      <file><name>mwd_properties.xml</name><path>/workspaces/def/temp_dictionaries/mwd_properties.xml</path></file>
      <file><name>pil_properties.xml</name><path>/workspaces/def/temp_dictionaries/pil_properties.xml</path></file>
      <file><name>properties.xml</name><path>/workspaces/def/temp_dictionaries/properties.xml</path></file>
      <file><name>roles.xml</name><path>/workspaces/def/temp_dictionaries/roles.xml</path></file>
      <file><name>soundingPurpose.xml</name><path>/workspaces/def/temp_dictionaries/soundingPurpose.xml</path></file>
      <file><name>triaxType.xml</name><path>/workspaces/def/temp_dictionaries/triaxType.xml</path></file>
      <file><name>usda.xml</name><path>/workspaces/def/temp_dictionaries/usda.xml</path></file>
        </xsl:variable>
        
        <!-- Base URL for original dictionaries (for reference) -->
        <xsl:variable name="base-url" select="'https://diggsml.org/def/codes/DIGGS/0.1/'"/>
        
        <!-- Main template -->
        <xsl:template name="process-dictionaries">
            <!-- Process all files and collect dictionary info -->
            <xsl:variable name="all-dictionaries">
                <dictionaries>
                    <xsl:for-each select="$dictionary-files/file">
                        <xsl:variable name="filename" select="name"/>
                        <xsl:variable name="filepath" select="path"/>
                        <xsl:variable name="full-url" select="concat($base-url, $filename)"/>
                        
                        <xsl:try>
                            <!-- Load the dictionary XML from local path -->
                            <xsl:variable name="dict-doc" select="doc($filepath)"/>
                            <xsl:variable name="dict-id" select="$dict-doc//*[local-name()='Dictionary']/@*[local-name()='id']"/>
                            
                            <xsl:if test="$dict-id">
                                <dictionary>
                                    <id><xsl:value-of select="$dict-id"/></id>
                                    <xpath><xsl:value-of select="diggs:construct-xpath($dict-id)"/></xpath>
                                    <url><xsl:value-of select="$full-url"/></url>
                                </dictionary>
                            </xsl:if>
                            
                            <xsl:catch>
                                <xsl:message>Error loading dictionary: <xsl:value-of select="$filepath"/></xsl:message>
                            </xsl:catch>
                        </xsl:try>
                    </xsl:for-each>
                </dictionaries>
            </xsl:variable>
            
            <!-- Generate the output with grouped code types -->
            <codeTypeElements>
                <xsl:for-each-group select="$all-dictionaries/dictionaries/dictionary" group-by="id">
                    <codeType>
                        <xpath><xsl:value-of select="current-group()[1]/xpath"/></xpath>
                        <xsl:for-each select="current-group()">
                            <dictionaryURL><xsl:value-of select="url"/></dictionaryURL>
                        </xsl:for-each>
                    </codeType>
                </xsl:for-each-group>
            </codeTypeElements>
        </xsl:template>
        
        <!-- Function to convert ID to XPath - now in the diggs namespace -->
        <xsl:function name="diggs:construct-xpath" as="xs:string">
            <xsl:param name="id" as="xs:string"/>
            
            <xsl:choose>
                <xsl:when test="not(contains($id, '_'))">
                    <!-- Simple case: just a single element name -->
                    <xsl:value-of select="concat('//*[local-name() = ''', $id, ''']')"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Complex case: path with segments -->
                    <xsl:variable name="segments" select="tokenize($id, '_')"/>
                    <xsl:value-of select="string-join(for $segment in $segments
                                         return concat('/*[local-name() = ''', $segment, ''']'),
                                         '')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:function>
        
        </xsl:stylesheet>
        