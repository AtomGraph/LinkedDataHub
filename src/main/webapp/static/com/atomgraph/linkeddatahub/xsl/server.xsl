<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:lapp="&lapp;"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:acl="&acl;"
xmlns:sd="&sd;"
exclude-result-prefixes="#all">

    <!-- the server-side bindings of the product-dualed functions: the servlet request context
         (request URI, base, origin, access modes, Memento headers), synchronous document access
         and the Jena-backed query parser. The Saxon-JS twins live in client/functions.xsl; the
         two modules mirror each other name for name, and shared modules call the names without
         knowing the product - which is what keeps client machinery (and this module's servlet bindings) out
         of the shared layer entirely. Imported by layout.xsl only. -->

    <!-- the term's document, when the product may consult it for a label: the server fetches
         synchronously (blocking the render is the design), the client only reads the Saxon-JS
         document pool - the one product-dualed primitive the label ladders build on, so the
         templates themselves stay product-neutral -->
    <xsl:function name="ldh:label-document" as="document-node()?">
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:sequence select="if (doc-available($uri)) then document($uri) else ()"/>
    </xsl:function>

    <xsl:function name="acl:mode" as="xs:anyURI*">
        <xsl:sequence select="ldh:link-targets($ldh:httpHeaders('Link'), '&acl;mode')"/>
    </xsl:function>

    <xsl:function name="ac:uri" as="xs:anyURI?">
        <xsl:sequence select="$ac:uri"/>
    </xsl:function>

    <!-- TimeMap URI from the Link response header (rel=timemap), present when the document is versioned -->
    <xsl:function name="ldh:timemap" as="xs:anyURI?">
        <xsl:sequence select="ldh:link-targets($ldh:httpHeaders('Link'), 'rel=timemap')[1]"/>
    </xsl:function>

    <!-- Memento-Datetime response header value, present on ?version= responses -->
    <xsl:function name="ldh:memento-datetime" as="xs:string?">
        <xsl:sequence select="$ldh:httpHeaders('Memento-Datetime')[1]"/>
    </xsl:function>

    <xsl:function name="ldh:request-uri" as="xs:anyURI">
        <xsl:sequence select="$ldh:requestUri"/>
    </xsl:function>

    <xsl:function name="ldh:base-uri" as="xs:anyURI">
        <xsl:param name="arg" as="node()"/>
        
        <xsl:sequence select="base-uri($arg)"/>
    </xsl:function>

    <xsl:function name="lapp:origin" as="xs:anyURI?">
        <xsl:sequence select="$lapp:origin"/>
    </xsl:function>

    <!-- the dataspace base: the origin with a trailing slash. ApplicationImpl.getBaseURI() derives it the
         same way - getOriginURI().resolve("/"), which discards any path - so there is no separate
         writer-supplied param, and LDH no longer reads Web-Client's $ldt:base. On a request that
         resolves to no application $lapp:origin is absent and this yields the relative '/', where the
         former $ldt:base binding raised XTTE0780. The Saxon-JS twin reads the active pane instead. -->
    <xsl:function name="lapp:base" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(lapp:origin() || '/')"/>
    </xsl:function>

    <xsl:function name="sd:endpoint" as="xs:anyURI">
        <xsl:sequence select="resolve-uri('sparql', lapp:base())"/>
    </xsl:function>

    <xsl:function name="ldh:parse-query" as="xs:string" override-extension-function="no">
        <xsl:param name="query" as="xs:string"/>

        <xsl:sequence select="'{}'"/>
    </xsl:function>

    <xsl:function name="ldh:url-decode" as="xs:string" override-extension-function="no" cache="yes">
        <xsl:param name="encoded-string" as="xs:string"/>
        
        <xsl:message terminate="yes">
            Not implemented -- com.atomgraph.linkeddatahub.writer.function.URLDecode needs to be registered as an extension function
        </xsl:message>
    </xsl:function>

</xsl:stylesheet>
