<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rdf     "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY memento "http://mementoweb.org/ns#">
    <!ENTITY dct     "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdf="&rdf;"
xmlns:memento="&memento;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
>

    <!-- Memento (RFC 7089) version history rendering -->

    <!-- a version entry: datetime links to the memento (?version= URI); opens in a new tab so the CSR navigation (which drops query params) is bypassed -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&memento;Memento']" mode="bs2:MementoList">
        <li>
            <a href="{@rdf:about}" target="_blank">
                <xsl:apply-templates select="memento:mementoDatetime/text()"/>
            </a>
            <xsl:if test="dct:creator/@rdf:resource">
                <span class="pull-right">
                    <xsl:apply-templates select="dct:creator/@rdf:resource"/>
                </span>
            </xsl:if>
        </li>
    </xsl:template>

</xsl:stylesheet>
