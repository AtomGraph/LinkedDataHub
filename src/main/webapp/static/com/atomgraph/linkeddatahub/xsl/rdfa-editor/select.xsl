<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
xmlns:cm="https://w3id.org/atomgraph/rdfa-editor/content-model#"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Cross-host selection: the gestures that create selections spanning editable
    hosts (Google-Docs model), select-all scoped to the editable region and
    deletion of selections that span editable hosts.

    Each block is its own contenteditable host, so the browser confines a
    native drag-selection to the host it starts in - it never crosses a host
    boundary (even a drag from the page background clamps on the first host it
    enters) and it refuses to edit a document-level selection that spans hosts.
    Docs-style selection is therefore synthesized: mousedown in a region arms a
    sweep anchor (caretRangeFromPoint); once the pointer leaves the anchor
    host, each mousemove rebuilds the selection anchor-to-pointer with
    setBaseAndExtent - the only Selection API that can express a backward
    selection, so dragging upward keeps the anchor fixed like Docs; mouseup
    disarms. Shift+Click extends from the standing anchor to the clicked point
    and re-arms it, so Shift+drag keeps extending; Shift+Up/Down extend the
    focus block-granularly past host edges (within a host they stay native).
    Every gesture clamps to one region. The result is a plain document-level
    selection: it paints natively across blocks, and one delete machine serves
    Ctrl/Cmd+A stage 2 and every synthetic gesture alike. Keyboard dispatch
    lives in edit.xsl (keydown, body keydown, paste gate); the machinery and
    the mouse gesture templates live here, mirroring the tables.xsl split.

    Deletion is block-granular, never one raw deleteContents across the range:
    fully covered blocks are removed whole, partial edge hosts get a
    sub-range delete scoped inside the host, and composites (table, figure)
    holding a range boundary never lose grid structure - their covered cells
    are cleared instead (B3/B4 doctrine: composites are hard boundaries).
    Non-composite edge remnants merge Google-Docs-style (the tail joins the
    head, caret at the seam). One gesture pushes one region-keyed undo entry.
-->

    <!-- ................................ predicates ................................ -->

    <!-- the host's content is entirely inside the selection (chrome- and
         placeholder-insensitive via the rdfae:at-* probes); an empty host counts
         as fully selected, so Ctrl+A escalates immediately where stage 1 would
         have nothing to select -->
    <xsl:function name="rdfae:host-fully-selected" as="xs:boolean">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="range"/>
        <xsl:sequence select="rdfae:block-text($host) = ''
            or (not(ixsl:get($range, 'collapsed'))
                and rdfae:at-start($host, $range) and rdfae:at-end($host, $range))"/>
    </xsl:function>

    <!-- true for a non-collapsed selection that engages an editable region but is
         not confined to a single host: the boundary hosts differ, or a boundary
         sits outside any host (region level, page background). Host-page
         contenteditables don't count (the rdfae:block-of clamp), and selections
         that never touch a region stay native -->
    <xsl:function name="rdfae:selection-crosses-hosts" as="xs:boolean">
        <xsl:variable name="range" select="rdfae:caret-range()"/>
        <xsl:choose>
            <xsl:when test="empty($range) or ixsl:get($range, 'collapsed')">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="start-host" as="element()?"
                    select="rdfae:host-of(ixsl:get($range, 'startContainer'))[exists(rdfae:block-of(.))]"/>
                <xsl:variable name="end-host" as="element()?"
                    select="rdfae:host-of(ixsl:get($range, 'endContainer'))[exists(rdfae:block-of(.))]"/>
                <xsl:sequence select="(empty($start-host) or empty($end-host) or not($start-host is $end-host))
                    and (some $root in rdfae:roots() satisfies ixsl:call($range, 'intersectsNode', [ $root ]))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- the node lies entirely inside the range: it intersects it and neither
         range boundary sits at or below the node (an offset in a parent points
         between children, so a boundary inside the node means its container is
         in the node's subtree - pure XDM containment, no compareBoundaryPoints) -->
    <xsl:function name="rdfae:covered-by" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="range"/>
        <xsl:sequence select="ixsl:call($range, 'intersectsNode', [ $node ])
            and empty(ixsl:get($range, 'startContainer')/ancestor-or-self::node()
                intersect $node/descendant-or-self::node())
            and empty(ixsl:get($range, 'endContainer')/ancestor-or-self::node()
                intersect $node/descendant-or-self::node())"/>
    </xsl:function>

    <!-- ................................ region select ................................ -->

    <!-- a document-level range over all of the region's blocks: it paints across
         host boundaries and never extends beyond the region. Focus stays where it
         was, so the same keydown template keeps firing -->
    <xsl:template name="rdfae:select-region">
        <xsl:param name="region" as="element()"/>
        <xsl:variable name="blocks" as="element()*" select="$region/*[not(@data-role)]"/>
        <xsl:if test="exists($blocks)">
            <xsl:variable name="range" select="ixsl:call(ixsl:page(), 'createRange', [])"/>
            <xsl:sequence select="ixsl:call($range, 'setStartBefore', [ $blocks[1] ])[current-date() lt xs:date('2000-01-01')],
                ixsl:call($range, 'setEndAfter', [ $blocks[last()] ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:variable name="selection" select="rdfae:selection()"/>
            <xsl:sequence select="ixsl:call($selection, 'removeAllRanges', [])[current-date() lt xs:date('2000-01-01')],
                ixsl:call($selection, 'addRange', [ $range ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- a clone of $range clamped to $region: boundaries outside the region (page
         content, another region) move to the region's extremes, and a boundary
         inside chrome moves out of the ephemeral subtree (the handle is not
         content). Shared by the delete machine and canonical copy -->
    <xsl:function name="rdfae:clamped-range" as="item()">
        <xsl:param name="range"/>
        <xsl:param name="region" as="element()"/>
        <xsl:variable name="all" as="element()*" select="$region/*[not(@data-role)]"/>
        <xsl:variable name="work" select="ixsl:call($range, 'cloneRange', [])"/>
        <xsl:if test="not(rdfae:root-of(ixsl:get($work, 'startContainer')) is $region)">
            <xsl:sequence select="ixsl:call($work, 'setStartBefore', [ $all[1] ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <xsl:if test="not(rdfae:root-of(ixsl:get($work, 'endContainer')) is $region)">
            <xsl:sequence select="ixsl:call($work, 'setEndAfter', [ $all[last()] ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <xsl:for-each select="(ixsl:get($work, 'startContainer')/ancestor-or-self::*[@data-role])[1]">
            <xsl:sequence select="ixsl:call($work, 'setStartAfter', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:for-each select="(ixsl:get($work, 'endContainer')/ancestor-or-self::*[@data-role])[1]">
            <xsl:sequence select="ixsl:call($work, 'setEndBefore', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- a boundary inside an object-block island moves out of it (after the
             chrome escape - the rendering div is chrome inside the island):
             islands join a selection whole, so the delete machine and canonical
             copy never see a boundary inside one -->
        <xsl:for-each select="(ixsl:get($work, 'startContainer')/ancestor-or-self::*[rdfae:island(.)])[1]">
            <xsl:sequence select="ixsl:call($work, 'setStartBefore', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:for-each select="(ixsl:get($work, 'endContainer')/ancestor-or-self::*[rdfae:island(.)])[1]">
            <xsl:sequence select="ixsl:call($work, 'setEndAfter', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:sequence select="$work"/>
    </xsl:function>

    <!-- ................................ selection gestures ................................ -->

    <!-- the document position under a viewport point, as map{'node','offset'}:
         caretRangeFromPoint (Chromium, Safari) or caretPositionFromPoint
         (Firefox). A position inside chrome moves out of the ephemeral subtree
         to just after it (mirroring rdfae:clamped-range); empty when the point
         resolves to nothing -->
    <xsl:function name="rdfae:caret-at-point" as="map(*)?">
        <xsl:param name="x" as="xs:double"/>
        <xsl:param name="y" as="xs:double"/>
        <xsl:variable name="raw" as="map(*)?">
            <xsl:choose>
                <xsl:when test="exists(ixsl:get(ixsl:page(), 'caretRangeFromPoint'))">
                    <xsl:for-each select="ixsl:call(ixsl:page(), 'caretRangeFromPoint', [ $x, $y ])">
                        <xsl:sequence select="map{
                            'node': ixsl:get(., 'startContainer'),
                            'offset': xs:integer(ixsl:get(., 'startOffset')) }"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="ixsl:call(ixsl:page(), 'caretPositionFromPoint', [ $x, $y ])">
                        <xsl:sequence select="map{
                            'node': ixsl:get(., 'offsetNode'),
                            'offset': xs:integer(ixsl:get(., 'offset')) }"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- one ancestor walk serves both probes: this runs per mousemove during a sweep -->
        <xsl:variable name="ancestors" as="element()*" select="$raw?node/ancestor-or-self::*"/>
        <xsl:variable name="island" as="element()?" select="($ancestors[rdfae:island(.)])[1]"/>
        <xsl:variable name="chrome" as="element()?" select="($ancestors[@data-role])[1]"/>
        <xsl:choose>
            <!-- a point inside an object-block island (its rendering or its RDFa
                 spans) escapes to just after the island: sweep anchors never sit
                 inside islands - checked first, the rendering div is chrome
                 inside the island -->
            <xsl:when test="exists($island)">
                <xsl:sequence select="map{
                    'node': $island/parent::node(),
                    'offset': count($island/preceding-sibling::node()) + 1 }"/>
            </xsl:when>
            <xsl:when test="exists($chrome)">
                <xsl:sequence select="map{
                    'node': $chrome/parent::node(),
                    'offset': count($chrome/preceding-sibling::node()) + 1 }"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$raw"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- a selection focus clamped into $region: a position outside it (page
         content, another region) becomes the region extreme on that side -
         one gesture, one region -->
    <xsl:function name="rdfae:clamp-focus-to-region" as="map(*)">
        <xsl:param name="node"/>
        <xsl:param name="offset" as="xs:integer"/>
        <xsl:param name="region" as="element()"/>
        <xsl:choose>
            <xsl:when test="rdfae:root-of($node) is $region">
                <xsl:sequence select="map{ 'node': $node, 'offset': $offset }"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="probe" select="ixsl:call(ixsl:page(), 'createRange', [])"/>
                <xsl:sequence select="ixsl:call($probe, 'selectNodeContents', [ $region ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:variable name="cmp" as="xs:integer" select="xs:integer(ixsl:call($probe, 'comparePoint', [ $node, $offset ]))"/>
                <xsl:choose>
                    <xsl:when test="$cmp lt 0">
                        <xsl:sequence select="map{ 'node': $region,
                            'offset': count($region/*[not(@data-role)][1]/preceding-sibling::node()) }"/>
                    </xsl:when>
                    <xsl:when test="$cmp gt 0">
                        <xsl:sequence select="map{ 'node': $region, 'offset': count($region/node()) }"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="map{ 'node': $node, 'offset': $offset }"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- move the selection focus, anchor fixed: setBaseAndExtent is the only
         Selection API that can express a backward selection (focus before
         anchor), which an upward drag or Shift+Click produces -->
    <xsl:template name="rdfae:extend-selection-to">
        <xsl:param name="anchor-node"/>
        <xsl:param name="anchor-offset" as="xs:integer"/>
        <xsl:param name="focus" as="map(*)"/>
        <xsl:sequence select="ixsl:call(rdfae:selection(), 'setBaseAndExtent',
            [ $anchor-node, $anchor-offset, $focus?node, $focus?offset ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template name="rdfae:disarm-sweep">
        <xsl:for-each select="('sweepAnchorNode', 'sweepAnchorHost', 'sweepRegion')">
            <ixsl:set-property name="{.}" select="()" object="rdfae:editor-state()"/>
        </xsl:for-each>
    </xsl:template>

    <!-- mousedown in a region: Shift extends the standing selection to the
         clicked point (the anchor never moves - preventDefault stops the
         native caret placement that would collapse it), a press on non-editable
         canvas places the caret at the point itself (no native placement exists
         there), and a plain primary press on a host arms a sweep anchor for the
         mousemove takeover (no preventDefault: native caret placement and
         in-host drags proceed untouched). SaxonJS dispatches an event at the
         innermost matching template only, so a press on the drag handle never
         reaches this (the handle owns its gesture) and chrome is guarded out
         explicitly -->
    <xsl:template match="*[contains-token(@class, 'rdfa-editor-content')]" mode="ixsl:onmousedown">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="region" as="element()" select="."/>
        <xsl:variable name="target" as="node()?" select="ixsl:get($event, 'target')"/>
        <xsl:variable name="button" as="xs:double" select="number(ixsl:get($event, 'button'))"/>
        <xsl:if test="$button = 0 and empty($target/ancestor-or-self::*[@data-role])">
            <xsl:variable name="anchor-node" as="node()?" select="rdfae:anchor-node()"/>
            <xsl:variable name="point" as="map(*)?" select="rdfae:caret-at-point(
                xs:double(ixsl:get($event, 'clientX')), xs:double(ixsl:get($event, 'clientY')))"/>
            <xsl:choose>
                <!-- an anchor outside any region is the host page's - never hijacked -->
                <xsl:when test="ixsl:get($event, 'shiftKey') = true()
                        and exists(rdfae:root-of($anchor-node)) and exists($point)">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:variable name="anchor-offset" as="xs:integer" select="rdfae:anchor-offset()"/>
                    <xsl:call-template name="rdfae:extend-selection-to">
                        <xsl:with-param name="anchor-node" select="$anchor-node"/>
                        <xsl:with-param name="anchor-offset" select="$anchor-offset"/>
                        <xsl:with-param name="focus" select="rdfae:clamp-focus-to-region(
                            $point?node, $point?offset, rdfae:root-of($anchor-node))"/>
                    </xsl:call-template>
                    <!-- re-arm from the same anchor so Shift+drag keeps extending; the
                         preventDefault killed the native drag session, so every move
                         must be synthetic (no anchor host) -->
                    <ixsl:set-property name="sweepAnchorNode" select="$anchor-node" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="sweepAnchorOffset" select="$anchor-offset" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="sweepAnchorHost" select="()" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="sweepRegion" select="rdfae:root-of($anchor-node)" object="rdfae:editor-state()"/>
                </xsl:when>
                <!-- a press that landed outside every editable host: the surface
                     between blocks, the handle gutter, a structural container's own
                     box. The browser has no caret to place there and no focusable
                     element below the region to focus, so the placement is ours -
                     the nearest host takes focus and the caret lands at the point,
                     rather than focus dropping off the canvas. A point that resolves
                     into a non-editable parent (rdfae:caret-at-point escapes islands
                     and chrome to a position beside them) has no host to focus and
                     nothing to place: it falls through to the region's own tabindex -->
                <xsl:when test="empty($target/ancestor-or-self::*[@contenteditable = 'true'])
                        and exists(rdfae:host-of($point?node))">
                    <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:call-template name="rdfae:focus-caret">
                        <xsl:with-param name="node" select="$point?node"/>
                        <xsl:with-param name="offset" select="$point?offset"/>
                    </xsl:call-template>
                    <!-- the preventDefault killed the native drag session, so a sweep
                         dragged out of here is synthetic throughout (no anchor host) -->
                    <ixsl:set-property name="sweepAnchorNode" select="$point?node" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="sweepAnchorOffset" select="$point?offset" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="sweepAnchorHost" select="()" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="sweepRegion" select="$region" object="rdfae:editor-state()"/>
                    <!-- focusin only fires when the host changes; a point in the same
                         host still moves the caret, so sync from the choke point -->
                    <xsl:call-template name="rdfae:update-breadcrumb"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$point">
                        <ixsl:set-property name="sweepAnchorNode" select="?node" object="rdfae:editor-state()"/>
                        <ixsl:set-property name="sweepAnchorOffset" select="?offset" object="rdfae:editor-state()"/>
                        <ixsl:set-property name="sweepAnchorHost"
                            select="rdfae:host-of(?node)[exists(rdfae:block-of(.))]" object="rdfae:editor-state()"/>
                        <ixsl:set-property name="sweepRegion" select="$region" object="rdfae:editor-state()"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- the sweep takeover: while a sweep is armed and the primary button is
         held, a pointer outside the anchor host rebuilds the selection from
         the stored anchor to the point under the pointer - the native
         drag-selection cannot cross host boundaries, so beyond them the
         selection is ours; inside the anchor host the native one is correct
         and untouched. The codebase's only mousemove template: the armed
         check comes first, one property read on the idle path. html catches
         moves over the body's margins -->
    <xsl:template match="body | html" mode="ixsl:onmousemove">
        <xsl:variable name="anchor-node" select="ixsl:get(rdfae:editor-state(), 'sweepAnchorNode')"/>
        <xsl:if test="exists($anchor-node)">
            <xsl:variable name="event" select="ixsl:event()"/>
            <xsl:choose>
                <!-- button released outside the window: the mouseup never fired -->
                <xsl:when test="number(ixsl:get($event, 'buttons')) ne 1">
                    <xsl:call-template name="rdfae:disarm-sweep"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="anchor-host" as="element()?" select="ixsl:get(rdfae:editor-state(), 'sweepAnchorHost')"/>
                    <xsl:variable name="target" as="node()?" select="ixsl:get($event, 'target')"/>
                    <xsl:if test="empty($anchor-host) or empty($target/ancestor-or-self::* intersect $anchor-host)">
                        <xsl:variable name="y" as="xs:double" select="xs:double(ixsl:get($event, 'clientY'))"/>
                        <xsl:variable name="point" as="map(*)?" select="rdfae:caret-at-point(
                            xs:double(ixsl:get($event, 'clientX')), $y)"/>
                        <!-- a point over floating editor UI does not move the focus -->
                        <xsl:if test="exists($point) and empty($point?node/ancestor-or-self::*[contains-token(@class, 'rdfa-editor-ui')])">
                            <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'sweepRegion')">
                                <xsl:call-template name="rdfae:extend-selection-to">
                                    <xsl:with-param name="anchor-node" select="$anchor-node"/>
                                    <xsl:with-param name="anchor-offset"
                                        select="xs:integer(ixsl:get(rdfae:editor-state(), 'sweepAnchorOffset'))"/>
                                    <xsl:with-param name="focus"
                                        select="rdfae:clamp-focus-to-region($point?node, $point?offset, .)"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:if>
                        <!-- native autoscroll died with the takeover: nudge the viewport
                             near its edges (advances only while the pointer moves) -->
                        <xsl:if test="$y lt 40">
                            <xsl:sequence select="ixsl:call(ixsl:window(), 'scrollBy', [ 0, -16 ])[current-date() lt xs:date('2000-01-01')]"/>
                        </xsl:if>
                        <xsl:if test="$y gt xs:double(ixsl:get(ixsl:window(), 'innerHeight')) - 40">
                            <xsl:sequence select="ixsl:call(ixsl:window(), 'scrollBy', [ 0, 16 ])[current-date() lt xs:date('2000-01-01')]"/>
                        </xsl:if>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- a sweep ending over the page background (the host and drag-handle
         mouseup templates disarm on their own paths - innermost-match
         dispatch means only one of them sees the event) -->
    <xsl:template match="body | html" mode="ixsl:onmouseup">
        <xsl:if test="exists(ixsl:get(rdfae:editor-state(), 'sweepAnchorNode'))">
            <xsl:call-template name="rdfae:disarm-sweep"/>
            <!-- no host mouseup fires out here: sync the breadcrumb ourselves -->
            <xsl:if test="rdfae:selection-crosses-hosts()">
                <xsl:call-template name="rdfae:update-breadcrumb"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- Shift+Up/Down handling gate: a cross-host selection cannot be extended
         natively at all, and a within-host focus at the host's edge facing the
         arrow is where native extension clamps - both are ours; anywhere else
         native line-wise extension is right. Probes run from the FOCUS: the
         range end is not the focus in a backward selection -->
    <xsl:function name="rdfae:shift-arrow-extends" as="xs:boolean">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="direction" as="xs:string"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:choose>
            <xsl:when test="rdfae:selection-crosses-hosts()">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="ixsl:get($selection, 'rangeCount') lt 1">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="focus-node" select="ixsl:get($selection, 'focusNode')"/>
                <xsl:variable name="focus-offset" as="xs:integer" select="xs:integer(ixsl:get($selection, 'focusOffset'))"/>
                <xsl:choose>
                    <xsl:when test="empty($focus-node/ancestor-or-self::* intersect $host)">
                        <xsl:sequence select="false()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="probe" select="ixsl:call(ixsl:page(), 'createRange', [])"/>
                        <xsl:choose>
                            <xsl:when test="$direction = 'down'">
                                <xsl:sequence select="ixsl:call($probe, 'setStart', [ $focus-node, $focus-offset ])[current-date() lt xs:date('2000-01-01')],
                                    ixsl:call($probe, 'setEnd', [ $host, xs:integer(ixsl:get($host, 'childNodes.length')) ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="ixsl:call($probe, 'setStart', [ $host, rdfae:chrome-count($host) ])[current-date() lt xs:date('2000-01-01')],
                                    ixsl:call($probe, 'setEnd', [ $focus-node, $focus-offset ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:sequence select="string(ixsl:call($probe, 'toString', [])) = ''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- block-granular focus stepping for Shift+Up/Down: the anchor stays, the
         focus moves between region-level positions - whole top-level blocks
         enter or leave the selection, composites always as one unit. From
         inside a block the first step lands just past (before) it; stepping
         across the anchor flips the selection direction; the extremes are
         no-ops -->
    <xsl:template name="rdfae:extend-selection-block-wise">
        <xsl:param name="direction" as="xs:string"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1">
            <xsl:variable name="focus-node" select="ixsl:get($selection, 'focusNode')"/>
            <xsl:variable name="focus-offset" as="xs:integer" select="xs:integer(ixsl:get($selection, 'focusOffset'))"/>
            <xsl:for-each select="rdfae:root-of($focus-node)">
                <xsl:variable name="region" as="element()" select="."/>
                <xsl:variable name="blocks" as="element()*" select="*[not(@data-role)]"/>
                <xsl:variable name="focus-block" as="element()?" select="rdfae:block-of($focus-node)"/>
                <!-- the focus as a region-level coordinate: inside a block it
                     counts as just inside the edge facing the step -->
                <xsl:variable name="current" as="xs:integer" select="
                    if (exists($focus-block))
                    then count($focus-block/preceding-sibling::node()) + (if ($direction = 'up') then 1 else 0)
                    else $focus-offset"/>
                <xsl:variable name="target-block" as="element()?" select="
                    if ($direction = 'down')
                    then $blocks[count(preceding-sibling::node()) + 1 gt $current][1]
                    else $blocks[count(preceding-sibling::node()) lt $current][last()]"/>
                <xsl:for-each select="$target-block">
                    <xsl:call-template name="rdfae:extend-selection-to">
                        <xsl:with-param name="anchor-node" select="ixsl:get($selection, 'anchorNode')"/>
                        <xsl:with-param name="anchor-offset" select="xs:integer(ixsl:get($selection, 'anchorOffset'))"/>
                        <xsl:with-param name="focus" select="map{ 'node': $region,
                            'offset': count(preceding-sibling::node()) + (if ($direction = 'down') then 1 else 0) }"/>
                    </xsl:call-template>
                    <xsl:sequence select="ixsl:call(., 'scrollIntoView',
                        [ map{ 'block': 'nearest' } ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- ................................ canonical copy / cut ................................ -->

    <!-- a cross-host selection is copied in its storage form: the editing DOM
         (chrome, contenteditable, marker classes) would otherwise travel to the
         clipboard's HTML flavor. The fragment runs the same canonical +
         cm:normalize pipeline as paste, in reverse; RDFa attributes survive, so
         annotated content round-trips between documents. Within-host copy stays
         native. The union match covers both dispatch shapes: the focused host,
         or body after a background-origin sweep -->
    <xsl:template match="*[@contenteditable = 'true'] | body" mode="ixsl:oncopy">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="rdfae:selection-crosses-hosts()">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:copy-selection">
                <xsl:with-param name="event" select="$event"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- cut = canonical copy + the delete machine (one region-keyed undo entry) -->
    <xsl:template match="*[@contenteditable = 'true'] | body" mode="ixsl:oncut">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="rdfae:selection-crosses-hosts()">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:copy-selection">
                <xsl:with-param name="event" select="$event"/>
            </xsl:call-template>
            <xsl:call-template name="rdfae:delete-cross-host-selection"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="rdfae:copy-selection">
        <xsl:param name="event"/>
        <xsl:variable name="range" select="rdfae:caret-range()"/>
        <xsl:variable name="region" as="element()?"
            select="(rdfae:root-of(ixsl:get($range, 'startContainer')),
                rdfae:roots()[ixsl:call($range, 'intersectsNode', [ . ])])[1]"/>
        <xsl:for-each select="$region[exists(*[not(@data-role)])]">
            <xsl:variable name="work" select="rdfae:clamped-range($range, .)"/>
            <!-- cloneContents keeps partially-selected ancestors as shells, so the
                 fragment stays block-shaped; the carrier div mirrors paste-html -->
            <xsl:variable name="carrier" as="element()" select="rdfae:element('div')"/>
            <xsl:sequence select="ixsl:call($carrier, 'appendChild',
                [ ixsl:call($work, 'cloneContents', []) ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:variable name="pass1">
                <xsl:apply-templates select="$carrier/node()" mode="cm:canonical"/>
            </xsl:variable>
            <xsl:variable name="clean">
                <xsl:sequence select="cm:normalize($pass1/node())"/>
            </xsl:variable>
            <xsl:variable name="data" select="ixsl:get($event, 'clipboardData')"/>
            <xsl:sequence select="ixsl:call($data, 'setData', [ 'text/html',
                serialize($clean/node(), map{ 'method': 'html' }) ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call($data, 'setData', [ 'text/plain',
                string-join($clean/node()[normalize-space()] ! normalize-space(.), '&#10;') ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ delete machine ................................ -->

    <!-- delete a cross-host selection: reads and classification first, one undo
         push, then the mutations in fixed order. Reached from the host and body
         keydown dispatchers (edit.xsl) -->
    <xsl:template name="rdfae:delete-cross-host-selection">
        <xsl:variable name="range" select="rdfae:caret-range()"/>
        <xsl:if test="exists($range) and not(ixsl:get($range, 'collapsed'))">
            <!-- the single region this gesture acts on: the start's region, else
                 the first region the sweep reaches (one gesture = one region-keyed
                 history entry; blocks never leave their region) -->
            <xsl:variable name="region" as="element()?"
                select="(rdfae:root-of(ixsl:get($range, 'startContainer')),
                    rdfae:roots()[ixsl:call($range, 'intersectsNode', [ . ])])[1]"/>
            <xsl:variable name="all" as="element()*" select="$region/*[not(@data-role)]"/>
            <xsl:if test="exists($all)">
                <xsl:variable name="work" select="rdfae:clamped-range($range, $region)"/>
                <xsl:variable name="blocks" as="element()*" select="$all[ixsl:call($work, 'intersectsNode', [ . ])]"/>
                <xsl:if test="exists($blocks) and not(ixsl:get($work, 'collapsed'))">
                    <!-- boundary hosts (a partial edge is an edge with a boundary
                         host); clamped boundaries sit at region level - no host -->
                    <xsl:variable name="start-host" as="element()?"
                        select="rdfae:host-of(ixsl:get($work, 'startContainer'))[rdfae:root-of(.) is $region]"/>
                    <xsl:variable name="end-host" as="element()?"
                        select="rdfae:host-of(ixsl:get($work, 'endContainer'))[rdfae:root-of(.) is $region]"/>
                    <!-- only the two edge blocks can be partially covered -->
                    <xsl:variable name="head-block" as="element()?" select="$blocks[1][not(rdfae:covered-by(., $work))]"/>
                    <xsl:variable name="tail-block" as="element()?" select="$blocks[last()][not(rdfae:covered-by(., $work))]"/>
                    <xsl:variable name="partial-blocks" as="element()*" select="$head-block | $tail-block"/>
                    <!-- composites holding a range boundary: their structure is
                         never ripped (composites are hard boundaries - B3/B4) -->
                    <xsl:variable name="partial-composites" as="element()*"
                        select="$partial-blocks/descendant-or-self::*[self::table or self::figure]
                            [ixsl:call($work, 'intersectsNode', [ . ])][not(rdfae:covered-by(., $work))]"/>
                    <!-- removals: covered blocks whole, plus the maximal covered
                         fragments of the edge blocks - except grid parts of a
                         boundary-holding composite (rows, cells, captions, the
                         figure image), which survive with their content cleared -->
                    <xsl:variable name="removals" as="element()*" select="
                        $blocks[rdfae:covered-by(., $work)]
                        | $partial-blocks/descendant::*
                            [not(ancestor-or-self::*[@data-role])]
                            [not((self::tbody or self::thead or self::tfoot or self::tr
                                or self::td or self::th or self::caption or self::figcaption or self::img)
                                and exists(ancestor::*[self::table or self::figure]))]
                            [rdfae:covered-by(., $work)]
                            [not(rdfae:covered-by(.., $work))]"/>
                    <!-- covered cells of a boundary-holding composite: cleared, kept -->
                    <xsl:variable name="clears" as="element()*" select="
                        $partial-blocks/descendant::*[self::td or self::th or self::caption or self::figcaption]
                            [exists(ancestor::*[self::table or self::figure])]
                            [rdfae:covered-by(., $work)]
                            [not(rdfae:covered-by((ancestor::*[self::table or self::figure])[last()], $work))]"/>
                    <!-- flow containers of the edge blocks touched by the range:
                         after the removals they may have lost their last block
                         (never an island - a div island must not become a text host) -->
                    <xsl:variable name="collapse-candidates" as="element()*" select="
                        $partial-blocks/descendant::*[cm:flow(local-name(.))][not(self::figure)]
                            [not(rdfae:island(.))]
                            [not(@contenteditable = 'true')]
                            [ixsl:call($work, 'intersectsNode', [ . ])]"/>
                    <!-- caret fallbacks for a fully-covered sweep: the untouched
                         neighbors of the swept range -->
                    <xsl:variable name="next-block" as="element()?" select="$blocks[last()]/following-sibling::*[not(@data-role)][1]"/>
                    <xsl:variable name="prev-block" as="element()?" select="$blocks[1]/preceding-sibling::*[not(@data-role)][1]"/>
                    <!-- remnants merge (Google Docs) only between plain text hosts:
                         never across a composite boundary, never with pre (B6) -->
                    <xsl:variable name="merge" as="xs:boolean" select="exists($start-host) and exists($end-host)
                        and not($start-host is $end-host)
                        and empty($start-host/ancestor::* intersect $partial-composites)
                        and empty($end-host/ancestor::* intersect $partial-composites)
                        and empty(($start-host, $end-host)/self::pre)"/>
                    <!-- sub-ranges for the partial edge hosts, cloned before any
                         mutation (a range scoped to one host cannot escape it) -->
                    <xsl:variable name="head-sub" select="if (exists($start-host)) then ixsl:call($work, 'cloneRange', []) else ()"/>
                    <xsl:for-each select="$start-host">
                        <xsl:sequence select="ixsl:call($head-sub, 'setEnd', [ ., xs:integer(ixsl:get(., 'childNodes.length')) ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    <xsl:variable name="tail-sub" select="if (exists($end-host)) then ixsl:call($work, 'cloneRange', []) else ()"/>
                    <xsl:for-each select="$end-host">
                        <xsl:sequence select="ixsl:call($tail-sub, 'setStart', [ ., 0 ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>

                    <!-- mutate: one region-keyed history entry, snapshot first -->
                    <xsl:call-template name="rdfae:push-undo">
                        <xsl:with-param name="root" select="$region"/>
                    </xsl:call-template>
                    <xsl:for-each select="$head-sub, $tail-sub">
                        <xsl:sequence select="ixsl:call(., 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    <xsl:for-each select="$clears">
                        <xsl:call-template name="rdfae:clear-host">
                            <xsl:with-param name="host" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <xsl:for-each select="$removals">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    <!-- the seam: the first text node of the tail remnant, captured
                         before the merge moves it (the reference rides through the
                         move and any container collapse - B4c) -->
                    <xsl:variable name="seam-text" as="text()?"
                        select="($end-host//text()[not(ancestor::*[@data-role])])[1]"/>
                    <xsl:if test="$merge">
                        <xsl:call-template name="rdfae:merge-into-previous">
                            <xsl:with-param name="host" select="$end-host"/>
                            <xsl:with-param name="prev" select="$start-host"/>
                        </xsl:call-template>
                    </xsl:if>
                    <!-- structural containers emptied by the deletion or the merge -->
                    <xsl:for-each select="($head-block, $tail-block)[exists(rdfae:root-of(.))]">
                        <xsl:call-template name="rdfae:prune-husks">
                            <xsl:with-param name="scope" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <!-- flow containers that lost their last block revert to text hosts -->
                    <xsl:for-each select="$collapse-candidates[exists(rdfae:root-of(.))]">
                        <xsl:call-template name="rdfae:collapse-container">
                            <xsl:with-param name="container" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <xsl:for-each select="($start-host, $end-host)[exists(rdfae:root-of(.))][@contenteditable = 'true']">
                        <xsl:call-template name="rdfae:ensure-placeholder">
                            <xsl:with-param name="host" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <!-- a boundary at a block's very edge can sweep the handle away:
                         re-inject (idempotent, top-level only) -->
                    <xsl:for-each select="$region/*[not(@data-role)]">
                        <xsl:call-template name="rdfae:inject-chrome">
                            <xsl:with-param name="block" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
                    <xsl:choose>
                        <!-- everything went: reseed so the region can hold a caret -->
                        <xsl:when test="empty($region/*[not(@data-role)])">
                            <xsl:call-template name="rdfae:seed-region">
                                <xsl:with-param name="region" select="$region"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$merge and exists($seam-text) and exists(rdfae:host-of($seam-text))">
                            <xsl:call-template name="rdfae:focus-caret">
                                <xsl:with-param name="node" select="$seam-text"/>
                                <xsl:with-param name="offset" select="0"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="exists(rdfae:last-host-in($head-block[exists(rdfae:root-of(.))]))">
                            <xsl:for-each select="rdfae:last-host-in($head-block)">
                                <xsl:call-template name="rdfae:focus-caret">
                                    <xsl:with-param name="node" select="."/>
                                    <xsl:with-param name="offset"
                                        select="count(node()) - count(node()[last()][self::br])"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="exists(rdfae:first-host-in($tail-block[exists(rdfae:root-of(.))]))">
                            <xsl:for-each select="rdfae:first-host-in($tail-block)">
                                <xsl:call-template name="rdfae:focus-caret">
                                    <xsl:with-param name="node" select="."/>
                                    <xsl:with-param name="offset" select="rdfae:chrome-count(.)"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="exists(rdfae:first-host-in($next-block))">
                            <xsl:for-each select="rdfae:first-host-in($next-block)">
                                <xsl:call-template name="rdfae:focus-caret">
                                    <xsl:with-param name="node" select="."/>
                                    <xsl:with-param name="offset" select="rdfae:chrome-count(.)"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:when>
                        <!-- a neighboring island has no host to land in: select it -->
                        <xsl:when test="rdfae:island($next-block)">
                            <xsl:call-template name="rdfae:select-island">
                                <xsl:with-param name="element" select="$next-block"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="rdfae:island($prev-block)">
                            <xsl:call-template name="rdfae:select-island">
                                <xsl:with-param name="element" select="$prev-block"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="rdfae:last-host-in($prev-block)">
                                <xsl:call-template name="rdfae:focus-caret">
                                    <xsl:with-param name="node" select="."/>
                                    <xsl:with-param name="offset"
                                        select="count(node()) - count(node()[last()][self::br])"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- type-to-replace: after the delete machine has collapsed the caret into a
         host, the typed character lands there - one gesture, one undo entry (the
         machine's push; the insert rides the same snapshot) -->
    <xsl:template name="rdfae:insert-text-at-caret">
        <xsl:param name="text" as="xs:string"/>
        <xsl:variable name="range" select="rdfae:caret-range()"/>
        <xsl:for-each select="$range[ixsl:get(., 'collapsed')]">
            <xsl:for-each select="rdfae:host-of(ixsl:get(., 'startContainer'))[exists(rdfae:block-of(.))]">
                <xsl:variable name="node" select="ixsl:call(ixsl:page(), 'createTextNode', [ $text ])"/>
                <xsl:sequence select="ixsl:call($range, 'insertNode', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:call-template name="rdfae:place-caret">
                    <xsl:with-param name="node" select="$node"/>
                    <xsl:with-param name="offset" select="string-length($text)"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ cleanup helpers ................................ -->

    <!-- empty a covered cell keeping the grid: content out, then a flow cell
         reverts to a text host (collapse handles editability and placeholder),
         an inline-only host (caption) just gets its placeholder back -->
    <xsl:template name="rdfae:clear-host">
        <xsl:param name="host" as="element()"/>
        <xsl:for-each select="1 to xs:integer(ixsl:get($host, 'childNodes.length'))">
            <xsl:sequence select="ixsl:call($host, 'removeChild', [ ixsl:get($host, 'firstChild') ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="cm:flow(local-name($host))">
                <xsl:call-template name="rdfae:collapse-container">
                    <xsl:with-param name="container" select="$host"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:ensure-placeholder">
                    <xsl:with-param name="host" select="$host"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- remove structural containers emptied by a deletion (a list whose items
         all went, a quote whose blocks all went), innermost first, re-probing
         after each removal so emptiness cascades upward -->
    <xsl:template name="rdfae:prune-husks">
        <xsl:param name="scope" as="element()"/>
        <xsl:variable name="husk" as="element()?" select="($scope/descendant-or-self::*
            [self::ul or self::ol or self::dl or self::blockquote]
            [empty(*[not(@data-role)])][not(text()[normalize-space()])])[last()]"/>
        <xsl:for-each select="$husk">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:if test="not(. is $scope)">
                <xsl:call-template name="rdfae:prune-husks">
                    <xsl:with-param name="scope" select="$scope"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- an emptied region cannot hold a caret: seed a fresh paragraph host (the
         empty-blockquote idiom with the region as explicit parent) -->
    <xsl:template name="rdfae:seed-region">
        <xsl:param name="region" as="element()"/>
        <xsl:variable name="p" as="element()" select="rdfae:element('p')"/>
        <xsl:sequence select="ixsl:call($p, 'appendChild', [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$p"/>
        <xsl:sequence select="ixsl:call($region, 'appendChild', [ $p ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:inject-chrome">
            <xsl:with-param name="block" select="$p"/>
        </xsl:call-template>
        <xsl:call-template name="rdfae:focus-caret">
            <xsl:with-param name="node" select="$p"/>
            <xsl:with-param name="offset" select="rdfae:chrome-count($p)"/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
