<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:math="http://www.w3.org/2005/xpath-functions/math"
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
    <!-- cannot reuse the 'resources' key because it's checking whether resources have properties -->
    <xsl:key name="descriptions" match="*[@rdf:about] | *[@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>

    <xsl:variable name="highlight-color" select="'gold'" as="xs:string"/>
    <xsl:variable name="highlighted-marker-id" select="'triangle-hl'" as="xs:string"/>

    <!-- TEMPLATES -->
    
    <xsl:template match="@* | node()" mode="ldh:MergeRDF">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="ldh:MergeRDF">
        <xsl:param name="new-rdf" as="document-node()" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
            
            <xsl:variable name="existing-rdf" select="root(.)" as="document-node()"/>
            <!-- Add new descriptions that don't exist in the existing document -->
            <xsl:for-each select="$new-rdf/rdf:RDF/*[@rdf:about]">
                <xsl:if test="not(key('descriptions', @rdf:about, $existing-rdf))">
                    <xsl:apply-templates select="." mode="#current"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="rdf:Description" mode="ldh:MergeRDF">
        <xsl:param name="new-rdf" as="document-node()" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- Add new properties from $new-rdf for the same resource -->
            <xsl:variable name="resource-uri" select="@rdf:about" as="xs:anyURI"/>
            <xsl:apply-templates select="key('resources', $resource-uri, $new-rdf)/*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- remove wrapper elements -->
    <xsl:template match="rdf:Description" mode="ac:SVG" xmlns="http://www.w3.org/2000/svg">
        <g>
            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current"/>

            <xsl:apply-templates mode="#current"/>
        </g>
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
    
    <!-- EVENT HANDLERS -->
    
    <xsl:template match="svg:g/svg:g[@class = 'subject']" mode="ixsl:onmouseover"> <!-- should be ixsl:onmouseenter but it's not supported by Saxon-JS 2.3 -->
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
        <xsl:for-each select="key('lines-by-start', @id) | key('lines-by-end', @id)">
            <ixsl:set-attribute name="stroke" select="$highlight-color"/>
            <ixsl:set-attribute name="marker-end" select="'url(#' || $highlighted-marker-id || ')'"/>
            <xsl:sequence select="ixsl:call(ancestor::svg:svg, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <!-- move line end node groups to the end of the document (visually, move to front) -->
        <xsl:if test="key('lines-by-start', @id)/@data-id2)">
            <xsl:for-each select="id(key('lines-by-start', @id)/@data-id2)">
                <ixsl:set-attribute name="stroke" select="$highlight-color" object="svg:circle"/>
                <xsl:sequence select="ixsl:call($svg, 'appendChild', [ .. ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="key('lines-by-end', @id)">
            <xsl:for-each select="id(key('lines-by-end', @id)/@data-id1)">
                <ixsl:set-attribute name="stroke" select="$highlight-color" object="svg:circle"/>
                <xsl:sequence select="ixsl:call($svg, 'appendChild', [ .. ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
        </xsl:if>
        
        <!-- move the start node group to the end of the document (visually, move to front) -->
        <xsl:sequence select="ixsl:call($svg, 'appendChild', [ .. ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="svg:g/svg:g[@class = 'subject']" mode="ixsl:onmouseout">
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
            <!-- add the mouse offset within the element which was stored in onmousedown -->
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

    <!-- double-click to expand graph by loading resource's objects -->

    <xsl:template match="svg:g/svg:g[@class = 'subject']" mode="ixsl:ondblclick" xmlns="http://www.w3.org/2000/svg">
        <!-- Set cursor to progress -->
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="resource-uri" select="@about" as="xs:string"/>
        <xsl:variable name="svg" select="ancestor::svg:svg" as="element()"/>

        <xsl:message>Double-click on graph node: <xsl:value-of select="$resource-uri"/></xsl:message>

        <!-- Get origin node position -->
        <xsl:variable name="origin-transform" select="@transform" as="xs:string"/>
        <xsl:message>$origin-transform: <xsl:value-of select="$origin-transform"/></xsl:message>

        <xsl:variable name="origin-coords-raw" select="substring-before(substring-after($origin-transform, 'translate('), ')')"/>
        <xsl:message>$origin-coords-raw: <xsl:value-of select="$origin-coords-raw"/></xsl:message>

        <xsl:variable name="origin-coords" select="tokenize($origin-coords-raw, '[,\s]+')"/>
        <xsl:message>$origin-coords count: <xsl:value-of select="count($origin-coords)"/></xsl:message>
        <xsl:message>$origin-coords[1]: '<xsl:value-of select="$origin-coords[1]"/>'</xsl:message>
        <xsl:message>$origin-coords[2]: '<xsl:value-of select="$origin-coords[2]"/>'</xsl:message>

        <xsl:variable name="origin-x" select="xs:double($origin-coords[1])" as="xs:double"/>
        <xsl:variable name="origin-y" select="xs:double($origin-coords[2])" as="xs:double"/>

        <!-- get the RDF document from window.LinkedDataHub.contents -->
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="resource" select="key('descriptions', $resource-uri, $doc)" as="element()?"/>

        <!-- extract all object URIs from properties -->
        <xsl:variable name="object-uris" select="distinct-values($resource/*/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:message>Found <xsl:value-of select="count($object-uris)"/> object URIs</xsl:message>

        <!-- Get existing node URIs -->
        <xsl:variable name="existing-node-uris" select="$svg//svg:g[@class = 'subject']/@about" as="xs:string*"/>

        <!-- Filter to new URIs only -->
        <xsl:variable name="new-object-uris" select="$object-uris[not(. = $existing-node-uris)]" as="xs:anyURI*"/>
        <xsl:message>Creating <xsl:value-of select="count($new-object-uris)"/> new nodes</xsl:message>

        <xsl:variable name="radius" select="150" as="xs:double"/>
        <xsl:variable name="count" select="count($new-object-uris)" as="xs:integer"/>
        <xsl:variable name="source-node-id" select="@id" as="xs:string"/>

        <!-- Create RDF descriptions for new nodes and apply SVG templates -->
        <xsl:for-each select="$new-object-uris">
            <xsl:variable name="object-uri" select="." as="xs:anyURI"/>
            <xsl:variable name="index" select="position() - 1" as="xs:integer"/>

            <!-- Calculate position in circle -->
            <xsl:variable name="angle" select="($index div $count) * 2 * math:pi()" as="xs:double"/>
            <xsl:variable name="node-x" select="$origin-x + $radius * math:cos($angle)" as="xs:double"/>
            <xsl:variable name="node-y" select="$origin-y + $radius * math:sin($angle)" as="xs:double"/>

            <xsl:message>Creating node at x=<xsl:value-of select="$node-x"/> y=<xsl:value-of select="$node-y"/></xsl:message>

            <!-- Create RDF description element -->
            <xsl:variable name="rdf-desc" as="element()">
                <rdf:Description rdf:about="{$object-uri}"/>
            </xsl:variable>

            <!-- Apply SVG template to generate node -->
            <xsl:variable name="node-svg" as="element()">
                <xsl:apply-templates select="$rdf-desc" mode="ac:SVG"/>
            </xsl:variable>

            <xsl:message>
                $node-svg: <xsl:value-of select="serialize($node-svg)"/>
            </xsl:message>

            <!-- Set position on inner subject <g> node, keeping full wrapper structure -->
            <xsl:variable name="positioned-node" as="element()">
                <xsl:apply-templates select="$node-svg" mode="ldh:set-svg-node-position">
                    <xsl:with-param name="x" select="$node-x"/>
                    <xsl:with-param name="y" select="$node-y"/>
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:message>
                $positioned-node: <xsl:value-of select="serialize($positioned-node)"/>
            </xsl:message>

            <!-- Create line from source node to new node (insert first so it appears under nodes) -->
            <xsl:variable name="target-node-id" select="$positioned-node//svg:g[@class = 'subject']/@id" as="xs:string"/>
            <xsl:for-each select="$svg">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <line data-id1="{$source-node-id}" data-id2="{$target-node-id}"
                          x1="{$origin-x}" y1="{$origin-y}" x2="{$node-x}" y2="{$node-y}"
                          stroke="gray" stroke-width="1" marker-end="url(#triangle)">
                        <title>Connected</title>
                    </line>
                </xsl:result-document>
            </xsl:for-each>

            <!-- Insert new node into SVG DOM (after lines so it appears on top) -->
            <xsl:for-each select="$svg">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:copy-of select="$positioned-node"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>

        <!-- Recalculate viewBox to include all nodes - select from updated SVG in DOM -->
        <xsl:variable name="svg" select="ancestor::svg:svg" as="element()"/>
        <xsl:variable name="all-nodes" select="$svg//svg:g[@class = 'subject']" as="element()*"/>
        <xsl:variable name="padding" select="50" as="xs:double"/>

        <xsl:message>Recalculating viewBox for <xsl:value-of select="count($all-nodes)"/> nodes</xsl:message>

        <!-- collect all x positions from nodes -->
        <xsl:variable name="all-x" as="xs:double*">
            <xsl:for-each select="$all-nodes">
                <xsl:variable name="transforms" select="ixsl:get(., 'transform.baseVal')"/>
                <xsl:variable name="transform" select="ixsl:call($transforms, 'getItem', [ 0 ])"/>
                <xsl:variable name="matrix" select="ixsl:get($transform, 'matrix')"/>
                <xsl:sequence select="ixsl:get($matrix, 'e')"/>
            </xsl:for-each>
        </xsl:variable>

        <!-- collect all y positions from nodes -->
        <xsl:variable name="all-y" as="xs:double*">
            <xsl:for-each select="$all-nodes">
                <xsl:variable name="transforms" select="ixsl:get(., 'transform.baseVal')"/>
                <xsl:variable name="transform" select="ixsl:call($transforms, 'getItem', [ 0 ])"/>
                <xsl:variable name="matrix" select="ixsl:get($transform, 'matrix')"/>
                <xsl:sequence select="ixsl:get($matrix, 'f')"/>
            </xsl:for-each>
        </xsl:variable>

        <!-- get existing viewBox -->
        <xsl:variable name="existing-viewBox" select="ixsl:get($svg, 'viewBox.baseVal')" as="item()?"/>
        <xsl:variable name="existing-x" select="ixsl:get($existing-viewBox, 'x')" as="xs:double"/>
        <xsl:variable name="existing-y" select="ixsl:get($existing-viewBox, 'y')" as="xs:double"/>
        <xsl:variable name="existing-width" select="ixsl:get($existing-viewBox, 'width')" as="xs:double"/>
        <xsl:variable name="existing-height" select="ixsl:get($existing-viewBox, 'height')" as="xs:double"/>
        <xsl:variable name="existing-max-x" select="$existing-x + $existing-width" as="xs:double"/>
        <xsl:variable name="existing-max-y" select="$existing-y + $existing-height" as="xs:double"/>

        <!-- calculate bounding box with padding, expanding existing viewBox if needed -->
        <xsl:message>$all-x: <xsl:value-of select="$all-x"/></xsl:message>
        <xsl:message>$all-y: <xsl:value-of select="$all-y"/></xsl:message>
        <xsl:message>$existing-x: <xsl:value-of select="$existing-x"/></xsl:message>
        <xsl:message>$existing-y: <xsl:value-of select="$existing-y"/></xsl:message>
        <xsl:message>$existing-max-x: <xsl:value-of select="$existing-max-x"/></xsl:message>
        <xsl:message>$existing-max-y: <xsl:value-of select="$existing-max-y"/></xsl:message>

        <xsl:variable name="min-x" select="min(($all-x, $existing-x)) - $padding" as="xs:double"/>
        <xsl:message>$min-x: <xsl:value-of select="$min-x"/></xsl:message>

        <xsl:variable name="min-y" select="min(($all-y, $existing-y)) - $padding" as="xs:double"/>
        <xsl:message>$min-y: <xsl:value-of select="$min-y"/></xsl:message>

        <xsl:variable name="max-x" select="max(($all-x, $existing-max-x)) + $padding" as="xs:double"/>
        <xsl:message>$max-x: <xsl:value-of select="$max-x"/></xsl:message>

        <xsl:variable name="max-y" select="max(($all-y, $existing-max-y)) + $padding" as="xs:double"/>
        <xsl:message>$max-y: <xsl:value-of select="$max-y"/></xsl:message>

        <xsl:variable name="width" select="$max-x - $min-x" as="xs:double"/>
        <xsl:message>$width: <xsl:value-of select="$width"/></xsl:message>

        <xsl:variable name="height" select="$max-y - $min-y" as="xs:double"/>
        <xsl:message>$height: <xsl:value-of select="$height"/></xsl:message>

        <!-- animate viewBox transition -->
        <xsl:call-template name="ldh:AnimateViewBox">
            <xsl:with-param name="svg" select="$svg"/>
            <xsl:with-param name="current-step" select="0"/>
            <xsl:with-param name="max-steps" select="30"/>
            <xsl:with-param name="start-x" select="$existing-x"/>
            <xsl:with-param name="start-y" select="$existing-y"/>
            <xsl:with-param name="start-width" select="$existing-width"/>
            <xsl:with-param name="start-height" select="$existing-height"/>
            <xsl:with-param name="target-x" select="$min-x"/>
            <xsl:with-param name="target-y" select="$min-y"/>
            <xsl:with-param name="target-width" select="$width"/>
            <xsl:with-param name="target-height" select="$height"/>
        </xsl:call-template>

        <!-- Restore cursor to default -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>

    <!-- Template to set position on inner subject <g> while preserving wrapper structure -->
    <xsl:template match="svg:g[@class = 'subject']" mode="ldh:set-svg-node-position">
        <xsl:param name="x" as="xs:double"/>
        <xsl:param name="y" as="xs:double"/>
        <xsl:copy>
            <xsl:copy-of select="@* except @transform"/>
            <xsl:attribute name="transform" select="'translate(' || $x || ' ' || $y || ')'"/>
            <xsl:copy-of select="node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Identity template for ldh:set-svg-node-position mode - copy everything else unchanged -->
    <xsl:template match="node() | @*" mode="ldh:set-svg-node-position">
        <xsl:param name="x" as="xs:double"/>
        <xsl:param name="y" as="xs:double"/>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="ldh:set-svg-node-position">
                <xsl:with-param name="x" select="$x"/>
                <xsl:with-param name="y" select="$y"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!-- Animate viewBox transition over multiple steps -->
    <xsl:template name="ldh:AnimateViewBox">
        <xsl:param name="svg" as="element()"/>
        <xsl:param name="current-step" as="xs:integer"/>
        <xsl:param name="max-steps" as="xs:integer"/>
        <xsl:param name="step-delay" as="xs:integer" select="25"/>
        <xsl:param name="start-x" as="xs:double"/>
        <xsl:param name="start-y" as="xs:double"/>
        <xsl:param name="start-width" as="xs:double"/>
        <xsl:param name="start-height" as="xs:double"/>
        <xsl:param name="target-x" as="xs:double"/>
        <xsl:param name="target-y" as="xs:double"/>
        <xsl:param name="target-width" as="xs:double"/>
        <xsl:param name="target-height" as="xs:double"/>

        <xsl:if test="$current-step le $max-steps">
            <!-- Calculate interpolation factor (0 to 1) -->
            <xsl:variable name="t" select="$current-step div $max-steps" as="xs:double"/>

            <!-- Interpolate current viewBox values -->
            <xsl:variable name="current-x" select="$start-x + ($target-x - $start-x) * $t" as="xs:double"/>
            <xsl:variable name="current-y" select="$start-y + ($target-y - $start-y) * $t" as="xs:double"/>
            <xsl:variable name="current-width" select="$start-width + ($target-width - $start-width) * $t" as="xs:double"/>
            <xsl:variable name="current-height" select="$start-height + ($target-height - $start-height) * $t" as="xs:double"/>

            <!-- Update viewBox -->
            <xsl:variable name="viewBox-string" select="$current-x || ' ' || $current-y || ' ' || $current-width || ' ' || $current-height" as="xs:string"/>
            <ixsl:set-attribute name="viewBox" select="$viewBox-string" object="$svg"/>

            <!-- Schedule next step -->
            <xsl:if test="$current-step lt $max-steps">
                <ixsl:schedule-action wait="$step-delay">
                    <xsl:call-template name="ldh:AnimateViewBox">
                        <xsl:with-param name="svg" select="$svg"/>
                        <xsl:with-param name="current-step" select="$current-step + 1"/>
                        <xsl:with-param name="max-steps" select="$max-steps"/>
                        <xsl:with-param name="step-delay" select="$step-delay"/>
                        <xsl:with-param name="start-x" select="$start-x"/>
                        <xsl:with-param name="start-y" select="$start-y"/>
                        <xsl:with-param name="start-width" select="$start-width"/>
                        <xsl:with-param name="start-height" select="$start-height"/>
                        <xsl:with-param name="target-x" select="$target-x"/>
                        <xsl:with-param name="target-y" select="$target-y"/>
                        <xsl:with-param name="target-width" select="$target-width"/>
                        <xsl:with-param name="target-height" select="$target-height"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:if>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
