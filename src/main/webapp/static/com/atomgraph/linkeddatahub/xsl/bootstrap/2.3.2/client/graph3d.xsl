<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:include href="3d-force-graph.xsl"/>
    <xsl:include href="normalize-rdfxml.xsl"/>
    <xsl:include href="merge-rdfxml.xsl"/>

    <!-- EVENT HANDLERS -->

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>
        <xsl:variable name="node-label" select="ixsl:get($event-detail, 'nodeLabel')" as="xs:string"/>

        <xsl:variable name="graph-state" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.graphs'), $canvas-id)"/>
        <xsl:variable name="rdf-doc" select="ixsl:get($graph-state, 'document')" as="document-node()"/>
        <xsl:variable name="description" select="key('resources', $node-id, $rdf-doc)"/>

        <xsl:variable name="tooltip-id" select="'tooltip-' || $canvas-id" as="xs:string"/>
        <xsl:for-each select="id($tooltip-id, ixsl:page())">
            <ixsl:set-style name="display" select="'block'"/>
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:apply-templates select="if (exists($description)) then $description else $node-label" mode="ldh:graph3d-info">
                    <xsl:with-param name="node-id" select="$node-id"/>
                    <xsl:with-param name="node-label" select="$node-label"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeDblClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>

        <xsl:if test="starts-with($node-id, 'http://') or starts-with($node-id, 'https://')">
            <xsl:variable name="graph-state" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.graphs'), $canvas-id)"/>
            <xsl:variable name="current-doc" select="ixsl:get($graph-state, 'document')" as="document-node()"/>
            <xsl:variable name="loaded-uris" select="ixsl:get($graph-state, 'loaded-uris', map{ 'convert-result': false() })"/>
            <xsl:variable name="node-uri-without-fragment" select="if (contains($node-id, '#')) then substring-before($node-id, '#') else $node-id" as="xs:string"/>
            <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>

            <xsl:choose>
                <!-- Already loaded: expand its undescribed objects as stubs -->
                <xsl:when test="ixsl:call($loaded-uris, 'includes', [ $node-uri-without-fragment ])">
                    <xsl:variable name="description" select="key('resources', $node-id, $current-doc)"/>
                    <xsl:variable name="object-uris" select="distinct-values($description/*/@rdf:resource)[not(key('resources', ., $current-doc))]" as="xs:anyURI*"/>

                    <xsl:if test="exists($object-uris)">
                        <xsl:variable name="new-descriptions" as="document-node()">
                            <xsl:document>
                                <rdf:RDF>
                                    <xsl:for-each select="$object-uris">
                                        <rdf:Description rdf:about="{.}">
                                            <rdfs:label><xsl:value-of select="tokenize(., '[/#]')[last()]"/></rdfs:label>
                                        </rdf:Description>
                                    </xsl:for-each>
                                </rdf:RDF>
                            </xsl:document>
                        </xsl:variable>

                        <xsl:call-template name="ldh:UpdateForceGraph3D">
                            <xsl:with-param name="new-descriptions" select="$new-descriptions"/>
                            <xsl:with-param name="current-doc" select="$current-doc"/>
                            <xsl:with-param name="graph-instance" select="$graph-instance"/>
                            <xsl:with-param name="graph-state" select="$graph-state"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>

                <!-- Not yet loaded: fetch via LDH proxy -->
                <xsl:otherwise>
                    <xsl:variable name="request-uri" select="ldh:href(xs:anyURI($node-uri-without-fragment), map{})" as="xs:anyURI"/>
                    <xsl:variable name="request" select="map{
                        'method': 'GET',
                        'href': $request-uri,
                        'headers': map{ 'Accept': 'application/rdf+xml' },
                        'pool': 'xml'
                    }" as="map(*)"/>
                    <xsl:variable name="context" select="map{
                        'canvas-id': $canvas-id,
                        'document-uri': xs:anyURI($node-uri-without-fragment),
                        'graph-state': $graph-state
                    }" as="map(*)"/>

                    <ixsl:promise select="
                        ixsl:http-request($request)
                            => ixsl:then(ldh:handle-graph3d-rdf-response($context, ?))
                    " on-failure="ldh:promise-failure#1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeHoverOn">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>
        <xsl:variable name="node-label" select="ixsl:get($event-detail, 'nodeLabel')" as="xs:string"/>
        <xsl:variable name="screen-x" select="ixsl:get($event-detail, 'screenX')" as="xs:double"/>
        <xsl:variable name="screen-y" select="ixsl:get($event-detail, 'screenY')" as="xs:double"/>

        <xsl:variable name="graph-state" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.graphs'), $canvas-id)"/>
        <xsl:variable name="rdf-doc" select="ixsl:get($graph-state, 'document')" as="document-node()"/>
        <xsl:variable name="description" select="key('resources', $node-id, $rdf-doc)"/>

        <xsl:variable name="tooltip-id" select="'tooltip-' || $canvas-id" as="xs:string"/>
        <xsl:for-each select="id($tooltip-id, ixsl:page())">
            <ixsl:set-style name="display" select="'block'"/>
            <ixsl:set-style name="left" select="$screen-x || 'px'"/>
            <ixsl:set-style name="top" select="$screen-y || 'px'"/>
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:apply-templates select="if (exists($description)) then $description else $node-label" mode="ldh:graph3d-tooltip">
                    <xsl:with-param name="node-label" select="$node-label"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeHoverOff">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>

        <xsl:variable name="tooltip-id" select="'tooltip-' || $canvas-id" as="xs:string"/>
        <xsl:for-each select="id($tooltip-id, ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DBackgroundClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>

        <xsl:variable name="tooltip-id" select="'tooltip-' || $canvas-id" as="xs:string"/>
        <xsl:for-each select="id($tooltip-id, ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <!-- UPDATE -->

    <xsl:template name="ldh:UpdateForceGraph3D">
        <xsl:param name="new-descriptions" as="document-node()"/>
        <xsl:param name="current-doc" as="document-node()"/>
        <xsl:param name="graph-instance" as="item()"/>
        <xsl:param name="graph-state" as="item()"/>

        <xsl:variable name="merged-doc" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$current-doc" mode="ldh:MergeRDF">
                    <xsl:with-param name="new-rdf" select="$new-descriptions" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <ixsl:set-property name="document" select="$merged-doc" object="$graph-state"/>

        <xsl:variable name="graph-data" as="item()">
            <xsl:apply-templates select="$merged-doc" mode="ldh:ForceGraph3D-convert-data">
                <xsl:with-param name="show-stubs" select="true()" tunnel="yes"/>
                <xsl:with-param name="show-literals" select="false()" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="ixsl:call($graph-instance, 'graphData', [$graph-data], map{'convert-args': false()})[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- HTTP RESPONSE HANDLER -->

    <xsl:function name="ldh:handle-graph3d-rdf-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response" as="map(*)"/>

        <xsl:variable name="canvas-id" select="$context('canvas-id')" as="xs:string"/>
        <xsl:variable name="document-uri" select="$context('document-uri')" as="xs:anyURI"/>
        <xsl:variable name="graph-state" select="$context('graph-state')"/>
        <xsl:variable name="loaded-uris" select="ixsl:get($graph-state, 'loaded-uris', map{ 'convert-result': false() })"/>
        <xsl:variable name="current-doc" select="ixsl:get($graph-state, 'document')" as="document-node()"/>
        <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>

        <xsl:for-each select="$response?body">
            <xsl:variable name="base-uri" select="if (contains($document-uri, '#')) then xs:anyURI(substring-before($document-uri, '#')) else $document-uri" as="xs:anyURI"/>
            <xsl:variable name="normalized-rdf" as="document-node()">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="base-uri" select="$base-uri"/>
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:sequence select="ixsl:call($loaded-uris, 'push', [ string($document-uri) ])[current-date() lt xs:date('2000-01-01')]"/>

            <xsl:call-template name="ldh:UpdateForceGraph3D">
                <xsl:with-param name="new-descriptions" select="$normalized-rdf"/>
                <xsl:with-param name="current-doc" select="$current-doc"/>
                <xsl:with-param name="graph-instance" select="$graph-instance"/>
                <xsl:with-param name="graph-state" select="$graph-state"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:function>

    <!-- TOOLTIP RENDERING -->

    <xsl:template match="rdf:Description" mode="ldh:graph3d-tooltip">
        <xsl:param name="node-label" as="xs:string"/>
        <strong><xsl:value-of select="$node-label"/></strong>
        <xsl:if test="rdf:type/@rdf:resource">
            <br/>
            <xsl:value-of select="tokenize(rdf:type[1]/@rdf:resource, '[/#]')[last()]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xs:string" mode="ldh:graph3d-tooltip">
        <xsl:param name="node-label" as="xs:string"/>
        <span><xsl:value-of select="$node-label"/></span>
    </xsl:template>

    <!-- INFO PANEL RENDERING (used on node click) -->

    <xsl:template match="rdf:Description" mode="ldh:graph3d-info">
        <xsl:param name="node-id" as="xs:string"/>
        <xsl:param name="node-label" as="xs:string"/>
        <strong><xsl:value-of select="$node-label"/></strong>
        <xsl:if test="starts-with($node-id, 'http://') or starts-with($node-id, 'https://')">
            <br/>
            <a href="{$node-id}" target="_blank"><xsl:value-of select="$node-id"/></a>
        </xsl:if>
        <xsl:if test="rdf:type/@rdf:resource">
            <br/>
            <xsl:value-of select="tokenize(rdf:type[1]/@rdf:resource, '[/#]')[last()]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xs:string" mode="ldh:graph3d-info">
        <xsl:param name="node-id" as="xs:string"/>
        <xsl:param name="node-label" as="xs:string"/>
        <span><xsl:value-of select="$node-label"/></span>
    </xsl:template>

</xsl:stylesheet>
