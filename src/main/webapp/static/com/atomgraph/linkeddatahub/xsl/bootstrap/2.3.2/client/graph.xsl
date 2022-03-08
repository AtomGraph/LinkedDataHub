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

    <!-- TEMPLATES -->
    
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
    
    <!-- EVENT HANDLERS -->
    
    <xsl:template match="svg:g[@class = 'subject']" mode="ixsl:onmouseover"> <!-- should be ixsl:onmouseenter but it's not supported by Saxon-JS 2.3 -->
        <xsl:variable name="svg" select="ancestor::svg:svg" as="element()"/>
        
        <!-- add highlighted <marker> if it doesn't exist yet -->
        <xsl:for-each select="$svg">
            <xsl:call-template name="add-highlighted-marker">
                <xsl:with-param name="id" select="$highlighted-marker-id"/>
            </xsl:call-template>
        </xsl:for-each>
        
        <!-- highlight this node -->
        <ixsl:set-attribute name="stroke" select="$highlight-color" object="svg:circle"/>

        <!-- highlight the lines going to/from this node and move to the end of the document (visually, move to front) -->
        <xsl:for-each select="key('lines-by-start', @id, ixsl:page()) | key('lines-by-end', @id, ixsl:page())">
            <ixsl:set-attribute name="stroke" select="$highlight-color"/>
            <ixsl:set-attribute name="marker-end" select="'url(#' || $highlighted-marker-id || ')'"/>
            <xsl:sequence select="ixsl:call(ancestor::svg:svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <!-- move line end nodes to the end of the document (visually, move to front) -->
        <xsl:for-each select="id(key('lines-by-start', @id, ixsl:page())/@data-id2, ixsl:page()) | id(key('lines-by-end', @id, ixsl:page())/@data-id1, ixsl:page())">
            <ixsl:set-attribute name="stroke" select="$highlight-color" object="svg:circle"/>
            <xsl:sequence select="ixsl:call($svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <!-- move start node to the end of the document (visually, move to front) -->
        <xsl:sequence select="ixsl:call($svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="svg:g[@class = 'subject']" mode="ixsl:onmouseout">
        <!-- unhighlight this node -->
        <ixsl:set-attribute name="stroke" select="'gray'" object="svg:circle"/>

        <!-- unhighlight end nodes -->
        <xsl:for-each select="id(key('lines-by-start', @id, ixsl:page())/@data-id2, ixsl:page()) | id(key('lines-by-end', @id, ixsl:page())/@data-id1, ixsl:page())">
            <ixsl:set-attribute name="stroke" select="'gray'" object="svg:circle"/>
        </xsl:for-each>

        <!-- unhighlight the lines going to/from this node -->
        <xsl:for-each select="key('lines-by-start', @id, ixsl:page()) | key('lines-by-end', @id, ixsl:page())">
            <ixsl:set-attribute name="stroke" select="'gray'"/>
            <ixsl:set-attribute name="marker-end" select="'url(#triangle)'"/>
        </xsl:for-each>
        
<!--        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.graph'), 'selected-node')">
            <xsl:message>onmouseout remove property</xsl:message>
            <ixsl:remove-property name="selected-node" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
        </xsl:if>-->
    </xsl:template>
    
    <!-- SVG drag implementation from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/ -->

    <xsl:template match="svg:svg" mode="ixsl:onclick">
        <xsl:variable name="bound" select="ixsl:call(., 'getBoundingClientRect', [])"/>
        <!-- TO-DO: the calculations might need to be adjusted for borders and padding: https://stackoverflow.com/a/47822104/1003113 -->
<!--        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX') - (ixsl:get($bound, 'left') + ixsl:get(ixsl:window(), 'scrollX'))"/>
        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY') - (ixsl:get($bound, 'top') + ixsl:get(ixsl:window(), 'scrollY'))"/>-->
        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')"/>
        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')"/>
        <xsl:variable name="point" select="ixsl:call(., 'createSVGPoint', [])"/>
        <ixsl:set-property name="x" select="$dom-x" object="$point"/>
        <ixsl:set-property name="y" select="$dom-y" object="$point"/>
        <xsl:variable name="ctm" select="ixsl:call(., 'getScreenCTM', [])"/>
        <xsl:variable name="svg-point" select="ixsl:call($point, 'matrixTransform', [ ixsl:call($ctm, 'inverse', []) ])"/>
        <xsl:variable name="svg-x" select="ixsl:get($svg-point, 'x')"/>
        <xsl:variable name="svg-y" select="ixsl:get($svg-point, 'y')"/>
        
        <xsl:message>ixsl:get(ixsl:event(), 'clientX'): <xsl:value-of select="ixsl:get(ixsl:event(), 'clientX')"/> ixsl:get(ixsl:event(), 'clientY'): <xsl:value-of select="ixsl:get(ixsl:event(), 'clientY')"/></xsl:message>
        <xsl:message>ixsl:get(ixsl:window(), 'scrollX'): <xsl:value-of select="ixsl:get(ixsl:window(), 'scrollX')"/> ixsl:get(ixsl:window(), 'scrollY'): <xsl:value-of select="ixsl:get(ixsl:window(), 'scrollY')"/></xsl:message>
        <xsl:message>ixsl:get($bound, 'left'): <xsl:value-of select="ixsl:get($bound, 'left')"/> ixsl:get($bound, 'top'): <xsl:value-of select="ixsl:get($bound, 'top')"/></xsl:message>
        <xsl:message>$dom-x: <xsl:value-of select="$dom-x"/> $dom-y: <xsl:value-of select="$dom-y"/></xsl:message>
        <xsl:message>$svg-x: <xsl:value-of select="$svg-x"/> $svg-y: <xsl:value-of select="$svg-y"/></xsl:message>
        <xsl:message>viewBox.baseVal.x: <xsl:value-of select="ixsl:get(., 'viewBox.baseVal.x')"/> viewBox.baseVal.y: <xsl:value-of select="ixsl:get(., 'viewBox.baseVal.y')"/></xsl:message>
        
        <xsl:result-document href="?." method="ixsl:append-content">
            <circle xmlns="http://www.w3.org/2000/svg" fill="green" cx="{$svg-x}" cy="{$svg-y}" r="5"/>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="svg:svg" mode="ixsl:onmousedown">
<!--        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')"/>
        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')"/>
        <xsl:variable name="point" select="ixsl:call(ancestor::svg:svg, 'createSVGPoint', [])"/>
        <ixsl:set-property name="x" select="$dom-x" object="$point"/>
        <ixsl:set-property name="y" select="$dom-y" object="$point"/>
        <xsl:variable name="ctm" select="ixsl:call(., 'getScreenCTM', [])"/>
        <xsl:variable name="svg-point" select="ixsl:call($point, 'matrixTransform', [ ixsl:call($ctm, 'inverse', []) ])"/>
        <xsl:variable name="svg-x" select="ixsl:get($svg-point, 'x')"/>
        <xsl:variable name="svg-y" select="ixsl:get($svg-point, 'y')"/>

<xsl:message>onmousedown $svg-x: <xsl:value-of select="$svg-x"/> $svg-y: <xsl:value-of select="$svg-y"/></xsl:message>-->

        <xsl:if test="ixsl:get(ixsl:event(), 'target')/ancestor-or-self::svg:g[@class = 'subject']">
            <ixsl:set-property name="selected-node" select="ixsl:get(ixsl:event(), 'target')/ancestor-or-self::svg:g[@class = 'subject']" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
        </xsl:if>
        
        
<!--        <ixsl:set-property name="svg-x" select="$svg-x" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
        <ixsl:set-property name="svg-y" select="$svg-y" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>-->
    </xsl:template>

    <xsl:template match="svg:svg" mode="ixsl:onmousemove">
        <xsl:choose>
            <xsl:when test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.graph'), 'selected-node')">
                <xsl:variable name="selected-node" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graph.selected-node')"/>
                <xsl:choose>
                    <xsl:when test="ixsl:get(ixsl:event(), 'target') is $selected-node">
                        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
                        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')"/>
                        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')"/>
                        <xsl:variable name="point" select="ixsl:call(., 'createSVGPoint', [])"/>
                        <ixsl:set-property name="x" select="$dom-x" object="$point"/>
                        <ixsl:set-property name="y" select="$dom-y" object="$point"/>
                        <xsl:variable name="ctm" select="ixsl:call(., 'getScreenCTM', [])"/>
                        <xsl:variable name="svg-point" select="ixsl:call($point, 'matrixTransform', [ ixsl:call($ctm, 'inverse', []) ])"/>
                        <xsl:variable name="svg-x" select="ixsl:get($svg-point, 'x')"/>
                        <xsl:variable name="svg-y" select="ixsl:get($svg-point, 'y')"/>
<!--                        <xsl:variable name="transform" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graph.transform')"/>
                        <xsl:sequence select="ixsl:call($transform, 'setTranslate', [ $coord-x - $svg-x, $coord-y - $svg-y ])"/>-->
                        <xsl:variable name="transforms" select="ixsl:get($selected-node, 'transform.baseVal')"/>
                        <!-- the element must have existing @transform, otherwise we'll get DOMException -->
                        <xsl:variable name="transform" select="ixsl:call($transforms, 'getItem', [ 0 ])"/>
<!--                        <xsl:variable name="translate-x" select="ixsl:get($transform, 'matrix.e')"/>
                        <xsl:variable name="translate-y" select="ixsl:get($transform, 'matrix.f')"/>
                        <xsl:message>onmousemove $translate-x: <xsl:value-of select="$translate-x"/> $translate-y: <xsl:value-of select="$translate-y"/></xsl:message>-->
                        <xsl:message>onmousemove $svg-x: <xsl:value-of select="$svg-x"/> $svg-y: <xsl:value-of select="$svg-y"/></xsl:message>
                        <xsl:sequence select="ixsl:call($transform, 'setTranslate', [ $svg-x, $svg-y ])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>LinkedDataHub.graph.selected-node is not the current node</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>LinkedDataHub.graph.selected-node empty</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="svg:svg" mode="ixsl:onmouseup">
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.graph'), 'selected-node')">
            <xsl:message>onmouseup remove property</xsl:message>
            <ixsl:remove-property name="selected-node" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
