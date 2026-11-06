<?xml version="1.0" encoding="UTF-8"?>
<!--
The href cases replayed against the code: the functions ldh:href is made of, taken from the stylesheets as they are
(imports/default.xsl, and Web-Client's functions.xsl beside this repository), compiled with a ldh:request-uri that
answers the case's page, and run on every case. The output has the shape of `ldh-client href-cases`, so the two diff.

    java -cp Saxon-HE.jar net.sf.saxon.Transform -xsl:formal/client/href-cases.xsl -it \
      cases=formal/client/href-cases.tsv web-client=../Web-Client
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:axsl="urn:x-ldh-client-alias" exclude-result-prefixes="map">

    <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
    <xsl:output method="text"/>

    <xsl:param name="cases" as="xs:string"/>
    <xsl:param name="web-client" as="xs:string" select="'../Web-Client'"/>

    <xsl:variable name="default" select="doc(resolve-uri('../../src/main/webapp/static/com/atomgraph/linkeddatahub/xsl/imports/default.xsl', static-base-uri()))"/>
    <xsl:variable name="functions" select="doc(resolve-uri($web-client || '/src/main/webapp/static/com/atomgraph/client/xsl/functions.xsl', resolve-uri('../../', static-base-uri())))"/>

    <!-- what ldh:href calls, and nothing else -->
    <xsl:variable name="names" select="('ldh:href', 'ldh:is-local', 'lds:origin', 'ldh:parse-query-params', 'ac:absolute-path', 'ac:build-uri', 'ac:document-uri')"/>

    <xsl:variable name="module" as="document-node()">
        <xsl:document>
            <axsl:stylesheet version="3.0" xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#" xmlns:lds="https://w3id.org/atomgraph/linkeddatahub/dataspaces#" xmlns:ac="https://w3id.org/atomgraph/client#">
                <axsl:param name="page" as="xs:string"/>
                <axsl:param name="uris" as="xs:string*"/>
                <axsl:output method="text"/>
                <xsl:copy-of select="($default, $functions)/xsl:stylesheet/xsl:function[@name = $names]"/>
                <!-- the page the case is read on, where the client reads window.location -->
                <axsl:function name="ldh:request-uri" as="xs:anyURI">
                    <axsl:sequence select="xs:anyURI($page)"/>
                </axsl:function>
                <!-- query values do not reach the projection the cases compare -->
                <axsl:function name="ldh:url-decode" as="xs:string">
                    <axsl:param name="s" as="xs:string"/>
                    <axsl:sequence select="$s"/>
                </axsl:function>
                <axsl:template name="xsl:initial-template">
                    <axsl:for-each select="$uris">
                        <axsl:value-of select="$page, ., substring-before(ldh:href(xs:anyURI(.)) || '?', '?')" separator="&#9;"/>
                        <axsl:value-of select="codepoints-to-string(10)"/>
                    </axsl:for-each>
                </axsl:template>
            </axsl:stylesheet>
        </xsl:document>
    </xsl:variable>

    <xsl:template name="xsl:initial-template">
        <xsl:variable name="rows" select="unparsed-text-lines(resolve-uri($cases, resolve-uri('../../', static-base-uri())))[normalize-space()] ! array { tokenize(., '&#9;') }"/>
        <xsl:for-each-group select="$rows" group-adjacent="?1">
            <xsl:value-of select="transform(map{ 'stylesheet-node': $module, 'initial-template': QName('http://www.w3.org/1999/XSL/Transform', 'initial-template'), 'stylesheet-params': map{ QName('', 'page'): current-grouping-key(), QName('', 'uris'): current-group() ! ?2 }, 'delivery-format': 'serialized' })?output"/>
        </xsl:for-each-group>
    </xsl:template>

</xsl:stylesheet>
