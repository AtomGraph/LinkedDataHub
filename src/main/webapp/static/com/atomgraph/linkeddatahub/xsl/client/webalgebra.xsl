<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY wa     "https://w3id.org/atomgraph/web-algebra">
    <!ENTITY waldh  "https://w3id.org/atomgraph/web-algebra/linkeddatahub">
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

    <!-- PLANS, as every caller shows them: the assistant's plan card and an action's confirmation render a plan the
         same way, as the tree of its operations -->

    <!-- the trace: a plan's operations as the rows they will be executed as, nested as the operations are, each
         folding out its own XML. Folded under its count unless $open -->
    <xsl:template match="*" mode="ldh:PlanTrace">
        <xsl:param name="open" select="false()" as="xs:boolean"/>

        <details class="ldh-chat-trace">
            <xsl:if test="$open">
                <xsl:attribute name="open" select="''"/>
            </xsl:if>
            <summary>
                <span class="msi sm chev" aria-hidden="true">chevron_right</span>
                <xsl:value-of select="count(ldh:plan-operations(.))"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="key('resources', 'chat-steps', ldh:translations())" mode="ac:label"/>
            </summary>
            <ul class="ldh-chat-steps">
                <xsl:apply-templates select="." mode="ldh:OperationTree"/>
            </ul>
        </details>
    </xsl:template>

    <!-- an operation before it runs, with the operations inside its arguments nested under it: its glyph says what it
         does to data (reads, writes, can take away), its state says it is planned. Once the executor reports, the same
         row is a wa:step -->
    <xsl:template match="*" mode="ldh:OperationTree">
        <xsl:variable name="kind" select="ldh:operation-kind(ldh:operation-name(.))" as="xs:string"/>
        <xsl:variable name="nested" select="ldh:nested-operations(.)" as="element()*"/>

        <li>
            <details class="ldh-chat-step is-planned kd-{$kind}">
                <summary>
                    <span class="st msi sm" aria-hidden="true">
                        <xsl:value-of select="map{ 'read': 'visibility', 'write': 'edit', 'destructive': 'warning' }($kind)"/>
                    </span>
                    <span class="op">
                        <xsl:value-of select="ldh:operation-name(.)"/>
                    </span>
                    <span class="mono muted"/>
                </summary>
                <xsl:sequence select="ldh:step-xml(.)"/>
            </details>
            <xsl:if test="exists($nested)">
                <ul>
                    <xsl:apply-templates select="$nested" mode="ldh:OperationTree"/>
                </ul>
            </xsl:if>
        </li>
    </xsl:template>

    <!-- the operations directly inside an operation. Arguments are the children and the operations are the
         arguments' children in the algebra's namespace, anything else there being inline data - except for the
         sequence form and a Variable, whose steps and value stand directly under them -->
    <xsl:function name="ldh:nested-operations" as="element()*">
        <xsl:param name="operation" as="element()"/>

        <xsl:sequence select="if ($operation/self::wa:Sequence or $operation/self::wa:Variable) then $operation/*[namespace-uri() = ('&wa;', '&waldh;')] else $operation/*/*[namespace-uri() = ('&wa;', '&waldh;')]"/>
    </xsl:function>

    <!-- how the service names an operation: the algebra's own bare, LinkedDataHub's with the family's prefix, as
         wa:operation/@name and wa:step/@operation carry it -->
    <xsl:function name="ldh:operation-name" as="xs:string">
        <xsl:param name="operation" as="element()"/>

        <xsl:sequence select="if (namespace-uri($operation) = '&waldh;') then 'waldh:' || local-name($operation) else local-name($operation)"/>
    </xsl:function>

    <!-- the operation elements of a plan in the order the service lists them: an operation, then the operations
         inside it, depth first -->
    <xsl:function name="ldh:plan-operations" as="element()*">
        <xsl:param name="operation" as="element()"/>

        <xsl:sequence select="$operation, for $child in ldh:nested-operations($operation) return ldh:plan-operations($child)"/>
    </xsl:function>

    <!-- the bytes that will be (or were) executed, not a rendering of them -->
    <xsl:function name="ldh:step-xml" as="element()?">
        <xsl:param name="operation" as="element()?"/>

        <xsl:for-each select="$operation">
            <div class="ac-codefield">
                <pre>
                    <xsl:value-of select="serialize(., map{ 'method': 'xml', 'indent': true() })"/>
                </pre>
            </div>
        </xsl:for-each>
    </xsl:function>

    <!-- what an operation does to data, by name: the algebra's writes and the waldh: family's creations and additions
         change documents, PATCH and the removals can take content away, everything else only reads -->
    <xsl:function name="ldh:operation-kind" as="xs:string">
        <xsl:param name="name" as="xs:string"/>

        <xsl:sequence select="
          if ($name = ('PATCH', 'DELETE', 'waldh:RemoveBlock')) then 'destructive'
          else if ($name = ('PUT', 'POST') or starts-with($name, 'waldh:Create') or starts-with($name, 'waldh:Add')) then 'write'
          else 'read'"/>
    </xsl:function>

</xsl:stylesheet>
