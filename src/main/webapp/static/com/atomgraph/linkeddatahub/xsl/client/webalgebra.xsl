<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY wa     "https://w3id.org/atomgraph/web-algebra">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:lds="&lds;"
xmlns:wa="&wa;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!--
        The Web-Algebra executor beside this instance (the web-algebra container, behind nginx at /webalgebra),
        as every caller in the client talks to it: the assistant's plans (client/chat.xsl) and the actions a
        package declares for a class (client/action.xsl). It acts for the reader whose certificate nginx
        forwards, so what a plan may write is what the reader may write.

        A plan is submitted with POST and answered 202 with an execution id; its result is then polled once a
        second until the execution ends. The caller says what to do along the way through two functions in the
        context map: 'on-progress' (optional), called with the context and the wa:execution while it runs, and
        'on-ended', called with the context and the final wa:execution - complete, or error with the steps and
        writes that did happen, which are reported rather than discarded.
    -->

    <!-- the executor is on this dataspace's origin, behind nginx at /webalgebra: the page's origin, never lds:base(),
         which a proxied document's lds:dataspace link moves to the origin it names -->
    <xsl:function name="ldh:webalgebra-href" as="xs:anyURI">
        <xsl:param name="path" as="xs:string"/>

        <xsl:sequence select="resolve-uri($path, xs:anyURI(lds:origin(ldh:request-uri()) || '/'))"/>
    </xsl:function>

    <!-- the submission: an XML body travels as a document node, which ixsl:http-request serializes itself -->
    <xsl:function name="ldh:webalgebra-request" as="map(*)">
        <xsl:param name="body" as="document-node()"/>

        <xsl:sequence select="map{ 'method': 'POST', 'href': ldh:webalgebra-href('webalgebra'), 'media-type': 'application/xml', 'body': $body, 'headers': map{ 'Accept': 'application/xml' } }"/>
    </xsl:function>

    <!-- 202: the execution has an id, and its result is polled from here on -->
    <xsl:function name="ldh:execution-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="id" select="$response?body/wa:execution/wa:id" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="$response?status = 202 and $id">
                <xsl:variable name="result-request" select="map{ 'method': 'GET', 'href': ldh:webalgebra-href('webalgebra/' || $id || '/result'), 'headers': map{ 'Accept': 'application/xml' } }" as="map(*)"/>
                <xsl:sequence select="ldh:poll-execution(map:put($context, 'result-request', $result-request))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- a second between polls: the steps arrive as they happen, and a plan is seconds to minutes long -->
    <xsl:function name="ldh:poll-execution" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="
          ixsl:sleep(1000)
            => ixsl:then(ldh:result-request($context, ?))
        "/>
    </xsl:function>

    <!-- 'result-request'/'result-response' rather than 'request'/'response', so a 429 on a poll retries the poll and
         not the submission (ldh:retry-request pairs the keys by name) -->
    <xsl:function name="ldh:result-request" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="sleep-result" as="item()?"/>

        <xsl:sequence select="
          ixsl:http-request($context('result-request'))
            => ixsl:then(ldh:rethread-response($context, ?, 'result-response'))
            => ixsl:then(ldh:handle-response(?, 'result-response'))
            => ixsl:then(ldh:result-response#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:result-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('result-response')" as="map(*)"/>
        <xsl:variable name="execution" select="$response?body/wa:execution" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$response?status = 202 and exists($execution)">
                <xsl:if test="map:contains($context, 'on-progress')">
                    <xsl:sequence select="$context('on-progress')($context, $execution)"/>
                </xsl:if>
                <xsl:sequence select="ldh:poll-execution($context)"/>
            </xsl:when>
            <xsl:when test="$response?status = 200 and $execution/wa:status = 'complete'">
                <xsl:sequence select="$context('on-ended')($context, $execution)"/>
            </xsl:when>
            <!-- a plan that failed answers 500 (or 409, a write refused) with the steps and writes that did happen;
                 they are reported, not discarded -->
            <xsl:when test="$execution/wa:status = 'error'">
                <xsl:sequence select="$context('on-ended')($context, $execution)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
