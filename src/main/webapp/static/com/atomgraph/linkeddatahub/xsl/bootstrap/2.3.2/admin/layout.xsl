<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lmod   "https://w3id.org/atomgraph/linkeddatahub/admin/modules/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:foaf="&foaf;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="../layout.xsl"/>
    <xsl:include href="acl/layout.xsl"/>
    <xsl:include href="sitemap/layout.xsl"/>

<!--    <xsl:template match="rdf:RDF[$acl:Agent]" mode="bs2:Create" priority="1">
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

            <xsl:variable name="this" select="@rdf:about"/>
            <ul class="dropdown-menu">
                <xsl:call-template name="bs2:ConstructorList">
                    <xsl:with-param name="ontology" select="xs:anyURI($apl:client//ldt:ontology/@rdf:resource)"/>
                </xsl:call-template>
            </ul>
        </div>
    </xsl:template>-->
    
    <!-- unlike in the end-user app, only show classes from top-level ontology - don't recurse into imports -->
    <xsl:template name="bs2:ConstructorList">
        <xsl:param name="ontology" as="xs:anyURI"/>
        <xsl:param name="visited-classes" as="element()*"/>

        <!-- check if ontology document is available -->
        <xsl:if test="doc-available(ac:document-uri($ontology))">
            <xsl:variable name="ont-doc" select="document(ac:document-uri($ontology))" as="document-node()"/>
            <xsl:variable name="classes" select="$ont-doc/rdf:RDF/*[@rdf:about][rdfs:isDefinedBy/@rdf:resource = $ontology][spin:constructor or (rdfs:subClassOf and apl:listSuperClasses(@rdf:about)/../../spin:constructor)]" as="element()*"/>
            <xsl:apply-templates select="$classes[let $about := @rdf:about return not(@rdf:about = ($classes)[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)][not((@rdf:about, apl:listSuperClasses(@rdf:about)) = ('&dh;Document', '&ldt;Parameter'))]" mode="bs2:ConstructorListItem">
                <xsl:sort select="ac:label(.)"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <!-- allow subject editing in admin EditMode -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:FormControl">
        <xsl:apply-imports>
            <xsl:with-param name="show-subject" select="true()" tunnel="yes"/>
        </xsl:apply-imports>
    </xsl:template>
        
</xsl:stylesheet>