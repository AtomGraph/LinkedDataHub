<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh     "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp    "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac      "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf     "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY prov    "http://www.w3.org/ns/prov#">
    <!ENTITY sp      "http://spinrdf.org/sp#">
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

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $timemap-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" select="map{ 'request': $request, 'timemap-uri': $timemap-uri, 'container': $container }" as="map(*)"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:timemap-response#1)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- renders the version history modal from the TimeMap RDF response -->
    <xsl:function name="ldh:timemap-response" as="item()?" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>

        <xsl:for-each select="$response">
            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

            <xsl:for-each select="$container">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div class="modal modal-constructor fade in" id="document-history-modal">
                        <div class="modal-header">
                            <button type="button" class="close">&#215;</button>
                            <legend>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'history', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </legend>
                            <p class="text-info">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'history-description', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </p>
                        </div>
                        <div class="modal-body">
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
                                        <table class="table table-striped">
                                            <colgroup>
                                                <col style="width: 45%;"/>
                                                <col style="width: 25%;"/>
                                                <col style="width: 15%;"/>
                                                <col style="width: 15%;"/>
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
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <xsl:apply-templates select="$mementos" mode="bs2:MementoList">
                                                    <xsl:sort select="prov:generatedAtTime" order="descending"/>
                                                    <xsl:with-param name="current-memento" select="$current-memento"/>
                                                    <xsl:with-param name="from-memento" select="$from-memento"/>
                                                    <xsl:with-param name="to-memento" select="$current-memento"/>
                                                </xsl:apply-templates>
                                            </tbody>
                                        </table>
                                        <div class="form-actions modal-footer">
                                            <button type="submit" class="btn btn-primary">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', 'compare', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                            <button type="button" class="btn btn-close">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                        </div>
                                    </form>
                                </xsl:when>
                                <xsl:otherwise>
                                    <div class="alert alert-error">
                                        <xsl:text>Could not load the version history</xsl:text>
                                    </div>
                                </xsl:otherwise>
                            </xsl:choose>
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
