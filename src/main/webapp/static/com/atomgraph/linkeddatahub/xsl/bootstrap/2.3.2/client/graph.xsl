<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>
    
    <xsl:key name="lines-by-start" match="svg:line" use="@data-id1"/>
    <xsl:key name="lines-by-end" match="svg:line" use="@data-id2"/>

    <xsl:variable name="highlight-color" select="'yellow'" as="xs:string"/>
    <xsl:variable name="highlighted-marker-id" select="'triangle-hl'" as="xs:string"/>

    <!-- EVENT HANDLERS -->
    
    <xsl:template match="svg:g[@class = 'subject']" mode="ixsl:onmouseover"> <!-- should be ixsl:onmouseenter but it's not supported by Saxon-JS 2.3 -->
        <xsl:variable name="svg" select="ancestor::svg:svg" as="element()"/>
        
        <!-- add highlighted <marker> if it doesn't exist yet -->
        <xsl:for-each select="$svg">
            <xsl:call-template name="add-highlighted-marker">
                <xsl:with-param name="id" select="$highlighted-marker-id"/>
            </xsl:call-template>
        </xsl:for-each>
        
        <!-- highlight the node -->
        <ixsl:set-attribute name="stroke" select="$highlight-color" object="svg:circle"/>

        <!-- highlight the lines going to/from the node and move to the end of the document (visually, move to front) -->
        <xsl:for-each select="key('lines-by-start', @id, ixsl:page()) | key('lines-by-end', @id, ixsl:page())">
            <ixsl:set-attribute name="stroke" select="$highlight-color"/>
            <ixsl:set-attribute name="marker-end" select="'url(#' || $highlighted-marker-id || ')'"/>
            <xsl:sequence select="ixsl:call(ancestor::svg:svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <!-- move line end nodes to the end of the document (visually, move to front) -->
        <xsl:for-each select="id(key('lines-by-start', @id, ixsl:page())/@data-id2, ixsl:page())/svg:circle | id(key('lines-by-end', @id, ixsl:page())/@data-id1, ixsl:page())/svg:circle">
            <ixsl:set-attribute name="stroke" select="$highlight-color"/>
            <xsl:sequence select="ixsl:call($svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <!-- move start node to the end of the document (visually, move to front) -->
        <xsl:sequence select="ixsl:call($svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="svg:g[@class = 'subject']" mode="ixsl:onmouseout">
        <!-- unhighlight the node -->
        <ixsl:set-attribute name="stroke" select="'gray'" object="svg:circle"/>

        <!-- unhighlight the lines going to/from the node -->
        <xsl:for-each select="key('lines-by-start', @id, ixsl:page()) | key('lines-by-end', @id, ixsl:page())">
            <ixsl:set-attribute name="stroke" select="'gray'"/>
            <ixsl:set-attribute name="marker-end" select="'url(#triangle)'"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="add-highlighted-marker">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:if test="not(svg:defs/svg:marker[@id = $id])">
            <xsl:for-each select="svg:defs">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <svg:marker id="{$id}" viewBox="0 0 10 10" refX="10" refY="5" markerUnits="strokeWidth" markerWidth="8" markerHeight="6" orient="auto">
                        <svg:path d="M 0 0 L 10 5 L 0 10 z" fill="{$highlight-color}"/>
                    </svg:marker>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
