<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY skos   "http://www.w3.org/2004/02/skos/core#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:foaf="&foaf;"
xmlns:skos="&skos;"
xmlns:srx="&srx;"
exclude-result-prefixes="#all">

    <!-- This one stylesheet is composed into BOTH the server and the client tree, so anything that
         reaches client/tree.xsl - the disclosure handlers, the children query, the fetch - is declared
         use-when Saxon-JS. Without the guard the server compile fails on XTSE0650/XPST0017 and the
         platform falls back to a stylesheet carrying no package rules at all, so the package stops
         working entirely rather than degrading. The emitter is deliberately NOT guarded: ldh:TreeNode
         lives in the shared trunk precisely so the tree is in the server's first paint, which is the
         only paint a directly loaded URL gets.

         the hierarchy predicates render as the concept tree, not as statement rows -->
    <xsl:template match="skos:narrower | skos:broader | skos:related | skos:member" mode="ac:PropertyEditor"/>

    <!-- A concept can always be expanded. Whether it has children is one query away and this template
         renders without one, so offering the disclosure and letting it resolve to an empty list beats
         either blocking the render or hiding a control the node may well need: the alternative is a
         tree whose leaves are wrong whenever narrower is asserted only on the child. -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&skos;Concept']" mode="ldh:TreeNode" priority="1">
        <xsl:next-match>
            <xsl:with-param name="expandable" select="true()"/>
        </xsl:next-match>
    </xsl:template>


    <!-- A taxonomy is read alongside its content, so the tree fills the platform's ldh:ContentColumn
         slot and the content body lays itself out in two columns. The card, its stickiness and the
         column width come from the design system's ontology-editor layout (.ldh-onto-list), already
         vendored in app.css; the grid is the platform's, keyed on this slot being filled.

         Anchored on the primary topic of THIS document, not on any SKOS resource in the graph: a
         container listing concept documents describes every child's topic too, and matching those
         would hang a tree off every such listing, rooted at whichever concept happened to come first.

         Not guarded by use-when: ldh:TreeNode lives in the shared trunk precisely so the tree is in
         the server's first paint, which is the only paint a directly loaded URL gets. -->
    <xsl:template match="rdf:RDF[key('resources', key('resources', ac:absolute-path(ldh:base-uri(.)))/foaf:primaryTopic/@rdf:resource)/rdf:type/@rdf:resource = ('&skos;ConceptScheme', '&skos;Concept')]" mode="ldh:ContentColumn">
        <xsl:variable name="topic" select="key('resources', key('resources', ac:absolute-path(ldh:base-uri(.)))/foaf:primaryTopic/@rdf:resource)" as="element()*"/>
        <!-- the root of a scheme's tree expands over hasTopConcept/topConceptOf, a concept's over broader/narrower;
             the class is what the ldh:TreeChildrenLoad rules below read at click time -->
        <xsl:variable name="scheme-root" select="$topic/rdf:type/@rdf:resource = '&skos;ConceptScheme'" as="xs:boolean"/>

        <div class="ldh-onto-list">
            <ul class="ldh-tree concept-tree{if ($scheme-root) then ' scheme-root' else ''}">
                <xsl:apply-templates select="$topic[1]" mode="ldh:TreeNode">
                    <xsl:with-param name="expandable" select="true()"/>
                </xsl:apply-templates>
            </ul>
        </div>
    </xsl:template>

    <!-- SKOS puts the hierarchy link on whichever end the modeller chose, and both are in use in the
         wild, so every relation below is given from both directions and client/tree.xsl unions them.

         Which relation applies is a question of depth, not of class: the node at the root of this tree
         is the scheme, whose children are its top concepts; every node below it is a concept, whose
         children are narrower concepts. count(ancestor::li) tells them apart without a marker class
         that the generic emitter would have to know how to attach. -->
    <xsl:template match="button[ancestor::ul[contains-token(@class, 'scheme-root')]][count(ancestor::li) = 1]" mode="ldh:TreeChildrenLoad" priority="1" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:call-template name="ldh:TreeChildrenFetch">
            <xsl:with-param name="container" select="$container"/>
            <xsl:with-param name="uri" select="$uri"/>
            <xsl:with-param name="query" select="ldh:tree-children-query($uri, xs:anyURI('&skos;topConceptOf'), xs:anyURI('&skos;hasTopConcept'))"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="button[ancestor::ul[contains-token(@class, 'concept-tree')]]" mode="ldh:TreeChildrenLoad" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:call-template name="ldh:TreeChildrenFetch">
            <xsl:with-param name="container" select="$container"/>
            <xsl:with-param name="uri" select="$uri"/>
            <xsl:with-param name="query" select="ldh:tree-children-query($uri, xs:anyURI('&skos;broader'), xs:anyURI('&skos;narrower'))"/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
