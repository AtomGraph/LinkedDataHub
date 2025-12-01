<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY skos   "http://www.w3.org/2004/02/skos/core#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="2.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:skos="&skos;"
xmlns:srx="&srx;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:param name="ldh:base" as="xs:anyURI" static="yes"/>

    <xsl:import _href="{resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl', $ldh:base)}"/>

    <xsl:param name="foaf:Agent" as="document-node()?"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="xhtml:Style">
        <xsl:param name="load-wymeditor" select="exists($foaf:Agent//@rdf:about)" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="true()" as="xs:boolean"/>

        <xsl:apply-imports/>

        <!-- inject custom Bootstrap theme that overrides the default one -->
        <link href="{resolve-uri('static/com/linkeddatahub/demo/skos/css/bootstrap.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        <!-- re-apply LinkedDataHub's Bootstrap customizations -->
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/bootstrap.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>

        <xsl:if test="$load-wymeditor">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/skins/default/skin.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        </xsl:if>
        <xsl:if test="$load-yasqe">
            <link href="{resolve-uri('static/css/yasqe.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="xhtml:Style">
        <xsl:next-match/>

        <link href="{resolve-uri('static/com/linkeddatahub/demo/skos/css/bootstrap.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
    </xsl:template>

    <xsl:template match="skos:narrower | skos:broader | skos:related | skos:member" mode="bs2:PropertyList"/>
    
</xsl:stylesheet>