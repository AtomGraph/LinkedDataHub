<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:geo="&geo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <!-- HEADER MODE -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>

            <xsl:apply-templates select="." mode="bs2:Image"/>
            
            <xsl:apply-templates select="." mode="bs2:Actions"/>

            <h2>
                <xsl:apply-templates select="." mode="apl:logo"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="xhtml:Anchor"/>
            </h2>

            <p>
                <xsl:apply-templates select="." mode="ac:description"/>
            </p>

            <xsl:apply-templates select="." mode="bs2:TypeList"/>

            <!--
            <xsl:if test="@rdf:nodeID">
            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
            </xsl:if>
            -->
        </div>
    </xsl:template>
    
    <!-- IMAGE -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Image">
        <xsl:variable name="prelim-images" as="item()*">
            <xsl:apply-templates mode="ac:image"/>
        </xsl:variable>
        <xsl:variable name="images" select="$prelim-images/self::*" as="element()*"/>

        <xsl:if test="$images">
            <div class="carousel slide">
                <div class="carousel-inner">
                    <xsl:for-each select="$images">
                        <div class="item">
                            <xsl:if test="position() = 1">
                                <xsl:attribute name="class">active item</xsl:attribute>
                            </xsl:if>
                            <xsl:copy-of select="."/>
                        </div>
                    </xsl:for-each>
                    <a class="carousel-control left" onclick="$(this).parents('.carousel').carousel('prev');">&#8249;</a>
                    <a class="carousel-control right" onclick="$(this).parents('.carousel').carousel('next');">&#8250;</a>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
        
    <!-- ACTIONS -->
    
    <xsl:template match="*" mode="bs2:Actions"/>
    
    <!-- TIMESTAMP -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Timestamp">
        <xsl:apply-templates select="dct:created/text()"/>
        <xsl:apply-templates select="dct:modified/text()"/>
    </xsl:template>
    
    <!-- TYPE LIST -->

    <xsl:template match="*[sioc:has_parent] | *[sioc:has_container]" mode="bs2:TypeList" priority="0.8"/>

    <xsl:template match="*[@rdf:about or @rdf:nodeID][rdf:type/@rdf:resource]" mode="bs2:TypeList">
        <ul class="inline">
            <xsl:for-each select="rdf:type/@rdf:resource">
                <xsl:sort select="ac:object-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:sort select="ac:object-label(.)" order="ascending" use-when="system-property('xsl:product-name') = 'Saxon-CE'"/>

                <xsl:choose use-when="system-property('xsl:product-name') = 'SAXON'">
                    <xsl:when test="doc-available(ac:document-uri(.))">
                        <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="bs2:TypeListItem"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:value-of select="." use-when="system-property('xsl:product-name') = 'Saxon-CE'"/>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
</xsl:stylesheet>