<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
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
        <xsl:param name="class" select="'row-fluid override-content'" as="xs:string?"/>
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
    
    <!-- BLOCK MODE -->

    <xsl:template match="*[sp:text/text()] | *[@rdf:nodeID]/sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:Block" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" select="'id' || ac:uuid()" as="xs:string?"/>
        <xsl:param name="class" select="'sparql-query-form form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="textarea-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="sp:text" as="xs:string"/>
        <xsl:param name="show-properties" select="false()" as="xs:boolean"/>

        <xsl:apply-templates select="." mode="bs2:Header"/>
        
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

            <textarea name="query" class="span12 sparql-query-string" rows="15">
                <xsl:if test="$textarea-id">
                    <xsl:attribute name="id" select="$textarea-id"/>
                </xsl:if>

                <xsl:value-of select="$query"/>
            </textarea>

            <div class="form-actions">
                <button type="submit">
                    <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn btn-primary btn-run-query wymupdate'"/>
                    </xsl:apply-templates>

                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
                <button type="button" class="btn btn-primary btn-open-query">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'open', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
                <button type="button" class="btn btn-primary btn-save btn-save-query">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
            </div>
        </form>
        
        <xsl:if test="$show-properties">
            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
        </xsl:if>
    </xsl:template>

    <!-- FORM CONTROL MODE -->

    <xsl:template match="sp:text/text() | *[@rdf:*[local-name() = 'nodeID']]/sp:text/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
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
    
    <xsl:template match="sp:text/text() | *[@rdf:*[local-name() = 'nodeID']]/sp:text/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControlTypeLabel">
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