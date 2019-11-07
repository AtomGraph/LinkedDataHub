<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY lsm    "http://linkeddatahub.com/ns/sitemap/domain#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:preserve-space elements="rdfs:comment"/>
    
    <!--
    <xsl:template match="rdfs:isDefinedBy/@rdf:*" mode="bs2:FormControl" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:variable name="property" select=".." as="element()"/>

        <xsl:variable name="ontologies-doc" select="document(resolve-uri('ontologies/', $ldt:base))" as="document-node()?"/>
        <xsl:variable name="ontologies" select="key('resources-by-type', '&lsm;Ontology', $ontologies-doc)" as="element()*"/>
        <select name="ou" id="{$id}">
            <xsl:for-each select="$ontologies">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about =  $property/@rdf:resource"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>

        <span class="help-inline">Resource</span>
    </xsl:template>
    
    <xsl:template match="rdfs:isDefinedBy[position() &gt; 1]" mode="bs2:FormControl" priority="2"/>
    -->
    
    <xsl:template match="rdfs:comment/text()" mode="bs2:FormControl">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <textarea name="ol" id="{generate-id()}" class="rdfs:comment" rows="10">
            <xsl:value-of select="."/>
        </textarea>

        <xsl:if test="$type-label">
            <xsl:choose>
                <xsl:when test="../@rdf:datatype">
                    <xsl:apply-templates select="../@rdf:datatype"/>
                </xsl:when>
                <xsl:otherwise>
                    <span class="help-inline">Literal</span>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>