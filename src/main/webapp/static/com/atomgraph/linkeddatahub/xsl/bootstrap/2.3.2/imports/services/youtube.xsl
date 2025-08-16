<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY schema "https://schema.org/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:fn="http://www.w3.org/2005/xpath-functions"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:schema="&schema;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->
    
    <xsl:template match="*[contains(@rdf:about, 'youtube.com/watch') or contains(@rdf:about, 'youtu.be/')][rdf:type/@rdf:resource = '&schema;VideoObject']">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Header"/>
        </div>
    </xsl:template>
    
    <xsl:template match="*[contains(@rdf:about, 'youtube.com/watch') or contains(@rdf:about, 'youtu.be/')][rdf:type/@rdf:resource = '&schema;VideoObject']" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>
        <xsl:variable name="video-id" select="analyze-string(@rdf:about, '^.*(?:youtube\.com/(?:watch\?v=|embed/)|youtu\.be/)([^&amp;?]+).*$')//fn:group[@nr='1']/text()" as="xs:string"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>

            <div class="well-small text-center">
                <iframe width="560" height="315" 
                        src="https://www.youtube.com/embed/{$video-id}" 
                        frameborder="0" 
                        allowfullscreen="allowfullscreen">
                </iframe>
            </div>
            
            <xsl:apply-templates select="." mode="bs2:Actions"/>

            <h2>
                <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="xhtml:Anchor">
                    <xsl:with-param name="class" as="xs:string?">
                        <xsl:apply-templates select="." mode="ldh:logo"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </h2>

            <xsl:where-populated>
                <p>
                    <xsl:apply-templates select="." mode="ac:description"/>
                </p>
            </xsl:where-populated>

            <xsl:apply-templates select="." mode="bs2:TypeList"/>
        </div>
    </xsl:template>
    
</xsl:stylesheet>
