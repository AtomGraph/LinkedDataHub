<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:lapp="&lapp;"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:sh="&sh;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:srx="&srx;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="../bootstrap/2.3.2/layout.xsl"/>

    <!-- CSS: add ldh.css after the Bootstrap stack -->
    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="xhtml:Style">
        <xsl:next-match/>
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/ldh.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
    </xsl:template>

    <!-- DocumentBody: add ldh-document class; document-body preserved for client handlers -->
    <xsl:template match="rdf:RDF" mode="bs2:DocumentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'document-body ldh-document'" as="xs:string?"/>
        <xsl:param name="mode" as="xs:anyURI"/>
        <xsl:param name="about" as="xs:anyURI"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="about" select="$about"/>
        </xsl:next-match>
    </xsl:template>

    <!-- ContentBody (http:Response): drop container-fluid -->
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response') and not(key('resources-by-type', '&spin;ConstraintViolation')) and not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ContentBody" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content-body ldh-content'" as="xs:string?"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
    </xsl:template>

    <!-- ContentBody (srx:sparql): drop container-fluid -->
    <xsl:template match="srx:sparql" mode="bs2:ContentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content-body ldh-content'" as="xs:string?"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
    </xsl:template>

    <!-- ContentBody (rdf:RDF): drop container-fluid -->
    <xsl:template match="rdf:RDF" mode="bs2:ContentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content-body ldh-content'" as="xs:string?"/>
        <xsl:param name="mode" select="ac:mode(root())" as="xs:anyURI"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="mode" select="$mode"/>
        </xsl:next-match>
    </xsl:template>

    <!-- Left nav: suppress empty Bootstrap span2 div -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Left" priority="1"/>

    <!-- Right nav: replace Bootstrap span3 class -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Right">
        <xsl:next-match>
            <xsl:with-param name="class" select="'ldh-block-nav'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- Right nav (Object with resource): replace Bootstrap span3 class -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Object'][rdf:value/@rdf:resource]" mode="bs2:Right" priority="1">
        <xsl:next-match>
            <xsl:with-param name="class" select="'ldh-block-nav'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- Block content dispatch: shared by generic SSR and SaxonJS block templates -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:BlockContent">
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>

        <xsl:variable name="doc" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:copy-of select="."/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>

        <div>
            <xsl:if test="$main-class">
                <xsl:attribute name="class" select="$main-class"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$mode = '&ac;MapMode'">
                    <xsl:apply-templates select="$doc" mode="bs2:Map">
                        <xsl:with-param name="id" select="generate-id() || '-map-canvas'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$mode = '&ac;ChartMode'">
                    <xsl:apply-templates select="$doc" mode="bs2:Chart">
                        <xsl:with-param name="canvas-id" select="generate-id() || '-chart-canvas'"/>
                        <xsl:with-param name="show-save" select="false()"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$mode = '&ac;GraphMode'">
                    <xsl:apply-templates select=".." mode="bs2:Graph"/>
                </xsl:when>
                <xsl:when test="$mode = '&ac;EditMode'">
                    <xsl:apply-templates select="." mode="bs2:Form">
                        <xsl:with-param name="required" select="rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </div>

        <xsl:apply-templates select="." mode="bs2:Right"/>
    </xsl:template>

    <!-- Generic resource block (SSR): no Bootstrap grid, content via ldh:BlockContent -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Row">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>
            <xsl:if test="$style">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="ldh:BlockContent">
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="main-class" select="$main-class"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <!-- Generic resource block (SaxonJS CSR): same structure, overrides Bootstrap SaxonJS wrapper to remove span12 -->
    <xsl:template match="*[*][@rdf:about][not(rdf:type/@rdf:resource = ('&http;Response', '&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select'))] | *[*][@rdf:nodeID][not(rdf:type/@rdf:resource = ('&http;Response', '&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select'))]" mode="bs2:Row" priority="0.7" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>
            <xsl:if test="$style">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="ldh:BlockContent">
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="main-class" select="$main-class"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <!-- Typed resource blocks (Object, View, charts, queries): drop row-fluid from outer div -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select')]" mode="bs2:Row" priority="1">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean?"/>
        <xsl:param name="show-row-block-controls" select="true()" as="xs:boolean"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="about" select="$about"/>
            <xsl:with-param name="typeof" select="$typeof"/>
            <xsl:with-param name="draggable" select="$draggable"/>
            <xsl:with-param name="show-row-block-controls" select="$show-row-block-controls"/>
        </xsl:next-match>
    </xsl:template>

    <!-- XHTML content blocks: drop row-fluid and span7 -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;XHTML'][rdf:value[@rdf:parseType = 'Literal']/xhtml:div]" mode="bs2:Row" priority="1">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean?"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="about" select="$about"/>
            <xsl:with-param name="typeof" select="$typeof"/>
            <xsl:with-param name="main-class" select="$main-class"/>
            <xsl:with-param name="draggable" select="$draggable"/>
        </xsl:next-match>
    </xsl:template>

    <!-- Resource header: drop Bootstrap well class -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ldh-header'" as="xs:string?"/>
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
    </xsl:template>

</xsl:stylesheet>
