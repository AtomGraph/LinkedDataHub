<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
    <xsl:output method="xml" indent="yes"/>
  
    <xsl:param name="https.trustManagerClassName"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- set truststore manager -->
    <xsl:template match="Connector[@protocol = 'org.apache.coyote.http11.Http11NioProtocol']">
        <xsl:copy>
            <xsl:attribute name="trustManagerClassName">
                <xsl:value-of select="$https.trustManagerClassName"/>
            </xsl:attribute>

            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>