<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lmod   "https://w3id.org/atomgraph/linkeddatahub/admin/modules/domain#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:foaf="&foaf;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="../layout.xsl"/>
    <xsl:include href="acl/layout.xsl"/>
    <xsl:include href="sitemap/layout.xsl"/>

    <xsl:template match="rdf:RDF" mode="bs2:ActionBarLeft">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span2'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:sequence select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:sequence select="$class"/></xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Create">
                <xsl:with-param name="class" select="'btn-group pull-left'"/>
                <xsl:with-param name="classes" select="key('resources', ('&adm;Ontology', '&adm;Authorization', '&adm;Person', '&adm;PublicKey', '&adm;UserAccount', '&adm;Group'), document(ac:document-uri('&adm;')))"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[$acl:Agent]" mode="bs2:Create" priority="1">
        <xsl:param name="classes" as="element()*"/>

        <div class="btn-group pull-left">
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document('../translations.rdf')))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <xsl:call-template name="bs2:ConstructorList">
                <xsl:with-param name="ontology" select="key('resources', $apl:client//ldt:ontology/@rdf:resource, document(ac:document-uri($apl:client//ldt:ontology/@rdf:resource)))"/>
                <xsl:with-param name="classes" select="$classes"/>
                <xsl:with-param name="classes" select="()"/>
            </xsl:call-template>
        </div>
    </xsl:template>
    
    <!-- unlike in the end-user app, only show classes from top-level ontology - don't recurse into imports -->
    <xsl:template name="bs2:ConstructorList">
        <xsl:param name="ontology" as="element()"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="visited-classes" as="element()*"/>

        <ul class="dropdown-menu">
            <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                <xsl:sort select="ac:label(.)"/>
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    
    <!-- allow subject editing in admin EditMode -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:FormControl">
        <xsl:apply-imports>
            <xsl:with-param name="show-subject" select="true()" tunnel="yes"/>
        </xsl:apply-imports>
    </xsl:template>
        
    <!-- FORM CONTROL -->
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID][$ac:forClass]/sioc:has_parent/@rdf:nodeID | *[@rdf:about or @rdf:nodeID][$ac:forClass]/sioc:has_container/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="class-containers" as="map(xs:string, xs:anyURI)">
            <xsl:map>
                <xsl:map-entry key="'&adm;Ontology'" select="resolve-uri('model/ontologies/', $apl:base)"/>
                <xsl:map-entry key="'&adm;Authorization'" select="resolve-uri('acl/authorizations/', $apl:base)"/>
                <xsl:map-entry key="'&adm;Person'" select="resolve-uri('acl/agents/', $apl:base)"/>
                <xsl:map-entry key="'&adm;PublicKey'" select="resolve-uri('acl/public-keys/', $apl:base)"/>
                <xsl:map-entry key="'&adm;UserAccount'" select="resolve-uri('acl/users/', $apl:base)"/>
                <xsl:map-entry key="'&adm;Group'" select="resolve-uri('acl/groups/', $apl:base)"/>
            </xsl:map>
        </xsl:param>
        
        <xsl:next-match>
            <xsl:with-param name="class-containers" select="$class-containers"/>
        </xsl:next-match>
    </xsl:template>
    
</xsl:stylesheet>