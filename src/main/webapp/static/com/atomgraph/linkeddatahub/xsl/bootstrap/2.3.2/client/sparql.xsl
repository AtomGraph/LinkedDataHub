<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
]>
<xsl:stylesheet version="3.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:sd="&sd;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:saxon="http://saxon.sf.net/"
exclude-result-prefixes="#all"
>

    <xsl:param name="default-query" as="xs:string">SELECT DISTINCT *
WHERE
{
    GRAPH ?g
    { ?s ?p ?o }
}
LIMIT 100</xsl:param>

    <!-- TEMPLATES -->
    
    <xsl:template match="*[@rdf:nodeID = 'run']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-run-query')"/>
    </xsl:template>

    <xsl:template name="bs2:QueryEditor">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7 main'" as="xs:string?"/>
        <xsl:param name="mode" select="$ac:mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="$ac:query" as="xs:string?"/>
        
        <div class="row-fluid">
            <div class="left-nav span2"></div>

            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
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
    </xsl:template>

    <xsl:template name="bs2:QueryForm">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'sparql-query-form form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="textarea-id" select="'id' || ac:uuid()" as="xs:string"/>
        <!--<xsl:param name="uri" as="xs:anyURI?"/>-->
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="default-query" as="xs:string"/>
        
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

<!--            <fieldset>-->
                <div class="control-group">
                    <label class="control-label">Service</label> <!-- for="service" -->

                    <div class="controls">
                        <select name="service" class="input-xxlarge input-query-service">
                            <option value="">
                                <xsl:value-of>
                                    <xsl:text>[</xsl:text>
                                    <xsl:apply-templates select="key('resources', 'sparql-service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                    <xsl:text>]</xsl:text>
                                </xsl:value-of>
                            </option>
                        </select>
                    </div>
                </div>
                
                <div class="control-group required">
                    <label class="control-label">Title</label> <!-- for="title" -->

                    <div class="controls">
                        <input type="text" name="title"/>
                    </div>
                </div>
        
                <textarea name="query" class="span12" rows="15">
                    <xsl:if test="$textarea-id">
                        <xsl:attribute name="id" select="$textarea-id"/>
                    </xsl:if>
                    
                    <xsl:value-of select="if ($query) then $query else $default-query"/>
                </textarea>

                <div class="form-actions">
                    <button type="submit">
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn btn-primary btn-run-query'"/>
                        </xsl:apply-templates>

                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                    <button type="button" class="btn btn-primary btn-save btn-save-query">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                    <button type="button" class="btn btn-cancel">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
<!--            </fieldset>-->
        </form>
    </xsl:template>

</xsl:stylesheet>