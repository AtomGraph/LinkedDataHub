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
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
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
    <xsl:param name="acl:mode" select="$foaf:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', ac:uri(), $main-doc)/rdf:type/@rdf:resource, key('resources', ac:uri(), $main-doc)/rdf:type/@rdf:resource/ldh:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>

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
    
    <!-- ROW BLOCK -->
    
    <xsl:template match="rdf:RDF" mode="bs2:RowBlock">
        <xsl:apply-templates mode="#current">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
        
    <!-- CONTENT -->
    
    <xsl:template match="rdf:RDF" mode="ldh:Content">
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
        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&ldh;GraphChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
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
                                    <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <br/>
                            <!-- TO-DO: replace with xsl:apply-templates on ac:Chart subclasses as in imports/ldh.xsl -->
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
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
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
        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&ldh;ResultSetChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI"/>
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
                                    <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
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
                                <xsl:with-param name="value" select="'&ldh;categoryVarName'"/>
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
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                            </xsl:apply-templates>
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
        
        <xsl:choose>
            <!-- if $forClass is not a document class or content, then pair the instance with a document instance -->
            <xsl:when test="$createGraph and not($forClass = ('&dh;Container', '&dh;Item', '&ldh;Content'))">
                <xsl:document>
                    <xsl:sequence select="ldh:construct(spin:constructors($forClass, resolve-uri('ns', $ldt:base), $constructor-query)//sp:text)"/>
<!--                    <xsl:for-each select="ac:construct($ldt:ontology, ($forClass, xs:anyURI('&dh;Item')), $ldt:base)">
                        <xsl:apply-templates select="." mode="ldh:SetPrimaryTopic">
                             avoid selecting object blank nodes which only have rdf:type 
                            <xsl:with-param name="topic-id" select="key('resources-by-type', $forClass)[* except rdf:type]/@rdf:nodeID" tunnel="yes"/>
                            <xsl:with-param name="doc-id" select="key('resources-by-type', '&dh;Item')/@rdf:nodeID" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:for-each>-->
                </xsl:document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:construct(spin:constructors($forClass, resolve-uri('ns', $ldt:base), $constructor-query)//sp:text)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- MODAL FORM -->

    <xsl:template match="rdf:RDF[$ac:forClass][$ac:method = 'GET']" mode="bs2:ModalForm" priority="1" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="action" select="ac:build-uri($a:graphStore, map{ 'forClass': string($ac:forClass), 'mode': ('&ac;EditMode', '&ac;ModalMode') })" as="xs:anyURI"/>

        <xsl:next-match>
            <xsl:with-param name="action" select="$action"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ModalForm" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="ac:build-uri($a:graphStore, map{ 'forClass': string($ac:forClass), 'mode': '&ac;ModalMode' })" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="'multipart/form-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>

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

                    <xsl:apply-templates select="*" mode="#current">
                        <xsl:sort select="ac:label(.)"/>
                        <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                    </xsl:apply-templates>
                </div>

                <xsl:apply-templates select="." mode="bs2:ModalFormActions">
                    <xsl:with-param name="button-class" select="$button-class"/>
                </xsl:apply-templates>
            </form>
        </div>
    </xsl:template>
    
    <!-- ROW FORM -->

    <xsl:template match="rdf:RDF[$ac:forClass = ('&ldh;CSVImport', '&ldh;RDFImport')][$ac:method = 'GET']" mode="bs2:RowForm" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="action" select="ac:build-uri(resolve-uri('imports', $ldt:base), map{ 'forClass': string($ac:forClass), 'mode': '&ac;EditMode' })" as="xs:anyURI"/>
        <xsl:param name="classes" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="classes" select="$classes"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[$ac:forClass][$ac:method = 'GET']" mode="bs2:RowForm" priority="1" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="action" select="ac:build-uri($a:graphStore, map{ 'forClass': string($ac:forClass), 'mode': '&ac;EditMode' })" as="xs:anyURI"/>
        <xsl:param name="classes" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="classes" select="$classes"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:RowForm">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="ac:build-uri(ac:uri(), let $params := map{ '_method': 'PUT', 'mode': for $mode in $ac:mode return string($mode) } return if (not(starts-with(ac:uri(), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:uri()) })) else $params)" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="'multipart/form-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
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

            <xsl:apply-templates select="*" mode="#current">
                <xsl:sort select="ac:label(.)"/>
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
            </xsl:apply-templates>

            <xsl:if test="$create-resource">
                <div class="create-resource row-fluid">
                    <div class="offset2 span7">
                        <xsl:apply-templates select="." mode="bs2:Create">
                            <xsl:with-param name="classes" select="$classes"/>
                            <xsl:with-param name="show-document-classes" select="false()"/>
                        </xsl:apply-templates>
                        
                        <!-- separate "Create" button only for Content -->
                        <a href="{ac:build-uri(ac:uri(), map{ 'forClass': '&ldh;Content' })}" class="btn btn-primary add-constructor create-action">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', '&ldh;Content', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                            </xsl:value-of>
                            <input type="hidden" class="forClass" value="&ldh;Content"/>
                        </a>
                    </div>
                </div>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:FormActions">
                <xsl:with-param name="button-class" select="$button-class"/>
            </xsl:apply-templates>
        </form>
    </xsl:template>

    <!-- MODAL FORM ACTIONS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:ModalFormActions">
        <xsl:param name="class" select="'form-actions modal-footer'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <button type="submit" class="{$button-class}">
                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                    <xsl:with-param name="class" select="$button-class"/>
                </xsl:apply-templates>
            </button>

            <button type="button" class="btn">
                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>

            <button type="reset" class="btn">
                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
        </div>
    </xsl:template>

    <!-- FORM ACTIONS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:FormActions">
        <xsl:param name="class" select="'row-fluid'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <div class="form-actions offset2 span7">
                <button type="submit" class="{$button-class}">
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="$button-class"/>
                    </xsl:apply-templates>
                </button>

                <button type="reset" class="btn">
                    <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>
                </button>
            </div>
        </div>
    </xsl:template>

    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
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
    
    <xsl:template match="rdf:RDF[$acl:mode = '&acl;Append']" mode="bs2:Create" priority="1">
        <xsl:param name="class" select="'btn-group'" as="xs:string?"/>
        <!--<xsl:param name="default-classes" as="element()*"/>-->
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="show-document-classes" select="true()" as="xs:boolean"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
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
                <xsl:if test="$show-document-classes">
                    <!--if the current resource is a Container, show Container and Item constructors--> 
                    <xsl:variable name="document-classes" select="key('resources', ('&dh;Container', '&dh;Item'), document(ac:document-uri('&def;')))" as="element()*"/>
                    <!-- current resource is a container -->
                    <xsl:if test="exists($document-classes) and key('resources', ac:uri())/rdf:type/@rdf:resource = ('&def;Root', '&dh;Container')">
                        <xsl:apply-templates select="$document-classes" mode="bs2:ConstructorListItem">
                            <xsl:with-param name="create-graph" select="$create-graph"/>
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>

                        <xsl:if test="$classes">
                            <li class="divider"></li>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>
                
                <xsl:apply-templates select="key('resources', '&owl;NamedIndividual', document(ac:document-uri('&owl;')))" mode="bs2:ConstructorListItem">
                    <xsl:with-param name="create-graph" select="$create-graph"/>
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>

                <li class="divider"></li>
                
                <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                    <xsl:with-param name="create-graph" select="$create-graph"/>
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
