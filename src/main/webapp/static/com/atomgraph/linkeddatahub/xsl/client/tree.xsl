<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!--
        The interactive half of the resource tree; the emitter it drives lives in the shared tree.xsl.

        Everything here needs the browser - the disclosure handlers, the fetch that appends the
        results, and the reveal that opens the path down to a node - which is exactly why the markup is
        not here: see tree.xsl for why that division is load-bearing rather than cosmetic.

        A domain tells this module which RELATIONS its tree follows and nothing else: its
        ldh:TreeChildrenLoad rule answers, for a node's disclosure button, with the predicates that link
        the node to its children, and its ldh:TreeParentsLoad rule answers, for the tree, with the
        predicates that link a node to its parents (client/hooks.xsl). Both answers are maps, not
        queries and not work - a package stylesheet renders and returns data, and runs nothing - and
        everything that moves (the fetch, the climb, the descent, the activation, the scroll) is here,
        once, for the drawer's document tree and a package's tree alike.
    -->

    <!-- How many children one fetch returns. A tree is a navigation aid, not a listing: a container
         with more children than this shows the first page of them (plus the one being opened to), and
         the alternative is not "all of them" but the response-size failure that unbounded DESCRIBEs
         produced over large containers. Raise it in an app stylesheet if its containers warrant it. -->
    <xsl:param name="ldh:tree-page-size" select="1000" as="xs:integer"/>

    <!-- The children of a node, as a query this module generates rather than one the domain writes.
         A tree is defined by the relation it follows, so that relation is the parameter: properties
         asserted on the child pointing at its parent, and - since RDF lets either end carry the link -
         properties asserted on the parent pointing at its children. The document hierarchy has two of
         the first kind and none of the second; a SKOS tree asserts skos:broader on the child and may
         also carry skos:narrower on the parent, and gets both branches for free.

         The type requirement keeps a tree to resources that describe themselves, which is what the
         stored ldh:SelectChildren asked for; its ORDER BY and its ?thing binding are deliberately not
         reproduced, because the children are sorted by ac:label() when they are rendered and the topic
         was already being stripped out before the query ran. -->
    <xsl:function name="ldh:tree-children-query" as="xs:string">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="parent-properties" as="xs:anyURI*"/> <!-- asserted on the child: ?child P $this -->
        <xsl:param name="child-properties" as="xs:anyURI*"/> <!-- asserted on the parent: $this P ?child -->

        <xsl:sequence select="ldh:tree-children-query($uri, $parent-properties, $child-properties, ())"/>
    </xsl:function>

    <!-- $path-uri is the document the tree is opening to, if any: the child leading to it is included
         whatever the page holds, so a descent through a container larger than the page still finds its
         next step (the document tree's ancestors are its lexical prefixes, and the descent would
         otherwise stop silently). -->
    <xsl:function name="ldh:tree-children-query" as="xs:string">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="parent-properties" as="xs:anyURI*"/>
        <xsl:param name="child-properties" as="xs:anyURI*"/>
        <xsl:param name="path-uri" as="xs:anyURI?"/>

        <xsl:variable name="branches" as="xs:string*" select="
            (for $property in $parent-properties return '{ ?child &lt;' || $property || '&gt; &lt;' || $uri || '&gt; }'),
            (for $property in $child-properties return '{ &lt;' || $uri || '&gt; &lt;' || $property || '&gt; ?child }')"/>
        <xsl:if test="empty($branches)">
            <xsl:message terminate="yes">ldh:tree-children-query requires at least one parent or child property</xsl:message>
        </xsl:if>

        <xsl:variable name="links" select="string-join($branches, ' UNION ')" as="xs:string"/>
        <!-- the relation the tree follows, echoed back on each child: it is what a domain's
             ldh:TreeNode rule reads to decide whether a node opens (the document tree keys on
             sioc:has_parent, which only a container has). Generic because the relation is the
             parameter - whatever a tree is built on is what its nodes are judged by. -->
        <xsl:variable name="tree-properties" select="distinct-values(($parent-properties, $child-properties))" as="xs:anyURI*"/>

        <!-- the link and the child's own description are in DIFFERENT graphs whenever the link is
             asserted on the parent, because each document is its own graph: a scheme's
             skos:hasTopConcept lives in the scheme's graph while the concept's rdf:type lives in the
             concept's. Scoping both to one GRAPH silently drops every child linked from above -
             measured against a fixture where it returned one top concept of two. -->
        <!-- Written out whole rather than a SELECT for something else to wrap, and handed to the
             endpoint as the string it already is. It used to go through SPARQL.js twice - parsed
             from a string here, re-serialised in the fetch - and that round-trip MERGED the two
             sibling GRAPH blocks into one keeping only the last graph variable, putting the type
             requirement back inside the link's graph and silently dropping every child linked from the
             parent side. Nothing needed the parse - this query is generated, not authored or edited. -->
        <!-- A CONSTRUCT of exactly what a node renders - its type for the icon, its labels, and the
             tree relation for the disclosure - not a DESCRIBE of everything the child happens to say.
             A DESCRIBE returns whole documents: measured over a container of 28k children it was
             20.5 MB against 6.6 MB here, and over one of 65k it exceeded the platform's response limit
             outright, so the tree answered 502 on every page under it. The page bound is what makes
             that independent of container size; the children are sorted by ac:label() as they are
             rendered, so ORDER BY only has to make the page itself deterministic. -->
        <xsl:sequence select="
            'CONSTRUCT { ?child a ?Type . ?child ?labelProp ?label . ?child ?treeProp ?treeValue }&#10;' ||
            'WHERE { { SELECT DISTINCT ?child WHERE { GRAPH ?linkGraph { ' || $links || ' } } ORDER BY ?child LIMIT ' || $ldh:tree-page-size || ' }' ||
            (if (exists($path-uri)) then ' UNION { GRAPH ?pathGraph { ' || $links || ' } FILTER (strstarts(&quot;' || $path-uri || '&quot;, str(?child))) }' else '') ||
            '&#10;GRAPH ?childGraph { ?child a ?Type' ||
            ' OPTIONAL { ?child ?labelProp ?label FILTER (?labelProp IN (' || string-join(for $property in $ldh:label-properties return '&lt;' || $property || '&gt;', ', ') || ')) }' ||
            (if (exists($tree-properties)) then ' OPTIONAL { ?child ?treeProp ?treeValue FILTER (?treeProp IN (' || string-join(for $property in $tree-properties return '&lt;' || $property || '&gt;', ', ') || ')) }' else '') ||
            ' } }'"/>
    </xsl:function>

    <!-- The parents of a set of nodes, one hop up, over the same relation parameters as the children
         query: properties asserted on the child and properties asserted on the parent, each read from
         its own GRAPH because every hop crosses one document. Asked for a whole frontier at once, so
         one request covers a level however wide a polyhierarchy branches. -->
    <xsl:function name="ldh:tree-parents-query" as="xs:string">
        <xsl:param name="children" as="xs:anyURI*"/>
        <xsl:param name="parent-properties" as="xs:anyURI*"/> <!-- asserted on the child: ?child P ?parent -->
        <xsl:param name="child-properties" as="xs:anyURI*"/> <!-- asserted on the parent: ?parent P ?child -->

        <xsl:variable name="branches" as="xs:string*" select="
            (for $property in $parent-properties return '{ ?child &lt;' || $property || '&gt; ?parent }'),
            (for $property in $child-properties return '{ ?parent &lt;' || $property || '&gt; ?child }')"/>
        <xsl:if test="empty($branches)">
            <xsl:message terminate="yes">ldh:tree-parents-query requires at least one parent or child property</xsl:message>
        </xsl:if>

        <xsl:sequence select="
            'SELECT DISTINCT ?parent WHERE { VALUES ?child { ' || string-join(for $child in $children return '&lt;' || $child || '&gt;', ' ') || ' } ' ||
            'GRAPH ?g { ' || string-join($branches, ' UNION ') || ' } }'"/>
    </xsl:function>

    <!-- the children query for a node, from what its domain's ldh:TreeChildrenLoad rule answered: the
         relation as predicates, or - for a shape this module does not generate - the query itself,
         sent as given -->
    <xsl:function name="ldh:tree-relation-query" as="xs:string">
        <xsl:param name="relation" as="map(*)"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="path-uri" as="xs:anyURI?"/>

        <xsl:sequence select="
            if (map:contains($relation, 'query')) then $relation('query')
            else ldh:tree-children-query($uri, $relation('parent-properties'), $relation('child-properties'), $path-uri)"/>
    </xsl:function>

    <!-- EVENT HANDLERS -->

    <!-- expands a node. A list that is already present re-shows through the toggle's aria-expanded
         state alone (ldh.css), so children are fetched exactly once. -->
    <xsl:template match="button[contains-token(@class, 'btn-expand-tree')]" mode="ixsl:onclick">
        <xsl:variable name="li" select="../.." as="element()"/> <!-- the row's parent <li> -->

        <xsl:choose>
            <xsl:when test="$li/ul">
                <xsl:call-template name="ldh:TreeNodeDisclose">
                    <xsl:with-param name="li" select="$li"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ldh:TreeNodeExpand">
                    <xsl:with-param name="li" select="$li"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- collapses a node; the children stay in the DOM and are never refetched -->
    <xsl:template match="button[contains-token(@class, 'btn-expanded-tree')]" mode="ixsl:onclick">
        <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expand-tree', true())"/>
        <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expanded-tree', false())"/>
        <ixsl:set-attribute name="aria-expanded" select="'false'"/>
        <xsl:for-each select="span[contains-token(@class, 'msi')]">
            <ixsl:set-property name="textContent" select="'chevron_right'" object="."/>
        </xsl:for-each>
    </xsl:template>

    <!-- the reveal: a tree that carries data-tree-reveal asks for the path down to that node to be
         opened once the tree is in the DOM - on a direct load and on a client-side navigation alike,
         since the ldh:RenderRow walk (client/block.xsl) visits every element of the rendered pane on
         both. The attribute is the domain's whole part in it: the climb and the descent are below. -->
    <xsl:template match="ul[contains-token(@class, 'ldh-tree')][@data-tree-reveal]" mode="ldh:RowHook" as="(function(item()?) as map(*))*">
        <xsl:sequence select="ldh:tree-reveal#2(map{ 'tree': ., 'target': xs:anyURI(@data-tree-reveal) }, ?)"/>
    </xsl:template>

    <!-- OPENING A NODE -->

    <!-- Opening a node is two things, and both are shared: the descent opens the path down to the node
         being viewed ahead of the reader, and a pre-expanded level has to be indistinguishable from a
         clicked one. Splitting them is what the click handler needs - it flips a node whose children
         are already loaded, which re-shows off aria-expanded, and expands one whose children are not. -->
    <xsl:template name="ldh:TreeNodeDisclose">
        <xsl:param name="li" as="element()"/>

        <xsl:for-each select="$li/div/button">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expand-tree', false())"/>
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expanded-tree', true())"/>
            <ixsl:set-attribute name="aria-expanded" select="'true'"/>
            <xsl:for-each select="span[contains-token(@class, 'msi')]">
                <ixsl:set-property name="textContent" select="'expand_more'" object="."/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- the list the children are rendered into, carrying the loading row until they land -->
    <xsl:template name="ldh:TreeChildrenPlaceholder">
        <xsl:param name="li" as="element()"/>
        <xsl:variable name="depth" select="count($li/ancestor::li) + 1" as="xs:integer"/> <!-- children sit one level below this row -->

        <xsl:for-each select="$li">
            <xsl:result-document href="?." method="ixsl:append-content">
                <ul>
                    <!-- replaced by the list items when the children response lands -->
                    <li class="tree-loading" style="--depth: {$depth}">
                        <span class="msi sm" aria-hidden="true">progress_activity</span>
                        <span>
                            <xsl:apply-templates select="key('resources', 'loading', ldh:translations())" mode="ac:label"/>
                        </span>
                    </li>
                </ul>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- Expands a node whose children are not in the DOM yet: flips the disclosure, appends the
         placeholder list, asks the domain which relation the children are linked over and fetches them
         into it. The one act behind a click and behind each level the descent opens, so the loading row,
         the busy cursor and the failure handler are the same whichever way a level opens.

         Dispatched on the button, so a domain selects its relation by matching the tree it sits in.
         A node whose domain answers nothing is left as it is: a tree whose domain supplies no relation
         is not expandable. -->
    <xsl:template name="ldh:TreeNodeExpand">
        <xsl:param name="li" as="element()"/>
        <xsl:param name="path-uri" select="()" as="xs:anyURI?"/> <!-- the node being opened to, pinned into the page of children -->
        <xsl:param name="then" select="()" as="(function(map(*)) as item()*)?"/> <!-- what to do once the children are in the DOM -->

        <!-- the RESOURCE, not the row's href: a domain may have decorated the href with display
             parameters, which would otherwise arrive as the subject of its children query -->
        <xsl:variable name="uri" select="ldh:tree-node-uri($li/div/a/@href)" as="xs:anyURI"/>
        <xsl:variable name="relation" as="map(*)?">
            <xsl:apply-templates select="$li/div/button" mode="ldh:TreeChildrenLoad"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="exists($relation)">
                <xsl:call-template name="ldh:TreeNodeDisclose">
                    <xsl:with-param name="li" select="$li"/>
                </xsl:call-template>
                <xsl:call-template name="ldh:TreeChildrenPlaceholder">
                    <xsl:with-param name="li" select="$li"/>
                </xsl:call-template>
                <xsl:call-template name="ldh:TreeChildrenFetch">
                    <xsl:with-param name="container" select="$li/ul"/>
                    <xsl:with-param name="uri" select="$uri"/>
                    <xsl:with-param name="query" select="ldh:tree-relation-query($relation, $uri, $path-uri)"/>
                    <xsl:with-param name="then" select="$then"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>ldh:TreeNodeExpand: no ldh:TreeChildrenLoad rule answers for <xsl:value-of select="$uri"/>, the node stays closed</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Fetches a node's children and renders them into the placeholder list: runs the query as
         given and applies ldh:TreeNode to whatever comes back. -->
    <xsl:template name="ldh:TreeChildrenFetch">
        <xsl:param name="container" as="element()"/> <!-- the <ul> the children are rendered into -->
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="query" as="xs:string"/> <!-- a CONSTRUCT of the children, sent as given -->
        <xsl:param name="endpoint" select="sd:endpoint()" as="xs:anyURI"/>
        <!-- what to do once the children are in the DOM. The descent passes its next step here rather
             than repeating this fetch, which is how it used to continue: its copy had no busy cursor,
             no loading row and no failure handler, so a failure mid-descent was silent. -->
        <xsl:param name="then" select="()" as="(function(map(*)) as item()*)?"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'container': $container,
            'uri': $uri
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:tree-children-response#1) =>
            ixsl:then(ldh:tree-children-continue($then, ?)) =>
            ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure($container, 'tree-children-not-loaded', ?)"/>
    </xsl:template>

    <!-- CALLBACKS -->

    <!-- applies ldh:TreeChildrenFetch's continuation if it was given one, so the chain is written once
         whether or not a caller carries on from it -->
    <xsl:function name="ldh:tree-children-continue" as="item()*" ixsl:updating="yes">
        <xsl:param name="then" as="(function(map(*)) as item()*)?"/>
        <xsl:param name="context" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="exists($then)">
                <xsl:sequence select="$then($context)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- replaces the placeholder list's content with the children, sorted by label -->
    <xsl:function name="ldh:tree-children-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/> <!-- <ul> element -->
        <xsl:variable name="uri" select="$context('uri')" as="xs:anyURI"/>

        <xsl:message>ldh:tree-children-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="resources" select="rdf:RDF/*[@rdf:about]" as="element()*"/>
                        <!-- replaces the list's content, so the lazy-loading row goes with it -->
                        <xsl:for-each select="$container">
                            <xsl:variable name="depth" select="count(ancestor::li)" as="xs:integer"/>
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <xsl:apply-templates select="$resources" mode="ldh:TreeNode">
                                    <xsl:sort select="ac:label(.)"/>
                                    <!-- tunnelled: a domain narrows ldh:TreeNode by matching and delegating with
                                         xsl:next-match, which forwards only the parameters it names, so a plain
                                         parameter here arrives as its default 0 and the whole tree renders flat -->
                                    <xsl:with-param name="depth" select="$depth" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:result-document>
                        </xsl:for-each>

                        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- the loading row would otherwise spin for the rest of the session: a tree in the content replaces it with
                         the failure, the drawer's tree goes (client/navigation.xsl) -->
                    <xsl:sequence select="ldh:render-failure($container, 'tree-children-not-loaded', ldh:http-error-key(.), ldh:response-detail(.))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- THE REVEAL: open the path down to a node, mark it, bring it into view

         Two steps. The climb asks for the node's ancestors one hop per request, over the relation the
         tree's ldh:TreeParentsLoad rule names; the descent then walks down from the root, expanding
         every child that is in the ancestor set, one level per request, until it reaches the node. A
         tree whose ancestors need no request - the document hierarchy, whose ancestors are the lexical
         prefixes of a document's URI - hands the descent its ancestor set directly (client/navigation.xsl).

         The context map carries: tree (the ul.ldh-tree), target (the node's URI), ancestors (URIs),
         li (where the descent is), path-uri (optional: the target, for a page of children to pin the
         path child into), relation (the parents relation, while climbing), frontier (while climbing).

         Why a climb at all, and why one hop at a time: the concept tree cannot decide where to go next
         from what is in the DOM, since a target's ancestors are not its lexical prefixes - a concept
         sits under no prefix of another concept - so the path is asked for. It is asked for the way the
         descent opens levels: one hop, one request, constant query, no depth bound, stopping when a hop
         returns nothing new. A bounded transitive closure was the alternative and is worse on both
         counts: as a UNION of one chain per depth it grows quadratically in text (past Tomcat's header
         limit at six hops, measured as a 400), and it has to name a maximum depth a taxonomy has no
         reason to respect. A property path cannot leave its GRAPH, and with one node per document
         every hop crosses one, so the hop is per-GRAPH too.

         The frontier is a set, so one request covers a whole level however wide it branches, and only
         parents not already seen enter it - the cycle guard: A broader B with B broader A runs out of
         new nodes and terminates where a depth bound would walk the two as deep as the bound allowed. -->

    <!-- the factory a tree's reveal contributes to the ldh:RenderRow walk (ldh:RowHook above). It
         resolves to a promise: everything below returns a plain map and fires each continuation as an
         ixsl:promise INSTRUCTION rather than returning it, which is what lets one level fan out into
         several branches. -->
    <xsl:function name="ldh:tree-reveal" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?"/>
        <xsl:variable name="tree" select="$context('tree')" as="element()"/>
        <xsl:variable name="relation" as="map(*)?">
            <xsl:apply-templates select="$tree" mode="ldh:TreeParentsLoad"/>
        </xsl:variable>
        <xsl:variable name="start" select="map:merge(($context, map{ 'li': $tree/li[1], 'ancestors': () }), map{ 'duplicates': 'use-last' })" as="map(*)"/>

        <xsl:choose>
            <!-- the domain names the relation the ancestors are reached over: climb first -->
            <xsl:when test="exists($relation) and exists($tree/li[1])">
                <xsl:sequence select="ixsl:resolve(ldh:tree-climb(map:merge(($start, map{ 'relation': $relation, 'frontier': $context('target') }), map{ 'duplicates': 'use-last' })))"/>
            </xsl:when>
            <!-- no relation to climb over: the path is what the DOM already holds -->
            <xsl:when test="exists($tree/li[1])">
                <xsl:sequence select="ixsl:resolve(ldh:tree-step($start))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:resolve($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- one hop up: asks for the parents of everything on the frontier at once -->
    <xsl:function name="ldh:tree-climb" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="relation" select="$context('relation')" as="map(*)"/>
        <xsl:variable name="query" select="ldh:tree-parents-query($context('frontier'), $relation('parent-properties'), $relation('child-properties'))" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(sd:endpoint(), map{ 'query': $query }), map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve(map:put($context, 'request', $request)) =>
                ixsl:then(ldh:http-request-threaded(?, 'request', 'parents-response')) =>
                ixsl:then(ldh:handle-response(?, 'parents-response')) =>
                ixsl:then(ldh:tree-climbed#1)
            " on-failure="ldh:promise-failure($context('tree')/li[1], 'tree-children-not-loaded', ?)"/>
        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- the hop's answer: keep climbing while it brings new nodes, then hand the set to the descent.
         The walk stops itself where the relation stops - a top concept is linked to its scheme by
         topConceptOf/hasTopConcept rather than broader/narrower - and that is the right place: the
         root node is where the descent starts, so it never belongs to the set. -->
    <xsl:function name="ldh:tree-climbed" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="ancestors" select="$context('ancestors')" as="xs:anyURI*"/>
        <xsl:variable name="parents" select="$context('parents-response')?body//srx:binding[@name = 'parent']/srx:uri/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:variable name="frontier" select="distinct-values($parents[not(. = ($ancestors, $context('target')))])" as="xs:anyURI*"/>
        <xsl:variable name="carry" select="map:merge((map:remove($context, 'parents-response'), map{ 'ancestors': ($ancestors, $frontier), 'frontier': $frontier }), map{ 'duplicates': 'use-last' })" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="exists($frontier)">
                <xsl:sequence select="ldh:tree-climb($carry)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:tree-step(map:remove(map:remove($carry, 'frontier'), 'relation'))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- one node of the path: the target itself ends the walk, anything else opens and continues -->
    <xsl:function name="ldh:tree-step" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="li" select="$context('li')" as="element()"/>

        <xsl:choose>
            <xsl:when test="ldh:tree-node-uri($li/div/a/@href) = $context('target')">
                <xsl:sequence select="ldh:tree-activate($context('tree'), $context('target'))"/>
                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:when test="empty($li/ul)">
                <xsl:call-template name="ldh:TreeNodeExpand">
                    <xsl:with-param name="li" select="$li"/>
                    <xsl:with-param name="path-uri" select="$context('path-uri')"/>
                    <xsl:with-param name="then" select="ldh:tree-descend($context, ?)"/>
                </xsl:call-template>
                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:tree-descend($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Steps into every child of the node the descent is at that is on the path - every matching
         child, not just the first: a concept with two broader concepts has two paths to it and is
         rendered under each, and the activation marks all of them. The test is membership of the
         ancestor set, which is what makes the descent indifferent to how the set was found.

         Children already in the DOM are stepped into without refetching. A node not expanded yet is
         opened and re-entered from the children response; no test on the ancestor set being non-empty,
         since it is legitimately empty when the target is a child of the root - a top concept, whose
         link to the scheme is not the relation the climb follows - and that is the one level the root
         must still expand to reveal it. A childless node fetches nothing, re-enters with an empty list
         and stops. -->
    <xsl:function name="ldh:tree-descend" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="li" select="$context('li')" as="element()"/>
        <xsl:variable name="wanted" select="($context('ancestors'), $context('target'))" as="xs:anyURI*"/>
        <xsl:variable name="next" select="$li/ul/li[ldh:tree-node-uri(./div/a/@href) = $wanted]" as="element()*"/>

        <xsl:choose>
            <xsl:when test="exists($next)">
                <!-- One promise per branch, not one call per branch: a function returns a single map, so
                     N branches cannot be N return values. Firing each as an instruction also gives every
                     branch of a polyhierarchy its own chain and its own failure handler. -->
                <xsl:for-each select="$next">
                    <ixsl:promise select="ixsl:resolve(map:put($context, 'li', .)) => ixsl:then(ldh:tree-step#1)" on-failure="ldh:promise-failure(., 'tree-children-not-loaded', ?)"/>
                </xsl:for-each>
                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:when test="empty($li/ul)">
                <xsl:call-template name="ldh:TreeNodeExpand">
                    <xsl:with-param name="li" select="$li"/>
                    <xsl:with-param name="path-uri" select="$context('path-uri')"/>
                    <xsl:with-param name="then" select="ldh:tree-descend($context, ?)"/>
                </xsl:call-template>
                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- re-entry from a children response: the node is the one the descent opened, now with its
         children in the DOM (or the loading row still there, when they never landed, which the
         descent then stops at) -->
    <xsl:function name="ldh:tree-descend" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="load-context" as="map(*)"/>

        <xsl:sequence select="ldh:tree-descend($context)"/>
    </xsl:function>

    <!-- Marks the node, at every occurrence: is-active rides the li so the selected ground spans the
         disclosure, aria-current rides the anchor, both the design system's own tree anatomy. Iterating
         all matching rows is what makes a polyhierarchical concept light up under each of its parents.

         Then brings it into view inside the tree, which scrolls on its own where ldh.css caps the card
         at the viewport and gives .ldh-tree overflow-y: auto: a large scheme reveals its target
         thousands of pixels down, where nobody would find it. The row is centred rather than put at the
         top edge, so its parent and siblings stay in view - the context that says where it sits - and
         only when it is not visible already, so a node near the top is not moved. The tree's own
         scrollTop rather than scrollIntoView(), which would scroll the page as well; a tree that does
         not scroll (the drawer's, whose scroll box is the drawer) is left alone by the visibility test.

         The FIRST occurrence in document order: a polyhierarchical node is active under each of its
         parents, and every branch of the descent ends here in whatever order its requests return.
         Re-deciding on each call converges on the same row whichever finishes last. -->
    <xsl:function name="ldh:tree-activate" as="item()*" ixsl:updating="yes">
        <xsl:param name="tree" as="element()"/> <!-- the ul.ldh-tree -->
        <xsl:param name="target" as="xs:anyURI"/>

        <xsl:for-each select="$tree//li[contains-token(@class, 'is-active')]">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-active', false())"/>
            <xsl:for-each select="./div/a">
                <ixsl:remove-attribute name="aria-current"/>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select="$tree//li[ldh:tree-node-uri(./div/a/@href) = $target]">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-active', true())"/>
            <xsl:for-each select="./div/a">
                <ixsl:set-attribute name="aria-current" select="'page'"/>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:variable name="row" select="($tree//li[ldh:tree-node-uri(./div/a/@href) = $target])[1]/div" as="element()?"/>
        <xsl:if test="exists($row)">
            <xsl:variable name="scroll-top" select="ixsl:get($tree, 'scrollTop')" as="xs:double"/>
            <xsl:variable name="client-height" select="ixsl:get($tree, 'clientHeight')" as="xs:double"/>
            <xsl:variable name="row-rect" select="ixsl:call($row, 'getBoundingClientRect', [])"/>
            <xsl:variable name="row-height" select="ixsl:get($row-rect, 'height')" as="xs:double"/>
            <!-- the row's offset within the tree's scrolled content -->
            <xsl:variable name="row-top" select="ixsl:get($row-rect, 'top') - ixsl:get(ixsl:call($tree, 'getBoundingClientRect', []), 'top') + $scroll-top" as="xs:double"/>

            <xsl:if test="$row-top lt $scroll-top or $row-top + $row-height gt $scroll-top + $client-height">
                <ixsl:set-property name="scrollTop" select="$row-top - ($client-height - $row-height) div 2" object="$tree"/>
            </xsl:if>
        </xsl:if>
    </xsl:function>

</xsl:stylesheet>
