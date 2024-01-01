<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
]>
<xsl:stylesheet version="2.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <!-- BLOCK MODE -->

<!--    <xsl:template match="*[ldh:chartType/@rdf:resource] | *[@rdf:nodeID]/ldh:chartType/@rdf:resource/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:Block" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="show-properties" select="false()" as="xs:boolean"/>
        <xsl:param name="canvas-id" select="generate-id() || '-chart-canvas'" as="xs:string" tunnel="yes"/>

        <xsl:apply-templates select="." mode="bs2:Header"/>
        
        <xsl:variable name="doc" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:copy-of select="."/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$doc" mode="bs2:Chart">
            <xsl:with-param name="canvas-id" select="$canvas-id"/>
        </xsl:apply-templates>
        
        <xsl:if test="$show-properties">
            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
        </xsl:if>
    </xsl:template>-->
    
    <xsl:template match="*[ldh:chartType/@rdf:resource] | *[@rdf:nodeID]/ldh:chartType/@rdf:resource/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:Block" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="canvas-id" select="generate-id() || '-chart-canvas'" as="xs:string"/>
        <xsl:param name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
<!--        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>-->
        <xsl:param name="type" select="xs:anyURI(rdf:type/@rdf:resource)" as="xs:anyURI"/>
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

        <xsl:apply-templates select="." mode="bs2:Header"/>

        <!-- <xsl:if test="$show-controls"> -->
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
<!--                                <option value="">
                                     URI is the default category 
                                    <xsl:if test="not($category)">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>[URI/ID]</xsl:text>
                                </option>-->

<!--                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
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
                                </xsl:for-each-group>-->
                            </select>
                        </div>
                        <div class="span4">
                            <label for="{$series-id}">Series</label>
                            <select id="{$series-id}" name="ou" multiple="multiple" class="input-large chart-series">
<!--                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
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
                                </xsl:for-each-group>-->
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
        <!-- </xsl:if> -->
    </xsl:template>
    
    <!-- FORM CONTROL MODE -->
    
    <!-- override the value of ldh:chartType with a dropdown of ac:Chart subclasses (currently in the LDH vocabulary) -->
    <xsl:template match="ldh:chartType/@rdf:resource | ldh:chartType/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="value" select="." as="xs:string"/>

        <xsl:variable name="chart-types" select="key('resources-by-subclass', '&ac;Chart', document(ac:document-uri('&ldh;')))" as="element()*"/>
        <select name="ou" id="{generate-id()}">
            <xsl:for-each select="$chart-types">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about = $value"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>