<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY dydra  "https://w3id.org/atomgraph/linkeddatahub/services/dydra#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:sp="&sp;"
xmlns:dydra="&dydra;"
xmlns:dydra-urn="urn:dydra:"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:key name="resources-by-primary-topic" match="*[@rdf:about] | *[@rdf:nodeID]" use="foaf:primaryTopic/@rdf:resource"/>
    
    <!-- FUNCTIONS -->

    <xsl:function name="ac:create-map">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="lat" as="xs:float"/>
        <xsl:param name="lng" as="xs:float"/>
        <xsl:param name="zoom" as="xs:integer"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.maps.Map(document.getElementById('{$canvas-id}'), {{ center: new google.maps.LatLng({$lat}, {$lng}), zoom: {$zoom} }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:function name="ac:create-geo-object">
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="graph-var-name" as="xs:string?"/>

        <!-- set ?this value -->
        <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <xsl:variable name="js-statement" as="element()">
            <!-- TO-DO: move Geo under AtomGraph namespace -->
            <!-- use template literals because the query is multi-line https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals -->
            <xsl:choose>
                <xsl:when test="$graph-var-name">
                    <root statement="new SPARQLMap.Geo(window.LinkedDataHub['{$content-uri}'].map, new URL('{$base}'), new URL('{$endpoint}'), `{$select-string}`, '{$focus-var-name}', '{$graph-var-name}')"/>
                </xsl:when>
                <xsl:otherwise>
                    <root statement="new SPARQLMap.Geo(window.LinkedDataHub['{$content-uri}'].map, new URL('{$base}'), new URL('{$endpoint}'), `{$select-string}`, '{$focus-var-name}')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:template name="ac:add-geo-listener">
        <xsl:param name="content-uri" as="xs:anyURI"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="window.LinkedDataHub['{$content-uri}'].map.addListener('idle', function() {{ window.LinkedDataHub['{$content-uri}'].geo.loadMarkers(window.LinkedDataHub['{$content-uri}'].geo.addMarkers); }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:template>
    
    <!-- TEMPLATES -->

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

                <input type="checkbox" name="{$object-var-name}" value="{srx:binding[@name = $object-var-name]/srx:*}"> <!-- can be srx:literal -->
                <!-- TO-DO: reload state from URL query params -->
<!--                                    <xsl:if test="$filter/*/@rdf:resource = @rdf:about">
                        <xsl:attribute name="checked" select="'checked'"/>
                    </xsl:if>-->
                </input>
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
    
    <!-- filters -->

    <!-- transform SPARQL BGP triple into facet header and placeholder -->
    <xsl:template name="bs2:FilterIn">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="class" select="'sidebar-nav faceted-nav'" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="subject-var-name" as="xs:string"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div>
                    <xsl:if test="$id">
                        <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                    </xsl:if>
                    <xsl:if test="$class">
                        <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                    </xsl:if>

                    <h2 class="nav-header btn">
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
                            <xsl:otherwise>
                                <xsl:value-of select="$predicate"/>
                            </xsl:otherwise>
                        </xsl:choose>

                        <span class="caret caret-reversed pull-right"></span>
                        <input type="hidden" name="subject" value="{$subject-var-name}"/>
                        <input type="hidden" name="predicate" value="{$predicate}"/>
                        <input type="hidden" name="object" value="{$object-var-name}"/>
                    </h2>

                    <!-- facet values will be loaded into an <ul> here -->
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- result counts -->
    
    <xsl:template name="apl:ResultCounts">
        <xsl:param name="count-var-name" select="'count'" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <!-- unset ORDER BY/LIMIT/OFFSET - we want to COUNT all of the container's children; ordering is irrelevant -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="apl:replace-limit"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="apl:replace-offset"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="apl:replace-order-by"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:apply-templates select="$select-xml" mode="apl:result-count">
                    <xsl:with-param name="count-var-name" select="$count-var-name" tunnel="yes"/>
                    <xsl:with-param name="expression-var-name" select="$focus-var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="select-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $select-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $select-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge(($params, map{ 'auth_token': $service/dydra-urn:accessToken })) else $params)" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ac:build-uri($apl:base, map{ 'uri': string($results-uri) })" as="xs:anyURI"/> <!-- proxy the results -->

        <!-- load result count -->
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                <xsl:call-template name="apl:ResultCountResultsLoad">
                    <xsl:with-param name="container-id" select="'result-counts'"/>
                    <xsl:with-param name="count-var-name" select="$count-var-name"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- order by -->
    
    <xsl:template name="bs2:OrderBy">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <!--<xsl:param name="container-id" as="xs:string"/>-->
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:param name="order-by-predicate" as="xs:anyURI?"/>
        <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:append-content">
                <!-- TO-DO: order options -->
                <option value="{$predicate}">
                    <xsl:if test="$predicate = $order-by-predicate">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

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
                        <xsl:otherwise>
                            <xsl:value-of select="$predicate"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </option>
            </xsl:result-document>
        </xsl:for-each>
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
                            <xsl:attribute name="class">previous disabled</xsl:attribute>
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
                            <xsl:attribute name="class">next disabled</xsl:attribute>
                            <a></a>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
            </ul>
        </xsl:if>
    </xsl:template>

    <!-- container -->
    
    <xsl:template name="apl:RenderContainer">
        <xsl:param name="container" as="element()"/>
        <!--<xsl:param name="container-id" as="xs:string"/>-->
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="content" as="element()?"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="service" as="element()?"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="apl:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge(($params, map{ 'auth_token': $service/dydra-urn:accessToken })) else $params)" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ac:build-uri($apl:base, map{ 'uri': string($results-uri) })" as="xs:anyURI"/> <!-- proxy the results -->

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="content-uri" select="$content-uri"/>
                <xsl:with-param name="content" select="$content"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                <xsl:with-param name="service" select="$service"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template name="render-container">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="content" as="element()?"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="order-by-predicate" as="xs:anyURI?"/>
        <xsl:param name="desc" as="xs:boolean?"/>
        <xsl:param name="default-order-by-predicate" as="xs:anyURI?"/>
        <xsl:param name="default-order-by-var-name" as="xs:string?"/>
        <xsl:param name="default-desc" as="xs:boolean?"/>
        <xsl:param name="active-class" select="'list-mode'" as="xs:string?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="order-by-container-id" select="$container-id || '-container-order'" as="xs:string?"/>

        <!-- hide progress bar -->
        <xsl:for-each select="$container//div[@class = 'progress-bar']">
            <ixsl:set-style name="display" select="'none'" object="."/>
        </xsl:for-each>
                
        <xsl:choose>
            <!-- container results are already rendered - replace the content of the div -->
            <xsl:when test="$container/div[ul]">
                <xsl:for-each select="$container/div[ul]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:call-template name="container-mode">
                            <xsl:with-param name="container-id" select="$container-id"/>
                            <xsl:with-param name="select-xml" select="$select-xml"/>
                            <xsl:with-param name="results" select="$results"/>
                            <xsl:with-param name="order-by-predicate" select="$order-by-predicate"/>
                            <xsl:with-param name="desc" select="$desc"/>
                            <xsl:with-param name="default-order-by-predicate" select="$default-order-by-predicate"/>
                            <xsl:with-param name="default-desc" select="$default-desc"/>
                            <xsl:with-param name="active-class" select="$active-class"/>
                        </xsl:call-template>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <!-- first time rendering the container results -->
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div class="pull-right">
                            <form class="form-inline">
                                <label for="{$order-by-container-id}">
                                    <!-- currently no space for the label in the layout -->
                                    <!--<xsl:text>Order by </xsl:text>-->

                                    <select id="{$order-by-container-id}" name="order-by" class="input-medium container-order">
                                        <!-- show the default option if the container query does not have an ORDER BY -->
                                        <xsl:if test="not($select-xml/json:map/json:array[@key = 'order'])">
                                            <option>[None]</option>
                                        </xsl:if>
                                    </select>

                                    <xsl:choose>
                                        <xsl:when test="not($desc)">
                                            <button type="button" class="btn btn-order-by">Ascending</button>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <button type="button" class="btn btn-order-by btn-order-by-desc">Descending</button>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </label>
                            </form>
                        </div>

                        <div>
                            <xsl:call-template name="container-mode">
                                <xsl:with-param name="container-id" select="$container-id"/>
                                <xsl:with-param name="select-xml" select="$select-xml"/>
                                <xsl:with-param name="results" select="$results"/>
                                <xsl:with-param name="order-by-predicate" select="$order-by-predicate"/>
                                <xsl:with-param name="desc" select="$desc"/>
                                <xsl:with-param name="default-order-by-predicate" select="$default-order-by-predicate"/>
                                <xsl:with-param name="default-desc" select="$default-desc"/>
                                <xsl:with-param name="active-class" select="$active-class"/>
                            </xsl:call-template>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
                
                <!-- use the BGPs where the predicate is a URI value and the subject and object are variables -->
                <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $focus-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>
                
                <xsl:for-each select="$bgp-triples-map">
                    <xsl:variable name="id" select="generate-id()" as="xs:string"/>
                    <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:anyURI"/>
                    <xsl:variable name="results-uri" select="ac:build-uri($apl:base, map{ 'uri': string($predicate), 'accept': 'application/rdf+xml', 'mode': 'fragment' })" as="xs:anyURI"/>

                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                            <xsl:call-template name="bs2:OrderBy">
                                <xsl:with-param name="container" select="id($order-by-container-id, ixsl:page())"/>
                                <xsl:with-param name="id" select="$id"/>
                                <xsl:with-param name="predicate" select="$predicate"/>
                                <xsl:with-param name="order-by-predicate" select="$order-by-predicate" as="xs:anyURI?"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

        <!-- after we've created the map container element, create the JS objects using it -->
        <xsl:if test="$active-class = 'map-mode' or (not($active-class) and $ac:container-mode = '&ac;MapMode')">
            <xsl:variable name="canvas-id" select="$container-id || '-map-canvas'" as="xs:string"/>
            <xsl:variable name="initial-load" select="not(ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'map'))" as="xs:boolean"/>
            <!-- reuse center and zoom if map object already exists, otherwise set defaults -->
            <xsl:variable name="center-lat" select="if (not($initial-load)) then xs:float(ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'map'), 'getCenter', []), 'lat', [])) else 56" as="xs:float"/>
            <xsl:variable name="center-lng" select="if (not($initial-load)) then xs:float(ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'map'), 'getCenter', []), 'lng', [])) else 10" as="xs:float"/>
            <xsl:variable name="zoom" select="if (not($initial-load)) then xs:integer(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'map'), 'getZoom', [])) else 4" as="xs:integer"/>
            
            <ixsl:set-property name="map" select="ac:create-map($canvas-id, $center-lat, $center-lng, $zoom)" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

            <!-- unset LIMIT and OFFSET - we want all of the container's children on the map -->
            <xsl:variable name="select-xml" as="document-node()">
                <xsl:document>
                    <xsl:apply-templates select="$select-xml" mode="apl:replace-limit"/>
                </xsl:document>
            </xsl:variable>
            <xsl:variable name="select-xml" as="document-node()">
                <xsl:document>
                    <xsl:apply-templates select="$select-xml" mode="apl:replace-offset"/>
                </xsl:document>
            </xsl:variable>
            <xsl:variable name="select-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
            <xsl:variable name="select-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $select-json-string ])"/>
            <xsl:variable name="select-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $select-json ]), 'toString', [])" as="xs:string"/>
            <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
            <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
            <!-- do not use the initial LinkedDataHub.focus-var-name since parallax is changing the SELECT var name -->
            <xsl:variable name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
            <!-- to begin with, focus var is in the subject position, but becomes object after parallax, so we select a union of those -->
            <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $focus-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')] | $select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[starts-with(json:string[@key = 'subject'], '?')][not(starts-with(json:string[@key = 'predicate'], '?'))][json:string[@key = 'object'] = '?' || $focus-var-name]" as="element()*"/>
            <xsl:variable name="graph-var-name" select="$bgp-triples-map/ancestor::json:map[json:string[@key = 'type'] = 'graph'][1]/json:string[@key = 'name']/substring-after(., '?')" as="xs:string?"/>

            <ixsl:set-property name="geo" select="ac:create-geo-object($content-uri, ac:uri(), $apl:base, $endpoint, $select-string, $focus-var-name, $graph-var-name)" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

            <xsl:call-template name="ac:add-geo-listener">
                <xsl:with-param name="content-uri" select="$content-uri"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$active-class = 'chart-mode' or (not($active-class) and $ac:container-mode = '&ac;ChartMode')">
            <xsl:variable name="canvas-id" select="$container-id || '-chart-canvas'" as="xs:string"/>
            <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
            <xsl:variable name="category" as="xs:string?"/>
            <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
            <xsl:variable name="data-table" select="ac:rdf-data-table($results, $category, $series)"/>
            
            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

            <xsl:call-template name="render-chart">
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

        <!-- update progress bar -->
        <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div id="container-pane">
                    <div class="alert alert-block">
                        <strong>Error during query execution:</strong>
                        <pre>
                            <xsl:value-of select="$message"/>
                        </pre>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- container results -->
    
    <xsl:template name="container-mode">
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="order-by-predicate" as="xs:anyURI?"/>
        <xsl:param name="desc" as="xs:boolean?"/>
        <xsl:param name="default-order-by-predicate" as="xs:anyURI?"/>
        <xsl:param name="default-desc" as="xs:boolean?"/>
        <xsl:param name="active-class" as="xs:string?"/>
        
        <ul class="nav nav-tabs">
            <li class="read-mode">
                <xsl:if test="$active-class = 'read-mode' or (not($active-class) and $ac:container-mode = '&ac;ReadMode')">
                    <xsl:attribute name="class" select="'read-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;ReadMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
            <li class="list-mode">
                <xsl:if test="$active-class = 'list-mode' or (not($active-class) and $ac:container-mode = '&ac;ListMode')">
                    <xsl:attribute name="class" select="'list-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;ListMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
            <li class="table-mode">
                <xsl:if test="$active-class = 'table-mode' or (not($active-class) and $ac:container-mode = '&ac;TableMode')">
                    <xsl:attribute name="class" select="'table-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;TableMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
            <li class="grid-mode">
                <xsl:if test="$active-class = 'grid-mode' or (not($active-class) and $ac:container-mode = '&ac;GridMode')">
                    <xsl:attribute name="class" select="'grid-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;GridMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
            <li class="chart-mode">
                <xsl:if test="$active-class = 'chart-mode' or (not($active-class) and $ac:container-mode = '&ac;ChartMode')">
                    <xsl:attribute name="class" select="'chart-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;ChartMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
            <li class="map-mode">
                <xsl:if test="$active-class = 'map-mode' or (not($active-class) and $ac:container-mode = '&ac;MapMode')">
                    <xsl:attribute name="class" select="'map-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;MapMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
            <li class="graph-mode">
                <xsl:if test="$active-class = 'graph-mode' or (not($active-class) and $ac:container-mode = '&ac;GraphMode')">
                    <xsl:attribute name="class" select="'graph-mode active'"/>
                </xsl:if>

                <a>
                    <xsl:apply-templates select="key('resources', '&ac;GraphMode', document(ac:document-uri('&ac;')))" mode="apl:logo"/>
                </a>
            </li>
        </ul>

        <div class="container-results">
            <xsl:variable name="sorted-results" as="document-node()">
                <xsl:document>
                    <xsl:for-each select="$results/rdf:RDF">
                        <xsl:copy>
                            <xsl:perform-sort select="*">
                                <!-- sort by $order-by-predicate if it is set (multiple properties might match) -->
                                <xsl:sort select="if ($order-by-predicate) then *[concat(namespace-uri(), local-name()) = $order-by-predicate][1] else ()" order="{if ($desc) then 'descending' else 'ascending'}"/>
                                <!-- sort by $default-order-by-predicate if it is set and not equal to $order-by-predicate (multiple properties might match) -->
                                <xsl:sort select="if ($default-order-by-predicate and not($order-by-predicate = $default-order-by-predicate)) then *[concat(namespace-uri(), local-name()) = $default-order-by-predicate][1] else ()" order="{if ($default-desc) then 'descending' else 'ascending'}"/>
                                <!-- soft by URI/bnode ID otherwise -->
                                <xsl:sort select="if (@rdf:about) then @rdf:about else @rdf:nodeID"/>
                            </xsl:perform-sort>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:document>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$active-class = 'list-mode' or (not($active-class) and $ac:container-mode = '&ac;ListMode')">
                    <xsl:apply-templates select="$sorted-results" mode="bs2:BlockList">
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$active-class = 'table-mode' or (not($active-class) and $ac:container-mode = '&ac;TableMode')">
                    <xsl:apply-templates select="$sorted-results" mode="xhtml:Table">
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$active-class = 'grid-mode' or (not($active-class) and $ac:container-mode = '&ac;GridMode')">
                    <xsl:apply-templates select="$sorted-results" mode="bs2:Grid">
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$active-class = 'chart-mode' or (not($active-class) and $ac:container-mode = '&ac;ChartMode')">
                    <xsl:apply-templates select="$sorted-results" mode="bs2:Chart">
                        <xsl:with-param name="canvas-id" select="$container-id || '-chart-canvas'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$active-class = 'map-mode' or (not($active-class) and $ac:container-mode = '&ac;MapMode')">
                    <xsl:apply-templates select="$sorted-results" mode="bs2:Map">
                        <xsl:with-param name="canvas-id" select="$container-id || '-map-canvas'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$active-class = 'graph-mode' or (not($active-class) and $ac:container-mode = '&ac;GraphMode')">
                    <xsl:apply-templates select="$sorted-results" mode="bs2:Graph"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$sorted-results" mode="bs2:Block"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    
    <!-- facets -->

    <xsl:template name="render-facets">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <!-- use the first SELECT variable as the facet variable name (so that we do not generate facets based on other variables) -->
        <xsl:param name="focus-var-name" as="xs:string"/>

        <!-- use the BGPs where the predicate is a URI value and the subject and object are variables -->
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $focus-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>

        <xsl:for-each select="$bgp-triples-map">
            <xsl:variable name="id" select="generate-id()" as="xs:string"/>
            <xsl:variable name="subject-var-name" select="json:string[@key = 'subject']/substring-after(., '?')" as="xs:string"/>
            <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:anyURI"/>
            <xsl:variable name="object-var-name" select="json:string[@key = 'object']/substring-after(., '?')" as="xs:string"/>
            <xsl:variable name="results-uri" select="ac:build-uri($apl:base, map{ 'uri': string($predicate), 'accept': 'application/rdf+xml', 'mode': 'fragment' })" as="xs:anyURI"/>

            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="bs2:FilterIn">
                        <xsl:with-param name="container" select="$container"/>
                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="subject-var-name" select="$subject-var-name"/>
                        <xsl:with-param name="predicate" select="$predicate"/>
                        <xsl:with-param name="object-var-name" select="$object-var-name"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="add-typeahead">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:for-each select="id($id, ixsl:page())">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'blur', ixsl:get(ixsl:window(), 'onTypeaheadInputBlur') ])"/>
                <xsl:value-of select="ixsl:call(., 'focus', [])"/>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>
    
    <!-- block list -->

    <xsl:template match="rdf:RDF" mode="bs2:BlockList" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*[key('resources', foaf:primaryTopic/@rdf:resource)]" mode="bs2:BlockList" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="apl:logo">
                <xsl:with-param name="class" select="'well'"/>
            </xsl:apply-templates>
            
            <!-- don't show actions on the document that wraps a thing -->
            <!--<xsl:apply-templates select="." mode="bs2:Actions"/>-->

            <xsl:apply-templates select="." mode="bs2:TypeList"/>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="xhtml:Anchor"/>

            <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="bs2:Header">
                <xsl:with-param name="class" select="'well well-small'"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <!-- hide resources that will be shown paired/nested with a document -->
    <xsl:template match="*[key('resources-by-primary-topic', @rdf:about)]" mode="bs2:BlockList" priority="1"/>
    
    <xsl:template match="*[*][@rdf:*[local-name() = ('about', 'nodeID')]]" mode="bs2:BlockList" priority="0.8">
        <xsl:apply-templates select="." mode="bs2:Header"/>
    </xsl:template>

    <!-- grid -->

    <xsl:template match="rdf:RDF" mode="bs2:Grid" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <!-- table -->

    <xsl:template match="rdf:RDF" mode="xhtml:Table" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <!-- graph -->

    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <xsl:apply-templates select="." mode="ac:SVG">
            <xsl:with-param name="width" select="'100%'"/>
            <xsl:with-param name="step-count" select="5"/>
            <xsl:with-param name="spring-length" select="100" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- map -->

    <!-- TO-DO: improve match pattern -->
    <xsl:template match="rdf:RDF[resolve-uri('geo/', $apl:base) = ac:uri()]" mode="bs2:Map" priority="1">
        <xsl:next-match>
            <xsl:with-param name="container-uri" select="()"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="bs2:Map">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="class" select="'map-canvas'" as="xs:string?"/>

        <div id="{$canvas-id}">
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
        </div>
    </xsl:template>
    
    <!-- parallax -->
    
    <xsl:template name="bs2:Parallax">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="class" select="'sidebar-nav parallax-nav'" as="xs:string?"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="service" as="element()?"/>
        <xsl:param name="properties-container-id" select="$container-id || '-parallax-properties'" as="xs:string"/>
        
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <h2 class="nav-header btn">Related results</h2>

                <ul id="{$properties-container-id}" class="well well-small nav nav-list">
                    <!-- <li> with properties will go here -->
                </ul>
            </xsl:result-document>
        </xsl:for-each>

        <!-- do not use the initial LinkedDataHub.focus-var-name since parallax is changing the SELECT var name -->
        <xsl:variable name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <xsl:variable name="query-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge(($params, map{ 'auth_token': $service/dydra-urn:accessToken })) else $params)" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ac:build-uri($apl:base, map{ 'uri': string($results-uri) })" as="xs:anyURI"/> <!-- proxy the results -->

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
            <xsl:call-template name="onParallaxSelectLoad">
                <xsl:with-param name="container" select="id($properties-container-id, ixsl:page())"/>
                <xsl:with-param name="var-name" select="$focus-var-name"/>
                <xsl:with-param name="results" select="$results"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>

    <!-- EVENT LISTENERS -->

    <!-- container mode tabs -->
    
    <xsl:template match="*[tokenize(@class, ' ') = 'resource-content']//div/ul[@class = 'nav nav-tabs']/li[not(tokenize(@class, ' ') = 'active')]/a" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <xsl:variable name="results-container" select="$container/div[@class = 'span7']" as="element()"/> <!-- results in the middle column -->
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="active-class" select="../@class" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:call-template name="render-container">
            <!--<xsl:with-param name="container-id" select="$container-id"/>-->
            <xsl:with-param name="container" select="$results-container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'results')"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="active-class" select="$active-class"/>
        </xsl:call-template>
    </xsl:template>

    <!-- pager prev links -->

    <xsl:template match="*[tokenize(@class, ' ') = 'resource-content']//ul[@class = 'pager']/li[@class = 'previous']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <xsl:variable name="results-container" select="$container/div[@class = 'span7']" as="element()"/> <!-- results in the middle column -->
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <!-- descrease OFFSET to get the previous page -->
        <xsl:variable name="offset" select="$offset - $page-size" as="xs:integer"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.services'))" as="element()?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:replace-offset">
                    <xsl:with-param name="offset" select="$offset" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:call-template name="apl:PushContentState">
            <xsl:with-param name="href" select="ac:build-uri($apl:base, map{ 'uri': string(ac:uri()) })"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>
        
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container" select="$results-container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="service" select="$service"/>
        </xsl:call-template>
    </xsl:template>

    <!-- pager next links -->
    
    <xsl:template match="*[tokenize(@class, ' ') = 'resource-content']//ul[@class = 'pager']/li[@class = 'next']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <xsl:variable name="results-container" select="$container/div[@class = 'span7']" as="element()"/> <!-- results in the middle column -->
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <!-- increase OFFSET to get the next page -->
        <xsl:variable name="offset" select="$offset + $page-size" as="xs:integer"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.services'))" as="element()?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:replace-offset">
                    <xsl:with-param name="offset" select="$offset" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:call-template name="apl:PushContentState">
            <xsl:with-param name="href" select="ac:build-uri($apl:base, map{ 'uri': string(ac:uri()) })"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>
        
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container" select="$results-container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="service" select="$service"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- order by onchange -->
    
    <xsl:template match="select[tokenize(@class, ' ') = 'container-order']" mode="ixsl:onchange">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <xsl:variable name="results-container" select="$container/div[@class = 'span7']" as="element()"/> <!-- results in the middle column -->
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="predicate" select="ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $focus-var-name][json:string[@key = 'predicate'] = $predicate][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>
        <xsl:variable name="var-name" select="$bgp-triples-map/json:string[@key = 'object'][1]/substring-after(., '?')" as="xs:string?"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.services'))" as="element()?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:replace-order-by">
                    <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:call-template name="apl:PushContentState">
            <xsl:with-param name="href" select="ac:build-uri($apl:base, map{ 'uri': string(ac:uri()) })"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container" select="$results-container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="service" select="$service"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- ascending/descending onclick -->
    
    <!-- TO-DO: unify with container ORDER BY onchange -->
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-order-by']" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="desc" select="contains(@class, 'btn-order-by-desc')" as="xs:boolean"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.services'))" as="element()?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:toggle-desc">
                    <xsl:with-param name="desc" select="not($desc)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:call-template name="apl:PushContentState">
            <xsl:with-param name="href" select="ac:build-uri($apl:base, map{ 'uri': string(ac:uri()) })"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container" select="$container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="service" select="$service"/>
        </xsl:call-template>
        
        <!-- toggle the arrow direction -->
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-order-by-desc' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- facet header on click -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//*[tokenize(@class, ' ') = 'nav-header']" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="facet-container" select="ancestor::div[tokenize(@class, ' ') = 'faceted-nav']" as="element()"/>
        <xsl:variable name="subject-var-name" select="input[@name = 'subject']/@value" as="xs:string"/>
        <xsl:variable name="predicate" select="input[@name = 'predicate']/@value" as="xs:anyURI"/>
        <xsl:variable name="object-var-name" select="input[@name = 'object']/@value" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <!-- TO-DO: can we get multiple BGPs here with the same ?s/p/?o ? -->
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $subject-var-name][json:string[@key = 'predicate'] = $predicate][json:string[@key = 'object'] = '?' || $object-var-name]" as="element()"/>

        <!-- is the current facet loaded? -->
        <xsl:variable name="loaded" select="exists(following-sibling::ul)" as="xs:boolean"/>
        <xsl:choose>
            <!-- if not, load and render its values -->
            <xsl:when test="not($loaded)">
                <xsl:for-each select="$container">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <!--<xsl:variable name="container-id" select="@id" as="xs:string"/>-->
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
                    <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
                    <!-- generate the XML structure of a SPARQL query which is used to load facet values, their counts and labels -->
                    <xsl:variable name="select-xml" as="document-node()">
                        <xsl:document>
                            <xsl:apply-templates select="$select-xml" mode="apl:bgp-value-counts">
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
                    <!-- TO-DO: unify dydra: and dydra-urn: ? -->
                    <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge(($params, map{ 'auth_token': $service/dydra-urn:accessToken })) else $params)" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ac:build-uri($apl:base, map{ 'uri': string($results-uri) })" as="xs:anyURI"/> <!-- proxy the results -->

                    <!-- load facet values, their counts and optional labels -->
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                            <xsl:call-template name="onFacetValueResultsLoad">
                                <xsl:with-param name="container" select="$facet-container"/>
                                <xsl:with-param name="predicate" select="$predicate"/>
                                <xsl:with-param name="object-var-name" select="$object-var-name"/>
                                <xsl:with-param name="count-var-name" select="$count-var-name"/>
                                <xsl:with-param name="label-sample-var-name" select="$label-sample-var-name"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- is the current facet hidden? -->
                <xsl:variable name="hidden" select="ixsl:style(following-sibling::*[tokenize(@class, ' ') = 'nav'])?display = 'none'" as="xs:boolean"/>

                <!-- toggle the caret direction -->
                <xsl:for-each select="span[tokenize(@class, ' ') = 'caret']">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <!-- toggle the value list visibility -->
                <xsl:choose>
                    <xsl:when test="$hidden">
                        <ixsl:set-style name="display" select="'block'" object="following-sibling::*[tokenize(@class, ' ') = 'nav']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <ixsl:set-style name="display" select="'none'" object="following-sibling::*[tokenize(@class, ' ') = 'nav']"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- facet onchange -->

    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//input[@type = 'checkbox']" mode="ixsl:onchange">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="var-name" select="@name" as="xs:string"/>
        <!-- collect the values/types/datatypes of all checked inputs within this facet and build an array of maps -->
        <xsl:variable name="labels" select="ancestor::ul//label[input[@type = 'checkbox'][ixsl:get(., 'checked')]]" as="element()*"/>
        <xsl:variable name="values" select="array { for $label in $labels return map { 'value' : string($label/input[@type = 'checkbox']/@value), 'type': string($label/input[@name = 'type']/@value), 'datatype': string($label/input[@name = 'datatype']/@value) } }" as="array(map(xs:string, xs:string))"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.services'))" as="element()?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:filter-in">
                    <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                    <xsl:with-param name="values" select="$values" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:call-template name="apl:PushContentState">
            <xsl:with-param name="href" select="ac:build-uri($apl:base, map{ 'uri': string(ac:uri()) })"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container" select="$container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="service" select="$service"/>
        </xsl:call-template>
    </xsl:template>

    <!-- parallax onclick -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'parallax-nav']/ul/li/a" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']" as="element()"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate(ixsl:get($container, 'dataset.contentUri'), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="predicate" select="input/@value" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-xml')" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'service-uri') else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.services'))" as="element()?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:add-parallax-step">
                    <xsl:with-param name="predicate" select="$predicate" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:call-template name="apl:PushContentState">
            <xsl:with-param name="href" select="ac:build-uri($apl:base, map{ 'uri': string(ac:uri()) })"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container" select="$container"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            <xsl:with-param name="service" select="$service"/>
        </xsl:call-template>
    </xsl:template>

    <!-- CALLBACKS -->
    
    <!-- when container RDF/XML results load, render them -->
    <xsl:template name="onContainerResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="content" as="element()?"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="service" as="element()?"/>

        <!-- update progress bar -->
        <xsl:for-each select="$container//div[@class = 'bar']">
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <!-- group descriptions by subject -->
                    <xsl:variable name="grouped-results" as="document-node()">
                        <xsl:apply-templates select="." mode="ac:GroupTriples"/>
                    </xsl:variable>
                    <ixsl:set-property name="results" select="$grouped-results" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>

                    <!-- use the BGPs where the predicate is a URI value and the subject and object are variables -->
                    <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $focus-var-name][not(starts-with(json:string[@key = 'predicate'], '?'))][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>
                    <xsl:variable name="order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
                    <xsl:variable name="order-by-predicate" select="$bgp-triples-map[json:string[@key = 'object'] = '?' || $order-by-var-name][1]/json:string[@key = 'predicate']" as="xs:anyURI?"/>
                    <xsl:variable name="desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
                    <xsl:variable name="default-order-by-var-name" select="$select-xml/json:map/json:array[@key = 'order']/json:map[2]/json:string[@key = 'expression']/substring-after(., '?')" as="xs:string?"/>
                    <xsl:variable name="default-order-by-predicate" select="$bgp-triples-map[json:string[@key = 'object'] = '?' || $default-order-by-var-name][1]/json:string[@key = 'predicate']" as="xs:anyURI?"/>
                    <xsl:variable name="default-desc" select="$select-xml/json:map/json:array[@key = 'order']/json:map[2]/json:boolean[@key = 'descending']" as="xs:boolean?"/>
                    <xsl:variable name="active-class" select="$container//ul[@class = 'nav nav-tabs']/li[tokenize(@class, ' ') = 'active']/tokenize(@class, ' ')[not(. = 'active')][1]" as="xs:string?"/>

                    <xsl:call-template name="render-container">
                        <xsl:with-param name="container" select="$container/div[@class = 'span7']"/> <!-- render results in the middle column -->
                        <xsl:with-param name="content-uri" select="$content-uri"/>
                        <xsl:with-param name="content" select="$content"/>
                        <xsl:with-param name="results" select="$grouped-results"/>
                        <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                        <xsl:with-param name="order-by-predicate" select="$order-by-predicate"/>
                        <xsl:with-param name="desc" select="$desc"/>
                        <xsl:with-param name="default-order-by-var-name" select="$default-order-by-var-name"/>
                        <xsl:with-param name="default-order-by-predicate" select="$default-order-by-predicate"/>
                        <xsl:with-param name="default-desc" select="$default-desc"/>
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="active-class" select="$active-class"/>
                    </xsl:call-template>

                    <!-- only append facets if they are not already present -->
                    <xsl:if test="not($container/div[tokenize(@class, ' ') = 'left-nav']/*)">
                        <xsl:variable name="facet-container-id" select="$container-id || '-left-nav'" as="xs:string"/>
                        
                        <xsl:for-each select="$container/div[tokenize(@class, ' ') = 'left-nav']">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <div id="{$facet-container-id}" class="well well-small"/>
                            </xsl:result-document>
                        </xsl:for-each>
                        
                        <!-- use the initial (not the current, transformed) SELECT query and focus var name for facet rendering -->
                        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
                        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
                        <xsl:variable name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>

                        <xsl:call-template name="render-facets">
                            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                            <xsl:with-param name="select-xml" select="$select-xml"/>
                            <xsl:with-param name="container" select="id($facet-container-id, ixsl:page())"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- result counts -->
                    <!-- <xsl:if test="id('result-counts', ixsl:page())">
                        <xsl:call-template name="apl:ResultCounts">
                            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                            <xsl:with-param name="select-xml" select="$select-xml"/>
                        </xsl:call-template>
                    </xsl:if> -->

                    <!-- only show parallax navigation if the RDF result contains object resources -->
                    <xsl:if test="$grouped-results/rdf:RDF/*/*[@rdf:resource]">
                        <xsl:variable name="parallax-container-id" select="$container-id || '-right-nav'" as="xs:string"/>

                        <!-- create a container for parallax controls in the right-nav, if it doesn't exist yet -->
                        <xsl:if test="not($container/div[tokenize(@class, ' ') = 'right-nav']/*)">
                            <xsl:for-each select="$container/div[tokenize(@class, ' ') = 'right-nav']">
                                <xsl:result-document href="?." method="ixsl:append-content">
                                    <div id="{$parallax-container-id}" class="well well-small sidebar-nav parallax-nav"/>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:if>

                        <xsl:call-template name="bs2:Parallax">
                            <xsl:with-param name="results" select="$grouped-results"/>
                            <xsl:with-param name="select-xml" select="$select-xml"/>
                            <xsl:with-param name="service" select="$service"/>
                            <xsl:with-param name="container" select="id($parallax-container-id, ixsl:page())"/>
                        </xsl:call-template>
                    </xsl:if>
                    
                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
                <xsl:call-template name="render-container-error">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="message" select="?message"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- loading is done - restore the default mouse cursor -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template name="onParallaxSelectLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="var-name" as="xs:string"/>
        <xsl:param name="results" as="document-node()"/>
        
        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="var-name-resources" select="//srx:binding[@name = $var-name]/srx:uri" as="xs:anyURI*"/>

                    <xsl:for-each-group select="$results/rdf:RDF/*[@rdf:about = $var-name-resources]/*[@rdf:resource or @rdf:nodeID]" group-by="concat(namespace-uri(), local-name())">
                        <xsl:variable name="predicate" select="xs:anyURI(namespace-uri() || local-name())" as="xs:anyURI"/>
                        <xsl:variable name="results-uri" select="ac:build-uri($apl:base, map{ 'uri': $predicate, 'accept': 'application/rdf+xml', 'mode': 'fragment' })" as="xs:anyURI"/>

                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                            <xsl:call-template name="onParallaxPropertyLoad">
                                <xsl:with-param name="container" select="$container"/>
                                <xsl:with-param name="predicate" select="$predicate"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:for-each-group>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
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
    </xsl:template>
    
    <xsl:template name="onParallaxPropertyLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
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
    </xsl:template>
    
    <xsl:template name="onFacetValueResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:param name="count-var-name" as="xs:string"/>
        <xsl:param name="label-sample-var-name" as="xs:string"/>

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
                                    <xsl:variable name="results-uri" select="ac:build-uri($apl:base, map{ 'uri': $object-type, 'accept': 'application/rdf+xml', 'mode': 'fragment' })" as="xs:anyURI"/>

                                    <!-- load the label of the object type -->
                                    <xsl:variable name="request" as="item()*">
                                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                            <xsl:call-template name="onFacetValueTypeLoad">
                                                <xsl:with-param name="container" select="$container"/>
                                                <xsl:with-param name="object-var-name" select="$object-var-name"/>
                                                <xsl:with-param name="count-var-name" select="$count-var-name"/>
                                                <xsl:with-param name="object-type" select="$object-type"/>
                                                <xsl:with-param name="value-result" select="$value-result"/>
                                            </xsl:call-template>
                                        </ixsl:schedule-action>
                                    </xsl:variable>
                                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- toggle the caret direction -->
                                <xsl:for-each select="$container/h2/span[tokenize(@class, ' ') = 'caret']">
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
                <!-- error response - could not load query results -->
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
    </xsl:template>
    
    <xsl:template name="onFacetValueTypeLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:param name="count-var-name" as="xs:string"/>
        <xsl:param name="object-type" as="xs:anyURI"/>
        <xsl:param name="value-result" as="element()"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        
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
    </xsl:template>
    
    <xsl:template name="apl:ResultCountResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="count-var-name" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                    <xsl:result-document href="#{$container-id}" method="ixsl:replace-content">
                        <p>
                            <xsl:text>Total results </xsl:text>
                            <span class="badge badge-inverse">
                                <xsl:value-of select="$results//srx:binding[@name = $count-var-name]/srx:literal"/>
                            </span>
                        </p>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="#{$container-id}" method="ixsl:replace-content">
                    <p class="alert">Error loading result count</p>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>