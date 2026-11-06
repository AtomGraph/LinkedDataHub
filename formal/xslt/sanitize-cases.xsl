<?xml version="1.0" encoding="UTF-8"?>
<!--
The sanitize and canonical cases replayed against the code. With which=sanitize, the rules XML literals render through
are taken from imports/default.xsl as they are - every template in mode ldh:SafeXHTML, which ldh:XHTMLContent shares,
and ldh:url-scheme - and run on every case's literal. With which=canonical, the editor's canonical form is run on it,
canonical-xhtml.xsl and content-model.xsl included whole, the literal as the region's content. The output has the
shape of `ldh-xslt sanitize-cases` and `ldh-xslt canonical-cases`, so the two diff.

    java -cp Saxon-HE.jar net.sf.saxon.Transform -xsl:formal/xslt/sanitize-cases.xsl -it \
      cases=formal/xslt/sanitize-cases.tsv which=sanitize
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:axsl="urn:x-ldh-xslt-alias" exclude-result-prefixes="map">

    <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
    <xsl:output method="text"/>

    <xsl:param name="cases" as="xs:string"/>
    <xsl:param name="which" as="xs:string" select="'sanitize'"/>

    <xsl:variable name="xsl" select="resolve-uri('../../src/main/webapp/static/com/atomgraph/linkeddatahub/xsl/', static-base-uri())"/>
    <xsl:variable name="default" select="doc(resolve-uri('imports/default.xsl', $xsl))"/>

    <xsl:variable name="module" as="document-node()">
        <xsl:document>
            <axsl:stylesheet version="3.0" xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#" xmlns:cm="https://w3id.org/atomgraph/rdfa-editor/content-model#">
                <axsl:param name="literals" as="xs:string*"/>
                <axsl:output method="text"/>
                <xsl:choose>
                    <xsl:when test="$which = 'sanitize'">
                        <xsl:copy-of select="$default/xsl:stylesheet/xsl:template[tokenize(@mode) = 'ldh:SafeXHTML'] | $default/xsl:stylesheet/xsl:function[@name = 'ldh:url-scheme']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <axsl:include href="{resolve-uri('rdfa-editor/content-model.xsl', $xsl)}"/>
                        <axsl:include href="{resolve-uri('rdfa-editor/canonical-xhtml.xsl', $xsl)}"/>
                    </xsl:otherwise>
                </xsl:choose>

                <axsl:function name="ldh:quote" as="xs:string">
                    <axsl:param name="s" as="xs:string"/>
                    <axsl:sequence select="'&quot;' || replace(replace(replace(replace(replace($s, '\\', '\\\\'), '&quot;', '\\&quot;'), '&#9;', '\\t'), '&#10;', '\\n'), '&#13;', '\\r') || '&quot;'"/>
                </axsl:function>

                <axsl:function name="ldh:project" as="xs:string">
                    <axsl:param name="node" as="node()"/>
                    <axsl:sequence select="if ($node instance of text()) then ldh:quote($node) else
                        '(' || namespace-uri($node) || ' ' || local-name($node)
                        || string-join(sort($node/@*, 'http://www.w3.org/2005/xpath-functions/collation/codepoint', function($a) {{ namespace-uri($a) || ' ' || local-name($a) }}) ! (' @' || namespace-uri(.) || ' ' || local-name(.) || '=' || ldh:quote(.)))
                        || string-join($node/node() ! (' ' || ldh:project(.))) || ')'"/>
                </axsl:function>

                <axsl:template name="xsl:initial-template">
                    <axsl:for-each select="$literals">
                        <axsl:variable name="literal" select="parse-xml(.)/*"/>
                        <xsl:choose>
                            <xsl:when test="$which = 'sanitize'">
                                <axsl:variable name="rendered" as="node()*">
                                    <axsl:apply-templates select="$literal" mode="ldh:SafeXHTML"/>
                                </axsl:variable>
                                <axsl:value-of select="., string-join($rendered ! ldh:project(.), ' ')" separator="&#9;"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <axsl:variable name="region" as="element()">
                                    <div xmlns="http://www.w3.org/1999/xhtml">
                                        <axsl:sequence select="$literal"/>
                                    </div>
                                </axsl:variable>
                                <axsl:variable name="canonical" as="element()*">
                                    <axsl:call-template name="cm:canonical-xhtml">
                                        <axsl:with-param name="content" select="$region"/>
                                    </axsl:call-template>
                                </axsl:variable>
                                <axsl:value-of select="., string-join($canonical/node() ! ldh:project(.), ' ')" separator="&#9;"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <axsl:value-of select="codepoints-to-string(10)"/>
                    </axsl:for-each>
                </axsl:template>
            </axsl:stylesheet>
        </xsl:document>
    </xsl:variable>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="literals" select="unparsed-text-lines(resolve-uri($cases, resolve-uri('../../', static-base-uri())))[normalize-space()] ! substring-before(., '&#9;')"/>
        <xsl:value-of select="transform(map{ 'stylesheet-node': $module, 'initial-template': QName('http://www.w3.org/1999/XSL/Transform', 'initial-template'), 'stylesheet-params': map{ QName('', 'literals'): $literals }, 'delivery-format': 'serialized' })?output"/>
    </xsl:template>

</xsl:stylesheet>
