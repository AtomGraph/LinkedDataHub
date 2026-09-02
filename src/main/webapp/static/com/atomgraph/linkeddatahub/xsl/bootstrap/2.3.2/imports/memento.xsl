<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rdf     "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY prov    "http://www.w3.org/ns/prov#">
    <!ENTITY dct     "http://purl.org/dc/terms/">
    <!ENTITY lapp    "https://w3id.org/atomgraph/linkeddatahub/apps#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
xmlns:lapp="&lapp;"
xmlns:ac="https://w3id.org/atomgraph/client#"
xmlns:rdf="&rdf;"
xmlns:prov="&prov;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
>

    <!-- Memento (RFC 7089) version history rendering -->

    <!-- a version entry: datetime links to the memento (?version= URI), which navigates like any document link -->
    <xsl:template match="*[@rdf:about][prov:specializationOf/@rdf:resource]" mode="bs2:MementoList">
        <!-- the memento URI of the version currently being viewed; when the live document is viewed, callers pass the latest memento -->
        <xsl:param name="current-memento" select="if (map:contains(ldh:query-params(), 'version')) then xs:anyURI(ac:absolute-path(ldh:request-uri()) || '?version=' || ldh:query-params()?version) else ()" as="xs:anyURI?"/>
        <!-- preselected diff endpoints: the version being viewed and its predecessor -->
        <xsl:param name="from-memento" as="xs:anyURI?"/>
        <xsl:param name="to-memento" as="xs:anyURI?"/>
        <!-- whether the agent can write the live document, which is what a restore rewrites -->
        <xsl:param name="writable" select="false()" as="xs:boolean"/>

        <tr>
            <td>
                <xsl:choose>
                    <!-- the version being viewed: bold, no self-link -->
                    <xsl:when test="@rdf:about = $current-memento">
                        <strong>
                            <xsl:apply-templates select="prov:generatedAtTime/text()"/>
                        </strong>
                    </xsl:when>
                    <xsl:otherwise>
                        <a href="{@rdf:about}">
                            <xsl:apply-templates select="prov:generatedAtTime/text()"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
            <td>
                <xsl:apply-templates select="dct:creator/@rdf:resource"/>
            </td>
            <td>
                <input type="radio" name="from" value="{@rdf:about}">
                    <xsl:if test="@rdf:about = $from-memento">
                        <xsl:attribute name="checked" select="'checked'"/>
                    </xsl:if>
                </input>
            </td>
            <td>
                <input type="radio" name="to" value="{@rdf:about}">
                    <xsl:if test="@rdf:about = $to-memento">
                        <xsl:attribute name="checked" select="'checked'"/>
                    </xsl:if>
                </input>
            </td>
            <td>
                <!-- restoring is a point action on one version, unlike the From/To pair that bounds a comparison.
                     The version being viewed is skipped: writing it back would only commit identical content. -->
                <xsl:if test="$writable and not(@rdf:about = $current-memento)">
                    <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm btn-restore" value="{@rdf:about}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'restore', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </xsl:if>
            </td>
        </tr>
    </xsl:template>

</xsl:stylesheet>
