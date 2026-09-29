<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:lds="&lds;"
xmlns:sd="&sd;"
exclude-result-prefixes="#all"
>

    <!--
        The browser-only half of the package extension contract (see hooks.xsl for the contract itself
        and the shared open modes). Imported by client.xsl directly, so it may use the client's
        functions freely and needs no product guards.
    -->

    <!-- the children fetch for one tree node, chosen by the domain that owns the tree: the drawer's
         document tree matches its own buttons in client/navigation.xsl, a package's tree matches its
         own. No fallback: a tree whose domain supplies no fetch is not expandable. -->
    <xsl:mode name="ldh:TreeChildrenLoad"/>

    <!-- work to schedule for one rendered row, as FACTORIES rather than work: the ldh:RenderRow walk
         in client/block.xsl applies this mode to every element it visits, collects what comes back
         inside a non-updating binding and invokes the factories later inside ixsl:promise, which is
         also what gives ixsl:http-request the active promise it requires.

         The walk itself is sealed and only ever descends; this mode is what it asks at each node. So a
         rule here can add work for a node and can never take the node's subtree out of the walk, which
         is exactly the failure that made this a separate mode. deep-skip: a node nobody claims
         contributes nothing. -->
    <xsl:mode name="ldh:RowHook" on-no-match="deep-skip"/>

    <!-- the platform's own contribution: ontology-driven view blocks for any row wrapper produced by
         resource.xsl - outer div.ldh-block-row[@about] whose div.row-main child contains the inner
         typed resource block (class='block ldh-block').

         Typed-block rows (Object/View/Query/Chart) are excluded automatically: their card carries no
         @typeof (the typeof rides the inner .block-row container), so the inner [@typeof] predicate
         excludes them.

         Below the packages on purpose: a package may decorate the injection for rows of its own
         vocabulary, and must xsl:next-match to keep it. A rule that forgets costs that one row its
         views and nothing else. -->
    <xsl:template match="child::div[contains-token(@class, 'ldh-block-row')][@about][child::div[contains-token(@class, 'row-main')]/div[contains-token(@class, 'block')][@typeof]]" mode="ldh:RowHook" as="(function(item()?) as map(*))*">
        <xsl:variable name="block" select="child::div[contains-token(@class, 'row-main')]/div[contains-token(@class, 'block')][@typeof]" as="element()"/>
        <xsl:variable name="typeof-uris" select="tokenize($block/@typeof, ' ') ! xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:variable name="values-clause" select="' VALUES ?type { ' || string-join(for $t in $typeof-uris return '&lt;' || $t || '&gt;', ' ') || ' }'" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': $ontology-view-query || $values-clause }), map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
            map{
                'request': $request,
                'container': .,
                'base-uri': ac:absolute-path(ldh:base-uri($block)),
                'endpoint': sd:endpoint()
            }"/>
        <xsl:sequence select="ldh:load-block#3($context, ldh:ontology-view-self-thunk#1, ?)"/>
    </xsl:template>

</xsl:stylesheet>
