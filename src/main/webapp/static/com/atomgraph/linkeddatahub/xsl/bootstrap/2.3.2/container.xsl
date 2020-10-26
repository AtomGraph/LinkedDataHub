<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
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
    <!ENTITY void   "http://rdfs.org/ns/void#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
xmlns:geo="&geo;"
xmlns:void="&void;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:saxon="http://saxon.sf.net/"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- PARALLAX -->
    
    <xsl:template name="bs2:Parallax">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'sidebar-nav parallax-nav'" as="xs:string?"/>
        <xsl:param name="results" as="document-node()"/>
        
        <xsl:result-document href="#parallax-nav" method="ixsl:replace-content">
            <!-- only show if the result contains object resources -->
            <xsl:if test="$results/rdf:RDF/*/*[@rdf:resource]"> <!-- can't use bnodes because labels accross DESCRIBE and SELECT results won't match -->
                <div>
                    <xsl:if test="$id">
                        <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                    </xsl:if>
                    <xsl:if test="$class">
                        <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                    </xsl:if>

                    <h2 class="nav-header btn">Navigation</h2>

                    <ul class="well well-small nav nav-list" id="parallax-properties">
                        <!-- <li> with properties will go here -->
                    </ul>
                </div>
            </xsl:if>
        </xsl:result-document>
        
        <xsl:if test="$results/rdf:RDF/*/*[@rdf:resource or @rdf:nodeID]">
            <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
            <xsl:variable name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))" as="xs:integer"/>
            <xsl:variable name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))" as="xs:integer"/>
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:variable name="var-name" select="substring-after(ixsl:get(ixsl:call($select-builder, 'build', []), 'variables')[1], '?')"/>
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:call($select-builder, 'limit', [ $limit ]), 'offset', [ $offset ])"/>
            <xsl:variable name="query-string" select="ixsl:call($select-builder, 'toString', [])" as="xs:string"/>
            <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
            <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
            <!-- TO-DO: unify dydra: and dydra-urn: ? -->
            <xsl:variable name="results-uri" select="xs:anyURI(if ($service/dydra-urn:accessToken) then ($endpoint || '?auth_token=' || $service/dydra-urn:accessToken || '&amp;query=' || encode-for-uri($query-string)) else ($endpoint || '?query=' || encode-for-uri($query-string)))" as="xs:anyURI"/>

            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                <xsl:call-template name="onParallaxSelectLoad">
                    <xsl:with-param name="container-id" select="'parallax-properties'"/>
                    <xsl:with-param name="var-name" select="$var-name"/>
                    <xsl:with-param name="results" select="$results"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:if>
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
                        <xsl:call-template name="parallax-property-load-despatch">
                            <xsl:with-param name="container-id" select="$container-id"/>
                        </xsl:call-template>
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
    
    <!-- need a separate template due to Saxon-JS bug: https://saxonica.plan.io/issues/4767 -->
    <xsl:template name="parallax-property-load-despatch">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="predicate" select="xs:anyURI(concat(namespace-uri(), local-name()))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="resolve-uri('?uri=' || encode-for-uri($predicate) || '&amp;accept=' || encode-for-uri('application/rdf+xml') || '&amp;mode=' || encode-for-uri('fragment'), $ldt:base)" as="xs:anyURI"/>
        
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onParallaxPropertyLoad">
                <xsl:with-param name="container-id" select="$container-id"/>
                <xsl:with-param name="predicate" select="$predicate"/>
            </xsl:call-template>
        </ixsl:schedule-action>
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
                            <xsl:apply-templates select="key('resources', $predicate, $results)" mode="ac:label"/>
                        </xsl:when>
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
        <xsl:param name="predicate" as="xs:anyURI"/>
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
                            <xsl:apply-templates select="key('resources', $predicate, $results)" mode="ac:label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$predicate"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <span class="caret pull-right"></span>
                    <input type="hidden" name="bgp-id" value="{$id}"/>
                </h2>

                <!-- facet values will be loaded into an <ul> here -->
            </div>
        </xsl:result-document>
    </xsl:template>

    <!-- PAGER -->

    <xsl:template name="bs2:PagerList">
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean?"/>
        <xsl:param name="result-count" as="xs:integer?"/>
        <xsl:param name="show" select="($offset - $limit) &gt;= 0 or $result-count &gt;= $limit" as="xs:boolean"/>

        <!-- do not show pagination if the children document count is less than the page limit -->
        <xsl:if test="$show">
            <ul class="pager">
                <li class="previous">
                    <xsl:choose>
                        <xsl:when test="($offset - $limit) &gt;= 0">
                            <a class="active">
                                <!-- only set hyperlink on server-side - client-side will use event listener to avoid page refresh -->
                                <xsl:variable name="href" select="xs:anyURI(concat($ac:uri, '?limit=', $limit, '&amp;offset=', $offset - $limit, if ($order-by) then concat('&amp;order-by=', $order-by) else (), if ($desc) then concat('&amp;desc=', $desc) else ()))" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:attribute name="href" select="$href" use-when="system-property('xsl:product-name') = 'SAXON'"/>
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
                                <!-- only set hyperlink on server-side - client-side will use event listener to avoid page refresh -->
                                <xsl:variable name="href" select="xs:anyURI(concat($ac:uri, '?limit=', $limit, '&amp;offset=', $offset + $limit, if ($order-by) then concat('&amp;order-by=', $order-by) else (), if ($desc) then concat('&amp;desc=', $desc) else ()))" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:attribute name="href" select="$href" use-when="system-property('xsl:product-name') = 'SAXON'"/>
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
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
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

            <xsl:apply-templates select="." mode="bs2:Actions"/>

            <xsl:apply-templates select="." mode="bs2:TypeList"/>

            <xsl:apply-templates select="." mode="apl:logo">
                <xsl:with-param name="class" select="'well'"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="xhtml:Anchor"/>

            <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="bs2:Header">
                <xsl:with-param name="class" select="'well well-small'"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <xsl:template match="*[key('resources', foaf:isPrimaryTopicOf/@rdf:resource)]" mode="bs2:BlockList" priority="1"/>

    <xsl:template match="*[*][@rdf:*[local-name() = ('about', 'nodeID')]]" mode="bs2:BlockList" priority="0.8">
        <xsl:apply-templates select="." mode="bs2:Header"/>
    </xsl:template>

    <!-- GRID MODE -->

    <xsl:template match="rdf:RDF" mode="bs2:Grid" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
    </xsl:template>

    <!-- TABLE MODE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Table" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>

        <xsl:next-match/>

        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
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
        <xsl:param name="canvas-id" select="'map-canvas'" as="xs:string"/>

        <div id="{$canvas-id}"></div>
    </xsl:template>

    <xsl:function name="ac:create-map">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="lat" as="xs:float"/>
        <xsl:param name="lng" as="xs:float"/>
        <xsl:param name="zoom" as="xs:integer"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.maps.Map(document.getElementById('{$id}'), {{ center: new google.maps.LatLng({$lat}, {$lng}), zoom: {$zoom} }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:template name="create-google-map">
        <xsl:param name="map"/>

        <ixsl:set-property name="map" select="$map" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>

    <xsl:function name="ac:create-geo-object">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="item-var-name" as="xs:string"/>

        <!-- set ?this value -->
        <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <xsl:variable name="js-statement" as="element()">
            <!-- TO-DO: move Geo under AtomGraph namespace -->
            <!-- use template literals because the query is multi-line https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals -->
            <root statement="new SPARQLMap.Geo(window.LinkedDataHub.map, new URL('{$endpoint}'), `{$select-string}`, '{$item-var-name}')"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:template name="create-geo-object">
        <xsl:param name="geo"/>

        <ixsl:set-property name="geo" select="$geo" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>

    <xsl:template name="add-geo-listener">
        <xsl:variable name="js-statement" as="element()">
            <root statement="window.LinkedDataHub.map.addListener('idle', function() {{ window.LinkedDataHub.geo.loadMarkers(window.LinkedDataHub.geo.addMarkers); }})"/> <!-- use template literal because the query string is multi-line -->
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:template>

    <!-- CHART MODE -->

    <!-- graph chart (for RDF/XML results) -->

    <xsl:template match="rdf:RDF" mode="bs2:Chart" use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" select="distinct-values(*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <!-- <xsl:param name="endpoint" as="xs:anyURI"/> -->
        <xsl:param name="canvas-id" select="'chart-canvas'" as="xs:string"/>

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
        <xsl:param name="type" select="resolve-uri('ns/default#GraphChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="action" select="resolve-uri(concat('charts/?forClass=', encode-for-uri(resolve-uri($type, $ldt:base))), $ldt:base)" as="xs:anyURI"/>
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

<!--                    <div class="row-fluid">
                        <div class="span12">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;endpoint'"/>
                            </xsl:call-template>

                            <label for="endpoint-uri">Endpoint</label>
                            <xsl:text> </xsl:text>
                                <select id="endpoint-uri" name="ou" class="input-xxlarge">
                                    <option value="{resolve-uri('sparql', $ldt:base)}">[SPARQL endpoint]</option>

                                    <xsl:for-each select="document(resolve-uri('services/', $ldt:base))//*[sd:endpoint/@rdf:resource]" use-when="system-property('xsl:product-name') = 'SAXON'">
                                        <xsl:sort select="ac:label(.)"/>

                                        <xsl:apply-templates select="." mode="xhtml:Option">
                                            <xsl:with-param name="value" select="sd:endpoint/@rdf:resource"/>
                                            <xsl:with-param name="selected" select="sd:endpoint/@rdf:resource = $endpoint"/>
                                        </xsl:apply-templates>
                                    </xsl:for-each>
                                    <xsl:if test="true()"  use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
                                        <xsl:variable name="query" select="'DESCRIBE ?service { GRAPH ?g { ?service &lt;&sd;endpoint&gt; ?endpoint } }'"/>
                                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': resolve-uri(concat('sparql?query=', encode-for-uri($query)), $ldt:base), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                            <xsl:call-template name="onchartModeServiceLoad"/>
                                        </ixsl:schedule-action>
                                    </xsl:if>
                            </select>
                        </div>
                    </div>-->
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
                                <xsl:apply-templates select="key('resources', '&apl;chartType', document('&apl;'))" mode="ac:label" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:value-of use-when="system-property('xsl:product-name') eq 'Saxon-JS'">Chart type</xsl:value-of>
                            </label>
                            <br/>
                            <!-- TO-DO: replace with xsl:apply-templates on ac:Chart subclasses as in imports/apl.xsl -->
                            <select id="{$chart-type-id}" name="ou" class="input-medium">
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
                            <select id="{$category-id}" name="ou" class="input-large">
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

                                        <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
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
                            <select id="{$series-id}" name="ou" multiple="multiple" class="input-large">
                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'Saxon-JS'"/>

                                    <option value="{current-grouping-key()}">
                                        <xsl:if test="$series = current-grouping-key()">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
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
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" select="srx:head/srx:variable/@name" as="xs:string*"/>
        <!-- <xsl:param name="endpoint" as="xs:anyURI"/> -->
        <xsl:param name="canvas-id" select="'chart-canvas'" as="xs:string"/>

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
        <xsl:param name="type" select="resolve-uri('ns/default#ResultSetChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="action" select="resolve-uri(concat('charts/?forClass=', encode-for-uri(resolve-uri($type, $ldt:base))), $ldt:base)" as="xs:anyURI"/>
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

<!--                    <div class="row-fluid">
                        <div class="span12">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;endpoint'"/>
                            </xsl:call-template>

                            <label for="endpoint-uri">Endpoint</label>
                            <xsl:text> </xsl:text>
                                <select id="endpoint-uri" name="ou" class="input-xxlarge">
                                    <option value="{resolve-uri('sparql', $ldt:base)}">[SPARQL endpoint]</option>

                                    <xsl:for-each select="document(resolve-uri('services/', $ldt:base))//*[sd:endpoint/@rdf:resource]" use-when="system-property('xsl:product-name') = 'SAXON'">
                                        <xsl:sort select="ac:label(.)"/>

                                        <xsl:apply-templates select="." mode="xhtml:Option">
                                            <xsl:with-param name="value" select="sd:endpoint/@rdf:resource"/>
                                            <xsl:with-param name="selected" select="sd:endpoint/@rdf:resource = $endpoint"/>
                                        </xsl:apply-templates>
                                    </xsl:for-each>
                                    <xsl:if test="true()"  use-when="system-property('xsl:product-name') eq 'Saxon-JS'">
                                        <xsl:variable name="query" select="'DESCRIBE ?service { GRAPH ?g { ?service &lt;&sd;endpoint&gt; ?endpoint } }'"/>
                                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': resolve-uri(concat('sparql?query=', encode-for-uri($query)), $ldt:base), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                            <xsl:call-template name="onchartModeServiceLoad"/>
                                        </ixsl:schedule-action>
                                    </xsl:if>
                            </select>
                        </div>
                    </div>-->
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
                                <xsl:apply-templates select="key('resources', '&apl;chartType', document('&apl;'))" mode="ac:label" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:value-of use-when="system-property('xsl:product-name') eq 'Saxon-JS'">Chart type</xsl:value-of>
                            </label>
                            <br/>
                            <select id="{$chart-type-id}" name="ou" class="input-medium">
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
                            <select id="{$category-id}" name="ol" class="input-large">
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
                            <select id="{$series-id}" name="ol" multiple="multiple" class="input-large">
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

    <!-- EVENT LISTENERS -->

    <!-- facet header on click -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//*[tokenize(@class, ' ') = 'nav-header']" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[tokenize(@class, ' ') = 'faceted-nav']" as="element()"/>
        <xsl:variable name="bgp-id" select="input[@name = 'bgp-id']/@value" as="xs:string"/>
        <xsl:variable name="select-xml" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-xml')" as="document-node()"/>
        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <xsl:variable name="bgp-triples-map" select="$select-xml//json:map[generate-id() = $bgp-id]" as="element()"/> <!-- TO-DO: use key()? -->

        <!-- is the current facet loaded? -->
        <xsl:variable name="loaded" select="not(empty(following-sibling::ul))" as="xs:boolean"/>
        <xsl:choose>
            <!-- if not, load and render its values -->
            <xsl:when test="not($loaded)">
                <xsl:for-each select="$container">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <xsl:call-template name="render-facet-values-despatch">
                        <xsl:with-param name="bgp-triples-map" select="$bgp-triples-map"/>
                        <xsl:with-param name="select-xml" select="$select-xml"/>
                        <xsl:with-param name="service" select="$service"/>
                    </xsl:call-template>
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
    
    <!-- need a separate template due to Saxon-JS bug: https://saxonica.plan.io/issues/4767 -->
    <xsl:template name="render-facet-values-despatch">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="container-id" select="@id" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="service" as="element()?"/>
        <xsl:param name="bgp-triples-map" as="element()"/>
        <!-- the subject is a variable - trim the leading question mark -->
        <xsl:variable name="subject-var-name" select="substring-after($bgp-triples-map/json:string[@key = 'subject'], '?')" as="xs:string"/>
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
        <xsl:variable name="results-uri" select="xs:anyURI(if ($service/dydra-urn:accessToken) then ($endpoint || '?auth_token=' || $service/dydra-urn:accessToken || '&amp;query=' || encode-for-uri($query-string)) else ($endpoint || '?query=' || encode-for-uri($query-string)))" as="xs:anyURI"/>

        <!-- load facet values, their counts and optional labels -->
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
            <xsl:call-template name="onFacetValueResultsLoad">
                <xsl:with-param name="container-id" select="$container-id"/>
                <xsl:with-param name="object-var-name" select="$object-var-name"/>
                <xsl:with-param name="count-var-name" select="$count-var-name"/>
                <xsl:with-param name="label-sample-var-name" select="$label-sample-var-name"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:bgp-value-counts">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- replace query variables with ?varName (COUNT(DISTINCT ?varName) AS ?countVarName) -->
    <xsl:template match="json:map/json:array[@key = 'variables']" mode="apl:bgp-value-counts" priority="1">
        <xsl:param name="subject-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-sample-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <json:string><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
            <!-- COUNT() of subjects -->
            <json:map>
                <json:map key="expression">
                    <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$subject-var-name"/></json:string>
                    <json:string key="type">aggregate</json:string>
                    <json:string key="aggregation">count</json:string>
                    <json:boolean key="distinct">true</json:boolean>
                </json:map>
                <json:string key="variable"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
            </json:map>
            <!-- SAMPLE() of ?labels -->
            <json:map>
                <json:map key="expression">
                    <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$label-var-name"/></json:string>
                    <json:string key="type">aggregate</json:string>
                    <json:string key="aggregation">sample</json:string>
                    <json:boolean key="distinct">false</json:boolean>
                </json:map>
                <json:string key="variable"><xsl:text>?</xsl:text><xsl:value-of select="$label-sample-var-name"/></json:string>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- add GROUP BY ?varName and ORDER BY DESC(?varName) after the WHERE -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'query']" mode="apl:bgp-value-counts" priority="1">
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="descending" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- TO-DO: will fail on queries with existing GROUP BY -->
            <json:array key="group">
                <json:map>
                    <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                </json:map>
            </json:array>
            <!-- create ORDER BY if it doesn't exist -->
            <xsl:if test="not(json:array[@key = 'order'])">
                <json:array key="order">
                    <json:map>
                        <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
                        <json:boolean key="descending"><xsl:value-of select="$descending"/></json:boolean>
                    </json:map>
                </json:array>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- append OPTIONAL pattern with ?label property paths after the BGP with object var name -->
    <xsl:template match="json:*[json:map[json:string[@key = 'type'] = 'bgp']]" mode="apl:bgp-value-counts" priority="1">
        <xsl:param name="bgp-triples-map" as="element()" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-graph-var-name" select="$label-var-name || 'graph'" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- one of the triple patterns in this BGP equals the one supplied as param - append ?label pattern to this BGP -->
            <xsl:if test="json:map[json:string[@key = 'type'] = 'bgp']//json:map[. is $bgp-triples-map]">
                <json:map>
                    <json:string key="type">optional</json:string>
                    <json:array key="patterns">
                        <json:map>
                            <json:string key="type">union</json:string>
                            <json:array key="patterns">
                                <json:map>
                                    <json:string key="type">bgp</json:string>
                                    <json:array key="triples">
                                        <json:map>
                                            <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                                            <json:map key="predicate">
                                                <json:string key="type">path</json:string>
                                                <json:string key="pathType">|</json:string>
                                                <json:array key="items">
                                                    <json:map>
                                                        <json:string key="type">path</json:string>
                                                        <json:string key="pathType">|</json:string>
                                                        <json:array key="items">
                                                            <json:map>
                                                                <json:string key="type">path</json:string>
                                                                <json:string key="pathType">|</json:string>
                                                                <json:array key="items">
                                                                    <json:map>
                                                                        <json:string key="type">path</json:string>
                                                                        <json:string key="pathType">|</json:string>
                                                                        <json:array key="items">
                                                                            <json:map>
                                                                                <json:string key="type">path</json:string>
                                                                                <json:string key="pathType">|</json:string>
                                                                                <json:array key="items">
                                                                                    <json:map>
                                                                                        <json:string key="type">path</json:string>
                                                                                        <json:string key="pathType">|</json:string>
                                                                                        <json:array key="items">
                                                                                            <json:map>
                                                                                                <json:string key="type">path</json:string>
                                                                                                <json:string key="pathType">|</json:string>
                                                                                                <json:array key="items">
                                                                                                    <json:map>
                                                                                                        <json:string key="type">path</json:string>
                                                                                                        <json:string key="pathType">|</json:string>
                                                                                                        <json:array key="items">
                                                                                                            <json:string>http://www.w3.org/2000/01/rdf-schema#label</json:string>
                                                                                                            <json:string>http://purl.org/dc/elements/1.1/title</json:string>
                                                                                                        </json:array>
                                                                                                    </json:map>
                                                                                                    <json:string>http://purl.org/dc/terms/title</json:string>
                                                                                                </json:array>
                                                                                            </json:map>
                                                                                            <json:string>http://xmlns.com/foaf/0.1/name</json:string>
                                                                                        </json:array>
                                                                                    </json:map>
                                                                                    <json:string>http://xmlns.com/foaf/0.1/givenName</json:string>
                                                                                </json:array>
                                                                            </json:map>
                                                                            <json:string>http://xmlns.com/foaf/0.1/familyName</json:string>
                                                                        </json:array>
                                                                    </json:map>
                                                                    <json:string>http://rdfs.org/sioc/ns#name</json:string>
                                                                </json:array>
                                                            </json:map>
                                                            <json:string>http://www.w3.org/2004/02/skos/core#prefLabel</json:string>
                                                        </json:array>
                                                    </json:map>
                                                    <json:string>http://rdfs.org/sioc/ns#content</json:string>
                                                </json:array>
                                            </json:map>
                                            <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$label-var-name"/></json:string>
                                        </json:map>
                                    </json:array>
                                </json:map>
                                <json:map>
                                    <json:string key="type">graph</json:string>
                                    <json:array key="patterns">
                                        <json:map>
                                            <json:string key="type">bgp</json:string>
                                            <json:array key="triples">
                                                <json:map>
                                                    <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                                                    <json:map key="predicate">
                                                        <json:string key="type">path</json:string>
                                                        <json:string key="pathType">|</json:string>
                                                        <json:array key="items">
                                                            <json:map>
                                                                <json:string key="type">path</json:string>
                                                                <json:string key="pathType">|</json:string>
                                                                <json:array key="items">
                                                                    <json:map>
                                                                        <json:string key="type">path</json:string>
                                                                        <json:string key="pathType">|</json:string>
                                                                        <json:array key="items">
                                                                            <json:map>
                                                                                <json:string key="type">path</json:string>
                                                                                <json:string key="pathType">|</json:string>
                                                                                <json:array key="items">
                                                                                    <json:map>
                                                                                        <json:string key="type">path</json:string>
                                                                                        <json:string key="pathType">|</json:string>
                                                                                        <json:array key="items">
                                                                                            <json:map>
                                                                                                <json:string key="type">path</json:string>
                                                                                                <json:string key="pathType">|</json:string>
                                                                                                <json:array key="items">
                                                                                                    <json:map>
                                                                                                        <json:string key="type">path</json:string>
                                                                                                        <json:string key="pathType">|</json:string>
                                                                                                        <json:array key="items">
                                                                                                            <json:map>
                                                                                                                <json:string key="type">path</json:string>
                                                                                                                <json:string key="pathType">|</json:string>
                                                                                                                <json:array key="items">
                                                                                                                    <json:string>http://www.w3.org/2000/01/rdf-schema#label</json:string>
                                                                                                                    <json:string>http://purl.org/dc/elements/1.1/title</json:string>
                                                                                                                </json:array>
                                                                                                            </json:map>
                                                                                                            <json:string>http://purl.org/dc/terms/title</json:string>
                                                                                                        </json:array>
                                                                                                    </json:map>
                                                                                                    <json:string>http://xmlns.com/foaf/0.1/name</json:string>
                                                                                                </json:array>
                                                                                            </json:map>
                                                                                            <json:string>http://xmlns.com/foaf/0.1/givenName</json:string>
                                                                                        </json:array>
                                                                                    </json:map>
                                                                                    <json:string>http://xmlns.com/foaf/0.1/familyName</json:string>
                                                                                </json:array>
                                                                            </json:map>
                                                                            <json:string>http://rdfs.org/sioc/ns#name</json:string>
                                                                        </json:array>
                                                                    </json:map>
                                                                    <json:string>http://www.w3.org/2004/02/skos/core#prefLabel</json:string>
                                                                </json:array>
                                                            </json:map>
                                                            <json:string>http://rdfs.org/sioc/ns#content</json:string>
                                                        </json:array>
                                                    </json:map>
                                                    <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$label-var-name"/></json:string>
                                                </json:map>
                                            </json:array>
                                        </json:map>
                                    </json:array>
                                    <json:string key="name"><xsl:text>?</xsl:text><xsl:value-of select="$label-graph-var-name"/></json:string>
                                </json:map>
                            </json:array>
                        </json:map>
                    </json:array>
                </json:map>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:map/json:array[@key = 'order']" mode="apl:bgp-value-counts" priority="1">
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="descending" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>

            <json:map>
                <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
                <json:boolean key="descending"><xsl:value-of select="$descending"/></json:boolean>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="onFacetValueResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="object-var-name" as="xs:string"/>
        <xsl:param name="count-var-name" as="xs:string"/>
        <xsl:param name="label-sample-var-name" as="xs:string"/>

        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                    <xsl:if test="$results//srx:result[srx:binding[@name = $object-var-name]]">
                        <xsl:result-document href="#{$container-id}" method="ixsl:append-content">
                            <ul class="well well-small nav nav-list">
                                <xsl:for-each select="$results//srx:result[srx:binding[@name = $object-var-name]]">
                                    <xsl:sort select="srx:binding[@name = $count-var-name]/srx:literal"/>
                                    <xsl:sort select="srx:binding[@name = $label-sample-var-name]/srx:literal"/>
                                    <xsl:sort select="srx:binding[@name = $object-var-name]/srx:*"/>

                                    <li>
                                        <label class="checkbox">
                                            <!-- store value type ('uri'/'literal') in a hidden input -->
                                            <input type="hidden" name="type" value="{srx:binding[@name = $object-var-name]/srx:*/local-name()}"/>
                                            <xsl:if test="srx:binding[@name = $object-var-name]/srx:literal/@datatype">
                                                <input type="hidden" name="datatype" value="{srx:binding[@name = $object-var-name]/srx:literal/@datatype}"/>
                                            </xsl:if>

                                            <input type="checkbox" name="{$object-var-name}" value="{srx:binding[@name = $object-var-name]/srx:*}"> <!-- can be srx:literal -->
                                            <!-- TO-DO: reload state from URL query params -->
                    <!--                                    <xsl:if test="$filter/*/@rdf:resource = @rdf:about">
                                                    <xsl:attribute name="checked" select="'checked'"/>
                                                </xsl:if>-->
                                            </input>
                                            <span title="{srx:binding[@name = $object-var-name]/srx:*}">
                                                <xsl:choose>
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
                                </xsl:for-each>
                            </ul>
                        </xsl:result-document>
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
    
    <!-- facet onchange -->

    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//input[@type = 'checkbox']" mode="ixsl:onchange">
        <xsl:variable name="var-name" select="@name" as="xs:string"/>
        <!-- collect the values/types/datatypes of all checked inputs within this facet and build an array of maps -->
        <xsl:variable name="values" select="array { for $label in ancestor::ul//label[input[@type = 'checkbox'][ixsl:get(., 'checked')]] return map { 'value' : string($label/input[@type = 'checkbox']/@value), 'type': string($label/input[@name = 'type']/@value), 'datatype': string($label/input[@name = 'datatype']/@value) } }" as="array(map(xs:string, xs:string))"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
        <!-- add FILTER IN () if not present, and set IN () values -->
        <xsl:variable name="select-xml" as="element()">
            <xsl:apply-templates select="json-to-xml($select-json-string)" mode="apl:filter-in">
                <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                <xsl:with-param name="values" select="$values" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="select-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $select-json-string ])"/>
        <xsl:variable name="select-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $select-json ]), 'toString', [])" as="xs:string"/>
        <!-- set ?this variable value -->
        <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $ac:uri, '&gt;'))" as="xs:string"/>
        <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
        <xsl:variable name="query-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset')), ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="xs:anyURI(if ($service/dydra-urn:accessToken) then ($endpoint || '?auth_token=' || $service/dydra-urn:accessToken || '&amp;query=' || encode-for-uri($query-string)) else ($endpoint || '?query=' || encode-for-uri($query-string)))" as="xs:anyURI"/>

        <!-- set global SELECT query (without modifiers) -->
        <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <!-- set global DESCRIBE query -->
        <ixsl:set-property name="describe-query" select="$query-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad">
                <xsl:with-param name="select-string" select="$select-string"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:filter-in">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- append FILTER (?varName IN ()) to WHERE, if it's not present yet, and replace IN() values -->
    <xsl:template match="json:array[@key = 'where']" mode="apl:filter-in" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        <xsl:variable name="var-filter" select="json:map[json:string[@key = 'type'] = 'filter'][json:map[@key = 'expression']/json:array[@key = 'args']/json:string eq '?' || $var-name]" as="element()?"/>
        <xsl:variable name="where" as="element()">
            <xsl:choose>
                <xsl:when test="$var-filter">
                    <xsl:copy-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="#current"/>

                        <!-- append FILTER (?varName IN ()) to WHERE-->
                        <json:map>
                            <json:string key="type">filter</json:string>
                            <json:map key="expression">
                                <json:string key="type">operation</json:string>
                                <json:string key="operator">in</json:string>
                                <json:array key="args">
                                    <json:string><xsl:text>?</xsl:text><xsl:value-of select="$var-name"/></json:string>
                                    <json:array>
                                        <!-- values -->
                                    </json:array>
                                </json:array>
                            </json:map>
                        </json:map>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- append value to IN() -->
        <xsl:apply-templates select="$where" mode="apl:set-filter-in-values">
            <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
            <xsl:with-param name="values" select="$values" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:set-filter-in-values">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:map[json:string[@key = 'type'] = 'filter']" mode="apl:set-filter-in-values" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        
        <!-- remove the FILTER ($varName) if there are no values -->
        <xsl:if test="not(json:map[@key = 'expression']/json:array[@key = 'args']/json:string = '?' || $var-name and array:size($values) = 0)">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- replace IN () values for the FILTER with matching variable name -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'filter']/json:map[@key = 'expression']/json:array[@key = 'args']/json:array" mode="apl:set-filter-in-values" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:choose>
                <!-- replace IN() values if $varName matches -->
                <xsl:when test="../json:string eq '?' || $var-name">
                    <xsl:for-each select="1 to array:size($values)">
                        <xsl:variable name="pos" select="position()"/>
                        
                        <json:string>
                            <xsl:choose>
                                <!-- literal value - wrap in quotes: "literal" -->
                                <xsl:when test="array:get($values, $pos)?type = 'literal'">
                                    <xsl:text>&quot;</xsl:text><xsl:value-of select="array:get($values, $pos)?value"/><xsl:text>&quot;</xsl:text>
                                    <!-- add datatype URI, if any -->
                                    <xsl:if test="array:get($values, $pos)?datatype">
                                        <xsl:text>^^</xsl:text>
                                        <xsl:value-of select="array:get($values, $pos)?datatype"/>
                                    </xsl:if>
                                </xsl:when>
                                <!-- URI value -->
                                <xsl:otherwise>
                                    <xsl:value-of select="array:get($values, $pos)?value"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </json:string>
                    </xsl:for-each>
                </xsl:when>
                <!-- otherwise, retain existing values -->
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!-- parallax onclick -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'parallax-nav']/ul/li/a" mode="ixsl:onclick">
        <xsl:variable name="predicate" select="input/@value" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <xsl:variable name="var-name" select="substring-after(ixsl:get(ixsl:call($select-builder, 'build', []), 'variables')[1], '?')"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        <xsl:variable name="new-var-name" select="'subject' || translate($uuid, '-', '_')" as="xs:string"/>
        <xsl:variable name="triple" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'triple', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ $var-name ]), ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'uri', [ $predicate ]), ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ $new-var-name ]) ])"/>
        <xsl:variable name="bgp" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'bgp', [ [ $triple ] ])"/>
        <!-- pseudo JS code: QueryBuilder.graph(QueryBuilder.var("g" + generateUUID()), [ bgp ]) -->
        <xsl:variable name="graph" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'graph', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ 'graph' || translate($uuid, '-', '_') ]), [ $bgp ] ])"/>
        <!-- pseudo JS code: QueryBuilder.union([ bgp, graph ]) -->
        <xsl:variable name="union" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'union', [ [ $bgp, $graph ] ])"/>
        <!-- pseudo JS code: SPARQLBuilder.SelectBuilder.fromString(select-builder).where(graph) -->
        <xsl:variable name="select-builder" select="ixsl:call($select-builder, 'wherePattern', [ $union ])"/>
        <!-- pseudo JS code: SelectBuilder.fromString(query).variables([ SelectBuilder.var("whatever") ]).build(); -->
        <xsl:variable name="select-builder" select="ixsl:call($select-builder, 'variables', [ [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ $new-var-name ]) ] ])"/>
        <xsl:variable name="select-string" select="ixsl:call($select-builder, 'toString', [])" as="xs:string"/>
        <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
        <xsl:variable name="query-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset')), ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
        
        <!-- set global SELECT query (without modifiers) -->
        <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <!-- set global DESCRIBE query -->
        <ixsl:set-property name="describe-query" select="$query-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="xs:anyURI(if ($service/dydra-urn:accessToken) then ($endpoint || '?auth_token=' || $service/dydra-urn:accessToken || '&amp;query=' || encode-for-uri($query-string)) else ($endpoint || '?query=' || encode-for-uri($query-string)))" as="xs:anyURI"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad">
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="expression-var-name" select="$new-var-name" as="xs:string?"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>

    <!-- result counts -->
    
    <xsl:template name="apl:ResultCounts">
        <xsl:param name="expression-var-name" as="xs:string?"/>
        <xsl:param name="count-var-name" select="'count'" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$select-xml" mode="apl:result-count">
                    <xsl:with-param name="count-var-name" select="$count-var-name" tunnel="yes"/>
                    <xsl:with-param name="expression-var-name" select="$expression-var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="select-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $select-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $select-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="service" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.service')) then ixsl:get(ixsl:window(), 'LinkedDataHub.service') else ()" as="element()?"/>
        <xsl:variable name="endpoint" select="xs:anyURI(($service/sd:endpoint/@rdf:resource, (if ($service/dydra:repository/@rdf:resource) then ($service/dydra:repository/@rdf:resource || 'sparql') else ()), $ac:endpoint)[1])" as="xs:anyURI"/>
        <!-- TO-DO: unify dydra: and dydra-urn: ? -->
        <xsl:variable name="results-uri" select="xs:anyURI(if ($service/dydra-urn:accessToken) then ($endpoint || '?auth_token=' || $service/dydra-urn:accessToken || '&amp;query=' || encode-for-uri($query-string)) else ($endpoint || '?query=' || encode-for-uri($query-string)))" as="xs:anyURI"/>

        <!-- load result count -->
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
            <xsl:call-template name="apl:ResultCountResultsLoad">
                <xsl:with-param name="container-id" select="'result-counts'"/>
                <xsl:with-param name="count-var-name" select="$count-var-name"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:result-count">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- replace query variables with (COUNT(DISTINCT *) AS ?count) -->
    <xsl:template match="json:map/json:array[@key = 'variables']" mode="apl:result-count" priority="1">
        <xsl:param name="expression-var-name" as="xs:string?" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <json:map>
                <json:map key="expression">
                    <json:string key="expression">
                        <xsl:choose>
                            <xsl:when test="$expression-var-name">
                                <xsl:text>?</xsl:text>
                                <xsl:value-of select="$expression-var-name"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>*</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </json:string>
                    <json:string key="type">aggregate</json:string>
                    <json:string key="aggregation">count</json:string>
                    <json:boolean key="distinct">true</json:boolean>
                </json:map>
                <json:string key="variable">?<xsl:value-of select="$count-var-name"/></json:string>
            </json:map>
        </xsl:copy>
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
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>