<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx     "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:geo="&geo;"
xmlns:srx="&srx;"
xmlns:void="&void;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>
    
    <xsl:param name="main-doc" select="/" as="document-node()"/>
    <xsl:param name="acl:Agent" as="document-node()?"/>
    <xsl:param name="acl:mode" select="$acl:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', ac:uri(), $main-doc)/rdf:type/@rdf:resource, key('resources', ac:uri(), $main-doc)/rdf:type/@rdf:resource/apl:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>

    <!-- BODY -->
    
    <!-- always show errors (except ConstraintViolations) in block mode -->
    <xsl:template match="rdf:RDF[not(key('resources', ac:uri()))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="xhtml:Body" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span12'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
        
            <xsl:apply-templates mode="bs2:Block"/>
        </div>
    </xsl:template>
    
    <!-- BLOCK ROW -->
    
    <xsl:template match="rdf:RDF" mode="bs2:BlockRow">
        <xsl:apply-templates mode="#current">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
        
    <!-- CONTENT -->
    
    <xsl:template match="rdf:RDF" mode="apl:Content">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <!-- MAP -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Map">
        <xsl:param name="canvas-id" select="'map-canvas'" as="xs:string"/>

        <div id="{$canvas-id}"/>
    </xsl:template>
        
    <!-- CHART -->

    <!-- graph chart (for RDF/XML results) -->

    <xsl:template match="rdf:RDF" mode="bs2:Chart">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" select="distinct-values(*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <xsl:param name="canvas-id" select="'chart-canvas'" as="xs:string"/>

        <xsl:apply-templates select="." mode="bs2:ChartForm">
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:apply-templates>

        <div id="{$canvas-id}"></div>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="bs2:ChartForm" priority="-1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="xs:anyURI('&def;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&def;GraphChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $apl:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
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
                    <div class="row-fluid">
                        <div class="span4">
                            <label for="{$chart-type-id}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&apl;chartType', document(ac:document-uri('&apl;')))" mode="ac:label"/>
                                </xsl:value-of>
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
                </fieldset>

                <xsl:if test="$show-save">
                    <div class="form-actions">
                        <button class="btn btn-primary btn-save-chart" type="button">
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

    <xsl:template match="srx:sparql" mode="bs2:Chart">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
        <xsl:param name="category" select="srx:head/srx:variable[1]/@name" as="xs:string?"/>
        <xsl:param name="series" select="srx:head/srx:variable/@name" as="xs:string*"/>
        <xsl:param name="canvas-id" select="'canvas-id'" as="xs:string"/>

        <xsl:apply-templates select="." mode="bs2:ChartForm">
            <xsl:with-param name="chart-type" select="$chart-type"/>
            <xsl:with-param name="category" select="$category"/>
            <xsl:with-param name="series" select="$series"/>
        </xsl:apply-templates>

        <div id="{$canvas-id}"></div>
    </xsl:template>

    <xsl:template match="srx:sparql" mode="bs2:ChartForm">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="xs:anyURI('&def;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&def;ResultSetChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $apl:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
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
                    <div class="row-fluid">
                        <div class="span4">
                            <label for="{$chart-type-id}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&apl;chartType', document(ac:document-uri('&apl;')))" mode="ac:label"/>
                                </xsl:value-of>
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
                </fieldset>
                
                <xsl:if test="$show-save">
                    <div class="form-actions">
                        <button class="btn btn-primary btn-save-chart" type="button">
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                            </xsl:apply-templates>
                        </button>
                    </div>
                </xsl:if>
            </form>
        </xsl:if>
    </xsl:template>
    
    <!-- FORM -->

    <xsl:template match="rdf:RDF" mode="bs2:ModalForm" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="ac:build-uri($a:graphStore, map{ 'forClass': string($ac:forClass), 'mode': '&ac;ModalMode' })" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="'multipart/form-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="constructor" select="ac:construct-doc($apl:ontology, $ac:forClass, $apl:base)" as="document-node()"/>

        <div class="modal modal-constructor fade in">
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

                <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'rdf'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>

                <input type="hidden" class="target-id"/>

                <div class="modal-header">
                    <button type="button" class="close">&#215;</button>

                    <!--<xsl:apply-templates select="." mode="bs2:Legend"/>-->
                </div>

                <div class="modal-body">
                    <xsl:apply-templates mode="bs2:Exception"/>

                    <xsl:choose>
                        <xsl:when test="$ac:forClass and not(key('resources-by-type', '&spin;ConstraintViolation'))">
                            <xsl:apply-templates select="$constructor/rdf:RDF/*" mode="bs2:Form">
                                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="bs2:Form">
                                <xsl:sort select="ac:label(.)"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>

                <xsl:apply-templates select="." mode="bs2:FormActions">
                    <xsl:with-param name="modal" select="true()"/>
                    <xsl:with-param name="button-class" select="$button-class"/>
                </xsl:apply-templates>
            </form>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:Form" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI(if (not(starts-with(ac:uri(), $ac:contextUri))) then ac:build-uri($apl:base, map { 'uri': string(ac:uri()) }) else ac:uri())" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="'multipart/form-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="constructor" select="ac:construct-doc($apl:ontology, $ac:forClass, $apl:base)" as="document-node()"/>
        <xsl:param name="classes" as="element()*"/>

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

            <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'rdf'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>

            <input type="hidden" class="target-id"/>

            <xsl:apply-templates mode="bs2:Exception"/>

            <xsl:choose>
                <xsl:when test="$ac:forClass and not(key('resources-by-type', '&spin;ConstraintViolation'))">
                    <xsl:apply-templates select="$constructor/rdf:RDF/*" mode="bs2:Form">
                        <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="*" mode="#current">
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="$create-resource">
                <xsl:apply-templates select="." mode="bs2:Create">
                    <xsl:with-param name="classes" select="$classes"/>
                    <xsl:with-param name="show-document-classes" select="false()"/>
                </xsl:apply-templates>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:FormActions">
                <xsl:with-param name="button-class" select="$button-class"/>
            </xsl:apply-templates>
        </form>
    </xsl:template>
    
    <!-- FORM ACTIONS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:FormActions">
        <xsl:param name="modal" select="false()" as="xs:boolean"/>
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div class="form-actions {if ($modal) then 'modal-footer' else ''}">
            <button type="submit" class="{$button-class}">
                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="$button-class"/>
                </xsl:apply-templates>
            </button>

            <xsl:if test="$modal">
                <button type="button" class="btn">
                    <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>
                </button>
            </xsl:if>

            <button type="reset" class="btn">
                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
        </div>
    </xsl:template>

    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document(ac:document-uri('&apl;')))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document(ac:document-uri('&apl;')))" mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>

    <!-- CREATE -->

    <xsl:template match="rdf:RDF[$acl:mode = '&acl;Append']" mode="bs2:CreateDocument" priority="1">
        <xsl:param name="class" select="'btn-group'" as="xs:string?"/>
        <xsl:param name="classes" as="element()*"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </ul>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:CreateDocument"/>
    
    <xsl:template match="rdf:RDF[$acl:mode = '&acl;Append']" mode="bs2:Create" priority="1">
        <xsl:param name="class" select="'btn-group'" as="xs:string?"/>
        <xsl:param name="default-classes" select="key('resources-by-type', '&rdfs;Class', document(ac:document-uri('&def;')))[not(@rdf:about = ('&def;Root', '&def;Container', '&def;Item'))]" as="element()*"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="show-document-classes" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <xsl:variable name="constructor-list" as="element()*">
                    <xsl:call-template name="bs2:ConstructorList">
                        <xsl:with-param name="ontology" select="key('resources', $apl:ontology, document(ac:document-uri($apl:ontology)))"/>
                        <xsl:with-param name="classes" select="$classes"/>
                        <xsl:with-param name="visited-classes" select="($default-classes, $default-classes/apl:listSuperClasses(@rdf:about)/../..)"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:copy-of select="$constructor-list"/>
                
                <xsl:if test="$constructor-list and $default-classes">
                    <li class="divider"></li>
                </xsl:if>

                <xsl:if test="$show-document-classes">
                    <!--if the current resource is a Container, show Container and Item constructors--> 
                    <xsl:variable name="document-classes" select="key('resources', ('&def;Container', '&def;Item'), document(ac:document-uri('&def;')))" as="element()*"/>
                    <!-- current resource is a container -->
                    <xsl:if test="exists($document-classes) and key('resources', ac:uri())/rdf:type/@rdf:resource = ('&def;Root', '&def;Container')">
                        <xsl:apply-templates select="$document-classes" mode="bs2:ConstructorListItem">
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>

                        <xsl:if test="$default-classes">
                            <li class="divider"></li>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>
                
                <xsl:apply-templates select="$default-classes" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:Create"/>

    <xsl:template name="bs2:ConstructorList">
        <xsl:param name="ontology" as="element()"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="visited-classes" as="element()*"/>

        <xsl:variable name="constructor-list" as="element()*">
            <!-- eliminate matches where a class is a subclass of itself (happens in inferenced ontology models) -->
            <xsl:apply-templates select="$classes[not(@rdf:about = $visited-classes/@rdf:about)][let $about := @rdf:about return not(@rdf:about = ($classes, $visited-classes)[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)]" mode="bs2:ConstructorListItem"> <!-- [not((@rdf:about, apl:listSuperClasses(@rdf:about)) = ('&dh;Document', '&ldt;Parameter'))] -->
                <xsl:sort select="ac:label(.)"/>
            </xsl:apply-templates>

            <!-- show user-defined classes. Apply to owl:imported ontologies recursively -->
            <xsl:for-each select="$ontology/owl:imports/@rdf:resource[doc-available(ac:document-uri(.))]">
                <xsl:variable name="import-uri" select="." as="xs:anyURI"/>
                
                <xsl:for-each select="document(ac:document-uri($import-uri))">
                    <xsl:variable name="classes" select="rdf:RDF/*[@rdf:about][rdfs:isDefinedBy/@rdf:resource = $import-uri][spin:constructor or (rdfs:subClassOf and apl:listSuperClasses(@rdf:about)/../../spin:constructor)]" as="element()*"/>

                    <xsl:if test="key('resources', $import-uri)">
                        <xsl:call-template name="bs2:ConstructorList">
                            <xsl:with-param name="ontology" select="key('resources', $import-uri)"/>
                            <xsl:with-param name="classes" select="$classes"/>
                            <xsl:with-param name="visited-classes" select="($visited-classes, $classes)"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <!-- avoid nesting lists without items (classes) -->
        <xsl:if test="$constructor-list">
            <ul>
                <xsl:copy-of select="$constructor-list"/>
            </ul>
        </xsl:if>
    </xsl:template>
    
    <!-- OBJECT -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
</xsl:stylesheet>
