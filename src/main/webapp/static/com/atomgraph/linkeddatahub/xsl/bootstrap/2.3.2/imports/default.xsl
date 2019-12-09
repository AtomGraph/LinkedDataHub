<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY java   "http://xml.apache.org/xalan/java/">
    <!ENTITY lapp   "http://linkeddatahub.com/ns/apps/domain#">
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY a      "http://atomgraph.com/ns/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:lapp="&lapp;"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:xsd="&xsd;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:ldt="&ldt;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:foaf="&foaf;"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:uuid="java:java.util.UUID"
exclude-result-prefixes="#all">

    <xsl:key name="predicates-by-object" match="*[@rdf:about]/* | *[@rdf:nodeID]/*" use="@rdf:resource | @rdf:nodeID"/>
    <xsl:key name="violations-by-root" match="*[@rdf:about] | *[@rdf:nodeID]" use="spin:violationRoot/@rdf:resource | spin:violationRoot/@rdf:nodeID"/>
    <xsl:key name="resources-by-type" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="rdf:type/@rdf:resource"/>

    <xsl:param name="ac:contextUri" as="xs:anyURI?"/>
    <xsl:param name="uri" as="xs:anyURI"/>
    <!-- <xsl:param name="lapp:Application" as="document-node()?"/> -->

    <!-- CLIENT-SIDE FUNCTIONS -->
    
    <!-- accepts and returns SelectBuilder. Use ixsl:call(ac:paginate(...), 'toString') to get SPARQL string -->
    <xsl:function name="ac:paginate" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:param name="select-builder"/> <!-- as SelectBuilder -->
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="$order-by and not(empty($desc))">
                <xsl:sequence select="ixsl:call(ixsl:call(ixsl:call($select-builder, 'limit', $limit), 'offset', $offset), 'orderBy', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'ordering', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', $order-by), $desc))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:call($select-builder, 'limit', $limit), 'offset', $offset)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- format URLs in DataTable as HTML links -->
    <xsl:template match="srx:uri[starts-with(., 'http://')] | srx:uri[starts-with(., 'https://')]" mode="ac:DataTable" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        "&lt;a href=\"<xsl:value-of select="."/>\"&gt;<xsl:value-of select="."/>&lt;/a&gt;"
    </xsl:template>
    
    <xsl:function name="ac:rdf-data-table" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="json" as="xs:string">
            <xsl:value-of>
                <xsl:choose>
                    <xsl:when test="$category">
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="property-uris" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- if no $category specified, show resource URI/ID as category -->
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="resource-ids" select="true()" tunnel="yes"/>
                            <xsl:with-param name="property-uris" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:value-of>
        </xsl:variable>
        
        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.visualization.DataTable(JSON.parse(String.raw`{$json}`))"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:function name="ac:sparql-results-data-table" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="json" as="xs:string">
            <xsl:value-of>
                <xsl:apply-templates select="$results" mode="ac:DataTable">
                    <xsl:with-param name="var-names" select="$category, $series" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:value-of>
        </xsl:variable>

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.visualization.DataTable(JSON.parse(String.raw`{$json}`))"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <!-- TO-DO: make 'data-table' configurable -->
    <xsl:template name="ac:draw-chart" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" as="xs:string?"/>
        
        <xsl:variable name="chart-class" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$chart-type = '&ac;Table'">google.visualization.Table</xsl:when>
                <xsl:when test="$chart-type = '&ac;LineChart'">google.visualization.LineChart</xsl:when>
                <xsl:when test="$chart-type = '&ac;BarChart'">google.visualization.BarChart</xsl:when>
                <xsl:when test="$chart-type = '&ac;ScatterChart'">google.visualization.ScatterChart</xsl:when>
                <xsl:when test="$chart-type = '&ac;Timeline'">google.visualization.Timeline</xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        Chart type '<xsl:value-of select="$chart-type"/>' unknown
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$chart-type = '&ac;Table'">
                <xsl:variable name="js-statement" as="element()">
                    <root statement="(new {$chart-class}(document.getElementById('{$canvas-id}'))).draw(window['LinkedDataHub']['data-table'], {{ allowHtml: true }})"/>
                </xsl:variable>
                <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="js-statement" as="element()">
                    <root statement="(new {$chart-class}(document.getElementById('{$canvas-id}'))).draw(window['LinkedDataHub']['data-table'], {{ allowHtml: true, hAxis: {{ title: '{$category}' }}, vAxis: {{ title: '{$series}' }} }})"/>
                </xsl:variable>
                <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- SHARED FUNCTIONS -->
    
    <xsl:function name="ac:svg-label" as="xs:string?">
        <xsl:param name="resource" as="element()"/>

        <xsl:sequence select="ac:label($resource)"/>
    </xsl:function>

    <xsl:function name="ac:svg-object-label" as="xs:string?">
        <xsl:param name="object" as="attribute()"/>

        <xsl:sequence select="ac:object-label($object)"/>
    </xsl:function>
    
    <xsl:function name="apl:subClasses" as="node()*">
        <xsl:param name="class" as="xs:anyURI*"/>
        <xsl:param name="document" as="document-node()"/>
        
        <xsl:variable name="subclasses" select="ac:superClassOf($class, $document)" as="attribute()*"/>
        <xsl:if test="$subclasses[not(. = $class)]">
            <xsl:sequence select="apl:subClasses($subclasses[not(. = $class)], $document)"/>
        </xsl:if>
        <xsl:sequence select="key('resources', $class, $document)/@rdf:about, $subclasses"/>
    </xsl:function>

    <xsl:function name="apl:superClasses" as="node()*">
        <xsl:param name="class" as="xs:anyURI*"/>
        <xsl:param name="document" as="document-node()"/>
        
        <xsl:variable name="superclasses" select="rdfs:subClassOf($class, $document)" as="attribute()*"/>
        <xsl:if test="$superclasses[not(. = $class)]">
            <xsl:sequence select="apl:superClasses($superclasses[not(. = $class)], $document)"/>
        </xsl:if>
        <xsl:sequence select="key('resources', $class, $document)/@rdf:about, $superclasses"/>
    </xsl:function>
    
    <xsl:function name="lapp:base" as="node()?">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="document" as="document-node()"/>

        <xsl:for-each select="$document">
            <xsl:sequence select="//*[ldt:base/@rdf:resource = $ldt:base]/ldt:base/@rdf:resource[starts-with(., $uri)]"/>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template match="*[@rdf:nodeID = 'add']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-add')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'remove']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-remove')"/>
    </xsl:template>
        
    <xsl:template match="*" mode="apl:logo" priority="0">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="$class"/>
    </xsl:template>
    
    <!-- DEFAULT -->

    <!-- resources with URIs not relative to app base -->
    <xsl:template match="@rdf:resource[starts-with(., $ldt:base)] | srx:uri[starts-with(., $ldt:base)]" priority="2">
        <xsl:next-match>
            <xsl:with-param name="href" select="."/>
        </xsl:next-match>
    </xsl:template>

    <!-- ANCHOR -->

    <!-- override Web-Client's template which always adds ?uri= -->
    <xsl:template match="*[@rdf:about[starts-with(., $ldt:base)]]" mode="xhtml:Anchor">
        <xsl:param name="href" select="@rdf:about" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="@rdf:about" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
    </xsl:template>

    <!-- LOOKUP -->
    
    <xsl:template name="bs2:Lookup">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="list-class" select="'resource-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:param name="list-id" select="concat('ul-', $id)" as="xs:string"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:call-template>
        
        <ul class="{$list-class}" id="{$list-id}" style="display: none;"></ul>
    </xsl:template>

    <!-- TYPE -->
    
    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:TypeControl"/>

    <!-- object -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@*" mode="bs2:TypeControl"/>

    <!-- FORM CONTROL -->

    <!-- resource -->
    <xsl:template match="*[*]/@rdf:*[local-name() = ('about', 'nodeID')]" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject input-xxlarge'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="auto" select="local-name() = 'nodeID' or starts-with(., $ldt:base)" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="not($type = 'hidden')">
                <!-- <fieldset> -->
                    <div class="control-group">
                        <span class="control-label">
                            <input type="hidden" class="old subject-type" value="{if (local-name() = 'about') then 'su' else if (local-name() = 'nodeID') then 'sb' else ()}"/>
                            <select class="subject-type input-medium">
                                <option value="su">
                                    <xsl:if test="local-name() = 'about'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>URI</xsl:text>
                                </option>
                                <option value="sb">
                                    <xsl:if test="local-name() = 'nodeID'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>Blank node</xsl:text>
                                </option>
                            </select>
                        </span>
                        <div class="controls">
                            <span>
                                <!--
                                <xsl:if test="$auto">
                                    <xsl:attribute name="style">display: none;</xsl:attribute>
                                </xsl:if>
                                -->
                                <!-- hidden inputs in which we store the old values of the visible input -->
                                <input type="hidden" class="old su">
                                    <xsl:attribute name="value">
                                        <xsl:choose>
                                            <xsl:when test="local-name() = 'about'">
                                                <xsl:attribute name="value" select="."/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of use-when="system-property('xsl:product-name') = 'Saxon-CE'" select="resolve-uri(concat('/', ixsl:call(ixsl:window(), 'generateUUID')), $ac:uri)"/>
                                                <xsl:value-of use-when="system-property('xsl:product-name') = 'SAXON'" select="resolve-uri(concat('/', xs:string(uuid:randomUUID())), $ac:uri)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </input>
                                <input type="hidden" class="old sb">
                                    <xsl:attribute name="value">
                                        <xsl:choose>
                                            <xsl:when test="local-name() = 'nodeID'">
                                                <xsl:attribute name="value" select="."/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="generate-id()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </input>
                                <xsl:apply-templates select="." mode="xhtml:Input">
                                    <xsl:with-param name="type" select="$type"/>
                                    <!-- <xsl:with-param name="id" select="$id"/> -->
                                    <xsl:with-param name="class" select="$class"/>
                                    <xsl:with-param name="disabled" select="$disabled"/>
                                </xsl:apply-templates>
                                <xsl:text> </xsl:text>
                            </span>
                            <!--
                            <input type="checkbox" value="auto">
                                <xsl:if test="$auto">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                            </input>
                            <span class="help-inline">Auto</span>
                            -->
                        </div>
                    </div>
                <!-- </fieldset> -->
                
                <hr/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <!-- <xsl:with-param name="id" select="$id"/> -->
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- hide foaf:primaryTopic/foaf:isPrimaryTopicOf if their object resources have properties other than rdf:type -->
    <!--
    <xsl:template match="foaf:primaryTopic[key('resources', (@rdf:resource, @rdf:nodeID))[* except rdf:type]] | foaf:isPrimaryTopicOf[key('resources', (@rdf:resource, @rdf:nodeID))[* except rdf:type]]" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    -->
    
    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:FormControl">
        <xsl:param name="this" select="xs:anyURI(concat(namespace-uri(), local-name()))" as="xs:anyURI"/>
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="error" select="@rdf:resource = $violations/apl:violationValue or $violations/spin:violationPath/@rdf:resource = $this" as="xs:boolean"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="label" select="true()" as="xs:boolean"/>
        <xsl:param name="template-doc" as="document-node()?"/>
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="cloneable" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="not(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this]) and (if (../rdf:type/@rdf:resource and $ac:sitemap) then (key('resources', key('resources', (../rdf:type/@rdf:resource, apl:superClasses(../rdf:type/@rdf:resource, $ac:sitemap)), $ac:sitemap)/spin:constraint/(@rdf:resource|@rdf:nodeID), $ac:sitemap)[rdf:type/@rdf:resource = '&apl;MissingPropertyValue'][sp:arg1/@rdf:resource = $this]) else true())" as="xs:boolean"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <!-- <xsl:param name="forClass" as="xs:anyURI?"/> -->
        
        <div class="control-group">
            <xsl:if test="$error">
                <xsl:attribute name="class">control-group error</xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Input">
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:apply-templates>
            <xsl:if test="$label">
                <label class="control-label" for="{$for}" title="{$this}">
                    <xsl:choose use-when="system-property('xsl:product-name') = 'SAXON'">
                        <xsl:when test="doc-available(ac:document-uri(xs:anyURI($this)))">
                            <xsl:choose>
                                <xsl:when test="key('resources', $this, document(ac:document-uri(xs:anyURI($this))))">
                                    <xsl:for-each select="key('resources', $this, document(ac:document-uri(xs:anyURI($this))))">
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                        
                                        <xsl:if test="ac:description(.)">
                                            <span class="description">
                                                <xsl:value-of select="ac:description(.)"/>
                                            </span>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="local-name()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="local-name()"/>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:value-of use-when="system-property('xsl:product-name') = 'Saxon-CE'" select="local-name()"/>
                </label>
            </xsl:if>
            
            <xsl:if test="$cloneable">
                <div class="btn-group pull-right">
                    <button type="button" class="btn btn-small pull-right btn-add" title="Add another statement">&#x271a;</button>
                </div>
            </xsl:if>

            <div class="controls">
                <xsl:if test="not($required)">
                    <div class="btn-group pull-right">
                        <button type="button" title="Remove this statement">
                            <!-- TO-DO: unify when cached RDF/XML ontologies are available for client-side XSLT -->
                            <xsl:apply-templates use-when="system-property('xsl:product-name') = 'SAXON'" select="key('resources', 'remove', document('../translations.rdf'))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn btn-small pull-right'"/>
                            </xsl:apply-templates>
                            <xsl:text use-when="system-property('xsl:product-name') = 'Saxon-CE'">&#x2715;</xsl:text>
                        </button>
                    </div>
                </xsl:if>

                <xsl:apply-templates select="node() | @rdf:*[local-name() = ('resource', 'nodeID')]" mode="#current">
                    <xsl:with-param name="required" select="$required"/>
                    <xsl:with-param name="template-doc" select="$template-doc"/>
                </xsl:apply-templates>
            </div>
            
            <xsl:if test="(@xml:*[local-name() = 'lang'] | @rdf:*[local-name() = 'datatype'])">
                <div class="controls">
                    <xsl:apply-templates select="@xml:*[local-name() = 'lang'] | @rdf:*[local-name() = 'datatype']" mode="#current"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- object resource -->
    <xsl:template match="@rdf:*[local-name() = 'resource']" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="template"  as="element()?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="template-doc" as="document-node()?"/>
        <xsl:variable name="resource" select="key('resources', .)"/>
        <xsl:variable name="doc-uri" select="if (starts-with($ldt:base, $ac:contextUri)) then ac:document-uri(.) else resolve-uri(concat('?uri=', encode-for-uri(ac:document-uri(.))), $ldt:base)" as="xs:anyURI"/>

        <xsl:choose>
            <!-- loop if node not visited already -->
            <xsl:when test="$inline and $resource and not(. = $traversed-ids)">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="$resource" mode="#current">
                    <xsl:with-param name="traversed-ids" select="(., $traversed-ids)" tunnel="yes"/>
                </xsl:apply-templates>
                <!-- restore subject context -->
                <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$type = 'hidden'">
                <xsl:next-match>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="starts-with(., $ldt:base) and doc-available($doc-uri)">
                <xsl:choose>
                    <xsl:when test="key('resources', ., document($doc-uri))">
                        <span>
                            <xsl:for-each select="key('resources', ., document($doc-uri))">
                                <xsl:apply-templates select="." mode="apl:Typeahead"/>
                            </xsl:for-each>
                        </span>

                        <xsl:if test="$template-doc">
                            <xsl:text> </xsl:text>
                            <xsl:variable name="forClass" select="key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $template-doc)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $template-doc)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')]" as="xs:anyURI?"/>
                            <xsl:if test="$forClass">
                                <!-- forClass input is required by typeahead's FILTER (?Type IN ()) in client.xsl -->
                                <xsl:choose>
                                    <xsl:when test="system-property('xsl:product-name') = 'SAXON'">
                                        <!-- add subclasses as forClass -->
                                        <xsl:for-each select="distinct-values(apl:subClasses($forClass, $ac:sitemap))[not(. = $forClass)]">
                                            <input type="hidden" class="forClass" value="{.}"/>
                                        </xsl:for-each>
                                        <!-- bs2:Constructor sets forClass -->
                                        <xsl:apply-templates select="key('resources', $forClass, $ac:sitemap)" mode="bs2:Constructor">
                                            <xsl:with-param name="subclasses" select="true()"/>
                                        </xsl:apply-templates>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- $ac:sitemap not available for Saxon-CE -->
                                        <input type="hidden" class="forClass" value="{$forClass}"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            
                                <xsl:if test="not($type = 'hidden') and $type-label">
                                    <span class="help-inline">
                                        <xsl:choose>
                                            <xsl:when test="system-property('xsl:product-name') = 'SAXON'"> <!-- server-side Saxon has access to the sitemap ontology -->
                                                <xsl:apply-templates select="key('resources', $forClass, $ac:sitemap)" mode="ac:label"/>
                                            </xsl:when>
                                            <xsl:otherwise> <!-- client-side Saxon-CE does not have access to the sitemap ontology -->
                                                <xsl:value-of select="$forClass"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </span>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:next-match/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
                
                <xsl:if test="not($type = 'hidden') and $type-label">
                    <span class="help-inline">Resource</span>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- object blank node -->
    <xsl:template match="*[@rdf:*[local-name() = ('about', 'nodeID')]]/*/@rdf:*[local-name() = ('nodeID')]" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="template"  as="element()?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="resource" select="key('resources', .)"/>

        <xsl:choose>
            <xsl:when test="$inline and $resource and not(. = $traversed-ids)">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>

                <xsl:apply-templates select="$resource" mode="#current">
                    <xsl:with-param name="traversed-ids" select="(., $traversed-ids)" tunnel="yes"/>
                </xsl:apply-templates>

                <!-- restore subject context -->
                <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
                
                <xsl:if test="not($type = 'hidden') and $type-label">
                    <span class="help-inline">Resource</span>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- blank nodes that only have rdf:type xsd:* and no other properties become literal inputs -->
    <!-- TO-DO: expand pattern to handle other XSD datatypes -->
    <xsl:template match="*[@rdf:*[local-name() = 'nodeID']]/*/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[starts-with(@rdf:resource, '&xsd;')])]]" mode="bs2:FormControl" priority="2">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:call-template>
        
        <!-- datatype -->
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="key('resources', .)/rdf:type/@rdf:resource"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- blank nodes that only have non-XSD rdf:type and no other properties become resource typeaheads -->
    <xsl:template match="*[@rdf:*[local-name() = 'nodeID']]/*/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[not(starts-with(@rdf:resource, '&xsd;'))])]]" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <span>
            <xsl:call-template name="bs2:Lookup">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="class" select="$class"/>
            </xsl:call-template>
        </span>
        <xsl:text> </xsl:text>

        <xsl:variable name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI"/>
        <!-- forClass input is used by typeahead's FILTER (?Type IN ()) in client.xsl -->
        <xsl:choose>
            <xsl:when test="system-property('xsl:product-name') = 'SAXON' and not($forClass = '&rdfs;Resource')">
                <!-- add subclasses as forClass -->
                <xsl:for-each select="distinct-values(apl:subClasses($forClass, $ac:sitemap))[not(. = $forClass)]">
                    <input type="hidden" class="forClass" value="{.}"/>
                </xsl:for-each>
                <!-- bs2:Constructor sets forClass -->
                <xsl:apply-templates select="key('resources', $forClass, $ac:sitemap)" mode="bs2:Constructor">
                    <xsl:with-param name="subclasses" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!-- $ac:sitemap not available for Saxon-CE -->
                <input type="hidden" class="forClass" value="{$forClass}"/> <!-- required by ?Type FILTER -->
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="not($type = 'hidden') and $type-label">
            <span class="help-inline">
                <xsl:choose>
                    <xsl:when test="system-property('xsl:product-name') = 'SAXON'"> <!-- server-side Saxon has access to the sitemap ontology -->
                        <xsl:choose>
                            <xsl:when test="$forClass = '&rdfs;Resource'">Resource</xsl:when>
                            <xsl:when test="key('resources', $forClass, $ac:sitemap)">
                                <xsl:apply-templates select="key('resources', $forClass, $ac:sitemap)" mode="ac:label"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$forClass"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise> <!-- client-side Saxon-CE does not have access to the sitemap ontology -->
                        <xsl:value-of select="$forClass"/>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
        </xsl:if>
    </xsl:template>
    
    <!-- PROPERTY CONTROL -->
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:PropertyControl">
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="label" select="true()" as="xs:boolean"/>
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <xsl:param name="forClass" as="xs:anyURI?"/>

        <div class="control-group">
            <span class="control-label">
                <select class="input-medium">
                    <!-- group properties by URI - there might be duplicates in the constructor -->
                    <xsl:for-each-group select="$template/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="ac:property-label(.)"/>
                        <xsl:variable name="this" select="xs:anyURI(current-grouping-key())" as="xs:anyURI"/>
                        <xsl:variable name="available" select="doc-available(ac:document-uri($this))" as="xs:boolean"/>
                        <xsl:choose use-when="system-property('xsl:product-name') = 'SAXON'">
                            <xsl:when test="$available and key('resources', $this, document(ac:document-uri($this)))">
                                <xsl:apply-templates select="key('resources', $this, document(ac:document-uri($this)))" mode="xhtml:Option">
                                    <!-- <xsl:with-param name="selected" select="@rdf:about = $this"/> -->
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <option value="{current-grouping-key()}">
                                    <xsl:value-of select="local-name()"/>
                                </option>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:for-each use-when="system-property('xsl:product-name') = 'Saxon-CE'" select=".">
                            <option value="{current-grouping-key()}">
                                <xsl:value-of select="local-name()"/>
                            </option>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </select>
            </span>

            <div class="controls">
                <button type="button" id="button-{generate-id()}" class="btn add-value" value="{$forClass}">
                    <!-- TO-DO: unify when cached RDF/XML ontologies are available for clien-side XSLT -->
                    <xsl:apply-templates use-when="system-property('xsl:product-name') = 'SAXON'" select="key('resources', 'add', document('../translations.rdf'))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn add-value'"/>
                    </xsl:apply-templates>
                    <xsl:text use-when="system-property('xsl:product-name') = 'Saxon-CE'">&#10133;</xsl:text>
                </button>
            </div>
        </div>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->
    
    <xsl:template match="*[@rdf:about]" mode="bs2:Constructor">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="subclasses" select="false()" as="xs:boolean"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:variable name="forClass" select="@rdf:about" as="xs:anyURI"/>

        <!-- this is used for typeahead FILTER ?Type -->
        <input type="hidden" class="forClass" value="{$forClass}"/>

        <xsl:choose>
            <xsl:when test="$subclasses and apl:subClasses($forClass, $ac:sitemap)">
                <div class="btn-group">
                    <button type="button">
                        <xsl:choose>
                            <xsl:when test="$with-label">
                                <xsl:apply-templates select="." mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                </xsl:apply-templates>
                                <xsl:text> </xsl:text>
                                <xsl:apply-templates select="." mode="ac:label"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </button>
                    <ul class="dropdown-menu">
                        <xsl:variable name="self-and-subclasses" select="(., key('resources', apl:subClasses($forClass, $ac:sitemap), $ac:sitemap))" as="element()*"/>

                        <!-- apply on the "deepest" subclass of $forClass and its subclasses -->
                        <xsl:for-each select="$self-and-subclasses[not(@rdf:about = $self-and-subclasses/rdfs:subClassOf/@rdf:resource)]">
                            <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                            
                            <!-- we are in $ac:sitemap context already -->
                            <xsl:variable name="action" as="xs:anyURI?">
                                <xsl:value-of select="key('resources', key('resources', key('resources', key('resources', @rdf:about)/rdfs:subClassOf/@rdf:*)/owl:allValuesFrom/@rdf:*)/rdfs:subClassOf/@rdf:*)/owl:hasValue/@rdf:resource"/>
                            </xsl:variable>

                            <li>
                                <button type="button" class="btn add-constructor" title="{@rdf:about}">
                                    <xsl:if test="$id">
                                        <xsl:attribute name="id" select="$id"/>
                                    </xsl:if>
                                    <input type="hidden" class="action" value="{concat(if ($action) then $action else $ac:uri, '?forClass=', encode-for-uri(@rdf:about), '&amp;mode=', encode-for-uri('&ac;ModalMode'))}"/>

                                    <xsl:apply-templates select="." mode="ac:label"/>
                                </button>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="action" as="xs:anyURI?">
                    <xsl:for-each select="$ac:sitemap">
                        <xsl:value-of select="key('resources', key('resources', key('resources', key('resources', $forClass)/rdfs:subClassOf/@rdf:*)/owl:allValuesFrom/@rdf:*)/rdfs:subClassOf/@rdf:*)/owl:hasValue/@rdf:resource"/>
                    </xsl:for-each>
                </xsl:variable>
                <button type="button" title="{@rdf:about}">
                    <xsl:if test="$id">
                        <xsl:attribute name="id" select="$id"/>
                    </xsl:if>
                    
                    <xsl:choose>
                        <xsl:when test="$with-label">
                            <xsl:apply-templates select="." mode="apl:logo">
                                <xsl:with-param name="class" select="'btn add-constructor'"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn add-constructor'"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>

                    <input type="hidden" class="action" value="{concat(if ($action) then $action else $ac:uri, '?forClass=', encode-for-uri(@rdf:about),'&amp;mode=', encode-for-uri('&ac;ModalMode'))}"/>
                </button>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- WYSIWYG editor for XMLLiteral objects -->

    <xsl:template match="*[@rdf:*[local-name() = 'parseType'] = 'Literal']/xhtml:*" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>

        <textarea name="ol" id="{$id}" class="wymeditor">
            <xsl:apply-templates select="xhtml:*" mode="xml-to-string"/>
        </textarea>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="'&rdf;XMLLiteral'"/>
        </xsl:call-template>
    </xsl:template>

    <!-- real numbers -->
    
    <xsl:template match="text()[../@rdf:datatype = '&xsd;float'] | text()[../@rdf:datatype = '&xsd;double']" priority="1" mode="xhtml:Input">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="value" select="format-number(., '#####.00000')"/>
        </xsl:call-template>
    </xsl:template>
   
</xsl:stylesheet>