<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
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
xmlns:lapp="&lapp;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:acl="&acl;"
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
    
    <!-- update the chart resource before saving. A mode of its own, not shared with the query save. -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:replace-chart">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- set chart properties -->

    <xsl:template match="ldh:chartType | ldh:categoryVarName | ldh:categoryProperty | ldh:seriesVarName | ldh:seriesProperty" mode="ldh:replace-chart" priority="1"/>

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;ResultSetChart']" mode="ldh:replace-chart" priority="1">
        <xsl:param name="chart-type" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="category" as="xs:string?" tunnel="yes"/>
        <xsl:param name="series" as="xs:string*" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
            
            <xsl:for-each select="$chart-type">
                <ldh:chartType rdf:resource="{.}"/>
            </xsl:for-each>
            <xsl:for-each select="$category">
                <ldh:categoryVarName>
                    <xsl:value-of select="."/>
                </ldh:categoryVarName>
            </xsl:for-each>
            <xsl:for-each select="$series">
                <ldh:seriesVarName>
                    <xsl:value-of select="."/>
                </ldh:seriesVarName>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;GraphChart']" mode="ldh:replace-chart" priority="1">
        <xsl:param name="chart-type" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="category" as="xs:string?" tunnel="yes"/>
        <xsl:param name="series" as="xs:string*" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:for-each select="$chart-type">
                <ldh:chartType rdf:resource="{.}"/>
            </xsl:for-each>
            <xsl:for-each select="$category">
                <ldh:categoryProperty rdf:resource="{.}"/>
            </xsl:for-each>
            <xsl:for-each select="$series">
                <ldh:seriesProperty rdf:resource="{.}"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
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
        
        <xsl:variable name="chart" select="ixsl:new($chart-class, [ id($canvas-id, ixsl:page()) ])"/>
        <!-- design tokens resolved at draw time - Google Charts takes concrete color strings, not var() references -->
        <xsl:variable name="axis-text-style" select="map{ 'color': ldh:css-token('--fg-muted') }" as="map(*)"/>
        <xsl:variable name="axis-title-style" select="map{ 'color': ldh:css-token('--fg-2'), 'italic': false() }" as="map(*)"/>
        <xsl:variable name="gridline-style" select="map{ 'color': ldh:css-token('--border-default') }" as="map(*)"/>
        <xsl:variable name="baseline-color" select="ldh:css-token('--border-strong')" as="xs:string"/>
        <xsl:variable name="options" as="map(xs:string, item())">
            <xsl:map>
                <xsl:if test="exists($width)">
                    <xsl:map-entry key="'width'" select="$width"/>
                </xsl:if>
                <xsl:if test="exists($height)">
                    <xsl:map-entry key="'height'" select="$height"/>
                </xsl:if>
                <xsl:choose>
                    <!-- the Table chart renders as HTML - it is skinned by CSS in ldh.css, not draw options -->
                    <xsl:when test="$chart-type = '&ac;Table'">
                        <xsl:map-entry key="'allowHtml'" select="true()"/>
                        <!-- the HTML table sizes to content by default, unlike the SVG charts which fill their container -->
                        <xsl:if test="not(exists($width))">
                            <xsl:map-entry key="'width'" select="'100%'"/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:map-entry key="'colors'" select="array{ ('--ldh-blue-500', '--ldh-violet-500', '--success-500', '--warning-500', '--danger-500', '--ldh-blue-300', '--ldh-violet-300') ! ldh:css-token(.)[. ne ''] }"/>
                        <xsl:map-entry key="'backgroundColor'" select="'transparent'"/>
                        <xsl:map-entry key="'fontName'" select="normalize-space(translate((tokenize(ldh:css-token('--font-sans'), ',')[1], '')[1], '''&quot;', ''))"/>
                        <xsl:map-entry key="'legend'" select="map{ 'textStyle': $axis-title-style }"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$chart-type = '&ac;BarChart'">
                        <xsl:map-entry key="'hAxis'" select="map{ 'title': $series[1], 'textStyle': $axis-text-style, 'titleTextStyle': $axis-title-style, 'gridlines': $gridline-style, 'baselineColor': $baseline-color }"/>
                        <xsl:map-entry key="'vAxis'" select="map{ 'title': $category, 'textStyle': $axis-text-style, 'titleTextStyle': $axis-title-style, 'gridlines': $gridline-style, 'baselineColor': $baseline-color }"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:map-entry key="'hAxis'" select="map{ 'title': $category, 'textStyle': $axis-text-style, 'titleTextStyle': $axis-title-style, 'gridlines': $gridline-style, 'baselineColor': $baseline-color }"/>
                        <xsl:map-entry key="'vAxis'" select="map{ 'title': $series[1], 'textStyle': $axis-text-style, 'titleTextStyle': $axis-title-style, 'gridlines': $gridline-style, 'baselineColor': $baseline-color }"/>
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
        
        <xsl:choose>
            <!-- a result set with no rows has nothing to chart, and Google Charts validates column types whether or not there are rows to draw: a variable bound in no result types as a string, which it refuses on a value axis, so the absence of data was reported as a datatype error -->
            <xsl:when test="xs:double(ixsl:call($data-table, 'getNumberOfRows', [])) = 0">
                <xsl:variable name="translations" select="document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))" as="document-node()"/>

                <xsl:for-each select="id($canvas-id, ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="ldh-block-blank" role="status">
                            <span class="msi outline" aria-hidden="true">inbox</span>
                            <span class="bb-msg">
                                <xsl:apply-templates select="key('resources', 'no-results', $translations)" mode="ac:label"/>
                            </span>
                            <span class="bb-sub">
                                <xsl:apply-templates select="key('resources', 'no-results-explanation', $translations)" mode="ac:label"/>
                            </span>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ac:draw-chart">
                    <xsl:with-param name="data-table" select="$data-table"/>
                    <xsl:with-param name="canvas-id" select="$canvas-id"/>
                    <xsl:with-param name="chart-type" select="$chart-type"/>
                    <xsl:with-param name="category" select="$category"/>
                    <xsl:with-param name="series" select="$series"/>
                    <xsl:with-param name="height" select="400"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- render chart block -->
    
    <xsl:template match="*[@typeof = ('&ldh;ResultSetChart', '&ldh;GraphChart')][descendant::*[@property = '&spin;query'][@resource]][descendant::*[@property = '&ldh;chartType'][@resource]]" mode="ldh:RenderRow" as="function(item()?) as map(*)" priority="2"> <!-- prioritize above block.xsl -->
        <xsl:param name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:param name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="chart-type-id" select="'chart-type-' || generate-id()" as="xs:string"/>
        <xsl:param name="category-id" select="'category-' || generate-id()" as="xs:string"/>
        <xsl:param name="series-id" select="'series-' || generate-id()" as="xs:string"/>
        <xsl:variable name="query-uri" select="descendant::*[@property = '&spin;query']/@resource" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="descendant::*[@property = '&ldh;chartType']/@resource" as="xs:anyURI?"/>
        <xsl:variable name="category" select="descendant::*[@property = '&ldh;categoryProperty']/@resource | descendant::*[@property = '&ldh;categoryVarName']/text()" as="xs:string?"/>
        <xsl:variable name="series" select="descendant::*[@property = '&ldh;seriesProperty']/@resource | descendant::*[@property = '&ldh;seriesVarName']/text()" as="xs:string*"/>
        <xsl:variable name="canvas-id" select="generate-id() || '-chart-canvas'" as="xs:string?"/>
        <xsl:variable name="canvas-class" select="'chart-canvas'" as="xs:string?"/>

        <!-- Create cache object for this block -->
        <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $about || '`'))">
            <ixsl:set-property name="{'`' || $about || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:if>
        <xsl:variable name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $about || '`')" as="item()"/>

        <!-- Initialize progress counters: 2 steps (query, results) -->
        <xsl:sequence select="ldh:update-progress-counter($cache, map{'container': $container}, 'init', 2)"/>

        <xsl:variable name="request-uri" select="ldh:href($query-uri, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'this': $about,
            'block': $block,
            'container': $container,
            'container-id': $container-id,
            'method': $method,
            'chart-type-id': $chart-type-id,
            'category-id': $category-id,
            'series-id': $series-id,
            'query-uri': $query-uri,
            'chart-type': $chart-type,
            'category': $category,
            'series': $series,
            'canvas-id': $canvas-id,
            'canvas-class': $canvas-class,
            'cache': $cache
          }"/>
        
        <xsl:sequence select="
            ldh:load-block#3(
              $context,
              ldh:chart-self-thunk#1,
              ?
            )
        "/>
    </xsl:template>
    
    <!-- this is the one thunk you hand to load-block#4 -->
    <xsl:function name="ldh:chart-self-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:chart-self-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:render-chart#1) =>
                ixsl:then(ldh:chart-query-thunk#1) =>
                ixsl:then(ldh:chart-results-thunk#1)
        "/>
    </xsl:function>
    
    <!-- only the first HTTP → query‐response lives here -->
    <xsl:function name="ldh:chart-query-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:chart-query-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:chart-query-response#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:chart-results-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:chart-results-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:http-request($context('chart-results-request')) =>
                ixsl:then(ldh:rethread-response($context, ?, 'chart-results-response')) =>
                ixsl:then(ldh:handle-response(?, 'chart-results-response')) =>
                ixsl:then(ldh:chart-results-response#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:render-chart" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="method" select="$context('method')" as="xs:string"/>
        <xsl:variable name="chart-type-id" select="$context('chart-type-id')" as="xs:string"/>
        <xsl:variable name="category-id" select="$context('category-id')" as="xs:string"/>
        <xsl:variable name="series-id" select="$context('series-id')" as="xs:string"/>
        <xsl:variable name="chart-type" select="$context('chart-type')" as="xs:anyURI?"/>
        <xsl:variable name="canvas-id" select="$context('canvas-id')" as="xs:string?"/>
        <xsl:variable name="canvas-class" select="$context('canvas-class')" as="xs:string?"/>
        <!-- placeholder results: the header renders with empty category/series options until ldh:chart-results-response re-renders it from the real results -->
        <xsl:variable name="results" as="document-node()">
            <xsl:document>
                <rdf:RDF/>
            </xsl:document>
        </xsl:variable>

        <xsl:message>ldh:render-chart</xsl:message>

        <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
            <xsl:variable name="header" select=".//*[contains-token(@class, 'ldh-block-head')][1]" as="element()"/>

            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$header"/>

                <xsl:apply-templates select="$results/rdf:RDF" mode="bs2:Chart">
                    <xsl:with-param name="method" select="$method"/>
                    <xsl:with-param name="class" select="()"/>
                    <xsl:with-param name="chart-type" select="($chart-type, xs:anyURI('&ac;Table'))[1]"/>
                    <xsl:with-param name="chart-type-id" select="$chart-type-id"/>
                    <xsl:with-param name="category-id" select="$category-id"/>
                    <xsl:with-param name="series-id" select="$series-id"/>
                    <xsl:with-param name="canvas-id" select="$canvas-id"/>
                    <xsl:with-param name="canvas-class" select="$canvas-class"/>
                    <xsl:with-param name="show-save" select="acl:mode() = '&acl;Write'"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>
    
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

    <!-- the block wrapper carries @about but not @typeof - bs2:Row has the typeof attribute commented out
         (resource.xsl), leaving @typeof on the inner .block-row - so matching on both never fires -->
    <xsl:template match="div[contains-token(@class, 'block')][@about]//button[contains-token(@class, 'btn-create-chart')]" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="textarea-id" select="$block//textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
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
        <xsl:call-template name="ldh:CreateBlock">
            <xsl:with-param name="block" select="$block"/>
            <xsl:with-param name="forClass" select="$forClass"/>
            <!-- title/description come from the class constructor; these are what make it *this* chart -->
            <xsl:with-param name="properties" as="element()*">
                <ldh:chartType rdf:resource="{$chart-type}"/>
                <ldh:categoryVarName><xsl:value-of select="$category"/></ldh:categoryVarName>
                <xsl:for-each select="$series">
                    <ldh:seriesVarName><xsl:value-of select="."/></ldh:seriesVarName>
                </xsl:for-each>
                <spin:query rdf:resource="{$block/@about}"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- save chart onclick -->
    <!-- TO-DO: use @typeof in match so that we don't need a custom button.btn-save-chart class -->
    
    <xsl:template match="div[@typeof]//button[contains-token(@class, 'btn-save-chart')]" mode="ixsl:onclick">
        <xsl:sequence select="ldh:busy-cursor()"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:variable name="query-uri" select="$container//descendant::*[@property = '&spin;query']/@resource" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="$container//form//select[contains-token(@class, 'chart-type')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="category" select="$container//form//select[contains-token(@class, 'chart-category')]/ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="series" as="xs:string*">
            <xsl:for-each select="$container//form//select[contains-token(@class, 'chart-series')]">
                <xsl:variable name="select" select="." as="element()"/>
                <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                    <xsl:sequence select="ixsl:get(ixsl:call(ixsl:get($select, 'selectedOptions'), 'item', [ . ]), 'value')"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="method" select="'PATCH'" as="xs:string"/>
        <xsl:variable name="action" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="accept" select="'application/rdf+xml'" as="xs:string"/>
        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>
        <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(xs:anyURI(ixsl:location())) || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="chart" select="key('resources', $about, $doc)" as="element()"/>
        <!-- update the properties on the chart resource -->
        <xsl:variable name="chart" as="element()">
            <xsl:apply-templates select="$chart" mode="ldh:replace-chart">
                <xsl:with-param name="chart-type" select="$chart-type" tunnel="yes"/>
                <xsl:with-param name="series" select="$series" tunnel="yes"/>
                <xsl:with-param name="category" select="$category" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="triples" select="ldh:descriptions-to-triples($chart)" as="element()*"/>
        <xsl:variable name="update-string" select="ldh:insertdelete-update(ldh:triples-to-bgp(ldh:uri-po-pattern($about)), ldh:triples-to-bgp($triples), ldh:triples-to-bgp(ldh:uri-po-pattern($about)))" as="xs:string"/>
        <xsl:variable name="resources" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:sequence select="ldh:triples-to-descriptions($triples)"/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="request-uri" select="ldh:href($action, map{})" as="xs:anyURI"/>
        <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile -->
        <xsl:variable name="request" select="map{ 'method': $method, 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string, 'headers': map{ 'If-Match': $etag, 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'doc-uri': ac:absolute-path(ldh:base-uri(.)),
            'block': $block,
            'resources': $resources
          }"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:row-form-response#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        "/>
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

        <xsl:message>ldh:chart-query-response</xsl:message>

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
                        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ldh:href(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }, ()))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
                        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
                        <xsl:variable name="request-uri" select="ldh:href($endpoint, map{})" as="xs:anyURI"/>

                        <!-- Mark query response as complete -->
                        <xsl:sequence select="ldh:update-progress-counter($context('cache'), $context, 'complete', ())"/>

                        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }" as="map(*)"/>
                        <xsl:sequence select="map:merge(($context, map{
                            'chart-results-request': $request,
                            'endpoint': $endpoint,
                            'chart-canvas-id': $canvas-id,
                            'show-editor': false(),
                            'show-chart-save': false(),
                            'results-container-id': $container-id || '-query-results'
                        }))"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- error response - could not load query -->
                    <xsl:sequence select="ldh:render-block-error($container, 'block-query-not-loaded', ldh:http-error-key($response?status), $query-uri, $response)"/>

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
    
    <!-- SPARQL results response -->

    <xsl:function name="ldh:chart-results-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('chart-results-response')" as="map(*)"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="chart-canvas-id" select="$context('chart-canvas-id')" as="xs:string"/>
        <xsl:variable name="chart-type" select="$context('chart-type')" as="xs:anyURI"/>
        <xsl:variable name="category" select="$context('category')" as="xs:string?"/>
        <xsl:variable name="series" select="$context('series')" as="xs:string*"/>
        <xsl:variable name="endpoint" select="$context('endpoint')" as="xs:anyURI?"/>
        <xsl:variable name="show-editor" select="$context('show-editor')" as="xs:boolean"/>
        <xsl:variable name="show-chart-save" select="$context('show-chart-save')" as="xs:boolean"/>
        <xsl:variable name="results-container-id" select="$context('results-container-id')"  as="xs:string"/>

        <xsl:message>ldh:chart-results-response</xsl:message>
        
        <xsl:for-each select="$response">
            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

            <xsl:variable name="response" select="." as="map(*)"/>
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                    <xsl:for-each select="?body">
                        <xsl:variable name="results" select="." as="document-node()"/>
                        <xsl:variable name="category" select="if (exists($category)) then $category else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name()))[1] else srx:sparql/srx:head/srx:variable[1]/@name)" as="xs:string?"/>
                        <xsl:variable name="series" select="if (exists($series)) then $series else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name())) else srx:sparql/srx:head/srx:variable/@name)" as="xs:string*"/>

                        <!-- re-render the chart header with the category/series options from the results -->
                        <xsl:for-each select="$container//form/fieldset">
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <xsl:apply-templates select="$results/*" mode="bs2:ChartHeader">
                                    <xsl:with-param name="chart-type" select="$chart-type"/>
                                    <xsl:with-param name="category" select="$category"/>
                                    <xsl:with-param name="series" select="$series"/>
                                    <xsl:with-param name="chart-type-id" select="$context('chart-type-id')"/>
                                    <xsl:with-param name="category-id" select="$context('category-id')"/>
                                    <xsl:with-param name="series-id" select="$context('series-id')"/>
                                </xsl:apply-templates>
                            </xsl:result-document>
                        </xsl:for-each>

                        <!-- Store results in cache -->
                        <ixsl:set-property name="results" select="$results" object="$context('cache')"/>
                        <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
                        <ixsl:set-property name="data-table" select="$data-table" object="$context('cache')"/>

                        <xsl:call-template name="ldh:RenderChart">
                            <xsl:with-param name="data-table" select="$data-table"/>
                            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                            <xsl:with-param name="chart-type" select="$chart-type"/>
                            <xsl:with-param name="category" select="$category"/>
                            <xsl:with-param name="series" select="$series"/>
                        </xsl:call-template>

                        <!-- Mark results response as complete -->
                        <xsl:sequence select="ldh:update-progress-counter($context('cache'), $context, 'complete', ())"/>

                        <xsl:sequence select="$context"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- error response - could not load query results -->
                    <xsl:sequence select="ldh:render-block-error($container, 'block-query-failed', ldh:http-error-key($response?status), (), $response)"/>

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
    
</xsl:stylesheet>