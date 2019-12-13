<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ldt="&ldt;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:nfo="&nfo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:preserve-space elements="nfo:fileName"/>
        
    <xsl:template match="nfo:fileName/text() | *[@rdf:*[local-name() = 'nodeID']]/nfo:fileName/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept" as="xs:string?"/>
        <xsl:param name="container" select="resolve-uri('uploads/', $ldt:base)" as="xs:anyURI"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="'file'"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <!--
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="value" select="."/>
            -->
        </xsl:call-template>
        
        <!--
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'pu'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="'&sioc;has_container'"/>
        </xsl:call-template>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="$container"/>
        </xsl:call-template>
        -->
        
        <span class="help-inline">Upload</span>
    </xsl:template>

    <xsl:template match="nfo:fileName/@rdf:datatype" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:next-match>
    </xsl:template>
     
</xsl:stylesheet>