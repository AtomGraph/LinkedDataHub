<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "http://linkeddatahub.com/ns/apps/domain#">
    <!ENTITY a      "http://atomgraph.com/ns/core#">
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">    
    <!ENTITY c      "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spl    "http://spinrdf.org/spl#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:lapp="&lapp;"
xmlns:a="&a;"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:srx="&srx;"
xmlns:sd="&sd;"
xmlns:ldt="&ldt;"
xmlns:core="&c;"
xmlns:spl="&spl;"
xmlns:void="&void;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:javaee="http://java.sun.com/xml/ns/javaee"
xmlns:uuid="java:java.util.UUID"
exclude-result-prefixes="#all">

<!--    <xsl:import href="../../../../client/xsl/bootstrap/2.3.2/sparql.xsl"/>-->

    <!-- <xsl:template match="*[@rdf:about = resolve-uri('query', $ldt:base)]" mode="bs2:BlockList" priority="2"/> -->

    <xsl:template match="rdf:RDF[not(key('resources-by-type', '&http;Response'))][$ac:mode = '&ac;QueryEditorMode']" mode="bs2:Main" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="id" select="'main-content'" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <legend>SPARQL editor</legend>

            <xsl:call-template name="bs2:QueryForm">
                <xsl:with-param name="uri" select="$ac:uri"/>
                <xsl:with-param name="mode" select="$ac:mode"/>
                <xsl:with-param name="endpoint" select="if ($ac:endpoint) then $ac:endpoint else resolve-uri('sparql', $ldt:base)"/>
                <xsl:with-param name="query" select="$ac:query"/>
                <xsl:with-param name="default-query" select="$default-query"/>
            </xsl:call-template>

<!--            <xsl:if test="$ac:query and $ac:endpoint">
                <xsl:variable name="results-uri" select="resolve-uri(concat('sparql', '?query=', encode-for-uri($ac:query)), $ldt:base)" as="xs:anyURI"/>
                <xsl:choose>
                    <xsl:when test="doc-available($results-uri)">
                        <xsl:variable name="results" select="document($results-uri)" as="document-node()"/>

                        <ul class="nav nav-tabs">
                            <li>
                                <xsl:if test="not($ac:mode = '&ac;ChartMode')">
                                    <xsl:attribute name="class" select="'active'"/>
                                </xsl:if>

                                 $ac:query is already in the URL as it is not removed 
                                <a href="{if ($ac:mode = '&ac;ChartMode') then concat($ac:uri, '?query=', encode-for-uri($ac:query), '&amp;endpoint=', encode-for-uri($ac:endpoint), '&amp;mode=', encode-for-uri('&ac;QueryEditorMode')) else ()}">Results</a>
                            </li>
                            <li>
                                <xsl:if test="$ac:mode = '&ac;ChartMode'">
                                    <xsl:attribute name="class" select="'active'"/>
                                </xsl:if>

                                 $ac:query is already in the URL as it is not removed 
                                <a href="{if (not($ac:mode = '&ac;ChartMode')) then concat($ac:uri, '?query=', encode-for-uri($ac:query), '&amp;endpoint=', encode-for-uri($ac:endpoint), '&amp;mode=', encode-for-uri('&ac;QueryEditorMode'), '&amp;mode=', encode-for-uri('&ac;ChartMode')) else ()}">
                                    <xsl:for-each select="key('resources', '&apl;Chart', document('&apl;'))">
                                        <img style="height: 2em;" src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_show_chart_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </xsl:for-each>
                                </a>
                            </li>
                        </ul>
                
                        <xsl:choose>
                             draw diagram 
                            <xsl:when test="$ac:mode = '&ac;ChartMode'">
                                <xsl:apply-templates select="$results" mode="bs2:Chart">
                                        <xsl:with-param name="chart-type" select="$ac:chart-type"/>
                                        <xsl:with-param name="category" select="$ac:category"/>
                                        <xsl:with-param name="series" select="$ac:series"/>
                                        <xsl:with-param name="uri" select="$ac:uri"/>
                                        <xsl:with-param name="mode" select="$ac:mode"/>
                                        <xsl:with-param name="endpoint" select="$ac:endpoint"/>
                                        <xsl:with-param name="query" select="$ac:query"/>
                                </xsl:apply-templates>
                            </xsl:when>
                             show result table 
                            <xsl:otherwise>
                                <xsl:call-template name="ac:QueryResult"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                     show error if results could not be loaded 
                    <xsl:otherwise>
                        <div class="alert alert-block">
                            <strong>Could not execute query</strong>. Check syntax
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>-->
        </div>
    </xsl:template>

<!--    <xsl:template match="rdf:RDF[$ac:mode = '&ac;QueryEditorMode']" mode="bs2:Right" priority="2">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span3'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:if test="$ac:query">
                <div class="well well-small">
                    <h2 class="nav-header">Save query</h2>

                    <xsl:apply-templates select="." mode="bs2:SaveAs">
                        <xsl:with-param name="query" select="$ac:query"/>
                    </xsl:apply-templates>
                </div>
            </xsl:if>
        </div>
    </xsl:template>-->

    <xsl:template name="bs2:QueryForm">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" select="'query-form'" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="default-query" as="xs:string?"/>
        
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
                <label for="endpoint-uri">Endpoint</label>
                <xsl:text> </xsl:text>
                    <select id="endpoint-uri" name="endpoint" class="input-xxlarge">
                        <option value="{resolve-uri('sparql', $ldt:base)}">[SPARQL endpoint]</option>

<!--                        <xsl:for-each select="document(resolve-uri('services/', $ldt:base))//*[sd:endpoint/@rdf:resource]" use-when="system-property('xsl:product-name') = 'SAXON'">
                            <xsl:sort select="ac:label(.)"/>

                            <xsl:apply-templates select="." mode="xhtml:Option">
                                <xsl:with-param name="value" select="sd:endpoint/@rdf:resource"/>
                                <xsl:with-param name="selected" select="sd:endpoint/@rdf:resource = $endpoint"/>
                            </xsl:apply-templates>
                        </xsl:for-each>
                        <xsl:if test="true()"  use-when="system-property('xsl:product-name') = 'Saxon-CE'">
                            <xsl:variable name="query" select="'DESCRIBE ?service { GRAPH ?g { ?service &lt;&sd;endpoint&gt; ?endpoint } }'"/>
                            <xsl:message>
                                <xsl:sequence select="ac:fetch(resolve-uri(concat('sparql?query=', encode-for-uri($query)), $ldt:base), 'application/rdf+xml', 'onchartModeServiceLoad')"/>
                            </xsl:message> 
                        </xsl:if>-->
                </select>
        
                <textarea id="query-string" name="query" class="span12" rows="15">
<!--                    <xsl:choose>
                        <xsl:when test="$ac:query">
                            <xsl:value-of select="$ac:query"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$default-query"/>
                        </xsl:otherwise>
                    </xsl:choose>-->

                    <xsl:value-of select="$default-query"/>
                </textarea>

                <script src="{resolve-uri('static/js/yasqe.js', $ac:contextUri)}" type="text/javascript"></script>
                <!-- global yasqe object. TO-DO: move under AtomGraph namespace -->
                <script type="text/javascript">
                    <![CDATA[
                    var yasqe = YASQE.fromTextArea(document.getElementById("query-string"), { persistent: null });
                    ]]>
                </script>

                <div class="form-actions">
                    <!-- retain URL parameters -->
                    <xsl:if test="$ac:uri">
                        <input type="hidden" name="uri" value="{$ac:uri}"/>
                    </xsl:if>
                    <xsl:if test="$endpoint">
                        <input type="hidden" name="endpoint" value="{$endpoint}"/>
                    </xsl:if>
                    <xsl:for-each select="$mode">
                        <input type="hidden" name="mode" value="{.}"/>
                    </xsl:for-each>
                    <!-- chart params -->
<!--                    <xsl:if test="$ac:chart-type">
                        <input type="hidden" name="chart-type" value="{$ac:chart-type}"/>
                    </xsl:if>
                    <xsl:if test="$ac:category">
                        <input type="hidden" name="category" value="{$ac:category}"/>
                    </xsl:if>
                    <xsl:for-each select="$ac:series">
                        <input type="hidden" name="series" value="{.}"/>
                    </xsl:for-each>-->
    
                    <button class="btn btn-primary btn-run-query" type="submit" >
                        <img style="height: 2em;" src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/baseline-play_arrow-24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
                        <xsl:text>Run</xsl:text>
                    </button>
                </div>
            </fieldset>
        </form>
    </xsl:template>
    
    <!-- service endpoint dropdown -->
    
    <xsl:template match="ixsl:window()" mode="ixsl:onServiceLoad" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="detail" select="ixsl:get($event, 'detail')"/>
        <xsl:variable name="services-doc" select="ixsl:get($detail, 'body')" as="document-node()"/>
        <xsl:variable name="id" select="'endpoint-uri'" as="xs:string"/>
        
        <xsl:result-document href="#{$id}">
            <xsl:for-each select="$services-doc//*[sd:endpoint/@rdf:resource]">
                <xsl:sort select="ac:label(.)"/>
                
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="value" select="sd:endpoint/@rdf:resource"/>
                    <xsl:with-param name="selected" select="sd:endpoint/@rdf:resource = $ac:endpoint"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="bs2:SaveQueryForm">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:param name="endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
        <!-- brittle string-based query type heuristic -->
        <xsl:param name="type" as="xs:anyURI">
            <xsl:choose>
                <xsl:when test="matches($query, 'CONSTRUCT', 'i')">
                    <xsl:value-of select="resolve-uri('ns#Construct', $ldt:base)"/>
                </xsl:when>
                <xsl:when test="matches($query, 'DESCRIBE', 'i')">
                    <xsl:value-of select="resolve-uri('ns#Describe', $ldt:base)"/>
                </xsl:when>
                <xsl:when test="matches($query, 'SELECT', 'i')">
                    <xsl:value-of select="resolve-uri('ns#Select', $ldt:base)"/>
                </xsl:when>
                <xsl:when test="matches($query, 'ASK', 'i')">
                    <xsl:value-of select="resolve-uri('ns#Ask', $ldt:base)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="resolve-uri('ns/default#Query', $ldt:base)"/> <!-- TO-DO: add to namespace ontology -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="action" select="resolve-uri(concat('queries/?forClass=', encode-for-uri(resolve-uri($type, $ldt:base))), $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="id" select="'save-query-form'" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>

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
        
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'rdf'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <!-- query -->
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'sb'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="'query'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="'&dct;title'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="id" select="'query-title'"/>
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
                <xsl:with-param name="value" select="$type"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="'&sp;text'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="id" select="'save-query-string'"/>
                <xsl:with-param name="name" select="'ol'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="$query"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="'&apl;endpoint'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="id" select="'query-endpoint'"/>
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="$endpoint"/>
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
            <!-- query document -->
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
                <xsl:with-param name="id" select="'query-doc-title'"/>
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
                <xsl:with-param name="value" select="resolve-uri('ns#QueryItem', $ldt:base)"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ob'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="'query'"/>
            </xsl:call-template>
        
            <div class="form-actions">
                <button class="btn btn-save-query" type="submit">
                    <!-- <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                        <xsl:with-param name="filename" select="'ic_note_add_white_24px.svg'"/>
                    </xsl:apply-templates> -->

                    <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_save_white_24px.svg', $ac:contextUri)}" alt="Save"/>
                    <xsl:text> Save</xsl:text> <!-- to do: use query class in apl:logo mode -->
                </button>
            </div>
        </form>
    </xsl:template>

<!--    <xsl:template match="*" mode="bs2:SaveAs"/>-->

<!--    <xsl:template match="*[@rdf:about][key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource = '&c;SPARQLEndpoint']" mode="bs2:ModeListItem" priority="2">
        <xsl:param name="active" as="xs:anyURI*"/>
        <xsl:variable name="href" select="xs:anyURI(concat($ac:uri, '?query=', encode-for-uri($ac:query), '&amp;mode=', encode-for-uri(@rdf:about)))" as="xs:anyURI"/>
        
        <li>
            <xsl:if test="@rdf:about = $active">
                <xsl:attribute name="class">active</xsl:attribute>
            </xsl:if>

            <a href="{if (not(starts-with($href, $ac:contextUri))) then xs:anyURI(concat(lapp:base($ac:contextUri, $lapp:Application), '?uri=', encode-for-uri($href))) else $href}" title="{@rdf:about}">
                <xsl:apply-templates select="." mode="apl:logo"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="ac:label"/>
            </a>
        </li>
    </xsl:template>-->
    
</xsl:stylesheet>