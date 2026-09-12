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

</xsl:stylesheet>
