<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY schema "https://schema.org/">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:sh="&sh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:geo="&geo;"
xmlns:srx="&srx;"
xmlns:void="&void;"
xmlns:schema="&schema;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>
    
    <xsl:mode name="ldh:Shape" on-no-match="deep-skip"/>

    <xsl:param name="main-doc" select="/" as="document-node()"/>
    <xsl:param name="acl:Agent" as="document-node()?"/>
    <xsl:param name="acl:mode" select="$foaf:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', ac:absolute-path(base-uri()), $main-doc)/rdf:type/@rdf:resource, key('resources', ac:absolute-path(base-uri()), $main-doc)/rdf:type/@rdf:resource/ldh:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>
    
    <!-- schema.org BREADCRUMBS -->
    
    <xsl:template match="rdf:RDF" mode="schema:BreadCrumbList">
        <xsl:variable name="resource" select="key('resources', ac:absolute-path(base-uri()))" as="element()?"/>

        <xsl:if test="$resource">
            <xsl:variable name="doc-with-ancestors" select="ldh:doc-with-ancestors($resource)" as="element()*"/>

            <rdf:RDF>
                <rdf:Description rdf:nodeID="breadcrumb-list">
                    <rdf:type rdf:resource="&schema;BreadcrumbList"/>

                    <!-- position index has to start from Root=1, so we need to reverse the ancestor sequence -->
                    <xsl:for-each select="reverse($doc-with-ancestors)">
                        <schema:itemListElement rdf:nodeID="item{position()}"/> <!-- rdf:nodeID aligned with schema:BreadCrumbListItem output -->
                    </xsl:for-each>
                </rdf:Description>

                <!-- position index has to start from Root=1, so we need to reverse the ancestor sequence -->
                <xsl:apply-templates select="reverse($doc-with-ancestors)" mode="schema:BreadCrumbListItem"/>
            </rdf:RDF>
        </xsl:if>
    </xsl:template>

    <xsl:template match="srx:sparql" mode="schema:BreadCrumbList"/>

    <!-- walks up the ancestor document chain and collects them -->
    <xsl:function name="ldh:doc-with-ancestors" as="element()*">
        <xsl:param name="resource" as="element()"/>
        <xsl:variable name="parent-uri" select="$resource/sioc:has_container/@rdf:resource | $resource/sioc:has_parent/@rdf:resource" as="xs:anyURI?"/>
        
        <xsl:sequence select="$resource"/>

        <xsl:if test="$parent-uri">
            <xsl:if test="doc-available(ac:document-uri($parent-uri))">
                <xsl:variable name="parent-doc" select="document(ac:document-uri($parent-uri))" as="document-node()"/>
                <xsl:variable name="parent" select="key('resources', $parent-uri, $parent-doc)" as="element()?"/>

                <xsl:if test="$parent">
                    <xsl:sequence select="ldh:doc-with-ancestors($parent)"/>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:function>

    <!-- BODY -->
    
    <!-- always show errors (except ConstraintViolations) in block mode -->
    <xsl:template match="rdf:RDF[not(key('resources', ac:absolute-path(base-uri())))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))] | rdf:RDF[not(key('resources', ac:absolute-path(base-uri())))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&sh;ValidationResult'))]" mode="xhtml:Body" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span12'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
        
            <xsl:apply-templates mode="bs2:Block"/>
        </div>
    </xsl:template>
    
    <!-- MODE TABS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:ModeTabs">
        <xsl:param name="has-content" as="xs:boolean"/>
        <xsl:param name="active-mode" as="xs:anyURI?"/>
        <xsl:param name="forClass" as="xs:anyURI?"/>
        <xsl:param name="ajax-rendering" select="true()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="base-uri()" as="xs:anyURI"/>

        <div class="row-fluid">
            <ul class="nav nav-tabs offset2 span7">
                <li class="content-mode{if ((empty($active-mode) and $has-content and not($forClass)) or $active-mode = '&ldh;ContentMode') then ' active' else() }">
                    <a href="{ldh:href($ldt:base, ac:absolute-path(ac:absolute-path(base-uri())), ldh:query-params(xs:anyURI('&ldh;ContentMode')), ac:absolute-path(base-uri()))}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'content', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </li>

                <xsl:for-each select="key('resources', '&ac;ReadMode', document(ac:document-uri('&ac;')))">
                    <xsl:apply-templates select="." mode="bs2:ModeTabsItem">
                        <xsl:with-param name="active" select="@rdf:about = $active-mode or (empty($active-mode) and not($has-content))"/>
                        <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each>
                <xsl:for-each select="key('resources', '&ac;MapMode', document(ac:document-uri('&ac;')))">
                    <xsl:apply-templates select="." mode="bs2:ModeTabsItem">
                        <xsl:with-param name="active" select="@rdf:about = $active-mode"/>
                        <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each>
                <xsl:if test="$ajax-rendering">
                    <xsl:for-each select="key('resources', '&ac;ChartMode', document(ac:document-uri('&ac;')))">
                        <xsl:apply-templates select="." mode="bs2:ModeTabsItem">
                            <xsl:with-param name="active" select="@rdf:about = $active-mode"/>
                            <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:if>
                <xsl:for-each select="key('resources', '&ac;GraphMode', document(ac:document-uri('&ac;')))">
                    <xsl:apply-templates select="." mode="bs2:ModeTabsItem">
                        <xsl:with-param name="active" select="@rdf:about = $active-mode"/>
                        <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </ul>
        </div>
    </xsl:template>
    
    <!-- CONTENT LIST -->
    
    <xsl:template match="rdf:RDF" mode="ldh:ContentList">
        <xsl:apply-templates select="key('resources', ac:absolute-path(base-uri()))" mode="#current"/>
        
        <!-- only show buttons to agents who have sufficient access to modify them -->
        <xsl:if test="$acl:mode = '&acl;Append'">
            <div class="row-fluid">
                <div class="main offset2 span7">
                    <p>
                        <button type="button" class="btn btn-primary create-action add-xhtml-content">
                            <xsl:apply-templates select="key('resources', 'html', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </button>
                        <button type="button" class="btn btn-primary create-action add-resource-content">
                            <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </button>
                    </p>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    
    <!-- ROW BLOCK -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Row">
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="classes" as="element()*"/>

        <!-- select elements explicitly, because Saxon-JS chokes on text nodes here -->
        <!-- hide the current document resource and the content resources -->
        <xsl:apply-templates select="*" mode="#current">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
        
        <xsl:if test="$create-resource">
            <div class="create-resource row-fluid">
                <div class="main offset2 span7">
                    <xsl:apply-templates select="." mode="bs2:Create">
                        <xsl:with-param name="classes" select="$classes"/>
                    </xsl:apply-templates>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- MAP -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Map">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="class" select="'map-canvas'" as="xs:string?"/>
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
        </div>
    </xsl:template>
    
    <!-- CHART -->

    <!-- graph chart (for RDF/XML results) -->

    <xsl:template match="rdf:RDF" mode="bs2:Chart">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&ldh;GraphChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/> <!-- table is the default chart type -->
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>
        <xsl:param name="show-save" select="true()" as="xs:boolean"/>

        <xsl:if test="$show-controls">
            <form method="{$method}" action="{$action}">
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
                </xsl:if>
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
                            <!-- TO-DO: replace with xsl:apply-templates on ac:Chart subclasses as in imports/ldh.xsl -->
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
                            <select id="{$category-id}" name="ou" class="input-large chart-category">
                                <option value="">
                                    <!-- URI is the default category -->
                                    <xsl:if test="not($category)">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>[URI/ID]</xsl:text>
                                </option>

                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
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
                            </select>
                        </div>
                        <div class="span4">
                            <label for="{$series-id}">Series</label>
                            <select id="{$series-id}" name="ou" multiple="multiple" class="input-large chart-series">
                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
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
                            </select>
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
        
                <xsl:if test="$show-save">
                    <div class="form-actions">
                        <button class="btn btn-primary btn-save-chart" type="button">
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                            </xsl:apply-templates>
                            
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </button>
                    </div>
                </xsl:if>
            </form>
        </xsl:if>
    </xsl:template>

    <!-- table chart (for SPARQL XML results) -->

    <xsl:template match="srx:sparql" mode="bs2:Chart">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&ldh;ResultSetChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/> <!-- table is the default chart type -->
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>
        <xsl:param name="show-save" select="true()" as="xs:boolean"/>

        <xsl:if test="$show-controls">
            <form method="{$method}" action="{$action}">
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
                </xsl:if>
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
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&ldh;categoryVarName'"/>
                            </xsl:call-template>

                            <label for="{$category-id}">Category</label>
                            <select id="{$category-id}" name="ol" class="input-large chart-category">
                                <xsl:for-each select="srx:head/srx:variable">
                                    <!-- leave the original variable order so it can be controlled from query -->

                                    <option value="{@name}">
                                        <xsl:if test="$category = @name">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:value-of select="@name"/>
                                    </option>
                                </xsl:for-each>
                            </select>
                        </div>
                        <div class="span4">
                            <label for="{$series-id}">Series</label>
                            <select id="{$series-id}" name="ol" multiple="multiple" class="input-large chart-series">
                                <xsl:for-each select="srx:head/srx:variable">
                                    <!-- leave the original variable order so it can be controlled from query -->

                                    <option value="{@name}">
                                        <xsl:if test="$series = @name">
                                            <xsl:attribute name="selected" select="'selected'"/>
                                        </xsl:if>

                                        <xsl:value-of select="@name"/>
                                    </option>
                                </xsl:for-each>
                            </select>
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
        
                <xsl:if test="$show-save">
                    <div class="form-actions">
                        <button class="btn btn-primary btn-save-chart" type="button">
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                            </xsl:apply-templates>
                            
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </button>
                    </div>
                </xsl:if>
            </form>
        </xsl:if>
    </xsl:template>

    <!-- CONSTRUCTOR -->
    
    <xsl:template match="rdf:RDF" mode="ldh:Constructor" as="document-node()">
        <xsl:param name="forClass" as="xs:anyURI"/>
        <xsl:param name="createGraph" as="xs:boolean"/>
        <xsl:param name="constructor-query" as="xs:string?"/>

        <xsl:document>
            <xsl:variable name="constructors" select="ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $forClass return '&lt;' || $type || '&gt;', ' ') || ' }')" as="document-node()?"/>
            <!-- ldh:construct() expects ($forClass, $constructor*) map -->
            <xsl:variable name="constructed-doc" select="ldh:construct(map{ $forClass: $constructors//srx:result[srx:binding[@name = 'Type'] = $forClass]/srx:binding[@name = 'construct']/srx:literal/string() })" as="document-node()"/>

            <xsl:apply-templates select="$constructed-doc" mode="ldh:SetDocumentURI"/>
        </xsl:document>
    </xsl:template>

    <!-- SHAPE -->
    
    <!-- converts sh:NodeShape into an rdf:Description of the new instance -->
    
    <xsl:template match="rdf:RDF" mode="ldh:Shape" as="document-node()">
        <xsl:document>
            <rdf:RDF>
                <xsl:apply-templates mode="#current"/>
            </rdf:RDF>
        </xsl:document>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&sh;NodeShape']" mode="ldh:Shape">
        <rdf:Description rdf:nodeID="{generate-id()}-instance">
            <xsl:apply-templates mode="#current"/>
        </rdf:Description>
    </xsl:template>

    <xsl:template match="sh:targetClass[@rdf:resource]" mode="ldh:Shape">
        <rdf:type rdf:resource="{@rdf:resource}"/>
    </xsl:template>
    
    <xsl:template match="sh:property[key('resources', (@rdf:resource, @rdf:nodeID)[1])[sh:path/@rdf:resource][sh:minCount]]" mode="ldh:Shape" priority="1">
        <xsl:variable name="triple" as="element()*">
            <xsl:next-match/>
        </xsl:variable>

        <xsl:for-each select="1 to key('resources', (@rdf:resource, @rdf:nodeID)[1])/sh:minCount">
            <xsl:copy-of select="$triple"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="sh:property[key('resources', (@rdf:resource, @rdf:nodeID)[1])[sh:path/@rdf:resource]]" mode="ldh:Shape">
        <xsl:for-each select="key('resources', (@rdf:resource, @rdf:nodeID)[1])">
            <xsl:variable name="property" select="." as="element()"/>
            <xsl:variable name="namespace" select="if (contains(sh:path/@rdf:resource, '#')) then substring-before(sh:path/@rdf:resource, '#') || '#' else string-join(tokenize(sh:path/@rdf:resource, '/')[not(position() = last())], '/') || '/'" as="xs:string"/>
            <xsl:variable name="local-name" select="if (contains(sh:path/@rdf:resource, '#')) then substring-after(sh:path/@rdf:resource, '#') else tokenize(sh:path/@rdf:resource, '/')[last()]" as="xs:string"/>
            
            <xsl:element namespace="{$namespace}" name="{$local-name}">
                <rdf:Description>
                    <xsl:choose>
                        <xsl:when test="$property/sh:class/@rdf:resource">
                            <rdf:type rdf:resource="{$property/sh:class/@rdf:resource}"/>
                        </xsl:when>
                        <xsl:when test="$property/sh:nodeKind/@rdf:resource = ('&sh;BlankNode', '&sh;IRI', '&sh;BlankNodeOrIRI')">
                            <rdf:type rdf:resource="&rdfs;Resource"/>
                        </xsl:when>
<!--                            <xsl:when test="$property/sh:nodeKind/@rdf:resource = '&sh;Literal'">
                            <rdf:type rdf:resource="&rdfs;Literal"/>
                        </xsl:when>-->
                        <xsl:when test="$property/sh:datatype/@rdf:resource">
                            <rdf:type rdf:resource="{$property/sh:datatype/@rdf:resource}"/>
                        </xsl:when>
                    </xsl:choose>
                </rdf:Description>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ROW FORM -->

    <xsl:template match="rdf:RDF[$ac:forClass = ('&ldh;CSVImport', '&ldh;RDFImport')][$ac:method = 'GET']" mode="bs2:RowForm" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="action" select="ac:build-uri(resolve-uri('importer', $ldt:base), map{ '_method': 'PUT', 'forClass': string($ac:forClass), 'mode': '&ac;EditMode' })" as="xs:anyURI"/>
        <xsl:param name="classes" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="classes" select="$classes"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[$ac:forClass][$ac:method = 'GET']" mode="bs2:RowForm" priority="1" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="base-uri" as="xs:anyURI" tunnel="yes"/>
        <!-- document resource might not always be present in the form (e.g. ldh:Content only) -->
        <xsl:param name="document-uri" select="if (key('resources-by-type', ('&dh;Container', '&dh;Item'))/@rdf:about) then key('resources-by-type', ('&dh;Container', '&dh;Item'))/@rdf:about else $base-uri" as="xs:anyURI"/> <!-- $doc-uri of the constructed document -->
        <xsl:param name="action" select="ac:build-uri($document-uri, map{ '_method': 'PUT', 'forClass': string($ac:forClass), 'mode': '&ac;EditMode' })" as="xs:anyURI"/>
        <xsl:param name="classes" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="document-uri" select="$document-uri" tunnel="yes"/>
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="classes" select="$classes"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:RowForm" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="base-uri" select="base-uri()" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="action" select="ldh:href($ldt:base, ac:absolute-path($base-uri), map{}, ac:build-uri(ac:absolute-path($base-uri), map{ '_method': 'PUT', 'mode': for $mode in $ac:mode return string($mode) }))" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="'multipart/form-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="types" select="distinct-values(rdf:Description/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:param name="constructor-query" as="xs:string?" tunnel="yes"/>
        <xsl:param name="constraint-query" as="xs:string?" tunnel="yes"/>
        <xsl:param name="shape-query" as="xs:string?" tunnel="yes"/>
        <xsl:variable name="constructors" select="if ($constructor-query and exists($types)) then (ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?"/>
        <xsl:variable name="constraints" select="if ($constraint-query and exists($types)) then (ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?"/>
        <xsl:variable name="shapes" select="if ($shape-query and exists($types)) then (ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $shape-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?"/>
        <xsl:variable name="type-metadata" select="if (exists($types)) then ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?"/>
        <xsl:variable name="property-uris" select="distinct-values(rdf:Description/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <xsl:variable name="property-metadata" select="if (exists($property-uris)) then ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?"/>

        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset" select="$accept-charset"/>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype" select="$enctype"/>
            </xsl:if>

            <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'rdf'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            
            <xsl:apply-templates mode="bs2:Exception"/>

            <!-- show the current document on the top -->
            <xsl:apply-templates select="*[@rdf:about = ac:absolute-path(base-uri())]" mode="#current">
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
            </xsl:apply-templates>
            <!-- show the rest of the resources (contents, instances) below it -->
            <xsl:apply-templates select="*[not(@rdf:about = ac:absolute-path(base-uri()))]" mode="#current">
                <xsl:sort select="ac:label(.)"/>
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
            </xsl:apply-templates>

            <xsl:if test="$create-resource">
                <div class="create-resource row-fluid">
                    <div class="main offset2 span7">
                        <xsl:apply-templates select="." mode="bs2:Create">
                            <xsl:with-param name="classes" select="$classes"/>
                        </xsl:apply-templates>
                    </div>
                </div>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:FormActions">
                <xsl:with-param name="button-class" select="$button-class"/>
            </xsl:apply-templates>
        </form>
    </xsl:template>

    <!-- MODAL FORM ACTIONS -->
    
<!--    <xsl:template match="rdf:RDF" mode="bs2:ModalFormActions">
        <xsl:param name="class" select="'form-actions modal-footer'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <button type="submit" class="{$button-class}">
                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                    <xsl:with-param name="class" select="$button-class"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </button>

            <button type="button" class="btn">
                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </button>

            <button type="reset" class="btn">
                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </button>
        </div>
    </xsl:template>-->

    <!-- FORM ACTIONS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:FormActions">
        <xsl:param name="class" select="'row-fluid'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <div class="form-actions main offset2 span7">
                <button type="submit" class="{$button-class}">
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="$button-class"/>
                    </xsl:apply-templates>
                    
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </button>

                <button type="reset" class="btn">
                    <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>
                    
                    <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </button>
                
                <button type="button" class="btn btn-cancel">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
            </div>
        </div>
    </xsl:template>

    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&ldh;ResourceExistsException', document(ac:document-uri('&ldh;')))" mode="ldh:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="key('resources', '&ldh;ResourceExistsException', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>

    <!-- CREATE -->
    
    <xsl:template match="rdf:RDF[$acl:mode = '&acl;Append'] | srx:sparql[$acl:mode = '&acl;Append']" mode="bs2:Create" priority="1">
        <xsl:param name="class" select="'btn-group'" as="xs:string?"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="base-uri()" as="xs:anyURI"/>
        <xsl:param name="show-instance" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <xsl:if test="$show-instance">
                    <xsl:apply-templates select="key('resources', '&owl;NamedIndividual', document(ac:document-uri('&owl;')))" mode="bs2:ConstructorListItem">
                        <xsl:with-param name="create-graph" select="$create-graph"/>
                        <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>

                    <li class="divider"></li>
                </xsl:if>
                
                <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                    <xsl:with-param name="create-graph" select="$create-graph"/>
                    <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:Create"/>
    
    <!-- OBJECT -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
</xsl:stylesheet>
