<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:sp="&sp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <xsl:template match="sp:text/text() | *[@rdf:*[local-name() = 'nodeID']]/sp:text/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <textarea name="ol" id="{generate-id()}" class="sp:text" rows="10" style="font-family: monospace;">
            <xsl:if test="self::text()">
                <xsl:value-of select="."/>
            </xsl:if>
        </textarea>

        <xsl:if test="$type-label">
            <xsl:choose>
                <xsl:when test="../@rdf:datatype">
                    <xsl:apply-templates select="../@rdf:datatype"/>
                </xsl:when>
                <xsl:otherwise>
                    <span class="help-inline">Literal</span>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/@rdf:datatype" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:next-match>
    </xsl:template>
    
</xsl:stylesheet>