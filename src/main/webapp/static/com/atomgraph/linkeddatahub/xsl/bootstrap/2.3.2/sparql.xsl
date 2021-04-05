<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps/domain#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
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
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY dydra  "https://w3id.org/atomgraph/linkeddatahub/services/dydra#">
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
xmlns:dydra="&dydra;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:saxon="http://saxon.sf.net/"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>

    <xsl:param name="default-query" as="xs:string">SELECT DISTINCT *
WHERE
{
    { ?s ?p ?o }
    UNION
    {
        GRAPH ?g
        { ?s ?p ?o }
    }
}
LIMIT 100</xsl:param>

    <xsl:template match="*[@rdf:nodeID = 'run']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-run-query')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'save']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-save')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

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
                <xsl:with-param name="query" select="$ac:query"/>
                <xsl:with-param name="default-query" select="$default-query"/>
            </xsl:call-template>
        </div>
    </xsl:template>

    <xsl:template name="bs2:QueryForm">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" select="'query-form'" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
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
                <label for="service">Service</label>
                <xsl:text> </xsl:text>
                    <select id="service" name="service" class="input-xxlarge">
                        <option value="">[SPARQL service]</option>
                </select>
        
                <textarea id="query-string" name="query" class="span12" rows="15">
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
                    <xsl:if test="$service">
                        <input type="hidden" name="service" value="{$service}"/>
                    </xsl:if>
                    <xsl:for-each select="$mode">
                        <input type="hidden" name="mode" value="{.}"/>
                    </xsl:for-each>
    
                    <button type="submit" >
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                            <xsl:with-param name="class" select="'btn btn-primary'"/>
                        </xsl:apply-templates>
                    </button>
                </div>
            </fieldset>
        </form>
    </xsl:template>
    
    <!-- render dropdown from SPARQL service results -->
    
    <xsl:template name="onServiceLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="service-select" as="element()"/>
        <xsl:param name="selected-service" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                    
                    <xsl:for-each select="$service-select">
                        <xsl:result-document href="?.">
                            <xsl:for-each select="$results//*[@rdf:about]">
                                <xsl:sort select="ac:label(.)"/>

                                <xsl:apply-templates select="." mode="xhtml:Option">
                                    <xsl:with-param name="value" select="@rdf:about"/>
                                    <xsl:with-param name="selected" select="@rdf:about = $selected-service"/>
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="bs2:SaveQueryForm">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:param name="service" as="xs:anyURI?"/>
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
                    <xsl:value-of select="resolve-uri('ns/domain/default#Query', $ldt:base)"/> <!-- TO-DO: add to namespace ontology -->
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
                <xsl:with-param name="value" select="'&apl;service'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="id" select="'query-service'"/>
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="$service"/>
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
                <xsl:with-param name="value" select="'&sioc;has_container'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="value" select="resolve-uri('queries/', $ldt:base)"/>
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
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn btn-save-query'"/>
                    </xsl:apply-templates>
                </button>
            </div>
        </form>
    </xsl:template>
    
</xsl:stylesheet>