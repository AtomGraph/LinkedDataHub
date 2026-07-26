<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:local="urn:rdfa-editor:functions"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Unified snapshot undo/redo: one whole-document history over #content innerHTML.
    Every mutating handler pushes a snapshot first and calls local:after-mutation last;
    plain typing is
    coalesced into ~1s bursts via ixsl:onbeforeinput. Ctrl/Cmd+Z and Shift+Z / Ctrl+Y
    are intercepted in the keydown dispatcher (edit.xsl) - native undo is replaced.

    Storage: hidden DOM stash divs (one child div per snapshot, textContent = the
    innerHTML string). JS arrays are unusable across the IXSL boundary (they marshal
    to XDM sequences; an empty array becomes an empty sequence) and sequence-valued
    window properties store only their first item - the DOM stash uses only proven
    primitives and gives O(1) push/pop. It carries data-role="storage", so the
    extractor skips it; it lives outside #content, so canonicalization never sees it.

    Caret restoration after undo/redo is approximate (first editable host): exact
    restoration would require serializing Range endpoints into content-polluting
    markers, which the canonicalization contract forbids.
-->

    <xsl:variable name="local:max-undo" as="xs:integer" select="100"/>

    <xsl:template name="local:init-undo">
        <xsl:for-each select="ixsl:page()//body">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div id="rdfa-editor-undo-storage" data-role="storage" style="display: none;">
                    <div id="rdfa-editor-undo-stack"/>
                    <div id="rdfa-editor-redo-stack"/>
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- append a snapshot entry, enforcing the depth cap. The caret position of the
         state being snapshotted rides along as data attributes (the stash lives
         outside #content, so data attributes are fine here) -->
    <xsl:template name="local:stash-push">
        <xsl:param name="stack" as="element()"/>
        <xsl:param name="snapshot" as="xs:string"/>
        <xsl:param name="root" as="element()"/>

        <xsl:variable name="entry" as="element()" select="local:element('div')"/>
        <ixsl:set-property name="textContent" select="$snapshot" object="$entry"/>
        <!-- histories are keyed by editable region -->
        <ixsl:set-attribute name="data-root"
            select="string(count(local:roots()[. &lt;&lt; $root]) + 1)" object="$entry"/>
        <xsl:call-template name="local:capture-caret">
            <xsl:with-param name="entry" select="$entry"/>
            <xsl:with-param name="root" select="$root"/>
        </xsl:call-template>
        <xsl:sequence select="ixsl:call($stack, 'appendChild', [ $entry ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:for-each select="($stack/div)[position() le count($stack/div) - $local:max-undo]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- caret as (block index, chrome-free text-node index, character offset);
         captured only when the selection anchors a text node inside content -->
    <xsl:template name="local:capture-caret">
        <xsl:param name="entry" as="element()"/>
        <xsl:param name="root" as="element()"/>

        <xsl:variable name="selection" select="local:selection()"/>
        <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1">
            <xsl:variable name="anchor" select="ixsl:get($selection, 'anchorNode')"/>
            <xsl:if test="ixsl:get($anchor, 'nodeType') = 3 and (local:root-of($anchor) ! (. is $root))">
                <xsl:for-each select="local:block-of($anchor)">
                    <xsl:variable name="texts" select=".//text()[not(ancestor::*[@data-role])]"/>
                    <xsl:if test="exists($texts[. is $anchor])">
                        <ixsl:set-attribute name="data-block"
                            select="string(count(preceding-sibling::*) + 1)" object="$entry"/>
                        <ixsl:set-attribute name="data-node"
                            select="string(count($texts[. &lt;&lt; $anchor]) + 1)" object="$entry"/>
                        <ixsl:set-attribute name="data-offset"
                            select="string(ixsl:get($selection, 'anchorOffset'))" object="$entry"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- record the pre-mutation state; call FIRST in every mutating handler.
         $snapshot allows capturing before an operation that may fail (wrap-range)
         and pushing only on success -->
    <xsl:template name="local:push-undo">
        <xsl:param name="host" as="element()?" select="()"/>
        <xsl:param name="root" as="element()?" select="($host ! local:root-of(.), local:active-root())[1]"/>
        <xsl:param name="snapshot" as="xs:string?" select="$root ! string(ixsl:get(., 'innerHTML'))"/>

        <xsl:for-each select="$root[exists($snapshot)]">
            <xsl:variable name="stack" as="element()" select="id('rdfa-editor-undo-stack', ixsl:page())"/>
            <xsl:variable name="root-index" as="xs:integer" select="count(local:roots()[. &lt;&lt; current()]) + 1"/>
            <xsl:variable name="top" as="element()?" select="($stack/div)[last()]"/>
            <!-- dedup guard: the same region's unchanged snapshot is a no-op -->
            <xsl:if test="not(string($top) eq $snapshot and xs:integer($top/@data-root) eq $root-index)">
                <xsl:call-template name="local:stash-push">
                    <xsl:with-param name="stack" select="$stack"/>
                    <xsl:with-param name="snapshot" select="$snapshot"/>
                    <xsl:with-param name="root" select="."/>
                </xsl:call-template>
                <ixsl:set-property name="textContent" select="''" object="id('rdfa-editor-redo-stack', ixsl:page())"/>
            </xsl:if>
        </xsl:for-each>
        <ixsl:set-property name="lastUndoTime"
            select="ixsl:call(ixsl:get(ixsl:window(), 'Date'), 'now', [])" object="local:editor-state()"/>
        <ixsl:set-property name="lastUndoHost" select="$host" object="local:editor-state()"/>
    </xsl:template>

    <!-- undo and redo are the same move with the stacks swapped: pop $from,
         push the popped entry's region's current state raw onto $to (raw: never
         clears the redo stack - only local:push-undo does), restore -->
    <xsl:template name="local:shift-history">
        <xsl:param name="from" as="xs:string"/>
        <xsl:param name="to" as="xs:string"/>

        <xsl:for-each select="(id($from, ixsl:page())/div)[last()]">
            <xsl:variable name="root-index" as="xs:integer" select="xs:integer(@data-root)"/>
            <xsl:variable name="root" as="element()?" select="local:roots()[$root-index]"/>
            <xsl:call-template name="local:stash-push">
                <xsl:with-param name="stack" select="id($to, ixsl:page())"/>
                <xsl:with-param name="snapshot" select="$root ! string(ixsl:get(., 'innerHTML'))"/>
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
            <xsl:variable name="snapshot" as="xs:string" select="string(.)"/>
            <xsl:variable name="caret" as="xs:integer*" select="(@data-block, @data-node, @data-offset) ! xs:integer(.)"/>
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="local:restore-snapshot">
                <xsl:with-param name="snapshot" select="$snapshot"/>
                <xsl:with-param name="caret" select="$caret"/>
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="local:apply-undo">
        <xsl:call-template name="local:shift-history">
            <xsl:with-param name="from" select="'rdfa-editor-undo-stack'"/>
            <xsl:with-param name="to" select="'rdfa-editor-redo-stack'"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="local:apply-redo">
        <xsl:call-template name="local:shift-history">
            <xsl:with-param name="from" select="'rdfa-editor-redo-stack'"/>
            <xsl:with-param name="to" select="'rdfa-editor-undo-stack'"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="local:restore-snapshot">
        <xsl:param name="snapshot" as="xs:string"/>
        <xsl:param name="caret" as="xs:integer*" select="()"/>
        <xsl:param name="root" as="element()?"/>

        <xsl:for-each select="$root">
            <ixsl:set-property name="innerHTML" select="$snapshot" object="."/>
            <!-- the HTML fragment parser foster-parents non-table content out of a
                 <table>, so a chrome span serialized inside a (possibly nested)
                 table lands astray on restore. Strip every handle and re-converge
                 (deterministic: first-child prepend on each draggable block); must
                 precede caret resolution, which indexes $root/* -->
            <xsl:for-each select="descendant::*[@data-role = 'chrome']">
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
            <xsl:call-template name="local:ensure-chrome">
                <xsl:with-param name="scope" select="."/>
            </xsl:call-template>
            <!-- snapshots carry island rendering markup, so restores are normally
                 render-stable; only islands captured mid-render (no rendering div -
                 async renderers inject it in the completion callback only) re-fire -->
            <xsl:for-each select="descendant-or-self::*[local:island(.)][empty(*[@data-role = 'rendering'])]">
                <xsl:apply-templates select="." mode="local:render-island"/>
            </xsl:for-each>
        </xsl:for-each>
        <!-- every stored node reference is stale now -->
        <xsl:call-template name="local:hide-overlay"/>
        <xsl:call-template name="local:hide-dialogs"/>
        <xsl:for-each select="('activeBlock', 'editingSpan', 'draggedBlock', 'editRange', 'editingLink',
                'insertHost', 'range', 'breadcrumbLeaf', 'findNode', 'lastUndoHost',
                'draggedSectionHeading', 'slashHost', 'sweepAnchorNode', 'sweepAnchorHost', 'sweepRegion')">
            <ixsl:set-property name="{.}" select="()" object="local:editor-state()"/>
        </xsl:for-each>
        <ixsl:set-property name="lastUndoTime" select="0" object="local:editor-state()"/>
        <!-- snapshots taken mid-drag may carry transient drag state -->
        <xsl:call-template name="local:clear-drop-marks"/>
        <xsl:for-each select="$root/descendant::*[@draggable]">
            <ixsl:remove-attribute name="draggable"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="local:tidy-class">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:for-each>
        <!-- the caret stored with a snapshot is the caret of that state: restore it -->
        <xsl:variable name="block-index" as="xs:integer?" select="$caret[1]"/>
        <xsl:variable name="node-index" as="xs:integer?" select="$caret[2]"/>
        <xsl:variable name="target" as="text()?"
            select="(($root/*)[$block-index]//text()[not(ancestor::*[@data-role])])[$node-index]"/>
        <xsl:choose>
            <xsl:when test="exists($target)">
                <xsl:for-each select="local:host-of($target)">
                    <xsl:call-template name="local:focus">
                        <xsl:with-param name="element" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:call-template name="local:place-caret">
                    <xsl:with-param name="node" select="$target"/>
                    <xsl:with-param name="offset" select="min(($caret[3], string-length($target)))"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="($root/descendant-or-self::*[@contenteditable = 'true'])[1]">
                    <xsl:call-template name="local:focus-caret">
    <xsl:with-param name="node" select="."/>
    <xsl:with-param name="offset" select="local:chrome-count(.)"/>
</xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="local:after-mutation"/>
    </xsl:template>

    <!-- coalesced typing history: beforeinput fires pre-mutation for typing, native
         deletes and cut, so a burst boundary snapshot captures the state before it -->
    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onbeforeinput">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="exists(local:block-of(.))">
            <xsl:variable name="type" as="xs:string" select="string(ixsl:get($event, 'inputType'))"/>
            <xsl:choose>
                <!-- menu-driven Edit > Undo/Redo bypasses keydown -->
                <xsl:when test="starts-with($type, 'history')">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:choose>
                        <xsl:when test="$type = 'historyUndo'">
                            <xsl:call-template name="local:apply-undo"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="local:apply-redo"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Date.now via ixsl:call is a deliberate last resort: current-dateTime()
                         is stable across event invocations in SaxonJS (probed), so it cannot
                         detect burst boundaries -->
                    <xsl:variable name="now" as="xs:double" select="ixsl:call(ixsl:get(ixsl:window(), 'Date'), 'now', [])"/>
                    <xsl:if test="$now - xs:double((ixsl:get(local:editor-state(), 'lastUndoTime'), 0)[1]) gt 1000
                            or not(ixsl:get(local:editor-state(), 'lastUndoHost') ! (. is current()))">
                        <xsl:call-template name="local:push-undo">
                            <xsl:with-param name="host" select="."/>
                        </xsl:call-template>
                        <xsl:call-template name="local:after-mutation"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- the single post-mutation refresh hook: chrome convergence (a gesture may
         have built nested draggable blocks), lint markers, live ToC, breadcrumb -->
    <xsl:template name="local:after-mutation">
        <xsl:call-template name="local:ensure-chrome"/>
        <xsl:call-template name="local:run-lint"/>
        <xsl:if test="id('toc-drawer', ixsl:page()) ! (ixsl:get(., 'style.display') ne 'none')">
            <xsl:call-template name="local:render-toc"/>
        </xsl:if>
        <xsl:call-template name="local:update-breadcrumb"/>
    </xsl:template>

</xsl:stylesheet>
