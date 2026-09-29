<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>

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
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
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

    <!-- This module is the half of the widget that is pure markup, so it sits in the shared trunk and
         renders on the server as well as in the browser. That split is not tidiness: the client keeps
         the server-rendered body on a direct page load, so a tree emitted only client-side would be
         absent from every bookmarked or shared URL until the reader navigated somewhere else. What
         genuinely needs the browser - the disclosure handlers and the fetch - stays in
         client/tree.xsl. The two meet at the button
         this template emits: the server paints it, the client binds it. -->


    <!-- the per-node renderer - the fallback a domain narrows and decorates - is not here but in
         hooks.xsl, the open-mode layer below the package stylesheets: that is what lets a package's
         narrower ldh:TreeNode rule outrank it. -->

    <!-- The inverse of the href param above: the resource a row links to, recovered from the row's own
         @href. It lives here, beside the emitter that writes the href, because everything that walks the
         rendered tree - the disclosure handler asking a domain for a node's children, a domain's own
         descent - needs the RESOURCE, while the DOM only carries the navigable form. Reading @href
         directly works right up until a domain decorates it, and then fails as an empty children query
         rather than as an error. A bare href round-trips to itself, so the document tree is unaffected.

         Empty in, empty out, because the rows this is asked about include the loading placeholder,
         which carries no anchor at all. Every caller compares the result with =, which is false
         against an empty sequence - the behaviour reading @href directly used to have for free, and
         which a required cardinality turned into a runtime error mid-walk. -->
    <xsl:function name="ldh:tree-node-uri" as="xs:anyURI?">
        <xsl:param name="href" as="xs:anyURI?"/>
        <xsl:variable name="parsed" select="$href!ldh:parse-href(.)" as="map(xs:string, item()?)?"/>

        <xsl:sequence select="$parsed!xs:anyURI(.('doc-uri') || (if (.('fragment')) then '#' || .('fragment') else ''))"/>
    </xsl:function>

</xsl:stylesheet>
