<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Object']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- provide a property label which otherwise would default to local-name() client-side (since $property-metadata is not loaded) -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Object']/rdfs:label | *[rdf:type/@rdf:resource = '&ldh;Object']/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- object block (RDF resource) -->
    
    <xsl:template match="*[@typeof = '&ldh;Object'][descendant::*[@property = '&rdf;value'][@resource]]" mode="ldh:RenderRow" as="function(item()?) as map(*)" priority="2"> <!-- prioritize above block.xsl -->
        <xsl:param name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:param name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:param name="block-uri" select="$about" as="xs:anyURI"/>
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="resource-uri" select="descendant::*[@property = '&rdf;value']/@resource" as="xs:anyURI?"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="show-edit-button" select="false()" as="xs:boolean?"/>

        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'50%'" object="."/>
        </xsl:for-each>

        <!-- don't use ldh:base-uri(.) because its value comes from the last HTML document load -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, if (starts-with($graph, $ldt:base)) then $graph else ac:absolute-path(xs:anyURI(ixsl:location())), map{}, ac:document-uri($resource-uri), $graph, ())" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'block': $block,
            'container': $container,
            'resource-uri': $resource-uri,
            'graph': $graph,
            'mode': $mode,
            'show-edit-button': $show-edit-button
          }"/>
        
        <xsl:sequence select="
            ldh:load-block#3(
                $context,
                ldh:object-self-thunk#1,
                ?
            )
        "/>
    </xsl:template>
    
    <!-- this is the one thunk you hand to load-block#4 -->
    <xsl:function name="ldh:object-self-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:object-self-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:object-value-thunk#1) =>
                ixsl:then(ldh:object-metadata-thunk#1)
        "/>
    </xsl:function>
    
    <!-- only the first HTTP → query‐response lives here -->
    <xsl:function name="ldh:object-value-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:object-value-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:block-object-value-response#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:object-metadata-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:object-metadata-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:block-object-metadata-response#1) =>
                ixsl:then(ldh:block-object-apply#1) =>
                ixsl:then(ldh:invoke-factory#1)                
        "/>
    </xsl:function>
    
    <xsl:function name="ldh:invoke-factory" as="item()*" ixsl:updating="yes">
        <xsl:param name="factory" as="function(item()?) as item()*?"/>
        <xsl:message>ldh:invoke-factory</xsl:message>
        <xsl:sequence select="$factory(())"/>
    </xsl:function>

    <xsl:function name="ldh:block-object-value-response" as="item()" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="resource-uri" select="$context('resource-uri')" as="xs:anyURI"/>
        <xsl:variable name="graph" select="$context('graph')" as="xs:anyURI?"/>
        <xsl:variable name="mode" select="$context('mode')" as="xs:anyURI?"/>
        <xsl:variable name="show-edit-button" select="$context('show-edit-button')" as="xs:boolean?"/>

        <xsl:message>ldh:block-object-value-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
                        <!-- update progress bar -->
                        <ixsl:set-style name="width" select="'33%'" object="."/>
                    </xsl:for-each>

                    <xsl:for-each select="?body">
                        <xsl:variable name="resource" select="key('resources', $resource-uri)" as="element()?"/>
                        <xsl:choose>
                            <!-- only attempt to load object metadata for local resources -->
                            <xsl:when test="$resource">
                                <xsl:message>ldh:block-object-value-response $resource-uri: <xsl:value-of select="$resource-uri"/></xsl:message>
                                <xsl:variable name="object-uris" select="distinct-values($resource/*/@rdf:resource[starts-with(., $ldt:base)][not(key('resources', ., root($resource)))])" as="xs:string*"/>
                                <xsl:variable name="query-string" select="$object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>                    
                                <xsl:variable name="request" select="map{ 'method': 'POST', 'href': sd:endpoint(), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                                <xsl:sequence select="
                                  map{
                                    'request': $request,
                                    'block': $block,
                                    'container': $container,
                                    'resource': $resource,
                                    'graph': $graph,
                                    'mode': $mode,
                                    'show-edit-button': $show-edit-button
                                  }"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each select="$container">
                                    <xsl:result-document href="?." method="ixsl:replace-content">
                                        <div class="alert alert-block">
                                            <strong>Document loaded successfully but resource was not found: <a href="{$resource-uri}"><xsl:value-of select="$resource-uri"/></a></strong>
                                        </div>
                                    </xsl:result-document>
                                </xsl:for-each>
                                
                                <xsl:sequence select="ldh:hide-block-progress-bar($context, ())[current-date() lt xs:date('2000-01-01')]"/>
                                <xsl:sequence select="
                                    error(
                                      QName('&ldh;', 'ldh:HTTPError'),
                                      concat('HTTP ', ?status, ' returned: ', ?message),
                                      $response
                                    )
                                "/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="?status = 406">
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="offset2 span7 main">
                                <object data="{$resource-uri}"/>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="alert alert-block">
                                <strong>Could not load resource: <a href="{$resource-uri}"><xsl:value-of select="$resource-uri"/></a></strong>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                    
                    <xsl:sequence select="ldh:hide-block-progress-bar($context, ())[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="
                        error(
                          QName('&ldh;', 'ldh:HTTPError'),
                          concat('HTTP ', ?status, ' returned: ', ?message),
                          $response
                        )
                    "/>

                    <xsl:sequence select="$context"/>                    
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>        
    </xsl:function>
    
 <!-- replaces the block with a row -->
    
    <xsl:function name="ldh:block-object-metadata-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="resource" select="$context('resource')" as="element()"/>
        <xsl:variable name="graph" select="$context('graph')" as="xs:anyURI?"/>
        <xsl:variable name="mode" select="$context('mode')" as="xs:anyURI?"/>
        <xsl:variable name="show-edit-button" select="$context('show-edit-button')" as="xs:boolean?"/>

        <xsl:message>ldh:block-object-metadata-response</xsl:message>
        
        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'45%'" object="."/>
        </xsl:for-each>
                    
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="object-metadata" select="?body" as="document-node()"/>

                    <xsl:variable name="row" as="node()*">
                        <xsl:apply-templates select="$resource" mode="bs2:Row">
                            <xsl:with-param name="graph" select="$graph" tunnel="yes"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="show-edit-button" select="$show-edit-button" tunnel="yes"/>
                            <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                            <xsl:with-param name="show-row-block-controls" select="false()"/> <!-- blocks nested within ldh:Object do not show their own progress bars -->
                            <xsl:with-param name="draggable" select="false()"/> <!-- blocks nested within ldh:Object are not draggable -->
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:variable name="obj-value-id" select="'obj-value-' || generate-id($block)" as="xs:string"/>
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <!-- wrap the row -->
                            <div id="{$obj-value-id}" class="span12">
                                <xsl:copy-of select="$row"/>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                    
                    <xsl:sequence select="map:put($context, 'obj-value-id', $obj-value-id)"/>
                    
                    <!-- we don't want any of the other resources that may be part of root($resource) document -->
                    <xsl:variable name="resource-doc" as="document-node()">
                        <xsl:document>
                            <rdf:RDF>
                                <xsl:sequence select="$resource"/>
                            </rdf:RDF>
                        </xsl:document>
                    </xsl:variable>
                    
                    <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`'))">
                        <ixsl:set-property name="{'`' || $block/@about || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                    </xsl:if>

                    <!-- TO-DO: reuse similar initialization code from client.xsl -->
                    <xsl:if test="$mode = '&ac;MapMode' and key('elements-by-class', 'map-canvas', $block)">
                        <xsl:for-each select="$resource-doc">
                            <!-- initialize maps -->
                            <xsl:if test="key('elements-by-class', 'map-canvas', $block)">
                                <xsl:call-template name="ldh:DrawMap">
                                    <xsl:with-param name="block-uri" select="$block/@about"/>
                                    <xsl:with-param name="canvas-id" select="key('elements-by-class', 'map-canvas', $block)/@id"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                    <xsl:if test="$mode = '&ac;ChartMode' and key('elements-by-class', 'chart-canvas', $block)">
                        <!-- initialize charts -->
                        <xsl:for-each select="key('elements-by-class', 'chart-canvas', $block)">
                            <xsl:variable name="canvas-id" select="@id" as="xs:string"/>
                            <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
                            <xsl:variable name="category" as="xs:string?"/>
                            <xsl:variable name="series" select="distinct-values($resource-doc/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                            <xsl:variable name="data-table" select="ac:rdf-data-table($resource-doc, $category, $series)"/>

                            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`')"/>

                            <xsl:call-template name="ldh:RenderChart">
                                <xsl:with-param name="data-table" select="$data-table"/>
                                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
                    
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>        
    </xsl:function>

    <xsl:function name="ldh:block-object-apply" as="item()" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="obj-value-id" select="$context('obj-value-id')" as="xs:string"/>

        <xsl:message>ldh:block-object-apply $obj-value-id: <xsl:value-of select="$obj-value-id"/> exists(id($obj-value-id, ixsl:page())): <xsl:value-of select="exists(id($obj-value-id, ixsl:page()))"/></xsl:message>
    
        <!-- get the optional promise of the object value resource -->
        <xsl:variable name="rendered" as="(function(item()?) as map(*))?">
            <xsl:apply-templates select="id($obj-value-id, ixsl:page())" mode="ldh:RenderRow"/>
        </xsl:variable>
        
        <xsl:sequence select="if (exists($rendered)) then $rendered else ldh:object-noop#2($context, ?)"/>
    </xsl:function>
    
    <xsl:function name="ldh:object-noop" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?" />
        <!-- just return the context, doing nothing else -->
        <xsl:sequence select="$context"/>
    </xsl:function>

</xsl:stylesheet>