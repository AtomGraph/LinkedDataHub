<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

    <xsl:output method="xml" indent="yes"/>

    <!-- The thread count of the connector behind the proxy. letsencrypt-tomcat.xsl, which generates
         server.xml from the base image's, sizes only the HTTPS connector; this one is left at Tomcat's
         default of 200. The count matters beyond capacity: every server-side render calls back into
         this same connector through the proxy, so it is also the number of renders that can end up
         waiting on each other (tests/load/render-burst-no-deadlock.sh). -->
    <xsl:param name="Connector.maxThreads.http"/>

    <xsl:template match="Server/Service/Connector[not(@SSLEnabled = 'true')]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="$Connector.maxThreads.http">
                <xsl:attribute name="maxThreads">
                    <xsl:value-of select="$Connector.maxThreads.http"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
