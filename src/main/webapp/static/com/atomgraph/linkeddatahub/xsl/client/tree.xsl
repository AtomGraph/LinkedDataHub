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
        A lazily expanded tree of resources, over whatever relation the caller's domain uses.

        The hierarchy this renders is not the document hierarchy: the drawer's document tree is one
        consumer, a SKOS concept tree is another, and the two share every part of the widget except
        the query that produces a node's children and the test for whether a node has any. Those two
        are the extension points - a domain supplies them by matching in ldh:TreeChildrenLoad and
        ldh:TreeNode - and nothing else here knows what it is rendering.

        Deliberately not a role="tree": a tree widget owes a roving tabindex and typeahead over
        non-navigational items, while this is a nested list of links, which is what the markup says
        and what screen readers announce.
    -->

    <!-- one tree node: li > .tree-row > disclosure + a.tree-link. The li carries state, the row carries
         the depth indent ramp, and a node with no children takes the inert spacer so labels stay aligned.
         Whether a node can be expanded is the domain's to decide, so it is a parameter rather than a test
         on some predicate this module would have to know about; a domain narrows the match and supplies it
         through xsl:next-match. -->
    <xsl:template match="*[@rdf:about]" mode="ldh:TreeNode">
        <xsl:param name="depth" select="0" as="xs:integer"/>
        <xsl:param name="expandable" select="false()" as="xs:boolean"/>

        <li>
            <div class="tree-row" style="--depth: {$depth}">
                <!-- the disclosure is a SIBLING of the anchor, so a node can be expanded without
                     navigating into it, and so the anchor holds no nested interactive content -->
                <xsl:choose>
                    <xsl:when test="$expandable">
                        <button type="button" class="ac-iconbtn sz-xs in-neutral ap-ghost btn-expand-tree" aria-expanded="false">
                            <span class="msi sm" aria-hidden="true">chevron_right</span>
                        </button>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="tree-spacer" aria-hidden="true"/>
                    </xsl:otherwise>
                </xsl:choose>

                <a class="tree-link" href="{@rdf:about}" title="{@rdf:about}">
                    <span class="msi sm tree-icon" aria-hidden="true">
                        <xsl:value-of select="ldh:class-icon(., 'description')"/>
                    </span>
                    <span class="tree-label">
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </span>
                </a>
            </div>
        </li>
    </xsl:template>

    <!-- The children of a node, as a SELECT this module generates rather than one the domain writes.
         A tree is defined by the relation it follows, so that relation is the parameter: properties
         asserted on the child pointing at its parent, and - since RDF lets either end carry the link -
         properties asserted on the parent pointing at its children. The document hierarchy has two of
         the first kind and none of the second; a SKOS tree asserts skos:broader on the child and may
         also carry skos:narrower on the parent, and gets both branches for free.

         The type requirement keeps a tree to resources that describe themselves, which is what the
         stored ldh:SelectChildren asked for; its ORDER BY and its ?thing binding are deliberately not
         reproduced, because the children are sorted by ac:label() when they are rendered and the topic
         was already being stripped out before the query ran. -->
    <xsl:function name="ldh:tree-children-query" as="document-node()">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="parent-properties" as="xs:anyURI*"/> <!-- asserted on the child: ?child P $this -->
        <xsl:param name="child-properties" as="xs:anyURI*"/> <!-- asserted on the parent: $this P ?child -->

        <xsl:variable name="branches" as="xs:string*" select="
            (for $property in $parent-properties return '{ ?child &lt;' || $property || '&gt; &lt;' || $uri || '&gt; }'),
            (for $property in $child-properties return '{ &lt;' || $uri || '&gt; &lt;' || $property || '&gt; ?child }')"/>
        <xsl:if test="empty($branches)">
            <xsl:message terminate="yes">ldh:tree-children-query requires at least one parent or child property</xsl:message>
        </xsl:if>

        <xsl:variable name="select-string" select="
            'SELECT DISTINCT ?child WHERE { GRAPH ?childGraph { ' ||
            string-join($branches, ' UNION ') ||
            ' ?child a ?Type } }'" as="xs:string"/>
        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:document>
            <xsl:sequence select="json-to-xml($select-json-string)"/>
        </xsl:document>
    </xsl:function>

    <!-- EVENT HANDLERS -->

    <!-- expands a node: flips the disclosure, appends a placeholder list, and hands off to the domain
         to load the children into it. A list that is already present re-shows through the toggle's
         aria-expanded state alone (ldh.css), so children are fetched exactly once. -->
    <xsl:template match="button[contains-token(@class, 'btn-expand-tree')]" mode="ixsl:onclick">
        <xsl:variable name="href" select="following-sibling::a/@href" as="xs:anyURI"/>
        <xsl:variable name="container" select="../.." as="element()"/> <!-- the row's parent <li> -->
        <xsl:variable name="depth" select="count(ancestor::li)" as="xs:integer"/> <!-- children sit one level below this row -->

        <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expand-tree', false())"/>
        <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'btn-expanded-tree', true())"/>
        <ixsl:set-attribute name="aria-expanded" select="'true'"/>
        <xsl:for-each select="span[contains-token(@class, 'msi')]">
            <ixsl:set-property name="textContent" select="'expand_more'" object="."/>
        </xsl:for-each>

        <xsl:if test="not($container/ul)">
            <xsl:for-each select="$container">
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

            <!-- dispatched on the button, so a domain selects its loader by matching the tree it sits in -->
            <xsl:apply-templates select="." mode="ldh:TreeChildrenLoad">
                <xsl:with-param name="container" select="$container/ul"/>
                <xsl:with-param name="uri" select="$href"/>
            </xsl:apply-templates>
        </xsl:if>
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

    <!-- LOADING -->

    <!-- Fetches a node's children and renders them into the placeholder list. The SELECT is the
         caller's - this wraps it in a DESCRIBE, runs it, and applies ldh:TreeNode to whatever comes
         back - so the relation the tree follows lives entirely in the domain's query. -->
    <xsl:template name="ldh:TreeChildrenFetch">
        <xsl:param name="container" as="element()"/> <!-- the <ul> the children are rendered into -->
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" select="sd:endpoint()" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
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
            ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- CALLBACKS -->

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
                                    <xsl:with-param name="depth" select="$depth"/>
                                </xsl:apply-templates>
                            </xsl:result-document>
                        </xsl:for-each>

                        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        Error loading tree children for URI: <xsl:value-of select="$uri"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

</xsl:stylesheet>
