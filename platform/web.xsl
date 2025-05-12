<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:jee="https://jakarta.ee/xml/ns/jakartaee"
>

    <xsl:output method="xml" indent="yes"/>

    <xsl:param name="jee:servlet-name"/>

    <!-- replace server's JAX-RS application (don't touch other <servlet-name>s) -->
    <xsl:template match="jee:servlet-name/text()[. = 'com.atomgraph.linkeddatahub.Application']">
        <xsl:choose>
            <xsl:when test="$jee:servlet-name">
                <xsl:value-of select="$jee:servlet-name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>