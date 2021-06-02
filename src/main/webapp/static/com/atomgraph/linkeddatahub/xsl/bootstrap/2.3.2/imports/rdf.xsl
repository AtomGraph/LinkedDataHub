<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY sparql "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
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
xmlns:lapp="&lapp;"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:sparql="&sparql;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:spin="&spin;"
xmlns:sp="&sp;"
xmlns:void="&void;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:saxon="http://saxon.sf.net/"
exclude-result-prefixes="#all">

    <!-- shortened version of @rdf:resource bs2:FormControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:TypeControl">
        <xsl:param name="forClass" as="xs:anyURI?"/> 
        <xsl:param name="hidden" select="false()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$hidden"> <!-- can't apply bs2:FormControl on @rdf:resource here as that pattern/mode is off -->
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <div class="control-group">
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="value" select="'&rdf;type'"/>
                    </xsl:call-template>

                    <label class="control-label">
                        <xsl:value-of select="ac:label(key('resources', '&rdf;type', document('&rdf;')))"/>
                    </label>

                    <div class="controls">
                        <xsl:if test="$forClass">
                            <input type="hidden" class="forClass" value="{$forClass}"/>
                        </xsl:if>

                        <xsl:apply-templates select="@rdf:resource" mode="#current"/>

                        <!-- adding more types is disabled at this point -->
                        <!--
                        <span>
                            <button type="button" class="btn add-type">
                                <xsl:apply-templates use-when="system-property('xsl:product-name') = 'SAXON'" select="key('resources', 'add', document('translations.rdf'))" mode="apl:logo"/>
                                <xsl:text use-when="system-property('xsl:product-name') eq 'Saxon-JS'">&#x2715;</xsl:text>
                            </button>
                        </span>
                        -->
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="rdf:type/@rdf:resource" mode="bs2:TypeControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject input-xxlarge'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="auto" select="local-name() = 'nodeID' or starts-with(., $ldt:base)" as="xs:boolean"/>
        <xsl:variable name="doc-uri" select="if (starts-with($ldt:base, $ac:contextUri)) then ac:document-uri(.) else ac:build-uri($ldt:base), map{ 'uri': string(ac:document-uri(.)) })" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="doc-available($doc-uri) and key('resources', ., document($doc-uri))">
                <span>
                    <xsl:for-each select="key('resources', ., document($doc-uri))">
                        <xsl:apply-templates select="." mode="apl:Typeahead">
                            <xsl:with-param name="class" select="'btn add-typeahead add-typetypeahead'"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="bs2:FormControl">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="auto" select="$auto"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>