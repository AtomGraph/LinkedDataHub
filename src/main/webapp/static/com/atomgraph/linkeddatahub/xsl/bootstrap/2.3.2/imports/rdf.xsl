<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY sparql "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
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
xmlns:ldh="&ldh;"
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
        <xsl:param name="this" select="xs:anyURI(concat(namespace-uri(), local-name()))" as="xs:anyURI"/>
        <!-- <xsl:param name="forClass" as="xs:anyURI?"/>  -->
        <xsl:param name="hidden" select="false()" as="xs:boolean"/>
        <!-- types are required on document instances -->
        <xsl:param name="required" select="@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')" as="xs:boolean"/>
        <xsl:param name="for" select="generate-id(@rdf:resource)" as="xs:string"/>

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

                    <label class="control-label" for="{$for}" title="{$this}">
                        <xsl:value-of select="ac:label(key('resources', $this, document(ac:document-uri(namespace-uri()))))"/>
                    </label>

                    <div class="controls">
                        <xsl:if test="not($required)">
                            <div class="btn-group pull-right">
                                <button type="button" tabindex="-1">
                                    <xsl:attribute name="title">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'remove-stmt', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </xsl:attribute>

                                    <xsl:apply-templates select="key('resources', 'remove', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                        <xsl:with-param name="class" select="'btn btn-small pull-right'"/>
                                    </xsl:apply-templates>
                                </button>
                            </div>
                        </xsl:if>

                        <!--
                        <xsl:if test="$forClass">
                            <input type="hidden" class="forClass" value="{$forClass}"/>
                        </xsl:if>
                        -->

                        <xsl:apply-templates select="@rdf:resource" mode="#current"/>
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
        <xsl:param name="type-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="lookup-class" select="'type-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="if ($type-metadata) then key('resources', ., $type-metadata) else false()">
                <xsl:apply-templates select="key('resources', ., $type-metadata)" mode="ldh:Typeahead">
                    <xsl:with-param name="class" select="'btn add-typeahead add-type-typeahead'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="value" select="."/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        <span class="help-inline">
            <xsl:value-of select="ac:label(key('resources', '&owl;Class', document(ac:document-uri('&owl;'))))"/>
        </span>
    </xsl:template>
    
</xsl:stylesheet>