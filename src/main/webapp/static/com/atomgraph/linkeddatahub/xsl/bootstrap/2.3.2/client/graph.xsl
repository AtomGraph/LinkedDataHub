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

    <xsl:variable name="highlight-color" select="'gold'" as="xs:string"/>
    <xsl:variable name="highlighted-marker-id" select="'triangle-hl'" as="xs:string"/>
    <xsl:variable name="svg-transform-translate" select="2" as="xs:integer"/> <!-- https://developer.mozilla.org/en-US/docs/Web/API/SVGTransform -->
    <xsl:variable name="svg-transform-scale" select="3" as="xs:integer"/> <!-- https://developer.mozilla.org/en-US/docs/Web/API/SVGTransform -->

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
    </xsl:template>
    
    <xsl:template match="svg:svg" mode="ixsl:onmousedown">
        <xsl:if test="ixsl:get(ixsl:event(), 'target')/ancestor-or-self::svg:g[@class = 'subject']">
            <xsl:variable name="selected-node" select="ixsl:get(ixsl:event(), 'target')/ancestor-or-self::svg:g[@class = 'subject']" as="element()"/>
            <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')"/>
            <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')"/>
            <xsl:variable name="bound" select="ixsl:call($selected-node, 'getBoundingClientRect', [])"/>
            <xsl:variable name="offset-x" select="ixsl:get($bound, 'width') div 2 - ($dom-x - ixsl:get($bound, 'x'))"/>
            <xsl:variable name="offset-y" select="ixsl:get($bound, 'height') div 2 - ($dom-y - ixsl:get($bound, 'y'))"/>
            
            <ixsl:set-property name="offset-x" select="$offset-x" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
            <ixsl:set-property name="offset-y" select="$offset-y" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
            <ixsl:set-property name="selected-node" select="$selected-node" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="svg:svg" mode="ixsl:onmousemove">
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.graph'), 'selected-node')">
            <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
            <xsl:variable name="selected-node" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graph.selected-node')" as="element()"/>
            <xsl:variable name="offset-x" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graph.offset-x')"/>
            <xsl:variable name="offset-y" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graph.offset-y')"/>
            <!-- add the mouse offset within the element which was stored in onmousedown -->?
            <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX') + $offset-x"/>
            <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY') + $offset-y"/>
            <xsl:variable name="point" select="ldh:new('DOMPoint', [ $dom-x, $dom-y ])"/>
            <xsl:variable name="ctm" select="ixsl:call(., 'getScreenCTM', [])"/>
            <xsl:variable name="svg-point" select="ixsl:call($point, 'matrixTransform', [ ixsl:call($ctm, 'inverse', []) ])"/>
            <xsl:variable name="svg-x" select="ixsl:get($svg-point, 'x')"/>
            <xsl:variable name="svg-y" select="ixsl:get($svg-point, 'y')"/>
            <xsl:variable name="transforms" select="ixsl:get($selected-node, 'transform.baseVal')"/>
            <!-- the element must have existing @transform, otherwise we'll get DOMException -->
            <xsl:variable name="transform" select="ixsl:call($transforms, 'getItem', [ 0 ])"/>
            <xsl:sequence select="ixsl:call($transform, 'setTranslate', [ $svg-x, $svg-y ])"/>

            <!-- move line ends together with the target node -->
            <xsl:for-each select="key('lines-by-start', $selected-node/@id, ixsl:page())">
                <ixsl:set-attribute name="x1" select="string($svg-x)"/>
                <ixsl:set-attribute name="y1" select="string($svg-y)"/>
            </xsl:for-each>
            <xsl:for-each select="key('lines-by-end', $selected-node/@id, ixsl:page())">
                <ixsl:set-attribute name="x2" select="string($svg-x)"/>
                <ixsl:set-attribute name="y2" select="string($svg-y)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="svg:svg" mode="ixsl:onmouseup">
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.graph'), 'selected-node')">
            <ixsl:remove-property name="selected-node" object="ixsl:get(ixsl:window(), 'LinkedDataHub.graph')"/>
        </xsl:if>
    </xsl:template>

    <!-- ported JS code from https://codepen.io/osublake/pen/oGoyYb -->
    <xsl:template match="svg:svg" mode="ixsl:onwheel">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/> <!-- Ignoring 'preventDefault()' call on event of type 'wheel' from a listener registered as 'passive'. -->
        <xsl:variable name="zoom-scale-factor" select="1.2" as="xs:double"/>
        <xsl:variable name="delta" select="ixsl:get(ixsl:event(), 'wheelDelta')" as="xs:double"/>
        <xsl:variable name="normalized" select="if ($delta mod 120 = 0) then $delta div 120 else $delta div 12" as="xs:double"/>
        <xsl:variable name="scale-delta" select="if ($normalized &gt; 0) then 1 div $zoom-scale-factor else $zoom-scale-factor" as="xs:double"/>
        
        <xsl:message>
            $delta: <xsl:value-of select="$delta"/>
            $normalized: <xsl:value-of select="$normalized"/>
            $scale-delta: <xsl:value-of select="$scale-delta"/>
            ixsl:get(ixsl:event(), 'clientX'): <xsl:value-of select="ixsl:get(ixsl:event(), 'clientX')"/>
            ixsl:get(ixsl:event(), 'clientY'): <xsl:value-of select="ixsl:get(ixsl:event(), 'clientY')"/>
            ixsl:get(., 'viewBox.baseVal.x'): <xsl:value-of select="ixsl:get(., 'viewBox.baseVal.x')"/>
            ixsl:get(., 'viewBox.baseVal.y'): <xsl:value-of select="ixsl:get(., 'viewBox.baseVal.y')"/>
        </xsl:message>
        
        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')"/>
        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')"/>
        <xsl:variable name="bound" select="ixsl:call(., 'getBoundingClientRect', [])"/>
        <xsl:variable name="offset-x" select="ixsl:get($bound, 'width') div 2 - ($dom-x - ixsl:get($bound, 'x'))"/>
        <xsl:variable name="offset-y" select="ixsl:get($bound, 'height') div 2 - ($dom-y - ixsl:get($bound, 'y'))"/>
        <xsl:variable name="point" select="ixsl:call(., 'createSVGPoint', [])" as="item()"/>
        <ixsl:set-property name="x" select="$offset-x" object="$point"/>
        <ixsl:set-property name="y" select="$offset-y" object="$point"/>
        
        <xsl:variable name="start-point" select="ixsl:call($point, 'matrixTransform', [ ixsl:call(ixsl:call(., 'getScreenCTM', []), 'inverse', []) ])" as="item()"/>
        <xsl:variable name="viewbox" select="ixsl:get(., 'viewBox.baseVal')" as="item()"/>
        <ixsl:set-property name="x" select="(ixsl:get($start-point, 'x') - ixsl:get($viewbox, 'x')) * ($scale-delta - 1)" object="$viewbox"/>
        <ixsl:set-property name="y" select="(ixsl:get($start-point, 'y') - ixsl:get($viewbox, 'y')) * ($scale-delta - 1)" object="$viewbox"/>
        <ixsl:set-property name="width" select="$width * $scale-delta" object="$viewbox"/>
        <ixsl:set-property name="height" select="$height * $scale-delta" object="$viewbox"/>
        
<!--  event.preventDefault();
  
  pivotAnimation.reverse();
  
  var normalized;  
  var delta = event.wheelDelta;

  if (delta) {
    normalized = (delta % 120) == 0 ? delta / 120 : delta / 12;
  } else {
    delta = event.deltaY || event.detail || 0;
    normalized = -(delta % 3 ? delta * 10 : delta / 3);
  }
  
  var scaleDelta = normalized > 0 ? 1 / zoom.scaleFactor : zoom.scaleFactor;
  
  point.x = event.clientX;
  point.y = event.clientY;
  
  var startPoint = point.matrixTransform(svg.getScreenCTM().inverse());
    
  var fromVars = {
    ease: zoom.ease,
    x: viewBox.x,
    y: viewBox.y,
    width: viewBox.width,
    height: viewBox.height,
  };
  
  viewBox.x -= (startPoint.x - viewBox.x) * (scaleDelta - 1);
  viewBox.y -= (startPoint.y - viewBox.y) * (scaleDelta - 1);
  viewBox.width *= scaleDelta;
  viewBox.height *= scaleDelta;
    
  zoom.animation = TweenLite.from(viewBox, zoom.duration, fromVars);  -->
    </xsl:template>

</xsl:stylesheet>
