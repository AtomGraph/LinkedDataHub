<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh     "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp    "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac      "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf     "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY prov    "http://www.w3.org/ns/prov#">
    <!ENTITY sp      "http://spinrdf.org/sp#">
    <!ENTITY acl     "http://www.w3.org/ns/auth/acl#">
]>
<xsl:stylesheet
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ldh="&ldh;"
xmlns:lapp="&lapp;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:prov="&prov;"
xmlns:sp="&sp;"
xmlns:acl="&acl;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
version="3.0"
>

    <!-- Memento (RFC 7089) version history modal and version diff loading -->

    <!-- open the version history modal instead of navigating to the TimeMap URL -->
    <xsl:template match="a[contains-token(@class, 'document-history')]" mode="ixsl:onclick" priority="1">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="timemap-uri" select="xs:anyURI(resolve-uri(@href, ldh:base-uri(.)))" as="xs:anyURI"/>
        <xsl:variable name="container" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $timemap-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <!-- ac:absolute-path() drops the ?version= that distinguishes a memento from the document it specializes -->
        <xsl:variable name="context" select="map{ 'request': $request, 'timemap-uri': $timemap-uri, 'doc-uri': ac:absolute-path(ldh:request-uri()), 'container': $container }" as="map(*)"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:load-document-modes#1)
            => ixsl:then(ldh:timemap-response#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- reads the live document's access modes, which decide whether a version can be restored.
         Neither the memento nor the TimeMap response can answer this: both are snapshot views and
         ResponseHeadersFilter caps them at acl:Read, so the modes are read from the document itself. -->
    <xsl:function name="ldh:load-document-modes" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:variable name="request" select="map{ 'method': 'HEAD', 'href': ldh:href($context('doc-uri')), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:sequence select="
          ixsl:http-request($request)
            => ixsl:then(ldh:rethread-response($context, ?, 'doc-response'))
        "/>
    </xsl:function>

    <!-- renders the version history modal from the TimeMap RDF response -->
    <xsl:function name="ldh:timemap-response" as="item()?" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <!-- same Link header parse as client.xsl uses to seed acl:mode(), but against the live document's response -->
        <xsl:variable name="acl-modes" select="ldh:link-targets($context('doc-response')?headers?link, '&acl;mode')" as="xs:anyURI*"/>
        <xsl:variable name="writable" select="$acl-modes = '&acl;Write'" as="xs:boolean"/>

        <xsl:for-each select="$response">
            <xsl:for-each select="$container">

                <!-- a modal takes over from the chrome that opened it: a drop-down the pick came from is dismissed here, once its own handler has run -->
                <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'btn-group')][contains-token(@class, 'open')] | ixsl:page()//*[contains-token(@class, 'ldh-form-actions-wrap')][contains-token(@class, 'is-open')]" mode="ldh:CloseDropdown"/>
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div class="ldhc-backdrop pos-top modal modal-constructor" id="document-history-modal">
                        <div class="ldhc-modal sz-xl" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                        <div class="ldhc-modal-head">
                            <div class="ldhc-modal-titles">
                                <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'history', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </h2>
                                <span class="ldhc-modal-sub">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'history-description', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </span>
                            </div>
                            <span class="ldhc-modal-x">
                                <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                            </span>
                        </div>
                        <div class="ldhc-modal-body">
                            <xsl:choose>
                                <xsl:when test="$response?status = 200 and $response?media-type = 'application/rdf+xml'">
                                    <xsl:variable name="mementos" select="$response?body//*[@rdf:about][prov:specializationOf/@rdf:resource]" as="element()*"/>
                                    <xsl:variable name="sorted-mementos" select="sort($mementos, (), function($memento) { string($memento/prov:generatedAtTime) })" as="element()*"/>
                                    <!-- on the live document view, the latest version is the one being viewed -->
                                    <xsl:variable name="current-memento" select="if (map:contains(ldh:query-params(), 'version')) then xs:anyURI(ac:absolute-path(ldh:request-uri()) || '?version=' || ldh:query-params()?version) else xs:anyURI($sorted-mementos[last()]/@rdf:about)" as="xs:anyURI?"/>
                                    <xsl:variable name="current-index" select="index-of($sorted-mementos ! string(@rdf:about), string($current-memento))[1]" as="xs:integer?"/>
                                    <!-- preselect the viewed version as the diff target and its predecessor as the diff source (the viewed version itself when there is none) -->
                                    <xsl:variable name="from-memento" select="(xs:anyURI($sorted-mementos[$current-index - 1]/@rdf:about), $current-memento)[1]" as="xs:anyURI?"/>
                                    <form id="form-version-diff">
                                        <table class="table">
                                            <colgroup>
                                                <col style="width: 38%;"/>
                                                <col style="width: 22%;"/>
                                                <col style="width: 12%;"/>
                                                <col style="width: 12%;"/>
                                                <col style="width: 16%;"/>
                                            </colgroup>
                                            <thead>
                                                <tr>
                                                    <th>
                                                        <xsl:value-of>
                                                            <xsl:apply-templates select="key('resources', 'version', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                        </xsl:value-of>
                                                    </th>
                                                    <th>
                                                        <xsl:value-of>
                                                            <xsl:apply-templates select="key('resources', 'agent', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                        </xsl:value-of>
                                                    </th>
                                                    <!-- header colors match the diff colors: removed content comes from the From version, added content from the To version -->
                                                    <th class="text-error">
                                                        <xsl:value-of>
                                                            <xsl:apply-templates select="key('resources', 'from', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                        </xsl:value-of>
                                                    </th>
                                                    <th class="text-success">
                                                        <xsl:value-of>
                                                            <xsl:apply-templates select="key('resources', 'to', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                        </xsl:value-of>
                                                    </th>
                                                    <!-- the restore column has no heading: the buttons name the action themselves -->
                                                    <th></th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <xsl:apply-templates select="$mementos" mode="bs2:MementoList">
                                                    <xsl:sort select="prov:generatedAtTime" order="descending"/>
                                                    <xsl:with-param name="current-memento" select="$current-memento"/>
                                                    <xsl:with-param name="from-memento" select="$from-memento"/>
                                                    <xsl:with-param name="to-memento" select="$current-memento"/>
                                                    <xsl:with-param name="writable" select="$writable"/>
                                                </xsl:apply-templates>
                                            </tbody>
                                        </table>
                                        <div class="ldh-block-foot">
                                            <button type="button" class="ldhc-btn in-neutral ap-outline sz-md btn-close">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                            <button type="submit" class="ldhc-btn in-primary ap-solid sz-md">
                                                <span class="msi sm" aria-hidden="true">compare_arrows</span>
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', 'compare', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                        </div>
                                    </form>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="ldh:error-alert('version-history-not-loaded', ldh:http-error-key($response?status), ())"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                        </div>
                    </div>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:function>

    <!-- navigates to the version diff view instead of submitting the form -->
    <xsl:template match="form[@id = 'form-version-diff']" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="from-uri" select=".//input[@name = 'from'][ixsl:get(., 'checked')] ! xs:anyURI(ixsl:get(., 'value'))" as="xs:anyURI?"/>
        <xsl:variable name="to-uri" select=".//input[@name = 'to'][ixsl:get(., 'checked')] ! xs:anyURI(ixsl:get(., 'value'))" as="xs:anyURI?"/>

        <xsl:if test="exists($from-uri) and exists($to-uri)">
            <!-- the memento URI is <doc>?version=<sha>; the diff view URL appends the compared version's SHA as display state -->
            <xsl:variable name="href" select="xs:anyURI($to-uri || '&amp;diff=' || substring-after($from-uri, '?version='))" as="xs:anyURI"/>
            <xsl:variable name="parsed" select="ldh:parse-href($href)" as="map(xs:string, item()?)"/>

            <xsl:for-each select="ancestor::div[contains-token(@class, 'modal')]">
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>

            <xsl:call-template name="ldh:DocumentNavigate">
                <xsl:with-param name="doc-uri" select="map:get($parsed, 'doc-uri')"/>
                <xsl:with-param name="fragment" select="map:get($parsed, 'fragment')"/>
                <xsl:with-param name="query-params" select="map:get($parsed, 'query-params')"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- restores a version: reads it back and writes it to the live document, which the versioning filter
         records as a new commit. The memento itself is never written to, so it stays immutable per RFC 7089. -->
    <xsl:template match="button[contains-token(@class, 'btn-restore')]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="memento-uri" select="xs:anyURI(ixsl:get(., 'value'))" as="xs:anyURI"/>
        <!-- ac:absolute-path() drops the ?version= that distinguishes a memento from the document it specializes -->
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI"/>
        <xsl:variable name="modal" select="ancestor::div[contains-token(@class, 'modal')]" as="element()?"/>

        <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))) ])">
            <xsl:sequence select="ldh:busy-cursor()"/>

            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $memento-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
            <xsl:variable name="context" select="map{ 'request': $request, 'doc-uri': $doc-uri, 'modal': $modal }" as="map(*)"/>
            <ixsl:promise select="
              ixsl:http-request($context('request'))
                => ixsl:then(ldh:rethread-response($context, ?))
                => ixsl:then(ldh:handle-response#1)
                => ixsl:then(ldh:restore-version#1) =>
                ixsl:finally(ldh:reset-cursor#0)
            " on-failure="ldh:promise-failure#1"/>
        </xsl:if>
    </xsl:template>

    <!-- writes the retrieved version back to the live document -->
    <xsl:function name="ldh:restore-version" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="$response?status = 200 and exists($response?body)">
                <!-- the graph store takes the document node directly; the server restamps dct:modified -->
                <xsl:variable name="request" select="map{ 'method': 'PUT', 'href': ldh:href($context('doc-uri')), 'media-type': 'application/rdf+xml', 'body': $response?body, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($request)
                    => ixsl:then(ldh:rethread-response(map:remove($context, 'response'), ?))
                    => ixsl:then(ldh:restored-version#1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:restore-failed($context, 'version-not-read')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- dismisses the modal and re-renders the document, whose newest version is now the restored one -->
    <xsl:function name="ldh:restored-version" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 201, 204)">
                <xsl:for-each select="$context('modal')">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <!-- land on the live document rather than the ?version= view the restore was started from, which is now stale -->
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$context('doc-uri')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:restore-failed($context, 'version-not-restored')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- reports a failed restore inside the modal, so the agent keeps the version list they were working from -->
    <xsl:function name="ldh:restore-failed" as="item()?" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="title-key" as="xs:string"/> <!-- translations.rdf nodeID naming which step of the restore failed -->

        <xsl:for-each select="($context('modal')//div[contains-token(@class, 'ldhc-modal-body')])[1]">
            <xsl:result-document href="?." method="ixsl:prepend-content">
                <xsl:sequence select="ldh:error-alert($title-key, ldh:http-error-key($context('response')?status), ())"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:function>

    <!-- fetches the ?diff= comparison version when the context carries a diff request; passes the context through otherwise -->
    <xsl:function name="ldh:load-diff-version" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="map:contains($context, 'diff-request')">
                <xsl:sequence select="
                  ixsl:http-request($context('diff-request'))
                    => ixsl:then(ldh:rethread-response($context, ?, 'diff-response'))
                    => ixsl:then(ldh:handle-response(?, 'diff-response'))
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- union of the two versions' descriptions for the diff view, merged via ldh:MergeRDF; a changed typed block keeps only its current rdf:value because its render factory cannot handle two -->
    <xsl:function name="ldh:diff-union" as="document-node()">
        <xsl:param name="to-doc" as="document-node()"/>
        <xsl:param name="from-doc" as="document-node()"/>
        <xsl:param name="removed-keys" as="xs:string*"/>

        <xsl:variable name="merged" select="ldh:merge-metadata($to-doc, $from-doc)" as="document-node()"/>
        <xsl:document>
            <xsl:apply-templates select="$merged" mode="ldh:DiffPruneValues">
                <xsl:with-param name="removed-keys" select="$removed-keys" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:function>

    <!-- identity transform for ldh:DiffPruneValues mode -->
    <xsl:template match="@* | node()" mode="ldh:DiffPruneValues">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- drop a typed block's removed rdf:value, but only when the block survives in the To version (has triples outside the removed set) -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select')]/rdf:value" mode="ldh:DiffPruneValues">
        <xsl:param name="removed-keys" as="xs:string*" tunnel="yes"/>

        <xsl:if test="not(ldh:triple-key(., false()) = $removed-keys and ../*[not(ldh:triple-key(., false()) = $removed-keys)])">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
