<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:ldt="&ldt;"
xmlns:lapp="&lapp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <!-- show "Actions" dropdown with Install/Uninstall options for packages -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&lapp;Package']" mode="bs2:Actions">
        <xsl:variable name="admin-origin" select="(key('resources', $lapp:Application//*[lapp:origin/@rdf:resource = $lapp:origin]/lapp:adminApplication/(@rdf:resource, @rdf:nodeID), $lapp:Application)/lapp:origin/@rdf:resource, $ldt:base)[1]" as="xs:anyURI"/>

        <div class="btn-group pull-right">
            <button type="button" class="btn dropdown-toggle">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'actions', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li>
                    <form action="{resolve-uri('packages/install', $admin-origin)}" method="post">
                        <input type="hidden" name="package-uri" value="{@rdf:about}"/>
                        <button class="btn btn-primary" type="submit">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'install', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </form>
                </li>
                <li>
                    <form action="{resolve-uri('packages/uninstall', $admin-origin)}" method="post">
                        <input type="hidden" name="package-uri" value="{@rdf:about}"/>
                        <button class="btn btn-danger" type="submit">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'uninstall', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </form>
                </li>
            </ul>
        </div>

        <xsl:next-match/>
    </xsl:template>

</xsl:stylesheet>
