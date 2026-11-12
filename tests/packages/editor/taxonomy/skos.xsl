<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY skos   "http://www.w3.org/2004/02/skos/core#">
    <!ENTITY taxonomy "https://packages.linkeddatahub.com/editor/taxonomy/ns/#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:foaf="&foaf;"
xmlns:skos="&skos;"
xmlns:taxonomy="&taxonomy;"
exclude-result-prefixes="#all">

    <!-- This one stylesheet is composed into BOTH the server and the client tree, and it RENDERS and
         nothing else: every rule here returns markup or data in an open mode, and the platform does
         whatever moves - the children fetch, the climb to the scheme, the descent, the marking, the
         scroll (client/tree.xsl). Nothing is ixsl:, nothing reads, nothing needs a product guard, and
         the server paints the whole tree root on a direct load. The package's own names are in its own
         namespace (taxonomy:), as the package contract asks (PackageContract).

         The hierarchy predicates render as the concept tree, not as statement rows -->
    <xsl:template match="skos:narrower | skos:broader | skos:related | skos:member" mode="ac:PropertyEditor"/>

    <!-- Every row of this tree navigates in ReadMode explicitly, because the tree itself only renders in
         ReadMode: a concept document that has content blocks resolves to ContentMode by default, so a row
         linking to its bare URI is a link out of the very widget the reader is navigating with - click a
         sibling and the tree disappears. Naming the mode in the link keeps the reading surface closed
         over its own navigation, and leaves the URL the single source of truth for the mode.

         One function rather than the expression at both call sites - the root, and every other node
         through the override below - so the two cannot drift into linking differently. -->
    <xsl:function name="taxonomy:conceptree-href" as="xs:anyURI">
        <xsl:param name="resource" as="element()"/>

        <xsl:sequence select="ldh:href(ac:document-uri($resource/@rdf:about), ldh:build-query(xs:anyURI('&ac;ReadMode')), ac:fragment-id($resource/@rdf:about))"/>
    </xsl:function>

    <!-- A concept can always be expanded. Whether it has children is one query away and this template
         renders without one, so offering the disclosure and letting it resolve to an empty list beats
         either blocking the render or hiding a control the node may well need: the alternative is a
         tree whose leaves are wrong whenever narrower is asserted only on the child.

         Matched on the type, so it covers every node a children fetch brings back - those responses are
         CONSTRUCTs that carry rdf:type - but NOT the scheme at the root, whose description on a concept
         page comes from $object-metadata, a literals-only CONSTRUCT. The root is given its href at the
         call site instead. -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&skos;Concept']" mode="ldh:TreeNode" priority="1">
        <xsl:next-match>
            <xsl:with-param name="expandable" select="true()"/>
            <xsl:with-param name="href" select="taxonomy:conceptree-href(.)"/>
        </xsl:next-match>
    </xsl:template>

    <!-- A taxonomy is read alongside its content, so the tree fills the platform's ldh:ContentColumn
         slot and the content body lays itself out in two columns. The card, its stickiness and the
         column width come from the design system's ontology-editor layout (.ldh-onto-list), already
         vendored in app.css; the grid is the platform's, keyed on this slot being filled.

         The tree is rooted at the SCHEME, never at the document's own topic. A tree rooted at the
         concept you are already looking at shows one node and tells you nothing: what a taxonomy tree
         is for is placing that concept among the others, so it has to start where the taxonomy starts.

         On a scheme document the topic IS the root. On a concept document the scheme is named by
         skos:inScheme, which is already in the rendered RDF, and its label comes from the platform's
         $object-metadata - the same label-only CONSTRUCT that renders "Drinks" as the link text in the
         property list beside this tree. So the root node costs no request at all. That tunnel
         parameter does reach this mode: it is set once per render (layout.xsl server-side,
         client.xsl per pane) and flows down through ldh:ContentBody.

         Falls back to the topic when no scheme resolves - an unplaced concept still gets a tree of
         itself rather than an empty card.

         Anchored on the primary topic of THIS document, not on any SKOS resource in the graph: a
         container listing concept documents describes every child's topic too, and matching those
         would hang a tree off every such listing, rooted at whichever concept happened to come first.

         Not guarded by use-when: ldh:TreeNode lives in the shared trunk precisely so the tree is in
         the server's first paint, which is the only paint a directly loaded URL gets. -->
    <xsl:template match="rdf:RDF[key('resources', key('resources', ac:absolute-path(ldh:base-uri(.)))/foaf:primaryTopic/@rdf:resource)/rdf:type/@rdf:resource = ('&skos;ConceptScheme', '&skos;Concept')]" mode="ldh:ContentColumn">
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:variable name="topic" select="key('resources', key('resources', ac:absolute-path(ldh:base-uri(.)))/foaf:primaryTopic/@rdf:resource)" as="element()*"/>
        <xsl:variable name="scheme-uri" select="$topic/skos:inScheme/@rdf:resource" as="attribute()*"/>
        <!-- described in this document (a scheme page), else in the label metadata (a concept page) -->
        <xsl:variable name="root" select="(
            $topic[rdf:type/@rdf:resource = '&skos;ConceptScheme'],
            key('resources', $scheme-uri),
            $object-metadata!key('resources', $scheme-uri, .),
            $topic)[1]" as="element()?"/>

        <!-- ReadMode only. The tree is for reading a concept in its place among the others, and the
             other document modes have a body it does not belong beside: ContentMode is an authoring
             surface for the document's own content blocks, and the Map, Chart and Graph canvases take
             the whole body - ldh.css even zeroes its padding and drops its max-width for them, which a
             two-column grid would fight. Rendering the tree there put it next to an empty authoring
             body, which is what prompted this. ac:mode() always resolves to a concrete mode, so the
             test can be positive: ?mode= when given, else ContentMode for a document that has content
             blocks, else ReadMode. -->
        <xsl:if test="$root and $mode = '&ac;ReadMode'">
            <div class="ldh-onto-list">
                <!-- headed like the drawer's document tree, in the design system's in-card vocabulary
                     (.ldh-onto-group-h) rather than the drawer's .sb-heading: the eyebrow treatment is
                     the same, the owning surface is not. The heading names the KIND, since the tree's
                     root node already carries the scheme's name. -->
                <div class="ldh-onto-group">
                    <h3 class="ldh-onto-group-h">
                        <xsl:apply-templates select="key('resources', 'concept-tree', ldh:translations())" mode="ac:label"/>
                    </h3>

                    <!-- the concept being viewed, which the platform opens the tree down to once the tree
                         is in the DOM (data-tree-reveal, client/tree.xsl): it climbs to the scheme over the
                         relation ldh:TreeParentsLoad names below, descends, marks the concept and scrolls to
                         it. Absent when the topic IS the scheme, which is already the root. -->
                    <ul class="ldh-tree concept-tree">
                        <xsl:if test="not($topic/rdf:type/@rdf:resource = '&skos;ConceptScheme')">
                            <xsl:attribute name="data-tree-reveal" select="$topic[1]/@rdf:about"/>
                        </xsl:if>
                        <xsl:apply-templates select="$root" mode="ldh:TreeNode">
                            <xsl:with-param name="expandable" select="true()"/>
                            <xsl:with-param name="href" select="taxonomy:conceptree-href($root)"/>
                        </xsl:apply-templates>
                    </ul>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- THE RELATIONS THE TREE FOLLOWS

         SKOS puts the hierarchy link on whichever end the modeller chose, and both are in use in the
         wild, so every relation below is given from both directions and client/tree.xsl unions them:
         parent-properties are asserted on the child (skos:broader, skos:topConceptOf), child-properties
         on the parent (skos:narrower, skos:hasTopConcept). The platform builds the children query from
         them, one GRAPH per hop because every concept is its own document.

         Which relation applies is a question of depth alone: the root is always the scheme, whose
         children are its top concepts, and every node below it is a concept, whose children are
         narrower concepts. count(ancestor::li) tells them apart - no marker class, which is why the
         scheme-root token this used to carry is gone: with the root always a scheme it distinguished
         nothing. -->
    <xsl:template match="button[ancestor::ul[contains-token(@class, 'concept-tree')]][count(ancestor::li) = 1]" mode="ldh:TreeChildrenLoad" priority="1" as="map(*)">
        <xsl:sequence select="map{ 'parent-properties': xs:anyURI('&skos;topConceptOf'), 'child-properties': xs:anyURI('&skos;hasTopConcept') }"/>
    </xsl:template>

    <xsl:template match="button[ancestor::ul[contains-token(@class, 'concept-tree')]]" mode="ldh:TreeChildrenLoad" as="map(*)">
        <xsl:sequence select="map{ 'parent-properties': xs:anyURI('&skos;broader'), 'child-properties': xs:anyURI('&skos;narrower') }"/>
    </xsl:template>

    <!-- The relation the climb follows up from the open concept, one hop per request, to find the
         ancestors the descent then opens: the concept hierarchy only. The walk stops itself at the top
         concept, because the link from there to the scheme is topConceptOf/hasTopConcept rather than
         broader/narrower, and that is the right place to stop: the scheme is the tree's root node and
         the descent starts there, so it never belongs to the ancestor set. -->
    <xsl:template match="ul[contains-token(@class, 'concept-tree')]" mode="ldh:TreeParentsLoad" as="map(*)">
        <xsl:sequence select="map{ 'parent-properties': xs:anyURI('&skos;broader'), 'child-properties': xs:anyURI('&skos;narrower') }"/>
    </xsl:template>

</xsl:stylesheet>
