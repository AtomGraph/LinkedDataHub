<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema">

    <xsl:param name="json" as="xs:string?"/>
    <xsl:param name="request-uri" as="xs:string?"/>

    <xsl:template name="xsl:initial-template">
        <rdf:RDF>
            <rdf:Description rdf:about="{$request-uri}">
                <rdf:value><xsl:value-of select="$json"/></rdf:value>
            </rdf:Description>
        </rdf:RDF>
    </xsl:template>

</xsl:stylesheet>
