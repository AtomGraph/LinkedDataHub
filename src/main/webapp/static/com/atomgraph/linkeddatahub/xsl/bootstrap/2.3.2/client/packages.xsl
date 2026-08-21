<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh     "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp    "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac      "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf     "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs    "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY dct     "http://purl.org/dc/terms/">
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
xmlns:rdfs="&rdfs;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
version="3.0"
>

    <!-- package management in the application settings modal. An application imports a package with a
    single ldh:import triple; the package stylesheet is composed into the application stylesheet on the
    next request. The package checkboxes are RDF/POST inputs in the settings form, so its Save submits
    the ldh:import triples together with the other settings. -->

    <!-- catalog of available packages; resolved through the Linked Data proxy (served from the bundled
    copy until the registry is live) -->
    <xsl:variable name="ldh:package-catalog" select="xs:anyURI('https://packages.linkeddatahub.com/')" as="xs:anyURI"/>

    <!-- load/set pair for ldh:fire-load-set-parallel -->

    <xsl:function name="ldh:load-package-catalog" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="request-uri" select="ldh:href($ldh:package-catalog, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>

        <xsl:sequence select="map:merge(($context, map{ 'package-catalog-request': $request }))"/>
    </xsl:function>

    <xsl:function name="ldh:set-package-catalog" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('package-catalog-response')" as="map(*)"/>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:sequence select="map:merge(($context, map{ 'package-catalog': ?body }))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <!-- renders the package table from the catalog document -->

    <xsl:template match="rdf:RDF" mode="ldh:PackageList">
        <xsl:param name="installed" as="xs:anyURI*"/>
        <xsl:variable name="packages" select="key('resources', distinct-values(*/rdfs:member/@rdf:resource))" as="element()*"/>

        <xsl:if test="$packages">
            <fieldset id="packages">
                <legend>
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'packages', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </xsl:value-of>
                </legend>
                <table class="table table-striped">
                    <colgroup>
                        <col style="width: 25%;"/>
                        <col style="width: 60%;"/>
                        <col style="width: 15%;"/>
                    </colgroup>
                    <thead>
                        <tr>
                            <th>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&lapp;Package', document(ac:document-uri('&lapp;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </th>
                            <th>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&dct;description', document(ac:document-uri('&dct;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </th>
                            <th>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'installed', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:apply-templates select="$packages" mode="#current">
                            <xsl:sort select="lower-case(dct:title[1])"/>
                            <xsl:with-param name="installed" select="$installed"/>
                        </xsl:apply-templates>
                    </tbody>
                </table>
            </fieldset>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@rdf:about]" mode="ldh:PackageList">
        <xsl:param name="installed" as="xs:anyURI*"/>

        <tr>
            <td>
                <a href="{ldh:href(xs:anyURI(@rdf:about), map{})}">
                    <xsl:apply-templates select="." mode="ac:label"/>
                </a>
            </td>
            <td>
                <xsl:value-of select="dct:description[1]"/>
            </td>
            <td>
                <input type="hidden" name="pu" value="&ldh;import"/>
                <input type="checkbox" name="ou" value="{@rdf:about}">
                    <xsl:if test="@rdf:about = $installed">
                        <xsl:attribute name="checked" select="'checked'"/>
                    </xsl:if>
                </input>
            </td>
        </tr>
    </xsl:template>

</xsl:stylesheet>
