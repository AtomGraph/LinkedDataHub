<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:ac="https://w3id.org/atomgraph/client#"
    xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
    exclude-result-prefixes="#all"
    extension-element-prefixes="ixsl"
    version="3.0">

    <!-- Max characters shown for literal node labels before truncation -->
    <xsl:variable name="ldh:literal-label-max-length" as="xs:integer" select="40"/>

    <!-- Function to calculate node color from resource type URI(s) by averaging hues -->
    <!-- Uses a simple hash function to deterministically derive hue from URI string -->
    <xsl:function name="ldh:force-graph-3d-node-color" as="xs:string">
        <xsl:param name="resource" as="element()"/>

        <xsl:for-each select="$resource">
            <xsl:variable name="type-uris" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>
            <xsl:choose>
                <xsl:when test="exists($type-uris)">
                    <!-- Generate hues from URI strings using simple hash (sum of codepoints mod 360) -->
                    <xsl:variable name="hues" as="xs:double*">
                        <xsl:for-each select="$type-uris">
                            <xsl:variable name="uri-string" select="string(.)" as="xs:string"/>
                            <xsl:variable name="codepoint-sum" select="sum(string-to-codepoints($uri-string))" as="xs:integer"/>
                            <xsl:sequence select="$codepoint-sum mod 360"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="avg-hue" select="avg($hues)" as="xs:double"/>
                    <!-- 70% saturation, 60% lightness = vibrant colors visible on black background -->
                    <xsl:sequence select="'hsl(' || $avg-hue || ', 70%, 60%)'"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Default gray for resources without type -->
                    <xsl:sequence select="'#95a5a6'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <!-- Initialize 3D Force Graph -->
    <xsl:template name="ldh:ForceGraph3D-init">
        <xsl:param name="graph-id" as="xs:string"/> <!-- string: graph container element ID -->
        <xsl:param name="container" as="element()"/> <!-- HTMLElement: DOM element for graph -->
        <xsl:param name="builder" as="item()?"/> <!-- function: ForceGraph3D constructor -->
        <xsl:param name="graph-width" as="xs:double"/> <!-- number: canvas width in px -->
        <xsl:param name="graph-height" as="xs:double"/> <!-- number: canvas height in px -->
        <xsl:param name="node-rel-size" as="xs:double"/> <!-- number: relative node size -->
        <xsl:param name="link-width" as="xs:double"/> <!-- number: link line width in px -->
        <xsl:param name="node-label-color" as="xs:string"/> <!-- string: CSS color for node labels -->
        <xsl:param name="node-literal-color" select="'#e8d5a3'" as="xs:string"/> <!-- string: CSS color for literal node mesh -->
        <xsl:param name="node-sphere-color" select="'#999999'" as="xs:string"/> <!-- string: CSS color fallback for resource/uri node mesh -->
        <xsl:param name="node-label-text-height" as="xs:double"/> <!-- number: node label font size -->
        <xsl:param name="node-label-position-y" as="xs:double"/> <!-- number: node label Y offset -->
        <xsl:param name="link-label-color" as="xs:string"/> <!-- string: CSS color for link labels -->
        <xsl:param name="link-label-text-height" as="xs:double"/> <!-- number: link label font size -->
        <xsl:param name="link-force-distance" as="xs:double"/> <!-- number: target distance between linked nodes -->
        <xsl:param name="charge-force-strength" as="xs:double"/> <!-- number: node repulsion strength (negative) -->
        <xsl:param name="cooldown-time" as="xs:double?"/> <!-- number: milliseconds to render before stopping engine (optional) -->
        <xsl:param name="cooldown-ticks" as="xs:double?"/> <!-- number: frames to render before stopping engine (optional) -->

        <!-- CustomEvent names for graph interactions -->
        <xsl:param name="node-click-event-name" as="xs:string"/> <!-- string: event name for node single-click -->
        <xsl:param name="node-dblclick-event-name" as="xs:string"/> <!-- string: event name for node double-click -->
        <xsl:param name="node-rightclick-event-name" as="xs:string"/> <!-- string: event name for node right-click -->
        <xsl:param name="node-hover-on-event-name" as="xs:string"/> <!-- string: event name for node hover start -->
        <xsl:param name="node-hover-off-event-name" as="xs:string"/> <!-- string: event name for node hover end -->
        <xsl:param name="link-click-event-name" as="xs:string"/> <!-- string: event name for link click -->
        <xsl:param name="background-click-event-name" as="xs:string"/> <!-- string: event name for background click -->
        <xsl:param name="engine-stop-event-name" as="xs:string?"/> <!-- string: event name for engine stop (optional) -->
        <xsl:param name="highlight-color" select="'#ffff00'" as="xs:string"/> <!-- string: CSS hex color for hover highlight -->

        <!-- Optional JavaScript function parameters - callers can override default behavior -->
        <xsl:param name="nodeLabel-fn" select="ixsl:eval('() => null')" as="item()?"/> <!-- function: node label accessor -->
        <xsl:param name="nodeColor-fn" select="ixsl:eval('node => node.color')" as="item()?"/> <!-- function: node color accessor -->
        <xsl:param name="nodeThreeObject-fn" as="item()?"> <!-- function: custom Three.js object for nodes -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="node => {{
                    const group = new THREE.Group();
                    if (node.nodeType === 'literal') {{
                        const geo = new THREE.BoxGeometry(10, 6, 1);
                        const mat = new THREE.MeshLambertMaterial({{ color: node.color || '{$node-literal-color}' }});
                        group.add(new THREE.Mesh(geo, mat));
                        const sprite = new SpriteText(node.label);
                        sprite.material.depthWrite = false;
                        sprite.color = '{$node-label-color}';
                        sprite.textHeight = {$node-label-text-height};
                        sprite.position.y = 7;
                        group.add(sprite);
                    }} else {{
                        const radius = node.nodeType === 'resource' ? 10 : 3;
                        const geo = new THREE.SphereGeometry(radius, 16, 8);
                        const mat = new THREE.MeshLambertMaterial({{ color: node.color || '{$node-sphere-color}' }});
                        group.add(new THREE.Mesh(geo, mat));
                        const sprite = new SpriteText(node.label);
                        sprite.material.depthWrite = false;
                        sprite.color = '{$node-label-color}';
                        sprite.textHeight = {$node-label-text-height};
                        sprite.position.y = radius + {$node-label-position-y};
                        group.add(sprite);
                    }}
                    return group;
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="linkThreeObject-fn" as="item()?"> <!-- function: custom Three.js object for links -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="link => {{
                    const sprite = new SpriteText(link.label);
                    sprite.material.depthWrite = false;
                    sprite.color = '{$link-label-color}';
                    sprite.textHeight = {$link-label-text-height};
                    return sprite;
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="linkPositionUpdate-fn" select="ixsl:eval('(sprite, { start, end }) => {
            if (!sprite) return;
            const middlePos = Object.assign({},
                ...[''x'', ''y'', ''z''].map(c => ({
                    [c]: start[c] + (end[c] - start[c]) / 2
                }))
            );
            Object.assign(sprite.position, middlePos);
        }')" as="item()?"/> <!-- function: link sprite position updater -->
        <xsl:param name="onEngineStop-fn" as="item()"> <!-- function: engine stop handler -->
            <xsl:variable name="js-statement" as="element()">
                <xsl:choose>
                    <xsl:when test="exists($engine-stop-event-name)">
                        <root statement="() => {{
                            window.LinkedDataHub.graphs['{$graph-id}'].highlightingEnabled = true;
                            document.dispatchEvent(new CustomEvent('{$engine-stop-event-name}', {{
                                detail: {{ canvasId: '{$graph-id}' }}
                            }}));
                        }}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <root statement="() => {{
                            window.LinkedDataHub.graphs['{$graph-id}'].highlightingEnabled = true;
                        }}"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="onNodeClick-fn" as="item()?"> <!-- function: node click handler -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="node => {{
                    var graphState = window.LinkedDataHub.graphs['{$graph-id}'];
                    var now = new Date().getTime();
                    var lastClick = graphState.lastNodeClickTime || 0;
                    var timeDiff = now - lastClick;
                    graphState.lastNodeClickTime = now;
                    if (timeDiff > 0 &amp;&amp; timeDiff &lt; 500) {{
                        var event = new CustomEvent('{$node-dblclick-event-name}', {{
                            detail: {{
                                canvasId: '{$graph-id}',
                                nodeId: node.id,
                                nodeLabel: node.label
                            }}
                        }});
                        document.dispatchEvent(event);
                    }} else {{
                        var event = new CustomEvent('{$node-click-event-name}', {{
                            detail: {{
                                canvasId: '{$graph-id}',
                                nodeId: node.id,
                                nodeLabel: node.label
                            }}
                        }});
                        document.dispatchEvent(event);
                    }}
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="onNodeRightClick-fn" as="item()?"> <!-- function: node right-click handler -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="node => {{
                    let event = new CustomEvent('{$node-rightclick-event-name}', {{
                        detail: {{
                            canvasId: '{$graph-id}',
                            nodeId: node.id,
                            nodeLabel: node.label
                        }}
                    }});
                    document.dispatchEvent(event);
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="onNodeHover-fn-factory" as="item()?"> <!-- function: creates node hover handler -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="(graphInstance) => {{
                    var highlightNodes = [];
                    var highlightLinks = [];
                    var highlightColor = '{$highlight-color}';

                    graphInstance
                        .nodeColor(function(node) {{
                            return highlightNodes.indexOf(node) >= 0 ? highlightColor : (node.color || '#999999');
                        }})
                        .linkColor(function(link) {{
                            return highlightLinks.indexOf(link) >= 0 ? highlightColor : (link.color || '#aaaaaa');
                        }})
                        .linkOpacity(1);

                    return (node) => {{
                        highlightNodes = [];
                        highlightLinks = [];

                        if (node) {{
                            if (window.LinkedDataHub.graphs['{$graph-id}'].highlightingEnabled) {{
                                var graphData = graphInstance.graphData();
                                graphData.links.forEach(link => {{
                                    var srcId = link.source &amp;&amp; typeof link.source === 'object' ? link.source.id : link.source;
                                    if (srcId === node.id) {{
                                        highlightLinks.push(link);
                                        if (link.target &amp;&amp; typeof link.target === 'object') highlightNodes.push(link.target);
                                    }}
                                }});
                                highlightNodes.push(node);
                            }}

                            graphInstance.nodeColor(graphInstance.nodeColor());
                            graphInstance.linkColor(graphInstance.linkColor());

                            const screenCoords = graphInstance.graph2ScreenCoords(node.x, node.y, node.z);
                            document.dispatchEvent(new CustomEvent('{$node-hover-on-event-name}', {{
                                detail: {{
                                    canvasId: '{$graph-id}',
                                    nodeId: node.id,
                                    nodeLabel: node.label,
                                    screenX: screenCoords.x,
                                    screenY: screenCoords.y
                                }}
                            }}));
                        }} else {{
                            graphInstance.nodeColor(graphInstance.nodeColor());
                            graphInstance.linkColor(graphInstance.linkColor());

                            document.dispatchEvent(new CustomEvent('{$node-hover-off-event-name}', {{
                                detail: {{
                                    canvasId: '{$graph-id}'
                                }}
                            }}));
                        }}
                    }};
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="onLinkClick-fn" as="item()?"> <!-- function: link click handler -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="link => {{
                    let event = new CustomEvent('{$link-click-event-name}', {{
                        detail: {{
                            canvasId: '{$graph-id}',
                            sourceId: link.source.id,
                            targetId: link.target.id,
                            linkLabel: link.label
                        }}
                    }});
                    document.dispatchEvent(event);
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>
        <xsl:param name="onBackgroundClick-fn" as="item()?"> <!-- function: background click handler -->
            <xsl:variable name="js-statement" as="element()">
                <root statement="() => {{
                    let event = new CustomEvent('{$background-click-event-name}', {{
                        detail: {{
                            canvasId: '{$graph-id}'
                        }}
                    }});
                    document.dispatchEvent(event);
                }}"/>
            </xsl:variable>
            <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
        </xsl:param>

        <!-- Guard: ForceGraph3D library must be loaded -->
        <xsl:if test="empty($builder)">
            <xsl:message terminate="yes">ForceGraph3D constructor not found on window. Ensure 3d-force-graph.min.js is loaded before Saxon-JS.</xsl:message>
        </xsl:if>

        <!-- Create the graph instance -->
        <xsl:variable name="graph" select="ixsl:apply($builder, [ $container ])" as="item()"/>

        <!-- Configure graph -->
        <xsl:variable name="graph" select="if (exists($nodeLabel-fn)) then ixsl:call($graph, 'nodeLabel', [ $nodeLabel-fn ]) else $graph"/>
        <xsl:variable name="graph" select="if (exists($nodeColor-fn)) then ixsl:call($graph, 'nodeColor', [ $nodeColor-fn ]) else $graph"/>
        <xsl:variable name="graph" select="ixsl:call($graph, 'width', [ $graph-width ])"/>
        <xsl:variable name="graph" select="ixsl:call($graph, 'height', [ $graph-height ])"/>
        <xsl:variable name="graph" select="ixsl:call($graph, 'nodeRelSize', [ $node-rel-size ])"/>
        <xsl:variable name="graph" select="ixsl:call($graph, 'linkWidth', [ $link-width ])"/>

        <!-- Configure cooldown behavior (optional) -->
        <xsl:variable name="graph" select="if (exists($cooldown-time)) then ixsl:call($graph, 'cooldownTime', [ $cooldown-time ]) else $graph"/>
        <xsl:variable name="graph" select="if (exists($cooldown-ticks)) then ixsl:call($graph, 'cooldownTicks', [ $cooldown-ticks ]) else $graph"/>

        <!-- Configure labels to be always visible -->
        <xsl:variable name="graph" select="if (exists($nodeThreeObject-fn)) then ixsl:call($graph, 'nodeThreeObjectExtend', [ false() ]) else $graph"/>
        <xsl:variable name="graph" select="if (exists($nodeThreeObject-fn)) then ixsl:call($graph, 'nodeThreeObject', [ $nodeThreeObject-fn ]) else $graph"/>

        <xsl:variable name="graph" select="if (exists($linkThreeObject-fn)) then ixsl:call($graph, 'linkThreeObjectExtend', [ true() ]) else $graph"/>
        <xsl:variable name="graph" select="if (exists($linkThreeObject-fn)) then ixsl:call($graph, 'linkThreeObject', [ $linkThreeObject-fn ]) else $graph"/>

        <xsl:variable name="graph" select="if (exists($linkPositionUpdate-fn)) then ixsl:call($graph, 'linkPositionUpdate', [ $linkPositionUpdate-fn ]) else $graph"/>

        <!-- Set up event handlers (only if provided) -->
        <xsl:variable name="graph" select="if (exists($onNodeClick-fn)) then ixsl:call($graph, 'onNodeClick', [ $onNodeClick-fn ], map{ 'convert-args': false() }) else $graph"/>
        <xsl:variable name="graph" select="if (exists($onNodeRightClick-fn)) then ixsl:call($graph, 'onNodeRightClick', [ $onNodeRightClick-fn ], map{ 'convert-args': false() }) else $graph"/>

        <!-- Create hover handler with graph instance in closure -->
        <xsl:variable name="onNodeHover-fn" select="if (exists($onNodeHover-fn-factory)) then ixsl:apply($onNodeHover-fn-factory, [ $graph ]) else ()"/>
        <xsl:variable name="graph" select="if (exists($onNodeHover-fn)) then ixsl:call($graph, 'onNodeHover', [ $onNodeHover-fn ], map{ 'convert-args': false() }) else $graph"/>

        <xsl:variable name="graph" select="if (exists($onLinkClick-fn)) then ixsl:call($graph, 'onLinkClick', [ $onLinkClick-fn ], map{ 'convert-args': false() }) else $graph"/>
        <xsl:variable name="graph" select="if (exists($onBackgroundClick-fn)) then ixsl:call($graph, 'onBackgroundClick', [ $onBackgroundClick-fn ], map{ 'convert-args': false() }) else $graph"/>
        <xsl:variable name="graph" select="if (exists($onEngineStop-fn)) then ixsl:call($graph, 'onEngineStop', [ $onEngineStop-fn ]) else $graph"/>

        <!-- Configure force simulation -->
        <xsl:variable name="link-force" select="ixsl:call($graph, 'd3Force', [ 'link' ])"/>
        <xsl:sequence select="ixsl:call($link-force, 'distance', [ $link-force-distance ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="charge-force" select="ixsl:call($graph, 'd3Force', [ 'charge' ])"/>
        <xsl:sequence select="ixsl:call($charge-force, 'strength', [ $charge-force-strength ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- Create and return graph state -->
        <xsl:variable name="graph-state" select="ixsl:eval('({})')"/>
        <xsl:for-each select="$graph-state">
            <ixsl:set-property name="instance" select="$graph" object="."/>
            <ixsl:set-property name="showLabels" select="false()" object="."/>
            <ixsl:set-property name="highlightingEnabled" select="false()" object="."/>
        </xsl:for-each>
        <!-- Return the graph state for further use -->
        <xsl:sequence select="$graph-state"/>
    </xsl:template>

    <!-- Convert RDF/XML to Force Graph data structure -->
    <xsl:template match="/" mode="ldh:ForceGraph3D-convert-data" as="item()">
        <!-- Expects pre-normalized RDF/XML (all nested structures flattened, URIs resolved) -->
        <xsl:message>ldh:ForceGraph3D-convert-data: rdf:RDF=<xsl:value-of select="exists(rdf:RDF)"/> rdf:Description count=<xsl:value-of select="count(rdf:RDF/rdf:Description)"/> root element=<xsl:value-of select="name(*)"/></xsl:message>
        <!-- Process RDF to get nodes and links -->
        <xsl:variable name="nodes" as="item()*">
            <xsl:apply-templates select="rdf:RDF" mode="ldh:ForceGraph3D-nodes"/>
        </xsl:variable>
        <xsl:variable name="links" as="item()*">
            <xsl:apply-templates select="rdf:RDF" mode="ldh:ForceGraph3D-links"/>
        </xsl:variable>
        <xsl:message>ldh:ForceGraph3D-convert-data: nodes=<xsl:value-of select="count($nodes)"/> links=<xsl:value-of select="count($links)"/></xsl:message>
        <!-- Create graph data object with empty arrays -->
        <xsl:variable name="graph-data" select="ixsl:eval('({ nodes: [], links: [] })')"/>

        <!-- Get arrays from the object -->
        <xsl:variable name="nodes-array" select="ixsl:get($graph-data, 'nodes', map{ 'convert-result': false() })"/>
        <xsl:variable name="links-array" select="ixsl:get($graph-data, 'links', map{ 'convert-result': false() })"/>

        <!-- Populate JavaScript arrays -->
        <xsl:for-each select="$nodes">
            <xsl:sequence select="ixsl:call($nodes-array, 'push', [ . ], map{ 'convert-args': false() })[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:for-each select="$links">
            <xsl:sequence select="ixsl:call($links-array, 'push', [ . ], map{ 'convert-args': false() })[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:sequence select="$graph-data"/>
    </xsl:template>

    <!-- NODE MODE TEMPLATES -->

    <!-- Level 1: rdf:RDF -->
    <xsl:template match="rdf:RDF" mode="ldh:ForceGraph3D-nodes" as="item()*">
        <xsl:param name="show-stubs" select="true()" tunnel="yes" as="xs:boolean"/>

        <!-- Resource, literal, and blank node stub nodes from described resources -->
        <xsl:apply-templates mode="#current"/>

        <!-- One stub URI node per unique unresolved @rdf:resource (deduplicates across all descriptions) -->
        <xsl:if test="$show-stubs">
            <xsl:for-each select="distinct-values(rdf:Description/*/@rdf:resource[not(key('resources', .))])">
                <xsl:variable name="uri" select="xs:anyURI(.)" as="xs:anyURI"/>
                <xsl:variable name="node" select="ixsl:eval('{}')"/>
                <xsl:for-each select="$node">
                    <ixsl:set-property name="id" select="$uri" object="."/>
                    <ixsl:set-property name="label" select="$uri" object="."/>
                    <ixsl:set-property name="nodeType" select="'uri'" object="."/>
                    <ixsl:set-property name="color" select="'#7f8c8d'" object="."/>
                </xsl:for-each>
                <xsl:sequence select="$node"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Level 2: described resource node + dispatch into properties -->
    <xsl:template match="rdf:Description[@rdf:about or @rdf:nodeID]" mode="ldh:ForceGraph3D-nodes" as="item()+">
        <xsl:param name="label" select="ac:label(.)" as="xs:string"/> <!-- string: display label for the node -->
        <xsl:param name="type-uri" select="rdf:type[1]/@rdf:resource" as="xs:anyURI?"/> <!-- anyURI?: full URI of node type -->
        <xsl:param name="type-local" select="if ($type-uri) then tokenize($type-uri, '[/#]')[last()] else 'Resource'" as="xs:string"/> <!-- string: local name of type -->
        <xsl:param name="color" select="ldh:force-graph-3d-node-color(.)" as="xs:string"/> <!-- string: CSS color for node -->
        <xsl:variable name="id" select="xs:anyURI((@rdf:about, @rdf:nodeID)[1])" as="xs:anyURI"/>

        <xsl:variable name="node" select="ixsl:eval('{}')"/>
        <xsl:for-each select="$node">
            <ixsl:set-property name="id" select="$id" object="."/>
            <ixsl:set-property name="label" select="$label" object="."/>
            <ixsl:set-property name="type" select="$type-local" object="."/>
            <ixsl:set-property name="color" select="$color" object="."/>
            <ixsl:set-property name="nodeType" select="'resource'" object="."/>
        </xsl:for-each>
        <xsl:sequence select="$node"/>

        <!-- Dispatch to property element templates -->
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <!-- Level 3: general property template — dispatch to all object types -->
    <xsl:template match="rdf:Description/*" mode="ldh:ForceGraph3D-nodes" as="item()*">
        <xsl:apply-templates select="@rdf:resource | @rdf:nodeID | text() | *" mode="#current"/>
    </xsl:template>

    <!-- Level 4a: @rdf:resource not described → suppress; stub nodes created at rdf:RDF level with deduplication -->
    <xsl:template match="@rdf:resource[not(key('resources', .))]" mode="ldh:ForceGraph3D-nodes"/>

    <!-- Level 4a: @rdf:resource already described → suppress (node already emitted at level 2) -->
    <xsl:template match="@rdf:resource" mode="ldh:ForceGraph3D-nodes"/>

    <!-- Level 4b: @rdf:nodeID → blank node already described → suppress -->
    <xsl:template match="@rdf:nodeID" mode="ldh:ForceGraph3D-nodes"/>

    <!-- Level 4c: non-empty text node → literal node -->
    <xsl:template match="text()[normalize-space(.) != '']" mode="ldh:ForceGraph3D-nodes" as="item()?">
        <xsl:param name="show-literals" select="true()" tunnel="yes" as="xs:boolean"/>
        <xsl:param name="locale-filter" select="()" tunnel="yes" as="xs:string?"/>
        <xsl:if test="$show-literals and (empty($locale-filter) or not(parent::*/@xml:lang) or lang($locale-filter))">
            <xsl:variable name="node-id" select="generate-id(.)" as="xs:string"/>
            <xsl:variable name="literal-value" select="normalize-space(.)" as="xs:string"/>
            <xsl:variable name="display-label" as="xs:string"
                select="if (string-length($literal-value) gt $ldh:literal-label-max-length)
                        then substring($literal-value, 1, $ldh:literal-label-max-length) || '…'
                        else $literal-value"/>
            <xsl:variable name="node" select="ixsl:eval('{}')"/>
            <xsl:for-each select="$node">
                <ixsl:set-property name="id" select="$node-id" object="."/>
                <ixsl:set-property name="label" select="$display-label" object="."/>
                <ixsl:set-property name="nodeType" select="'literal'" object="."/>
                <ixsl:set-property name="color" select="'#e8d5a3'" object="."/>
            </xsl:for-each>
            <xsl:sequence select="$node"/>
        </xsl:if>
    </xsl:template>

    <!-- Level 4d: XMLLiteral embedded element → literal-like node -->
    <xsl:template match="rdf:Description/*/*" mode="ldh:ForceGraph3D-nodes" as="item()?">
        <xsl:param name="show-literals" select="true()" tunnel="yes" as="xs:boolean"/>
        <xsl:if test="$show-literals">
            <xsl:variable name="node-id" select="generate-id(.)" as="xs:string"/>
            <xsl:variable name="literal-value" select="normalize-space(string(.))" as="xs:string"/>
            <xsl:variable name="display-label" as="xs:string"
                select="if (string-length($literal-value) gt $ldh:literal-label-max-length)
                        then substring($literal-value, 1, $ldh:literal-label-max-length) || '…'
                        else $literal-value"/>
            <xsl:variable name="node" select="ixsl:eval('{}')"/>
            <xsl:for-each select="$node">
                <ixsl:set-property name="id" select="$node-id" object="."/>
                <ixsl:set-property name="label" select="$display-label" object="."/>
                <ixsl:set-property name="nodeType" select="'literal'" object="."/>
                <ixsl:set-property name="color" select="'#e8d5a3'" object="."/>
            </xsl:for-each>
            <xsl:sequence select="$node"/>
        </xsl:if>
    </xsl:template>

    <!-- Suppress whitespace-only text nodes in nodes mode -->
    <xsl:template match="text()" mode="ldh:ForceGraph3D-nodes"/>

    <!-- LINKS MODE TEMPLATES -->

    <!-- Level 1: rdf:RDF -->
    <xsl:template match="rdf:RDF" mode="ldh:ForceGraph3D-links" as="item()*">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <!-- Level 2: rdf:Description → dispatch to all property children -->
    <xsl:template match="rdf:Description[@rdf:about or @rdf:nodeID]" mode="ldh:ForceGraph3D-links" as="item()*">
        <xsl:variable name="id" select="xs:anyURI((@rdf:about, @rdf:nodeID)[1])" as="xs:anyURI"/>

        <xsl:apply-templates select="*" mode="#current">
            <xsl:with-param name="source-id" select="$id"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- Level 3: general property template — dispatch to all object types, passing link-label -->
    <xsl:template match="rdf:Description/*" mode="ldh:ForceGraph3D-links" as="item()*">
        <xsl:param name="source-id" as="xs:anyURI"/>

        <xsl:apply-templates select="@rdf:resource | @rdf:nodeID | text() | *" mode="#current">
            <xsl:with-param name="source-id" select="$source-id"/>
            <xsl:with-param name="link-label" select="local-name()"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- Level 4a: @rdf:resource → link to URI (described or URI-only) -->
    <xsl:template match="@rdf:resource" mode="ldh:ForceGraph3D-links" as="item()?">
        <xsl:param name="source-id" as="xs:anyURI"/>
        <xsl:param name="link-label" as="xs:string"/>
        <xsl:param name="show-stubs" select="true()" tunnel="yes" as="xs:boolean"/>
        <!-- Suppress link if target is a stub and stubs are hidden -->
        <xsl:if test="$show-stubs or exists(key('resources', .))">
            <xsl:variable name="target-id" select="xs:anyURI(.)" as="xs:anyURI"/>
            <xsl:variable name="link" select="ixsl:eval('{}')"/>
            <xsl:for-each select="$link">
                <ixsl:set-property name="source" select="$source-id" object="."/>
                <ixsl:set-property name="target" select="$target-id" object="."/>
                <ixsl:set-property name="label" select="$link-label" object="."/>
            </xsl:for-each>
            <xsl:sequence select="$link"/>
        </xsl:if>
    </xsl:template>

    <!-- Level 4b: @rdf:nodeID → link to blank node -->
    <xsl:template match="@rdf:nodeID" mode="ldh:ForceGraph3D-links" as="item()">
        <xsl:param name="source-id" as="xs:anyURI"/>
        <xsl:param name="link-label" as="xs:string"/>
        <xsl:variable name="target-id" select="string(.)" as="xs:string"/>

        <xsl:variable name="link" select="ixsl:eval('{}')"/>
        <xsl:for-each select="$link">
            <ixsl:set-property name="source" select="$source-id" object="."/>
            <ixsl:set-property name="target" select="$target-id" object="."/>
            <ixsl:set-property name="label" select="$link-label" object="."/>
        </xsl:for-each>
        <xsl:sequence select="$link"/>
    </xsl:template>

    <!-- Level 4c: non-empty text → literal link -->
    <xsl:template match="text()[normalize-space(.) != '']" mode="ldh:ForceGraph3D-links" as="item()?">
        <xsl:param name="source-id" as="xs:anyURI"/>
        <xsl:param name="link-label" as="xs:string"/>
        <xsl:param name="show-literals" select="true()" tunnel="yes" as="xs:boolean"/>
        <xsl:param name="locale-filter" select="()" tunnel="yes" as="xs:string?"/>
        <xsl:if test="$show-literals and (empty($locale-filter) or not(parent::*/@xml:lang) or lang($locale-filter))">
            <xsl:variable name="target-id" select="generate-id(.)" as="xs:string"/>
            <xsl:variable name="link" select="ixsl:eval('{}')"/>
            <xsl:for-each select="$link">
                <ixsl:set-property name="source" select="$source-id" object="."/>
                <ixsl:set-property name="target" select="$target-id" object="."/>
                <ixsl:set-property name="label" select="$link-label" object="."/>
            </xsl:for-each>
            <xsl:sequence select="$link"/>
        </xsl:if>
    </xsl:template>

    <!-- Level 4d: XMLLiteral embedded element → link to XMLLiteral node -->
    <xsl:template match="rdf:Description/*/*" mode="ldh:ForceGraph3D-links" as="item()?">
        <xsl:param name="source-id" as="xs:anyURI"/>
        <xsl:param name="link-label" as="xs:string"/>
        <xsl:param name="show-literals" select="true()" tunnel="yes" as="xs:boolean"/>
        <xsl:if test="$show-literals">
            <xsl:variable name="target-id" select="generate-id(.)" as="xs:string"/>
            <xsl:variable name="link" select="ixsl:eval('{}')"/>
            <xsl:for-each select="$link">
                <ixsl:set-property name="source" select="$source-id" object="."/>
                <ixsl:set-property name="target" select="$target-id" object="."/>
                <ixsl:set-property name="label" select="$link-label" object="."/>
            </xsl:for-each>
            <xsl:sequence select="$link"/>
        </xsl:if>
    </xsl:template>

    <!-- Suppress whitespace-only text nodes in links mode -->
    <xsl:template match="text()" mode="ldh:ForceGraph3D-links"/>

</xsl:stylesheet>
