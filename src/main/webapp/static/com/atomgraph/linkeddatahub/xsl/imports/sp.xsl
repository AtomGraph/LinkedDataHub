<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
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
xmlns:lapp="&lapp;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:sp="&sp;"
exclude-result-prefixes="#all">
    
    <xsl:template match="*[@rdf:about = '&sp;Ask']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'ask-query', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Select']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'select-query', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Describe']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'describe-query', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Construct']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'construct-query', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="#current"/>
    </xsl:template>

    <!-- ROW: WRONG IMPORT PRECEDENCE! -->
    
<!--    <xsl:template match="*[sp:text/text()]" mode="ldh:BlockRow" priority="1">
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

    <xsl:template match="sp:text/text() | sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="ac:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'ldhc-cf-area sparql-query-string'" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="name" select="'ol'" as="xs:string"/>
        <xsl:param name="rows" select="3" as="xs:integer"/>
        <xsl:param name="gutter-rows" select="max(($rows, count(tokenize(string(self::text()), '\n'))))" as="xs:integer"/>

        <div class="ldhc-codefield">
            <div class="ldhc-cf-gutter" aria-hidden="true">
                <xsl:for-each select="1 to $gutter-rows">
                    <div>
                        <xsl:value-of select="."/>
                    </div>
                </xsl:for-each>
            </div>

            <textarea name="{$name}" id="{generate-id()}" rows="{$rows}" spellcheck="false">
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
                </xsl:if>

                <xsl:if test="self::text()">
                    <xsl:value-of select="."/>
                </xsl:if>
            </textarea>
        </div>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/text() | sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ldhc-tag sz-sm em-quiet an-term is-literal'"/>
                <xsl:with-param name="label" as="item()*">
                    <xsl:apply-templates select="key('resources', 'literal', ldh:translations())" mode="ac:label"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>