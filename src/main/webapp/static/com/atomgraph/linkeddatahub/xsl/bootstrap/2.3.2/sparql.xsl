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
<xsl:stylesheet version="3.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
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
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-save-query')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template name="bs2:QueryEditor" >
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>
        <xsl:param name="mode" select="$ac:mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="$ac:query" as="xs:string?"/>
        <xsl:param name="results-container-id" as="xs:string"/>
        
        <div class="row-fluid">
            <div class="left-nav span2"></div>

            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>

                <!--<legend>SPARQL editor</legend>-->
                
                <xsl:call-template name="bs2:QueryForm">
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="service" select="$service"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="query" select="$query"/>
                    <xsl:with-param name="default-query" select="$default-query"/>
                </xsl:call-template>
            </div>
        </div>
        
        <div id="{$results-container-id}"/>
    </xsl:template>

    <xsl:template name="bs2:QueryForm">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" select="'query-form'" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <!--<xsl:param name="uri" as="xs:anyURI?"/>-->
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="default-query" as="xs:string"/>
        
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
<!--                <label for="query-uri">Query</label>
                <xsl:text> </xsl:text>
                <select id="query-uri" name="query-uri" class="input-xxlarge">
                    <option value="">[Query]</option>
                </select>-->
                
                <label for="service">Service</label>
                <xsl:text> </xsl:text>
                <select id="query-service" name="service" class="input-xxlarge">
                    <option value="">[SPARQL service]</option>
                </select>
        
                <textarea id="query-string" name="query" class="span12" rows="15">
                    <xsl:value-of select="if ($query) then $query else $default-query"/>
                </textarea>

                <div class="form-actions">
                    <!-- retain URL parameters -->
<!--                    <xsl:if test="$ac:uri">
                        <input type="hidden" name="uri" value="{$ac:uri}"/>
                    </xsl:if>-->
                    <xsl:if test="$service">
                        <input type="hidden" name="service" value="{$service}"/>
                    </xsl:if>
                    <xsl:for-each select="$mode">
                        <input type="hidden" name="mode" value="{.}"/>
                    </xsl:for-each>
    
                    <button type="submit">
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                            <xsl:with-param name="class" select="'btn btn-primary'"/>
                        </xsl:apply-templates>
                    </button>
                    <button class="btn btn-save-query" type="button">
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                            <xsl:with-param name="class" select="'btn'"/>
                        </xsl:apply-templates>
                    </button>
                </div>
            </fieldset>
            
            <input name="href" type="hidden"/> <!-- used to store $content-uri value -->
        </form>
    </xsl:template>
    
</xsl:stylesheet>