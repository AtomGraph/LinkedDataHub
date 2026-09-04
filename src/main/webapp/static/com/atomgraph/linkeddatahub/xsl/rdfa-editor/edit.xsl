<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:cm="https://w3id.org/atomgraph/rdfa-editor/content-model#"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Built-in XHTML editor: structured blocks under the #content container, each
    individually contenteditable - block structure is never browser-editable.
    Enter splits, Backspace at block start merges, the toolbar changes block types
    and wraps inline strong/em/a (reusing the annotation machinery), blocks reorder
    via the drag handle. Injected chrome carries data-role="chrome" and is stripped
    by canonical-xhtml.xsl and skipped by the RDFa extractor.

    Undo: native per-block typing undo works (Ctrl/Cmd+Z is never intercepted);
    structural operations (split/merge/convert/move/delete) are not undoable in v1.
-->

    <!-- ................................ helpers ................................ -->

    <!-- the page URI without its fragment: the base for RDFa resolution in the browser -->
    <xsl:function name="rdfae:document-uri" as="xs:string">
        <xsl:sequence select="substring-before(ixsl:location() || '#', '#')"/>
    </xsl:function>

    <!-- editable regions are marked by convention with the rdfa-editor-content class
         (host-page chrome: never serialized - the canonical form strips @class) -->
    <xsl:function name="rdfae:roots" as="element()*">
        <xsl:sequence select="ixsl:page()//*[contains-token(@class, 'rdfa-editor-content')]"/>
    </xsl:function>

    <!-- where rdfae:init-editing appends the toolbar; hosts without a nav element
         override this to point at their own chrome -->
    <xsl:function name="rdfae:toolbar-host" as="element()*">
        <xsl:sequence select="ixsl:page()//nav"/>
    </xsl:function>

    <xsl:function name="rdfae:root-of" as="element()?">
        <xsl:param name="node"/>
        <xsl:sequence select="$node/ancestor-or-self::*[contains-token(@class, 'rdfa-editor-content')][1]"/>
    </xsl:function>

    <!-- the region the user is working in: selection first, then the last focused host -->
    <xsl:function name="rdfae:active-root" as="element()?">
        <xsl:sequence select="(rdfae:anchor-node() ! rdfae:root-of(.),
            ixsl:get(rdfae:editor-state(), 'activeBlock') ! rdfae:root-of(.), rdfae:roots()[1])[1]"/>
    </xsl:function>

    <!-- the top-level block containing a node -->
    <xsl:function name="rdfae:block-of" as="element()?">
        <xsl:param name="node"/>
        <xsl:sequence select="$node/ancestor-or-self::*[parent::*[contains-token(@class, 'rdfa-editor-content')]][1]"/>
    </xsl:function>

    <!-- a block the drag layer picks up: a real %block element - never the
         ephemeral run wrapper, never ephemera or anything inside it, never hr
         (a void element cannot serialize the chrome span) - sitting where the
         model places blocks: a region, a mixed flow container (li, dd, td, th,
         div, figure, figcaption) or a blockquote. Top-level blocks satisfy this
         by construction; every chrome and drag decision routes through here -->
    <xsl:function name="rdfae:draggable-block" as="xs:boolean">
        <xsl:param name="element" as="element()?"/>
        <xsl:sequence select="exists($element
            [cm:block(local-name(.))][not(self::hr)]
            [not(contains-token(@class, 'rdfa-editor-run'))]
            [empty(ancestor-or-self::*[@data-role])]
            [exists(rdfae:root-of(.))]
            [parent::*[contains-token(@class, 'rdfa-editor-content')
                or cm:flow(local-name(.)) or self::blockquote]])"/>
    </xsl:function>

    <!-- the drag handle's owning block: chrome is its first child -->
    <xsl:function name="rdfae:handle-block" as="element()?">
        <xsl:param name="handle" as="element()"/>
        <xsl:sequence select="$handle/parent::*[rdfae:draggable-block(.)]"/>
    </xsl:function>

    <!-- a container admits the dragged kind: the region takes any block (the
         editor contract, deliberately outside content-model.xsl), everything
         else per the DTD -->
    <xsl:function name="rdfae:container-accepts" as="xs:boolean">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="block" as="element()"/>
        <xsl:sequence select="contains-token($container/@class, 'rdfa-editor-content')
            or cm:allows-child(local-name($container), local-name($block))"/>
    </xsl:function>

    <!-- the innermost draggable block under a pointer hit - never the dragged
         block itself or anything inside it (its ancestors are fair targets:
         dropping before/after an ancestor lifts the block out) -->
    <xsl:function name="rdfae:deepest-block-at" as="element()?">
        <xsl:param name="hit"/>
        <xsl:param name="dragged" as="element()?"/>
        <xsl:sequence select="$hit/ancestor-or-self::*[rdfae:draggable-block(.)]
            [empty(ancestor-or-self::* intersect $dragged)][1]"/>
    </xsl:function>

    <!-- the drop level: the innermost block at or above the candidate whose
         container legally accepts the dragged kind - an illegal drop clamps to
         the nearest legal ancestor level instead of being created. The region
         accepts any block, so the climb always terminates -->
    <xsl:function name="rdfae:legal-drop-level" as="element()?">
        <xsl:param name="candidate" as="element()"/>
        <xsl:param name="dragged" as="element()"/>
        <xsl:sequence select="$candidate/ancestor-or-self::*[rdfae:draggable-block(.)]
            [rdfae:container-accepts(parent::*, $dragged)][1]"/>
    </xsl:function>

    <!-- the editable host containing a node (block, li or figcaption) -->
    <xsl:function name="rdfae:host-of" as="element()?">
        <xsl:param name="node"/>
        <xsl:sequence select="$node/ancestor-or-self::*[@contenteditable = 'true'][1]"/>
    </xsl:function>

    <!-- the list item a node sits in (the host may be a nested block inside a
         container item): the unit Tab indent/outdent acts on. Clamped at the
         region root - a host-page li wrapping an embedded region is not ours -->
    <xsl:function name="rdfae:item-of" as="element()?">
        <xsl:param name="node"/>
        <xsl:sequence select="$node/ancestor-or-self::li[exists(rdfae:block-of(.))][1]"/>
    </xsl:function>

    <!-- the first/last editable host within an element (the element itself when it
         is a host): where the caret lands entering a container from either side -->
    <xsl:function name="rdfae:first-host-in" as="element()?">
        <xsl:param name="element" as="element()?"/>
        <xsl:sequence select="($element/descendant-or-self::*[@contenteditable = 'true'])[1]"/>
    </xsl:function>

    <xsl:function name="rdfae:last-host-in" as="element()?">
        <xsl:param name="element" as="element()?"/>
        <xsl:sequence select="($element/descendant-or-self::*[@contenteditable = 'true'])[last()]"/>
    </xsl:function>

    <!-- the merge target for Backspace joins: the last editable host within an
         element, unless it sits inside a composite (table, figure) at or below
         the element, or an object-block island follows it at the element's tail
         (islands hold no hosts, so the lookup would leapfrog them) - composites
         and islands are hard boundaries (B3/B6), so an empty result leaves the
         gesture inert -->
    <xsl:function name="rdfae:merge-host-in" as="element()?">
        <xsl:param name="element" as="element()?"/>
        <xsl:variable name="host" as="element()?" select="rdfae:last-host-in($element)"/>
        <xsl:sequence select="$host
            [empty(ancestor-or-self::*[self::table or self::figure or rdfae:island(.)]
                intersect $element/descendant-or-self::*)]
            [empty($element/descendant-or-self::*[rdfae:island(.)][. &gt;&gt; $host])]"/>
    </xsl:function>

    <!-- keyboard-navigation stops within a region, in document order: the editable
         hosts plus block-level (figure) images plus object-block islands. Neither
         can hold a caret, so each is a navigation island in its own right -
         focused (selected) rather than given a caret - see rdfae:land-forward/
         -backward. Nothing inside an island or an ephemeral subtree is a stop -->
    <xsl:function name="rdfae:nav-targets" as="element()*">
        <xsl:param name="node"/>
        <xsl:sequence select="rdfae:root-of($node)//*[@contenteditable = 'true'
            or (self::img and empty(ancestor::*[@contenteditable = 'true']))
            or rdfae:island(.)]
            [empty(ancestor::*[@data-role])][empty(ancestor::*[rdfae:island(.)])]"/>
    </xsl:function>

    <!-- toolbar actions resolve the block from the selection, falling back to the
         last focused host (the block-type select steals focus - see ixsl:onfocusin) -->
    <xsl:function name="rdfae:current-block" as="element()?">
        <xsl:sequence select="(rdfae:anchor-node() ! rdfae:block-of(.),
            ixsl:get(rdfae:editor-state(), 'activeBlock') ! rdfae:block-of(.))[1]"/>
    </xsl:function>

    <!-- host-based resolution for actions that act on the leaf block the caret
         sits in (block-type convert, quote toggle) rather than the top-level block -->
    <xsl:function name="rdfae:current-host" as="element()?">
        <xsl:sequence select="(rdfae:anchor-node() ! rdfae:host-of(.),
            ixsl:get(rdfae:editor-state(), 'activeBlock') ! rdfae:host-of(.))[1]"/>
    </xsl:function>

    <xsl:function name="rdfae:chrome-count" as="xs:integer">
        <xsl:param name="block" as="element()"/>
        <xsl:sequence select="count($block/*[@data-role = 'chrome'])"/>
    </xsl:function>

    <!-- block text excluding chrome, for emptiness checks -->
    <xsl:function name="rdfae:block-text" as="xs:string">
        <xsl:param name="block" as="element()"/>
        <xsl:sequence select="normalize-space(string-join($block//text()[not(ancestor::*[@data-role])]))"/>
    </xsl:function>

    <!-- true when nothing but chrome precedes the caret inside the host -->
    <xsl:function name="rdfae:at-start" as="xs:boolean">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="range"/>
        <xsl:variable name="probe" select="ixsl:call(ixsl:page(), 'createRange', [])"/>
        <xsl:sequence select="ixsl:call($probe, 'setStart', [ $host, rdfae:chrome-count($host) ])[current-date() lt xs:date('2000-01-01')],
            ixsl:call($probe, 'setEnd', [ ixsl:get($range, 'startContainer'), xs:integer(ixsl:get($range, 'startOffset')) ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="string(ixsl:call($probe, 'toString', [])) = ''"/>
    </xsl:function>

    <!-- true when nothing but a trailing placeholder follows the caret inside the host -->
    <xsl:function name="rdfae:at-end" as="xs:boolean">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="range"/>
        <xsl:variable name="probe" select="ixsl:call(ixsl:page(), 'createRange', [])"/>
        <xsl:sequence select="ixsl:call($probe, 'setEnd', [ $host, xs:integer(ixsl:get($host, 'childNodes.length')) ])[current-date() lt xs:date('2000-01-01')],
            ixsl:call($probe, 'setStart', [ ixsl:get($range, 'endContainer'), xs:integer(ixsl:get($range, 'endOffset')) ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="string(ixsl:call($probe, 'toString', [])) = ''"/>
    </xsl:function>

    <!-- an empty editable host needs a <br> placeholder: without one it has no height
         and no valid caret position (its only child may be non-editable chrome), so
         clicks and typing go nowhere. Dropped again by canonical-xhtml.xsl. Never
         fires on element-only containers (blockquote) - br is inline content -->
    <xsl:template name="rdfae:ensure-placeholder">
        <xsl:param name="host" as="element()"/>
        <xsl:if test="rdfae:block-text($host) = '' and empty($host/br)
                and cm:allows-child(local-name($host), 'br')">
            <xsl:sequence select="ixsl:call($host, 'appendChild',
                [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- outermost RDFa-attributed inline ancestor of a node, strictly below the host -->
    <xsl:function name="rdfae:enclosing-annotation" as="element()?">
        <xsl:param name="node"/>
        <xsl:param name="host" as="element()"/>
        <xsl:sequence select="($node/ancestor-or-self::*[@property or @about or @typeof or @resource]
            intersect $host/descendant::*)[1]"/>
    </xsl:function>

    <xsl:function name="rdfae:selection" as="item()">
        <xsl:sequence select="ixsl:call(ixsl:window(), 'getSelection', [])"/>
    </xsl:function>

    <xsl:function name="rdfae:caret-range" as="item()?">
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:sequence select="if (ixsl:get($selection, 'rangeCount') ge 1)
            then ixsl:call($selection, 'getRangeAt', [ 0 ]) else ()"/>
    </xsl:function>

    <!-- the selection anchor as a node (empty when no range) and its offset (0 then) -->
    <xsl:function name="rdfae:anchor-node" as="node()?">
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:sequence select="if (ixsl:get($selection, 'rangeCount') ge 1)
            then ixsl:get($selection, 'anchorNode') else ()"/>
    </xsl:function>

    <xsl:function name="rdfae:anchor-offset" as="xs:integer">
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:sequence select="if (ixsl:get($selection, 'rangeCount') ge 1)
            then xs:integer(ixsl:get($selection, 'anchorOffset')) else 0"/>
    </xsl:function>

    <xsl:function name="rdfae:element" as="element()">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="ixsl:call(ixsl:page(), 'createElement', [ $name ])"/>
    </xsl:function>

    <!-- the live value of the first input named $name under $scope (a dialog or form) -->
    <xsl:function name="rdfae:input-value" as="xs:string">
        <xsl:param name="scope" as="element()"/>
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="string(ixsl:get(($scope//input[@name = $name])[1], 'value'))"/>
    </xsl:function>

    <!-- focus the host of $node, then collapse the caret there -->
    <xsl:template name="rdfae:focus-caret">
        <xsl:param name="node"/>
        <xsl:param name="offset" as="xs:integer"/>
        <xsl:for-each select="rdfae:host-of($node)">
            <xsl:call-template name="rdfae:focus">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:call-template name="rdfae:place-caret">
            <xsl:with-param name="node" select="$node"/>
            <xsl:with-param name="offset" select="$offset"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="rdfae:place-caret">
        <xsl:param name="node"/>
        <xsl:param name="offset" as="xs:integer"/>
        <xsl:sequence select="ixsl:call(rdfae:selection(), 'collapse',
            [ $node, $offset ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template name="rdfae:focus">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="ixsl:call($element, 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- a block image or object-block island is 'selected' by focusing it (both
         carry tabindex=-1, set at init); the text caret is cleared so only the
         island reads as the current target. Its onfocusin records it as the
         active block, so toolbar/drag act on it (or its figure) just as for a
         focused editable host -->
    <xsl:template name="rdfae:select-island">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="ixsl:call(rdfae:selection(), 'removeAllRanges', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:focus">
            <xsl:with-param name="element" select="$element"/>
        </xsl:call-template>
    </xsl:template>

    <!-- land at the start of the next target (down/right): caret at a host after any
         chrome, focus (selection) at an image -->
    <xsl:template name="rdfae:land-forward">
        <xsl:param name="target" as="element()"/>
        <xsl:choose>
            <xsl:when test="$target/self::img or rdfae:island($target)">
                <xsl:call-template name="rdfae:select-island">
                    <xsl:with-param name="element" select="$target"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:focus-caret">
                    <xsl:with-param name="node" select="$target"/>
                    <xsl:with-param name="offset" select="rdfae:chrome-count($target)"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- land at the end of the previous target (up/left): caret before any trailing
         placeholder <br> at a host, focus (selection) at an image -->
    <xsl:template name="rdfae:land-backward">
        <xsl:param name="target" as="element()"/>
        <xsl:choose>
            <xsl:when test="$target/self::img or rdfae:island($target)">
                <xsl:call-template name="rdfae:select-island">
                    <xsl:with-param name="element" select="$target"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:focus">
                    <xsl:with-param name="element" select="$target"/>
                </xsl:call-template>
                <xsl:call-template name="rdfae:place-caret">
                    <xsl:with-param name="node" select="$target"/>
                    <xsl:with-param name="offset"
                        select="count($target/node()) - count($target/node()[last()][self::br])"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ................................ init ................................ -->

    <xsl:template name="rdfae:init-editing">
        <xsl:for-each select="rdfae:toolbar-host()">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:call-template name="rdfae:render-toolbar"/>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="ixsl:page()//body">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:call-template name="rdfae:render-link-dialog"/>
                <xsl:call-template name="rdfae:render-figure-dialog"/>
                <xsl:call-template name="rdfae:render-table-dialog"/>
                <xsl:call-template name="rdfae:render-slash-menu"/>
                <!-- extension dialogs (opt into teardown via the edit-dialog class) -->
                <xsl:call-template name="rdfae:render-extra-dialogs"/>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="rdfae:roots()">
            <xsl:call-template name="rdfae:init-region">
                <xsl:with-param name="region" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- per-region bring-up, callable for regions rendered after the initial page
         (hosts that open editable regions lazily init each one through this) -->
    <xsl:template name="rdfae:init-region">
        <xsl:param name="region" as="element()"/>

        <!-- the region is the canvas' focusable floor. Only leaf text hosts are
             contenteditable, so the surface between them - sibling margins, the
             handle gutter, a structural container's own box, chrome on a structural
             block - has no focusable ancestor at all, and a press there drops focus
             out of the editor entirely (which hosts read as leaving it, and a press
             on a drag handle cannot preventDefault without killing dragstart). With
             tabindex the region absorbs that focus instead: same idiom as the block
             images and object-block islands in rdfae:init-block, out of the tab
             order, and stripped by the canonical form -->
        <ixsl:set-attribute name="tabindex" select="'-1'" object="$region"/>
        <!-- boundary-normalize invalid host markup (bare text in blockquote,
             blocks inside p, stray inline at region level, ...) before
             editability init; the probe keeps the valid case zero-churn -->
        <xsl:variable name="invalid" as="xs:boolean" select="
            exists($region//*[not(ancestor-or-self::*[@data-role])][not(cm:valid-nesting(.))])
            or exists($region//*[not(ancestor-or-self::*[@data-role])]
                [cm:structural(local-name(.))][text()[normalize-space()]])
            or exists($region/(text()[normalize-space()] | *[cm:inline(local-name(.))]))"/>
        <xsl:if test="$invalid">
            <xsl:variable name="fixed" as="node()*"
                select="cm:wrap-inline-runs(cm:normalize($region/node()), 'p')"/>
            <xsl:for-each select="$region">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:copy-of select="$fixed"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
        <!-- an empty region cannot hold a caret: seed a paragraph (the
             empty-blockquote idiom in rdfae:init-block) -->
        <xsl:if test="empty($region/*[not(@data-role)])">
            <xsl:variable name="p" as="element()" select="rdfae:element('p')"/>
            <xsl:sequence select="ixsl:call($p, 'appendChild', [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call($region, 'appendChild', [ $p ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <xsl:for-each select="$region/*">
            <xsl:call-template name="rdfae:init-block">
                <xsl:with-param name="block" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- editability per the content model, recursively: an element is a text host
         while it allows text and holds no block children; mixed flow containers
         (li, td, dd, ... with blocks) and structural containers (blockquote, lists,
         figure, table) lock their own markup and recurse into their parts. Every
         draggable block - nested ones included - carries its own chrome handle -->

    <xsl:template name="rdfae:init-block">
        <xsl:param name="block" as="element()"/>
        <xsl:variable name="name" as="xs:string" select="local-name($block)"/>

        <xsl:choose>
            <!-- object-block island: an atomic unit - never editable inside, its
                 RDFa definition spans locked, focusable (tabindex, like a block
                 image) and rendered via the rdfae:render-island hook when it has
                 no rendering div yet (idempotent across re-inits and undo) -->
            <xsl:when test="rdfae:island($block)">
                <xsl:for-each select="$block">
                    <ixsl:remove-attribute name="contenteditable"/>
                    <ixsl:set-attribute name="tabindex" select="'-1'"/>
                </xsl:for-each>
                <xsl:sequence select="ixsl:call(ixsl:get($block, 'classList'), 'add',
                    [ 'rdfa-editor-island' ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:if test="empty($block/*[@data-role = 'rendering'])">
                    <xsl:apply-templates select="$block" mode="rdfae:render-island"/>
                </xsl:if>
            </xsl:when>
            <!-- text host: inline-only elements, and flow elements without block
                 children (figure is always composite structure - its parts are the
                 image island, the caption host and any wrapped runs) -->
            <xsl:when test="not($block/self::figure) and (cm:inline-only($name)
                    or (cm:flow($name) and empty($block/*[cm:block(local-name(.))])))">
                <xsl:for-each select="$block">
                    <ixsl:set-attribute name="contenteditable" select="'true'"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- mixed flow container: stray inline runs get an editable wrapper -->
                <xsl:if test="cm:flow($name)">
                    <xsl:call-template name="rdfae:wrap-stray-runs">
                        <xsl:with-param name="container" select="$block"/>
                    </xsl:call-template>
                </xsl:if>
                <!-- an empty blockquote cannot hold a caret itself: seed a paragraph -->
                <xsl:if test="$block/self::blockquote and empty($block/*[not(@data-role)])">
                    <xsl:variable name="p" as="element()" select="rdfae:element('p')"/>
                    <xsl:sequence select="ixsl:call($p, 'appendChild', [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call($block, 'appendChild', [ $p ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
                <xsl:for-each select="$block/*[not(@data-role)][cm:known(local-name(.))]
                        [not(cm:inline(local-name(.)))]">
                    <xsl:call-template name="rdfae:init-block">
                        <xsl:with-param name="block" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        <!-- block images can't hold a caret, so they are made focusable to serve as
             keyboard-navigation islands (tabindex is canonicalization-stripped);
             imgs inside ephemeral subtrees (island renderings) are never targets -->
        <xsl:for-each select="$block/descendant-or-self::img[empty(ancestor::*[@contenteditable = 'true'])]
                [empty(ancestor::*[@data-role])]">
            <ixsl:set-attribute name="tabindex" select="'-1'"/>
        </xsl:for-each>
        <xsl:if test="rdfae:draggable-block($block)">
            <xsl:call-template name="rdfae:inject-chrome">
                <xsl:with-param name="block" select="$block"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- the inverse of rdfae:wrap-stray-runs: when a flow container loses its last
         block child, remaining run wrappers unwrap (adjacent runs merge back) and
         the container becomes a plain text host again -->
    <xsl:template name="rdfae:collapse-container">
        <xsl:param name="container" as="element()"/>
        <xsl:if test="not(rdfae:island($container)) and cm:flow(local-name($container))
                and empty($container/*[not(@data-role)][cm:block(local-name(.)) or self::figcaption]
                    [not(contains-token(@class, 'rdfa-editor-run')
                        and not(@property or @about or @typeof or @resource or @content or @datatype))])">
            <xsl:for-each select="$container/p[contains-token(@class, 'rdfa-editor-run')]
                    [not(@property or @about or @typeof or @resource or @content or @datatype)]">
                <xsl:variable name="wrapper" as="element()" select="."/>
                <xsl:for-each select="1 to xs:integer(ixsl:get($wrapper, 'childNodes.length'))">
                    <xsl:sequence select="ixsl:call($wrapper, 'before', [ ixsl:get($wrapper, 'firstChild') ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
                <xsl:sequence select="ixsl:call($wrapper, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
            <xsl:for-each select="$container">
                <ixsl:set-attribute name="contenteditable" select="'true'"/>
            </xsl:for-each>
            <xsl:call-template name="rdfae:ensure-placeholder">
                <xsl:with-param name="host" select="$container"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- editing-DOM run wrapper: the stray inline runs of a mixed flow container
         are wrapped in p.rdfa-editor-run hosts so they stay editable; the marker
         class is unwrapped again by canonical-xhtml.xsl (C11), so mixed content
         like <li>text<ul>...</ul></li> round-trips intact. Blocks, block images,
         figcaption, ephemera and unknown elements stay put. Structural gestures
         (Enter-split, block-type convert) promote a wrapper to a real paragraph -->
    <xsl:template name="rdfae:wrap-stray-runs">
        <xsl:param name="container" as="element()"/>
        <!-- snapshot the child sequence: wrapping mutates the live list -->
        <xsl:variable name="kids" as="node()*" select="$container/node()"/>
        <xsl:for-each-group select="$kids" group-adjacent="boolean(self::*[cm:block(local-name(.))
                or self::img or self::figcaption or @data-role or not(cm:known(local-name(.)))])">
            <xsl:if test="not(current-grouping-key())
                    and exists(current-group()[self::* or self::text()[normalize-space()]])">
                <xsl:variable name="wrapper" as="element()" select="rdfae:element('p')"/>
                <ixsl:set-attribute name="class" select="'rdfa-editor-run'" object="$wrapper"/>
                <!-- the wrapper IS the run's editable host - callers outside init
                     (insert, indent, outdent) never re-init the container -->
                <ixsl:set-attribute name="contenteditable" select="'true'" object="$wrapper"/>
                <xsl:sequence select="ixsl:call(current-group()[1], 'before', [ $wrapper ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:for-each select="current-group()">
                    <xsl:sequence select="ixsl:call($wrapper, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:template>

    <!-- first-child chrome keeps split ranges (caret to end of block) clean of it -->
    <xsl:template name="rdfae:inject-chrome">
        <xsl:param name="block" as="element()"/>

        <xsl:if test="empty($block/*[@data-role = 'chrome'])">
            <xsl:variable name="chrome" as="element()" select="rdfae:element('span')"/>
            <ixsl:set-attribute name="data-role" select="'chrome'" object="$chrome"/>
            <ixsl:set-attribute name="class" select="'drag-handle'" object="$chrome"/>
            <ixsl:set-attribute name="contenteditable" select="'false'" object="$chrome"/>
            <ixsl:set-attribute name="title" select="'Drag to reorder'" object="$chrome"/>
            <ixsl:set-property name="textContent" select="'&#x283F;'" object="$chrome"/>
            <xsl:sequence select="ixsl:call($block, 'prepend', [ $chrome ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="rdfae:remove-chrome">
        <xsl:param name="block" as="element()"/>
        <xsl:for-each select="$block/*[@data-role = 'chrome']">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- classList.remove leaves an empty @class behind, which would survive into
         undo snapshots and canonical-comparison baselines as class="" noise -->
    <xsl:template name="rdfae:tidy-class">
        <xsl:param name="element" as="element()"/>
        <xsl:for-each select="$element[@class = '']">
            <ixsl:remove-attribute name="class"/>
        </xsl:for-each>
    </xsl:template>

    <!-- chrome convergence: every draggable block carries its handle. Init seeds
         the loaded content; gestures that build nested blocks (split, indent,
         paste, list insert) converge here via rdfae:after-mutation instead of
         each threading its own injection -->
    <xsl:template name="rdfae:ensure-chrome">
        <xsl:param name="scope" as="element()*" select="rdfae:roots()"/>
        <xsl:for-each select="$scope/descendant::*[rdfae:draggable-block(.)]
                [empty(*[@data-role = 'chrome'])]">
            <xsl:call-template name="rdfae:inject-chrome">
                <xsl:with-param name="block" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="rdfae:render-toolbar">
        <div id="edit-toolbar" class="rdfa-editor-ui" role="toolbar" aria-label="Editing toolbar">
            <div class="tb-group" role="group" aria-label="Block">
                <select name="block-type" title="Block type" aria-label="Block type">
                    <option value="p">Paragraph</option>
                    <option value="h1">Heading 1</option>
                    <option value="h2">Heading 2</option>
                    <option value="h3">Heading 3</option>
                    <option value="pre">Preformatted</option>
                </select>
            </div>
            <div class="tb-group" role="group" aria-label="Text">
                <button type="button" class="format-inline" data-element="strong" aria-pressed="false" title="Bold" aria-label="Bold"><strong>B</strong></button>
                <button type="button" class="format-inline" data-element="em" aria-pressed="false" title="Italic" aria-label="Italic"><em>I</em></button>
                <button type="button" class="format-link" aria-pressed="false" title="Link" aria-label="Link">&#x1F517;</button>
            </div>
            <div class="tb-group" role="group" aria-label="Blocks">
                <button type="button" class="insert-block" title="Add paragraph" aria-label="Add paragraph">+ &#xB6;</button>
                <button type="button" class="insert-list" data-list="ul" aria-pressed="false" title="Bulleted list" aria-label="Bulleted list">&#x2022; List</button>
                <button type="button" class="insert-list" data-list="ol" aria-pressed="false" title="Numbered list" aria-label="Numbered list">1. List</button>
                <button type="button" class="format-quote" aria-pressed="false" title="Quote" aria-label="Quote">&#x201C;&#x201D;</button>
            </div>
            <div class="tb-group" role="group" aria-label="Insert">
                <button type="button" class="insert-figure" title="Insert figure" aria-label="Insert figure">&#x1F5BC;</button>
                <button type="button" class="insert-table" title="Insert table" aria-label="Insert table">&#x229E;</button>
                <xsl:call-template name="rdfae:render-extra-insert-buttons"/>
            </div>
            <div class="tb-group table-ops" role="group" aria-label="Table operations">
                <button type="button" class="table-op" data-op="row-above" disabled="disabled" title="Insert row above" aria-label="Insert row above">&#x2191;R</button>
                <button type="button" class="table-op" data-op="row-below" disabled="disabled" title="Insert row below" aria-label="Insert row below">&#x2193;R</button>
                <button type="button" class="table-op" data-op="col-left" disabled="disabled" title="Insert column left" aria-label="Insert column left">&#x2190;C</button>
                <button type="button" class="table-op" data-op="col-right" disabled="disabled" title="Insert column right" aria-label="Insert column right">&#x2192;C</button>
                <button type="button" class="table-op" data-op="del-row" disabled="disabled" title="Delete row" aria-label="Delete row">&#x2212;R</button>
                <button type="button" class="table-op" data-op="del-col" disabled="disabled" title="Delete column" aria-label="Delete column">&#x2212;C</button>
            </div>
            <div class="tb-group" role="group" aria-label="Block actions">
                <button type="button" class="delete-block" title="Delete block" aria-label="Delete block">&#x2715;</button>
            </div>
            <div class="tb-group" role="group" aria-label="View">
                <button type="button" id="toc-toggle" title="Table of contents" aria-label="Table of contents">&#x2630;</button>
                <button type="button" id="inspector-toggle" title="Properties" aria-label="Subject properties">&#x24C5;</button>
                <button type="button" id="find-open" title="Find and replace" aria-label="Find and replace">&#x1F50D;</button>
                <button type="button" id="view-source" title="Canonical XHTML+RDFa" aria-label="View canonical source">Source</button>
            </div>
        </div>
    </xsl:template>

    <!-- caret-contextual toolbar state, riding rdfae:update-breadcrumb (the single
         caret-awareness choke point) alongside rdfae:sync-table-toolbar: the inline
         toggles reflect the elements the caret sits inside (strong/em/link/list) and
         the block-type select follows the current convertible block kind -->
    <xsl:template name="rdfae:sync-format-toolbar">
        <xsl:variable name="leaf" as="element()?" select="ixsl:get(rdfae:editor-state(), 'breadcrumbLeaf')"/>
        <xsl:variable name="host" as="element()?" select="$leaf ! rdfae:host-of(.)"/>
        <!-- inline element toggles: strong / em (mirrors the format-inline click handler) -->
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//button[@data-element]">
            <xsl:variable name="name" as="xs:string" select="string(@data-element)"/>
            <xsl:variable name="on" as="xs:boolean" select="exists($host)
                and exists($leaf/ancestor-or-self::*[local-name() = $name] intersect $host/descendant::*)"/>
            <ixsl:set-attribute name="aria-pressed" select="if ($on) then 'true' else 'false'" object="."/>
        </xsl:for-each>
        <!-- link toggle -->
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//button[contains-token(@class, 'format-link')]">
            <xsl:variable name="on" as="xs:boolean" select="exists($host)
                and exists($leaf/ancestor-or-self::a intersect $host/descendant::*)"/>
            <ixsl:set-attribute name="aria-pressed" select="if ($on) then 'true' else 'false'" object="."/>
        </xsl:for-each>
        <!-- list toggles: only the innermost enclosing list lights (never both) -->
        <xsl:variable name="list" as="element()?" select="$leaf/ancestor-or-self::*[self::ul or self::ol][1]"/>
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//button[@data-list]">
            <xsl:variable name="on" as="xs:boolean" select="exists($list) and local-name($list) = string(@data-list)"/>
            <ixsl:set-attribute name="aria-pressed" select="if ($on) then 'true' else 'false'" object="."/>
        </xsl:for-each>
        <!-- quote toggle: pressed inside a blockquote (of this region - host-page
             quotes around an embedded region don't count), disabled where neither
             pressed nor a valid wrap target exists -->
        <xsl:variable name="in-quote" as="xs:boolean"
            select="exists($host) and exists($leaf/ancestor-or-self::blockquote[exists(rdfae:block-of(.))])"/>
        <xsl:variable name="wrappable" as="xs:boolean" select="exists($host[cm:block(local-name(.))]
            [parent::*[contains-token(@class, 'rdfa-editor-content')]
                or cm:allows-child(local-name(parent::*), 'blockquote')])"/>
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//button[contains-token(@class, 'format-quote')]">
            <ixsl:set-attribute name="aria-pressed" select="if ($in-quote) then 'true' else 'false'" object="."/>
            <ixsl:set-property name="disabled" select="not($in-quote or $wrappable)" object="."/>
        </xsl:for-each>
        <!-- block-type select follows the convertible HOST (a quote paragraph reads
             as Paragraph); disabled on non-convertible hosts (li, cells, captions) -->
        <xsl:variable name="convertible" as="element()?"
            select="$host[self::p or self::h1 or self::h2 or self::h3 or self::pre]"/>
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//select[@name = 'block-type']">
            <ixsl:set-property name="disabled" select="empty($convertible)" object="."/>
            <xsl:for-each select="$convertible">
                <xsl:variable name="kind" as="xs:string" select="local-name(.)"/>
                <xsl:for-each select="id('edit-toolbar', ixsl:page())//select[@name = 'block-type']">
                    <ixsl:set-property name="value" select="$kind" object="."/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ keyboard ................................ -->

    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onkeydown">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="key" as="xs:string" select="string(ixsl:get($event, 'key'))"/>
        <xsl:variable name="chord" as="xs:boolean"
            select="(ixsl:get($event, 'ctrlKey') or ixsl:get($event, 'metaKey')) and not(ixsl:get($event, 'altKey'))"/>
        <xsl:if test="exists(rdfae:block-of(.)) and not(ixsl:get($event, 'isComposing'))">
            <xsl:choose>
                <!-- native undo is replaced by the snapshot history: intercept even on an empty stack -->
                <xsl:when test="$chord and lower-case($key) = 'z' and not(ixsl:get($event, 'shiftKey'))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:apply-undo"/>
                </xsl:when>
                <xsl:when test="$chord and ((lower-case($key) = 'z' and ixsl:get($event, 'shiftKey'))
                        or (lower-case($key) = 'y' and not(ixsl:get($event, 'shiftKey'))))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:apply-redo"/>
                </xsl:when>
                <!-- Ctrl/Cmd+A escalates Docs-style: native select-all already scopes
                     to the host (stage 1); once the host is fully selected (or the
                     selection already spans hosts) the whole region is selected
                     instead - never the host page -->
                <xsl:when test="$chord and lower-case($key) = 'a' and not(ixsl:get($event, 'shiftKey'))">
                    <xsl:variable name="range" select="rdfae:caret-range()"/>
                    <xsl:if test="rdfae:selection-crosses-hosts()
                            or (exists($range) and rdfae:host-fully-selected(., $range))">
                        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:for-each select="rdfae:root-of(.)">
                            <xsl:call-template name="rdfae:select-region">
                                <xsl:with-param name="region" select="."/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:when>
                <!-- other ctrl/meta chords stay native (copy, paste, browser find) -->
                <xsl:when test="ixsl:get($event, 'ctrlKey') or ixsl:get($event, 'metaKey')"/>
                <!-- Escape closes the annotation overlay / dialogs even while focus
                     remains in the content (their own keydown templates only fire
                     when focus is inside them) -->
                <xsl:when test="$key = 'Escape'">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:hide-overlay"/>
                    <xsl:call-template name="rdfae:hide-dialogs"/>
                </xsl:when>
                <!-- Shift+Up/Down extend the selection block-granularly beyond the
                     host: native extension clamps at host edges, and a cross-host
                     selection cannot be extended natively at all; within the host
                     (focus not at the facing edge) they stay native line-wise -->
                <xsl:when test="ixsl:get($event, 'shiftKey') and not(ixsl:get($event, 'altKey'))
                        and $key = ('ArrowUp', 'ArrowDown')
                        and rdfae:shift-arrow-extends(., if ($key = 'ArrowUp') then 'up' else 'down')">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:extend-selection-block-wise">
                        <xsl:with-param name="direction" select="if ($key = 'ArrowUp') then 'up' else 'down'"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- a selection spanning hosts: Backspace/Delete run the editor's own
                     delete (the browser refuses to edit across host boundaries), a
                     printable character replaces the selection (delete, then the
                     character lands at the machine-placed caret), Enter/Tab are
                     suppressed so the selection cannot be half-edited; plain arrows
                     stay native (they collapse it) and the chord cases above keep
                     copy/cut native (canonical copy intercepts at the event level) -->
                <xsl:when test="rdfae:selection-crosses-hosts()">
                    <xsl:choose>
                        <xsl:when test="$key = ('Backspace', 'Delete')">
                            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:call-template name="rdfae:delete-cross-host-selection"/>
                        </xsl:when>
                        <xsl:when test="string-length($key) = 1">
                            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:call-template name="rdfae:delete-cross-host-selection"/>
                            <xsl:call-template name="rdfae:insert-text-at-caret">
                                <xsl:with-param name="text" select="$key"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:after-mutation"/>
                        </xsl:when>
                        <xsl:when test="$key = ('Enter', 'Tab')">
                            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:when>
                <!-- Alt+Arrow moves the current block (keyboard alternative to drag-and-drop) -->
                <xsl:when test="ixsl:get($event, 'altKey') and $key = ('ArrowUp', 'ArrowDown')">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:variable name="host" as="element()" select="."/>
                    <xsl:variable name="block" as="element()?" select="rdfae:block-of(.)"/>
                    <xsl:for-each select="if ($key = 'ArrowUp')
                            then $block/preceding-sibling::*[1] else $block/following-sibling::*[1]">
                        <xsl:call-template name="rdfae:push-undo"/>
                        <xsl:sequence select="ixsl:call(., if ($key = 'ArrowUp') then 'before' else 'after',
                            [ $block ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    <!-- moving the focused block blurs it -->
                    <xsl:call-template name="rdfae:focus">
                        <xsl:with-param name="element" select="$host"/>
                    </xsl:call-template>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:when>
                <!-- Tab indents/outdents list items and walks table cells; the
                     innermost context wins (li inside a cell indents, a table
                     nested in an item traverses); native Tab everywhere else -->
                <xsl:when test="$key = 'Tab'">
                    <xsl:variable name="item" as="element()?" select="rdfae:item-of(.)"/>
                    <!-- clamped at the region root: a host-page cell wrapping an
                         embedded region must never be traversed or grown -->
                    <xsl:variable name="cell" as="element()?"
                        select="ancestor-or-self::*[self::td or self::th or self::caption]
                            [exists(rdfae:block-of(.))][1]"/>
                    <xsl:choose>
                        <xsl:when test="exists($item) and (empty($cell)
                                or exists($item/ancestor::* intersect $cell))">
                            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:choose>
                                <xsl:when test="ixsl:get($event, 'shiftKey')">
                                    <xsl:call-template name="rdfae:list-outdent">
                                        <xsl:with-param name="item" select="$item"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="rdfae:list-indent">
                                        <xsl:with-param name="item" select="$item"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="exists($cell)">
                            <xsl:call-template name="rdfae:table-tab">
                                <xsl:with-param name="host" select="$cell"/>
                                <xsl:with-param name="event" select="$event"/>
                                <xsl:with-param name="shift" select="ixsl:get($event, 'shiftKey') = true()"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:when>
                <!-- arrow keys cross block boundaries: each block is its own
                     contenteditable island, so the browser stops at its edges.
                     Block-level (figure) images are non-editable but still navigable -
                     rdfae:nav-targets includes them and rdfae:land-* selects them
                     (focus) rather than placing a caret -->
                <xsl:when test="$key = ('ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft')
                        and not(ixsl:get($event, 'shiftKey')) and not(ixsl:get($event, 'altKey'))">
                    <xsl:variable name="selection" select="rdfae:selection()"/>
                    <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1 and ixsl:get($selection, 'isCollapsed')">
                        <xsl:variable name="range" select="rdfae:caret-range()"/>
                        <xsl:variable name="host" as="element()" select="."/>
                        <xsl:variable name="targets" as="element()*" select="rdfae:nav-targets(.)"/>
                        <xsl:choose>
                            <xsl:when test="$key = ('ArrowDown', 'ArrowRight') and rdfae:at-end($host, $range)">
                                <xsl:for-each select="($targets[. &gt;&gt; $host])[1]">
                                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                                    <xsl:call-template name="rdfae:land-forward">
                                        <xsl:with-param name="target" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="$key = ('ArrowUp', 'ArrowLeft') and rdfae:at-start($host, $range)">
                                <xsl:for-each select="($targets[. &lt;&lt; $host])[last()]">
                                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                                    <xsl:call-template name="rdfae:land-backward">
                                        <xsl:with-param name="target" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$key = ('Enter', 'Backspace')">
                    <xsl:variable name="selection" select="rdfae:selection()"/>
                    <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1">
                        <xsl:variable name="range" select="rdfae:caret-range()"/>
                        <xsl:choose>
                            <xsl:when test="$key = 'Enter'">
                                <xsl:call-template name="rdfae:handle-enter">
                                    <xsl:with-param name="host" select="."/>
                                    <xsl:with-param name="event" select="$event"/>
                                    <xsl:with-param name="range" select="$range"/>
                                </xsl:call-template>
                            </xsl:when>
                            <!-- Backspace intercepts only collapsed carets; everything else stays native (B1) -->
                            <xsl:when test="ixsl:get($selection, 'isCollapsed')">
                                <xsl:call-template name="rdfae:handle-backspace">
                                    <xsl:with-param name="host" select="."/>
                                    <xsl:with-param name="event" select="$event"/>
                                    <xsl:with-param name="range" select="$range"/>
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- undo chords also work with focus on the page background, and a mouse sweep
         from the background leaves focus there: the cross-host gestures must fire
         from body too. Plain Ctrl+A without a region-engaging selection stays
         native - whole-page select-all is never hijacked on a host page -->
    <xsl:template match="body" mode="ixsl:onkeydown">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="key" as="xs:string" select="string(ixsl:get($event, 'key'))"/>
        <xsl:variable name="chord" as="xs:boolean"
            select="(ixsl:get($event, 'ctrlKey') or ixsl:get($event, 'metaKey')) and not(ixsl:get($event, 'altKey'))"/>
        <xsl:if test="ixsl:call(ixsl:get($event, 'target'), 'isSameNode', [ . ])">
            <xsl:choose>
                <xsl:when test="$chord and lower-case($key) = 'z' and not(ixsl:get($event, 'shiftKey'))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:apply-undo"/>
                </xsl:when>
                <xsl:when test="$chord and ((lower-case($key) = 'z' and ixsl:get($event, 'shiftKey'))
                        or (lower-case($key) = 'y' and not(ixsl:get($event, 'shiftKey'))))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:apply-redo"/>
                </xsl:when>
                <!-- Docs-style: select-all from the page background selects editor
                     content, never the page - the swept region when a cross-host
                     selection exists, else the active region (selection anchor,
                     last focused host, first region). Native page select-all only
                     when no editable region exists at all -->
                <xsl:when test="$chord and lower-case($key) = 'a' and not(ixsl:get($event, 'shiftKey'))">
                    <xsl:variable name="range" select="rdfae:caret-range()"/>
                    <xsl:variable name="region" as="element()?" select="
                        if (rdfae:selection-crosses-hosts())
                        then (rdfae:root-of(ixsl:get($range, 'startContainer')),
                            rdfae:roots()[ixsl:call($range, 'intersectsNode', [ . ])])[1]
                        else rdfae:active-root()"/>
                    <xsl:for-each select="$region">
                        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:call-template name="rdfae:select-region">
                            <xsl:with-param name="region" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="not($chord) and $key = ('Backspace', 'Delete')
                        and rdfae:selection-crosses-hosts()">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:delete-cross-host-selection"/>
                </xsl:when>
                <!-- type-to-replace works from the page background too: the delete
                     machine focuses a host, the character lands at its caret -->
                <xsl:when test="not($chord) and string-length($key) = 1
                        and rdfae:selection-crosses-hosts()">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:delete-cross-host-selection"/>
                    <xsl:call-template name="rdfae:insert-text-at-caret">
                        <xsl:with-param name="text" select="$key"/>
                    </xsl:call-template>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:when>
                <!-- a background-ended sweep leaves focus on body: Shift+Up/Down keep
                     extending the cross-host selection block-wise from here too -->
                <xsl:when test="not($chord) and ixsl:get($event, 'shiftKey') and not(ixsl:get($event, 'altKey'))
                        and $key = ('ArrowUp', 'ArrowDown') and rdfae:selection-crosses-hosts()">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:extend-selection-block-wise">
                        <xsl:with-param name="direction" select="if ($key = 'ArrowUp') then 'up' else 'down'"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- a focused block image or object-block island is a navigation island: plain
         arrow keys move to the adjacent target (island <-> caret), matching
         text-block crossing, and Backspace/Delete removes it (an image goes with
         its figure). Since an island can't hold a caret, these keys are the only
         way keyboard editing reaches or leaves it -->
    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')]//*[self::img or rdfae:island(.)]" mode="ixsl:onkeydown">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="key" as="xs:string" select="string(ixsl:get($event, 'key'))"/>
        <!-- Ctrl/Cmd+A on a selected island selects its whole region: the island is
             its own fully-selected unit, so this is stage 2 directly -->
        <xsl:if test="empty(ancestor::*[@contenteditable = 'true'])
                and (ixsl:get($event, 'ctrlKey') or ixsl:get($event, 'metaKey'))
                and not(ixsl:get($event, 'altKey')) and not(ixsl:get($event, 'shiftKey'))
                and lower-case($key) = 'a'">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:for-each select="rdfae:root-of(.)">
                <xsl:call-template name="rdfae:select-region">
                    <xsl:with-param name="region" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        <!-- undo/redo chords work with focus on a selected island too - e.g. right
             after an insert or B3 selects one (native undo is replaced globally) -->
        <xsl:if test="empty(ancestor::*[@contenteditable = 'true'])
                and (ixsl:get($event, 'ctrlKey') or ixsl:get($event, 'metaKey'))
                and not(ixsl:get($event, 'altKey'))">
            <xsl:choose>
                <xsl:when test="lower-case($key) = 'z' and not(ixsl:get($event, 'shiftKey'))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:apply-undo"/>
                </xsl:when>
                <xsl:when test="(lower-case($key) = 'z' and ixsl:get($event, 'shiftKey'))
                        or (lower-case($key) = 'y' and not(ixsl:get($event, 'shiftKey')))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:apply-redo"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="empty(ancestor::*[@contenteditable = 'true'])
                and not(ixsl:get($event, 'shiftKey')) and not(ixsl:get($event, 'altKey'))
                and not(ixsl:get($event, 'ctrlKey')) and not(ixsl:get($event, 'metaKey'))">
            <xsl:variable name="island" as="element()" select="."/>
            <xsl:variable name="targets" as="element()*" select="rdfae:nav-targets(.)"/>
            <xsl:choose>
                <xsl:when test="$key = ('ArrowDown', 'ArrowRight')">
                    <xsl:for-each select="($targets[. &gt;&gt; $island])[1]">
                        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:call-template name="rdfae:land-forward">
                            <xsl:with-param name="target" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$key = ('ArrowUp', 'ArrowLeft')">
                    <xsl:for-each select="($targets[. &lt;&lt; $island])[last()]">
                        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                        <xsl:call-template name="rdfae:land-backward">
                            <xsl:with-param name="target" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <!-- a selected image is deleted whole with its FIGURE when it has one,
                     an object block deletes itself (no smaller unit, no confirm - it
                     was explicitly selected and undo covers accidents); a bare island
                     in a mixed container is deleted alone, never its whole list/table.
                     The caret lands on the previous target for Backspace, the next
                     for Delete -->
                <!-- with a cross-host selection painted (Ctrl+A from the island), the
                     selection wins over the island: the delete machine runs instead -->
                <xsl:when test="$key = ('Backspace', 'Delete') and rdfae:selection-crosses-hosts()">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:delete-cross-host-selection"/>
                </xsl:when>
                <xsl:when test="$key = ('Backspace', 'Delete')">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:variable name="victim" as="element()"
                        select="($island/ancestor-or-self::figure[exists(rdfae:block-of(.))][1], $island)[1]"/>
                    <xsl:variable name="container" as="element()?" select="$victim/parent::*"/>
                    <xsl:variable name="outside" as="element()*"
                        select="$targets[empty(. intersect $victim/descendant-or-self::*)]"/>
                    <xsl:variable name="prev" as="element()?" select="($outside[. &lt;&lt; $victim])[last()]"/>
                    <xsl:variable name="next" as="element()?" select="($outside[. &gt;&gt; $victim])[1]"/>
                    <xsl:call-template name="rdfae:push-undo"/>
                    <xsl:sequence select="ixsl:call($victim, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
                    <!-- a mixed container that just lost its only nested block
                         becomes a plain text host again -->
                    <xsl:for-each select="$container[not(contains-token(@class, 'rdfa-editor-content'))]">
                        <xsl:call-template name="rdfae:collapse-container">
                            <xsl:with-param name="container" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <xsl:for-each select="if ($key = 'Backspace') then ($prev, $next)[1] else ($next, $prev)[1]">
                        <xsl:choose>
                            <xsl:when test=". is $prev">
                                <xsl:call-template name="rdfae:land-backward">
                                    <xsl:with-param name="target" select="."/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="rdfae:land-forward">
                                    <xsl:with-param name="target" select="."/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- a focused block image or object-block island becomes the active block, so
         toolbar/breadcrumb resolve to it (or its figure) just as they do for a
         focused editable host (mirrors the contenteditable onfocusin above) -->
    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')]//*[self::img or rdfae:island(.)]" mode="ixsl:onfocusin">
        <xsl:if test="empty(ancestor::*[@contenteditable = 'true'])">
            <ixsl:set-property name="activeBlock" select="." object="rdfae:editor-state()"/>
            <xsl:call-template name="rdfae:update-breadcrumb"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="rdfae:handle-enter">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="event"/>
        <xsl:param name="range"/>

        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:push-undo">
            <xsl:with-param name="host" select="$host"/>
        </xsl:call-template>
        <xsl:if test="not(ixsl:get($range, 'collapsed'))">
            <xsl:sequence select="ixsl:call($range, 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>

        <xsl:choose>
            <!-- E1: Shift+Enter = line break -->
            <xsl:when test="ixsl:get($event, 'shiftKey')">
                <xsl:call-template name="rdfae:insert-at-caret">
                    <xsl:with-param name="node" select="rdfae:element('br')"/>
                    <xsl:with-param name="range" select="$range"/>
                </xsl:call-template>
            </xsl:when>
            <!-- E2: line structure inside pre is text -->
            <xsl:when test="$host/self::pre">
                <xsl:call-template name="rdfae:insert-at-caret">
                    <xsl:with-param name="node" select="ixsl:call(ixsl:page(), 'createTextNode', [ '&#10;' ])"/>
                    <xsl:with-param name="range" select="$range"/>
                </xsl:call-template>
            </xsl:when>
            <!-- E2b: Enter in a table cell steps down the column, growing the table -->
            <xsl:when test="$host/self::td or $host/self::th">
                <xsl:call-template name="rdfae:table-enter">
                    <xsl:with-param name="host" select="$host"/>
                </xsl:call-template>
            </xsl:when>
            <!-- E4a: Enter on the empty last item of a NESTED list outdents one
                 level (progressive: each press lifts it until it reaches the top) -->
            <xsl:when test="$host/self::li and rdfae:block-text($host) = ''
                    and empty($host/following-sibling::li) and exists($host/parent::*/parent::li)">
                <xsl:call-template name="rdfae:list-outdent">
                    <xsl:with-param name="item" select="$host"/>
                </xsl:call-template>
            </xsl:when>
            <!-- E4b: Enter on the empty last item of a list exits it - the paragraph
                 anchors after the list BEFORE anything is removed (a sole-item list
                 disappears with it), so the exit lands where the list was: at the
                 region for top-level lists, inside the cell/quote for nested ones -->
            <xsl:when test="$host/self::li and rdfae:block-text($host) = '' and empty($host/following-sibling::li)">
                <xsl:variable name="list" as="element()" select="$host/parent::*"/>
                <xsl:call-template name="rdfae:insert-empty-paragraph">
                    <xsl:with-param name="after" select="$list"/>
                </xsl:call-template>
                <xsl:sequence select="ixsl:call($host, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:if test="empty($list/li)">
                    <xsl:sequence select="ixsl:call($list, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:when>
            <!-- E6: Enter in a figure/table caption starts a paragraph after the
                 figure/table itself - which may be nested inside an item or cell -->
            <xsl:when test="$host/self::figcaption or $host/self::caption">
                <xsl:call-template name="rdfae:insert-empty-paragraph">
                    <xsl:with-param name="after" select="$host/parent::*"/>
                </xsl:call-template>
            </xsl:when>
            <!-- E3/E5/E7/E8: split, never through an annotation (the split point moves
                 behind the outermost RDFa-attributed ancestor so the graph is unchanged) -->
            <xsl:otherwise>
                <xsl:for-each select="rdfae:enclosing-annotation(ixsl:get($range, 'startContainer'), $host)">
                    <xsl:sequence select="ixsl:call($range, 'setStartAfter', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call($range, 'collapse', [ true() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
                <xsl:call-template name="rdfae:split-block">
                    <xsl:with-param name="host" select="$host"/>
                    <xsl:with-param name="range" select="$range"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <!-- a fresh empty paragraph after a block: the <br> is the browser-standard caret
         placeholder for empty editable elements (dropped again by canonical-xhtml.xsl) -->
    <xsl:template name="rdfae:insert-empty-paragraph">
        <xsl:param name="after" as="element()?"/>

        <xsl:variable name="p" as="element()" select="rdfae:element('p')"/>
        <xsl:sequence select="ixsl:call($p, 'appendChild', [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:choose>
            <xsl:when test="exists($after)">
                <xsl:sequence select="ixsl:call($after, 'after', [ $p ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="rdfae:active-root()">
                    <xsl:sequence select="ixsl:call(., 'appendChild', [ $p ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$p"/>
        <xsl:if test="$p/parent::*[contains-token(@class, 'rdfa-editor-content')]">
            <xsl:call-template name="rdfae:inject-chrome">
                <xsl:with-param name="block" select="$p"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:call-template name="rdfae:focus-caret">
    <xsl:with-param name="node" select="$p"/>
    <xsl:with-param name="offset" select="rdfae:chrome-count($p)"/>
</xsl:call-template>
    </xsl:template>

    <xsl:template name="rdfae:insert-at-caret">
        <xsl:param name="node"/>
        <xsl:param name="range"/>

        <xsl:sequence select="ixsl:call($range, 'insertNode', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:place-caret">
            <xsl:with-param name="node" select="ixsl:get($node, 'parentNode')"/>
            <xsl:with-param name="offset" select="count($node/preceding-sibling::node()) + 1"/>
        </xsl:call-template>
    </xsl:template>

    <!-- move everything from the caret to the end of the host into a fresh sibling
         of the same name; inline elements wholly after the caret move intact.
         Splitting a run wrapper promotes it: the marker class comes off the first
         half (the fresh second half never has it) - a structural edit makes both
         halves real paragraphs -->
    <xsl:template name="rdfae:split-block">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="range"/>

        <xsl:if test="contains-token($host/@class, 'rdfa-editor-run')">
            <xsl:sequence select="ixsl:call(ixsl:get($host, 'classList'), 'remove',
                [ 'rdfa-editor-run' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <xsl:sequence select="ixsl:call($range, 'setEnd', [ $host, xs:integer(ixsl:get($host, 'childNodes.length')) ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="fragment" select="ixsl:call($range, 'extractContents', [])"/>
        <xsl:variable name="new" as="element()" select="ixsl:call(ixsl:page(), 'createElement', [ local-name($host) ])"/>
        <xsl:sequence select="ixsl:call($new, 'appendChild', [ $fragment ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call($host, 'after', [ $new ])[current-date() lt xs:date('2000-01-01')]"/>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$new"/>
        <!-- chrome is a top-level affordance: nested hosts (li, quote paragraphs,
             cell blocks) never carry a drag handle -->
        <xsl:if test="$host/parent::*[contains-token(@class, 'rdfa-editor-content')]">
            <xsl:call-template name="rdfae:inject-chrome">
                <xsl:with-param name="block" select="$new"/>
            </xsl:call-template>
        </xsl:if>
        <!-- a split at either extreme leaves one empty half -->
        <xsl:call-template name="rdfae:ensure-placeholder">
            <xsl:with-param name="host" select="$host"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:ensure-placeholder">
            <xsl:with-param name="host" select="$new"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:focus-caret">
    <xsl:with-param name="node" select="$new"/>
    <xsl:with-param name="offset" select="rdfae:chrome-count($new)"/>
</xsl:call-template>
    </xsl:template>

    <xsl:template name="rdfae:handle-backspace">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="event"/>
        <xsl:param name="range"/>

        <!-- B1: anywhere but the block start stays native -->
        <xsl:if test="rdfae:at-start($host, $range)">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:choose>
                <!-- B4: a list item merges into the visually preceding line - the
                     deepest last host of the previous item (which may be a container
                     holding a nested list); a previous item ending in a composite
                     is a hard boundary (merge-host-in returns nothing - inert) -->
                <xsl:when test="$host/self::li and exists($host/preceding-sibling::li)">
                    <xsl:for-each select="rdfae:merge-host-in($host/preceding-sibling::li[1])">
                        <xsl:call-template name="rdfae:push-undo">
                            <xsl:with-param name="host" select="$host"/>
                        </xsl:call-template>
                        <xsl:call-template name="rdfae:merge-into-previous">
                            <xsl:with-param name="host" select="$host"/>
                            <xsl:with-param name="prev" select="."/>
                        </xsl:call-template>
                        <xsl:call-template name="rdfae:after-mutation"/>
                    </xsl:for-each>
                </xsl:when>
                <!-- B4b: the first item of a NESTED list outdents (mirrors Shift+Tab) -->
                <xsl:when test="$host/self::li and exists($host/parent::*/parent::li)">
                    <xsl:call-template name="rdfae:list-outdent">
                        <xsl:with-param name="item" select="$host"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- B4c: the first item of a list nested in a container (cell,
                     quote, dd) merges into the preceding line inside it; the
                     emptied list goes and the container collapses back to a text
                     host - composites (table, figure) stay hard boundaries -->
                <xsl:when test="$host/self::li
                        and $host/parent::*/parent::*[not(contains-token(@class, 'rdfa-editor-content'))]
                        and exists(rdfae:merge-host-in($host/parent::*/preceding-sibling::*[not(@data-role)][1]))">
                    <xsl:variable name="list" as="element()" select="$host/parent::*"/>
                    <xsl:variable name="container" as="element()" select="$list/parent::*"/>
                    <!-- the caret target must survive the merge AND the collapse
                         unwrap (text-node references ride through both moves) -->
                    <xsl:variable name="first-text" select="($host//text()[not(ancestor::*[@data-role])])[1]"/>
                    <xsl:call-template name="rdfae:push-undo">
                        <xsl:with-param name="host" select="$host"/>
                    </xsl:call-template>
                    <xsl:call-template name="rdfae:merge-into-previous">
                        <xsl:with-param name="host" select="$host"/>
                        <xsl:with-param name="prev" select="rdfae:merge-host-in(
                            $list/preceding-sibling::*[not(@data-role)][1])"/>
                    </xsl:call-template>
                    <xsl:if test="empty($list/li)">
                        <xsl:sequence select="ixsl:call($list, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>
                    <xsl:call-template name="rdfae:collapse-container">
                        <xsl:with-param name="container" select="$container"/>
                    </xsl:call-template>
                    <xsl:choose>
                        <xsl:when test="exists($first-text)">
                            <xsl:call-template name="rdfae:focus-caret">
                                <xsl:with-param name="node" select="$first-text"/>
                                <xsl:with-param name="offset" select="0"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="rdfae:last-host-in($container)">
                                <xsl:call-template name="rdfae:focus-caret">
                                    <xsl:with-param name="node" select="."/>
                                    <xsl:with-param name="offset"
                                        select="count(node()) - count(node()[last()][self::br])"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:when>
                <!-- B5: the first item of a top-level list (or of a list with
                     nothing mergeable before it) is inert -->
                <xsl:when test="$host/self::li"/>
                <!-- B6: cells, captions and pre absorb Backspace-at-start (never merge away) -->
                <xsl:when test="$host/self::figcaption or $host/self::pre
                        or $host/self::td or $host/self::th or $host/self::caption"/>
                <xsl:otherwise>
                    <xsl:variable name="prev" as="element()?" select="$host/preceding-sibling::*[1]"/>
                    <xsl:choose>
                        <!-- B2: text blocks merge -->
                        <xsl:when test="$prev[self::p or self::h1 or self::h2 or self::h3]">
                            <xsl:call-template name="rdfae:push-undo">
                                <xsl:with-param name="host" select="$host"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:merge-into-previous">
                                <xsl:with-param name="host" select="$host"/>
                                <xsl:with-param name="prev" select="$prev"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:after-mutation"/>
                        </xsl:when>
                        <!-- B2b: a preceding non-composite container (blockquote,
                             list) merges into its last editable host, never into
                             the container itself (bare text there would be invalid;
                             tables and figures stay hard boundaries - B3 - even
                             nested at the container's tail: merge-host-in) -->
                        <xsl:when test="$prev[self::blockquote or self::ul or self::ol or self::dl]">
                            <xsl:for-each select="rdfae:merge-host-in($prev)">
                                <xsl:call-template name="rdfae:push-undo">
                                    <xsl:with-param name="host" select="$host"/>
                                </xsl:call-template>
                                <xsl:call-template name="rdfae:merge-into-previous">
                                    <xsl:with-param name="host" select="$host"/>
                                    <xsl:with-param name="prev" select="."/>
                                </xsl:call-template>
                                <xsl:call-template name="rdfae:after-mutation"/>
                            </xsl:for-each>
                        </xsl:when>
                        <!-- B7: the first block of a blockquote exits upward - it
                             moves before the quote; an emptied quote is removed -->
                        <xsl:when test="empty($prev[not(@data-role)]) and $host/parent::blockquote">
                            <xsl:variable name="quote" as="element()" select="$host/parent::blockquote"/>
                            <xsl:call-template name="rdfae:push-undo">
                                <xsl:with-param name="host" select="$host"/>
                            </xsl:call-template>
                            <xsl:sequence select="ixsl:call($quote, 'before', [ $host ])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:if test="empty($quote/*[not(@data-role)])">
                                <xsl:sequence select="ixsl:call($quote, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:if>
                            <xsl:if test="$host/parent::*[contains-token(@class, 'rdfa-editor-content')]">
                                <xsl:call-template name="rdfae:inject-chrome">
                                    <xsl:with-param name="block" select="$host"/>
                                </xsl:call-template>
                            </xsl:if>
                            <xsl:call-template name="rdfae:focus-caret">
                                <xsl:with-param name="node" select="$host"/>
                                <xsl:with-param name="offset" select="rdfae:chrome-count($host)"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:after-mutation"/>
                        </xsl:when>
                        <!-- B3: never merge across composite blocks; an empty block is removed
                             (a preceding island has no host to land in - it is selected) -->
                        <xsl:when test="exists($prev[not(@data-role)]) and rdfae:block-text($host) = ''">
                            <xsl:call-template name="rdfae:push-undo"/>
                            <xsl:sequence select="ixsl:call($host, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                            <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
                            <xsl:choose>
                                <xsl:when test="rdfae:island($prev)">
                                    <xsl:call-template name="rdfae:select-island">
                                        <xsl:with-param name="element" select="$prev"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="prev-host" as="element()?"
                                        select="($prev/descendant-or-self::*[@contenteditable = 'true'])[last()]"/>
                                    <xsl:for-each select="$prev-host">
                                        <xsl:call-template name="rdfae:focus-caret">
                                            <xsl:with-param name="node" select="."/>
                                            <xsl:with-param name="offset" select="xs:integer(ixsl:get(., 'childNodes.length'))"/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:call-template name="rdfae:after-mutation"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- ................................ list indent/outdent ................................ -->

    <!-- Tab: the item indents under its previous sibling - per ul/ol -> (li)+ the
         nested list lives INSIDE the previous item, which becomes a container
         (trailing nested list reused, else a fresh list of the same kind). A first
         item has nowhere to go - flash -->
    <xsl:template name="rdfae:list-indent">
        <xsl:param name="item" as="element()"/>

        <xsl:variable name="prev" as="element()?" select="$item/preceding-sibling::li[1]"/>
        <xsl:choose>
            <xsl:when test="exists($prev)">
                <xsl:call-template name="rdfae:push-undo">
                    <xsl:with-param name="host" select="$item"/>
                </xsl:call-template>
                <!-- text-node caret references survive reparenting -->
                <xsl:variable name="caret-node" as="node()?" select="rdfae:anchor-node()"/>
                <xsl:variable name="caret-offset" as="xs:integer" select="rdfae:anchor-offset()"/>
                <xsl:variable name="target" as="element()?"
                    select="$prev/*[not(@data-role)][last()][self::ul or self::ol]"/>
                <xsl:if test="empty($target)">
                    <xsl:for-each select="$prev[@contenteditable = 'true']">
                        <ixsl:remove-attribute name="contenteditable"/>
                        <xsl:call-template name="rdfae:wrap-stray-runs">
                            <xsl:with-param name="container" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <xsl:variable name="list" as="element()" select="if (exists($target)) then $target
                    else rdfae:element(local-name($item/parent::*))"/>
                <xsl:if test="empty($target)">
                    <xsl:sequence select="ixsl:call($prev, 'appendChild', [ $list ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
                <xsl:sequence select="ixsl:call($list, 'appendChild', [ $item ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:choose>
                    <xsl:when test="exists($caret-node)">
                        <xsl:call-template name="rdfae:focus-caret">
                            <xsl:with-param name="node" select="$caret-node"/>
                            <xsl:with-param name="offset" select="$caret-offset"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="rdfae:first-host-in($item)">
                            <xsl:call-template name="rdfae:focus-caret">
                                <xsl:with-param name="node" select="."/>
                                <xsl:with-param name="offset" select="0"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="rdfae:caret-range()">
                    <xsl:call-template name="rdfae:show-flash">
                        <xsl:with-param name="range" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Shift+Tab (and progressive Enter/Backspace exits): the item moves after its
         container item; following siblings demote into a nested list inside the
         moved item (they were logically below it). The emptied nested list is
         removed and the container collapses back to a text host when its last
         block leaves. A top-level item has nowhere to go - flash -->
    <xsl:template name="rdfae:list-outdent">
        <xsl:param name="item" as="element()"/>

        <xsl:variable name="list" as="element()" select="$item/parent::*"/>
        <xsl:variable name="container" as="element()?" select="$list/parent::li"/>
        <xsl:choose>
            <xsl:when test="exists($container)">
                <xsl:call-template name="rdfae:push-undo">
                    <xsl:with-param name="host" select="$item"/>
                </xsl:call-template>
                <xsl:variable name="caret-node" as="node()?" select="rdfae:anchor-node()"/>
                <xsl:variable name="caret-offset" as="xs:integer" select="rdfae:anchor-offset()"/>
                <xsl:variable name="followers" as="element()*" select="$item/following-sibling::li"/>
                <xsl:if test="exists($followers)">
                    <xsl:variable name="target" as="element()?"
                        select="$item/*[not(@data-role)][last()][self::ul or self::ol]"/>
                    <xsl:if test="empty($target)">
                        <xsl:for-each select="$item[@contenteditable = 'true']">
                            <ixsl:remove-attribute name="contenteditable"/>
                            <xsl:call-template name="rdfae:wrap-stray-runs">
                                <xsl:with-param name="container" select="."/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:if>
                    <xsl:variable name="sub" as="element()" select="if (exists($target)) then $target
                        else rdfae:element(local-name($list))"/>
                    <xsl:if test="empty($target)">
                        <xsl:sequence select="ixsl:call($item, 'appendChild', [ $sub ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>
                    <xsl:for-each select="$followers">
                        <xsl:sequence select="ixsl:call($sub, 'appendChild', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:if>
                <xsl:sequence select="ixsl:call($container, 'after', [ $item ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:if test="empty($list/li)">
                    <xsl:sequence select="ixsl:call($list, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
                <xsl:call-template name="rdfae:collapse-container">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
                <xsl:choose>
                    <xsl:when test="exists($caret-node)">
                        <xsl:call-template name="rdfae:focus-caret">
                            <xsl:with-param name="node" select="$caret-node"/>
                            <xsl:with-param name="offset" select="$caret-offset"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="rdfae:first-host-in($item)">
                            <xsl:call-template name="rdfae:focus-caret">
                                <xsl:with-param name="node" select="."/>
                                <xsl:with-param name="offset" select="0"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="rdfae:caret-range()">
                    <xsl:call-template name="rdfae:show-flash">
                        <xsl:with-param name="range" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- counted firstChild moves (never iterate a live child list lazily); no
         normalize() afterwards - the caret index depends on the node count -->
    <xsl:template name="rdfae:merge-into-previous">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="prev" as="element()"/>

        <xsl:call-template name="rdfae:remove-chrome">
            <xsl:with-param name="block" select="$host"/>
        </xsl:call-template>
        <xsl:variable name="index" as="xs:integer" select="xs:integer(ixsl:get($prev, 'childNodes.length'))"/>
        <xsl:for-each select="1 to xs:integer(ixsl:get($host, 'childNodes.length'))">
            <xsl:sequence select="ixsl:call($prev, 'appendChild', [ ixsl:get($host, 'firstChild') ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:sequence select="ixsl:call($host, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
        <xsl:call-template name="rdfae:focus-caret">
    <xsl:with-param name="node" select="$prev"/>
    <xsl:with-param name="offset" select="$index"/>
</xsl:call-template>
    </xsl:template>

    <!-- ................................ paste / focus ................................ -->

    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onpaste">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="exists(rdfae:block-of(.))">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:variable name="html" as="xs:string"
                select="string(ixsl:call(ixsl:get($event, 'clipboardData'), 'getData', [ 'text/html' ]))"/>
            <!-- pasting over a cross-host selection is inert this iteration: the
                 paste machines would raw-deleteContents across hosts -->
            <xsl:choose>
                <xsl:when test="rdfae:selection-crosses-hosts()"/>
                <!-- formatted paste through the canonical (sanitizing) pipeline -->
                <xsl:when test="$html ne '' and not(self::pre)">
                    <xsl:call-template name="rdfae:paste-html">
                        <xsl:with-param name="host" select="."/>
                        <xsl:with-param name="html" select="$html"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="rdfae:paste-text">
                        <xsl:with-param name="host" select="."/>
                        <xsl:with-param name="raw" select="string(ixsl:call(ixsl:get($event, 'clipboardData'),
                            'getData', [ 'text/plain' ]))"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template name="rdfae:paste-text">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="raw" as="xs:string"/>

        <xsl:variable name="text" as="xs:string"
            select="if ($host/self::pre) then $raw else normalize-space($raw)"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:if test="$text ne '' and ixsl:get($selection, 'rangeCount') ge 1">
            <xsl:variable name="range" select="rdfae:caret-range()"/>
            <xsl:call-template name="rdfae:push-undo">
                <xsl:with-param name="host" select="$host"/>
            </xsl:call-template>
            <xsl:sequence select="ixsl:call($range, 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:variable name="node" select="ixsl:call(ixsl:page(), 'createTextNode', [ $text ])"/>
            <xsl:sequence select="ixsl:call($range, 'insertNode', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:place-caret">
                <xsl:with-param name="node" select="$node"/>
                <xsl:with-param name="offset" select="string-length($text)"/>
            </xsl:call-template>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
    </xsl:template>

    <!-- clipboard HTML: browser-parse it on a DETACHED element (scripts inert),
         sanitize/normalize via mode="cm:canonical" + mode="cm:normalize", then insert
         where the content model allows - inline fragments at the caret, blocks
         inside a flow host (li, td, ...) or as new siblings between the split
         halves of an inline-only host; hosts that can take blocks neither way
         (caption, dt) flatten to text -->
    <xsl:template name="rdfae:paste-html">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="html" as="xs:string"/>

        <xsl:variable name="carrier" as="element()" select="rdfae:element('div')"/>
        <ixsl:set-property name="innerHTML" select="$html" object="$carrier"/>
        <xsl:variable name="pass1">
            <xsl:apply-templates select="$carrier/node()" mode="cm:canonical"/>
        </xsl:variable>
        <xsl:variable name="clean">
            <xsl:sequence select="cm:normalize($pass1/node())"/>
        </xsl:variable>
        <xsl:variable name="has-blocks" as="xs:boolean"
            select="exists($clean/*[cm:block(local-name(.))])"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>

        <xsl:choose>
            <xsl:when test="empty($clean/node()) or ixsl:get($selection, 'rangeCount') lt 1"/>
            <!-- a mixed flow host takes the blocks inside itself -->
            <xsl:when test="$has-blocks and cm:flow(local-name($host))">
                <xsl:call-template name="rdfae:paste-into-flow-host">
                    <xsl:with-param name="host" select="$host"/>
                    <xsl:with-param name="clean" select="$clean/node()"/>
                </xsl:call-template>
            </xsl:when>
            <!-- an inline-only host splits when its parent takes the blocks as
                 siblings (the region by contract; blockquote, containers by model) -->
            <xsl:when test="$has-blocks and (not(cm:known(local-name($host/parent::*)))
                    or (every $block in $clean/*[cm:block(local-name(.))]
                        satisfies cm:allows-child(local-name($host/parent::*), local-name($block))))">
                <!-- stray top-level inline runs become paragraphs -->
                <xsl:variable name="blocks" as="element()*"
                    select="cm:wrap-inline-runs($clean/node(), 'p')[self::*]"/>
                <xsl:variable name="range" select="rdfae:caret-range()"/>
                <xsl:call-template name="rdfae:push-undo">
                    <xsl:with-param name="host" select="$host"/>
                </xsl:call-template>
                <xsl:if test="not(ixsl:get($range, 'collapsed'))">
                    <xsl:sequence select="ixsl:call($range, 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
                <!-- split the host, then thread the pasted blocks in after the first half -->
                <xsl:call-template name="rdfae:split-block">
                    <xsl:with-param name="host" select="$host"/>
                    <xsl:with-param name="range" select="$range"/>
                </xsl:call-template>
                <xsl:variable name="count" as="xs:integer" select="count($blocks)"/>
                <xsl:for-each select="$host">
                    <xsl:result-document href="?." method="ixsl:insert-after">
                        <xsl:copy-of select="$blocks"/>
                    </xsl:result-document>
                </xsl:for-each>
                <xsl:for-each select="$host/following-sibling::*[position() le $count]">
                    <xsl:call-template name="rdfae:init-block">
                        <xsl:with-param name="block" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                <!-- caret at the end of the last pasted block's last editable host -->
                <xsl:variable name="last" as="element()?" select="$host/following-sibling::*[$count]"/>
                <xsl:for-each select="($last/descendant-or-self::*[@contenteditable = 'true'])[last()]">
                    <xsl:call-template name="rdfae:focus-caret">
    <xsl:with-param name="node" select="."/>
    <xsl:with-param name="offset" select="count(node()) - count(node()[last()][self::br])"/>
</xsl:call-template>
                </xsl:for-each>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:when>
            <!-- blocks fit neither inside the host nor beside it (caption, dt):
                 flatten to sanitized text -->
            <xsl:when test="$has-blocks">
                <xsl:call-template name="rdfae:paste-text">
                    <xsl:with-param name="host" select="$host"/>
                    <xsl:with-param name="raw" select="string($clean)"/>
                </xsl:call-template>
            </xsl:when>
            <!-- inline-only fragment: insert at the caret -->
            <xsl:otherwise>
                <xsl:variable name="range" select="rdfae:caret-range()"/>
                <xsl:call-template name="rdfae:push-undo">
                    <xsl:with-param name="host" select="$host"/>
                </xsl:call-template>
                <xsl:sequence select="ixsl:call($range, 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:variable name="stage" as="element()" select="rdfae:element('div')"/>
                <ixsl:set-property name="innerHTML" select="serialize($clean/node(), map{ 'method': 'html' })" object="$stage"/>
                <xsl:variable name="last" select="ixsl:get($stage, 'lastChild')"/>
                <xsl:variable name="fragment" select="ixsl:call(ixsl:page(), 'createDocumentFragment', [])"/>
                <xsl:for-each select="1 to xs:integer(ixsl:get($stage, 'childNodes.length'))">
                    <xsl:sequence select="ixsl:call($fragment, 'appendChild', [ ixsl:get($stage, 'firstChild') ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
                <xsl:sequence select="ixsl:call($range, 'insertNode', [ $fragment ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:for-each select="$last">
                    <xsl:call-template name="rdfae:place-caret">
                        <xsl:with-param name="node" select="ixsl:get(., 'parentNode')"/>
                        <xsl:with-param name="offset" select="count(preceding-sibling::node()) + 1"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- blocks paste INSIDE a mixed flow host (li, td, th, dd, figcaption): the
         host's content splits around the caret into head and tail runs with the
         blocks between them, and re-init turns the host into a container (stray
         runs wrapped as p.rdfa-editor-run, nested blocks inited recursively) -->
    <xsl:template name="rdfae:paste-into-flow-host">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="clean" as="node()*"/>

        <xsl:variable name="range" select="rdfae:caret-range()"/>
        <xsl:call-template name="rdfae:push-undo">
            <xsl:with-param name="host" select="$host"/>
        </xsl:call-template>
        <xsl:if test="not(ixsl:get($range, 'collapsed'))">
            <xsl:sequence select="ixsl:call($range, 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <!-- the tail (caret to end of host) rides out as HTML -->
        <xsl:sequence select="ixsl:call($range, 'setEnd', [ $host, xs:integer(ixsl:get($host, 'childNodes.length')) ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="tail-stage" as="element()" select="rdfae:element('div')"/>
        <xsl:sequence select="ixsl:call($tail-stage, 'appendChild',
            [ ixsl:call($range, 'extractContents', []) ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:remove-chrome">
            <xsl:with-param name="block" select="$host"/>
        </xsl:call-template>
        <ixsl:set-property name="innerHTML" select="string(ixsl:get($host, 'innerHTML'))
            || serialize($clean, map{ 'method': 'html' })
            || string(ixsl:get($tail-stage, 'innerHTML'))" object="$host"/>
        <!-- re-init decides text host vs container afresh -->
        <xsl:for-each select="$host">
            <ixsl:remove-attribute name="contenteditable"/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:init-block">
            <xsl:with-param name="block" select="$host"/>
        </xsl:call-template>
        <!-- caret at the end of the last editable host in the rebuilt container -->
        <xsl:for-each select="($host/descendant-or-self::*[@contenteditable = 'true'])[last()]">
            <xsl:call-template name="rdfae:focus-caret">
                <xsl:with-param name="node" select="."/>
                <xsl:with-param name="offset" select="count(node()) - count(node()[last()][self::br])"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onfocusin">
        <xsl:if test="exists(rdfae:block-of(.))">
            <ixsl:set-property name="activeBlock" select="." object="rdfae:editor-state()"/>
            <xsl:call-template name="rdfae:update-breadcrumb"/>
        </xsl:if>
    </xsl:template>

    <!-- ................................ toolbar ................................ -->

    <!-- buttons must not steal the selection they act on -->
    <xsl:template match="div[@id = 'edit-toolbar']//button" mode="ixsl:onmousedown">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- the select acts on the HOST the caret sits in (a paragraph inside a quote
         converts alone, leaving the quote intact); quote wrapping lives on the
         format-quote toggle -->
    <xsl:template match="select[@name = 'block-type']" mode="ixsl:onchange">
        <xsl:variable name="name" as="xs:string" select="string(ixsl:get(., 'value'))"/>
        <xsl:for-each select="rdfae:current-host()[self::p or self::h1 or self::h2 or self::h3
                or self::pre][exists(rdfae:block-of(.))][local-name() ne $name]">
            <xsl:call-template name="rdfae:convert-block">
                <xsl:with-param name="block" select="."/>
                <xsl:with-param name="name" select="$name"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- the quote toggle: wrapping keeps the block's name, editability and caret
         (text nodes survive reparenting); chrome moves to a new top-level quote.
         Wrapping a run wrapper promotes it (blockquote > bare run would unwrap to
         invalid bare text at canonicalization) -->
    <xsl:template name="rdfae:wrap-in-blockquote">
        <xsl:param name="block" as="element()"/>

        <xsl:call-template name="rdfae:push-undo">
            <xsl:with-param name="host" select="$block"/>
        </xsl:call-template>
        <xsl:if test="contains-token($block/@class, 'rdfa-editor-run')">
            <xsl:sequence select="ixsl:call(ixsl:get($block, 'classList'), 'remove',
                [ 'rdfa-editor-run' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <xsl:variable name="quote" as="element()" select="rdfae:element('blockquote')"/>
        <xsl:sequence select="ixsl:call($block, 'before', [ $quote ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:remove-chrome">
            <xsl:with-param name="block" select="$block"/>
        </xsl:call-template>
        <xsl:sequence select="ixsl:call($quote, 'appendChild', [ $block ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:if test="$quote/parent::*[contains-token(@class, 'rdfa-editor-content')]">
            <xsl:call-template name="rdfae:inject-chrome">
                <xsl:with-param name="block" select="$quote"/>
            </xsl:call-template>
        </xsl:if>
        <ixsl:set-property name="activeBlock" select="$block" object="rdfae:editor-state()"/>
        <xsl:call-template name="rdfae:focus">
            <xsl:with-param name="element" select="$block"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <!-- the quote toggle off: all children move out (counted sibling inserts) and
         re-init (chrome iff now top-level); refused with a flash when the quote
         carries RDFa attributes - unwrapping would silently drop triples -->
    <xsl:template name="rdfae:unwrap-blockquote">
        <xsl:param name="quote" as="element()"/>

        <xsl:choose>
            <xsl:when test="$quote/@property or $quote/@about or $quote/@typeof
                    or $quote/@resource or $quote/@content or $quote/@datatype">
                <xsl:for-each select="rdfae:caret-range()">
                    <xsl:call-template name="rdfae:show-flash">
                        <xsl:with-param name="range" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:push-undo">
                    <xsl:with-param name="host" select="$quote"/>
                </xsl:call-template>
                <xsl:variable name="caret-node" as="node()?" select="rdfae:anchor-node()"/>
                <xsl:variable name="caret-offset" as="xs:integer" select="rdfae:anchor-offset()"/>
                <xsl:call-template name="rdfae:remove-chrome">
                    <xsl:with-param name="block" select="$quote"/>
                </xsl:call-template>
                <xsl:variable name="inner" as="element()*" select="$quote/*"/>
                <xsl:for-each select="1 to xs:integer(ixsl:get($quote, 'childNodes.length'))">
                    <xsl:sequence select="ixsl:call($quote, 'before', [ ixsl:get($quote, 'firstChild') ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
                <xsl:sequence select="ixsl:call($quote, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:for-each select="$inner">
                    <xsl:call-template name="rdfae:init-block">
                        <xsl:with-param name="block" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
                <xsl:choose>
                    <xsl:when test="exists($caret-node)">
                        <xsl:call-template name="rdfae:focus-caret">
                            <xsl:with-param name="node" select="$caret-node"/>
                            <xsl:with-param name="offset" select="$caret-offset"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="rdfae:first-host-in($inner[1])">
                            <xsl:call-template name="rdfae:focus-caret">
                                <xsl:with-param name="node" select="."/>
                                <xsl:with-param name="offset" select="rdfae:chrome-count(.)"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'format-quote')]" mode="ixsl:onclick">
        <xsl:variable name="host" as="element()?" select="rdfae:current-host()[exists(rdfae:block-of(.))]"/>
        <!-- clamped at the region root: a host-page blockquote wrapping an
             embedded region is not ours to unwrap -->
        <xsl:variable name="quote" as="element()?"
            select="$host/ancestor-or-self::blockquote[exists(rdfae:block-of(.))][1]"/>
        <xsl:choose>
            <xsl:when test="exists($quote)">
                <xsl:call-template name="rdfae:unwrap-blockquote">
                    <xsl:with-param name="quote" select="$quote"/>
                </xsl:call-template>
            </xsl:when>
            <!-- wrap the host block where its parent admits a blockquote (the
                 region by contract; flow containers and blockquote by model) -->
            <xsl:when test="$host[cm:block(local-name(.))]
                    [parent::*[contains-token(@class, 'rdfa-editor-content')]
                        or cm:allows-child(local-name(parent::*), 'blockquote')]">
                <xsl:call-template name="rdfae:wrap-in-blockquote">
                    <xsl:with-param name="block" select="$host"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="rdfae:caret-range()">
                    <xsl:call-template name="rdfae:show-flash">
                        <xsl:with-param name="range" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- rename by rebuild: copy RDFa/lang attributes, move children (text-node
         references survive reparenting, so the caret can be restored exactly) -->
    <xsl:template name="rdfae:convert-block">
        <xsl:param name="block" as="element()"/>
        <xsl:param name="name" as="xs:string"/>
        <!-- optionally pre-captured by the caller (unwrap+rename is one undo entry);
             the defaults mirror rdfae:push-undo's capture-now behavior -->
        <xsl:param name="snapshot-root" as="element()?" select="rdfae:active-root()"/>
        <xsl:param name="snapshot" as="xs:string?"
            select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>

        <xsl:call-template name="rdfae:push-undo">
            <xsl:with-param name="root" select="$snapshot-root"/>
            <xsl:with-param name="snapshot" select="$snapshot"/>
        </xsl:call-template>
        <!-- host-of, not block-of: $block may be a nested host (a paragraph in a
             quote or cell) whose top-level block is the container. Restore only a
             node that MOVES with the children (a descendant); an element-level
             caret on the block itself dangles after replaceWith, so it falls back
             to the start of the new block (matters for empty-block conversions) -->
        <xsl:variable name="caret-node" as="node()?"
            select="rdfae:anchor-node()[rdfae:host-of(.) is $block][not(. is $block)]"/>
        <xsl:variable name="caret-offset" as="xs:integer"
            select="if (exists($caret-node)) then rdfae:anchor-offset() else 0"/>

        <xsl:variable name="new" as="element()" select="ixsl:call(ixsl:page(), 'createElement', [ $name ])"/>
        <xsl:for-each select="$block/(@about | @property | @typeof | @resource | @content
                | @datatype | @lang | @xml:lang | @contenteditable)">
            <ixsl:set-attribute name="{name()}" select="string(.)" object="$new"/>
        </xsl:for-each>
        <xsl:for-each select="1 to xs:integer(ixsl:get($block, 'childNodes.length'))">
            <xsl:sequence select="ixsl:call($new, 'appendChild', [ ixsl:get($block, 'firstChild') ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:sequence select="ixsl:call($block, 'replaceWith', [ $new ])[current-date() lt xs:date('2000-01-01')]"/>
        <ixsl:set-property name="activeBlock" select="$new" object="rdfae:editor-state()"/>
        <xsl:call-template name="rdfae:focus">
            <xsl:with-param name="element" select="$new"/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="exists($caret-node)">
                <xsl:call-template name="rdfae:place-caret">
                    <xsl:with-param name="node" select="$caret-node"/>
                    <xsl:with-param name="offset" select="$caret-offset"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:place-caret">
                    <xsl:with-param name="node" select="$new"/>
                    <xsl:with-param name="offset" select="rdfae:chrome-count($new)"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <!-- inline formatting toggles reuse the annotation wrap/unwrap machinery -->
    <xsl:template match="button[contains-token(@class, 'format-inline')]" mode="ixsl:onclick">
        <xsl:variable name="name" as="xs:string" select="string(@data-element)"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1">
            <xsl:variable name="range" select="rdfae:caret-range()"/>
            <xsl:variable name="anchor" select="ixsl:get($selection, 'anchorNode')"/>
            <xsl:for-each select="rdfae:host-of($anchor)[exists(rdfae:block-of(.))]">
                <xsl:variable name="existing" as="element()?"
                    select="($anchor/ancestor-or-self::*[local-name() = $name] intersect descendant::*)[1]"/>
                <xsl:choose>
                    <xsl:when test="exists($existing)">
                        <xsl:call-template name="rdfae:push-undo"/>
                        <xsl:call-template name="rdfae:unwrap-element">
                            <xsl:with-param name="element" select="$existing"/>
                        </xsl:call-template>
                        <xsl:call-template name="rdfae:after-mutation"/>
                    </xsl:when>
                    <xsl:when test="not(ixsl:get($selection, 'isCollapsed'))">
                        <!-- capture pre-wrap state; push only when the wrap succeeded -->
                        <xsl:variable name="snapshot-root" as="element()?" select="rdfae:active-root()"/>
                        <xsl:variable name="snapshot" as="xs:string?"
                            select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>
                        <xsl:variable name="wrapped" as="element()?">
                            <xsl:call-template name="rdfae:wrap-range">
                                <xsl:with-param name="range" select="$range"/>
                                <xsl:with-param name="name" select="$name"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:for-each select="$wrapped">
                            <xsl:call-template name="rdfae:push-undo">
                                <xsl:with-param name="root" select="$snapshot-root"/>
                                <xsl:with-param name="snapshot" select="$snapshot"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:after-mutation"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- places a freshly created block per the content model: after the caret's
         host when its parent admits the kind (region children by contract; a
         paragraph in a cell or quote gets the block as its sibling), INSIDE a leaf
         flow host otherwise (a cell or list item grows a nested block, becoming a
         container), after the current top-level block as a last resort (caption,
         dt). Chrome stays a top-level affordance -->
    <xsl:template name="rdfae:insert-block-at-caret">
        <xsl:param name="node" as="element()"/>
        <!-- dialog saves pass the host their dialog was opened from (the caret
             sits in the dialog input by then); defaulted for the direct buttons -->
        <xsl:param name="host" as="element()?" select="rdfae:current-host()[exists(rdfae:block-of(.))]"/>

        <xsl:choose>
            <!-- not inside a figure: the figure is a locked composite, so a block
                 inserted at its caption nests INSIDE the figcaption (flow branch)
                 rather than growing the figure's children -->
            <xsl:when test="$host[not(parent::figure)][parent::*[contains-token(@class, 'rdfa-editor-content')]
                    or cm:allows-child(local-name(parent::*), local-name($node))]">
                <xsl:sequence select="ixsl:call($host, 'after', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:when test="$host[cm:flow(local-name(.))]">
                <xsl:for-each select="$host">
                    <ixsl:remove-attribute name="contenteditable"/>
                </xsl:for-each>
                <xsl:call-template name="rdfae:wrap-stray-runs">
                    <xsl:with-param name="container" select="$host"/>
                </xsl:call-template>
                <xsl:sequence select="ixsl:call($host, 'appendChild', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:when test="exists(rdfae:current-block())">
                <xsl:sequence select="ixsl:call(rdfae:current-block(), 'after', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="rdfae:active-root()">
                    <xsl:sequence select="ixsl:call(., 'appendChild', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$node/parent::*[contains-token(@class, 'rdfa-editor-content')]">
            <xsl:call-template name="rdfae:inject-chrome">
                <xsl:with-param name="block" select="$node"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'insert-block')]" mode="ixsl:onclick">
        <xsl:call-template name="rdfae:push-undo"/>
        <xsl:variable name="p" as="element()" select="rdfae:element('p')"/>
        <xsl:sequence select="ixsl:call($p, 'appendChild', [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$p"/>
        <xsl:call-template name="rdfae:insert-block-at-caret">
            <xsl:with-param name="node" select="$p"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:focus-caret">
            <xsl:with-param name="node" select="$p"/>
            <xsl:with-param name="offset" select="rdfae:chrome-count($p)"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'insert-list')]" mode="ixsl:onclick">
        <xsl:call-template name="rdfae:push-undo"/>
        <xsl:variable name="list" as="element()" select="ixsl:call(ixsl:page(), 'createElement', [ string(@data-list) ])"/>
        <xsl:variable name="li" as="element()" select="rdfae:element('li')"/>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$li"/>
        <xsl:sequence select="ixsl:call($list, 'appendChild', [ $li ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:insert-block-at-caret">
            <xsl:with-param name="node" select="$list"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:focus-caret">
    <xsl:with-param name="node" select="$li"/>
    <xsl:with-param name="offset" select="0"/>
</xsl:call-template>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'delete-block')]" mode="ixsl:onclick">
        <xsl:for-each select="rdfae:current-block()">
            <xsl:variable name="confirmed" as="xs:boolean" select="rdfae:block-text(.) = ''
                or ixsl:call(ixsl:window(), 'confirm', [ 'Delete this block?' ])"/>
            <xsl:if test="$confirmed">
                <xsl:call-template name="rdfae:push-undo"/>
                <xsl:variable name="prev" as="element()?" select="preceding-sibling::*[1]"/>
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
                <xsl:for-each select="($prev/descendant-or-self::*[@contenteditable = 'true'])[last()]">
                    <xsl:call-template name="rdfae:focus">
                        <xsl:with-param name="element" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ link dialog ................................ -->

    <xsl:template match="button[contains-token(@class, 'format-link')]" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1">
            <xsl:variable name="range" select="rdfae:caret-range()"/>
            <xsl:variable name="anchor" select="ixsl:get($selection, 'anchorNode')"/>
            <xsl:for-each select="rdfae:host-of($anchor)[exists(rdfae:block-of(.))]">
                <xsl:variable name="link" as="element()?"
                    select="($anchor/ancestor-or-self::a intersect descendant::*)[1]"/>
                <xsl:choose>
                    <!-- caret inside a link: edit it -->
                    <xsl:when test="exists($link)">
                        <ixsl:set-property name="editingLink" select="$link" object="rdfae:editor-state()"/>
                        <xsl:call-template name="rdfae:open-link-dialog">
                            <xsl:with-param name="event" select="$event"/>
                            <xsl:with-param name="href" select="string($link/@href)"/>
                            <xsl:with-param name="editing" select="true()"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- selection: create one -->
                    <xsl:when test="not(ixsl:get($selection, 'isCollapsed'))">
                        <ixsl:set-property name="editRange" select="$range" object="rdfae:editor-state()"/>
                        <ixsl:set-property name="editingLink" select="()" object="rdfae:editor-state()"/>
                        <xsl:call-template name="rdfae:open-link-dialog">
                            <xsl:with-param name="event" select="$event"/>
                            <xsl:with-param name="href" select="''"/>
                            <xsl:with-param name="editing" select="false()"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="rdfae:render-link-dialog">
        <div id="link-dialog" class="rdfa-editor-ui edit-dialog" role="dialog" aria-modal="true"
                aria-label="Link" style="display: none;">
            <label>Link target (href)</label>
            <input type="text" name="href" placeholder="https://..."/>
            <div class="action-buttons">
                <button type="button" class="ldhc-btn in-negative ap-solid sz-sm link-remove" style="display: none;">Remove link</button>
                <button type="button" class="ldhc-btn in-primary ap-solid sz-sm link-save">Save</button>
                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm link-cancel">Cancel</button>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="rdfae:open-link-dialog">
        <xsl:param name="event"/>
        <xsl:param name="href" as="xs:string"/>
        <xsl:param name="editing" as="xs:boolean"/>

        <xsl:variable name="dialog" as="element()" select="id('link-dialog', ixsl:page())"/>
        <xsl:for-each select="($dialog//input[@name = 'href'])[1]">
            <ixsl:set-property name="value" select="$href" object="."/>
        </xsl:for-each>
        <xsl:for-each select="$dialog//button[contains-token(@class, 'link-remove')]">
            <ixsl:set-style name="display" select="if ($editing) then 'inline-block' else 'none'"/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:show-at">
            <xsl:with-param name="element" select="$dialog"/>
            <xsl:with-param name="event" select="$event"/>
        </xsl:call-template>
        <xsl:for-each select="($dialog//input[@name = 'href'])[1]">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'link-save')]" mode="ixsl:onclick">
        <xsl:variable name="href" as="xs:string"
            select="rdfae:input-value(ancestor::div[@id = 'link-dialog'][1], 'href')"/>
        <xsl:if test="$href ne ''">
            <xsl:variable name="editing" select="ixsl:get(rdfae:editor-state(), 'editingLink')"/>
            <xsl:choose>
                <xsl:when test="exists($editing)">
                    <xsl:call-template name="rdfae:push-undo"/>
                    <xsl:for-each select="$editing">
                        <ixsl:set-attribute name="href" select="$href"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- capture pre-wrap state; push only when the wrap succeeded -->
                    <xsl:variable name="snapshot-root" as="element()?" select="rdfae:active-root()"/>
                    <xsl:variable name="snapshot" as="xs:string?"
                        select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>
                    <xsl:variable name="wrapped" as="element()?">
                        <xsl:call-template name="rdfae:wrap-range">
                            <xsl:with-param name="range" select="ixsl:get(rdfae:editor-state(), 'editRange')"/>
                            <xsl:with-param name="name" select="'a'"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="$wrapped">
                        <xsl:call-template name="rdfae:push-undo">
                            <xsl:with-param name="root" select="$snapshot-root"/>
                            <xsl:with-param name="snapshot" select="$snapshot"/>
                        </xsl:call-template>
                        <ixsl:set-attribute name="href" select="$href"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
        <xsl:call-template name="rdfae:hide-dialogs"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'link-remove')]" mode="ixsl:onclick">
        <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'editingLink')">
            <xsl:call-template name="rdfae:push-undo"/>
            <xsl:call-template name="rdfae:unwrap-element">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:hide-dialogs"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'link-cancel')
            or contains-token(@class, 'figure-cancel')
            or contains-token(@class, 'table-cancel')]" mode="ixsl:onclick">
        <xsl:call-template name="rdfae:hide-dialogs"/>
    </xsl:template>

    <xsl:template match="div[contains-token(@class, 'edit-dialog')] | div[@id = 'slash-menu']" mode="ixsl:onkeydown">
        <xsl:if test="string(ixsl:get(ixsl:event(), 'key')) = 'Escape'">
            <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:hide-dialogs"/>
        </xsl:if>
    </xsl:template>

    <!-- single teardown point for all dialogs: everything carrying the edit-dialog
         class (extension dialogs opt in the same way) plus the slash menu -->
    <xsl:template name="rdfae:hide-dialogs">
        <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'edit-dialog')],
                id('slash-menu', ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
        <ixsl:set-property name="editRange" select="()" object="rdfae:editor-state()"/>
        <ixsl:set-property name="editingLink" select="()" object="rdfae:editor-state()"/>
        <ixsl:set-property name="insertHost" select="()" object="rdfae:editor-state()"/>
        <ixsl:set-property name="slashHost" select="()" object="rdfae:editor-state()"/>
        <ixsl:set-property name="findNode" select="()" object="rdfae:editor-state()"/>
        <ixsl:set-property name="findOffset" select="1" object="rdfae:editor-state()"/>
        <!-- return focus to the content -->
        <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'activeBlock')[exists(rdfae:block-of(.))]">
            <xsl:call-template name="rdfae:focus">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ figure dialog ................................ -->

    <xsl:template match="button[contains-token(@class, 'insert-figure')]" mode="ixsl:onclick">
        <ixsl:set-property name="insertHost"
            select="rdfae:current-host()[exists(rdfae:block-of(.))]" object="rdfae:editor-state()"/>
        <xsl:variable name="dialog" as="element()" select="id('figure-dialog', ixsl:page())"/>
        <xsl:for-each select="$dialog//input">
            <ixsl:set-property name="value" select="''" object="."/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:show-at">
            <xsl:with-param name="element" select="$dialog"/>
            <xsl:with-param name="event" select="ixsl:event()"/>
        </xsl:call-template>
        <xsl:for-each select="($dialog//input[@name = 'src'])[1]">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="rdfae:render-figure-dialog">
        <div id="figure-dialog" class="rdfa-editor-ui edit-dialog" role="dialog" aria-modal="true"
                aria-label="Insert figure" style="display: none;">
            <label>Image URL (src)</label>
            <input type="text" name="src" placeholder="https://... or relative path"/>
            <label>Alternate text (alt)</label>
            <input type="text" name="alt"/>
            <label>Caption</label>
            <input type="text" name="caption"/>
            <div class="action-buttons">
                <button type="button" class="ldhc-btn in-primary ap-solid sz-sm figure-save">Insert</button>
                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm figure-cancel">Cancel</button>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'figure-save')]" mode="ixsl:onclick">
        <xsl:variable name="dialog" as="element()" select="ancestor::div[@id = 'figure-dialog']"/>
        <xsl:variable name="src" as="xs:string" select="rdfae:input-value($dialog, 'src')"/>
        <xsl:if test="$src ne ''">
            <xsl:call-template name="rdfae:push-undo"/>
            <xsl:variable name="figure" as="element()" select="rdfae:element('figure')"/>
            <xsl:variable name="img" as="element()" select="rdfae:element('img')"/>
            <ixsl:set-attribute name="src" select="$src" object="$img"/>
            <ixsl:set-attribute name="alt" select="rdfae:input-value($dialog, 'alt')" object="$img"/>
            <!-- focusable so the image is a keyboard-navigation island (see rdfae:nav-targets) -->
            <ixsl:set-attribute name="tabindex" select="'-1'" object="$img"/>
            <xsl:variable name="figcaption" as="element()" select="rdfae:element('figcaption')"/>
            <ixsl:set-property name="textContent" select="rdfae:input-value($dialog, 'caption')" object="$figcaption"/>
            <ixsl:set-attribute name="contenteditable" select="'true'" object="$figcaption"/>
            <xsl:sequence select="ixsl:call($figure, 'appendChild', [ $img ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call($figure, 'appendChild', [ $figcaption ])[current-date() lt xs:date('2000-01-01')]"/>
            <!-- placed per the content model relative to the host the dialog was
                 opened from: an empty list item or cell grows the figure INSIDE
                 itself, a sibling where the parent admits it (chrome only when it
                 lands top-level - the helper guards it) -->
            <xsl:call-template name="rdfae:insert-block-at-caret">
                <xsl:with-param name="node" select="$figure"/>
                <xsl:with-param name="host" select="ixsl:get(rdfae:editor-state(), 'insertHost')[exists(rdfae:block-of(.))]"/>
            </xsl:call-template>
            <xsl:call-template name="rdfae:focus">
                <xsl:with-param name="element" select="$figcaption"/>
            </xsl:call-template>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
        <xsl:call-template name="rdfae:hide-dialogs"/>
    </xsl:template>

    <!-- ................................ drag-and-drop ................................ -->
    <!-- ported from LinkedDataHub client/block.xsl; handle-gated draggable because a
         permanently draggable contenteditable block breaks text selection -->

    <xsl:template match="span[contains-token(@class, 'drag-handle')]" mode="ixsl:onmousedown">
        <xsl:for-each select="rdfae:handle-block(.)">
            <ixsl:set-attribute name="draggable" select="'true'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="span[contains-token(@class, 'drag-handle')]" mode="ixsl:onmouseup">
        <xsl:for-each select="rdfae:handle-block(.)">
            <ixsl:remove-attribute name="draggable"/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:disarm-sweep"/>
    </xsl:template>

    <xsl:template match="*[@draggable = 'true'][rdfae:draggable-block(.)]" mode="ixsl:ondragstart">
        <xsl:variable name="transfer" select="ixsl:get(ixsl:event(), 'dataTransfer')"/>
        <!-- a block drag must never race an armed sweep -->
        <xsl:call-template name="rdfae:disarm-sweep"/>
        <ixsl:set-property name="draggedBlock" select="." object="rdfae:editor-state()"/>
        <ixsl:set-property name="effectAllowed" select="'move'" object="$transfer"/>
        <xsl:sequence select="ixsl:call($transfer, 'setData', [ 'application/vnd.atomgraph.rdfa-editor.block', '' ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call($transfer, 'setDragImage', [ ., 0, 0 ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- links cannot navigate on plain click inside contenteditable (the click
         places the caret for editing); the standard editor convention applies:
         Ctrl/Cmd+Click follows the link -->
    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')]//a[@href]" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="ixsl:get($event, 'ctrlKey') or ixsl:get($event, 'metaKey')">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:window(), 'open',
                [ string(resolve-uri(@href, rdfae:document-uri())), '_blank' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- images are natively draggable, so a drag starting on one would otherwise
         carry no block identity and snap back; treat it as dragging its innermost
         draggable block (the figure, wherever it nests) -->
    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')]//img" mode="ixsl:ondragstart">
        <xsl:variable name="transfer" select="ixsl:get(ixsl:event(), 'dataTransfer')"/>
        <xsl:call-template name="rdfae:disarm-sweep"/>
        <xsl:for-each select="ancestor-or-self::*[rdfae:draggable-block(.)][1]">
            <ixsl:set-property name="draggedBlock" select="." object="rdfae:editor-state()"/>
            <ixsl:set-property name="effectAllowed" select="'move'" object="$transfer"/>
            <xsl:sequence select="ixsl:call($transfer, 'setData', [ 'application/vnd.atomgraph.rdfa-editor.block', '' ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call($transfer, 'setDragImage', [ ., 0, 0 ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')] | *[contains-token(@class, 'rdfa-editor-content')]//*" mode="ixsl:ondragover">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="dragged" select="ixsl:get(rdfae:editor-state(), 'draggedBlock')"/>
        <xsl:variable name="target" as="element()?" select="rdfae:drop-target-of(., $event)"/>
        <xsl:if test="exists($dragged) and exists($target)
                and rdfae:has-transfer-type($event, 'application/vnd.atomgraph.rdfa-editor.block')">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <ixsl:set-property name="dropEffect" select="'move'" object="ixsl:get($event, 'dataTransfer')"/>
            <xsl:call-template name="rdfae:clear-drop-marks"/>
            <!-- a block target takes a before/after line; a cell target is entered
                 whole, so it highlights as a box -->
            <xsl:sequence select="ixsl:call(ixsl:get($target, 'classList'), 'add',
                [ if (not(rdfae:draggable-block($target))) then 'drop-into'
                    else if (rdfae:drop-before($event, $target)) then 'drop-before'
                    else 'drop-after' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')] | *[contains-token(@class, 'rdfa-editor-content')]//*" mode="ixsl:ondrop">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="dragged" select="ixsl:get(rdfae:editor-state(), 'draggedBlock')"/>
        <xsl:variable name="target" as="element()?" select="rdfae:drop-target-of(., $event)"/>
        <xsl:if test="exists($dragged) and exists($target)
                and rdfae:has-transfer-type($event, 'application/vnd.atomgraph.rdfa-editor.block')">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:clear-drop-marks"/>
            <!-- transient drag state must not reach the undo snapshot -->
            <xsl:for-each select="$dragged">
                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
                <ixsl:remove-attribute name="draggable"/>
                <xsl:call-template name="rdfae:tidy-class">
                    <xsl:with-param name="element" select="."/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="rdfae:push-undo"/>
            <!-- the vacated origin, captured before the move: the top-level block
                 (husk-prune scope) and the nearest flow container (collapse
                 candidate) - both empty for a top-level drag -->
            <xsl:variable name="origin-block" as="element()?"
                select="$dragged/parent::*[not(contains-token(@class, 'rdfa-editor-content'))]
                    ! rdfae:block-of(.)"/>
            <xsl:variable name="origin-flow" as="element()?"
                select="$dragged/ancestor::*[cm:flow(local-name(.))]
                    [not(contains-token(@class, 'rdfa-editor-content'))]
                    [exists(rdfae:block-of(.))][1]"/>
            <xsl:choose>
                <xsl:when test="rdfae:draggable-block($target)">
                    <xsl:sequence select="ixsl:call($target,
                        if (rdfae:drop-before($event, $target)) then 'before' else 'after',
                        [ $dragged ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:when>
                <!-- into a cell: the text host becomes a container (its runs wrapped,
                     the insert-block-at-caret flow doctrine) and the block appends -->
                <xsl:otherwise>
                    <xsl:for-each select="$target[@contenteditable = 'true']">
                        <ixsl:remove-attribute name="contenteditable"/>
                    </xsl:for-each>
                    <xsl:call-template name="rdfae:wrap-stray-runs">
                        <xsl:with-param name="container" select="$target"/>
                    </xsl:call-template>
                    <xsl:sequence select="ixsl:call($target, 'appendChild', [ $dragged ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- repair the origin: structural containers emptied by the lift-out go
                 (a quote whose only block left - B7 doctrine), then a flow container
                 that lost its last block reverts to a text host (both self-guard) -->
            <xsl:for-each select="$origin-block[exists(rdfae:root-of(.))]">
                <xsl:call-template name="rdfae:prune-husks">
                    <xsl:with-param name="scope" select="."/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="$origin-flow[exists(rdfae:root-of(.))]">
                <xsl:call-template name="rdfae:collapse-container">
                    <xsl:with-param name="container" select="."/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')] | *[contains-token(@class, 'rdfa-editor-content')]//*" mode="ixsl:ondragend">
        <!-- clean the actually-dragged block (the event target of a nested drag
             may be a descendant, so re-deriving from it would miss) -->
        <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'draggedBlock')">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
            <ixsl:remove-attribute name="draggable"/>
            <xsl:call-template name="rdfae:tidy-class">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:call-template name="rdfae:clear-drop-marks"/>
        <ixsl:set-property name="draggedBlock" select="()" object="rdfae:editor-state()"/>
    </xsl:template>

    <!-- dataTransfer.types marshals to an XDM array or sequence of strings -->
    <xsl:function name="rdfae:has-transfer-type" as="xs:boolean">
        <xsl:param name="event"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:variable name="types" select="ixsl:get(ixsl:get($event, 'dataTransfer'), 'types')"/>
        <xsl:sequence select="(if ($types instance of array(*)) then $types?* else $types) = $type"/>
    </xsl:function>

    <!-- the block to drop relative to: the innermost content-model-legal block
         under the pointer (a nested drop lands where the model admits the dragged
         kind, clamped upward to the nearest legal level otherwise - the resolver
         never produces invalid nesting), else the geometrically nearest top-level
         block by vertical midpoint - so gaps between blocks, the container padding
         and the (tall) dragged block itself are all valid drop zones instead of
         snapping the drag back. The gutter and gaps resolve top-level: dropping
         there lifts a nested block all the way out -->
    <xsl:function name="rdfae:drop-target-of" as="element()?">
        <xsl:param name="hit"/>
        <xsl:param name="event"/>
        <xsl:variable name="dragged" select="ixsl:get(rdfae:editor-state(), 'draggedBlock')"/>
        <!-- blocks never move between editable regions -->
        <xsl:variable name="root" as="element()?"
            select="($dragged ! rdfae:root-of(.), rdfae:root-of($hit))[1]"/>
        <xsl:variable name="deepest" as="element()?"
            select="rdfae:deepest-block-at($hit, $dragged)[rdfae:root-of(.) is $root]"/>
        <!-- a cell's pixels are unambiguous - nothing can legally drop before or
             after a td/th, so pointing into a cell (away from any block it holds)
             drops INTO it. A list item stays a clamp to around-the-list instead:
             its pixels compete with reordering next to the list, and Tab/indent
             already move content into items. Only CONTENT cells qualify: a cell
             inside ephemera or an island interior (a rendered chart or reference
             card paints real tables) is external rendering, never a drop zone -
             the pointer falls through to the island itself (before/after) -->
        <xsl:variable name="cell" as="element()?"
            select="$hit/ancestor-or-self::*[self::td or self::th]
                [empty(ancestor-or-self::*[@data-role])]
                [empty(ancestor::*[rdfae:island(.)])]
                [empty(ancestor-or-self::* intersect $dragged)]
                [rdfae:root-of(.) is $root][1]"/>
        <xsl:choose>
            <xsl:when test="exists($cell) and exists($dragged)
                    and cm:allows-child(local-name($cell), local-name($dragged))
                    and empty($deepest/ancestor::* intersect $cell)">
                <xsl:sequence select="$cell"/>
            </xsl:when>
            <xsl:when test="exists($deepest) and exists($dragged)">
                <xsl:sequence select="rdfae:legal-drop-level($deepest, $dragged)"/>
            </xsl:when>
            <!-- geometric fallback only within the dragged block's own region:
                 a pointer over another region is not a drop zone at all -->
            <xsl:when test="not(rdfae:root-of($hit) is $root)"/>
            <xsl:otherwise>
                <xsl:variable name="y" as="xs:double" select="xs:double(ixsl:get($event, 'clientY'))"/>
                <xsl:variable name="candidates" as="element()*"
                    select="$root/*[not(exists($dragged) and . is $dragged)]"/>
                <xsl:variable name="distances" as="xs:double*" select="$candidates
                    ! (let $rect := ixsl:call(., 'getBoundingClientRect', []) return
                        abs(xs:double(ixsl:get($rect, 'top')) + xs:double(ixsl:get($rect, 'height')) div 2 - $y))"/>
                <xsl:variable name="nearest" as="xs:integer?" select="index-of($distances, min($distances))[1]"/>
                <xsl:sequence select="$candidates[$nearest]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- above or below the vertical midpoint of the target block -->
    <xsl:function name="rdfae:drop-before" as="xs:boolean">
        <xsl:param name="event"/>
        <xsl:param name="target" as="element()"/>
        <xsl:variable name="rect" select="ixsl:call($target, 'getBoundingClientRect', [])"/>
        <xsl:sequence select="xs:double(ixsl:get($event, 'clientY')) - xs:double(ixsl:get($rect, 'top'))
            lt xs:double(ixsl:get($rect, 'height')) div 2"/>
    </xsl:function>

    <xsl:template name="rdfae:clear-drop-marks">
        <xsl:param name="scope" as="element()*" select="rdfae:roots()/descendant::*"/>
        <xsl:for-each select="$scope[contains-token(@class, 'drop-before')
                or contains-token(@class, 'drop-after') or contains-token(@class, 'drop-into')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'drop-before' ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'drop-after' ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'drop-into' ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:tidy-class">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ view source ................................ -->

    <!-- W3C Exclusive XML Canonicalization (the rdf:XMLLiteral value space) via the
         xml-c14n lib on the host page - LinkedDataHub's ldh:canonicalize-xml ported.
         parse-xml() is the XDM->DOM bridge: the lib walks browser DOM nodes, not
         Saxon's temporary trees -->
    <xsl:function name="rdfae:canonicalize-xml" as="xs:string">
        <xsl:param name="doc" as="document-node()"/>
        <xsl:variable name="js-function" select="ixsl:eval('(function (doc) { return window[''xml-c14n-sync.js'']().createCanonicaliser(''http://www.w3.org/2001/10/xml-exc-c14n#WithComments'').canonicaliseSync(doc.documentElement); })')"/>
        <xsl:sequence select="ixsl:call($js-function, 'call', [ (), $doc ])"/>
    </xsl:function>

    <xsl:template match="button[@id = 'view-source']" mode="ixsl:onclick">
        <xsl:variable name="canonical" as="element()?">
            <xsl:call-template name="cm:canonical-xhtml">
                <xsl:with-param name="content" select="rdfae:active-root()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="rdfae:show-output">
            <xsl:with-param name="title" select="'Canonical XHTML+RDFa'"/>
            <xsl:with-param name="text" select="rdfae:canonicalize-xml(parse-xml(serialize($canonical, map{ 'method': 'xml' })))"/>
            <xsl:with-param name="filename" select="'content.xhtml'"/>
            <xsl:with-param name="media-type" select="'application/xhtml+xml'"/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
