<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:nfo="&nfo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:preserve-space elements="nfo:fileName"/>
        
    <xsl:template match="nfo:fileName/text() | *[@rdf:*[local-name() = 'nodeID']]/nfo:fileName/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept" as="xs:string?"/>
        <xsl:param name="container" select="resolve-uri('uploads/', $apl:base)" as="xs:anyURI"/> <!-- TO-DO: get container URI from the ns:ItemOfFileContainer restriction -->

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="'file'"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:call-template>
        
        <span class="help-inline">Upload</span>
    </xsl:template>

    <xsl:template match="nfo:fileName/@rdf:datatype" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:next-match>
    </xsl:template>
     
</xsl:stylesheet>