<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
exclude-result-prefixes="#all">
    
    <!-- FORM CONTROL MODE -->
    
    <!-- override the value of ldh:chartType with a dropdown of ac:Chart subclasses (currently in the LDH vocabulary) -->
    <xsl:template match="ldh:chartType/@rdf:resource | ldh:chartType/@rdf:nodeID" mode="ac:FormControl">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="value" select="." as="xs:string"/>

        <xsl:variable name="chart-types" select="key('resources-by-subclass', '&ac;Chart', document(ac:document-uri('&ldh;')))" as="element()*"/>
        <xsl:apply-templates select="." mode="ac:SelectShell">
            <xsl:with-param name="select" as="item()*">
        <select name="ou" id="{generate-id()}">
            <xsl:for-each select="$chart-types">
                <xsl:sort select="ac:label(.)" lang="{ac:langs()[1]}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about = $value"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>
            </xsl:with-param>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>