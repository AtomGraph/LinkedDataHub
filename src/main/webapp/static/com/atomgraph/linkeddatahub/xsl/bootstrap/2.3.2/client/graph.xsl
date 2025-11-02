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

    <xsl:variable name="highlight-color" select="'gold'" as="xs:string"/>
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

    <xsl:template match="svg:g[@class = 'subject']" mode="ixsl:ondblclick">
        <xsl:variable name="resource-uri" select="@about" as="xs:string"/>
        <xsl:variable name="svg" select="ancestor::svg:svg" as="element()"/>

        <xsl:message>Double-click on graph node: <xsl:value-of select="$resource-uri"/></xsl:message>

        <!-- get the RDF document from window.LinkedDataHub.contents -->
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="resource" select="key('resources', $resource-uri, $doc)" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$resource">
                <xsl:message>Found resource with <xsl:value-of select="count($resource/*)"/> properties</xsl:message>

                <!-- extract all object URIs from properties -->
                <xsl:variable name="object-uris" select="$resource/*/@rdf:resource[starts-with(., 'http')]" as="xs:anyURI*"/>

                <xsl:message>Found <xsl:value-of select="count($object-uris)"/> object URIs</xsl:message>

                <!-- get the position of the clicked node -->
                <xsl:variable name="transforms" select="ixsl:get(., 'transform.baseVal')"/>
                <xsl:variable name="transform" select="ixsl:call($transforms, 'getItem', [ 0 ])"/>
                <xsl:variable name="matrix" select="ixsl:get($transform, 'matrix')"/>
                <xsl:variable name="source-x" select="ixsl:get($matrix, 'e')" as="xs:double"/>
                <xsl:variable name="source-y" select="ixsl:get($matrix, 'f')" as="xs:double"/>

                <!-- create new SVG nodes and lines for each object URI -->
                <xsl:variable name="radius" select="150" as="xs:double"/>
                <xsl:for-each select="$object-uris">
                    <xsl:variable name="object-uri" select="string(.)" as="xs:string"/>
                    <xsl:variable name="position" select="position()" as="xs:integer"/>

                    <!-- check if node already exists by @about attribute -->
                    <xsl:choose>
                        <xsl:when test="$svg//svg:g[@about = $object-uri]">
                            <xsl:message>Node already exists for: <xsl:value-of select="$object-uri"/></xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                        <!-- arrange new nodes in a circle around the source node -->
                        <xsl:variable name="angle" select="(2 * 3.14159 * $position) div count($object-uris)" as="xs:double"/>
                        <xsl:variable name="target-x" select="$source-x + $radius * math:cos($angle)" as="xs:double"/>
                        <xsl:variable name="target-y" select="$source-y + $radius * math:sin($angle)" as="xs:double"/>

                        <!-- get the resource from the document if it exists -->
                        <xsl:variable name="object-resource" select="key('resources', $object-uri, $doc)" as="element()?"/>

                        <!-- determine fill color based on rdf:type if resource exists in document -->
                        <xsl:variable name="random-seed" select="if ($object-resource/rdf:type/@rdf:*) then random-number-generator($object-resource/rdf:type[1]/@rdf:*)?number else ()" as="xs:double?"/>
                        <xsl:variable name="hsl" select="if ($random-seed) then 'hsl(' || $random-seed * 360 || ', 50%, 70%)' else ()" as="xs:string?"/>
                        <xsl:variable name="fill" select="if ($hsl) then $hsl else '#acf'" as="xs:string"/>

                        <!-- use URI fragment or last path segment as label -->
                        <xsl:variable name="label" select="if (contains($object-uri, '#')) then substring-after($object-uri, '#') else tokenize($object-uri, '/')[last()]" as="xs:string"/>

                        <!-- create the connecting line first (so it appears behind the node) -->
                        <xsl:variable name="r" select="15" as="xs:double"/> <!-- circle radius -->
                        <xsl:variable name="x-diff" select="$target-x - $source-x" as="xs:double"/>
                        <xsl:variable name="y-diff" select="$target-y - $source-y" as="xs:double"/>

                        <!-- calculate intersection point at target circle edge -->
                        <xsl:variable name="tan" select="$x-diff div $y-diff" as="xs:double"/>
                        <xsl:variable name="yc" select="abs($r div math:sqrt($tan * $tan + 1))" as="xs:double"/>
                        <xsl:variable name="xc" select="abs($r * $tan * math:sqrt(1 div ($tan * $tan + 1)))" as="xs:double"/>
                        <xsl:variable name="x2" select="if ($source-x gt $target-x) then ($target-x + $xc) else ($target-x - $xc)" as="xs:double"/>
                        <xsl:variable name="y2" select="if ($source-y gt $target-y) then ($target-y + $yc) else ($target-y - $yc)" as="xs:double"/>

                        <xsl:for-each select="$svg">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <svg:line x1="{$source-x}" y1="{$source-y}" x2="{$x2}" y2="{$y2}"
                                          stroke="gray" stroke-width="1" marker-end="url(#triangle)"
                                          data-id1="{$resource-uri}" data-id2="{$object-uri}"/>
                            </xsl:result-document>
                        </xsl:for-each>

                        <!-- create the new node after the line (so it appears on top) -->
                        <xsl:for-each select="$svg">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <svg:g id="{generate-id(current())}-{$position}" class="subject" about="{$object-uri}" transform="translate({$target-x} {$target-y})">
                                    <svg:circle r="15" cx="0" cy="0" fill="{$fill}" stroke="gray" stroke-width="1">
                                        <svg:title><xsl:value-of select="$object-uri"/></svg:title>
                                    </svg:circle>
                                    <svg:a href="{$object-uri}">
                                        <svg:text x="0" y="0" text-anchor="middle" font-size="6" dy="0.3em">
                                            <xsl:value-of select="$label"/>
                                        </svg:text>
                                    </svg:a>
                                </svg:g>
                            </xsl:result-document>
                        </xsl:for-each>

                        <xsl:message>Created node for: <xsl:value-of select="$object-uri"/> at (<xsl:value-of select="$target-x"/>, <xsl:value-of select="$target-y"/>)</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <!-- Recalculate viewBox to include all nodes -->
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
                <xsl:variable name="min-x" select="min(($all-x, $existing-x)) - $padding" as="xs:double"/>
                <xsl:variable name="min-y" select="min(($all-y, $existing-y)) - $padding" as="xs:double"/>
                <xsl:variable name="max-x" select="max(($all-x, $existing-max-x)) + $padding" as="xs:double"/>
                <xsl:variable name="max-y" select="max(($all-y, $existing-max-y)) + $padding" as="xs:double"/>
                <xsl:variable name="width" select="$max-x - $min-x" as="xs:double"/>
                <xsl:variable name="height" select="$max-y - $min-y" as="xs:double"/>

                <!-- update viewBox -->
                <xsl:variable name="new-viewBox" select="$min-x || ' ' || $min-y || ' ' || $width || ' ' || $height" as="xs:string"/>
                <ixsl:set-attribute name="viewBox" select="$new-viewBox" object="$svg"/>

                <xsl:message>Updated viewBox to: <xsl:value-of select="$new-viewBox"/></xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Resource not found in document</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
