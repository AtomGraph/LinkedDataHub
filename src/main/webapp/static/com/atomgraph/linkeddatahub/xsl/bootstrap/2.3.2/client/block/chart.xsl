<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
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
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
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
    
    <!-- render chart block -->
    <xsl:template match="*[@typeof = ('&ldh;ResultSetChart', '&ldh;GraphChart')][descendant::*[@property = '&spin;query'][@resource]][descendant::*[@property = '&ldh;chartType'][@resource]]" mode="ldh:RenderRow" priority="2"> <!-- prioritize above block.xsl -->
        <xsl:param name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:param name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="form-actions" as="element()?">
            <div class="form-actions">
                <button class="btn btn-primary btn-save-chart" type="button">
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                    </xsl:apply-templates>

                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </button>
            </div>
        </xsl:param>
        <xsl:variable name="query-uri" select="descendant::*[@property = '&spin;query']/@resource" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="descendant::*[@property = '&ldh;chartType']/@resource" as="xs:anyURI?"/>
        <xsl:variable name="category" select="descendant::*[@property = '&ldh;categoryProperty']/@resource | descendant::*[@property = '&ldh;categoryVarName']/text()" as="xs:string?"/>
        <xsl:variable name="series" select="descendant::*[@property = '&ldh;seriesProperty']/@resource | descendant::*[@property = '&ldh;seriesVarName']/text()" as="xs:string*"/>
        <xsl:variable name="canvas-id" select="generate-id() || '-chart-canvas'" as="xs:string?"/>
        <xsl:variable name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        
        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <ixsl:set-style name="width" select="'66%'" object="."/>
        </xsl:for-each>

        <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
            <xsl:variable name="header" select="./div/div[@class = 'well']" as="element()"/>

            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$header"/>

                <form method="{$method}" action="{$action}">
                    <xsl:if test="$accept-charset">
                        <xsl:attribute name="accept-charset" select="$accept-charset"/>
                    </xsl:if>
                    <xsl:if test="$enctype">
                        <xsl:attribute name="enctype" select="$enctype"/>
                    </xsl:if>

                    <fieldset>
                        <div class="row-fluid">
                            <div class="span4">
                                <label for="{$chart-type-id}">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                                    </xsl:value-of>
                                </label>
                                <!--  TO-DO: replace with xsl:apply-templates on ac:Chart subclasses as in imports/ldh.xsl -->
                                <select id="{$chart-type-id}" name="ou" class="input-medium chart-type">
                                    <option value="&ac;Table">
                                        <xsl:if test="$chart-type = '&ac;Table'">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:text>Table</xsl:text>
                                    </option>
                                    <option value="&ac;ScatterChart">
                                        <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:text>Scatter chart</xsl:text>
                                    </option>
                                    <option value="&ac;LineChart">
                                        <xsl:if test="$chart-type = '&ac;LineChart'">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:text>Line chart</xsl:text>
                                    </option>
                                    <option value="&ac;BarChart">
                                        <xsl:if test="$chart-type = '&ac;BarChart'">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:text>Bar chart</xsl:text>
                                    </option>
                                    <option value="&ac;Timeline">
                                        <xsl:if test="$chart-type = '&ac;Timeline'">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:text>Timeline</xsl:text>
                                    </option>
                                </select>
                            </div>
                            <div class="span4">
                                <label for="{$category-id}">Category</label>
                                <select id="{$category-id}" name="ou" class="input-large chart-category"></select>
                            </div>
                            <div class="span4">
                                <label for="{$series-id}">Series</label>
                                <select id="{$series-id}" name="ou" multiple="multiple" class="input-large chart-series"></select>
                            </div>
                        </div>
                    </fieldset>

                    <div>
                        <xsl:if test="$canvas-id">
                            <xsl:attribute name="id" select="$canvas-id"/>
                        </xsl:if>
                        <xsl:if test="$canvas-class">
                            <xsl:attribute name="class" select="$canvas-class"/>
                        </xsl:if>
                    </div>

                    <xsl:sequence select="$form-actions"/>
                </form>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $query-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'this': $about,
            'block': $block,
            'container': $container,
            'container-id': $container-id,
            'query-uri': $query-uri,
            'chart-type': $chart-type,
            'category': $category,
            'series': $series,
            'canvas-id': $canvas-id
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:chart-query-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->
    
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
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()?"/>
        <xsl:variable name="block-id" select="$block/@id" as="xs:string?"/>
        <!-- if there is no block, the chart is rendering the current document -->
        <xsl:variable name="block-uri" select="if ($block/@about) then $block/@about else (if ($block-id) then xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $block-id) else ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::fieldset/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results') else root(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'content'))" as="document-node()"/>
        
        <xsl:if test="not($chart-type) or not($category or $results/rdf:RDF) or empty($series)">
            <xsl:message terminate="yes">Chart control values missing for content '<xsl:value-of select="$block-id"/>'</xsl:message>
        </xsl:if>

        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

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
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()?"/>
        <xsl:variable name="block-id" select="$block/@id" as="xs:string?"/>
        <!-- if there is no block, the chart is rendering the current document -->
        <xsl:variable name="block-uri" select="if ($block/@about) then $block/@about else (if ($block-id) then xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $block-id) else ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::fieldset/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results') else root(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'content'))" as="document-node()"/>

        <xsl:if test="not($chart-type) or not($category or $results/rdf:RDF) or empty($series)">
            <xsl:message terminate="yes">Chart control values missing for content '<xsl:value-of select="$block-id"/>'</xsl:message>
        </xsl:if>

        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

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
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()?"/>
        <xsl:variable name="block-id" select="$block/@id" as="xs:string?"/>
        <!-- if there is no block, the chart is rendering the current document -->
        <xsl:variable name="block-uri" select="if ($block/@about) then $block/@about else (if ($block-id) then xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $block-id) else ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::fieldset/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'results') else root(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'content'))" as="document-node()"/>

        <xsl:if test="not($chart-type) or not($category or $results/rdf:RDF) or empty($series)">
            <xsl:message terminate="yes">Chart control values missing for content '<xsl:value-of select="$block-id"/>'</xsl:message>
        </xsl:if>

        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:call-template name="ldh:RenderChart">
            <xsl:with-param name="data-table" select="$data-table"/>
            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- create chart onclick (appends a new chart block after this, with query and category/series fields filled out) -->
    
    <xsl:template match="div[@about][@typeof]//button[contains-token(@class, 'btn-create-chart')]" mode="ixsl:onclick">
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="textarea-id" select="$block//textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('query-service'), 'value'))" as="xs:anyURI?"/> <!-- TO-DO: fix content-embedded queries -->
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string"/>
        <xsl:variable name="forClass" select="if ($query-type = ('SELECT', 'ASK')) then xs:anyURI('&ldh;ResultSetChart') else xs:anyURI('&ldh;GraphChart')" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="../..//select[contains-token(@class, 'chart-type')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="category" select="../..//select[contains-token(@class, 'chart-category')]/ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="series" as="xs:string*">
            <xsl:for-each select="../..//select[contains-token(@class, 'chart-series')]">
                <xsl:variable name="select" select="." as="element()"/>
                <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                    <xsl:sequence select="ixsl:get(ixsl:call(ixsl:get($select, 'selectedOptions'), 'item', [ . ]), 'value')"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>        
        <xsl:variable name="constructed-doc" as="document-node()">
            <xsl:document>
                <rdf:RDF> 
                    <rdf:Description rdf:nodeID="chart">
                        <rdf:type rdf:resource="{$forClass}"/>
                        <dct:title rdf:nodeID="title"/>
                        <ldh:chartType rdf:resource="{$chart-type}"/>
                        <ldh:categoryVarName><xsl:value-of select="$category"/></ldh:categoryVarName>
                        <xsl:for-each select="$series">
                            <ldh:seriesVarName><xsl:value-of select="."/></ldh:seriesVarName>
                        </xsl:for-each>
                        <spin:query rdf:resource="{$block/@about}"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="title">
                        <rdf:type rdf:resource="&xsd;string"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="this" select="xs:anyURI($doc-uri || '#' || $id)" as="xs:anyURI"/>
        <!-- set document URI instead of blank node -->
        <xsl:variable name="constructed-doc" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$constructed-doc" mode="ldh:SetResourceID">
                    <xsl:with-param name="forClass" select="$forClass" tunnel="yes"/>
                    <xsl:with-param name="about" select="$this" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <xsl:variable name="method" select="'post'" as="xs:string"/>
        <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
        <xsl:variable name="row-form" as="element()*">
            <!-- TO-DO: refactor to use asynchronous HTTP requests -->
            <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
            <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
            <xsl:variable name="type-metadata" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

            <xsl:variable name="property-uris" select="distinct-values($resource/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
            <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
            <xsl:variable name="property-metadata" select="document($request-uri)" as="document-node()"/>

            <xsl:variable name="query-string" select="$constructor-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
            <xsl:variable name="constructors" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

            <xsl:variable name="query-string" select="$constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
            <xsl:variable name="constraints" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

            <xsl:variable name="query-string" select="$shape-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
            <xsl:variable name="shapes" select="document($request-uri)" as="document-node()"/>

            <xsl:apply-templates select="$constructed-doc" mode="bs2:RowForm">
                <xsl:with-param name="about" select="()"/> <!-- don't set @about on the container until after the resource is saved -->
                <xsl:with-param name="method" select="$method"/>
                <xsl:with-param name="action" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $doc-uri)" as="xs:anyURI"/>
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                <xsl:with-param name="constructor" select="$constructed-doc" tunnel="yes"/>
                <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/> <!-- ac:absolute-path(ldh:base-uri(.)) is empty on constructed documents -->
                <xsl:with-param name="show-cancel-button" select="false()"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <!-- insert $row-form after the $block TO-DO: replace with <xsl:result-document href="?." method="ixsl:insert-after"> when SaxonJS 3 is available https://saxonica.plan.io/issues/5543 -->
        <xsl:sequence select="ixsl:call($block, 'after', [ $row-form ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- apply client-side templates on the appended row form (now following sibling of the $block) -->
        <xsl:apply-templates select="$block/following-sibling::*[1]" mode="ldh:RenderRowForm"/>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <!-- chart query response -->
    
    <xsl:function name="ldh:chart-query-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="this" select="$context('this')" as="xs:anyURI"/>
        <xsl:variable name="container-id" select="$context('container-id')" as="xs:string"/>
        <xsl:variable name="query-uri" select="$context('query-uri')" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="$context('chart-type')" as="xs:anyURI"/>
        <xsl:variable name="category" select="$context('category')" as="xs:string?"/>
        <xsl:variable name="series" select="$context('series')" as="xs:string*"/>
        <xsl:variable name="canvas-id" select="$context('canvas-id')" as="xs:string"/>

        <xsl:for-each select="$response">
            <xsl:variable name="response" select="." as="map(*)"/>
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                    <xsl:for-each select="?body">
                        <xsl:variable name="query-string" select="key('resources', $query-uri)/sp:text" as="xs:string"/>
                        <xsl:variable name="query-string" select="replace($query-string, '$this', '&lt;' || $this || '&gt;', 'q')" as="xs:string"/>
                        <!-- TO-DO: use SPARQLBuilder to set LIMIT -->
                        <!--<xsl:variable name="query-string" select="concat($query-string, ' LIMIT 100')" as="xs:string"/>-->
                        <xsl:variable name="service-uri" select="xs:anyURI(key('resources', $query-uri)/ldh:service/@rdf:resource)" as="xs:anyURI?"/>
                        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
                        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
                        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/>

                        <!-- update progress bar -->
                        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
                            <ixsl:set-style name="width" select="'83%'" object="."/>
                        </xsl:for-each>

                        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }" as="map(*)"/>
                        <xsl:variable name="context" as="map(*)" select="
                          map{
                            'request': $request,
                            'endpoint': $endpoint,
                            'results-uri': $results-uri,
                            'block': $block,
                            'container': $container,
                            'chart-canvas-id': $canvas-id,
                            'block-uri': $block/@about,
                            'chart-type': $chart-type,
                            'category': $category,
                            'series': $series,
                            'show-editor': false(),
                            'show-chart-save': false(),
                            'results-container-id': $container-id || '-query-results'
                          }"/>
                        <ixsl:promise select="ixsl:http-request($context('request')) =>
                            ixsl:then(ldh:rethread-response($context, ?)) =>
                            ixsl:then(ldh:handle-response#1) =>
                            ixsl:then(ldh:chart-results-response#1)"
                            on-failure="ldh:promise-failure#1"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- hide the progress bar - either of this block (if it contains a progress bar) or of the parent block -->
                    <xsl:for-each select="($block//div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')], $block/ancestor::div[contains-token(@class, 'block')]//div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')])[1]">
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>

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
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <!-- SPARQL results response -->

    <xsl:function name="ldh:chart-results-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="results-uri" select="$context('results-uri')" as="xs:anyURI"/>
        <xsl:variable name="block-uri" select="$context('block-uri')" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="$context('chart-canvas-id')" as="xs:string"/>
        <xsl:variable name="chart-type" select="$context('chart-type')" as="xs:anyURI"/>
        <xsl:variable name="category" select="$context('category')" as="xs:string?"/>
        <xsl:variable name="series" select="$context('series')" as="xs:string*"/>
        <xsl:variable name="endpoint" select="$context('endpoint')" as="xs:anyURI?"/>
        <xsl:variable name="show-editor" select="$context('show-editor')" as="xs:boolean"/>
        <xsl:variable name="show-chart-save" select="$context('show-chart-save')" as="xs:boolean"/>
        <xsl:variable name="results-container-id" select="$context('results-container-id')"  as="xs:string"/>

        <xsl:for-each select="$response">
            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

            <xsl:variable name="response" select="." as="map(*)"/>
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                    <xsl:for-each select="?body">
                        <xsl:variable name="results" select="." as="document-node()"/>
                        <xsl:variable name="category" select="if (exists($category)) then $category else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name()))[1] else srx:sparql/srx:head/srx:variable[1]/@name)" as="xs:string?"/>
                        <xsl:variable name="series" select="if (exists($series)) then $series else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name())) else srx:sparql/srx:head/srx:variable/@name)" as="xs:string*"/>

                        <xsl:call-template name="ldh:RenderChartForm">
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="category" select="$category"/>
                            <xsl:with-param name="series" select="$series"/>
                        </xsl:call-template>

                        <!-- create new cache entry using content URI as key -->
                        <ixsl:set-property name="{'`' || $block-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                        <ixsl:set-property name="results" select="$results" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
                        <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

                        <xsl:call-template name="ldh:RenderChart">
                            <xsl:with-param name="data-table" select="$data-table"/>
                            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                            <xsl:with-param name="chart-type" select="$chart-type"/>
                            <xsl:with-param name="category" select="$category"/>
                            <xsl:with-param name="series" select="$series"/>
                        </xsl:call-template>

                        <!-- hide the progress bar - either of this block (if it contains a progress bar) or of the parent block -->
                        <xsl:for-each select="($block//div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')], $block/ancestor::div[contains-token(@class, 'block')]//div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')])[1]">
                            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- hide the progress bar - either of this block (if it contains a progress bar) or of the parent block -->
                    <xsl:for-each select="($block//div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')], $block/ancestor::div[contains-token(@class, 'block')]//div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')])[1]">
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>

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
        </xsl:for-each>
    </xsl:function>
    
</xsl:stylesheet>