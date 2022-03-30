<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="2.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <!-- override the value of ac:mode with a dropdown of ac:Mode instances -->
    <xsl:template match="ac:mode/@rdf:resource | ac:mode/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:variable name="value" select="." as="xs:string"/>

        <xsl:variable name="modes" select="key('resources-by-type', '&ac;Mode', document(ac:document-uri('&ac;')))" as="element()*"/>
        <select name="ou" id="{generate-id()}">
            <option>
                <!-- an empty option in case on ac:mode is specified -->
            </option>
            
            <xsl:for-each select="$modes">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about = $value"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>

        <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
    </xsl:template>
    
</xsl:stylesheet>