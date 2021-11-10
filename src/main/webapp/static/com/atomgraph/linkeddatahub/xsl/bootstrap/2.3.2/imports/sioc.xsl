<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <!-- override the value of sioc:has_parent/sioc:has_constructor in constructor with current URI -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID][$ac:forClass]/sioc:has_parent/@rdf:nodeID | *[@rdf:about or @rdf:nodeID][$ac:forClass]/sioc:has_container/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="container" select="ac:uri()" as="xs:anyURI"/>

        <span>
            <xsl:apply-templates select="key('resources', $container, document($container))" mode="apl:Typeahead"/>
        </span>
        
        <xsl:text> </xsl:text>

        <!-- forClass input is used by typeahead's FILTER (?Type IN ()) in client.xsl. Not the same as $ac:forClass! -->
        <xsl:variable name="forClass" select="../../rdf:type/@rdf:resource" as="xs:anyURI?"/>
        <xsl:choose>
            <xsl:when test="not($forClass = '&rdfs;Resource') and doc-available(ac:document-uri($forClass))">
                <xsl:variable name="subclasses" select="apl:listSubClasses($forClass, false(), $apl:ontology)" as="attribute()*"/>
                <!-- add subclasses as forClass -->
                <xsl:for-each select="distinct-values($subclasses)[not(. = $forClass)]">
                    <input type="hidden" class="forClass" value="{.}"/>
                </xsl:for-each>
                <!-- bs2:Constructor sets forClass -->
                <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                    <xsl:with-param name="modal-form" select="true()"/>
                    <xsl:with-param name="subclasses" select="$subclasses"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <input type="hidden" class="forClass" value="{$forClass}"/> <!-- required by ?Type FILTER -->
            </xsl:otherwise>
        </xsl:choose>

        <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="type-label" select="$type-label"/>
            <xsl:with-param name="forClass" select="$forClass"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="sioc:email/@rdf:*"  mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="'text'"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="value" select="substring-after(., 'mailto:')"/>
        </xsl:call-template>
        
        <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="type-label" select="$type-label"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="sioc:email/@rdf:*" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:if test="not($type = 'hidden') and $type-label">
            <span class="help-inline">Literal</span>
        </xsl:if>
    </xsl:template>

    <xsl:template match="sioc:content[@rdf:parseType = 'Literal']" mode="bs2:PropertyList"/>

    <!-- do not show the content input if its document is the topic of another document -->
    <xsl:template match="sioc:content[@rdf:parseType = 'Literal'][key('resources', ../foaf:isPrimaryTopicOf/@rdf:nodeID)]" mode="bs2:FormControl"/>
    
</xsl:stylesheet>