<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
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
xmlns:lapp="&lapp;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:foaf="&foaf;"
xmlns:dct="&dct;"
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
        <!-- footer emitted below the results by ldh:RenderViewResults, the same slot bs2:Chart offers charts.
             Empty for a saved view block; the query block fills it with its Create button -->
        <xsl:param name="form-actions" as="element()?"/>

        <!-- create cache entry for the block -->
        <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`'))">
            <ixsl:set-property name="{'`' || $block/@about || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:if>

        <!-- Initialize progress counters -->
        <xsl:variable name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`')"/>
        
        <xsl:sequence select="ldh:update-progress-counter($cache, map{'container': $container}, 'init', 3)"/>

        <xsl:variable name="request-uri" select="ldh:href(ac:document-uri($query-uri), map{})" as="xs:anyURI"/>
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
            'query-uri': $query-uri,
            'form-actions': $form-actions,
            'cache': ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block/@about || '`')
          }"/>

        <xsl:sequence select="
            ldh:load-block#3(
                $context,
                ldh:view-self-thunk#1,
                ?
            )
        "/>
    </xsl:template>
    
    <!-- flatten a SPARQL.js predicate node to its candidate URIs: simple URI (json:string) returns one; alt-path (pathType '|') recurses through items; sequence/inverse/variable predicates return empty -->
    <xsl:function name="ldh:alt-path-uris" as="xs:anyURI*">
        <xsl:param name="node" as="element()"/>
        <xsl:choose>
            <xsl:when test="$node/self::json:string[not(starts-with(., '?'))]">
                <xsl:sequence select="xs:anyURI($node)"/>
            </xsl:when>
            <xsl:when test="$node/self::json:map[json:string[@key = 'type'] = 'path'][json:string[@key = 'pathType'] = '|']">
                <xsl:sequence select="for $item in $node/json:array[@key = 'items']/* return ldh:alt-path-uris($item)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

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
                ixsl:then(ldh:rethread-response($context, ?, 'view-results-response')) =>
                ixsl:then(ldh:handle-response(?, 'view-results-response')) =>
                ixsl:then(ldh:view-results-error-handler#1) =>
                ixsl:then(ldh:load-object-metadata(?, 'view-results-response')) =>
                ixsl:then(ldh:http-request-threaded(?, 'metadata-request', 'metadata-response')) =>
                ixsl:then(ldh:handle-response(?, 'metadata-response')) =>
                ixsl:then(ldh:set-object-metadata#1) =>
                ixsl:then(ldh:http-request-threaded(?, 'ns-metadata-request', 'ns-metadata-response')) =>
                ixsl:then(ldh:handle-response(?, 'ns-metadata-response')) =>
                ixsl:then(ldh:set-object-metadata-ns#1) =>
                ixsl:then(ldh:merge-object-metadata#1) =>
                ixsl:then(ldh:load-property-metadata(?, 'view-results-response')) =>
                ixsl:then(ldh:http-request-threaded(?, 'property-metadata-request', 'property-metadata-response')) =>
                ixsl:then(ldh:handle-response(?, 'property-metadata-response')) =>
                ixsl:then(ldh:set-property-metadata#1) =>
                ixsl:then(ldh:render-view#1)
        "/>
    </xsl:function>

    <!-- view-results-specific HTTP error UI: renders an alert into $container, hides the block progress bar, raises ldh:HTTPError; the generic ldh:load-object-metadata in client/block.xsl has no error UI of its own -->
    <xsl:function name="ldh:view-results-error-handler" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('view-results-response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="endpoint" select="$context('endpoint')" as="xs:anyURI"/>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:sequence select="$context"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ldh:render-block-error($container, 'block-query-failed', ldh:http-error-key($response?status), $endpoint, $response)"/>

                    <xsl:sequence select="ldh:hide-block-progress-bar($context, ())[current-date() lt xs:date('2000-01-01')]"/>

                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

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
                    <xsl:apply-templates select="key('resources', 'total-results', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
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
    
    <!-- facet predicate block: a toolbar dropdown — the pill button opens a popover of value checkboxes -->
    <xsl:template match="rdf:Description[@rdf:about]" mode="bs2:FilterIn">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'facet faceted-nav'" as="xs:string?"/>
        <xsl:param name="subject-var-name" as="xs:string"/>
        <xsl:param name="object-var-name" as="xs:string"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <button type="button" class="facet-pill nav-header" title="{@rdf:about}">
                <span>
                    <xsl:value-of>
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </xsl:value-of>
                </span>

                <span class="caret"></span>
                <input type="hidden" name="subject" value="{$subject-var-name}"/>
                <input type="hidden" name="predicate" value="{@rdf:about}"/>
                <input type="hidden" name="object" value="{$object-var-name}"/>
            </button>

            <!-- facet values will be loaded into an <ul> here -->
        </div>
    </xsl:template>
    
    <!-- result counts -->
    
    <xsl:template name="ldh:ResultCount">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="container-id" as="xs:string?"/>
        <xsl:param name="count-var-name" select="'count'" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="cache" as="item()"/>
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
        <xsl:variable name="request-uri" select="ldh:href($endpoint, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map {
            'request': $request,
            'container': .,
            'container-id': $container-id,
            'count-var-name': $count-var-name,
            'cache': $cache
          }"/>

        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:result-count-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- pager -->

    <xsl:template name="bs2:Pager">
        <xsl:param name="container-id" as="xs:string?"/>
        <xsl:param name="result-count" as="xs:integer?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="total-count" as="xs:integer?"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <xsl:variable name="limit" select="if ($select-xml/json:map/json:number[@key = 'limit']) then xs:integer($select-xml/json:map/json:number[@key = 'limit']) else 0" as="xs:integer"/>
        <xsl:variable name="show" select="$limit gt 0 and (($offset - $limit) ge 0 or $result-count ge $limit)" as="xs:boolean"/>

        <!-- do not show pagination if the children document count is less than the page limit -->
        <xsl:if test="$show">
            <div class="ldh-pager" role="navigation">
                <xsl:call-template name="bs2:PagerControls">
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="result-count" select="$result-count"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="total-count" select="$total-count"/>
                </xsl:call-template>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- the three pager zones (page-size selector · prev/status/next · page count), re-rendered by ldh:result-count-response once the COUNT total arrives -->
    <xsl:template name="bs2:PagerControls">
        <xsl:param name="container-id" as="xs:string?"/>
        <xsl:param name="result-count" as="xs:integer?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="total-count" as="xs:integer?"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <xsl:variable name="limit" select="if ($select-xml/json:map/json:number[@key = 'limit']) then xs:integer($select-xml/json:map/json:number[@key = 'limit']) else 0" as="xs:integer"/>
        <xsl:variable name="select-id" select="$container-id ! (. || '-pager-size')" as="xs:string?"/>

        <div class="ldh-pager-size">
            <label>
                <xsl:if test="$select-id">
                    <xsl:attribute name="for" select="$select-id"/>
                </xsl:if>

                <xsl:apply-templates select="key('resources', 'rows-per-page', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
            </label>
            <div class="ldh-pager-select">
                <select class="pager-size" title="{ac:label(key('resources', 'rows-per-page', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                    <xsl:if test="$select-id">
                        <xsl:attribute name="id" select="$select-id"/>
                    </xsl:if>

                    <xsl:for-each select="distinct-values(((20, 50, 100), $limit[. gt 0]))">
                        <xsl:sort select="." data-type="number"/>

                        <option value="{.}">
                            <xsl:if test=". = $limit">
                                <xsl:attribute name="selected">selected</xsl:attribute>
                            </xsl:if>

                            <xsl:value-of select="."/>
                        </option>
                    </xsl:for-each>
                </select>
                <span class="msi sm caret" aria-hidden="true">unfold_more</span>
            </div>
        </div>

        <div class="ldh-pager-nav">
            <xsl:choose>
                <xsl:when test="($offset - $limit) ge 0">
                    <a class="ldh-pager-btn pager-prev">
                        <span class="msi sm" aria-hidden="true">chevron_left</span>
                        <span>
                            <xsl:apply-templates select="key('resources', 'previous', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <span class="ldh-pager-btn is-disabled" aria-disabled="true">
                        <span class="msi sm" aria-hidden="true">chevron_left</span>
                        <span>
                            <xsl:apply-templates select="key('resources', 'previous', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </span>
                </xsl:otherwise>
            </xsl:choose>

            <span class="ldh-pager-status">
                <b>
                    <xsl:value-of select="$offset + 1"/>
                    <xsl:text>&#8211;</xsl:text>
                    <xsl:value-of select="$offset + ($result-count, 0)[1]"/>
                </b>
                <xsl:if test="exists($total-count)">
                    <span class="of">
                        <xsl:apply-templates select="key('resources', 'of', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$total-count"/>
                    </span>
                </xsl:if>
            </span>

            <!-- next stays active while the current page is full and, when the total is known, rows remain beyond it -->
            <xsl:choose>
                <xsl:when test="$result-count ge $limit and (empty($total-count) or ($offset + $limit) lt $total-count)">
                    <a class="ldh-pager-btn pager-next">
                        <span>
                            <xsl:apply-templates select="key('resources', 'next', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                        <span class="msi sm" aria-hidden="true">chevron_right</span>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <span class="ldh-pager-btn is-disabled" aria-disabled="true">
                        <span>
                            <xsl:apply-templates select="key('resources', 'next', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                        <span class="msi sm" aria-hidden="true">chevron_right</span>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
        </div>

        <xsl:if test="exists($total-count) and $limit gt 0">
            <div class="ldh-pager-page">
                <xsl:apply-templates select="key('resources', 'page', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                <xsl:text> </xsl:text>
                <b>
                    <xsl:value-of select="$offset idiv $limit + 1"/>
                </b>
                <xsl:text> / </xsl:text>
                <xsl:value-of select="max((xs:integer(ceiling($total-count div $limit)), 1))"/>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- view mode dropdown -->

    <xsl:template name="bs2:ViewModeList">
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="id" select="'view-modes'" as="xs:string?"/>
        <xsl:param name="mode-button-classes" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'&ac;ReadMode'" select="'btn-read'"/>
                <xsl:map-entry key="'&ac;ListMode'" select="'btn-list'"/>
                <xsl:map-entry key="'&ac;TableMode'" select="'btn-table'"/>
                <xsl:map-entry key="'&ac;GridMode'" select="'btn-grid'"/>
                <xsl:map-entry key="'&ac;ChartMode'" select="'btn-chart'"/>
                <xsl:map-entry key="'&ac;MapMode'" select="'btn-map'"/>
                <xsl:map-entry key="'&ac;GraphMode'" select="'btn-graph'"/>
            </xsl:map>
        </xsl:param>

        <div class="ldh-mode btn-group">
            <button type="button" title="{ac:label(key('resources', '&ac;Mode', document(ac:document-uri('&ac;'))))}">
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>

                <xsl:attribute name="class" select="'dropdown-toggle ' || (map:get($mode-button-classes, string($active-mode)), 'btn-read')[1]"/>

                <span class="msi sm" aria-hidden="true"><xsl:value-of select="(map:get($ldh:mode-icons, string($active-mode)), 'view_list')[1]"/></span>
                <span class="msi caret" aria-hidden="true">expand_more</span>
            </button>

            <div class="modes-pop view-mode-list">
                <xsl:for-each select="('&ac;ReadMode', '&ac;ListMode', '&ac;TableMode', '&ac;GridMode', '&ac;ChartMode', '&ac;MapMode', '&ac;GraphMode')">
                    <xsl:for-each select="key('resources', ., document(ac:document-uri('&ac;')))">
                        <xsl:apply-templates select="." mode="bs2:ModeListItem">
                            <xsl:with-param name="active" select="@rdf:about = $active-mode"/>
                            <xsl:with-param name="href" select="()"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:for-each>
            </div>
        </div>
    </xsl:template>

    <!-- render view -->
    
    <xsl:template name="ldh:RenderView">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" select="xs:anyURI"/>
        <xsl:param name="initial-var-name" as="xs:string"/>
        <xsl:param name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="cache" as="item()"/>
        <!-- carried into the returned context so it survives to ldh:RenderViewResults. Only the initial load
             emits it, so the re-render call sites (paging, sort, facets) leave it empty and lose nothing -->
        <xsl:param name="form-actions" as="element()?"/>

        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href($endpoint, map{})" as="xs:anyURI"/>
        <xsl:variable name="headers" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'Accept'" select="'application/rdf+xml'"/>

                <xsl:if test="$refresh-content">
                    <xsl:map-entry key="'Cache-Control'" select="'no-cache, no-store, must-revalidate'"/>
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': $headers }" as="map(*)"/>
        <xsl:sequence select="
          map{
            'request': $request,
            'container': $container,
            'container-id': generate-id($container),
            'active-mode': $active-mode,
            'select-string': $select-string,
            'select-xml': $select-xml,
            'initial-var-name': $initial-var-name,
            'focus-var-name': $focus-var-name,
            'endpoint': $endpoint,
            'form-actions': $form-actions,
            'cache': $cache
          }"/>
    </xsl:template>

    <xsl:template name="ldh:ViewPage">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="direction" as="xs:string"/> <!-- 'previous' or 'next' -->

        <!-- step by the query's own LIMIT so paging stays aligned after the page size is changed -->
        <xsl:variable name="limit" select="if ($select-xml/json:map/json:number[@key = 'limit']) then xs:integer($select-xml/json:map/json:number[@key = 'limit']) else $page-size" as="xs:integer"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <xsl:variable name="offset" select="if ($direction = 'previous') then $offset - $limit else $offset + $limit" as="xs:integer"/>

        <xsl:document>
            <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                <xsl:with-param name="offset" select="$offset" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:template>

    <xsl:template name="ldh:ViewLimit">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="limit" as="xs:integer"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit">
                    <xsl:with-param name="limit" select="$limit" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- a new page size restarts paging from the first page (no tunneled $offset removes OFFSET) -->
        <xsl:document>
            <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset"/>
        </xsl:document>
    </xsl:template>

    <xsl:template name="ldh:ViewOrder">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="var-name" as="xs:string?"/>

        <xsl:document>
            <xsl:apply-templates select="$select-xml" mode="ldh:replace-order-by">
                <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:template>

    <xsl:template name="ldh:ViewOrderDirection">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="desc" as="xs:boolean"/>

        <xsl:document>
            <xsl:apply-templates select="$select-xml" mode="ldh:toggle-desc">
                <xsl:with-param name="desc" select="not($desc)" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:template>

    <xsl:template name="ldh:ViewFilter">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="var-name" as="xs:string"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:filter-in">
                    <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                    <xsl:with-param name="values" select="$values" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- a changed filter changes the result set, so paging restarts from the first page (no tunneled $offset removes OFFSET) -->
        <xsl:document>
            <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset"/>
        </xsl:document>
    </xsl:template>

    <xsl:template name="ldh:ViewParallax">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <!-- an inverse step pivots onto the subjects pointing at the current results, rather than onto their objects -->
        <xsl:param name="inverse" select="false()" as="xs:boolean"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="ldh:add-parallax-step">
                    <xsl:with-param name="predicate" select="$predicate" tunnel="yes"/>
                    <xsl:with-param name="inverse" select="$inverse" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <!-- a parallax step changes the result set, so paging restarts from the first page (no tunneled $offset removes OFFSET) -->
        <xsl:document>
            <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset"/>
        </xsl:document>
    </xsl:template>

    <!-- $container here is the inner result container, not the content container! -->
    <xsl:template name="ldh:RenderViewMode">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="var-predicates" as="map(xs:string, xs:anyURI*)?"/>
        <xsl:param name="order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
        <xsl:param name="order-by-desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
        <xsl:param name="cache" as="item()"/>

        <!-- Skip ViewModeChoice replace-content for GraphMode: its canvas lives in the persistent graph-host (sibling of $container), not in container-results, so re-rendering this area would only churn unused DOM. -->
        <xsl:if test="not($active-mode = '&ac;GraphMode')">
            <!-- total cached by ldh:result-count-response (or the exact-count short-circuit); empty until the first COUNT response arrives -->
            <xsl:variable name="total-count" select="if (ixsl:contains($cache, 'result-count')) then xs:integer(ixsl:get($cache, 'result-count')) else ()" as="xs:integer?"/>

            <xsl:for-each select="$container">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:call-template name="ldh:ViewModeChoice">
                        <xsl:with-param name="container-id" select="$container-id"/>
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="endpoint" select="$endpoint"/>
                        <xsl:with-param name="results" select="$results"/>
                        <xsl:with-param name="active-mode" select="$active-mode"/>
                        <xsl:with-param name="object-metadata" select="$object-metadata"/>
                        <xsl:with-param name="total-count" select="$total-count"/>
                        <xsl:with-param name="var-predicates" select="$var-predicates"/>
                        <xsl:with-param name="order-by-var-name" select="$order-by-var-name"/>
                        <xsl:with-param name="order-by-desc" select="$order-by-desc"/>
                    </xsl:call-template>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>

        <!-- toggle visibility between persistent graph-host (GraphMode) and ephemeral container-results (everything else) -->
        <xsl:variable name="graph-host" select="id($container-id || '-graph-host', ixsl:page())" as="element()?"/>
        <xsl:if test="exists($graph-host)">
            <xsl:choose>
                <xsl:when test="$active-mode = '&ac;GraphMode'">
                    <ixsl:set-style name="display" select="'none'" object="$container"/>
                    <ixsl:set-style name="display" select="'block'" object="$graph-host"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-style name="display" select="'block'" object="$container"/>
                    <ixsl:set-style name="display" select="'none'" object="$graph-host"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

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

            <xsl:sequence select="ldh:busy-cursor()"/>

            <xsl:variable name="canvas-id" select="$container-id || '-map-canvas'" as="xs:string"/>
            <xsl:variable name="initial-load" select="not(ixsl:contains($cache, 'map'))" as="xs:boolean"/>
            <xsl:variable name="map" select="if ($initial-load) then ldh:create-map($canvas-id, 0, 0, 4) else ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), 'map')" as="item()"/>  <!-- OpenLayers map object -->

            <xsl:if test="not($initial-load)">
                <ixsl:set-property name="map" select="$map" object="$cache"/>
            </xsl:if>
                        
            <!-- dettach the old canvas element (since it's destroyed and regenerated during AJAX page load) -->
            <xsl:sequence select="ixsl:call($map, 'setTarget', [ () ])[current-date() lt xs:date('2000-01-01')]"/>
            <!-- attach the new canvas element -->
            <xsl:sequence select="ixsl:call($map, 'setTarget', [ $canvas-id ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call($map, 'updateSize', [])[current-date() lt xs:date('2000-01-01')]"/>

            <xsl:call-template name="ldh:LoadGeoResources">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="container-id" select="$container-id"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="map" select="$map"/>
                <xsl:with-param name="initial-load" select="$initial-load"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$active-mode = '&ac;ChartMode'">
            <xsl:variable name="canvas-id" select="$container-id || '-chart-canvas'" as="xs:string"/>
            <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
            <xsl:variable name="category" as="xs:string?"/>
            <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
            <xsl:variable name="data-table" select="ac:rdf-data-table($results, $category, $series)"/>

            <ixsl:set-property name="data-table" select="$data-table" object="$cache"/>

            <xsl:call-template name="ldh:RenderChart">
                <xsl:with-param name="data-table" select="$data-table"/>
                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
        <!-- GraphMode: the persistent canvas lives in graph-host (visible since the toggle above). Lazily emit the canvas div + init ForceGraph3D on first activation; subsequent re-renders just feed new $results via redisplay-graph. -->
        <xsl:if test="$active-mode = '&ac;GraphMode'">
            <xsl:variable name="canvas-id" select="$container-id || '-graph-canvas'" as="xs:string"/>
            <xsl:variable name="graph-host" select="id($container-id || '-graph-host', ixsl:page())" as="element()"/>
            <xsl:variable name="graphs" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graphs')"/>
            <xsl:variable name="needs-init" select="not(ixsl:contains($graphs, $canvas-id))" as="xs:boolean"/>

            <xsl:if test="$needs-init">
                <xsl:for-each select="$graph-host">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div id="{$canvas-id}" class="graph-3d-canvas"/>
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:variable name="canvas" select="id($canvas-id, ixsl:page())" as="element()"/>
                <xsl:variable name="graph-state" as="item()">
                    <xsl:call-template name="ldh:ForceGraph3D-init">
                        <xsl:with-param name="graph-id" select="$canvas-id"/>
                        <xsl:with-param name="container" select="$canvas"/>
                        <xsl:with-param name="builder" select="ixsl:apply(ixsl:get(ixsl:window(), 'ForceGraph3D'), [])"/>
                        <xsl:with-param name="graph-width" select="xs:double(ixsl:get($graph-host, 'offsetWidth'))"/>
                        <xsl:with-param name="graph-height" select="xs:double(600)"/>
                        <xsl:with-param name="node-rel-size" select="xs:double(4)"/>
                        <xsl:with-param name="link-width" select="xs:double(1.5)"/>
                        <xsl:with-param name="node-label-color" select="'white'"/>
                        <xsl:with-param name="node-label-text-height" select="xs:double(5)"/>
                        <xsl:with-param name="node-label-position-y" select="xs:double(10)"/>
                        <xsl:with-param name="link-label-color" select="'lightgrey'"/>
                        <xsl:with-param name="link-label-text-height" select="xs:double(4)"/>
                        <xsl:with-param name="link-force-distance" select="xs:double(100)"/>
                        <xsl:with-param name="charge-force-strength" select="xs:double(-200)"/>
                        <xsl:with-param name="node-click-event-name" select="'ForceGraph3DNodeClick'"/>
                        <xsl:with-param name="node-dblclick-event-name" select="'ForceGraph3DNodeDblClick'"/>
                        <xsl:with-param name="node-rightclick-event-name" select="'ForceGraph3DNodeRightClick'"/>
                        <xsl:with-param name="node-hover-on-event-name" select="'ForceGraph3DNodeHoverOn'"/>
                        <xsl:with-param name="node-hover-off-event-name" select="'ForceGraph3DNodeHoverOff'"/>
                        <xsl:with-param name="link-click-event-name" select="'ForceGraph3DLinkClick'"/>
                        <xsl:with-param name="background-click-event-name" select="'ForceGraph3DBackgroundClick'"/>
                    </xsl:call-template>
                </xsl:variable>
                <ixsl:set-property name="document" select="$results" object="$graph-state"/>
                <ixsl:set-property name="loaded-uris" select="ixsl:new('Array', [])" object="$graph-state"/>
                <ixsl:set-property name="loaded-backlink-uris" select="ixsl:new('Array', [])" object="$graph-state"/>
                <ixsl:set-property name="{$canvas-id}" select="$graph-state" object="$graphs"/>

                <xsl:call-template name="ldh:AppendGraph3DPanels">
                    <xsl:with-param name="canvas" select="$canvas"/>
                    <xsl:with-param name="canvas-id" select="$canvas-id"/>
                </xsl:call-template>
            </xsl:if>

            <xsl:variable name="graph-state" select="ixsl:get($graphs, $canvas-id)"/>
            <xsl:if test="not($needs-init)">
                <ixsl:set-property name="document" select="$results" object="$graph-state"/>
            </xsl:if>
            <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>
            <xsl:call-template name="ldh:redisplay-graph">
                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                <xsl:with-param name="graph-state" select="$graph-state"/>
                <xsl:with-param name="graph-instance" select="$graph-instance"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- view mode choice -->
    
    <xsl:template name="ldh:ViewModeChoice">
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="total-count" as="xs:integer?"/>
        <xsl:param name="var-predicates" as="map(xs:string, xs:anyURI*)?"/>
        <xsl:param name="order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
        <xsl:param name="order-by-desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending']" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="$active-mode = '&ac;ListMode'">
                <xsl:apply-templates select="$results" mode="bs2:ContainerBlockList">
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="total-count" select="$total-count"/>
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;TableMode'">
                <xsl:apply-templates select="$results" mode="bs2:ContainerTable">
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="total-count" select="$total-count"/>
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                    <xsl:with-param name="var-predicates" select="$var-predicates" tunnel="yes"/>
                    <xsl:with-param name="order-by-var-name" select="$order-by-var-name" tunnel="yes"/>
                    <xsl:with-param name="order-by-desc" select="$order-by-desc" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;GridMode'">
                <xsl:apply-templates select="$results" mode="bs2:ContainerGrid">
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="total-count" select="$total-count"/>
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;ChartMode'">
                <xsl:apply-templates select="$results" mode="bs2:Chart">
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="canvas-id" select="$container-id || '-chart-canvas'"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;MapMode'">
                <xsl:apply-templates select="$results" mode="bs2:Map">
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="id" select="$container-id || '-map-canvas'"/>
                    <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$active-mode = '&ac;GraphMode'">
                <xsl:apply-templates select="$results" mode="bs2:Graph">
                    <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                    <xsl:with-param name="canvas-id" select="$container-id || '-graph-canvas'"/>
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
        <xsl:param name="container" as="element()"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="var-predicates" as="map(xs:string, xs:anyURI*)"/>
        <xsl:param name="desc" as="xs:boolean?"/>
        <xsl:param name="order-by-var-name" as="xs:string?"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="result-count-container-id" as="xs:string"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:param name="cache" as="item()"/>
        <xsl:param name="form-actions" as="element()?"/>
        <!-- if  the container is full-width row (.row-fluid), render results in the middle column (.main) -->
        <xsl:variable name="order-by-container-id" select="$container-id || '-container-order'" as="xs:string"/>
        <xsl:variable name="container-results-id" select="$container-id || '-container-results'" as="xs:string"/>

        <!-- store sorted results as the current view results -->
        <ixsl:set-property name="results" select="$results" object="$cache"/>

        <xsl:variable name="initial-load" select="empty(.//div[@id = $container-results-id])" as="xs:boolean"/>
        <xsl:message>$initial-load: <xsl:value-of select="$initial-load"/></xsl:message>
        <!-- first time rendering the view results -->
        <xsl:if test="$initial-load">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:where-populated>
                    <h2>
                        <!-- select the value text() only: a lang-tagged dct:title renders as <dd> with a leading language-badge <span> (xhtml:DefinitionDescription), and value-of over the whole element would prepend the badge (e.g. "enCurrent members"). [1] guards against multiple language values. -->
                        <xsl:value-of select="($container/descendant::*[@property = '&dct;title']/text())[1]"/>
                    </h2>
                </xsl:where-populated>

                <div class="ldh-view-toolbar">
                    <div class="left">
                        <span class="facet-lead">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'filter-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">filter_alt</span>
                        </span>
                        <!-- applied parallax steps render here as removable chips (ldh:RenderParallaxSteps) -->
                        <span class="parallax-steps"></span>
                        <!-- facet pills are appended here by ldh:RenderFacets -->
                    </div>
                    <div class="right">
                        <!-- inline creation: Create button for views carrying ldh:container metadata (stamped as data-* attributes by ldh:ontology-view-insert, RDFa as fallback for hand-authored view blocks). PUT into the container requires acl:Write there (checked on the parent URI for new documents); forward views additionally PATCH the linking triple into the current document, hence acl:Write here too -->
                        <xsl:variable name="view-block" select="$container/ancestor::div[contains-token(@class, 'block')][1]" as="element()?"/>
                        <xsl:variable name="create-container" select="($view-block/@data-container, $container/descendant::*[@property = '&ldh;container']/@resource)[1]" as="xs:string?"/>
                        <xsl:variable name="create-for-class" select="$view-block/@data-for-class" as="xs:string?"/>
                        <xsl:if test="exists($create-container) and exists($create-for-class) and tokenize($view-block/@data-acl-modes, ' ') = '&acl;Write' and (exists($view-block/@data-inverse) or acl:mode() = '&acl;Write')">
                            <button type="button" class="ldhc-btn in-primary ap-solid sz-sm add-instance" data-for-class="{$create-for-class}" data-container="{$create-container}" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                        </xsl:if>

                        <p id="{$result-count-container-id}" class="result-count count"/>

                        <!-- no sortable variables means an empty order-by dropdown, so the sort controls stay out of the toolbar altogether -->
                        <xsl:if test="map:size($var-predicates) gt 0">
                            <form class="form-inline">
                                <label for="{$order-by-container-id}">
                                    <!-- currently no space for the label in the layout -->
                                    <!--<xsl:text>Order by </xsl:text>-->

                                    <select id="{$order-by-container-id}" name="order-by" class="container-order">
                                        <!-- show the default option if the container query does not have an ORDER BY -->
                                        <xsl:if test="not($select-xml/json:map/json:array[@key = 'order'])">
                                            <option>
                                                <xsl:value-of>
                                                    <xsl:text>[</xsl:text>
                                                    <xsl:apply-templates select="key('resources', 'none', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                    <xsl:text>]</xsl:text>
                                                </xsl:value-of>
                                            </option>
                                        </xsl:if>
                                        <!-- emit all order-by options synchronously: a single-predicate var takes its label from the /ns property-metadata (falling back to the predicate's local name), an alt-path-bound var uses the var name (no single canonical predicate URI) -->
                                        <xsl:for-each select="map:keys($var-predicates)">
                                            <xsl:sort select="."/>
                                            <xsl:variable name="var-name" select="." as="xs:string"/>
                                            <xsl:variable name="predicates" select="$var-predicates(.)" as="xs:anyURI*"/>
                                            <option value="{$var-name}">
                                                <xsl:if test="$var-name = $order-by-var-name">
                                                    <xsl:attribute name="selected">selected</xsl:attribute>
                                                </xsl:if>
                                                <xsl:choose>
                                                    <xsl:when test="count($predicates) eq 1">
                                                        <xsl:variable name="predicate" select="$predicates[1]" as="xs:anyURI"/>
                                                        <xsl:variable name="predicate-desc" select="$property-metadata!key('resources', $predicate, .)" as="element()?"/>
                                                        <xsl:choose>
                                                            <xsl:when test="exists($predicate-desc)">
                                                                <xsl:apply-templates select="$predicate-desc" mode="ac:label"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="tokenize($predicate, '[/#]')[last()]"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="$var-name"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </option>
                                        </xsl:for-each>
                                    </select>

                                    <!-- both direction labels are baked in and an empty arrow span mirrors the column headers; the CSR handlers only flip btn-order-by-desc, so CSS keyed on that class picks the visible label and the ::before glyph -->
                                    <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm btn-order-by{if ($desc) then ' btn-order-by-desc' else ()}">
                                        <span class="dir-asc">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'ascending', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </span>
                                        <span class="dir-desc">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'descending', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </span>
                                        <span class="msi sm sort-arrow" aria-hidden="true"></span>
                                    </button>
                                </label>
                            </form>
                        </xsl:if>

                        <xsl:call-template name="bs2:ViewModeList">
                            <xsl:with-param name="active-mode" select="$active-mode"/>
                        </xsl:call-template>

                        <xsl:apply-templates select="." mode="ldh:BlockLinksPopover"/>

                        <xsl:apply-templates select="." mode="ldh:CopyUriButton"/>
                    </div>
                </div>

                <!-- parallax row: the second row of the view's control header. Query inputs (filters, sort, modes) stay in the toolbar above; onward pivots derived from the current result set land here, filled by bs2:ParallaxNav after every results render. Hidden by CSS while it has no chips. -->
                <div class="parallax-nav">
                    <span class="plabel">
                        <!-- the chips carry their own direction arrows, so the row's own glyph stays neutral -->
                        <span class="msi sm" aria-hidden="true">alt_route</span>
                        <span class="ldhc-vh">
                            <xsl:apply-templates select="key('resources', 'related-results', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </span>

                    <div id="{$container-id}-parallax-properties" class="pchips"></div>
                </div>

                <div>
                    <!-- persistent host for the 3d-force-graph canvas; lives for the lifetime of this view block so the WebGL context + simulation state survive re-renders. Hidden when active-mode is not GraphMode. -->
                    <div id="{$container-id}-graph-host" class="graph-3d-host" style="display: none;"></div>
                    <div id="{$container-results-id}" class="container-results"></div>
                </div>

                <!-- outside .container-results on purpose: ldh:RenderViewMode replaces that div's content on
                     every mode, facet, sort and page change, which would take the footer with it -->
                <xsl:sequence select="$form-actions"/>
            </xsl:result-document>
        </xsl:if>

        <!-- result count: stays in sync with re-queried results (e.g. modal search keyword changes). Short-circuit the COUNT HTTP request when the entire result set fits in one page — typical for narrowed search queries. -->
        <xsl:variable name="limit" select="if ($select-xml/json:map/json:number[@key = 'limit']) then xs:integer($select-xml/json:map/json:number[@key = 'limit']) else 0" as="xs:integer"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <xsl:variable name="exact-count" select="count($results/rdf:RDF/rdf:Description)" as="xs:integer"/>

        <!-- ldh:showWhenEmpty (default true): when false, hide the whole injected view block while the query returns no results and un-hide it when results appear on a later refresh. Only evaluated on the first page: at offset 0 an empty page means an empty result set, while a non-zero offset implies interaction with a visible block -->
        <xsl:if test="$offset = 0">
            <xsl:variable name="view-block" select="$container/ancestor::div[contains-token(@class, 'block')][1]" as="element()?"/>
            <xsl:variable name="show-when-empty" select="not(($view-block/@data-show-when-empty, $container/descendant::*[@property = '&ldh;showWhenEmpty']/text())[1] = ('false', '0'))" as="xs:boolean"/>
            <xsl:if test="not($show-when-empty)">
                <xsl:for-each select="$view-block">
                    <ixsl:set-style name="display" select="if ($exact-count = 0) then 'none' else ''" object="."/>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="$offset = 0 and ($limit = 0 or $exact-count lt $limit)">
                <!-- the whole result set fits on one page, so its size is the total -->
                <ixsl:set-property name="result-count" select="$exact-count" object="$cache"/>

                <xsl:for-each select="id($result-count-container-id, ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <strong>
                            <xsl:apply-templates select="key('resources', 'total-results', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            <xsl:text> </xsl:text>
                            <span class="badge badge-inverse"><xsl:value-of select="$exact-count"/></span>
                        </strong>
                    </xsl:result-document>
                </xsl:for-each>
                <xsl:sequence select="ldh:update-progress-counter($cache, map{ 'container': $container }, 'complete', ())"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="id($result-count-container-id, ixsl:page())">
                    <xsl:call-template name="ldh:ResultCount">
                        <xsl:with-param name="container-id" select="$container-id"/>
                        <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                        <xsl:with-param name="endpoint" select="$endpoint"/>
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="cache" select="$cache"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="ldh:RenderViewMode">
            <xsl:with-param name="container" select=".//div[contains-token(@class, 'container-results')]"/>
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="endpoint" select="$endpoint"/>
            <xsl:with-param name="results" select="$results"/>
            <xsl:with-param name="object-metadata" select="$object-metadata"/>
            <xsl:with-param name="active-mode" select="$active-mode"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="var-predicates" select="$var-predicates"/>
            <xsl:with-param name="order-by-var-name" select="$order-by-var-name"/>
            <xsl:with-param name="order-by-desc" select="$desc"/>
            <xsl:with-param name="cache" select="$cache"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- facets -->

    <xsl:template name="ldh:RenderFacets">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="sub-container-id" as="xs:string"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <!-- use the first SELECT variable as the facet variable name (so that we do not generate facets based on other variables) -->
        <xsl:variable name="initial-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        
        <!-- use the BGPs where the predicate is a URI value and the subject and object are variables -->
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $initial-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>

        <!-- only append facets if they are not already present and there are BGP triples to facet on -->
        <xsl:if test="not(id($sub-container-id, ixsl:page())) and exists($bgp-triples-map)">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:apply-templates select="." mode="ldh:RenderFacets">
                    <xsl:with-param name="id" select="$sub-container-id"/>
                    <xsl:with-param name="class" select="'facets'"/>
                </xsl:apply-templates>
            </xsl:result-document>

            <xsl:variable name="sub-container" select="id($sub-container-id, ixsl:page())" as="element()"/>

            <xsl:for-each select="$bgp-triples-map">
                <!-- only simple properties in the BGP are supported, not property paths etc. -->
                <xsl:if test="json:string[@key = 'predicate']">
                    <xsl:variable name="id" select="generate-id()" as="xs:string"/>
                    <xsl:variable name="subject-var-name" select="json:string[@key = 'subject']/substring-after(., '?')" as="xs:string"/>
                    <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:anyURI"/>
                    <xsl:variable name="object-var-name" select="json:string[@key = 'object']/substring-after(., '?')" as="xs:string"/>
                    <!-- render the facet header synchronously from the /ns property-metadata; fall back to the predicate's local name when it is not in the closure -->
                    <xsl:variable name="predicate-desc" as="element()">
                        <xsl:variable name="ns-desc" select="$property-metadata!key('resources', $predicate, .)" as="element()?"/>
                        <xsl:choose>
                            <xsl:when test="exists($ns-desc)">
                                <xsl:sequence select="$ns-desc"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <rdf:Description rdf:about="{$predicate}">
                                    <rdfs:label><xsl:value-of select="tokenize($predicate, '[/#]')[last()]"/></rdfs:label>
                                </rdf:Description>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:for-each select="$sub-container">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <xsl:apply-templates select="$predicate-desc" mode="bs2:FilterIn">
                                <xsl:with-param name="subject-var-name" select="$subject-var-name"/>
                                <xsl:with-param name="object-var-name" select="$object-var-name"/>
                            </xsl:apply-templates>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="ldh:RenderFacets">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="()" as="xs:string?"/>
                
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- block list -->

    <xsl:template match="rdf:RDF" mode="bs2:ContainerBlockList" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="container-id" as="xs:string?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="total-count" as="xs:integer?"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <div class="ldh-list-block">
            <xsl:apply-templates select="." mode="bs2:List"/>
        </div>

        <xsl:call-template name="bs2:Pager">
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="total-count" select="$total-count"/>
        </xsl:call-template>
    </xsl:template>

    <!-- hide resources that will be shown paired/nested with a document -->
    <xsl:template match="*[key('resources-by-primary-topic', @rdf:about)]" mode="bs2:List" priority="1"/>

    <!-- a document paired with its primary topic renders as one row carrying the topic's label, description and type -->
    <xsl:template match="*[*][@rdf:about]" mode="bs2:List" priority="0.8">
        <xsl:variable name="subject" select="(key('resources', foaf:primaryTopic/@rdf:resource), .)[1]" as="element()"/>

        <a class="row" href="{ldh:href(ac:document-uri(xs:anyURI(@rdf:about)), map{})}" title="{@rdf:about}">
            <span class="ic">
                <span class="msi sm" aria-hidden="true">
                    <xsl:value-of select="(rdf:type/@rdf:resource ! map:get($ldh:class-icons, string(.)), 'description')[1]"/>
                </span>
            </span>
            <span class="ti">
                <xsl:apply-templates select="$subject" mode="ac:label"/>

                <xsl:where-populated>
                    <span class="desc">
                        <xsl:apply-templates select="$subject" mode="ac:description"/>
                    </span>
                </xsl:where-populated>
            </span>

            <xsl:apply-templates select="." mode="ldh:ListRowTimestamp"/>
            <xsl:apply-templates select="$subject" mode="ldh:ListRowType"/>
        </a>
    </xsl:template>

    <xsl:template match="*[*][@rdf:nodeID]" mode="bs2:List" priority="0.8">
        <div class="row">
            <span class="ic">
                <span class="msi sm" aria-hidden="true">
                    <xsl:value-of select="(rdf:type/@rdf:resource ! map:get($ldh:class-icons, string(.)), 'description')[1]"/>
                </span>
            </span>
            <span class="ti">
                <xsl:apply-templates select="." mode="ac:label"/>

                <xsl:where-populated>
                    <span class="desc">
                        <xsl:apply-templates select="." mode="ac:description"/>
                    </span>
                </xsl:where-populated>
            </span>

            <xsl:apply-templates select="." mode="ldh:ListRowTimestamp"/>
            <xsl:apply-templates select="." mode="ldh:ListRowType"/>
        </div>
    </xsl:template>

    <!-- .ts cell: the latest of dct:created/dct:modified as a short date -->
    <xsl:template match="*" mode="ldh:ListRowTimestamp">
        <xsl:variable name="sorted-date-time-properties" as="element()*">
            <xsl:perform-sort select="(dct:created, dct:modified)[exists(ldh:date-time(string(.)))]">
                <xsl:sort select="ldh:date-time(string(.))" order="ascending"/>
            </xsl:perform-sort>
        </xsl:variable>

        <xsl:for-each select="$sorted-date-time-properties[last()]">
            <span class="ts">
                <xsl:value-of select="format-date(xs:date(ldh:date-time(string(.))), '[D] [MNn] [Y]', ac:langs()[1], (), ())"/>
            </span>
        </xsl:for-each>
    </xsl:template>

    <!-- .type cell: the first type by label -->
    <xsl:template match="*" mode="ldh:ListRowType">
        <xsl:for-each select="rdf:type/@rdf:resource">
            <xsl:sort select="ac:object-label(.)" order="ascending" lang="{ac:langs()[1]}"/>

            <xsl:if test="position() = 1">
                <span class="type">
                    <xsl:value-of select="ac:object-label(.)"/>
                </span>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- grid -->

    <!-- override Web-Client's template to avoid sort by ac:label(); the design-system grid lays items out itself, so no row chunking -->
    <xsl:template match="rdf:RDF" mode="bs2:Grid">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>

    <!-- hide resources that will be shown paired/nested with a document -->
    <xsl:template match="*[key('resources-by-primary-topic', @rdf:about)]" mode="bs2:Grid" priority="1"/>

    <!-- a document paired with its primary topic renders as one card carrying the topic's label and description -->
    <xsl:template match="*[*][@rdf:about]" mode="bs2:Grid" priority="0.8">
        <xsl:variable name="subject" select="(key('resources', foaf:primaryTopic/@rdf:resource), .)[1]" as="element()"/>
        <xsl:variable name="pos" select="position()" as="xs:integer"/>

        <a class="card" href="{ldh:href(ac:document-uri(xs:anyURI(@rdf:about)), map{})}" title="{@rdf:about}">
            <xsl:choose>
                <xsl:when test="ac:image($subject)">
                    <div class="img">
                        <img src="{ac:image($subject)[1]}" alt="{ac:label($subject)}"/>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div class="img {('img-sky', 'img-mint', 'img-peach', 'img-lavender', 'img-blush', 'img-sand')[($pos - 1) mod 6 + 1]}">
                        <span class="msi" aria-hidden="true">
                            <xsl:value-of select="(rdf:type/@rdf:resource ! map:get($ldh:class-icons, string(.)), 'description')[1]"/>
                        </span>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
            <div class="card-body">
                <span class="ti">
                    <xsl:apply-templates select="$subject" mode="ac:label"/>
                </span>

                <xsl:where-populated>
                    <span class="meta">
                        <xsl:apply-templates select="$subject" mode="ac:description"/>
                    </span>
                </xsl:where-populated>
            </div>
        </a>
    </xsl:template>

    <xsl:template match="*[*][@rdf:nodeID]" mode="bs2:Grid" priority="0.8">
        <xsl:variable name="pos" select="position()" as="xs:integer"/>

        <div class="card">
            <xsl:choose>
                <xsl:when test="ac:image(.)">
                    <div class="img">
                        <img src="{ac:image(.)[1]}" alt="{ac:label(.)}"/>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div class="img {('img-sky', 'img-mint', 'img-peach', 'img-lavender', 'img-blush', 'img-sand')[($pos - 1) mod 6 + 1]}">
                        <span class="msi" aria-hidden="true">
                            <xsl:value-of select="(rdf:type/@rdf:resource ! map:get($ldh:class-icons, string(.)), 'description')[1]"/>
                        </span>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
            <div class="card-body">
                <span class="ti">
                    <xsl:apply-templates select="." mode="ac:label"/>
                </span>

                <xsl:where-populated>
                    <span class="meta">
                        <xsl:apply-templates select="." mode="ac:description"/>
                    </span>
                </xsl:where-populated>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="bs2:ContainerGrid" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="container-id" as="xs:string?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="total-count" as="xs:integer?"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <div class="ldh-grid-block">
            <xsl:apply-templates select="." mode="bs2:Grid"/>
        </div>

        <xsl:call-template name="bs2:Pager">
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="total-count" select="$total-count"/>
        </xsl:call-template>
    </xsl:template>

    <!-- table -->

    <xsl:template match="rdf:RDF" mode="bs2:ContainerTable" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="container-id" as="xs:string?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="total-count" as="xs:integer?"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:apply-templates select="." mode="xhtml:Table"/>

        <xsl:call-template name="bs2:Pager">
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="total-count" select="$total-count"/>
        </xsl:call-template>
    </xsl:template>

    <!-- hide documents that are paired with resources -->
    <xsl:template match="*[key('resources', foaf:primaryTopic/@rdf:resource)]" mode="xhtml:Table"/>

    <!-- sortable column header: in view tables the column's predicate reverse-maps to a SELECT variable via $var-predicates, so the th carries the var name for the onclick sort. Columns outside the query's BGP (and non-view tables, where no $var-predicates is tunneled) fall through to the plain th -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="xhtml:TableHeaderCell">
        <xsl:param name="var-predicates" as="map(xs:string, xs:anyURI*)?" tunnel="yes"/>
        <xsl:param name="order-by-var-name" as="xs:string?" tunnel="yes"/>
        <xsl:param name="order-by-desc" as="xs:boolean?" tunnel="yes"/>
        <xsl:variable name="predicate" select="concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="var-name" select="if (exists($var-predicates)) then sort(map:keys($var-predicates))[$predicate = $var-predicates(.)][1] else ()" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="exists($var-name)">
                <th class="sortable" data-var-name="{$var-name}">
                    <xsl:if test="$var-name = $order-by-var-name">
                        <xsl:attribute name="aria-sort" select="if ($order-by-desc) then 'descending' else 'ascending'"/>
                    </xsl:if>

                    <xsl:apply-templates select="."/>
                    <span class="msi sm sort-arrow" aria-hidden="true">
                        <xsl:value-of select="if ($var-name = $order-by-var-name and $order-by-desc) then 'arrow_downward' else 'arrow_upward'"/>
                    </span>
                </th>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- graph -->

    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <xsl:param name="canvas-id" as="xs:string"/>

        <div id="{$canvas-id}" class="graph-3d-canvas"/>
    </xsl:template>
    
    <!-- parallax -->
    
    <!-- Loads the chips for the parallax row: the predicates linking the result set to the rest of
         the graph, both outgoing and incoming. Discovery asks the endpoint over the whole result
         set (LIMIT/OFFSET/ORDER stripped off the subquery) rather than reading the loaded page, so
         properties held only by resources on other pages are found too, and objects that are dead
         ends - never subjects themselves - are excluded by the query. -->
    <xsl:template name="bs2:ParallaxNav">
        <xsl:param name="properties-container-id" as="xs:string"/>
        <xsl:param name="empty-results" as="xs:boolean"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:param name="cache" as="item()"/>

        <!-- the chips container is emitted with the parallax row by ldh:RenderViewResults' initial markup -->
        <xsl:for-each select="id($properties-container-id, ixsl:page())">
            <!-- a SELECT * view has no named focus variable to pivot on -->
            <xsl:if test="not($empty-results) and $focus-var-name != ''">
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
                <!-- an ordered subquery has to be materialized in full and defeats the outer LIMIT -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:strip-order-by"/>
                    </xsl:document>
                </xsl:variable>
                <!-- deduplicate the focus resources before the property fan-out, unless the query aggregates (re-projecting a GROUP BY query onto a non-grouping variable is invalid SPARQL) -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:choose>
                        <xsl:when test="$select-xml/json:map/json:array[@key = 'group'] or $select-xml/json:map/json:array[@key = 'variables']/json:map">
                            <xsl:sequence select="$select-xml"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:document>
                                <xsl:apply-templates select="$select-xml" mode="ldh:replace-variables">
                                    <xsl:with-param name="var-names" select="$focus-var-name" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:document>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- paging, sorting and mode switches re-render the view without changing the result set - only re-discover when the stripped query actually differs -->
                <xsl:variable name="parallax-key" select="serialize($select-xml)" as="xs:string"/>
                <xsl:if test="not(ixsl:contains($cache, 'parallax-key') and ixsl:get($cache, 'parallax-key') = $parallax-key)">
                    <ixsl:set-property name="parallax-key" select="$parallax-key" object="$cache"/>

                    <!-- clear chips from the previous result set -->
                    <xsl:result-document href="?." method="ixsl:replace-content"/>

                    <xsl:variable name="uuid" select="ac:uuid()" as="xs:string"/>
                    <xsl:variable name="query-xml" as="document-node()">
                        <xsl:document>
                            <xsl:apply-templates select="$select-xml" mode="ldh:link-predicates">
                                <xsl:with-param name="uuid" select="$uuid" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:document>
                    </xsl:variable>
                    <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
                    <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
                    <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ldh:href($endpoint, map{})" as="xs:anyURI"/>
                    <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
                    <xsl:variable name="context" as="map(*)" select="
                      map{
                        'request': $request,
                        'container': .,
                        'predicate-var-name': 'predicate' || translate($uuid, '-', '_'),
                        'inverse-var-name': 'inverse' || translate($uuid, '-', '_'),
                        'property-metadata': $property-metadata
                      }"/>
                    <ixsl:promise select="ixsl:http-request($context('request')) =>
                        ixsl:then(ldh:rethread-response($context, ?)) =>
                        ixsl:then(ldh:handle-response#1) =>
                        ixsl:then(ldh:parallax-response#1)"
                        on-failure="ldh:promise-failure#1"/>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- resolves the view's client-side cache entry: block-hosted views are keyed by the host block's @about, modal-hosted views (geo/latest/search/class instances) by the container's @id -->
    <xsl:function name="ldh:view-cache" as="item()">
        <xsl:param name="container" as="element()"/>

        <xsl:variable name="key" select="($container/ancestor::div[@about][contains-token(@class, 'block')][1]/@about, $container/@id)[1]" as="xs:string"/>
        <xsl:sequence select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $key || '`')"/>
    </xsl:function>

    <!-- EVENT LISTENERS -->

    <!-- create view onclick: inserts a row form for a new view block after the query block, bound to the same
         query resource. Its chart counterpart is the btn-create-chart handler in chart.xsl; both hand off to
         ldh:CreateBlock (client/block.xsl), which is the document-level create-instance chain. Unlike the
         chart, a view has no presentation settings to read off the results, so the query is all it carries. -->

    <xsl:template match="div[contains-token(@class, 'block')][@about]//button[contains-token(@class, 'btn-create-view')]" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="forClass" select="xs:anyURI('&ldh;View')" as="xs:anyURI"/>

        <xsl:call-template name="ldh:CreateBlock">
            <xsl:with-param name="block" select="$block"/>
            <xsl:with-param name="forClass" select="$forClass"/>
            <xsl:with-param name="properties" as="element()*">
                <spin:query rdf:resource="{$block/@about}"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- View pagination - previous page (generic handler for all Views) -->
    <xsl:template match="div[@typeof = '&ldh;View']//div[contains-token(@class, 'ldh-pager')]//a[contains-token(@class, 'pager-prev')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewPage">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="direction" select="'previous'"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- View pagination - next page (generic handler for all Views) -->
    <xsl:template match="div[@typeof = '&ldh;View']//div[contains-token(@class, 'ldh-pager')]//a[contains-token(@class, 'pager-next')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewPage">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="direction" select="'next'"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- View page size - rows per page (generic handler for all Views) -->
    <xsl:template match="div[@typeof = '&ldh;View']//select[contains-token(@class, 'pager-size')]" mode="ixsl:onchange">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="limit" select="xs:integer(ixsl:get(., 'value'))" as="xs:integer"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewLimit">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="limit" select="$limit"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- View container-order handler (generic handler for all Views) -->
    <xsl:template match="div[@typeof = '&ldh;View']//select[contains-token(@class, 'container-order')]" mode="ixsl:onchange">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="var-name" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewOrder">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="var-name" select="$var-name"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- View order-by button handler (generic handler for all Views) -->
    <xsl:template match="div[@typeof = '&ldh;View']//button[contains-token(@class, 'btn-order-by')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="desc" select="contains(@class, 'btn-order-by-desc')" as="xs:boolean"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewOrderDirection">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="desc" select="$desc"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>

        <!-- toggle the arrow direction -->
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-order-by-desc' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- View sortable column header handler (generic handler for all Views): the active column toggles direction, any other column becomes the sort key -->
    <xsl:template match="div[@typeof = '&ldh;View']//th[contains-token(@class, 'sortable')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="var-name" select="@data-var-name" as="xs:string"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
        <xsl:variable name="desc" select="boolean($select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending'][. = 'true'])" as="xs:boolean"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:choose>
                <xsl:when test="$var-name = $order-by-var-name">
                    <xsl:call-template name="ldh:ViewOrderDirection">
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="desc" select="$desc"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="ldh:ViewOrder">
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="var-name" select="$var-name"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <!-- keep the toolbar sort controls in agreement with the column-driven state -->
        <xsl:variable name="new-desc" select="boolean($select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending'][. = 'true'])" as="xs:boolean"/>
        <xsl:for-each select="$container//select[contains-token(@class, 'container-order')]">
            <ixsl:set-property name="value" select="$var-name" object="."/>
        </xsl:for-each>
        <xsl:for-each select="$container//button[contains-token(@class, 'btn-order-by')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-order-by-desc', $new-desc ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- View mode handler (generic handler for all Views) -->
    <xsl:template match="div[@typeof = '&ldh;View']//*[contains-token(@class, 'view-mode-list')]/a[not(contains-token(@class, 'is-active'))]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="active-class" select="tokenize(@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- deactivate the other mode items -->
        <xsl:for-each select="../a">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'is-active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this mode item -->
        <xsl:for-each select=".">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'is-active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- facet header onclick -->
    
    <xsl:template match="div[@typeof = '&ldh;View']//div[contains-token(@class, 'faceted-nav')]//*[contains-token(@class, 'nav-header')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="facet-container" select="ancestor::div[contains-token(@class, 'faceted-nav')]" as="element()"/>
        <xsl:variable name="subject-var-name" select="input[@name = 'subject']/@value" as="xs:string"/>
        <xsl:variable name="predicate" select="input[@name = 'predicate']/@value" as="xs:anyURI"/>
        <xsl:variable name="object-var-name" select="input[@name = 'object']/@value" as="xs:string"/>
        <!-- load facet values using the initial (not the current transformed) SELECT query, so that one facet's selection does not constrain another facet's value list -->
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <!-- TO-DO: can we get multiple BGPs here with the same ?s/p/?o ? -->
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $subject-var-name][json:string[@key = 'predicate'] = $predicate][json:string[@key = 'object'] = '?' || $object-var-name]" as="element()"/>

        <!-- opening one facet closes the others in the same toolbar -->
        <xsl:apply-templates select="$facet-container/../div[contains-token(@class, 'faceted-nav')][not(. is $facet-container)]/ul[contains-token(@class, 'facet-pop')][not(ixsl:style(.)?display = 'none')]" mode="ldh:CloseFacetPopover"/>

        <!-- is the current facet loaded? -->
        <xsl:variable name="loaded" select="exists(following-sibling::ul)" as="xs:boolean"/>
        <xsl:choose>
            <!-- if not, load and render its values -->
            <xsl:when test="not($loaded)">
                <!-- toggle the caret direction -->
                <xsl:for-each select="span[contains-token(@class, 'caret')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <!-- open the popover immediately with a loading state; the response replaces it with the value list.
                     'is-open' elevates the host .ldh-block (app.css :has() rule) so the popover paints above subsequent blocks -->
                <xsl:for-each select="$facet-container">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'is-open' ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <ul class="nav facet-pop">
                            <li class="facet-loading">
                                <div class="progress progress-indeterminate">
                                    <div class="bar"></div>
                                </div>
                            </li>
                        </ul>
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:for-each select="$container">
                    <xsl:sequence select="ldh:busy-cursor()"/>

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
                    <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>

                    <!-- strip LIMIT and OFFSET from the query - we want facet counts for the entire dataset, not just the current page -->
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
                    <xsl:variable name="request-uri" select="ldh:href($endpoint, map{})" as="xs:anyURI"/>
                    <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
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
                        ixsl:then(ldh:facet-value-response#1) =>
                        ixsl:finally(ldh:reset-cursor#0)"
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

                <!-- toggle the value list visibility, mirroring it as the container's 'is-open' state -->
                <xsl:choose>
                    <xsl:when test="$hidden">
                        <ixsl:set-style name="display" select="'block'" object="following-sibling::*[contains-token(@class, 'nav')]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <ixsl:set-style name="display" select="'none'" object="following-sibling::*[contains-token(@class, 'nav')]"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:sequence select="ixsl:call(ixsl:get($facet-container, 'classList'), 'toggle', [ 'is-open', $hidden ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- closes a facet popover: hides the value list, drops the container's 'is-open' state and resets its pill's caret -->

    <xsl:template match="ul[contains-token(@class, 'facet-pop')]" mode="ldh:CloseFacetPopover">
        <ixsl:set-style name="display" select="'none'" object="."/>
        <xsl:sequence select="ixsl:call(ixsl:get(.., 'classList'), 'remove', [ 'is-open' ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:for-each select="preceding-sibling::*[contains-token(@class, 'nav-header')]/span[contains-token(@class, 'caret')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- clicks that no other handler claims bubble up to body: dismiss any open facet and block links popovers.
         Drop-downs are not dismissed here - the pointerdown rule in client.xsl reaches every press, including
         the ones a specific handler takes, so this rule never saw a case it had left to close -->

    <xsl:template match="body" mode="ixsl:onclick">
        <xsl:apply-templates select="ixsl:page()//div[contains-token(@class, 'faceted-nav')]/ul[contains-token(@class, 'facet-pop')][not(ixsl:style(.)?display = 'none')]" mode="ldh:CloseFacetPopover"/>
        <xsl:apply-templates select="ixsl:page()//div[contains-token(@class, 'links-nav')][contains-token(@class, 'is-open')]" mode="ldh:CloseLinksPopover"/>
    </xsl:template>

    <!-- clicks inside the popover (value checkboxes) stop here instead of bubbling to body and dismissing it -->

    <xsl:template match="div[contains-token(@class, 'faceted-nav')]/ul[contains-token(@class, 'facet-pop')]" mode="ixsl:onclick"/>

    <!-- facet onchange -->

    <xsl:template match="div[@typeof = '&ldh;View']//div[contains-token(@class, 'faceted-nav')]//input[@type = 'checkbox']" mode="ixsl:onchange">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="var-name" select="@name" as="xs:string"/>
        <!-- collect the values/types/datatypes of all checked inputs within this facet and build an array of maps -->
        <xsl:variable name="labels" select="ancestor::ul//label[input[@type = 'checkbox'][ixsl:get(., 'checked')]]" as="element()*"/>
        <xsl:variable name="values" select="array { for $label in $labels return map { 'value' : string($label/input[@type = 'checkbox']/@value), 'type': string($label/input[@name = 'type']/@value), 'datatype': string($label/input[@name = 'datatype']/@value) } }" as="array(map(xs:string, xs:string))"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewFilter">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="var-name" select="$var-name"/>
                <xsl:with-param name="values" select="$values"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- parallax onclick -->

    <xsl:template match="div[@typeof = '&ldh;View']//div[contains-token(@class, 'parallax-nav')]//a[contains-token(@class, 'pchip')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="predicate" select="input/@value" as="xs:anyURI"/>
        <xsl:variable name="label" select="string(span[contains-token(@class, 'lbl')])" as="xs:string"/>
        <xsl:variable name="inverse" select="@data-dir = 'in'" as="xs:boolean"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ViewParallax">
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="predicate" select="$predicate"/>
                <xsl:with-param name="inverse" select="$inverse"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <!-- record the applied step and re-render the toolbar's step chips -->
        <xsl:variable name="steps-json" select="if (ixsl:contains($cache, 'parallax-steps')) then string(ixsl:get($cache, 'parallax-steps')) else '[]'" as="xs:string"/>
        <xsl:variable name="steps" select="array:append(parse-json($steps-json), map{ 'predicate': string($predicate), 'label': $label, 'inverse': $inverse })" as="array(*)"/>
        <ixsl:set-property name="parallax-steps" select="serialize($steps, map{ 'method': 'json' })" object="$cache"/>
        <xsl:apply-templates select="$container" mode="ldh:RenderParallaxSteps">
            <xsl:with-param name="steps" select="$steps"/>
        </xsl:apply-templates>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- applied parallax steps render as removable chips in the toolbar, next to the facet pills -->

    <xsl:template match="*" mode="ldh:RenderParallaxSteps">
        <xsl:param name="steps" as="array(*)"/>

        <xsl:for-each select="descendant::span[contains-token(@class, 'parallax-steps')][1]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:for-each select="1 to array:size($steps)">
                    <xsl:variable name="step" select="array:get($steps, .)" as="map(*)"/>
                    <xsl:variable name="inverse" select="($step('inverse'), false())[1]" as="xs:boolean"/>

                    <button type="button" class="facet-pill parallax-step" title="{$step('predicate')}">
                        <input name="ou" type="hidden" value="{$step('predicate')}"/>
                        <!-- the arrow is what distinguishes a step taken backwards from the same predicate followed forwards -->
                        <span class="msi xs" aria-hidden="true">
                            <xsl:value-of select="if ($inverse) then 'arrow_back' else 'arrow_forward'"/>
                        </span>
                        <span class="pred">
                            <xsl:apply-templates select="key('resources', if ($inverse) then 'via-incoming' else 'via', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                        <span class="val">
                            <xsl:value-of select="$step('label')"/>
                        </span>
                        <span class="x">
                            <span class="msi xs" aria-hidden="true">close</span>
                        </span>
                    </button>
                </xsl:for-each>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- removing an applied step rewinds the view: the query is rebuilt from the initial SELECT string and the steps before the removed one are replayed -->

    <xsl:template match="div[@typeof = '&ldh;View']//span[contains-token(@class, 'parallax-steps')]/button[contains-token(@class, 'parallax-step')]" mode="ixsl:onclick">
        <xsl:param name="container" select="ancestor::div[@typeof = '&ldh;View'][1]" as="element()"/>
        <xsl:param name="cache" select="ldh:view-cache($container)" as="item()"/>
        <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
        <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>
        <xsl:variable name="position" select="count(preceding-sibling::button[contains-token(@class, 'parallax-step')]) + 1" as="xs:integer"/>
        <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
        <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
        <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
        <xsl:variable name="steps" select="parse-json(string(ixsl:get($cache, 'parallax-steps')))" as="array(*)"/>
        <xsl:variable name="kept" select="array:subarray($steps, 1, $position - 1)" as="array(*)"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- rebuild the initial query XML from the cached SELECT string -->
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:call-template name="ldh:ReplayParallaxSteps">
                <xsl:with-param name="select-xml" select="json-to-xml($select-json-string)"/>
                <xsl:with-param name="steps" select="$kept"/>
            </xsl:call-template>
        </xsl:variable>

        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>
        <ixsl:set-property name="parallax-steps" select="serialize($kept, map{ 'method': 'json' })" object="$cache"/>
        <xsl:apply-templates select="$container" mode="ldh:RenderParallaxSteps">
            <xsl:with-param name="steps" select="$kept"/>
        </xsl:apply-templates>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1) =>
                ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- re-applies parallax steps to the query XML one at a time, each in its recorded direction -->

    <xsl:template name="ldh:ReplayParallaxSteps">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="steps" as="array(*)"/>

        <xsl:choose>
            <xsl:when test="array:size($steps) = 0">
                <xsl:sequence select="$select-xml"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="step" select="array:head($steps)" as="map(*)"/>
                <xsl:variable name="stepped" as="document-node()">
                    <xsl:call-template name="ldh:ViewParallax">
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="predicate" select="xs:anyURI($step('predicate'))"/>
                        <xsl:with-param name="inverse" select="($step('inverse'), false())[1]"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:call-template name="ldh:ReplayParallaxSteps">
                    <xsl:with-param name="select-xml" select="$stepped"/>
                    <xsl:with-param name="steps" select="array:tail($steps)"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
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
        <xsl:variable name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')" as="item()"/>

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
                        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ldh:href(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }, ()))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
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
                                <ixsl:set-property name="select-string" select="$select-string" object="$cache"/>
                                <!-- store the first var name of the initial SELECT query -->
                                <ixsl:set-property name="initial-var-name" select="$initial-var-name" object="$cache"/>
                                <!-- store the endpoint -->
                                <ixsl:set-property name="endpoint" select="$endpoint" object="$cache"/>

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
                                <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

                                <xsl:variable name="view-context" as="map(*)">
                                    <xsl:call-template name="ldh:RenderView">
                                        <xsl:with-param name="container" select="$container"/>
                                        <xsl:with-param name="select-string" select="$select-string"/>
                                        <xsl:with-param name="select-xml" select="$select-xml"/>
                                        <xsl:with-param name="endpoint" select="$endpoint"/>
                                        <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                                        <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                                        <xsl:with-param name="active-mode" select="if ($mode) then $mode else xs:anyURI('&ac;ListMode')"/>
                                        <xsl:with-param name="refresh-content" select="$refresh-content"/>
                                        <xsl:with-param name="cache" select="$cache"/>
                                        <xsl:with-param name="form-actions" select="$context('form-actions')"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <!-- Mark query response as complete -->
                                <xsl:sequence select="ldh:update-progress-counter($cache, $context, 'complete', ())"/>

                                <xsl:sequence select="map:merge((map{ 'block': $block }, $view-context))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- the query document loaded (200); the service resource is simply absent from it, so there is no
                                     HTTP failure to report and passing $response here would head the detail with a misleading 'HTTP 200' -->
                                <xsl:sequence select="ldh:render-block-error($container//div[contains-token(@class, 'main')], 'block-service-not-loaded', 'block-resource-not-described-explanation', $service-uri, ())"/>

                                <xsl:sequence select="ldh:hide-block-progress-bar($context, ())[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ldh:render-block-error($container//div[contains-token(@class, 'main')], 'block-query-not-loaded', ldh:http-error-key($response?status), $query-uri, $response)"/>

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
    
    <!-- the lexical sort key of a result: COALESCEs across $predicates in path order, preferring values whose @xml:lang primary subtag matches the reader's first accepted language -->

    <xsl:function name="ldh:sort-key-lexical" as="xs:string?">
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="predicates" as="xs:anyURI*"/>

        <xsl:variable name="children" select="for $p in $predicates return $resource/*[concat(namespace-uri(), local-name()) = $p]" as="element()*"/>
        <xsl:sequence select="(($children[tokenize(@xml:lang, '-')[1] = tokenize(ac:langs()[1], '-')[1]]/string(text()))[1], ($children[not(@xml:lang)]/string(text()))[1], ($children/string((text(), @rdf:resource, @rdf:nodeID)[1]))[1])[. ne ''][1]"/>
    </xsl:function>

    <!-- the RDF datatype shared by a sort column's literals, or () when the column carries none (plain or language-tagged literals, resources) or mixes several. The wrapped DESCRIBE returns an unordered graph, so the view re-sorts the page client-side; keying off the datatype is what keeps that order agreeing with the SPARQL ORDER BY that chose the page's members. -->

    <xsl:function name="ldh:sort-datatype" as="xs:anyURI?">
        <xsl:param name="resources" as="element()*"/>
        <xsl:param name="predicates" as="xs:anyURI*"/>

        <xsl:variable name="datatypes" select="distinct-values(for $p in $predicates return $resources/*[concat(namespace-uri(), local-name()) = $p]/@rdf:datatype/string(.))" as="xs:string*"/>
        <xsl:sequence select="if (count($datatypes) eq 1) then xs:anyURI($datatypes) else ()"/>
    </xsl:function>

    <!-- casts a lexical sort key to the XSD type that orders it. Returns () for datatypes XPath does not order (strings and their subtypes, xs:anyURI, binaries, gregorians, QNames) and for values that fail to cast - those tie here and are ordered by the lexical key instead. -->

    <xsl:function name="ldh:sort-key" as="xs:anyAtomicType?">
        <xsl:param name="key" as="xs:string?"/>
        <xsl:param name="datatype" as="xs:anyURI?"/>

        <xsl:choose>
            <!-- exact rather than promoted to xs:double, so integers beyond double's 2^53 keep their order -->
            <xsl:when test="ldh:datatype-family($datatype) = 'integer'">
                <xsl:sequence select="if ($key castable as xs:integer) then xs:integer($key) else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'decimal'">
                <xsl:sequence select="if ($key castable as xs:decimal) then xs:decimal($key) else ()"/>
            </xsl:when>
            <!-- 'NaN' is a valid xs:double lexical form, and a NaN sort key freezes SaxonJS's comparison outright - the remaining keys are never consulted and the results fall back to document order - so it is filtered back out to () here -->
            <xsl:when test="ldh:datatype-family($datatype) = 'double'">
                <xsl:sequence select="if ($key castable as xs:double) then xs:double($key)[. eq .] else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'dateTime'">
                <xsl:sequence select="if ($key castable as xs:dateTime) then xs:dateTime($key) else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'date'">
                <xsl:sequence select="if ($key castable as xs:date) then xs:date($key) else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'time'">
                <xsl:sequence select="if ($key castable as xs:time) then xs:time($key) else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'yearMonthDuration'">
                <xsl:sequence select="if ($key castable as xs:yearMonthDuration) then xs:yearMonthDuration($key) else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'dayTimeDuration'">
                <xsl:sequence select="if ($key castable as xs:dayTimeDuration) then xs:dayTimeDuration($key) else ()"/>
            </xsl:when>
            <!-- xs:duration is only partially ordered (P1M and P30D do not compare), so only its two ordered subtypes get a typed key -->
            <xsl:when test="ldh:datatype-family($datatype) = 'duration'">
                <xsl:sequence select="if ($key castable as xs:yearMonthDuration) then xs:yearMonthDuration($key) else if ($key castable as xs:dayTimeDuration) then xs:dayTimeDuration($key) else ()"/>
            </xsl:when>
            <xsl:when test="ldh:datatype-family($datatype) = 'boolean'">
                <xsl:sequence select="if ($key castable as xs:boolean) then xs:boolean($key) else ()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- when view RDF/XML results load, render them -->
    <xsl:function name="ldh:render-view" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="results" select="$context('view-results-response')?body" as="document-node()"/>
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
        <xsl:variable name="property-metadata" select="$context('property-metadata')" as="document-node()?"/>
        <xsl:variable name="cache" select="$context('cache')" as="item()"/>
        <xsl:variable name="form-actions" select="$context('form-actions')" as="element()?"/>
        <xsl:variable name="result-count-container-id" select="$container-id || '-result-count'" as="xs:string"/>

        <xsl:message>ldh:render-view</xsl:message>

        <xsl:for-each select="$results">
            <!-- map { object-var-name -> candidate predicate URIs } from BGP triples whose subject is the focus variable; deduped per var. SPARQL ORDER BY uses variables, but the wrapped DESCRIBE returns an unordered RDF graph, so the view sorts by predicates client-side - this map bridges the two. -->
            <xsl:variable name="var-predicates" as="map(xs:string, xs:anyURI*)">
                <xsl:map>
                    <xsl:for-each-group select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $initial-var-name][starts-with(json:string[@key = 'object'], '?')]" group-by="substring-after(json:string[@key = 'object'], '?')">
                        <xsl:variable name="predicates" as="xs:anyURI*">
                            <xsl:for-each select="current-group()">
                                <xsl:sequence select="ldh:alt-path-uris((json:string[@key = 'predicate'], json:map[@key = 'predicate'])[1])"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:if test="exists($predicates)">
                            <xsl:map-entry key="current-grouping-key()" select="distinct-values($predicates) ! xs:anyURI(.)"/>
                        </xsl:if>
                    </xsl:for-each-group>
                </xsl:map>
            </xsl:variable>

            <xsl:variable name="order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
            <xsl:variable name="order-by-predicates" select="if ($order-by-var-name and map:contains($var-predicates, $order-by-var-name)) then $var-predicates($order-by-var-name) else ()" as="xs:anyURI*"/>
            <xsl:variable name="desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
            <xsl:variable name="default-order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[2]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
            <!-- empty unless distinct from the primary, so the secondary keys below collapse to () when both ORDER BY conditions resolve to the same predicates -->
            <xsl:variable name="default-order-by-predicates" select="if ($default-order-by-var-name and map:contains($var-predicates, $default-order-by-var-name) and not(deep-equal($order-by-predicates, $var-predicates($default-order-by-var-name)))) then $var-predicates($default-order-by-var-name) else ()" as="xs:anyURI*"/>
            <xsl:variable name="default-desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[2]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
            <!-- each column's datatype is resolved once over the whole result set, not per row: xsl:sort requires every key to be mutually comparable, so the type has to be a property of the column rather than of the value -->
            <xsl:variable name="order-by-datatype" select="ldh:sort-datatype(/rdf:RDF/*, $order-by-predicates)" as="xs:anyURI?"/>
            <xsl:variable name="default-order-by-datatype" select="ldh:sort-datatype(/rdf:RDF/*, $default-order-by-predicates)" as="xs:anyURI?"/>
            <xsl:variable name="sorted-results" as="document-node()">
                <xsl:document>
                    <xsl:for-each select="/rdf:RDF">
                        <xsl:copy>
                            <!-- the typed key orders the column by its XSD datatype and the lexical key breaks its ties, which is also where untyped columns and values that fail to cast are ordered -->
                            <xsl:perform-sort select="*">
                                <xsl:sort select="ldh:sort-key(ldh:sort-key-lexical(., $order-by-predicates), $order-by-datatype)" order="{if ($desc) then 'descending' else 'ascending'}"/>
                                <xsl:sort select="ldh:sort-key-lexical(., $order-by-predicates)" order="{if ($desc) then 'descending' else 'ascending'}"/>
                                <xsl:sort select="ldh:sort-key(ldh:sort-key-lexical(., $default-order-by-predicates), $default-order-by-datatype)" order="{if ($default-desc) then 'descending' else 'ascending'}"/>
                                <xsl:sort select="ldh:sort-key-lexical(., $default-order-by-predicates)" order="{if ($default-desc) then 'descending' else 'ascending'}"/>
                                <!-- soft by URI/bnode ID otherwise -->
                                <xsl:sort select="if (@rdf:about) then @rdf:about else @rdf:nodeID" order="{if ($default-desc) then 'descending' else 'ascending'}"/>
                            </xsl:perform-sort>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:document>
            </xsl:variable>

            <xsl:for-each select="$container/div[contains-token(@class, 'main')]">
                <xsl:call-template name="ldh:RenderViewResults">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="results" select="$sorted-results"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="var-predicates" select="$var-predicates"/>
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                    <xsl:with-param name="desc" select="$desc"/>
                    <xsl:with-param name="order-by-var-name" select="$order-by-var-name"/>
                    <xsl:with-param name="result-count-container-id" select="$result-count-container-id"/>
                    <xsl:with-param name="active-mode" select="$active-mode"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata"/>
                    <xsl:with-param name="cache" select="$cache"/>
                    <xsl:with-param name="form-actions" select="$form-actions"/>
                </xsl:call-template>
            </xsl:for-each>

            <!-- use the initial (not the current transformed) SELECT query and focus var name for facet rendering. Facets render as dropdown pills in the view toolbar's left zone -->
            <xsl:for-each select="$container/descendant::div[contains-token(@class, 'ldh-view-toolbar')][1]/div[contains-token(@class, 'left')]">
                <xsl:call-template name="ldh:RenderFacets">
                    <xsl:with-param name="select-string" select="$select-string"/>
                    <xsl:with-param name="sub-container-id" select="$container-id || '-facets'"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata"/>
                </xsl:call-template>
            </xsl:for-each>

            <xsl:call-template name="bs2:ParallaxNav">
                <xsl:with-param name="empty-results" select="empty($sorted-results/rdf:RDF/*)"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                <xsl:with-param name="property-metadata" select="$property-metadata"/>
                <xsl:with-param name="cache" select="$cache"/>
                <xsl:with-param name="properties-container-id" select="$container-id || '-parallax-properties'"/>
            </xsl:call-template>

            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        </xsl:for-each>

        <!-- loading is done - restore the default mouse cursor -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <!-- Mark main view query as complete -->
        <xsl:sequence select="ldh:update-progress-counter($cache, $context, 'complete', ())"/>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- the discovered predicates arrive as (predicate, direction) pairs - one chip each, so a predicate
         used both ways yields two. Their labels live in the ontology rather than the end-user dataset,
         so they are fetched from the /ns endpoint in a single batched request. -->
    <xsl:function name="ldh:parallax-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="predicate-var-name" select="$context('predicate-var-name')" as="xs:string"/>
        <xsl:variable name="inverse-var-name" select="$context('inverse-var-name')" as="xs:string"/>

        <xsl:message>ldh:parallax-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="links" as="map(*)*">
                            <xsl:for-each select="//srx:result[srx:binding[@name = $predicate-var-name]/srx:uri]">
                                <xsl:sequence select="map{ 'predicate': xs:anyURI(srx:binding[@name = $predicate-var-name]/srx:uri), 'inverse': xs:boolean(srx:binding[@name = $inverse-var-name]/srx:literal) }"/>
                            </xsl:for-each>
                        </xsl:variable>

                        <xsl:if test="exists($links)">
                            <!-- render synchronously with whatever labels are already known, then re-render when the batch arrives -->
                            <xsl:sequence select="ldh:render-parallax-chips($container, $links, $context('property-metadata'))"/>

                            <xsl:variable name="values" select="' VALUES $this { ' || string-join(distinct-values($links ! ('&lt;' || ?predicate || '&gt;')), ' ') || ' }'" as="xs:string"/>
                            <xsl:variable name="query-string" select="$object-metadata-ns-query || $values" as="xs:string"/>
                            <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:href(resolve-uri('ns', ldt:base())), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                            <xsl:variable name="context" select="map:merge((
                              $context,
                              map{
                                'request': $request,
                                'container': $container,
                                'links': $links
                              }
                            ), map{ 'duplicates': 'use-last' })"/>
                            <ixsl:promise select="ixsl:http-request($context('request')) =>
                                ixsl:then(ldh:rethread-response($context, ?)) =>
                                ixsl:then(ldh:handle-response#1) =>
                                ixsl:then(ldh:parallax-property-response#1)"
                                on-failure="ldh:promise-failure#1"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="response" select="." as="map(*)"/>
                    <!-- error response - could not load parallax results -->
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <!-- appended beside the parallax rows rather than filling a block body, so the bare alert
                                 without the ldh-block-error wrapper - it must not ring the view card it sits in -->
                            <xsl:sequence select="ldh:error-alert('block-query-failed', ldh:http-error-key($response?status), ())"/>
                        </xsl:result-document>
                    </xsl:for-each>

                    <xsl:sequence select="ldh:hide-block-progress-bar($context, ())[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- re-renders the chip strip once the batched labels arrive -->
    <xsl:function name="ldh:parallax-property-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="links" select="$context('links')" as="map(*)*"/>

        <xsl:message>ldh:parallax-property-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:variable name="metadata" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>

            <xsl:sequence select="ldh:render-parallax-chips($container, $links, $metadata)"/>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- the whole strip renders at once from the complete link list: outgoing chips first, then incoming, each group by label -->
    <xsl:function name="ldh:render-parallax-chips" ixsl:updating="yes">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="links" as="map(*)*"/>
        <xsl:param name="metadata" as="document-node()?"/>

        <xsl:variable name="chips" as="element()*">
            <xsl:for-each select="$links">
                <xsl:sort select="number(?inverse)"/>
                <xsl:sort select="ldh:predicate-label(?predicate, $metadata)" lang="{ac:langs()[1]}"/>

                <a class="pchip{if (?inverse) then ' pchip-in' else ()}" title="{?predicate}" data-dir="{if (?inverse) then 'in' else 'out'}">
                    <input name="ou" type="hidden" value="{?predicate}"/>
                    <span class="msi sm" aria-hidden="true">
                        <xsl:value-of select="if (?inverse) then 'arrow_back' else 'arrow_forward'"/>
                    </span>
                    <span class="lbl">
                        <xsl:value-of select="ldh:predicate-label(?predicate, $metadata)"/>
                    </span>
                </a>
            </xsl:for-each>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="$chips"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:function>

    <!-- the ontology's label for a predicate, falling back to its fragment, then its last path segment, then the URI itself -->
    <xsl:function name="ldh:predicate-label" as="xs:string">
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:param name="metadata" as="document-node()?"/>
        <xsl:variable name="resource" select="if ($metadata) then key('resources', $predicate, $metadata) else ()" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$resource">
                <xsl:value-of>
                    <xsl:apply-templates select="$resource" mode="ac:label"/>
                </xsl:value-of>
            </xsl:when>
            <xsl:when test="contains($predicate, '#') and not(ends-with($predicate, '#'))">
                <xsl:value-of select="substring-after($predicate, '#')"/>
            </xsl:when>
            <xsl:when test="string-length(tokenize($predicate, '/')[last()]) &gt; 0">
                <xsl:value-of select="translate(tokenize($predicate, '/')[last()], '_', ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$predicate"/>
            </xsl:otherwise>
        </xsl:choose>
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
                        <xsl:choose>
                            <xsl:when test="$results//srx:result[srx:binding[@name = $object-var-name]]">
                                <xsl:choose>
                                    <!-- special case for rdf:type - we expect its values to be in the ontology (classes), not in the instance data -->
                                    <xsl:when test="$predicate = '&rdf;type'">
                                        <xsl:for-each select="$results//srx:result[srx:binding[@name = $object-var-name]]">
                                            <xsl:variable name="object-type" select="srx:binding[@name = $object-var-name]/srx:uri" as="xs:anyURI"/>
                                            <xsl:variable name="value-result" select="." as="element()"/>
                                            <!-- DESCRIBE the class over the application's /ns ontology endpoint (ACL-enforced) instead of proxying its vocab document -->
                                            <xsl:variable name="query-string" select="$property-metadata-query || ' VALUES $Type { &lt;' || $object-type || '&gt; }'" as="xs:string"/>
                                            <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:href(resolve-uri('ns', ldt:base())), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
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
                                        <!-- replace the loading state with the value list -->
                                        <xsl:for-each select="$container/ul[contains-token(@class, 'facet-pop')]">
                                            <xsl:result-document href="?." method="ixsl:replace-content">
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
                                            </xsl:result-document>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- no values - replace the loading state with the empty state -->
                                <xsl:for-each select="$container/ul[contains-token(@class, 'facet-pop')]">
                                    <xsl:result-document href="?." method="ixsl:replace-content">
                                        <li class="facet-empty">
                                            <xsl:apply-templates select="key('resources', 'no-values', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                        </li>
                                    </xsl:result-document>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- error response - could not load facet results -->
                    <xsl:for-each select="$container/ul[contains-token(@class, 'facet-pop')]">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <li>
                                <xsl:sequence select="ldh:error-alert('block-values-failed', ldh:http-error-key($response?status), ())"/>
                            </li>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>

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
            <xsl:variable name="existing-items" select="$container/ul/li[not(contains-token(@class, 'facet-loading'))]" as="element()*"/>
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
                    <xsl:sort select="a/text()" lang="{ac:langs()[1]}"/>
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

        <!-- Mark result count response as complete -->
        <xsl:sequence select="ldh:update-progress-counter($context('cache'), $context, 'complete', ())"/>

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

                        <!-- cache the total so pagers rendered on later page flips know it immediately, and refresh the pager already on the page with it -->
                        <xsl:variable name="total-count" select="xs:integer(($results//srx:binding[@name = $count-var-name]/srx:literal)[1])" as="xs:integer?"/>
                        <xsl:variable name="container-id" select="$context('container-id')" as="xs:string?"/>
                        <xsl:if test="exists($total-count)">
                            <ixsl:set-property name="result-count" select="$total-count" object="$context('cache')"/>

                            <xsl:if test="$container-id">
                                <xsl:variable name="view-results" select="if (ixsl:contains($context('cache'), 'results')) then ixsl:get($context('cache'), 'results') else ()" as="document-node()?"/>
                                <xsl:for-each select="id($container-id || '-container-results', ixsl:page())//div[contains-token(@class, 'ldh-pager')]">
                                    <xsl:result-document href="?." method="ixsl:replace-content">
                                        <xsl:call-template name="bs2:PagerControls">
                                            <xsl:with-param name="container-id" select="$container-id"/>
                                            <xsl:with-param name="result-count" select="count($view-results/rdf:RDF/rdf:Description)"/>
                                            <xsl:with-param name="select-xml" select="ixsl:get($context('cache'), 'select-xml')"/>
                                            <xsl:with-param name="total-count" select="$total-count"/>
                                        </xsl:call-template>
                                    </xsl:result-document>
                                </xsl:for-each>
                            </xsl:if>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <!-- the count sits inline in the view toolbar, where a full alert would outweigh the row it
                                 reports on - the design system's compact negative tag is the status marker at this size -->
                            <span class="ldhc-tag em-quiet co-negative sz-sm">
                                <span class="msi outline" aria-hidden="true">error</span>
                                <span class="ldhc-tag-lbl">
                                    <xsl:apply-templates select="key('resources', 'block-count-failed', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </span>
                            </span>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- INLINE CREATION -->

    <!-- update template for the forward linking triple, substituted with the same replace() idiom as the constructor update strings. INSERT/WHERE form: PATCH only accepts INSERT/WHERE and DELETE WHERE (DocumentHierarchyGraphStoreImpl) -->
    <xsl:variable name="view-instance-link-string" as="xs:string">
        <![CDATA[
            INSERT
              { $about  $property  $this }
            WHERE
              {}
        ]]>
    </xsl:variable>

    <!-- open the instance creation modal form for a view carrying ldh:container metadata (stamped as data-* attributes by ldh:ontology-view-insert) -->
    <xsl:template match="div[contains-token(@class, 'block')]//button[contains-token(@class, 'add-instance')][@data-for-class][@data-container]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="view-block" select="ancestor::div[contains-token(@class, 'block')][@data-property][1]" as="element()"/>
        <xsl:variable name="content-body" select="ancestor::div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>
        <xsl:variable name="forClass" select="xs:anyURI(@data-for-class)" as="xs:anyURI"/>
        <xsl:variable name="container-uri" select="xs:anyURI(@data-container)" as="xs:anyURI"/>
        <xsl:variable name="doc-uri" select="resolve-uri(ac:uuid() || '/', $container-uri)" as="xs:anyURI"/> <!-- build a relative URI for the container's child document -->
        <xsl:variable name="this" select="xs:anyURI($doc-uri || '#id' || ac:uuid())" as="xs:anyURI"/> <!-- the instance is a fragment resource within the new document, same minting as the type-typeahead flow -->

        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- 'types' is initially set to ($forClass) so the shape fetch targets the right class, same as the type-typeahead flow; 'view-*' keys carry the linkage metadata through the chain -->
        <xsl:variable name="context" as="map(*)" select="map{
            'content-body': $content-body,
            'forClass': $forClass,
            'types': ($forClass),
            'doc-uri': $doc-uri,
            'this': $this,
            'view-property': xs:anyURI($view-block/@data-property),
            'view-inverse': exists($view-block/@data-inverse),
            'view-about': xs:anyURI($view-block/ancestor::*[@about][1]/@about),
            'view-block-id': string($view-block/@id)
        }"/>

        <ixsl:promise select="ixsl:resolve($context) =>
            ixsl:then(ldh:fire-load-set-parallel(?, [
              [ ldh:load-constructed-doc#1, 'constructed-doc-request', 'constructed-doc-response', ldh:set-constructed-doc#1 ],
              [ ldh:load-shapes#1,          'shapes-request',          'shapes-response',          ldh:set-shapes#1 ]
            ])) =>
            ixsl:then(ldh:set-typeahead-form-resource#1) =>
            ixsl:then(ldh:fire-load-set-parallel(?, [
              [ ldh:load-constructors#1,      'constructors-request',      'constructors-response',      ldh:set-constructors#1 ],
              [ ldh:load-type-metadata#1,     'type-metadata-request',     'type-metadata-response',     ldh:set-type-metadata#1 ],
              [ ldh:load-property-metadata#1, 'property-metadata-request', 'property-metadata-response', ldh:set-property-metadata#1 ],
              [ ldh:load-constraints#1,       'constraints-request',       'constraints-response',       ldh:set-constraints#1 ]
            ])) =>
            ixsl:then(ldh:render-view-instance-modal-form#1) =>
            ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- Terminal callback for the add-instance onclick chain. Renders the instantiated resource with the same bs2:Form pipeline as the type-typeahead row form (ldh:render-typeahead-row-form), but with method='put' targeting the new document — the RDF/POST body then describes the fragment instance and the PUT auto-creates the containing Item document around it. Stamps the linkage metadata on the modal element so the submit and response handlers (separate events) can read it. -->
    <xsl:function name="ldh:render-view-instance-modal-form" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="content-body" select="$context('content-body')" as="element()"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="this" select="$context('this')" as="xs:anyURI"/>
        <xsl:variable name="forClass" select="$context('forClass')" as="xs:anyURI"/>
        <xsl:variable name="instance-doc" select="$context('instance-doc')" as="document-node()"/>
        <xsl:variable name="constructed-doc" select="$context('constructed-doc')" as="document-node()"/>
        <xsl:variable name="type-metadata" select="$context('type-metadata')" as="document-node()?"/>
        <xsl:variable name="property-metadata" select="$context('property-metadata')" as="document-node()?"/>
        <xsl:variable name="constraints" select="$context('constraints')" as="document-node()?"/>
        <xsl:variable name="constructors" select="$context('constructors')" as="document-node()?"/>
        <xsl:variable name="shapes" select="$context('shapes')" as="document-node()?"/>
        <xsl:variable name="classes" select="()" as="element()*"/>

        <xsl:message>ldh:render-view-instance-modal-form</xsl:message>

        <xsl:for-each select="$content-body">
            <!-- the document-level bs2:Form template renders the form shell (hidden rdf input, form actions); prototype-only object bnodes are suppressed by resource.xsl -->
            <xsl:variable name="form" as="element()*">
                <xsl:apply-templates select="$instance-doc" mode="bs2:Form">
                    <xsl:with-param name="method" select="'put'"/>
                    <xsl:with-param name="action" select="ldh:href($doc-uri)" as="xs:anyURI" tunnel="yes"/>
                    <xsl:with-param name="form-actions-class" select="'ldh-block-foot modal-footer'" as="xs:string?"/>
                    <xsl:with-param name="show-close-button" select="true()"/>
                    <xsl:with-param name="classes" select="$classes"/>
                    <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                    <xsl:with-param name="constructor" select="$constructed-doc" tunnel="yes"/>
                    <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                    <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                    <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                    <xsl:with-param name="base-uri" select="$doc-uri" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>


            <!-- a modal takes over from the chrome that opened it: a drop-down the pick came from is dismissed here, once its own handler has run -->
            <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'btn-group')][contains-token(@class, 'open')]" mode="ldh:CloseDropdown"/>
            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="modal modal-constructor fade in" about="{$doc-uri}" typeof="{$forClass}"> <!-- @about identifies the new document URL (uniform with the other modals so submit handlers can read $block/@about); the instance URI travels on @data-instance -->
                    <div class="modal-header">
                        <button type="button" class="close">&#215;</button>

                        <legend>
                        </legend>
                    </div>

                    <div class="modal-body">
                        <xsl:copy-of select="$form"/>
                    </div>
                </div>
            </xsl:result-document>

            <xsl:for-each select="./div[contains-token(@class, 'modal-constructor')][@about = $doc-uri]">
                <ixsl:set-attribute name="data-property" select="string($context('view-property'))" object="."/>
                <xsl:if test="$context('view-inverse')">
                    <ixsl:set-attribute name="data-inverse" select="'true'" object="."/>
                </xsl:if>
                <ixsl:set-attribute name="data-about" select="string($context('view-about'))" object="."/>
                <ixsl:set-attribute name="data-instance" select="string($this)" object="."/>
                <ixsl:set-attribute name="data-block-id" select="$context('view-block-id')" object="."/>
            </xsl:for-each>

            <!-- add event listeners to the descendants of the form -->
            <xsl:if test="id($form/@id, ixsl:page())">
                <xsl:apply-templates select="id($form/@id, ixsl:page())" mode="ldh:RenderRowForm"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>

    <!-- submit inline creation modal form: forward view — the linking triple <about> <property> <new> is PATCHed into the current document by the response callback -->
    <xsl:template match="div[contains-token(@class, 'modal-constructor')][@data-property][not(@data-inverse)]//form[contains-token(@class, 'ldh-prop-form')][upper-case(@method) = 'PUT']" mode="ixsl:onsubmit" priority="3"> <!-- prioritize over modal.xsl -->
        <xsl:next-match>
            <xsl:with-param name="callback" select="ldh:view-instance-form-response#1"/>
        </xsl:next-match>
    </xsl:template>

    <!-- submit inline creation modal form: inverse view — the linking triple <new> <property> <about> belongs in the new document's graph, so it ships inside the PUT body -->
    <xsl:template match="div[contains-token(@class, 'modal-constructor')][@data-property][@data-inverse]//form[contains-token(@class, 'ldh-prop-form')][upper-case(@method) = 'PUT']" mode="ixsl:onsubmit" priority="3"> <!-- prioritize over modal.xsl -->
        <xsl:param name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="modal" select="ancestor::div[contains-token(@class, 'modal-constructor')][1]" as="element()"/>
        <!-- pre-process form before submitting it: syncs input values, so it must precede ldh:parse-rdf-post -->
        <xsl:apply-templates select="." mode="ldh:FormPreSubmit"/>
        <xsl:variable name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <xsl:variable name="link-triple" as="element()">
            <json:map>
                <json:string key="subject"><xsl:sequence select="string($modal/@data-instance)"/></json:string>
                <json:string key="predicate"><xsl:sequence select="string($modal/@data-property)"/></json:string>
                <json:string key="object"><xsl:sequence select="string($modal/@data-about)"/></json:string>
            </json:map>
        </xsl:variable>

        <xsl:next-match>
            <xsl:with-param name="callback" select="ldh:view-instance-form-response#1"/>
            <!-- append $link-triple to the $request-body sent with the request, but not to the $resources rendered afterwards -->
            <xsl:with-param name="request-body" as="document-node()">
                <xsl:document>
                    <rdf:RDF>
                        <xsl:sequence select="ldh:triples-to-descriptions(($triples, $link-triple))"/>
                    </rdf:RDF>
                </xsl:document>
            </xsl:with-param>
        </xsl:next-match>
    </xsl:template>

    <!-- Per-flow callback for the inline creation PUT response. On 201 Created: close the modal, establish the forward linking triple (inverse ones shipped in the PUT body), refresh the view. Everything else delegates to the plain constructor modal flow (violation re-render, error alert). -->
    <xsl:function name="ldh:view-instance-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:view-instance-form-response</xsl:message>

        <xsl:choose>
            <xsl:when test="$response?status = 201 and map:contains($response?headers, 'location')">
                <xsl:variable name="modal" select="$context('block')" as="element()"/>
                <!-- read the linkage metadata off the modal before removing it -->
                <xsl:variable name="property" select="$modal/@data-property" as="xs:string"/>
                <xsl:variable name="inverse" select="exists($modal/@data-inverse)" as="xs:boolean"/>
                <xsl:variable name="about" select="$modal/@data-about" as="xs:string"/>
                <xsl:variable name="instance" select="$modal/@data-instance" as="xs:string"/>
                <xsl:variable name="block-id" select="$modal/@data-block-id" as="xs:string"/>
                <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
                <xsl:sequence select="ixsl:call($modal, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:choose>
                    <!-- inverse linking triple already shipped inside the PUT body: refresh straight away. The cursor stays 'progress' (set on form submit) until ldh:render-view restores it -->
                    <xsl:when test="$inverse">
                        <xsl:sequence select="ldh:refresh-view($block-id)"/>
                    </xsl:when>
                    <!-- forward: INSERT the linking triple into the current document, then refresh -->
                    <xsl:otherwise>
                        <xsl:variable name="update-string" select="replace($view-instance-link-string, '$about', '&lt;' || $about || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$property', '&lt;' || $property || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$this', '&lt;' || $instance || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`'), 'etag')" as="xs:string"/>
                        <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile -->
                        <xsl:variable name="link-request" select="map{ 'method': 'PATCH', 'href': ldh:href($doc-uri, map{}), 'media-type': 'application/sparql-update', 'body': $update-string, 'headers': map{ 'If-Match': $etag, 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }" as="map(*)"/>
                        <xsl:variable name="link-context" as="map(*)" select="map{ 'request': $link-request, 'doc-uri': $doc-uri, 'block-id': $block-id }"/>

                        <ixsl:promise select="
                            ixsl:http-request($link-context('request')) =>
                                ixsl:then(ldh:rethread-response($link-context, ?)) =>
                                ixsl:then(ldh:handle-response#1) =>
                                ixsl:then(ldh:view-instance-link-response#1)
                            "
                            on-failure="ldh:promise-failure#1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- 200/204, constraint violations and errors take the same path as the plain constructor modal flow -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:constructor-form-response($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- callback for the forward linking triple PATCH -->
    <xsl:function name="ldh:view-instance-link-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="block-id" select="$context('block-id')" as="xs:string"/>

        <xsl:message>ldh:view-instance-link-response</xsl:message>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 204)">
                <xsl:variable name="etag" select="$response?headers?etag" as="xs:string?"/>
                <xsl:if test="$etag">
                    <!-- store ETag header value under window.LinkedDataHub.contents[$doc-uri].etag so subsequent edits of the current document don't fail preconditions -->
                    <ixsl:set-property name="etag" select="$etag" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`')"/>
                </xsl:if>

                <!-- the cursor stays 'progress' (set on form submit) until ldh:render-view restores it -->
                <xsl:sequence select="ldh:refresh-view($block-id)"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

                <xsl:sequence select="ldh:error-response-alert($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Re-query the view block's results with fresh data (Cache-Control: no-cache). Rebuilds the request context from the contents cache like the pager/order/mode listeners do: the view's RDFa (spin:query) is replaced by the toolbar on the initial render, so re-entering ldh:RenderRow would no longer match the view template -->
    <xsl:function name="ldh:refresh-view" as="item()*" ixsl:updating="yes">
        <xsl:param name="block-id" as="xs:string"/>

        <xsl:message>ldh:refresh-view block-id: '<xsl:value-of select="$block-id"/>' matched views: <xsl:value-of select="count(id($block-id, ixsl:page())/div[contains-token(@class, 'row-main')]/div[@typeof = '&ldh;View'])"/></xsl:message>

        <xsl:for-each select="id($block-id, ixsl:page())/div[contains-token(@class, 'row-main')]/div[@typeof = '&ldh;View']">
            <xsl:variable name="container" select="." as="element()"/>
            <xsl:variable name="cache" select="ldh:view-cache($container)" as="item()"/>
            <xsl:message>ldh:refresh-view cache found: <xsl:value-of select="exists($cache)"/></xsl:message>
            <xsl:variable name="select-string" select="ixsl:get($cache, 'select-string')" as="xs:string"/>
            <xsl:variable name="select-xml" select="ixsl:get($cache, 'select-xml')" as="document-node()"/>
            <xsl:variable name="initial-var-name" select="ixsl:get($cache, 'initial-var-name')" as="xs:string"/>
            <xsl:variable name="endpoint" select="ixsl:get($cache, 'endpoint')" as="xs:anyURI"/>
            <xsl:variable name="active-class" select="tokenize($container//*[contains-token(@class, 'view-mode-list')]/a[contains-token(@class, 'is-active')]/@class, ' ')[. = map:keys($class-modes)]" as="xs:string"/>
            <xsl:variable name="active-mode" select="map:get($class-modes, $active-class)" as="xs:anyURI"/>

            <xsl:variable name="view-context" as="map(*)">
                <xsl:call-template name="ldh:RenderView">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="active-mode" select="$active-mode"/>
                    <xsl:with-param name="select-string" select="$select-string"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="refresh-content" select="true()"/>
                    <xsl:with-param name="cache" select="$cache"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

            <ixsl:promise select="
                ixsl:resolve($context) =>
                    ixsl:then(ldh:view-results-thunk#1) =>
                    ixsl:finally(ldh:reset-cursor#0)"
                on-failure="ldh:promise-failure#1"/>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>