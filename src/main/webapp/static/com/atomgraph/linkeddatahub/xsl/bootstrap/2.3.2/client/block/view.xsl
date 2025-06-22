<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY dct    "http://purl.org/dc/terms/">
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
xmlns:srx="&srx;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:key name="resources-by-primary-topic" match="*[@rdf:about] | *[@rdf:nodeID]" use="foaf:primaryTopic/@rdf:resource"/>
    
    <xsl:param name="class-modes" as="map(xs:string, xs:anyURI)">
        <xsl:map>
            <xsl:map-entry key="'read-mode'" select="xs:anyURI('&ac;ReadMode')"/>
            <xsl:map-entry key="'list-mode'" select="xs:anyURI('&ac;ListMode')"/>
            <xsl:map-entry key="'table-mode'" select="xs:anyURI('&ac;TableMode')"/>
            <xsl:map-entry key="'grid-mode'" select="xs:anyURI('&ac;GridMode')"/>
            <xsl:map-entry key="'chart-mode'" select="xs:anyURI('&ac;ChartMode')"/>
            <xsl:map-entry key="'map-mode'" select="xs:anyURI('&ac;MapMode')"/>
            <xsl:map-entry key="'graph-mode'" select="xs:anyURI('&ac;GraphMode')"/>
        </xsl:map>
    </xsl:param>
        
    <!-- TEMPLATES -->

    <!-- render view -->

    <xsl:template match="*[@typeof = '&ldh;View'][descendant::*[@property = '&spin;query'][@resource]]" mode="ldh:RenderRow" as="function(item()?) as map(*)" priority="2"> <!-- prioritize above block.xsl -->
        <xsl:param name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:param name="this" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/> <!-- document URL -->
        <xsl:param name="parent-about" select="$block/ancestor::*[@about][1]/@about" as="xs:anyURI"/> <!-- outer @about context -->
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="query-uri" select="descendant::*[@property = '&spin;query']/@resource" as="xs:anyURI"/>

        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'50%'" object="."/>
        </xsl:for-each>
        
        <xsl:message>
            $parent-about: <xsl:value-of select="$parent-about"/>
        </xsl:message>
        
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, ac:document-uri($query-uri))" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <!-- $about in the query gets set to the @about of the *parent* block  -->
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'this': $this,
            'about': $parent-about,
            'block': $block,
            'container': $container,
            'mode': $mode,
            'refresh-content': $refresh-content,
            'query-uri': $query-uri
          }"/>
            
        <xsl:sequence select="
            ldh:load-block#3(
                $context,
                ldh:view-self-thunk#1,
                ?
            )
        "/>
    </xsl:template>
    
    <xsl:function name="ldh:view-self-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:message>ldh:view-self-thunk</xsl:message>

        <xsl:sequence select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-query-thunk#1) =>
                ixsl:then(ldh:view-results-thunk#1)
        "/>
    </xsl:function>
    
    <xsl:function name="ldh:view-query-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:message>ldh:view-query-thunk</xsl:message>

        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:view-query-response#1)
        "/>
    </xsl:function>
    
    <xsl:function name="ldh:view-results-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        
        <xsl:message>ldh:view-results-thunk</xsl:message>

        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>        
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:load-object-metadata#1) =>
                ixsl:then(ldh:http-request-threaded#1) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:set-object-metadata#1) =>
                ixsl:then(ldh:render-view#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:load-object-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="endpoint" select="$context('endpoint')" as="xs:anyURI"/>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="results" select="?body" as="document-node()"/>

                    <xsl:choose>
                        <xsl:when test="$endpoint = sd:endpoint()">
                            <xsl:variable name="object-uris" select="distinct-values($results/rdf:RDF/rdf:Description/*/@rdf:resource[not(key('resources', .))])" as="xs:string*"/>
                            <xsl:variable name="query-string" select="$object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>                    
                            <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $endpoint, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                            <xsl:sequence select="map:merge(($context, map{ 'request': $request , 'response': () , 'results': $results }), map{ 'duplicates': 'use-last' })"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="map:merge(($context, map{ 'results': $results }))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="alert alert-block">
                                <strong>Could not load query results from <a href="{$endpoint}"><xsl:value-of select="$endpoint"/></a></strong>
                                <pre>
                                    <xsl:value-of select="$response?message"/>
                                </pre>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>

                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

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
    </xsl:function>
    
    <xsl:function name="ldh:set-object-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="object-metadata" select="?body" as="document-node()?"/>
                    <xsl:sequence select="map:merge(($context, map{ 'object-metadata': $object-metadata }))"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- ignore object metadata loading errors - treat as empty metadata -->
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
   
    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;View']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- provide a property label which otherwise would default to local-name() client-side (since $property-metadata is not loaded) -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;View']/rdfs:label | *[rdf:type/@rdf:resource = '&ldh;View']/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- result count -->
    
    <xsl:template match="srx:binding[@name][srx:literal]" mode="bs2:ViewResultCount" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>

        <xsl:choose>
            <xsl:when test="@name = $count-var-name">
                <strong>
                    <xsl:apply-templates select="key('resources', 'total-results', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    <xsl:text> </xsl:text>
                    <span class="badge badge-inverse">
                        <xsl:value-of select="srx:literal"/>
                    </span>
                </strong>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="srx:*" mode="bs2:ViewResultCount">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!-- facets -->
    
    <xsl:template match="srx:result" mode="bs2:FacetValueItem">
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:param name="count-var-name" as="xs:string"/>
        <xsl:param name="label-sample-var-name" as="xs:string?"/>
        <xsl:param name="label" as="xs:string?"/>
        
        <li>
            <label class="checkbox">
                <!-- store value type ('uri'/'literal') in a hidden input -->
                <input type="hidden" name="type" value="{srx:binding[@name = $object-var-name]/srx:*/local-name()}"/>
                <xsl:if test="srx:binding[@name = $object-var-name]/srx:literal/@datatype">
                    <input type="hidden" name="datatype" value="{srx:binding[@name = $object-var-name]/srx:literal/@datatype}"/>
                </xsl:if>
                <!-- store count in a hidden input -->
                <input type="hidden" name="count" value="{srx:binding[@name = $count-var-name]/srx:literal}"/>

                <input type="checkbox" name="{$object-var-name}" value="{srx:binding[@name = $object-var-name]/srx:*}"/> <!-- can be srx:literal -->
                <span title="{srx:binding[@name = $object-var-name]/srx:*}">
                    <xsl:choose>
                        <!-- label explicitly supplied -->
                        <xsl:when test="$label">
                            <xsl:value-of select="$label"/>
                        </xsl:when>
                        <!-- there is a separate ?label value - show it -->
                        <xsl:when test="srx:binding[@name = $label-sample-var-name]/srx:literal">
                            <xsl:value-of select="srx:binding[@name = $label-sample-var-name]/srx:literal"/>
                        </xsl:when>
                        <!-- show the raw value -->
                        <xsl:otherwise>
                            <xsl:value-of select="srx:binding[@name = $object-var-name]/srx:*"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="srx:binding[@name = $count-var-name]/srx:literal"/>
                    <xsl:text>)</xsl:text>
                </span>
            </label>
        </li>
    </xsl:template>
    
    <!-- facet predicate block -->
    <xsl:template match="rdf:Description[@rdf:about]" mode="bs2:FilterIn">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'sidebar-nav faceted-nav'" as="xs:string?"/>
        <xsl:param name="subject-var-name" as="xs:string"/>
        <xsl:param name="object-var-name" as="xs:string"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <h2 class="nav-header btn" title="{@rdf:about}">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>

                <span class="caret caret-reversed pull-right"></span>
                <input type="hidden" name="subject" value="{$subject-var-name}"/>
                <input type="hidden" name="predicate" value="{@rdf:about}"/>
                <input type="hidden" name="object" value="{$object-var-name}"/>
            </h2>

            <!-- facet values will be loaded into an <ul> here -->
        </div>
    </xsl:template>
    
    <!-- result counts -->
    
    <xsl:template name="ldh:ResultCount">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="count-var-name" select="'count'" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <!-- unset ORDER BY/LIMIT/OFFSET - we want to COUNT all of the container's children; ordering is irrelevant -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-order-by"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:apply-templates select="$select-xml" mode="ldh:result-count">
                    <xsl:with-param name="count-var-name" select="$count-var-name" tunnel="yes"/>
                    <xsl:with-param name="expression-var-name" select="$focus-var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="select-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $select-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $select-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, $results-uri)" as="xs:anyURI"/>       
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri,  'headers': map { 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map {
            'request': $request,
            'container': .,
            'count-var-name': $count-var-name
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:result-count-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- order by -->
    
    <xsl:template match="*[@rdf:about]" mode="bs2:OrderBy">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="order-by-predicate" as="xs:anyURI?"/>

        <!-- TO-DO: order options -->
        <option value="{@rdf:about}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="@rdf:about = $order-by-predicate">
                <xsl:attribute name="selected" select="'selected'"/>
            </xsl:if>
            
            <xsl:value-of>
                <xsl:apply-templates select="." mode="ac:label"/>
            </xsl:value-of>
        </option>
    </xsl:template>
    
    <!-- pager -->

    <xsl:template name="bs2:PagerList">
        <xsl:param name="result-count" as="xs:integer?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <xsl:variable name="limit" select="if ($select-xml/json:map/json:number[@key = 'limit']) then xs:integer($select-xml/json:map/json:number[@key = 'limit']) else 0" as="xs:integer"/>
        <xsl:variable name="show" select="($offset - $limit) &gt;= 0 or $result-count &gt;= $limit" as="xs:boolean"/>

        <!-- do not show pagination if the children document count is less than the page limit -->
        <xsl:if test="$show">
            <ul class="pager">
                <li class="previous">
                    <xsl:choose>
                        <xsl:when test="($offset - $limit) &gt;= 0">
                            <a class="active">
                                <!-- event listener will handle the click -->
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class" select="'previous disabled'"/>
                            <a></a>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li class="next">
                    <xsl:choose>
                        <xsl:when test="$result-count &gt;= $limit">
                            <a class="active">
                                <!-- event listener will handle the click -->
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class" select="'next disabled'"/>
                            <a></a>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
            </ul>
        </xsl:if>
    </xsl:template>

    <!-- view mode tabs -->
    
    <xsl:template name="bs2:ViewModeTabs">
        <xsl:param name="active-mode" as="xs:anyURI"/>

        <ul class="nav nav-tabs view-mode-nav-tabs">
            <li class="read-mode">
                <xsl:if test="$active-mode = '&ac;ReadMode'">
                    <xsl:attribute name="class" select="'read-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;ReadMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;ReadMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
            <li class="list-mode">
                <xsl:if test="$active-mode = '&ac;ListMode'">
                    <xsl:attribute name="class" select="'list-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;ListMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;ListMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
            <li class="table-mode">
                <xsl:if test="$active-mode = '&ac;TableMode'">
                    <xsl:attribute name="class" select="'table-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;TableMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;TableMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
            <li class="grid-mode">
                <xsl:if test="$active-mode = '&ac;GridMode'">
                    <xsl:attribute name="class" select="'grid-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;GridMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;GridMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
            <li class="chart-mode">
                <xsl:if test="$active-mode = '&ac;ChartMode'">
                    <xsl:attribute name="class" select="'chart-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;ChartMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;ChartMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
            <li class="map-mode">
                <xsl:if test="$active-mode = '&ac;MapMode'">
                    <xsl:attribute name="class" select="'map-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;MapMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;MapMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
            <li class="graph-mode">
                <xsl:if test="$active-mode = '&ac;GraphMode'">
                    <xsl:attribute name="class" select="'graph-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;GraphMode', document(ac:document-uri('&ac;')))" mode="ldh:logo"/>
                    <xsl:apply-templates select="key('resources', '&ac;GraphMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </li>
        </ul>
    </xsl:template>
    
    <!-- render view -->
    
    <xsl:template name="ldh:RenderView">
        <xsl:param name="block" as="element()"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" select="xs:anyURI"/>
        <xsl:param name="initial-var-name" as="xs:string"/>
        <xsl:param name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>

        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, $results-uri)" as="xs:anyURI"/>
        <xsl:variable name="headers" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'Accept'" select="'application/rdf+xml'"/>
                
                <xsl:if test="$refresh-content">
                    <xsl:map-entry key="'Cache-Control'" select="'no-cache, no-store, must-revalidate'"/>
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': $headers }" as="map(*)"/>
        <xsl:sequence select="
          map{
            'request': $request,
            'block': $block,
            'container': $container,
            'container-id': generate-id($container),
            'active-mode': $active-mode,
            'select-string': $select-string,
            'select-xml': $select-xml,
            'initial-var-name': $initial-var-name,
            'focus-var-name': $focus-var-name,
            'endpoint': $endpoint
          }"/>
    </xsl:template>

    <!-- $container here is the inner result container, not the content container! -->
    <xsl:template name="ldh:RenderViewMode">
        <xsl:param name="block" as="element()"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="base-uri" as="xs:anyURI"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="ldh:ViewModeChoice">
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="results" select="$results"/>
                    <xsl:with-param name="active-mode" select="$active-mode"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>

        <!-- after we've created the map container element, create the JS objects using it -->
        <xsl:if test="$active-mode = '&ac;MapMode'">
            <!-- unset LIMIT and OFFSET - we want all of the container's children on the map -->
            <xsl:variable name="select-xml" as="document-node()">
                <xsl:document>
                    <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit"/>
                </xsl:document>
            </xsl:variable>
            <xsl:variable name="select-xml" as="document-node()">
                <xsl:document>
                    <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset"/>
                </xsl:document>
            </xsl:variable>

            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <xsl:call-template name="ldh:LoadGeoResources">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="container-id" select="$container-id"/>
                <xsl:with-param name="block-uri" select="$block/@about"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="base-uri" select="$base-uri"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$active-mode = '&ac;ChartMode'">
            <xsl:variable name="canvas-id" select="$container-id || '-chart-canvas'" as="xs:string"/>
            <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
            <xsl:variable name="category" as="xs:string?"/>
            <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
            <xsl:variable name="data-table" select="ac:rdf-data-table($results, $category, $series)"/>

            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`')"/>

            <xsl:call-template name="ldh:RenderChart">
                <xsl:with-param name="data-table" select="$data-table"/>
                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="render-container-error">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="message" as="xs:string"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="alert alert-block">
                    <strong>Error during query execution:</strong>
                    <pre>
                        <xsl:value-of select="$message"/>
                    </pre>
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- view mode choice -->
    
    <xsl:template name="ldh:ViewModeChoice">
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="$active-mode = '&ac;ListMode'">
                <xsl:apply-templates select="$results" mode="bs2:ContainerBlockList">
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;TableMode'">
                <xsl:apply-templates select="$results" mode="bs2:ContainerTable">
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;GridMode'">
                <xsl:apply-templates select="$results" mode="bs2:ContainerGrid">
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;ChartMode'">
                <xsl:apply-templates select="$results" mode="bs2:Chart">
                    <xsl:with-param name="canvas-id" select="$container-id || '-chart-canvas'"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;MapMode'">
                <xsl:apply-templates select="$results" mode="bs2:Map">
                    <xsl:with-param name="id" select="$container-id || '-map-canvas'"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                    <xsl:with-param name="draggable" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;GraphMode'">
                <xsl:apply-templates select="$results" mode="bs2:Graph">
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$results">
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- view results -->
    
    <xsl:template name="ldh:RenderViewResults">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="block" as="element()"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="bgp-triples-map" as="element()*"/>
        <xsl:param name="desc" as="xs:boolean?"/>
        <xsl:param name="order-by-predicate" as="xs:anyURI?"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="result-count-container-id" as="xs:string"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <!-- if  the container is full-width row (.row-fluid), render results in the middle column (.main) -->
        <xsl:variable name="order-by-container-id" select="$container-id || '-container-order'" as="xs:string"/>
        <xsl:variable name="container-results-id" select="$container-id || '-container-results'" as="xs:string"/>
        <xsl:variable name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>

        <!-- store sorted results as the current view results -->
        <ixsl:set-property name="results" select="$results" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`')"/>

        <xsl:variable name="initial-load" select="empty(.//div[@id = $container-results-id])" as="xs:boolean"/>
        <xsl:message>$initial-load: <xsl:value-of select="$initial-load"/></xsl:message>
        <!-- first time rendering the view results -->
        <xsl:if test="$initial-load">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <h2>
                    <xsl:value-of select="$container/descendant::*[@property = '&dct;title']"/>
                </h2>
  
                <div class="pull-right">
                    <form class="form-inline">
                        <label for="{$order-by-container-id}">
                            <!-- currently no space for the label in the layout -->
                            <!--<xsl:text>Order by </xsl:text>-->

                            <select id="{$order-by-container-id}" name="order-by" class="input-medium container-order">
                                <!-- show the default option if the container query does not have an ORDER BY -->
                                <xsl:if test="not($select-xml/json:map/json:array[@key = 'order'])">
                                    <option>
                                        <xsl:value-of>
                                            <xsl:text>[</xsl:text>
                                            <xsl:apply-templates select="key('resources', 'none', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            <xsl:text>]</xsl:text>
                                        </xsl:value-of>
                                    </option>
                                </xsl:if>
                            </select>

                            <xsl:choose>
                                <xsl:when test="not($desc)">
                                    <button type="button" class="btn btn-order-by">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'ascending', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                </xsl:when>
                                <xsl:otherwise>
                                    <button type="button" class="btn btn-order-by btn-order-by-desc">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'descending', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                </xsl:otherwise>
                            </xsl:choose>
                        </label>
                    </form>
                </div>

                <div>
                    <p id="{$result-count-container-id}" class="result-count"/>

                    <xsl:call-template name="bs2:ViewModeTabs">
                        <xsl:with-param name="active-mode" select="$active-mode"/>
                    </xsl:call-template>

                    <div id="{$container-results-id}" class="container-results"></div>
                </div>
            </xsl:result-document>

            <!-- result count -->
            <xsl:for-each select="id($result-count-container-id, ixsl:page())">
                <xsl:call-template name="ldh:ResultCount">
                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                </xsl:call-template>
            </xsl:for-each>
             
            <xsl:for-each select="$bgp-triples-map">
                <!-- only simple properties in the BGP are supported, not property paths etc. -->
                <xsl:if test="json:string[@key = 'predicate']">
                    <xsl:variable name="id" select="generate-id()" as="xs:string"/>
                    <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': string($predicate), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                    <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                    <xsl:variable name="context" as="map(*)" select="
                      map{
                        'request': $request,
                        'container': id($order-by-container-id, ixsl:page()),
                        'id': $id,
                        'predicate': $predicate,
                        'order-by-predicate': $order-by-predicate
                      }"/>
                    <ixsl:promise select="ixsl:http-request($context('request')) =>
                        ixsl:then(ldh:rethread-response($context, ?)) =>
                        ixsl:then(ldh:handle-response#1) =>
                        ixsl:then(ldh:order-by-response#1)"
                        on-failure="ldh:promise-failure#1"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        
        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <ixsl:set-style name="width" select="'88%'" object="."/>
        </xsl:for-each>
                
        <xsl:call-template name="ldh:RenderViewMode">
            <xsl:with-param name="block" select="$block"/>
            <xsl:with-param name="container" select=".//div[contains-token(@class, 'container-results')]"/>
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="endpoint" select="$endpoint"/>
            <xsl:with-param name="results" select="$results"/>
            <xsl:with-param name="object-metadata" select="$object-metadata"/>
            <xsl:with-param name="active-mode" select="$active-mode"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="base-uri" select="$base-uri"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- facets -->

    <xsl:template name="ldh:RenderFacets">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="sub-container-id" as="xs:string"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <!-- use the first SELECT variable as the facet variable name (so that we do not generate facets based on other variables) -->
        <xsl:variable name="initial-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        
        <!-- only append facets if they are not already present -->
        <xsl:if test="not(id($sub-container-id, ixsl:page()))">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:apply-templates select="." mode="ldh:RenderFacets">
                    <xsl:with-param name="id" select="$sub-container-id"/>
                </xsl:apply-templates>
            </xsl:result-document>
            
            <xsl:variable name="sub-container" select="id($sub-container-id, ixsl:page())" as="element()"/>
            <!-- use the BGPs where the predicate is a URI value and the subject and object are variables -->
            <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $initial-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>

            <xsl:for-each select="$bgp-triples-map">
                <!-- only simple properties in the BGP are supported, not property paths etc. -->
                <xsl:if test="json:string[@key = 'predicate']">
                    <xsl:variable name="id" select="generate-id()" as="xs:string"/>
                    <xsl:variable name="subject-var-name" select="json:string[@key = 'subject']/substring-after(., '?')" as="xs:string"/>
                    <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:anyURI"/>
                    <xsl:variable name="object-var-name" select="json:string[@key = 'object']/substring-after(., '?')" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': string($predicate), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                    <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                    <xsl:variable name="context" as="map(*)" select="
                      map{
                        'request': $request,
                        'container': $sub-container,
                        'subject-var-name': $subject-var-name,
                        'predicate': $predicate,
                        'object-var-name': $object-var-name
                      }"/>
                    <ixsl:promise select="ixsl:http-request($context('request')) =>
                        ixsl:then(ldh:rethread-response($context, ?)) =>        
                        ixsl:then(ldh:handle-response#1) =>
                        ixsl:then(ldh:facet-filter-response#1)"
                        on-failure="ldh:promise-failure#1"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="ldh:RenderFacets">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well well-small'" as="xs:string?"/>
                
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
        </div>
    </xsl:template>
        
    <!-- DEFAULT  -->
    
    <!-- TO-DO: move to Web-Client -->
    <xsl:template match="rdf:RDF">
        <xsl:apply-templates>
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- block list -->

    <xsl:template match="rdf:RDF" mode="bs2:ContainerBlockList" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>

        <xsl:apply-templates select="." mode="bs2:List"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*[key('resources', foaf:primaryTopic/@rdf:resource)]" mode="bs2:List" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="ldh:logo">
                <xsl:with-param name="class" select="'well'"/>
            </xsl:apply-templates>
            
            <!-- don't show actions on a document that wraps a thing -->
            <!--<xsl:apply-templates select="." mode="bs2:Actions"/>-->

            <xsl:apply-templates select="." mode="bs2:TypeList"/>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="xhtml:Anchor"/>

            <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="bs2:Header">
                <xsl:with-param name="class" select="'well well-small'"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <!-- hide resources that will be shown paired/nested with a document -->
    <xsl:template match="*[key('resources-by-primary-topic', @rdf:about)]" mode="bs2:List" priority="1"/>
    
    <xsl:template match="*[*][@rdf:*[local-name() = ('about', 'nodeID')]]" mode="bs2:List" priority="0.8">
        <xsl:apply-templates select="." mode="bs2:Header"/>
    </xsl:template>

    <!-- grid -->

    <!-- override Web-Client's template to avoid sort by ac:label() -->
    <xsl:template match="rdf:RDF" mode="bs2:Grid">
        <xsl:param name="thumbnails-per-row" select="2" as="xs:integer"/>
        <xsl:param name="sort-property" as="xs:anyURI?"/>

        <xsl:variable name="prelim-items" as="item()*">
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="thumbnails-per-row" select="$thumbnails-per-row" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="items" select="$prelim-items/self::*" as="element()*"/>
        
        <xsl:for-each-group select="$items" group-adjacent="(position() - 1) idiv $thumbnails-per-row">
            <div class="row-fluid">
                <ul class="thumbnails">
                    <xsl:copy-of select="current-group()"/>
                </ul>
            </div>
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ContainerGrid" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>

        <xsl:apply-templates select="." mode="bs2:Grid"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <!-- hide documents that are paired with resources -->
    <xsl:template match="*[key('resources', foaf:primaryTopic/@rdf:resource)]" mode="bs2:Grid"/>

    <!-- table -->

    <xsl:template match="rdf:RDF" mode="bs2:ContainerTable" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>

        <xsl:apply-templates select="." mode="xhtml:Table"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <!-- hide documents that are paired with resources -->
    <xsl:template match="*[key('resources', foaf:primaryTopic/@rdf:resource)]" mode="xhtml:Table"/>

    <!-- graph -->

    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="draggable" select="true()" as="xs:boolean?"/> <!-- counter-intuitive but needed in order to trigger "ixsl:ondragstart" on the map and then cancel it -->

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$draggable = true()">
                <xsl:attribute name="draggable" select="'true'"/>
            </xsl:if>
            <xsl:if test="$draggable = false()">
                <xsl:attribute name="draggable" select="'false'"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="ac:SVG">
                <xsl:with-param name="width" select="'100%'"/>
                <xsl:with-param name="step-count" select="5"/>
                <xsl:with-param name="spring-length" select="100" tunnel="yes"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <!-- parallax -->
    
    <xsl:template name="bs2:ParallaxNav">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="sub-container-id" as="xs:string"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" select="xs:anyURI"/>
        <xsl:param name="properties-container-id" select="$sub-container-id || '-parallax-properties'" as="xs:string"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        
         <!-- create a container for parallax controls in the right-nav, if it doesn't exist yet -->
        <xsl:if test="not(id($sub-container-id, ixsl:page()))">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:apply-templates select="." mode="bs2:ParallaxNav">
                    <xsl:with-param name="id" select="$sub-container-id"/>
                    <xsl:with-param name="properties-container-id" select="$properties-container-id"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:if>
        <!-- clear existing properties in the list -->
        <xsl:for-each select="id($properties-container-id, ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content"/>
        </xsl:for-each>

        <!-- only render parallax if the RDF result contains object resources -->
        <xsl:if test="$results/rdf:RDF/*/*[@rdf:resource]">
            <xsl:variable name="query-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
            <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
            <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
            <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
            <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, $results-uri)" as="xs:anyURI"/>
            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
            <xsl:variable name="context" as="map(*)" select="
              map{
                'request': $request,
                'container': id($properties-container-id, ixsl:page()),
                'var-name': $focus-var-name,
                'results': $results
              }"/>
            <ixsl:promise select="ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:parallax-response#1)"
                on-failure="ldh:promise-failure#1"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*" mode="bs2:ParallaxNav">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well well-small sidebar-nav parallax-nav'" as="xs:string?"/>
        <xsl:param name="properties-container-id" as="xs:string"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <h2 class="nav-header btn">
                <xsl:apply-templates select="key('resources', 'related-results', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </h2>

            <ul id="{$properties-container-id}" class="well well-small nav nav-list">
                <!-- <li> with properties will go here -->
            </ul>
        </div>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->

    <!-- view mode tabs -->
    
    <xsl:template match="*[@typeof]//div/ul[contains-token(@class, 'view-mode-nav-tabs')]/li[not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="results-container" select="$container//div[contains-token(@class, 'container-results')]" as="element()"/> <!-- results in the middle column -->
        <xsl:variable name="active-class" select="../@class" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="object-uris" select="distinct-values($results/rdf:RDF/rdf:Description/*/@rdf:resource[not(key('resources', .))])" as="xs:string*"/>
        <xsl:variable name="query-string" select="$object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
        <xsl:variable name="container-id" select="generate-id($container)" as="xs:string"/>
        <xsl:variable name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>

        <!-- deactivate other tabs -->
        <xsl:for-each select="../../li">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="..">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': sd:endpoint(), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- pager prev links -->

    <xsl:template match="*[@typeof]//ul[@class = 'pager']/li[@class = 'previous']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//ul[contains-token(@class, 'view-mode-nav-tabs')]/li[contains-token(@class, 'active')]/@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <!-- descrease OFFSET to get the previous page -->
        <xsl:variable name="offset" select="$offset - $page-size" as="xs:integer"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                    <xsl:with-param name="offset" select="$offset" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
        
        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- pager next links -->
    
    <xsl:template match="*[@typeof]//ul[@class = 'pager']/li[@class = 'next']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//ul[contains-token(@class, 'view-mode-nav-tabs')]/li[contains-token(@class, 'active')]/@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <!-- increase OFFSET to get the next page -->
        <xsl:variable name="offset" select="$offset + $page-size" as="xs:integer"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                    <xsl:with-param name="offset" select="$offset" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
        
        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- order by onchange -->
    
    <xsl:template match="select[contains-token(@class, 'container-order')]" mode="ixsl:onchange">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//ul[contains-token(@class, 'view-mode-nav-tabs')]/li[contains-token(@class, 'active')]/@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="predicate" select="ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $initial-var-name][json:string[@key = 'predicate'] = $predicate][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>
        <xsl:variable name="var-name" select="$bgp-triples-map/json:string[@key = 'object'][1]/substring-after(., '?')" as="xs:string?"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:replace-order-by">
                    <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- ascending/descending onclick -->
    
    <!-- TO-DO: unify with container ORDER BY onchange -->
    <xsl:template match="div[@typeof]//button[contains-token(@class, 'btn-order-by')]" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//ul[contains-token(@class, 'view-mode-nav-tabs')]/li[contains-token(@class, 'active')]/@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="desc" select="contains(@class, 'btn-order-by-desc')" as="xs:boolean"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:toggle-desc">
                    <xsl:with-param name="desc" select="not($desc)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
        
        <!-- toggle the arrow direction -->
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-order-by-desc' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- facet header onclick -->
    
    <xsl:template match="div[contains-token(@class, 'faceted-nav')]//*[contains-token(@class, 'nav-header')]" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="facet-container" select="ancestor::div[contains-token(@class, 'faceted-nav')]" as="element()"/>
        <xsl:variable name="subject-var-name" select="input[@name = 'subject']/@value" as="xs:string"/>
        <xsl:variable name="predicate" select="input[@name = 'predicate']/@value" as="xs:anyURI"/>
        <xsl:variable name="object-var-name" select="input[@name = 'object']/@value" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
<!--        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>-->
        <!-- TO-DO: can we get multiple BGPs here with the same ?s/p/?o ? -->
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $subject-var-name][json:string[@key = 'predicate'] = $predicate][json:string[@key = 'object'] = '?' || $object-var-name]" as="element()"/>

        <!-- is the current facet loaded? -->
        <xsl:variable name="loaded" select="exists(following-sibling::ul)" as="xs:boolean"/>
        <xsl:choose>
            <!-- if not, load and render its values -->
            <xsl:when test="not($loaded)">
                <xsl:for-each select="$container">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <!-- the subject is a variable - trim the leading question mark -->
                    <xsl:variable name="subject-var-name" select="substring-after($bgp-triples-map/json:string[@key = 'subject'], '?')" as="xs:string"/>
                    <!-- predicate is a URI -->
                    <xsl:variable name="predicate" select="$bgp-triples-map/json:string[@key = 'predicate']" as="xs:anyURI"/>
                    <!-- the object is a variable - trim the leading question mark -->
                    <xsl:variable name="object-var-name" select="substring-after($bgp-triples-map/json:string[@key = 'object'], '?')" as="xs:string"/>
                    <!-- generate unique variable name for COUNT(?subject) -->
                    <xsl:variable name="count-var-name" select="'count' || $subject-var-name || generate-id()" as="xs:string"/>
                    <!-- generate unique variable name for ?label -->
                    <xsl:variable name="label-var-name" select="'label' || $object-var-name || generate-id()" as="xs:string"/>
                    <xsl:variable name="label-sample-var-name" select="$label-var-name || 'sample'" as="xs:string"/>
                    <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
                    <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
                    <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

                    <!-- generate the XML structure of a SPARQL query which is used to load facet values, their counts and labels -->
                    <xsl:variable name="select-xml" as="document-node()">
                        <xsl:document>
                            <xsl:apply-templates select="$select-xml" mode="ldh:bgp-value-counts">
                                <xsl:with-param name="bgp-triples-map" select="$bgp-triples-map" tunnel="yes"/>
                                <xsl:with-param name="subject-var-name" select="$subject-var-name" tunnel="yes"/>
                                <xsl:with-param name="object-var-name" select="$object-var-name" tunnel="yes"/>
                                <xsl:with-param name="count-var-name" select="$count-var-name" tunnel="yes"/>
                                <xsl:with-param name="label-var-name" select="$label-var-name" tunnel="yes"/>
                                <xsl:with-param name="label-sample-var-name" select="$label-sample-var-name" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:document>
                    </xsl:variable>
                    <xsl:variable name="select-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
                    <xsl:variable name="select-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $select-json-string ])"/>
                    <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $select-json ]), 'toString', [])" as="xs:string"/>
                    <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, $results-uri)" as="xs:anyURI"/>
                    <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
                    <xsl:variable name="context" as="map(*)" select="
                      map{
                        'request': $request,
                        'container': $facet-container,
                        'predicate': $predicate,
                        'object-var-name': $object-var-name,
                        'count-var-name': $count-var-name,
                        'label-sample-var-name': $label-sample-var-name
                      }"/>

                    <ixsl:promise select="ixsl:http-request($context('request')) =>
                        ixsl:then(ldh:rethread-response($context, ?)) =>
                        ixsl:then(ldh:handle-response#1) =>
                        ixsl:then(ldh:facet-value-response#1)"
                        on-failure="ldh:promise-failure#1"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- is the current facet hidden? -->
                <xsl:variable name="hidden" select="ixsl:style(following-sibling::*[contains-token(@class, 'nav')])?display = 'none'" as="xs:boolean"/>

                <!-- toggle the caret direction -->
                <xsl:for-each select="span[contains-token(@class, 'caret')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <!-- toggle the value list visibility -->
                <xsl:choose>
                    <xsl:when test="$hidden">
                        <ixsl:set-style name="display" select="'block'" object="following-sibling::*[contains-token(@class, 'nav')]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <ixsl:set-style name="display" select="'none'" object="following-sibling::*[contains-token(@class, 'nav')]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- facet onchange -->

    <xsl:template match="div[@typeof]//div[contains-token(@class, 'faceted-nav')]//input[@type = 'checkbox']" mode="ixsl:onchange">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//ul[contains-token(@class, 'view-mode-nav-tabs')]/li[contains-token(@class, 'active')]/@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="var-name" select="@name" as="xs:string"/>
        <!-- collect the values/types/datatypes of all checked inputs within this facet and build an array of maps -->
        <xsl:variable name="labels" select="ancestor::ul//label[input[@type = 'checkbox'][ixsl:get(., 'checked')]]" as="element()*"/>
        <xsl:variable name="values" select="array { for $label in $labels return map { 'value' : string($label/input[@type = 'checkbox']/@value), 'type': string($label/input[@name = 'type']/@value), 'datatype': string($label/input[@name = 'datatype']/@value) } }" as="array(map(xs:string, xs:string))"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:filter-in">
                    <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                    <xsl:with-param name="values" select="$values" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- parallax onclick -->
    
    <xsl:template match="div[@typeof]//div[contains-token(@class, 'parallax-nav')]/ul/li/a" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI($block/@about)" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//ul[contains-token(@class, 'view-mode-nav-tabs')]/li[contains-token(@class, 'active')]/@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="predicate" select="input/@value" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:add-parallax-step">
                    <xsl:with-param name="predicate" select="$predicate" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:variable name="context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- CALLBACKS -->
    
    <xsl:function name="ldh:view-query-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="this" select="$context('this')" as="xs:anyURI"/>
        <xsl:variable name="about" select="$context('about')" as="xs:anyURI"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="mode" select="$context('mode')" as="xs:anyURI?"/>
        <xsl:variable name="refresh-content" select="$context('refresh-content')" as="xs:boolean?"/>
        <xsl:variable name="query-uri" select="$context('query-uri')" as="xs:anyURI"/>
        <xsl:variable name="block-uri" select="$block/@about" as="xs:anyURI"/>

        <xsl:message>ldh:view-query-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="select-query" select="key('resources', $query-uri)" as="element()"/>
                        <xsl:variable name="service-uri" select="xs:anyURI($select-query/ldh:service/@rdf:resource)" as="xs:anyURI?"/>
                        <!-- set $this variable value unless getting the query string from state -->
                        <xsl:variable name="select-string" select="replace($select-query/sp:text, '$this', '&lt;' || $this || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="select-string" select="replace($select-string, '$about', '&lt;' || $about || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="select-xml" as="document-node()">
                            <xsl:variable name="select-json" as="item()">
                                <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                                <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
                            </xsl:variable>
                            <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
                            <xsl:sequence select="json-to-xml($select-json-string)"/>
                        </xsl:variable>
                        <xsl:variable name="initial-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
                        <xsl:variable name="focus-var-name" select="$initial-var-name" as="xs:string"/>
                        <!-- service can be explicitly specified on content using ldh:service -->
                        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
                        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>

                        <xsl:choose>
                            <!-- service URI is not specified or specified and can be loaded -->
                            <xsl:when test="not($service-uri) or ($service-uri and exists($service))">
                                <!-- create window.LinkedDataHub.contents[{$block-uri}] object if it's not already created -->
                                <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'))">
                                    <!-- create new cache entry using content URI as key -->
                                    <ixsl:set-property name="{'`' || $block-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                                </xsl:if>

                                <!-- store the initial SELECT query (without modifiers) -->
                                <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                                <!-- store the first var name of the initial SELECT query -->
                                <ixsl:set-property name="initial-var-name" select="$initial-var-name" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                                <xsl:if test="$service-uri">
                                    <!-- store (the URI of) the service -->
                                    <ixsl:set-property name="service-uri" select="$service-uri" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                                    <ixsl:set-property name="service" select="$service" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                                </xsl:if>

                                <xsl:variable name="select-xml" as="document-node()">
                                    <xsl:document>
                                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit">
                                            <xsl:with-param name="limit" select="$page-size" tunnel="yes"/>
                                        </xsl:apply-templates>
                                    </xsl:document>
                                </xsl:variable>
                                <xsl:variable name="select-xml" as="document-node()">
                                    <xsl:document>
                                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                                            <xsl:with-param name="offset" select="0" tunnel="yes"/>
                                        </xsl:apply-templates>
                                    </xsl:document>
                                </xsl:variable>

                                <!-- store the transformed query XML -->
                                <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                                <!-- update progress bar -->
                                <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
                                    <ixsl:set-style name="width" select="'63%'" object="."/>
                                </xsl:for-each>

                                <xsl:call-template name="ldh:RenderView">
                                    <xsl:with-param name="block" select="$block"/>
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="select-string" select="$select-string"/>
                                    <xsl:with-param name="select-xml" select="$select-xml"/>
                                    <xsl:with-param name="endpoint" select="$endpoint"/>
                                    <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                                    <xsl:with-param name="active-mode" select="if ($mode) then $mode else xs:anyURI('&ac;ListMode')"/>
                                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                                    <xsl:result-document href="?." method="ixsl:replace-content">
                                        <div class="alert alert-block">
                                            <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                                            <pre>
                                                <xsl:value-of select="$response?message"/>
                                            </pre>
                                        </div>
                                    </xsl:result-document>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="alert alert-block">
                                <strong>Could not load query resource: <a href="{$query-uri}"><xsl:value-of select="$query-uri"/></a></strong>
                                <pre>
                                    <xsl:value-of select="$response?message"/>
                                </pre>
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
    </xsl:function>
    
    <!-- when view RDF/XML results load, render them -->
    <xsl:function name="ldh:render-view" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="results" select="$context('results')" as="document-node()"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="container-id" select="$context('container-id')" as="xs:string"/>
        <xsl:variable name="active-mode" select="$context('active-mode')" as="xs:anyURI"/>
        <xsl:variable name="select-xml" select="$context('select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="$context('initial-var-name')" as="xs:string"/>
        <xsl:variable name="focus-var-name" select="$context('focus-var-name')" as="xs:string"/>
        <xsl:variable name="select-string" select="$context('select-string')" as="xs:string"/>
        <xsl:variable name="endpoint" select="$context('endpoint')" as="xs:anyURI"/>
        <xsl:variable name="object-metadata" select="$context('object-metadata')" as="document-node()?"/>
        <xsl:variable name="result-count-container-id" select="$container-id || '-result-count'" as="xs:string"/>
        
        <!-- update progress bar -->
        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>

        <xsl:for-each select="$results">
            <!-- use the BGPs where the predicate is a URI value and the subject and object are variables -->
            <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $initial-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>
            <xsl:variable name="order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
            <xsl:variable name="order-by-predicate" select="$bgp-triples-map[json:string[@key = 'object'] = '?' || $order-by-var-name][1]/json:string[@key = 'predicate']" as="xs:anyURI?"/>
            <xsl:variable name="desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
            <xsl:variable name="default-order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[2]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
            <xsl:variable name="default-order-by-predicate" select="$bgp-triples-map[json:string[@key = 'object'] = '?' || $default-order-by-var-name][1]/json:string[@key = 'predicate']" as="xs:anyURI?"/>
            <xsl:variable name="default-desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[2]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
            <xsl:variable name="sorted-results" as="document-node()">
                <xsl:document>
                    <xsl:for-each select="/rdf:RDF">
                        <xsl:copy>
                            <xsl:perform-sort select="*">
                                <!-- sort by $order-by-predicate if it is set (multiple properties might match) -->
                                <xsl:sort select="if ($order-by-predicate) then *[concat(namespace-uri(), local-name()) = $order-by-predicate][1]/(text(), @rdf:resource, @rdf:nodeID)[1]/string() else ()" order="{if ($desc) then 'descending' else 'ascending'}"/>
                                <!-- sort by $default-order-by-predicate if it is set and not equal to $order-by-predicate (multiple properties might match) -->
                                <xsl:sort select="if ($default-order-by-predicate and not($order-by-predicate = $default-order-by-predicate)) then *[concat(namespace-uri(), local-name()) = $default-order-by-predicate][1]/(text(), @rdf:resource, @rdf:nodeID)[1]/string() else ()" order="{if ($default-desc) then 'descending' else 'ascending'}"/>
                                <!-- soft by URI/bnode ID otherwise -->
                                <xsl:sort select="if (@rdf:about) then @rdf:about else @rdf:nodeID" order="{if ($default-desc) then 'descending' else 'ascending'}"/>
                            </xsl:perform-sort>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:document>
            </xsl:variable>

            <xsl:for-each select="$container/div[contains-token(@class, 'main')]">
                <xsl:call-template name="ldh:RenderViewResults">
                    <xsl:with-param name="block" select="$block"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="results" select="$sorted-results"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="bgp-triples-map" select="$bgp-triples-map"/>
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                    <xsl:with-param name="desc" select="$desc"/>
                    <xsl:with-param name="order-by-predicate" select="$order-by-predicate"/>
                    <xsl:with-param name="result-count-container-id" select="$result-count-container-id"/>
                    <xsl:with-param name="active-mode" select="$active-mode"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata"/>
                </xsl:call-template>
            </xsl:for-each>

            <!-- use the initial (not the current transformed) SELECT query and focus var name for facet rendering -->
            <xsl:for-each select="$container/div[contains-token(@class, 'left-nav')]">
                <xsl:call-template name="ldh:RenderFacets">
                    <xsl:with-param name="select-string" select="$select-string"/>
                    <xsl:with-param name="sub-container-id" select="$container-id || '-left-nav'"/>
                </xsl:call-template>
            </xsl:for-each>

            <xsl:for-each select="$container/div[contains-token(@class, 'right-nav')]">
                <xsl:call-template name="bs2:ParallaxNav">
                    <xsl:with-param name="results" select="$sorted-results"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                    <xsl:with-param name="sub-container-id" select="$container-id || '-right-nav'"/>
                </xsl:call-template>
            </xsl:for-each>

            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        </xsl:for-each>
        
        <!-- loading is done - restore the default mouse cursor -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:function>
    
    <!-- transform SPARQL BGP triple into facet header and placeholder -->
    <xsl:function name="ldh:facet-filter-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="subject-var-name" select="$context('subject-var-name')" as="xs:string"/>
        <xsl:variable name="predicate" select="$context('predicate')" as="xs:anyURI"/>
        <xsl:variable name="object-var-name" select="$context('object-var-name')" as="xs:string"/>

        <xsl:message>ldh:facet-filter-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:if test="?status = 200 and ?media-type = 'application/rdf+xml' and ?body">
                <xsl:variable name="body" select="?body" as="document-node()"/>

                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <xsl:apply-templates select="key('resources', $predicate, $body)" mode="bs2:FilterIn">
                            <xsl:with-param name="subject-var-name" select="$subject-var-name"/>
                            <xsl:with-param name="object-var-name" select="$object-var-name"/>
                        </xsl:apply-templates>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:if>
            <!-- ignore error response -->
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <xsl:function name="ldh:parallax-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="var-name" select="$context('var-name')" as="xs:string"/>       
        <xsl:variable name="results" select="$context('results')" as="document-node()"/>
        
        <xsl:message>ldh:parallax-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="var-name-resources" select="//srx:binding[@name = $var-name]/srx:uri" as="xs:anyURI*"/>

                        <xsl:for-each-group select="$results/rdf:RDF/*[@rdf:about = $var-name-resources]/*[@rdf:resource or @rdf:nodeID]" group-by="concat(namespace-uri(), local-name())">
                            <xsl:variable name="predicate" select="xs:anyURI(namespace-uri() || local-name())" as="xs:anyURI"/>
                            <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': $predicate, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                            <xsl:variable name="context" select="map:merge((
                              $context,
                              map{
                                'request': $request,
                                'container': $container,
                                'predicate': $predicate
                              }
                            ), map{ 'duplicates': 'use-last' })"/> 
                            <ixsl:promise select="ixsl:http-request($context('request')) =>
                                ixsl:then(ldh:rethread-response($context, ?)) =>
                                ixsl:then(ldh:handle-response#1) =>
                                ixsl:then(ldh:parallax-property-response#1)"
                                on-failure="ldh:promise-failure#1"/>
                        </xsl:for-each-group>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="response" select="." as="map(*)"/>
                    <!-- error response - could not load parallax results -->
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <div class="alert alert-block">
                                <strong>Error during query execution:</strong>
                                <pre>
                                    <xsl:value-of select="$response?message"/>
                                </pre>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <xsl:function name="ldh:parallax-property-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="class" select="$context('class')" as="xs:string?"/>
        <xsl:variable name="id" select="$context('id')" as="xs:string?"/>
        <xsl:variable name="predicate" select="$context('predicate')" as="xs:anyURI"/>
        
        <xsl:message>ldh:parallax-property-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>
            <xsl:variable name="existing-items" select="$container/li" as="element()*"/>
            <xsl:variable name="new-item" as="element()">
                <li>
                    <a title="{$predicate}">
                        <input name="ou" type="hidden" value="{$predicate}"/>
                        <xsl:variable name="resource" select="if ($results) then key('resources', $predicate, $results) else ()" as="element()?"/>

                        <xsl:choose>
                            <xsl:when test="$resource">
                                <xsl:value-of>
                                    <xsl:apply-templates select="$resource" mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:when>
                            <!-- attempt to use the fragment as label -->
                            <xsl:when test="contains($predicate, '#') and not(ends-with($predicate, '#'))">
                                <xsl:value-of select="substring-after($predicate, '#')"/>
                            </xsl:when>
                            <!-- attempt to use the last path segment as label -->
                            <xsl:when test="string-length(tokenize($predicate, '/')[last()]) &gt; 0">
                                <xsl:value-of select="translate(tokenize($predicate, '/')[last()], '_', ' ')"/>
                            </xsl:when>
                            <!-- fallback to simply displaying the full URI -->
                            <xsl:otherwise>
                                <xsl:value-of select="$predicate"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                </li>
            </xsl:variable>
            <xsl:variable name="items" as="element()*">
                <!-- sort the existing <li> items together with the new item -->
                <xsl:perform-sort select="($existing-items, $new-item)">
                    <!-- sort by the link text content (property label) -->
                    <xsl:sort select="a/text()" lang="{$ldt:lang}"/>
                </xsl:perform-sort>
            </xsl:variable>

            <xsl:for-each select="$container">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:sequence select="$items"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <xsl:function name="ldh:facet-value-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="predicate" select="$context('predicate')" as="xs:anyURI"/>
        <xsl:variable name="object-var-name" select="$context('object-var-name')" as="xs:string"/>
        <xsl:variable name="count-var-name" select="$context('count-var-name')" as="xs:string"/>
        <xsl:variable name="label-sample-var-name" select="$context('label-sample-var-name')" as="xs:string"/>

        <xsl:message>ldh:facet-value-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:variable name="response" select="." as="map(*)"/>
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="results" select="." as="document-node()"/>
                        <xsl:if test="$results//srx:result[srx:binding[@name = $object-var-name]]">
                            <xsl:choose>
                                <!-- special case for rdf:type - we expect its values to be in the ontology (classes), not in the instance data -->
                                <xsl:when test="$predicate = '&rdf;type'">
                                    <xsl:for-each select="$container">
                                        <xsl:result-document href="?." method="ixsl:append-content">
                                            <ul class="well well-small nav nav-list"></ul>
                                        </xsl:result-document>
                                    </xsl:for-each>

                                    <xsl:for-each select="$results//srx:result[srx:binding[@name = $object-var-name]]">
                                        <xsl:variable name="object-type" select="srx:binding[@name = $object-var-name]/srx:uri" as="xs:anyURI"/>
                                        <xsl:variable name="value-result" select="." as="element()"/>
                                        <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': $object-type, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                                        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                                        <xsl:variable name="context" as="map(*)" select="
                                          map{
                                            'request': $request,
                                            'container': $container,
                                            'object-var-name': $object-var-name,
                                            'count-var-name': $count-var-name,
                                            'object-type': $object-type,
                                            'value-result': $value-result
                                          }"/>
                                        <ixsl:promise select="ixsl:http-request($context('request')) =>
                                            ixsl:then(ldh:rethread-response($context, ?)) =>
                                            ixsl:then(ldh:handle-response#1) =>
                                            ixsl:then(ldh:facet-value-type-response#1)"
                                            on-failure="ldh:promise-failure#1"/>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- toggle the caret direction -->
                                    <xsl:for-each select="$container/h2/span[contains-token(@class, 'caret')]">
                                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                                    </xsl:for-each>

                                    <xsl:for-each select="$container">
                                        <xsl:result-document href="?." method="ixsl:append-content">
                                            <ul class="well well-small nav nav-list">
                                                <xsl:apply-templates select="$results//srx:result[srx:binding[@name = $object-var-name]]" mode="bs2:FacetValueItem">
                                                    <!-- order by count first -->
                                                    <xsl:sort select="xs:integer(srx:binding[@name = $count-var-name]/srx:literal)" order="descending"/>
                                                    <!-- order by label second -->
                                                    <xsl:sort select="srx:binding[@name = $label-sample-var-name]/srx:literal"/>
                                                    <xsl:sort select="srx:binding[@name = $object-var-name]/srx:*"/>

                                                    <xsl:with-param name="object-var-name" select="$object-var-name"/>
                                                    <xsl:with-param name="count-var-name" select="$count-var-name"/>
                                                    <xsl:with-param name="label-sample-var-name" select="$label-sample-var-name"/>
                                                </xsl:apply-templates>
                                            </ul>
                                        </xsl:result-document>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- error response - could not load facet results -->
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <div class="alert alert-block">
                                <strong>Error during query execution:</strong>
                                <pre>
                                    <xsl:value-of select="$response?message"/>
                                </pre>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>

            <!-- done loading, restore normal cursor -->
            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <xsl:function name="ldh:facet-value-type-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="object-var-name" select="$context('object-var-name')" as="xs:string"/>
        <xsl:variable name="count-var-name" select="$context('count-var-name')" as="xs:string"/>
        <xsl:variable name="object-type" select="$context('object-type')" as="xs:anyURI"/>
        <xsl:variable name="value-result" select="$context('value-result')" as="element()"/>

        <xsl:message>ldh:facet-value-type-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>
            <xsl:variable name="existing-items" select="$container/ul/li" as="element()*"/>
            <xsl:variable name="new-item" as="element()">
                <xsl:apply-templates select="$value-result" mode="bs2:FacetValueItem">
                    <xsl:with-param name="object-var-name" select="$object-var-name"/>
                    <xsl:with-param name="count-var-name" select="$count-var-name"/>
                    <xsl:with-param name="label">
                        <xsl:choose>
                            <xsl:when test="$results">
                                <xsl:apply-templates select="key('resources', $object-type, $results)" mode="ac:label"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$object-type"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:variable name="items" as="element()*">
                <!-- sort the existing <li> items together with the new item -->
                <xsl:perform-sort select="($existing-items, $new-item)">
                    <!-- sort by count in a hidden input first -->
                    <xsl:sort select="xs:integer(input[@name = 'count']/@value)" order="descending"/>
                    <!-- sort by the link text content (value label) -->
                    <xsl:sort select="a/text()" lang="{$ldt:lang}"/>
                </xsl:perform-sort>
            </xsl:variable>

            <xsl:for-each select="$container/ul">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:sequence select="$items"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <xsl:function name="ldh:result-count-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="count-var-name" select="$context('count-var-name')" as="xs:string"/>

        <xsl:message>ldh:result-count-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="results" select="." as="document-node()"/>
                        <xsl:for-each select="$container">
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <xsl:apply-templates select="$results" mode="bs2:ViewResultCount">
                                    <xsl:with-param name="count-var-name" select="$count-var-name" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <span class="alert">Error loading result count</span>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
        
    <!-- order by -->
    
    <xsl:function name="ldh:order-by-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="id" select="$context('id')" as="xs:string?"/>
        <xsl:variable name="predicate" select="$context('predicate')" as="xs:anyURI"/>
        <xsl:variable name="order-by-predicate" select="$context('order-by-predicate')" as="xs:anyURI?"/>

        <xsl:message>ldh:order-by-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:if test="?status = 200 and ?media-type = 'application/rdf+xml' and ?body">
                <xsl:variable name="body" select="?body" as="document-node()"/>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <xsl:apply-templates select="key('resources', $predicate, $body)" mode="bs2:OrderBy">
                            <xsl:with-param name="order-by-predicate" select="$order-by-predicate"/>
                        </xsl:apply-templates>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:if>
            <!-- ignore error response -->
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
</xsl:stylesheet>