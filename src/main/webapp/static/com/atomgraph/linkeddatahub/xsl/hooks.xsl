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
        THE PACKAGE EXTENSION CONTRACT.

        A package stylesheet is composed into the platform's import tree immediately ABOVE this module
        and BELOW everything else (the composers insert the package imports after the last import whose
        href ends in hooks.xsl). Import precedence beats template priority, so that position decides
        what a package can do, without any policy code:

            Web-Client common layer            generic leaf rendering, Web-Client's own page shell
            hooks.xsl  (+ client/hooks.xsl)    the OPEN modes: their declarations and generic fallbacks
            . . . package stylesheets . . .
            common.xsl and the rest            SEALED: structure, typed rules, globals
            the entry stylesheet's includes    highest, as always

        A package may therefore specialise any node in an open mode - its rule outranks the fallback
        here whatever the priorities - and cannot contradict a sealed rule for the same node, since
        that rule outranks the package whatever the package's priority. Redeclaring a sealed global
        variable, named template or function loses the same way.

        An open mode is a LEAF. It renders or contributes for one node and carries no control flow:
        a rule that wins here cannot interrupt a walk, drop a subtree or unhook another mode, because
        the walks live above the packages and merely apply these modes to what they visit.

        The open modes, and what a package rule in each one owes:

            ldh:TreeNode          renders one tree node. The fallback below is a default renderer:
                                  replace it, or decorate it with xsl:next-match (the taxonomy package
                                  narrows the match and forwards expandable/href that way).
            ac:PropertyEditor     renders one resource's property list (this module) or one statement
                                  row (Web-Client, below). Replace or decorate; an empty rule hides.
            ldh:ContentColumn     a slot beside the content body. Nothing to inherit: fill it or not.
            ldh:TreeChildrenLoad  (client only) the children fetch for one node. Replace.
            ldh:RowHook           (client only, see client/hooks.xsl) factories of deferred work for one
                                  rendered row. Contribute; there is nothing to inherit unless another
                                  package claimed the same node.
            the value leaves      (imports/values.xsl, imported below) ac:FormControl, ac:PropertyListValue,
                                  ac:ValueAnnotations, ldh:TypeControl, ac:property-label, ac:object-label,
                                  ac:lang-tag, ac:ResultsTableHeaderCell, xhtml:Anchor/svg:Anchor and the
                                  unnamed mode's property row and value link. A rule for the package's own
                                  property or datatype replaces the generic one, or decorates it with
                                  xsl:next-match; the platform's typed vocabulary modules above the
                                  packages still win for their terms.

        Deliberately sealed: every component mode (ldh:Modal, ldh:DataTable, ldh:PropertyLabel,
        ac:FieldShell...), the ldh:Combobox widget, and the library in imports/default.xsl - keys, global
        params, functions - which a package must not be able to redefine. Web-Client's own leaf and
        shell modes that this platform does not re-declare (ac:FieldShell, ac:SelectShell,
        ac:InlineAlert, xhtml:Option, ac:RDFaAttributes, ac:image) sit below the packages and can still
        be reached; closing that needs Web-Client's default module split into leaves and shells.
    -->

    <!-- the value tier is its own module for size; it is part of this contract and sits below it -->
    <xsl:import href="imports/values.xsl"/>

    <xsl:mode name="ldh:TreeNode"/>
    <xsl:mode name="ac:PropertyEditor"/>

    <!-- a navigation column beside the document's content, for a vocabulary that has a shape worth
         navigating: a taxonomy's concept tree, an ontology's class list. Empty unless something fills
         it, and deep-skip rather than a no-op rule so an unfilled slot costs nothing.

         It is a slot INSIDE the content body rather than a wrapper around it because .content-body
         carries the page gutter and content width, is addressed by rules as a direct child of
         .document-body, and is the containing block the sticky create dock measures its full bleed
         against - so a column emitted around it loses the gutter and breaks the dock, while one
         emitted into it leaves every existing rule matching.

         Whatever fills it is wrapped in .ldh-content-aside by ldh:ContentBody, and that class is what
         the two-column layout keys on. The filler therefore needs no layout class of its own and may
         look like anything - a card, a bare list, a full-height panel - where keying the grid on the
         filler's own class would have meant every package borrowing one component's arrangement to
         use a general slot.

         The active mode is passed in rather than filtered here: which modes a column belongs in is
         the filler's judgement, not the platform's. A taxonomy tree is a reading affordance and
         restricts itself to ReadMode; an editor's class list might well want to stay visible while
         its document's content is being authored. -->
    <xsl:mode name="ldh:ContentColumn" on-no-match="deep-skip"/>

    <!-- TREE NODE -->

    <!-- one tree node: li > .tree-row > disclosure + a.tree-link. The li carries state, the row carries
         the depth indent ramp, and a node with no children takes the inert spacer so labels stay aligned.
         Whether a node can be expanded is the domain's to decide, so it is a parameter rather than a test
         on some predicate this module would have to know about; a domain narrows the match and supplies it
         through xsl:next-match. The rest of the widget is in tree.xsl and client/tree.xsl; only the
         per-node fallback lives here, so that a package's narrower rule outranks it. -->
    <xsl:template match="*[@rdf:about]" mode="ldh:TreeNode">
        <!-- depth is TUNNELLED, expandable is not, and the difference is deliberate: the indent ramp is
             ambient state belonging to the level being rendered, while whether a node opens is a
             per-node decision the domain makes. A domain narrows this template by matching and
             delegating with xsl:next-match, which forwards only the parameters it names - so a plain
             depth parameter silently became 0 in every domain override and the tree rendered flat with
             correct nesting, which is exactly how it shipped. -->
        <xsl:param name="depth" select="0" as="xs:integer" tunnel="yes"/>
        <xsl:param name="expandable" select="false()" as="xs:boolean"/>
        <!-- where the row navigates, which is not always the resource's own URI: a domain whose nodes
             only make sense in one display mode passes an ldh:href() carrying it as a query parameter.
             Per-node rather than tunnelled, so it reaches the nodes a later children fetch renders -
             those are applied from ldh:tree-children-response, which tunnels depth and nothing else. -->
        <xsl:param name="href" select="@rdf:about" as="xs:anyURI"/>

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

                <!-- the title is the resource's own URI, since it states identity rather than where the
                     row goes -->
                <a class="tree-link" href="{$href}" title="{@rdf:about}">
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

    <!-- PROPERTY LIST -->

    <!-- one resource's property list. Overrides Web-Client's rule of the same match so the sort keys
         consume the tunneled $property-metadata and $object-metadata (tunnel params don't cross
         xsl:function boundaries, so 1-arg ac:property-label/ac:object-label can't see them). The
         statement rows it applies are Web-Client's property-level rules, which a package's empty rule
         for its own predicates outranks - that is how a taxonomy hides the hierarchy rows the concept
         tree already shows. -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:PropertyEditor">
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>

        <xsl:variable name="definitions" as="document-node()">
            <xsl:document>
                <dl>
                    <xsl:apply-templates select="*" mode="#current">
                        <xsl:sort select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)" order="ascending" lang="{ac:langs()[1]}"/>
                        <xsl:sort select="ac:lang-rank(.)" order="ascending"/>
                        <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{ac:langs()[1]}"/>
                    </xsl:apply-templates>
                </dl>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$definitions" mode="ac:PropertyGroups"/>
    </xsl:template>

</xsl:stylesheet>
