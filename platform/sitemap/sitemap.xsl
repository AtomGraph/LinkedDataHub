<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
xmlns:srx="http://www.w3.org/2005/sparql-results#"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />
    
    <xsl:template match="/srx:sparql">
        <urlset>
            <xsl:apply-templates/>
        </urlset>
    </xsl:template>

    <xsl:template match="srx:head"/>

    <xsl:template match="srx:results">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="srx:result">
        <url>
            <xsl:apply-templates/>
        </url>
    </xsl:template>

    <xsl:template match="srx:binding[@name = 'loc'][srx:uri]">
        <loc>
            <xsl:value-of select="srx:uri"/>
        </loc>
    </xsl:template>

    <xsl:template match="srx:binding[@name = 'lastmod'][srx:literal/@datatype = 'http://www.w3.org/2001/XMLSchema#dateTime']">
        <lastmod>
            <xsl:value-of select="srx:literal"/>
        </lastmod>
    </xsl:template>

</xsl:stylesheet>