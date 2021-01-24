<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="../layout.xsl"/>
    <xsl:include href="acl/layout.xsl"/>
    <xsl:include href="sitemap/layout.xsl"/>

    <!-- allow subject editing in admin EditMode -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:FormControl">
        <xsl:apply-imports>
            <xsl:with-param name="show-subject" select="true()" tunnel="yes"/>
        </xsl:apply-imports>
    </xsl:template>
        
</xsl:stylesheet>