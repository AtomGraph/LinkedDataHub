<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY dydra  "https://w3id.org/atomgraph/linkeddatahub/services/dydra#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY spl    "http://spinrdf.org/spl#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
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
xmlns:dh="&dh;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:sp="&sp;"
xmlns:spl="&spl;"
xmlns:geo="&geo;"
xmlns:void="&void;"
xmlns:dydra="&dydra;"
xmlns:dydra-urn="urn:dydra:"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:key name="resources-by-primary-topic" match="*[@rdf:about] | *[@rdf:nodeID]" use="foaf:primaryTopic/@rdf:resource"/>

    <!-- PARALLAX -->
    
    <xsl:template name="bs2:Parallax">
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="class" select="'sidebar-nav parallax-nav'" as="xs:string?"/>
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="select-xml" as="document-node()"/>

        <xsl:variable name="properties-container-id" select="$container-id || '-parallax-properties'" as="xs:string"/>
        
        <xsl:result-document href="#{$container-id}" method="ixsl:replace-content">
            <h2 class="nav-header btn">Related results</h2>

            <ul id="{$properties-container-id}" class="well well-small nav nav-list">
                <!-- <li> with properties will go here -->
            </ul>
        </xsl:result-document>

        <!-- do not use the initial LinkedDataHub.focus-var-name since parallax is changing the SELECT var name -->
        <xsl:variable name="focus-var-name" select="$select-xml//json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <xsl:variable name="query-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>

        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge($params, map{ 'auth_token': $service/dydra-urn:accessToken }) else $params)" as="xs:anyURI"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
            <xsl:call-template name="onParallaxSelectLoad">
                <xsl:with-param name="container-id" select="$properties-container-id"/>
                <xsl:with-param name="var-name" select="$focus-var-name"/>
                <xsl:with-param name="results" select="$results"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template name="onParallaxSelectLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="var-name" as="xs:string"/>
        <xsl:param name="results" as="document-node()"/>
        
        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="var-name-resources" select="//srx:binding[@name = $var-name]/srx:uri" as="xs:anyURI*"/>

                    <xsl:for-each-group select="$results/rdf:RDF/*[@rdf:about = $var-name-resources]/*[@rdf:resource or @rdf:nodeID]" group-by="concat(namespace-uri(), local-name())">
                        <xsl:variable name="predicate" select="xs:anyURI(namespace-uri() || local-name())" as="xs:anyURI"/>
                        <xsl:variable name="results-uri" select="ac:build-uri($ldt:base, map{ 'uri': $predicate, 'accept': 'application/rdf+xml', 'mode': 'fragment' })" as="xs:anyURI"/>

                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                            <xsl:call-template name="onParallaxPropertyLoad">
                                <xsl:with-param name="container-id" select="$container-id"/>
                                <xsl:with-param name="predicate" select="$predicate"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:for-each-group>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
                <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
                    <div class="alert alert-block">
                        <strong>Error during query execution:</strong>
                        <pre>
                            <xsl:value-of select="$response?message"/>
                        </pre>
                    </div>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onParallaxPropertyLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>
        <xsl:variable name="existing-items" select="id($container-id, ixsl:page())/li" as="element()*"/>
        <xsl:variable name="new-item" as="element()">
            <li>
                <a>
                    <input name="ou" type="hidden" value="{$predicate}"/>
                    
                    <xsl:choose>
                        <xsl:when test="$results">
                            <xsl:value-of select="ac:label(key('resources', $predicate, $results))"/>
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

        <xsl:result-document href="#{$container-id}" method="ixsl:replace-content">
            <xsl:sequence select="$items"/>
        </xsl:result-document>
    </xsl:template>
    
    <!-- FILTERS -->

    <!-- transform SPARQL BGP triple into facet header and placeholder -->
    <xsl:template name="bs2:FilterIn">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="class" select="'sidebar-nav faceted-nav'" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="subject-var-name" as="xs:string"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>

        <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>

                <h2 class="nav-header btn">
                    <xsl:choose>
                        <xsl:when test="$results">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', $predicate, $results)" mode="ac:label"/>
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
    </xsl:template>

    <!-- ORDER BY -->
    
    <xsl:template name="bs2:OrderBy">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="predicate" as="xs:anyURI"/>
        <xsl:param name="order-by-predicate" as="xs:anyURI?"/>
        <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>

        <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
            <!-- TO-DO: order options -->
            <option value="{$predicate}">
                <xsl:if test="$predicate = $order-by-predicate">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>
                
                <xsl:choose>
                    <xsl:when test="$results">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', $predicate, $results)" mode="ac:label"/>
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
    </xsl:template>
    
    <!-- PAGER -->

    <xsl:template name="bs2:PagerList">
        <xsl:param name="result-count" as="xs:integer?"/>
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
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

    <!-- BLOCK LIST MODE -->

    <xsl:template match="rdf:RDF" mode="bs2:BlockList" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
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

    <!-- GRID MODE -->

    <xsl:template match="rdf:RDF" mode="bs2:Grid" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
    </xsl:template>

    <!-- TABLE MODE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Table" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
    </xsl:template>

    <!-- GRAPH MODE -->

    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <xsl:apply-templates select="." mode="ac:SVG">
            <xsl:with-param name="width" select="'100%'"/>
            <xsl:with-param name="step-count" select="5"/>
            <xsl:with-param name="spring-length" select="100" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- do not show system named graph resources with provenance metadata as SVG nodes, also hide links to them -->
    <xsl:template match="*[starts-with(@rdf:about, resolve-uri('graphs/', xs:string($ldt:base)))] | void:inDataset[starts-with(@rdf:resource, resolve-uri('graphs/', xs:string($ldt:base)))] | @rdf:resource[starts-with(., resolve-uri('graphs/', xs:string($ldt:base)))]" mode="ac:SVG" priority="1"/>

    <!-- MAP MODE -->

    <!-- TO-DO: improve match pattern -->
    <xsl:template match="rdf:RDF[resolve-uri('geo/', $ldt:base) = $ac:uri]" mode="bs2:Map" priority="1">
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
                    <root statement="new SPARQLMap.Geo(window.LinkedDataHub['{$content-uri}'].map, new URL('{$endpoint}'), `{$select-string}`, '{$focus-var-name}', '{$graph-var-name}')"/>
                </xsl:when>
                <xsl:otherwise>
                    <root statement="new SPARQLMap.Geo(window.LinkedDataHub['{$content-uri}'].map, new URL('{$endpoint}'), `{$select-string}`, '{$focus-var-name}')"/>
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

    <!-- CHART MODE -->

    <!-- graph chart (for RDF/XML results) -->

    <xsl:template match="rdf:RDF" mode="bs2:Chart" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" select="distinct-values(*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <xsl:param name="canvas-id" as="xs:string"/>

        <xsl:apply-templates select="." mode="bs2:ChartForm">
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:apply-templates>

        <div id="{$canvas-id}"></div>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="bs2:ChartForm" use-when="system-property('xsl:product-name') eq 'Saxon-JS'" priority="-1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="resolve-uri('ns#ChartItem', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="type" select="resolve-uri('ns/domain/default#GraphChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <!-- table is the default chart type -->
        <xsl:param name="chart-type" select="if (ixsl:query-params()?chart-type) then xs:anyURI(ixsl:query-params()?chart-type) else xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" select="ixsl:query-params()?category" as="xs:string?"/>
        <xsl:param name="series" select="ixsl:query-params()?series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <!-- <xsl:param name="mode" as="xs:anyURI*"/> -->
        <xsl:param name="service" select="xs:anyURI(ixsl:query-params()?service)" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>
        <xsl:param name="show-save" select="ixsl:contains(ixsl:window(), 'LinkedDataHub.select-uri')" as="xs:boolean"/>

        <xsl:if test="$show-controls">
            <form method="{$method}" action="{$action}">
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$accept-charset">
                    <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$enctype">
                    <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
                </xsl:if>

                <fieldset>
                    <xsl:if test="$show-save">
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'rdf'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'sb'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'chart'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&rdf;type'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="$type"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&spin;query'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-uri')"/> <!-- SELECT URI -->
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ob'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'this'"/>
                        </xsl:call-template>

                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&apl;service'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="resolve-uri('sparql', $ldt:base)"/>
                        </xsl:call-template>
                    </xsl:if>

                    <div class="row-fluid">
                        <div class="span4">
                            <xsl:if test="$show-save">
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'pu'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="'&apl;chartType'"/>
                                </xsl:call-template>
                            </xsl:if>

                            <label for="{$chart-type-id}">
                                <xsl:value-of use-when="system-property('xsl:product-name') = 'SAXON'">
                                    <xsl:apply-templates select="key('resources', '&apl;chartType', document('&apl;'))" mode="ac:label"/>
                                </xsl:value-of>
                                <xsl:value-of use-when="system-property('xsl:product-name') eq 'Saxon-JS'">Chart type</xsl:value-of>
                            </label>
                            <br/>
                            <!-- TO-DO: replace with xsl:apply-templates on ac:Chart subclasses as in imports/apl.xsl -->
                            <select id="{$chart-type-id}" name="ou" class="input-medium chart-type">
                                <option value="&ac;Table">
                                    <xsl:if test="$chart-type = '&ac;Table'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Table</xsl:text>
                                </option>
                                <option value="&ac;ScatterChart">
                                    <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Scatter chart</xsl:text>
                                </option>
                                <option value="&ac;LineChart">
                                    <xsl:if test="$chart-type = '&ac;LineChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Line chart</xsl:text>
                                </option>
                                <option value="&ac;BarChart">
                                    <xsl:if test="$chart-type = '&ac;BarChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Bar chart</xsl:text>
                                </option>
                                <option value="&ac;Timeline">
                                    <xsl:if test="$chart-type = '&ac;Timeline'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Timeline</xsl:text>
                                </option>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:if test="$show-save">
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'pu'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="'&apl;categoryProperty'"/>
                                </xsl:call-template>
                            </xsl:if>

                            <label for="{$category-id}">Category</label>
                            <br/>
                            <select id="{$category-id}" name="ou" class="input-large chart-category">
                                <option value="">
                                    <!-- URI is the default category -->
                                    <xsl:if test="not($category)">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>[URI/ID]</xsl:text>
                                </option>

                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'Saxon-JS'"/>

                                    <option value="{current-grouping-key()}">
                                        <xsl:if test="$category = current-grouping-key()">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:value-of>
                                            <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
                                        </xsl:value-of>
                                    </option>
                                </xsl:for-each-group>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:if test="$show-save">
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'pu'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="'&apl;seriesProperty'"/>
                                </xsl:call-template>
                            </xsl:if>

                            <label for="{$series-id}">Series</label>
                            <br/>
                            <select id="{$series-id}" name="ou" multiple="multiple" class="input-large chart-series">
                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'Saxon-JS'"/>

                                    <option value="{current-grouping-key()}">
                                        <xsl:if test="$series = current-grouping-key()">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:value-of>
                                            <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
                                        </xsl:value-of>
                                    </option>
                                </xsl:for-each-group>
                            </select>
                        </div>
                    </div>
                    <xsl:if test="$show-save">
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&dct;title'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="id" select="'chart-title'"/>
                            <xsl:with-param name="name" select="'ol'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ob'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'this'"/>
                        </xsl:call-template>

                        <!-- ChartItem -->

                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'sb'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'this'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&sioc;has_container'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="resolve-uri('charts/', $ldt:base)"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&dct;title'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="id" select="'chart-doc-title'"/>
                            <xsl:with-param name="name" select="'ol'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&rdf;type'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="$doc-type"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ob'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'chart'"/>
                        </xsl:call-template>
                    </xsl:if>
                </fieldset>
                <xsl:if test="$show-save">
                    <div class="form-actions">
                        <button class="btn btn-primary btn-save-chart" type="submit">
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                            </xsl:apply-templates>
                        </button>
                    </div>
                </xsl:if>
            </form>
        </xsl:if>
    </xsl:template>

    <!-- table chart (for SPARQL XML results) -->

    <xsl:template match="srx:sparql" mode="bs2:Chart" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" select="srx:head/srx:variable[1]/@name" as="xs:string?"/>
        <xsl:param name="series" select="srx:head/srx:variable/@name" as="xs:string*"/>
        <xsl:param name="canvas-id" as="xs:string"/>

        <xsl:apply-templates select="." mode="bs2:ChartForm">
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:apply-templates>

        <div id="{$canvas-id}"></div>
    </xsl:template>

    <xsl:template match="srx:sparql" mode="bs2:ChartForm" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="resolve-uri('ns#ChartItem', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="type" select="resolve-uri('ns/domain/default#ResultSetChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <!-- table is the default chart type -->
        <xsl:param name="chart-type" select="if (ixsl:query-params()?chart-type) then xs:anyURI(ixsl:query-params()?chart-type) else xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" select="ixsl:query-params()?category" as="xs:string?"/>
        <xsl:param name="series" select="ixsl:query-params()?series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" select="xs:anyURI(ixsl:query-params()?service)" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>
        <xsl:param name="show-save" select="ixsl:contains(ixsl:window(), 'LinkedDataHub.select-uri')" as="xs:boolean"/>

        <xsl:if test="$show-controls">
            <form method="{$method}" action="{$action}">
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$accept-charset">
                    <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$enctype">
                    <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
                </xsl:if>

                <fieldset>
                    <xsl:if test="$show-save">
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'rdf'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'sb'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'chart'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&rdf;type'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="$type"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&spin;query'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-uri')"/> <!-- SELECT URI -->
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ob'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'this'"/>
                        </xsl:call-template>

                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&apl;service'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="$service"/>
                        </xsl:call-template>
                    </xsl:if>

                    <div class="row-fluid">
                        <div class="span4">
                            <xsl:if test="$show-save">
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'pu'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="'&apl;chartType'"/>
                                </xsl:call-template>
                            </xsl:if>

                            <label for="{$chart-type-id}">
                                <xsl:value-of use-when="system-property('xsl:product-name') = 'SAXON'">
                                    <xsl:apply-templates select="key('resources', '&apl;chartType', document('&apl;'))" mode="ac:label"/>
                                </xsl:value-of>
                                <xsl:value-of use-when="system-property('xsl:product-name') eq 'Saxon-JS'">Chart type</xsl:value-of>
                            </label>
                            <br/>
                            <select id="{$chart-type-id}" name="ou" class="input-medium chart-type">
                                <option value="&ac;Table">
                                    <xsl:if test="$chart-type = '&ac;Table'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Table</xsl:text>
                                </option>
                                <option value="&ac;ScatterChart">
                                    <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Scatter chart</xsl:text>
                                </option>
                                <option value="&ac;LineChart">
                                    <xsl:if test="$chart-type = '&ac;LineChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Line chart</xsl:text>
                                </option>
                                <option value="&ac;BarChart">
                                    <xsl:if test="$chart-type = '&ac;BarChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Bar chart</xsl:text>
                                </option>
                                <option value="&ac;Timeline">
                                    <xsl:if test="$chart-type = '&ac;Timeline'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>

                                    <xsl:text>Timeline</xsl:text>
                                </option>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;categoryVarName'"/>
                            </xsl:call-template>

                            <label for="{$category-id}">Category</label>
                            <br/>
                            <select id="{$category-id}" name="ol" class="input-large chart-category">
                                <xsl:for-each select="srx:head/srx:variable">
                                    <!-- leave the original variable order so it can be controlled from query -->

                                    <option value="{@name}">
                                        <xsl:if test="$category = @name">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:value-of select="@name"/>
                                    </option>
                                </xsl:for-each>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:if test="$show-save">
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'pu'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="'&apl;seriesVarName'"/>
                                </xsl:call-template>
                            </xsl:if>

                            <label for="{$series-id}">Series</label>
                            <br/>
                            <select id="{$series-id}" name="ol" multiple="multiple" class="input-large chart-series">
                                <xsl:for-each select="srx:head/srx:variable">
                                    <!-- leave the original variable order so it can be controlled from query -->

                                    <option value="{@name}">
                                        <xsl:if test="$series = @name">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:value-of select="@name"/>
                                    </option>
                                </xsl:for-each>
                            </select>
                        </div>
                    </div>
                    
                    <xsl:if test="$show-save">
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&dct;title'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="id" select="'chart-title'"/>
                            <xsl:with-param name="name" select="'ol'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ob'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'this'"/>
                        </xsl:call-template>

                        <!-- ChartItem -->

                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'sb'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'this'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&dct;title'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="id" select="'chart-doc-title'"/>
                            <xsl:with-param name="name" select="'ol'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&rdf;type'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ou'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="$doc-type"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
                        </xsl:call-template>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ob'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'chart'"/>
                        </xsl:call-template>
                    </xsl:if>
                </fieldset>
                <xsl:if test="$show-save">
                    <div class="form-actions">
                        <button class="btn btn-primary btn-save-chart" type="submit">
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                            </xsl:apply-templates>
                        </button>
                    </div>
                </xsl:if>
            </form>
        </xsl:if>
    </xsl:template>

    <!-- container state rendering -->
    
    <xsl:function name="ac:transform-query" as="document-node()">
        <xsl:param name="state" as="map(xs:string, item()?)"/>
        <xsl:param name="select-query" as="document-node()"/>

        <xsl:message select="'State type: ' || map:get($state, '&rdf;type')"/>
        
        <xsl:document>
            <xsl:choose>
                <xsl:when test="map:get($state, '&rdf;type') = '&ac;Limit'">
                    <xsl:apply-templates select="$select-query" mode="apl:replace-limit">
                        <xsl:with-param name="limit" select="xs:integer(map:get($state, '&rdf;value'))" as="xs:integer" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="map:get($state, '&rdf;type') = '&ac;Offset'">
                    <xsl:apply-templates select="$select-query" mode="apl:replace-offset">
                        <xsl:with-param name="offset" select="xs:integer(map:get($state, '&rdf;value'))" as="xs:integer" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="map:get($state, '&rdf;type') = '&ac;OrderBy'">
                    <xsl:apply-templates select="$select-query" mode="apl:replace-order-by">
                        <xsl:with-param name="var-name" select="map:get($state, '&rdf;value')" as="xs:string" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="map:get($state, '&rdf;type') = '&ac;Desc'">
                    <xsl:apply-templates select="$select-query" mode="apl:toggle-desc">
                        <xsl:with-param name="desc" select="xs:boolean(map:get($state, '&rdf;value'))" as="xs:boolean" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="map:get($state, '&rdf;type') = '&ac;FilterIn'">
                    <xsl:apply-templates select="$select-query" mode="apl:filter-in">
                        <xsl:with-param name="var-name" select="map:get($state, '&spl;predicate')" as="xs:string" tunnel="yes"/>
                        <xsl:with-param name="values" select="map:get($state, '&rdf;value')" as="array(map(xs:string, xs:string))" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="map:get($state, '&rdf;type') = '&ac;Parallax'">
                    <xsl:apply-templates select="$select-query" mode="apl:add-parallax-step">
                        <xsl:with-param name="predicate" select="xs:anyURI(map:get($state, '&rdf;value'))" as="xs:anyURI" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message error-code="apl:UnknownStateType" terminate="yes">
                        Unknown state type '<xsl:value-of select="map:get($state, '&rdf;type')"/>'
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:document>
    </xsl:function>
    
    <xsl:template name="apl:push-state">
        <xsl:param name="new-state" as="map(xs:string, item()?)"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <!-- we need to escape the backslashes with replace() before passing the JSON string to JSON.parse() -->
        <xsl:variable name="select-json-string" select="replace(xml-to-json($select-xml), '\\', '\\\\')" as="xs:string"/>
        <!-- push the latest state into history -->
        <xsl:variable name="js-statement" as="element()">
            <xsl:variable name="state-json-string" select="serialize($new-state, map { 'method': 'json' })" as="xs:string"/>
            <root statement="history.pushState({{ '&ldt;arg': JSON.parse('{$state-json-string}'), '&spin;query': JSON.parse('{$select-json-string}') }}, '')"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template name="apl:RenderContainer">
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="content" as="element()"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="service" as="element()?"/>
        <xsl:param name="focus-var-name" as="xs:string"/>

        <!--<ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>-->
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="apl:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge($params, map{ 'auth_token': $service/dydra-urn:accessToken }) else $params)" as="xs:anyURI"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad">
                <xsl:with-param name="container-id" select="$container-id"/>
                <xsl:with-param name="content-uri" select="$content-uri"/>
                <xsl:with-param name="content" select="$content"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->
    
    <!-- popstate -->
    
    <xsl:template match="." mode="ixsl:onpopstate">
        <xsl:variable name="state" select="ixsl:get(ixsl:event(), 'state')"/>
        <xsl:variable name="select-json" select="map:get($state, '&spin;query')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="select-xml" select="json-to-xml($select-json-string)"/>
            <!-- <xsl:param name="focus-var-name" as="xs:string"/> -->
        </xsl:call-template>
    </xsl:template>

    <!-- container mode tabs -->
    
    <xsl:template match="*[tokenize(@class, ' ') = 'resource-content']/div/ul[@class = 'nav nav-tabs']/li/a" mode="ixsl:onclick">
        <xsl:variable name="container-id" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']/input[@name = 'href']/@value" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="active-class" select="../@class" as="xs:string"/>
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>

        <!--<ixsl:set-property name="active-class" select="$active-class" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri)"/>-->

        <xsl:call-template name="render-container">
            <xsl:with-param name="container-id" select="$container-id"/>
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
        <xsl:variable name="container-id" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']/input[@name = 'href']/@value" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <!-- descrease OFFSET to get the previous page -->
        <xsl:variable name="offset" select="$offset - $page-size" as="xs:integer"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>

        <xsl:variable name="new-state" as="map(xs:string, item()?)">
            <xsl:map>
                <xsl:map-entry key="'&rdf;type'" select="'&ac;Offset'"/>
                <xsl:map-entry key="'&spl;predicate'" select="'&ac;offset'"/>
                <xsl:map-entry key="'&rdf;value'" select="$offset"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="select-xml" select="ac:transform-query($new-state, $select-xml)" as="document-node()"/>
        <xsl:call-template name="apl:push-state">
            <xsl:with-param name="new-state" select="$new-state" as="map(xs:string, item()?)"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
        </xsl:call-template>
    </xsl:template>

    <!-- pager next links -->
    
    <xsl:template match="*[tokenize(@class, ' ') = 'resource-content']//ul[@class = 'pager']/li[@class = 'next']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="container-id" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="ancestor::div[tokenize(@class, ' ') = 'resource-content']/input[@name = 'href']/@value" as="xs:anyURI"/>
        <xsl:variable name="content" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'content')" as="element()"/>
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="offset" select="if ($select-xml/json:map/json:number[@key = 'offset']) then xs:integer($select-xml/json:map/json:number[@key = 'offset']) else 0" as="xs:integer"/>
        <!-- increase OFFSET to get the next page -->
        <xsl:variable name="offset" select="$offset + $page-size" as="xs:integer"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>

        <xsl:variable name="new-state" as="map(xs:string, item()?)">
            <xsl:map>
                <xsl:map-entry key="'&rdf;type'" select="'&ac;Offset'"/>
                <xsl:map-entry key="'&spl;predicate'" select="'&ac;offset'"/>
                <xsl:map-entry key="'&rdf;value'" select="$offset"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="select-xml" select="ac:transform-query($new-state, $select-xml)" as="document-node()"/>
        <xsl:call-template name="apl:push-state">
            <xsl:with-param name="new-state" select="$new-state" as="map(xs:string, item()?)"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="select-string" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'select-query')"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
            <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- order by onchange -->
    
    <xsl:template match="select[@id = 'container-order']" mode="ixsl:onchange">
        <xsl:variable name="content-uri" select="()" as="xs:anyURI?"/> <!-- TO-DO: fix -->
        <xsl:variable name="predicate" select="ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), $content-uri), 'focus-var-name')" as="xs:string"/>
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map[json:string[@key = 'subject'] = '?' || $focus-var-name][json:string[@key = 'predicate'] = $predicate][starts-with(json:string[@key = 'object'], '?')]" as="element()*"/>
        <xsl:variable name="var-name" select="$bgp-triples-map/json:string[@key = 'object'][1]/substring-after(., '?')" as="xs:string?"/>
        
        <xsl:variable name="new-state" as="map(xs:string, item()?)">
            <xsl:map>
                <xsl:map-entry key="'&rdf;type'" select="'&ac;OrderBy'"/>
                <xsl:map-entry key="'&spl;predicate'" select="'&ac;orderBy'"/>
                <xsl:map-entry key="'&rdf;value'" select="$var-name"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="select-xml" select="ac:transform-query($new-state, $select-xml)" as="document-node()"/>
        <xsl:call-template name="apl:push-state">
            <xsl:with-param name="new-state" select="$new-state" as="map(xs:string, item()?)"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- ascending/descending onclick -->
    
    <!-- TO-DO: unify with container ORDER BY onchange -->
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-order-by']" mode="ixsl:onclick">
        <xsl:variable name="desc" select="contains(@class, 'btn-order-by-desc')" as="xs:boolean"/>
        <!-- retrieve SELECT query history.state -->
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <!-- history.pushState() state objects cannot contain elements, therefore we are converting the query to JSON before pushing -->
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)"/>

        <xsl:variable name="new-state" as="map(xs:string, item()?)">
            <xsl:map>
                <xsl:map-entry key="'&rdf;type'" select="'&ac;Desc'"/>
                <xsl:map-entry key="'&spl;predicate'" select="'&ac;desc'"/>
                <xsl:map-entry key="'&rdf;value'" select="not($desc)"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="select-xml" select="ac:transform-query($new-state, $select-xml)" as="document-node()"/>
        <xsl:call-template name="apl:push-state">
            <xsl:with-param name="new-state" select="$new-state" as="map(xs:string, item()?)"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        
        <!-- toggle the arrow direction -->
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-order-by-desc' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- facet header on click -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//*[tokenize(@class, ' ') = 'nav-header']" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'faceted-nav']" as="element()"/>
        <xsl:variable name="subject-var-name" select="input[@name = 'subject']/@value" as="xs:string"/>
        <xsl:variable name="predicate" select="input[@name = 'predicate']/@value" as="xs:anyURI"/>
        <xsl:variable name="object-var-name" select="input[@name = 'object']/@value" as="xs:string"/>
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
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

                    <xsl:variable name="container-id" select="@id" as="xs:string"/>
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
                    <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge($params, map{ 'auth_token': $service/dydra-urn:accessToken }) else $params)" as="xs:anyURI"/>

                    <!-- load facet values, their counts and optional labels -->
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                        <xsl:call-template name="onFacetValueResultsLoad">
                            <xsl:with-param name="container-id" select="$container-id"/>
                            <xsl:with-param name="predicate" select="$predicate"/>
                            <xsl:with-param name="object-var-name" select="$object-var-name"/>
                            <xsl:with-param name="count-var-name" select="$count-var-name"/>
                            <xsl:with-param name="label-sample-var-name" select="$label-sample-var-name"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
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
    
    <xsl:template name="onFacetValueResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
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
                                <xsl:for-each select="$results//srx:result[srx:binding[@name = $object-var-name]]">
                                    <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
                                        <ul class="well well-small nav nav-list"></ul>
                                    </xsl:result-document>
                                
                                    <xsl:variable name="object-type" select="srx:binding[@name = $object-var-name]/srx:uri" as="xs:anyURI"/>
                                    <xsl:variable name="value-result" select="." as="element()"/>
                                    <xsl:variable name="results-uri" select="ac:build-uri($ldt:base, map{ 'uri': $object-type, 'accept': 'application/rdf+xml', 'mode': 'fragment' })" as="xs:anyURI"/>

                                    <!-- load the label of the object type -->
                                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                        <xsl:call-template name="onFacetValueTypeLoad">
                                            <xsl:with-param name="container-id" select="$container-id"/>
                                            <xsl:with-param name="object-var-name" select="$object-var-name"/>
                                            <xsl:with-param name="count-var-name" select="$count-var-name"/>
                                            <xsl:with-param name="object-type" select="$object-type"/>
                                            <xsl:with-param name="value-result" select="$value-result"/>
                                        </xsl:call-template>
                                    </ixsl:schedule-action>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- toggle the caret direction -->
                                <xsl:for-each select="id($container-id, ixsl:page())/h2/span[tokenize(@class, ' ') = 'caret']">
                                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                                </xsl:for-each>
                
                                <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
                                    <ul class="well well-small nav nav-list">
                                        <xsl:apply-templates select="$results//srx:result[srx:binding[@name = $object-var-name]]" mode="bs2:FacetValueItem">
                                            <!-- order by count first -->
                                            <xsl:sort select="xs:integer(srx:binding[@name = $count-var-name]/srx:literal)" order="descending"/>
                                            <!-- order by label second -->
                                            <xsl:sort select="srx:binding[@name = $label-sample-var-name]/srx:literal"/>
                                            <xsl:sort select="srx:binding[@name = $object-var-name]/srx:*"/>

                                            <xsl:with-param name="container-id" select="$container-id"/>
                                            <xsl:with-param name="object-var-name" select="$object-var-name"/>
                                            <xsl:with-param name="count-var-name" select="$count-var-name"/>
                                            <xsl:with-param name="label-sample-var-name" select="$label-sample-var-name"/>
                                        </xsl:apply-templates>
                                    </ul>
                                </xsl:result-document>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
                <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
                    <div class="alert alert-block">
                        <strong>Error during query execution:</strong>
                        <pre>
                            <xsl:value-of select="$response?message"/>
                        </pre>
                    </div>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- done loading, restore normal cursor -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template match="srx:result" mode="bs2:FacetValueItem">
        <xsl:param name="container-id" as="xs:string"/>
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
    
    <xsl:template name="onFacetValueTypeLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:param name="count-var-name" as="xs:string"/>
        <xsl:param name="object-type" as="xs:anyURI"/>
        <xsl:param name="value-result" as="element()"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        
        <xsl:variable name="results" select="if (?status = 200 and ?media-type = 'application/rdf+xml') then ?body else ()" as="document-node()?"/>
        <xsl:variable name="existing-items" select="id($container-id, ixsl:page())/ul/li" as="element()*"/>
        <xsl:variable name="new-item" as="element()">
            <xsl:apply-templates select="$value-result" mode="bs2:FacetValueItem">
                <xsl:with-param name="container-id" select="$container-id"/>
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

        <xsl:for-each select="id($container-id, ixsl:page())/ul">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="$items"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- facet onchange -->

    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//input[@type = 'checkbox']" mode="ixsl:onchange">
        <xsl:variable name="var-name" select="@name" as="xs:string"/>
        <!-- collect the values/types/datatypes of all checked inputs within this facet and build an array of maps -->
        <xsl:variable name="labels" select="ancestor::ul//label[input[@type = 'checkbox'][ixsl:get(., 'checked')]]" as="element()*"/>
        <xsl:variable name="values" select="array { for $label in $labels return map { 'value' : string($label/input[@type = 'checkbox']/@value), 'type': string($label/input[@name = 'type']/@value), 'datatype': string($label/input[@name = 'datatype']/@value) } }" as="array(map(xs:string, xs:string))"/>
        <!-- retrieve SELECT query history.state -->
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <!-- history.pushState() state objects cannot contain elements, therefore we are converting the query to JSON before pushing -->
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)"/>

        <xsl:variable name="new-state" as="map(xs:string, item()?)">
            <xsl:map>
                <xsl:map-entry key="'&rdf;type'" select="'&ac;FilterIn'"/>
                <xsl:map-entry key="'&spl;predicate'" select="$var-name"/>
                <xsl:map-entry key="'&rdf;value'" select="$values"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="select-xml" select="ac:transform-query($new-state, $select-xml)" as="document-node()"/>
        <xsl:call-template name="apl:push-state">
            <xsl:with-param name="new-state" select="$new-state" as="map(xs:string, item()?)"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
    </xsl:template>

    <!-- parallax onclick -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'parallax-nav']/ul/li/a" mode="ixsl:onclick">
        <xsl:variable name="container-id" select="ancestor::div[tokenize(@class, ' ') = 'right-nav']/preceding-sibling::div[tokenize(@class, ' ') = 'resource-content']/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="ancestor::div[tokenize(@class, ' ') = 'right-nav']/preceding-sibling::div[tokenize(@class, ' ') = 'resource-content']/input[@name = 'href']/@value" as="xs:anyURI"/>
        <xsl:variable name="predicate" select="input/@value" as="xs:anyURI"/>
        <!-- retrieve SELECT query history.state -->
        <xsl:variable name="select-json" select="ixsl:eval('history.state[''&spin;query'']')"/>
        <!-- history.pushState() state objects cannot contain elements, therefore we are converting the query to JSON before pushing -->
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)"/>

        <xsl:variable name="new-state" as="map(xs:string, item()?)">
            <xsl:map>
                <xsl:map-entry key="'&rdf;type'" select="'&ac;Parallax'"/>
                <xsl:map-entry key="'&spl;predicate'" select="'&ac;predicate'"/>
                <xsl:map-entry key="'&rdf;value'" select="$predicate"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="select-xml" select="ac:transform-query($new-state, $select-xml)" as="document-node()"/>
        <xsl:call-template name="apl:push-state">
            <xsl:with-param name="new-state" select="$new-state" as="map(xs:string, item()?)"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
        <xsl:call-template name="apl:RenderContainer">
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="container-id" select="$container-id"/>
            <xsl:with-param name="select-xml" select="$select-xml"/>
        </xsl:call-template>
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
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, let $params := map{ 'query': $query-string } return if ($service/dydra-urn:accessToken) then map:merge($params, map{ 'auth_token': $service/dydra-urn:accessToken }) else $params)" as="xs:anyURI"/>

        <!-- load result count -->
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
            <xsl:call-template name="apl:ResultCountResultsLoad">
                <xsl:with-param name="container-id" select="'result-counts'"/>
                <xsl:with-param name="count-var-name" select="$count-var-name"/>
            </xsl:call-template>
        </ixsl:schedule-action>
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