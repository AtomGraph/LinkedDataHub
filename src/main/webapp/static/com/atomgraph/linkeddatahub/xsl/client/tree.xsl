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

        Everything here needs the browser - the disclosure handlers and the fetch that appends the
        results - which is exactly why the markup is not here: see tree.xsl for why that division is
        load-bearing rather than cosmetic.
    -->

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

        <xsl:variable name="branches" as="xs:string*" select="
            (for $property in $parent-properties return '{ ?child &lt;' || $property || '&gt; &lt;' || $uri || '&gt; }'),
            (for $property in $child-properties return '{ &lt;' || $uri || '&gt; &lt;' || $property || '&gt; ?child }')"/>
        <xsl:if test="empty($branches)">
            <xsl:message terminate="yes">ldh:tree-children-query requires at least one parent or child property</xsl:message>
        </xsl:if>

        <!-- the link and the child's own description are in DIFFERENT graphs whenever the link is
             asserted on the parent, because each document is its own graph: a scheme's
             skos:hasTopConcept lives in the scheme's graph while the concept's rdf:type lives in the
             concept's. Scoping both to one GRAPH silently drops every child linked from above -
             measured against a fixture where it returned one top concept of two. -->
        <!-- A DESCRIBE, written out whole rather than a SELECT for something else to wrap, and handed
             to the endpoint as the string it already is. It used to go through SPARQLBuilder twice -
             parsed from a string here, re-serialised in the fetch - and that round-trip MERGED the two
             sibling GRAPH blocks into one keeping only the last graph variable, putting the type
             requirement back inside the link's graph and silently dropping every child linked from the
             parent side. Measured: the query left here correctly scoped and arrived at the endpoint as
             GRAPH ?childGraph { {..} UNION {..} ?child a ?Type }, returning one top concept of two.
             Wrapping the second block in a group did not survive either. Nothing needed the parse -
             this query is generated, not authored or edited - so the scoping the comment above
             describes is now the scoping that gets sent. -->
        <xsl:sequence select="
            'DESCRIBE ?child WHERE { GRAPH ?linkGraph { ' ||
            string-join($branches, ' UNION ') ||
            ' } GRAPH ?childGraph { ?child a ?Type } }'"/>
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
        <xsl:param name="query" as="xs:string"/> <!-- a DESCRIBE of the children, sent as given -->
        <xsl:param name="endpoint" select="sd:endpoint()" as="xs:anyURI"/>

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
                    <xsl:message>
                        Error loading tree children for URI: <xsl:value-of select="$uri"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

</xsl:stylesheet>
