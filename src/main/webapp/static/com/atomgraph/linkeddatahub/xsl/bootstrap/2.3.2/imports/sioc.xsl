<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY gp     "http://graphity.org/gp#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">    
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:ac="&ac;"
xmlns:gp="&gp;"
xmlns:rdf="&rdf;"
xmlns:sioc="&sioc;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <!--
    <xsl:template match="rdf:type[@rdf:resource = ('&sioc;Container', '&sioc;Item')]" mode="bs2:FormControl">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>        
    </xsl:template>
    -->
    
    <!--
    <xsl:template match="sioc:has_container/@rdf:nodeID | sioc:has_parent/@rdf:nodeID | sioc:has_space/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>

        <xsl:variable name="bnode" select="key('resources', .)[not(@rdf:nodeID = current()/../../@rdf:nodeID)][not(*/@rdf:nodeID = current()/../../@rdf:nodeID)]"/>
        <xsl:choose>
            <xsl:when test="$bnode">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="$bnode" mode="#current"/>
                <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                </xsl:call-template>

                <xsl:if test="not($type = 'hidden')">
                    <span class="help-inline">Resource</span>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    -->
        
    <xsl:template match="sioc:email/@rdf:*"  mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="'text'"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="value" select="substring-after(., 'mailto:')"/>
        </xsl:call-template>
        <span class="help-inline">Literal</span>
    </xsl:template>

    <xsl:template match="sioc:content[@rdf:parseType = 'Literal']" mode="bs2:PropertyList"/>

    <!-- do not show the content input if its document is the topic of another document -->
    <xsl:template match="sioc:content[@rdf:parseType = 'Literal'][key('resources', ../foaf:isPrimaryTopicOf/@rdf:nodeID)]" mode="bs2:FormControl"/>
    
</xsl:stylesheet>