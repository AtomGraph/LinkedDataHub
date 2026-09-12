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
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
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
xmlns:sd="&sd;"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
extension-element-prefixes="ixsl"
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
                <!-- the concept being viewed, stamped so the reveal has its target without re-deriving
                     it from the page; absent when the topic IS the scheme, which is already the root -->
                <ul class="ldh-tree concept-tree">
                    <xsl:if test="not($topic/rdf:type/@rdf:resource = '&skos;ConceptScheme')">
                        <xsl:attribute name="data-concept" select="$topic[1]/@rdf:about"/>
                    </xsl:if>
                    <xsl:apply-templates select="$root" mode="ldh:TreeNode">
                        <xsl:with-param name="expandable" select="true()"/>
                    </xsl:apply-templates>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- ===================== REVEALING THE OPEN CONCEPT =====================

         The tree roots at the scheme, so on a concept page it must open the path down to that concept
         or the reader is left at the top of a taxonomy with no idea where they are.

         Triggered from ldh:RenderRow, which the platform already applies to every direct child of
         .content-body after the pane is in the DOM - on a direct load AND on a client-side navigation
         alike. That is the whole reason no new platform hook was needed, and why there is one
         implementation rather than a synchronous server walk beside an asynchronous client one: this
         mode is the only place both paths meet after the markup exists.

         The mode's contract is a FACTORY, not work: it is evaluated inside a non-updating variable
         binding and the factories are invoked later inside ixsl:promise, which is also what gives
         ixsl:http-request the active promise it requires. -->
    <xsl:template match="div[contains-token(@class, 'ldh-content-aside')][descendant::ul[contains-token(@class, 'concept-tree')][@data-concept]]" mode="ldh:RenderRow" as="(function(item()?) as map(*))*" priority="2" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <!-- descendant, not child: the platform owns the .ldh-content-aside wrapper and the package puts
             its own card treatment (.ldh-onto-list) inside it, so the tree sits a level deeper than the
             slot - and a package that wanted no card would have it one level up. Either way the tree is
             found by what it is rather than by where it happens to sit. -->
        <xsl:variable name="tree" select="descendant::ul[contains-token(@class, 'concept-tree')][@data-concept][1]" as="element()"/>
        <xsl:variable name="root-li" select="$tree/li[1]" as="element()?"/>

        <xsl:sequence select="ldh:conceptree-reveal#2(
            map{
                'tree': $tree,
                'root-li': $root-li,
                'target': xs:anyURI($tree/@data-concept)
            }, ?)"/>
    </xsl:template>

    <!-- Step one: climb to the scheme, one hop per request.

         Shaped after the document tree's descent rather than after a closure query: ldh:doctree-descend
         issues one constant-size children query per level and decides where to go next from what is
         already in the DOM. The concept tree cannot make that decision locally - the document hierarchy
         is path-nested, so a target's ancestors are exactly its lexical prefixes, while
         /taxonomies/espresso/#this sits under no prefix of /taxonomies/coffee/#this - so the path is
         asked for instead of derived. It is asked for the same way: one hop, one request, constant
         query, no depth bound, stopping when a hop returns nothing new.

         A bounded transitive closure was the alternative and is worse on both counts the shape is meant
         to get right. Expressed as a UNION of one chain per depth it grows quadratically in text - 4.6kB
         at six hops, past Tomcat's header limit once percent-encoded, measured as a 400 - and either
         formulation has to name a maximum depth, which a taxonomy has no reason to respect.

         Why per-hop GRAPH at all rather than skos:broader*: a property path cannot leave its GRAPH, and
         with one concept per document every hop crosses one. Measured on the fixture, the path form
         reached the first ancestor and stopped, because that ancestor's own parent link lives in another
         document; the default graph is empty, so an unscoped path has nowhere to run.

         The frontier is a set, so one request covers a whole level however wide it branches: a concept
         with two broader concepts puts both in the next VALUES block. That is also the cycle guard -
         only parents not already seen enter the frontier, so A broader B with B broader A (malformed but
         legal SKOS) runs out of new nodes and terminates, where a depth bound alone would have walked
         the two of them as deep as the bound allowed. -->
    <xsl:function name="ldh:conceptree-parents-query" as="xs:string" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="children" as="xs:anyURI*"/>

        <xsl:sequence select="
            'SELECT DISTINCT ?parent WHERE { VALUES ?child { ' || string-join(for $child in $children return '&lt;' || $child || '&gt;', ' ') || ' } ' ||
            'GRAPH ?g { { ?child &lt;&skos;broader&gt; ?parent } UNION { ?parent &lt;&skos;narrower&gt; ?child } } }'"/>
    </xsl:function>

    <xsl:function name="ldh:conceptree-reveal" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?"/>

        <!-- ixsl:resolve, because the mode's contract is a promise and everything below this point
             returns a plain map: each continuation is fired as an ixsl:promise INSTRUCTION rather than
             returned, which is what lets one level fan out into several branches. -->
        <xsl:sequence select="ixsl:resolve(ldh:conceptree-climb(map:merge(($context, map{ 'frontier': $context('target'), 'ancestors': () }), map{ 'duplicates': 'use-last' })))"/>
    </xsl:function>

    <!-- one hop up: asks for the parents of everything on the frontier at once -->
    <xsl:function name="ldh:conceptree-climb" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="query" select="ldh:conceptree-parents-query($context('frontier'))" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(sd:endpoint(), map{ 'query': $query }), map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve(map:merge(($context, map{ 'request': $request }), map{ 'duplicates': 'use-last' })) =>
                ixsl:then(ldh:http-request-threaded(?, 'request', 'parents-response')) =>
                ixsl:then(ldh:handle-response(?, 'parents-response')) =>
                ixsl:then(ldh:conceptree-climbed#1)
            " on-failure="ldh:promise-failure#1"/>
        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- the hop's answer: keep climbing while it brings new nodes, then hand the set to the descent.

         The walk stops itself at the top concept, because the link from there to the scheme is
         topConceptOf/hasTopConcept rather than broader/narrower. That is the right place to stop: the
         scheme is the tree's root node and the descent starts there, so it never belongs to the set. -->
    <xsl:function name="ldh:conceptree-climbed" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="ancestors" select="$context('ancestors')" as="xs:anyURI*"/>
        <xsl:variable name="parents" select="$context('parents-response')?body//srx:binding[@name = 'parent']/srx:uri/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:variable name="frontier" select="distinct-values($parents[not(. = ($ancestors, $context('target')))])" as="xs:anyURI*"/>
        <xsl:variable name="carry" select="map:merge((map:remove($context, 'parents-response'), map{ 'ancestors': ($ancestors, $frontier), 'frontier': $frontier }), map{ 'duplicates': 'use-last' })" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="exists($frontier)">
                <xsl:sequence select="ldh:conceptree-climb($carry)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:conceptree-descend(map:remove($carry, 'frontier'))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Step two: walk down from the scheme, one level per request.

         Mirrors ldh:doctree-descend in shape - expand, fetch, re-enter from the response callback - and
         differs only where it must: the document tree decides what to expand with a URI string-prefix
         test, which works because the document hierarchy is path-nested. Concept URIs are not, so the
         test here is membership of the ancestor set.

         Every matching child is descended into, not just the first. A concept with two broader concepts
         has two paths to it and Skosmos renders it under each; the activation pass marks all of them
         without special handling, because it iterates every row whose href matches. -->
    <xsl:function name="ldh:conceptree-descend" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="ancestors" select="$context('ancestors')" as="xs:anyURI*"/>
        <xsl:variable name="li" select="if (map:contains($context, 'li')) then $context('li') else $context('root-li')" as="element()"/>
        <xsl:variable name="wanted" select="($ancestors, $context('target'))" as="xs:anyURI*"/>
        <xsl:variable name="next" select="$li/ul/li[div/a/@href = $wanted]" as="element()*"/>

        <xsl:choose>
            <!-- children already in the DOM: step into every matching branch without refetching -->
            <xsl:when test="exists($next)">
                <!-- One promise per branch, not one call per branch: a function returns a single map, so
                     N branches cannot be N return values. Firing each as an instruction also gives every
                     branch of a polyhierarchy its own chain and its own failure handler. -->
                <xsl:for-each select="$next">
                    <ixsl:promise select="ixsl:resolve(map:merge(($context, map{ 'li': . }), map{ 'duplicates': 'use-last' })) => ixsl:then(ldh:conceptree-step#1)" on-failure="ldh:promise-failure#1"/>
                </xsl:for-each>
                <xsl:sequence select="$context"/>
            </xsl:when>
            <!-- Not expanded yet: open this level, then re-enter from the children response. No test on
                 the ancestor set being non-empty - it is legitimately empty when the open concept is a
                 top concept, whose link to the scheme is topConceptOf rather than broader, and that is
                 the one level the root must still expand to reveal it. Descending into a node is only
                 ever reached for the root or for a node already matched as wanted, so opening it is
                 always right; a childless one fetches nothing, re-enters with an empty list and stops. -->
            <xsl:when test="empty($li/ul)">
                <xsl:sequence select="ldh:conceptree-expand($context, $li)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- one node of the path: the target itself ends the walk, anything else opens and continues -->
    <xsl:function name="ldh:conceptree-step" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="li" select="$context('li')" as="element()"/>

        <xsl:choose>
            <xsl:when test="$li/div/a/@href = $context('target')">
                <xsl:sequence select="ldh:conceptree-activate($context)"/>
            </xsl:when>
            <xsl:when test="empty($li/ul)">
                <xsl:sequence select="ldh:conceptree-expand($context, $li)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:conceptree-descend($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Opens one node and fetches its children, then re-enters the descent.

         The disclosure is flipped in place and the loading row emitted, so a pre-expanded level looks
         exactly like a clicked one - ldh.css hides a subtree purely off aria-expanded, which is why no
         click needs simulating. The relation follows depth, as the click handlers below do: the root is
         the scheme, whose children are its top concepts. -->
    <xsl:function name="ldh:conceptree-expand" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="li" as="element()"/>
        <xsl:variable name="uri" select="xs:anyURI($li/div/a/@href)" as="xs:anyURI"/>
        <xsl:variable name="depth" select="count($li/ancestor::li) + 1" as="xs:integer"/>
        <xsl:variable name="query" select="
            if (empty($li/ancestor::li)) then ldh:tree-children-query($uri, xs:anyURI('&skos;topConceptOf'), xs:anyURI('&skos;hasTopConcept'))
            else ldh:tree-children-query($uri, xs:anyURI('&skos;broader'), xs:anyURI('&skos;narrower'))" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(sd:endpoint(), map{ 'query': $query }), map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>

        <xsl:for-each select="$li/div/button">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expand-tree', false())"/>
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expanded-tree', true())"/>
            <ixsl:set-attribute name="aria-expanded" select="'true'"/>
            <xsl:for-each select="span[contains-token(@class, 'msi')]">
                <ixsl:set-property name="textContent" select="'expand_more'" object="."/>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:for-each select="$li">
            <xsl:result-document href="?." method="ixsl:append-content">
                <ul>
                    <li class="tree-loading" style="--depth: {$depth}">
                        <span class="msi sm" aria-hidden="true">progress_activity</span>
                        <span>
                            <xsl:apply-templates select="key('resources', 'loading', ldh:translations())" mode="ac:label"/>
                        </span>
                    </li>
                </ul>
            </xsl:result-document>
        </xsl:for-each>

        <ixsl:promise select="
            ixsl:resolve(map:merge(($context, map{ 'request': $request, 'container': $li/ul, 'uri': $uri, 'li': $li }), map{ 'duplicates': 'use-last' })) =>
                ixsl:then(ldh:http-request-threaded#1) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:tree-children-response#1) =>
                ixsl:then(ldh:conceptree-descend#1)
            " on-failure="ldh:promise-failure#1"/>
        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- Marks the open concept, at every occurrence. Copied from the drawer's ldh:DocTreeActivateHref
         and scoped to this tree: is-active rides the li so the selected ground spans the disclosure,
         aria-current rides the anchor, and both are the design system's own tree anatomy. Iterating all
         matching rows is what makes a polyhierarchical concept light up under each of its parents. -->
    <xsl:function name="ldh:conceptree-activate" as="map(*)" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="tree" select="$context('tree')" as="element()"/>
        <xsl:variable name="target" select="$context('target')" as="xs:anyURI"/>

        <xsl:for-each select="$tree//li[contains-token(@class, 'is-active')]">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-active', false())"/>
            <xsl:for-each select="div/a">
                <ixsl:remove-attribute name="aria-current"/>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select="$tree//li[div/a/@href = $target]">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-active', true())"/>
            <xsl:for-each select="div/a">
                <ixsl:set-attribute name="aria-current" select="'page'"/>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- SKOS puts the hierarchy link on whichever end the modeller chose, and both are in use in the
         wild, so every relation below is given from both directions and client/tree.xsl unions them.

         Which relation applies is a question of depth alone: the root is always the scheme, whose
         children are its top concepts, and every node below it is a concept, whose children are
         narrower concepts. count(ancestor::li) tells them apart - no marker class, which is why the
         scheme-root token this used to carry is gone: with the root always a scheme it distinguished
         nothing. -->
    <xsl:template match="button[ancestor::ul[contains-token(@class, 'concept-tree')]][count(ancestor::li) = 1]" mode="ldh:TreeChildrenLoad" priority="1" use-when="system-property('xsl:product-name') = 'SaxonJS'">
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
