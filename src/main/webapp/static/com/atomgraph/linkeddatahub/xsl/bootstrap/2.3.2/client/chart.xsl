<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
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
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" as="xs:string?"/>

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
        
        <xsl:variable name="js-statement" as="element()">
            <root statement="(new {$chart-class}(document.getElementById('{$canvas-id}')))"/>
        </xsl:variable>
        <xsl:variable name="chart" select="ixsl:eval(string($js-statement/@statement))"/>
                
        <xsl:variable name="options" as="map(xs:string, item())">
            <xsl:map>
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

    <xsl:template name="render-chart">
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
            <xsl:with-param name="width" select="'100%'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="onAddSaveChartForm">
        <xsl:param name="query-string" as="xs:string"/>
        <xsl:param name="service-uri" as="xs:anyURI?"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string"/>
        <xsl:variable name="forClass" select="xs:anyURI('&def;' || upper-case(substring($query-type, 1, 1)) || lower-case(substring($query-type, 2)))" as="xs:anyURI"/>
        <!--- show a modal form if this button is in a <fieldset>, meaning on a resource-level and not form level. Otherwise (e.g. for the "Create" button) show normal form -->
        <xsl:variable name="modal-form" select="true()" as="xs:boolean"/>
        <xsl:variable name="href" select="ac:build-uri(ldh:absolute-path(ldh:href()), let $params := map{ 'forClass': string($forClass) } return if ($modal-form) then map:merge(($params, map{ 'mode': '&ac;ModalMode' })) else $params)" as="xs:anyURI"/>
        <xsl:message>Form URI: <xsl:value-of select="$href"/></xsl:message>

        <xsl:variable name="form-id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        <xsl:call-template name="onAddForm">
            <xsl:with-param name="add-class" select="'form-save-chart'"/>
            <xsl:with-param name="new-form-id" select="$form-id"/>
        </xsl:call-template>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="form" select="id($form-id, ixsl:page())" as="element()"/>
        
        <xsl:variable name="item-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sioc;has_container']]" as="element()"/>
        <xsl:variable name="container" select="resolve-uri('charts/', $ldt:base)" as="xs:anyURI"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $container, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onTypeaheadResourceLoad">
                    <xsl:with-param name="resource-uri" select="$container"/>
                    <xsl:with-param name="typeahead-span" select="$item-control-group/div[contains-token(@class, 'controls')]/span[1]"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        
        <!-- handle both ResultSetChart and GraphChart here -->
        <xsl:variable name="chart-type-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&ldh;chartType']]" as="element()"/>
        <ixsl:set-property name="value" select="$chart-type" object="$chart-type-group/descendant::select[@name = 'ou']"/>
        <xsl:variable name="category-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = ('&ldh;categoryVarName', '&ldh;categoryProperty')]]" as="element()"/>
        <ixsl:set-property name="value" select="$category" object="$category-control-group/descendant::input[@name = ('ou', 'ol')]"/>
        <!-- TO-DO: support more than one series variable -->
        <xsl:variable name="series-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = ('&ldh;seriesVarName', '&ldh;seriesProperty')]]" as="element()"/>
        <ixsl:set-property name="value" select="$series" object="$series-control-group/descendant::input[@name = ('ou', 'ol')]"/>
        <xsl:variable name="query-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&spin;query']]" as="element()*"/>
        <xsl:variable name="target-id" select="$query-control-group/descendant::input[@name = 'ou']/@id" as="xs:string"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddSaveQueryForm">
                    <xsl:with-param name="query-string" select="$query-string"/>
                    <xsl:with-param name="service-uri" select="$service-uri"/>
                    <xsl:with-param name="add-class" select="()"/>
                    <xsl:with-param name="form-id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])"/>
                    <xsl:with-param name="target-id" select="$target-id"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- chart content -->
    <xsl:template match="*[@rdf:about][spin:query/@rdf:resource][ldh:chartType/@rdf:resource]" mode="ldh:Content" priority="1">
        <xsl:param name="container" as="element()"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:param name="content-uri" select="xs:anyURI(translate(@rdf:about, '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="query-uri" select="xs:anyURI(spin:query/@rdf:resource)" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="xs:anyURI(ldh:chartType/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:variable name="category" select="ldh:categoryProperty/@rdf:resource | ldh:categoryVarName" as="xs:string?"/>
        <xsl:variable name="series" select="ldh:seriesProperty/@rdf:resource | ldh:seriesVarName" as="xs:string*"/>
        <xsl:message>$chart-type: <xsl:value-of select="$chart-type"/> $category: <xsl:value-of select="$category"/> $series: <xsl:value-of select="$series"/></xsl:message>

        <xsl:for-each select="$container//div[@class = 'bar']">
            <ixsl:set-style name="width" select="'66%'" object="."/>
        </xsl:for-each>

        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $query-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onChartQueryLoad">
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="query-uri" select="$query-uri"/>
                    <xsl:with-param name="chart-type" select="$chart-type"/>
                    <xsl:with-param name="category" select="$category"/>
                    <xsl:with-param name="series" select="$series"/>
                    <xsl:with-param name="container" select="$container"/>
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
        <!-- $content-uri value comes from the @data-content-uri -->
        <xsl:variable name="container" select="(ancestor::div[contains-token(@class, 'resource-content')], ancestor::div[contains-token(@class, 'sparql-results')])[1]" as="element()?"/>
        <xsl:variable name="content-uri" select="xs:anyURI(translate(if ($container) then ixsl:get($container, 'dataset.contentUri') else ac:uri(), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::form/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri), 'results')" as="document-node()"/>
                
        <xsl:if test="$chart-type and ($category or $results/rdf:RDF) and exists($series)">
            <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>

            <xsl:call-template name="render-chart">
                <xsl:with-param name="data-table" select="$data-table"/>
                <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
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
        <!-- $content-uri value comes from the @data-content-uri -->
        <xsl:variable name="container" select="(ancestor::div[contains-token(@class, 'resource-content')], ancestor::div[contains-token(@class, 'sparql-results')])[1]" as="element()?"/>
        <xsl:variable name="content-uri" select="xs:anyURI(translate(if ($container) then ixsl:get($container, 'dataset.contentUri') else ac:uri(), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::form/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri), 'results')" as="document-node()"/>

        <xsl:if test="$chart-type and ($category or $results/rdf:RDF) and exists($series)">
            <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>

            <xsl:call-template name="render-chart">
                <xsl:with-param name="data-table" select="$data-table"/>
                <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
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
        <!-- $content-uri value comes from the @data-content-uri -->
        <xsl:variable name="container" select="(ancestor::div[contains-token(@class, 'resource-content')], ancestor::div[contains-token(@class, 'sparql-results')])[1]" as="element()?"/>
        <xsl:variable name="content-uri" select="xs:anyURI(translate(if ($container) then ixsl:get($container, 'dataset.contentUri') else ac:uri(), '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="chart-canvas-id" select="ancestor::form/following-sibling::div/@id" as="xs:string"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri), 'results')" as="document-node()"/>

        <xsl:if test="$chart-type and ($category or $results/rdf:RDF) and exists($series)">
            <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>

            <xsl:call-template name="render-chart">
                <xsl:with-param name="data-table" select="$data-table"/>
                <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- save chart -->
    
    <xsl:template match="button[contains-token(@class, 'btn-save-chart')]" mode="ixsl:onclick">
        <xsl:variable name="textarea-id" select="'query-string'" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('query-service'), 'value'))" as="xs:anyURI?"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string"/>
        <xsl:variable name="forClass" select="if (upper-case($query-type) = ('SELECT', 'ASK')) then xs:anyURI('&def;ResultSetChart') else xs:anyURI('&def;GraphChart')" as="xs:anyURI"/>
        <xsl:message>Query type: <xsl:value-of select="$query-type"/> Chart $forClass: <xsl:value-of select="$forClass"/></xsl:message>
        <!--- show a modal form if this button is in a <fieldset>, meaning on a resource-level and not form level. Otherwise (e.g. for the "Create" button) show normal form -->
        <xsl:variable name="modal-form" select="true()" as="xs:boolean"/>
        <xsl:variable name="href" select="ac:build-uri(ldh:absolute-path(ldh:href()), let $params := map{ 'forClass': string($forClass) } return if ($modal-form) then map:merge(($params, map{ 'mode': '&ac;ModalMode' })) else $params)" as="xs:anyURI"/>
        <xsl:message>Form URI: <xsl:value-of select="$href"/></xsl:message>
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
        <xsl:message>$chart-type: <xsl:value-of select="$chart-type"/> $category: <xsl:value-of select="$category"/> $series: <xsl:value-of select="$series"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddSaveChartForm">
                    <xsl:with-param name="query-string" select="$query-string"/>
                    <xsl:with-param name="service-uri" select="$service-uri"/>
                    <xsl:with-param name="chart-type" select="$chart-type"/>
                    <xsl:with-param name="category" select="$category"/>
                    <xsl:with-param name="series" select="$series"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <xsl:template name="onChartQueryLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="query-type" select="xs:anyURI(key('resources', $query-uri)/rdf:type/@rdf:resource)" as="xs:anyURI"/>
                    <xsl:variable name="query-string" select="key('resources', $query-uri)/sp:text" as="xs:string"/>
                    <!-- TO-DO: use SPARQLBuilder to set LIMIT -->
                    <!--<xsl:variable name="query-string" select="concat($query-string, ' LIMIT 100')" as="xs:string"/>-->
                    <xsl:variable name="service-uri" select="xs:anyURI(key('resources', $query-uri)/ldh:service/@rdf:resource)" as="xs:anyURI?"/>
                    <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
                    <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), ac:endpoint())[1]" as="xs:anyURI"/>
                    <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, $results-uri)" as="xs:anyURI"/>

                    <!-- update progress bar -->
                    <xsl:for-each select="$container//div[@class = 'bar']">
                        <ixsl:set-style name="width" select="'83%'" object="."/>
                    </xsl:for-each>

                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }">
                            <xsl:call-template name="onSPARQLResultsLoad">
                                <xsl:with-param name="content-uri" select="$content-uri"/>
                                <!-- if  the container is full-width row (.row-fluid), render results in the middle column (.span7) -->
                                <xsl:with-param name="container" select="if (contains-token($container/@class, 'row-fluid')) then $container/div[contains-token(@class, 'span7')] else $container"/>
                                <xsl:with-param name="container-id" select="ixsl:get($container, 'id')"/>
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                                <xsl:with-param name="show-editor" select="false()"/>
                                <xsl:with-param name="content-method" select="xs:QName('ixsl:append-content')"/>
                                <xsl:with-param name="push-state" select="false()"/>
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