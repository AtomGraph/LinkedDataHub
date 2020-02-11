<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
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
    
    <!-- CSS -->
    
    <xsl:template use-when="system-property('xsl:product-name') = 'SAXON'" match="*[rdf:type/@rdf:resource][$ac:sitemap][(rdf:type/@rdf:resource, apl:superClasses(rdf:type/@rdf:resource, $ac:sitemap)) = '&dh;Container']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'container-logo')"/>
    </xsl:template>

    <xsl:template use-when="system-property('xsl:product-name') = 'SAXON'" match="*[rdf:type/@rdf:resource][$ac:sitemap][(rdf:type/@rdf:resource, apl:superClasses(rdf:type/@rdf:resource, $ac:sitemap)) = '&dh;Item']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'item-logo')"/>
    </xsl:template>

    <xsl:template use-when="system-property('xsl:product-name') = 'Saxon-CE'" match="*[rdf:type/@rdf:resource = (resolve-uri('ns/default#Container', $ldt:base), concat($ldt:ontology, 'Container'))]" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'container-logo')"/>
    </xsl:template>

    <xsl:template use-when="system-property('xsl:product-name') = 'Saxon-CE'" match="*[rdf:type/@rdf:resource = (resolve-uri('ns/default#Item', $ldt:base), concat($ldt:ontology, 'Item'))]" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'item-logo')"/>
    </xsl:template>

    <!-- do not show text instead for logo icon for "things" -->
    <xsl:template match="*[foaf:isPrimaryTopicOf]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="$class"/>
    </xsl:template>

    <!-- BLOCK MODE -->

    <!-- TO-DO: move to Web-Client -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Block">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Header"/>

            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
        </div>
    </xsl:template>

    <!-- TO-DO: move to Web-Client -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:PropertyList">
        <xsl:variable name="properties" as="element()*">
            <xsl:apply-templates select="*" mode="#current">
                <xsl:sort select="ac:property-label(.)" data-type="text" order="ascending" /> <!-- lang="{$ldt:lang}" -->
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:if test="$properties">
            <dl class="dl-horizontal">
                <xsl:copy-of select="$properties"/>
            </dl>
        </xsl:if>
    </xsl:template>

    <!-- TO-DO: move to Web-Client -->
    <!-- inline blank node resource if there is only one property except foaf:primaryTopic having it as object -->
    <xsl:template match="@rdf:nodeID[key('resources', .)][count(key('predicates-by-object', .)[not(self::foaf:primaryTopic)]) = 1]" mode="bs2:Block" priority="2">
        <xsl:param name="inline" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:choose>
            <xsl:when test="$inline">
                <xsl:apply-templates select="key('resources', .)" mode="#current">
                    <xsl:with-param name="display" select="$inline" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- TO-DO: move to Web-Client -->
    <!-- hide inlined blank node resources from the main block flow -->
    <xsl:template match="*[*][key('resources', @rdf:nodeID)][count(key('predicates-by-object', @rdf:nodeID)[not(self::foaf:primaryTopic)]) = 1]" mode="bs2:Block" priority="1">
        <xsl:param name="display" select="false()" as="xs:boolean" tunnel="yes"/>
        
        <xsl:if test="$display">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
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