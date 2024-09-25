<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
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
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->
    
    <!-- TO-DO: make 'data-table' configurable -->
    <xsl:template name="ac:draw-chart">
        <xsl:param name="data-table"/>
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="width" as="xs:integer?"/>
        <xsl:param name="height" as="xs:integer?"/>

        <xsl:variable name="chart-classes" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'&ac;Table'" select="'google.visualization.Table'"/>
                <xsl:map-entry key="'&ac;LineChart'" select="'google.visualization.LineChart'"/>
                <xsl:map-entry key="'&ac;BarChart'" select="'google.visualization.BarChart'"/>
                <xsl:map-entry key="'&ac;ScatterChart'" select="'google.visualization.ScatterChart'"/>
                <xsl:map-entry key="'&ac;Timeline'" select="'google.visualization.Timeline'"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="chart-class" select="map:get($chart-classes, $chart-type)" as="xs:string?"/>
        <xsl:if test="not($chart-class)">
            <xsl:message terminate="yes">
                Chart type '<xsl:value-of select="$chart-type"/>' unknown
            </xsl:message>
        </xsl:if>
        
        <xsl:variable name="chart" select="ldh:new($chart-class, [ id($canvas-id, ixsl:page()) ])"/>
        <xsl:variable name="options" as="map(xs:string, item())">
            <xsl:map>
                <xsl:if test="exists($width)">
                    <xsl:map-entry key="'width'" select="$width"/>
                </xsl:if>
                <xsl:if test="exists($height)">
                    <xsl:map-entry key="'height'" select="$height"/>
                </xsl:if>
                <xsl:if test="$chart-type = '&ac;Table'">
                    <xsl:map-entry key="'allowHtml'" select="true()"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$chart-type = '&ac;BarChart'">
                        <xsl:map-entry key="'hAxis'" select="map{ 'title': $series[1] }"/>
                        <xsl:map-entry key="'vAxis'" select="map{ 'title': $category }"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:map-entry key="'hAxis'" select="map{ 'title': $category }"/>
                        <xsl:map-entry key="'vAxis'" select="map{ 'title': $series[1] }"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="options-obj" select="ixsl:call(ixsl:window(), 'JSON.parse', [ $options => serialize(map{ 'method': 'json' }) ])"/>
        <xsl:sequence select="ixsl:call($chart, 'draw', [ $data-table, $options-obj ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template name="ldh:RenderChart">
        <xsl:param name="data-table"/>
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:call-template name="ac:draw-chart">
            <xsl:with-param name="data-table" select="$data-table"/>
            <xsl:with-param name="canvas-id" select="$canvas-id"/>
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
            <xsl:with-param name="height" select="400"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="ldh:RenderChartForm">
        <xsl:context-item as="document-node()" use="required"/> <!-- chart query result (rdf:RDF or srx:sparql) -->
        <xsl:param name="container" as="element()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>

        <xsl:variable name="results" select="." as="document-node()"/>

        <xsl:if test="rdf:RDF">
            <xsl:for-each select="$container//select[contains-token(@class, 'chart-category')]">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <option value="">
                        <!-- URI is the default category -->
                        <xsl:if test="not($category)">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>

                        <xsl:text>[URI/ID]</xsl:text>
                    </option>

                    <xsl:for-each-group select="$results/rdf:RDF/*/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                        <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

                        <option value="{current-grouping-key()}">
                            <xsl:if test="$category = current-grouping-key()">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of>
                                <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
                            </xsl:value-of>
                        </option>
                    </xsl:for-each-group>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:for-each select="$container//select[contains-token(@class, 'chart-series')]">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:for-each-group select="$results/rdf:RDF/*/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                        <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

                        <option value="{current-grouping-key()}">
                            <xsl:if test="$series = current-grouping-key()">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of>
                                <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
                            </xsl:value-of>
                        </option>
                    </xsl:for-each-group>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="srx:sparql">
            <xsl:for-each select="$container//select[contains-token(@class, 'chart-category')]">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:for-each select="$results//srx:head/srx:variable">
                        <!-- leave the original variable order so it can be controlled from query -->

                        <option value="{@name}">
                            <xsl:if test="$category = @name">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of select="@name"/>
                        </option>
                    </xsl:for-each>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:for-each select="$container//select[contains-token(@class, 'chart-series')]">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:for-each select="$results//srx:head/srx:variable">
                        <!-- leave the original variable order so it can be controlled from query -->

                        <option value="{@name}">
                            <xsl:if test="$series = @name">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of select="@name"/>
                        </option>
                    </xsl:for-each>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <!-- chart content -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&ldh;ResultSetChart', '&ldh;GraphChart')][spin:query/@rdf:resource][ldh:chartType/@rdf:resource]" mode="ldh:RenderBlock" priority="1">
        <xsl:param name="this" as="xs:anyURI"/>
<!--        <xsl:param name="block" as="element()"/>-->
        <xsl:param name="container" as="element()"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="block-uri" as="xs:anyURI"/> <!-- select="xs:anyURI($block/@about)" -->
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:variable name="query-uri" select="xs:anyURI(spin:query/@rdf:resource)" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="xs:anyURI(ldh:chartType/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:variable name="category" select="ldh:categoryProperty/@rdf:resource | ldh:categoryVarName" as="xs:string?"/>
        <xsl:variable name="series" select="ldh:seriesProperty/@rdf:resource | ldh:seriesVarName" as="xs:string*"/>
        <xsl:variable name="canvas-id" select="generate-id() || '-chart-canvas'" as="xs:string?"/>

        <xsl:message>
            Chart ldh:RenderBlock rdf:type/@rdf:resource: <xsl:value-of select="rdf:type/@rdf:resource"/>
        </xsl:message>
        
        <xsl:for-each select="$container//div[@class = 'bar']">
            <ixsl:set-style name="width" select="'66%'" object="."/>
        </xsl:for-each>
        
        <xsl:variable name="row" as="element()*">
            <xsl:apply-templates select="." mode="bs2:Block">
                <xsl:with-param name="graph" select="$graph" tunnel="yes"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="canvas-id" select="$canvas-id" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$row/*"/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $query-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onChartQueryLoad">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="block-uri" select="$block-uri"/>
                    <xsl:with-param name="container-id" select="$container-id"/>
                    <xsl:with-param name="query-uri" select="$query-uri"/>
                    <xsl:with-param name="chart-type" select="$chart-type"/>
                    <xsl:with-param name="category" select="$category"/>
                    <xsl:with-param name="series" select="$series"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="canvas-id" select="$canvas-id"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
    <!-- chart-type onchange -->
    
    <xsl:template match="select[contains-token(@class, 'chart-type')]" mode="ixsl:onchange">
        <xsl:variable name="chart-type" select="ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="category" select="../..//select[contains-token(@class, 'chart-category')]/ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="series" as="xs:string*">
            <xsl:for-each select="../..//select[contains-token(@class, 'chart-series')]">
                <xsl:variable name="select" select="." as="element()"/>
                <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                    <xsl:sequence select="ixsl:get(ixsl:call(ixsl:get($select, 'selectedOptions'), 'item', [ . ]), 'value')"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="container" select="ancestor::div[@about][1]" as="element()?"/>
        <xsl:variable name="content-id" select="$container/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::fieldset/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'results')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'results') else root(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'content'))" as="document-node()"/>
        
        <xsl:if test="not($chart-type) or not($category or $results/rdf:RDF) or empty($series)">
            <xsl:message terminate="yes">Chart control values missing for content '<xsl:value-of select="$content-id"/>'</xsl:message>
        </xsl:if>

        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>

        <xsl:call-template name="ldh:RenderChart">
            <xsl:with-param name="data-table" select="$data-table"/>
            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:call-template>
    </xsl:template>

    <!-- category onchange -->

    <xsl:template match="select[contains-token(@class, 'chart-category')]" mode="ixsl:onchange">
        <xsl:variable name="chart-type" select="../..//select[contains-token(@class, 'chart-type')]/ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="category" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="series" as="xs:string*">
            <xsl:for-each select="../..//select[contains-token(@class, 'chart-series')]">
                <xsl:variable name="select" select="." as="element()"/>
                <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                    <xsl:sequence select="ixsl:get(ixsl:call(ixsl:get($select, 'selectedOptions'), 'item', [ . ]), 'value')"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="container" select="ancestor::div[@about][1]" as="element()?"/>
        <xsl:variable name="content-id" select="$container/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::fieldset/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'results')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'results') else root(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'content'))" as="document-node()"/>

        <xsl:if test="not($chart-type) or not($category or $results/rdf:RDF) or empty($series)">
            <xsl:message terminate="yes">Chart control values missing for content '<xsl:value-of select="$content-id"/>'</xsl:message>
        </xsl:if>

        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>

        <xsl:call-template name="ldh:RenderChart">
            <xsl:with-param name="data-table" select="$data-table"/>
            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- series onchange -->

    <xsl:template match="select[contains-token(@class, 'chart-series')]" mode="ixsl:onchange">
        <xsl:variable name="chart-type" select="../..//select[contains-token(@class, 'chart-type')]/ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="category" select="../..//select[contains-token(@class, 'chart-category')]/ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="series" as="xs:string*">
            <xsl:variable name="select" select="." as="element()"/>
            <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                <xsl:sequence select="ixsl:get(ixsl:call(ixsl:get($select, 'selectedOptions'), 'item', [ . ]), 'value')"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="container" select="ancestor::div[@about][1]" as="element()?"/>
        <xsl:variable name="content-id" select="$container/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::fieldset/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'results')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'results') else root(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'content'))" as="document-node()"/>

        <xsl:if test="not($chart-type) or not($category or $results/rdf:RDF) or empty($series)">
            <xsl:message terminate="yes">Chart control values missing for content '<xsl:value-of select="$content-id"/>'</xsl:message>
        </xsl:if>

        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>

        <xsl:call-template name="ldh:RenderChart">
            <xsl:with-param name="data-table" select="$data-table"/>
            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <xsl:template name="onChartQueryLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="block-uri" as="xs:anyURI"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="canvas-id" as="xs:string"/>

        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                <xsl:for-each select="?body">
<!--                    <xsl:variable name="query-type" select="xs:anyURI(key('resources', $query-uri)/rdf:type/@rdf:resource)" as="xs:anyURI"/>-->
                    <xsl:variable name="query-string" select="key('resources', $query-uri)/sp:text" as="xs:string"/>
                    <xsl:variable name="query-string" select="replace($query-string, '$this', '&lt;' || $this || '&gt;', 'q')" as="xs:string"/>
                    <!-- TO-DO: use SPARQLBuilder to set LIMIT -->
                    <!--<xsl:variable name="query-string" select="concat($query-string, ' LIMIT 100')" as="xs:string"/>-->
                    <xsl:variable name="service-uri" select="xs:anyURI(key('resources', $query-uri)/ldh:service/@rdf:resource)" as="xs:anyURI?"/>
                    <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
                    <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
                    <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/>

                    <!-- update progress bar -->
                    <xsl:for-each select="$container//div[@class = 'bar']">
                        <ixsl:set-style name="width" select="'83%'" object="."/>
                    </xsl:for-each>

                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }">
                            <xsl:call-template name="onSPARQLResultsLoad">
                                <xsl:with-param name="endpoint" select="$endpoint"/>
                                <xsl:with-param name="results-uri" select="$results-uri"/>
                                <xsl:with-param name="container" select="$container"/>
                                <xsl:with-param name="chart-canvas-id" select="$canvas-id"/>
                                <xsl:with-param name="block-uri" select="$block-uri"/>
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                                <xsl:with-param name="show-editor" select="false()"/>
                                <xsl:with-param name="content-method" select="xs:QName('ixsl:append-content')"/>
                                <xsl:with-param name="push-state" select="false()"/>
                                <xsl:with-param name="show-chart-save" select="false()"/>
                                <xsl:with-param name="results-container-id" select="$container-id || '-query-results'"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'bar']"/>
        
                <!-- error response - could not load query results -->
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
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
    
</xsl:stylesheet>