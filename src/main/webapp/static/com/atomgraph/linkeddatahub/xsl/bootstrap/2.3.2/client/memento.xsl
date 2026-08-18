<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh     "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp    "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac      "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf     "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY memento "http://mementoweb.org/ns#">
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
xmlns:memento="&memento;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
version="3.0"
>

    <!-- Memento (RFC 7089) version history modal -->

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
                                    <xsl:variable name="mementos" select="$response?body//*[@rdf:about][rdf:type/@rdf:resource = '&memento;Memento']" as="element()*"/>
                                    <xsl:variable name="sorted-mementos" select="sort($mementos, (), function($memento) { string($memento/memento:mementoDatetime) })" as="element()*"/>
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
                                                    <!-- header colors match the diff line colors: - lines come from the From version, + lines from the To version -->
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
                                                    <xsl:sort select="memento:mementoDatetime" order="descending"/>
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
                                    <div id="version-diff"/>
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

    <!-- runs the version diff instead of submitting the form -->
    <xsl:template match="form[@id = 'form-version-diff']" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="from-uri" select=".//input[@name = 'from'][ixsl:get(., 'checked')] ! xs:anyURI(ixsl:get(., 'value'))" as="xs:anyURI?"/>
        <xsl:variable name="to-uri" select=".//input[@name = 'to'][ixsl:get(., 'checked')] ! xs:anyURI(ixsl:get(., 'value'))" as="xs:anyURI?"/>

        <xsl:if test="exists($from-uri) and exists($to-uri)">
            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <xsl:variable name="context" select="map{ 'from-uri': $from-uri, 'to-uri': $to-uri }" as="map(*)"/>
            <!-- seed a resolved promise so the fan-out's ixsl:http-request calls run in an active promise context -->
            <ixsl:promise select="ixsl:resolve($context) => ixsl:then(ldh:version-diff-fanout#1)" on-failure="ldh:promise-failure#1"/>
        </xsl:if>
    </xsl:template>

    <!-- fan-out driver: runs as a promise callback (so ixsl:http-request is called in an active promise context), fetches both versions and joins them with ixsl:all -->
    <xsl:function name="ldh:version-diff-fanout" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:variable name="promises" as="array(*)" select="
          array {
            for $uri in ($context('from-uri'), $context('to-uri')) return
              let $request := map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/rdf+xml' } } return
                ixsl:http-request($request)
                  => ixsl:then(ldh:rethread-response(map{ 'request': $request }, ?))
                  => ixsl:then(ldh:handle-response#1)
          }"/>
        <xsl:sequence select="ixsl:all($promises) => ixsl:then(ldh:version-diff-response#1)"/>
    </xsl:function>

    <!-- renders the triple diff between the two selected versions into the history modal -->
    <xsl:function name="ldh:version-diff-response" as="item()?" ixsl:updating="yes">
        <xsl:param name="results" as="array(*)"/>

        <xsl:variable name="from-response" select="$results?1?response" as="map(*)"/>
        <xsl:variable name="to-response" select="$results?2?response" as="map(*)"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:for-each select="id('version-diff', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:choose>
                    <xsl:when test="every $response in ($from-response, $to-response) satisfies ($response?status = 200 and $response?media-type = 'application/rdf+xml')">
                        <xsl:variable name="from-triples" select="ldh:triples-map($from-response?body, false())" as="map(xs:string, element())"/>
                        <xsl:variable name="to-triples" select="ldh:triples-map($to-response?body, false())" as="map(xs:string, element())"/>
                        <xsl:variable name="removed" select="for $triple-key in ac:value-except(map:keys($from-triples), map:keys($to-triples)) return map:get($from-triples, $triple-key)" as="element()*"/>
                        <xsl:variable name="added" select="for $triple-key in ac:value-except(map:keys($to-triples), map:keys($from-triples)) return map:get($to-triples, $triple-key)" as="element()*"/>

                        <xsl:choose>
                            <xsl:when test="exists(($removed, $added))">
                                <xsl:sequence select="ldh:version-diff($removed, $added)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <p class="text-info">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'no-changes', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </p>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <div class="alert alert-error">
                            <xsl:text>Could not load the versions</xsl:text>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>
