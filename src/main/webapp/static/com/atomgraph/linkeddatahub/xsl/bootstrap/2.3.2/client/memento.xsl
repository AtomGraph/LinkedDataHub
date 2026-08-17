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
                                    <table class="table table-striped">
                                        <colgroup>
                                            <col style="width: 60%;"/>
                                            <col style="width: 40%;"/>
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
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <xsl:apply-templates select="$response?body//*[@rdf:about][rdf:type/@rdf:resource = '&memento;Memento']" mode="bs2:MementoList">
                                                <xsl:sort select="memento:mementoDatetime" order="descending"/>
                                            </xsl:apply-templates>
                                        </tbody>
                                    </table>
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

</xsl:stylesheet>
