<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:sp="&sp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <xsl:template match="*[@rdf:about = '&sp;Ask']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'ask-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Select']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'select-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Describe']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'describe-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Construct']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'construct-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <!-- ROW: WRONG IMPORT PRECEDENCE! -->
    
<!--    <xsl:template match="*[sp:text/text()]" mode="bs2:Row" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'post-construct'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="content-value" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="about" select="$about"/>
            <xsl:with-param name="typeof" select="$typeof"/>
            <xsl:with-param name="content-value" select="$content-value"/>
            <xsl:with-param name="mode" select="$mode"/>
        </xsl:next-match>
    </xsl:template>-->

    <!-- FORM CONTROL MODE -->

    <xsl:template match="sp:text/text() | sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'sparql-query-string'" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="name" select="'ol'" as="xs:string"/>
        <xsl:param name="rows" select="10" as="xs:integer"/>
        <xsl:param name="style" select="'font-family: monospace;'" as="xs:string"/>

        <textarea name="{$name}" id="{generate-id()}" rows="{$rows}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$style">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>
            
            <xsl:if test="self::text()">
                <xsl:value-of select="."/>
            </xsl:if>
        </textarea>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/text() | sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <span class="help-inline">Literal</span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/@rdf:datatype" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:next-match>
    </xsl:template>
    
</xsl:stylesheet>