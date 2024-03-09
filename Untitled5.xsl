<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:diggs="http://diggsml.org/schemas/2.6" xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:template match="/">
        <xsl:for-each select="gml:Dictionary/gml:dictionaryEntry/diggs:Definition">
            <xsl:value-of select="./gml:description"/>|
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>