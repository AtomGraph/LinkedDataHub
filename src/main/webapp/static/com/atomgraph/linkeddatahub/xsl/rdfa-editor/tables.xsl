<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Tables as composite blocks: the table/thead/tbody/tr structure is locked,
    td/th/caption are the editable hosts (like li and figcaption). Structure
    changes go through explicit operations - the insert dialog and the
    row/column toolbar buttons (enabled while the caret is in a table) - plus
    Tab/Shift+Tab cell traversal and Enter stepping down a column, both growing
    the table by a body row at its bottom edge.

    Row/column operations address cells positionally, so they are disabled on
    tables with colspan/rowspan (pasted content): positional edits would corrupt
    a spanned grid. Such tables remain editable, draggable and annotatable.
-->

    <!-- ................................ helpers ................................ -->

    <xsl:function name="rdfae:cell-of" as="element()?">
        <xsl:param name="node"/>
        <xsl:sequence select="$node/ancestor-or-self::*[self::td or self::th][1]"/>
    </xsl:function>

    <!-- the cell the caret is in: selection first, then the last focused host -->
    <xsl:function name="rdfae:current-cell" as="element()?">
        <xsl:sequence select="(rdfae:anchor-node() ! rdfae:cell-of(.),
            ixsl:get(rdfae:editor-state(), 'activeBlock') ! rdfae:cell-of(.))[1][exists(rdfae:block-of(.))]"/>
    </xsl:function>

    <xsl:function name="rdfae:table-of" as="element()?">
        <xsl:param name="node"/>
        <xsl:sequence select="$node/ancestor-or-self::table[1]"/>
    </xsl:function>

    <!-- rows in visual order; tolerates bare table > tr (XHTML-parsed host pages) -->
    <xsl:function name="rdfae:table-rows" as="element()*">
        <xsl:param name="table" as="element()?"/>
        <xsl:sequence select="$table/(thead | tbody | tfoot)/tr | $table/tr"/>
    </xsl:function>

    <xsl:function name="rdfae:table-cells" as="element()*">
        <xsl:param name="table" as="element()?"/>
        <xsl:sequence select="rdfae:table-rows($table)/(td | th)"/>
    </xsl:function>

    <xsl:function name="rdfae:column-index" as="xs:integer">
        <xsl:param name="cell" as="element()"/>
        <xsl:sequence select="count($cell/preceding-sibling::*[self::td or self::th]) + 1"/>
    </xsl:function>

    <xsl:function name="rdfae:has-spans" as="xs:boolean">
        <xsl:param name="table" as="element()?"/>
        <xsl:sequence select="exists(rdfae:table-cells($table)[@colspan or @rowspan])"/>
    </xsl:function>

    <!-- ................................ construction ................................ -->

    <!-- a fresh editable cell with the <br> caret placeholder (dropped again by
         canonical-xhtml.xsl); returned for the caller to place -->
    <xsl:template name="rdfae:make-cell">
        <xsl:param name="name" as="xs:string"/>

        <xsl:variable name="cell" as="element()" select="rdfae:element($name)"/>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$cell"/>
        <xsl:sequence select="ixsl:call($cell, 'appendChild', [ rdfae:element('br') ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="$cell"/>
    </xsl:template>

    <xsl:template name="rdfae:make-row">
        <xsl:param name="cols" as="xs:integer"/>

        <xsl:variable name="row" as="element()" select="rdfae:element('tr')"/>
        <xsl:for-each select="1 to $cols">
            <xsl:variable name="cell" as="element()">
                <xsl:call-template name="rdfae:make-cell">
                    <xsl:with-param name="name" select="'td'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:sequence select="ixsl:call($row, 'appendChild', [ $cell ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:sequence select="$row"/>
    </xsl:template>

    <!-- a fresh all-td row next to $row, returned for caret placement; () on a
         no-op. The header row is pinned first: "before" it does nothing,
         "after" it lands at the top of the body -->
    <xsl:template name="rdfae:insert-row">
        <xsl:param name="row" as="element()"/>
        <xsl:param name="before" as="xs:boolean"/>

        <xsl:variable name="anchor" as="element()?" select="
            if ($row/parent::thead)
            then (if ($before) then () else ($row/ancestor::table[1]/tbody)[1])
            else $row"/>
        <xsl:for-each select="$anchor">
            <xsl:variable name="new" as="element()">
                <xsl:call-template name="rdfae:make-row">
                    <xsl:with-param name="cols" select="count($row/(td | th))"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:sequence select="ixsl:call(., if (self::tbody) then 'prepend'
                else if ($before) then 'before' else 'after', [ $new ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="$new"/>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ insert dialog ................................ -->

    <xsl:template name="rdfae:render-table-dialog">
        <div id="table-dialog" class="rdfa-editor-ui edit-dialog" role="dialog" aria-modal="true"
                aria-label="Insert table" style="display: none;">
            <label>Body rows</label>
            <input type="number" name="rows" value="3" min="1" max="50"/>
            <label>Columns</label>
            <input type="number" name="cols" value="3" min="1" max="20"/>
            <label class="checkbox-label"><input type="checkbox" name="header-row" checked="checked"/> Header row</label>
            <label>Caption</label>
            <input type="text" name="caption"/>
            <div class="action-buttons">
                <button type="button" class="ldhc-btn in-primary ap-solid sz-sm table-save">Insert</button>
                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm table-cancel">Cancel</button>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'insert-table')]" mode="ixsl:onclick">
        <ixsl:set-property name="insertHost"
            select="rdfae:current-host()[exists(rdfae:block-of(.))]" object="rdfae:editor-state()"/>
        <xsl:variable name="dialog" as="element()" select="id('table-dialog', ixsl:page())"/>
        <xsl:for-each select="($dialog//input[@name = 'rows'])[1], ($dialog//input[@name = 'cols'])[1]">
            <ixsl:set-property name="value" select="'3'" object="."/>
        </xsl:for-each>
        <xsl:for-each select="($dialog//input[@name = 'caption'])[1]">
            <ixsl:set-property name="value" select="''" object="."/>
        </xsl:for-each>
        <xsl:for-each select="($dialog//input[@name = 'header-row'])[1]">
            <ixsl:set-property name="checked" select="true()" object="."/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:show-at">
            <xsl:with-param name="element" select="$dialog"/>
            <xsl:with-param name="event" select="ixsl:event()"/>
        </xsl:call-template>
        <xsl:for-each select="($dialog//input[@name = 'rows'])[1]">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'table-save')]" mode="ixsl:onclick">
        <xsl:variable name="dialog" as="element()" select="ancestor::div[@id = 'table-dialog']"/>
        <xsl:variable name="rows-raw" as="xs:string" select="rdfae:input-value($dialog, 'rows')"/>
        <xsl:variable name="cols-raw" as="xs:string" select="rdfae:input-value($dialog, 'cols')"/>
        <xsl:if test="$rows-raw castable as xs:integer and $cols-raw castable as xs:integer">
            <xsl:variable name="rows" as="xs:integer" select="min((max((xs:integer($rows-raw), 1)), 50))"/>
            <xsl:variable name="cols" as="xs:integer" select="min((max((xs:integer($cols-raw), 1)), 20))"/>
            <xsl:variable name="header" as="xs:boolean" select="boolean(ixsl:get(($dialog//input[@name = 'header-row'])[1], 'checked'))"/>
            <xsl:variable name="caption-text" as="xs:string" select="rdfae:input-value($dialog, 'caption')"/>
            <xsl:call-template name="rdfae:push-undo"/>
            <xsl:variable name="table" as="element()" select="rdfae:element('table')"/>
            <xsl:if test="$caption-text ne ''">
                <xsl:variable name="caption" as="element()" select="rdfae:element('caption')"/>
                <ixsl:set-attribute name="contenteditable" select="'true'" object="$caption"/>
                <ixsl:set-property name="textContent" select="$caption-text" object="$caption"/>
                <xsl:sequence select="ixsl:call($table, 'appendChild', [ $caption ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
            <xsl:if test="$header">
                <xsl:variable name="thead" as="element()" select="rdfae:element('thead')"/>
                <xsl:variable name="tr" as="element()" select="rdfae:element('tr')"/>
                <xsl:for-each select="1 to $cols">
                    <xsl:variable name="th" as="element()">
                        <xsl:call-template name="rdfae:make-cell">
                            <xsl:with-param name="name" select="'th'"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:sequence select="ixsl:call($tr, 'appendChild', [ $th ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
                <xsl:sequence select="ixsl:call($thead, 'appendChild', [ $tr ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="ixsl:call($table, 'appendChild', [ $thead ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
            <xsl:variable name="tbody" as="element()" select="rdfae:element('tbody')"/>
            <xsl:for-each select="1 to $rows">
                <xsl:variable name="tr" as="element()">
                    <xsl:call-template name="rdfae:make-row">
                        <xsl:with-param name="cols" select="$cols"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:sequence select="ixsl:call($tbody, 'appendChild', [ $tr ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
            <xsl:sequence select="ixsl:call($table, 'appendChild', [ $tbody ])[current-date() lt xs:date('2000-01-01')]"/>
            <!-- placed per the content model relative to the host the dialog was
                 opened from: an empty list item or cell grows the table INSIDE
                 itself, a sibling where the parent admits it (chrome only when it
                 lands top-level - the helper guards it) -->
            <xsl:call-template name="rdfae:insert-block-at-caret">
                <xsl:with-param name="node" select="$table"/>
                <xsl:with-param name="host" select="ixsl:get(rdfae:editor-state(), 'insertHost')[exists(rdfae:block-of(.))]"/>
            </xsl:call-template>
            <xsl:for-each select="(rdfae:table-cells($table))[1]">
                <xsl:call-template name="rdfae:focus-caret">
                    <xsl:with-param name="node" select="."/>
                    <xsl:with-param name="offset" select="0"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
        <xsl:call-template name="rdfae:hide-dialogs"/>
    </xsl:template>

    <!-- ................................ row/column operations ................................ -->

    <xsl:template match="button[contains-token(@class, 'table-op')]" mode="ixsl:onclick">
        <xsl:variable name="op" as="xs:string" select="string(@data-op)"/>
        <xsl:for-each select="rdfae:current-cell()[not(rdfae:has-spans(rdfae:table-of(.)))]">
            <xsl:choose>
                <xsl:when test="$op = ('row-above', 'row-below')">
                    <xsl:call-template name="rdfae:op-insert-row">
                        <xsl:with-param name="cell" select="."/>
                        <xsl:with-param name="before" select="$op = 'row-above'"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$op = ('col-left', 'col-right')">
                    <xsl:call-template name="rdfae:op-insert-column">
                        <xsl:with-param name="cell" select="."/>
                        <xsl:with-param name="before" select="$op = 'col-left'"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$op = 'del-row'">
                    <xsl:call-template name="rdfae:op-delete-row">
                        <xsl:with-param name="cell" select="."/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$op = 'del-col'">
                    <xsl:call-template name="rdfae:op-delete-column">
                        <xsl:with-param name="cell" select="."/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- capture pre-insert state; push only when the insert happened (insert-row
         no-ops above the header row and after a headerless table's thead) -->
    <xsl:template name="rdfae:op-insert-row">
        <xsl:param name="cell" as="element()"/>
        <xsl:param name="before" as="xs:boolean"/>

        <xsl:variable name="i" as="xs:integer" select="rdfae:column-index($cell)"/>
        <xsl:variable name="snapshot-root" as="element()?" select="rdfae:root-of($cell)"/>
        <xsl:variable name="snapshot" as="xs:string?" select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>
        <xsl:variable name="new" as="element()?">
            <xsl:call-template name="rdfae:insert-row">
                <xsl:with-param name="row" select="$cell/parent::tr"/>
                <xsl:with-param name="before" select="$before"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="$new">
            <xsl:call-template name="rdfae:push-undo">
                <xsl:with-param name="root" select="$snapshot-root"/>
                <xsl:with-param name="snapshot" select="$snapshot"/>
            </xsl:call-template>
            <xsl:for-each select="((td | th)[$i], (td | th)[last()])[1]">
                <xsl:call-template name="rdfae:focus-caret">
                    <xsl:with-param name="node" select="."/>
                    <xsl:with-param name="offset" select="0"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="rdfae:op-insert-column">
        <xsl:param name="cell" as="element()"/>
        <xsl:param name="before" as="xs:boolean"/>

        <xsl:variable name="i" as="xs:integer" select="rdfae:column-index($cell)"/>
        <xsl:call-template name="rdfae:push-undo">
            <xsl:with-param name="host" select="$cell"/>
        </xsl:call-template>
        <xsl:for-each select="rdfae:table-rows(rdfae:table-of($cell))">
            <xsl:variable name="row" as="element()" select="."/>
            <xsl:variable name="new" as="element()">
                <xsl:call-template name="rdfae:make-cell">
                    <xsl:with-param name="name" select="if ($row/parent::thead) then 'th' else 'td'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="ref" as="element()?" select="($row/(td | th))[$i]"/>
            <xsl:choose>
                <xsl:when test="exists($ref)">
                    <xsl:sequence select="ixsl:call($ref, if ($before) then 'before' else 'after', [ $new ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:when>
                <!-- ragged (pasted) rows shorter than the caret column -->
                <xsl:otherwise>
                    <xsl:sequence select="ixsl:call($row, 'appendChild', [ $new ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:variable name="j" as="xs:integer" select="$i + (if ($before) then 0 else 1)"/>
        <xsl:for-each select="rdfae:first-host-in(($cell/parent::tr/(td | th))[$j])">
            <xsl:call-template name="rdfae:focus-caret">
                <xsl:with-param name="node" select="."/>
                <xsl:with-param name="offset" select="0"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:call-template name="rdfae:after-mutation"/>
    </xsl:template>

    <!-- the last body row stays (delete-block removes the whole table); a header
         row goes only while body rows remain to hold the caret -->
    <xsl:template name="rdfae:op-delete-row">
        <xsl:param name="cell" as="element()"/>

        <xsl:variable name="row" as="element()" select="$cell/parent::tr"/>
        <xsl:variable name="table" as="element()?" select="rdfae:table-of($cell)"/>
        <xsl:variable name="body-rows" as="element()*" select="rdfae:table-rows($table)[not(parent::thead)]"/>
        <xsl:if test="if ($row/parent::thead) then exists($body-rows) else count($body-rows) gt 1">
            <xsl:variable name="i" as="xs:integer" select="rdfae:column-index($cell)"/>
            <xsl:variable name="rows" as="element()*" select="rdfae:table-rows($table)"/>
            <xsl:variable name="target" as="element()?"
                select="(($rows[. &gt;&gt; $row])[1], ($rows[. &lt;&lt; $row])[last()])[1]"/>
            <xsl:call-template name="rdfae:push-undo">
                <xsl:with-param name="host" select="$cell"/>
            </xsl:call-template>
            <xsl:variable name="section" as="element()" select="$row/parent::*"/>
            <xsl:sequence select="ixsl:call($row, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:if test="$section[self::thead or self::tbody or self::tfoot] and empty($section/tr)">
                <xsl:sequence select="ixsl:call($section, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
            <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
            <xsl:for-each select="rdfae:first-host-in(
                    (($target/(td | th))[$i], ($target/(td | th))[last()])[1])">
                <xsl:call-template name="rdfae:focus-caret">
                    <xsl:with-param name="node" select="."/>
                    <xsl:with-param name="offset" select="0"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
    </xsl:template>

    <!-- the last column stays; victims are materialized before the first removal
         because the positional index shifts as cells go -->
    <xsl:template name="rdfae:op-delete-column">
        <xsl:param name="cell" as="element()"/>

        <xsl:variable name="row" as="element()" select="$cell/parent::tr"/>
        <xsl:if test="count($row/(td | th)) gt 1">
            <xsl:variable name="i" as="xs:integer" select="rdfae:column-index($cell)"/>
            <xsl:variable name="victims" as="element()*"
                select="rdfae:table-rows(rdfae:table-of($cell)) ! (./(td | th))[$i]"/>
            <xsl:call-template name="rdfae:push-undo">
                <xsl:with-param name="host" select="$cell"/>
            </xsl:call-template>
            <xsl:for-each select="$victims">
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
            <ixsl:set-property name="activeBlock" select="()" object="rdfae:editor-state()"/>
            <xsl:for-each select="rdfae:first-host-in(
                    (($row/(td | th))[$i], ($row/(td | th))[last()])[1])">
                <xsl:call-template name="rdfae:focus-caret">
                    <xsl:with-param name="node" select="."/>
                    <xsl:with-param name="offset" select="0"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:if>
    </xsl:template>

    <!-- ................................ cell traversal ................................ -->

    <!-- Tab walks the cells in visual order and grows the table by a body row at
         the very last cell; the caption Tabs into the first cell. Focus never
         Tabs out of the grid into the toolbar -->
    <xsl:template name="rdfae:table-tab">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="event"/>
        <xsl:param name="shift" as="xs:boolean"/>

        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="table" as="element()?" select="rdfae:table-of($host)"/>
        <xsl:variable name="cells" as="element()*" select="rdfae:table-cells($table)"/>
        <xsl:choose>
            <xsl:when test="$shift">
                <xsl:for-each select="rdfae:last-host-in(($cells[. &lt;&lt; $host])[last()])">
                    <!-- caret at the end, but before a trailing placeholder <br> -->
                    <xsl:call-template name="rdfae:focus-caret">
                        <xsl:with-param name="node" select="."/>
                        <xsl:with-param name="offset" select="count(node()) - count(node()[last()][self::br])"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="exists(($cells[. &gt;&gt; $host])[1])">
                <xsl:for-each select="rdfae:first-host-in(($cells[. &gt;&gt; $host])[1])">
                    <xsl:call-template name="rdfae:focus-caret">
                        <xsl:with-param name="node" select="."/>
                        <xsl:with-param name="offset" select="0"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- capture pre-insert state; push only when the row appeared -->
                <xsl:variable name="snapshot-root" as="element()?" select="rdfae:root-of($host)"/>
                <xsl:variable name="snapshot" as="xs:string?" select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>
                <xsl:variable name="new" as="element()?">
                    <xsl:for-each select="(rdfae:table-rows($table))[last()]">
                        <xsl:call-template name="rdfae:insert-row">
                            <xsl:with-param name="row" select="."/>
                            <xsl:with-param name="before" select="false()"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:for-each select="$new">
                    <xsl:call-template name="rdfae:push-undo">
                        <xsl:with-param name="root" select="$snapshot-root"/>
                        <xsl:with-param name="snapshot" select="$snapshot"/>
                    </xsl:call-template>
                    <xsl:for-each select="(td | th)[1]">
                        <xsl:call-template name="rdfae:focus-caret">
                            <xsl:with-param name="node" select="."/>
                            <xsl:with-param name="offset" select="0"/>
                        </xsl:call-template>
                    </xsl:for-each>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Enter steps down the column, growing the table below the last row; the
         caller (rdfae:handle-enter) has already pushed undo and cut a selection -->
    <xsl:template name="rdfae:table-enter">
        <xsl:param name="host" as="element()"/>

        <xsl:variable name="table" as="element()?" select="rdfae:table-of($host)"/>
        <xsl:variable name="row" as="element()" select="$host/parent::tr"/>
        <xsl:variable name="i" as="xs:integer" select="rdfae:column-index($host)"/>
        <xsl:variable name="next" as="element()?" select="(rdfae:table-rows($table)[. &gt;&gt; $row])[1]"/>
        <xsl:choose>
            <xsl:when test="exists($next)">
                <xsl:for-each select="rdfae:first-host-in(
                        (($next/(td | th))[$i], ($next/(td | th))[last()])[1])">
                    <xsl:call-template name="rdfae:focus-caret">
                        <xsl:with-param name="node" select="."/>
                        <xsl:with-param name="offset" select="0"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="new" as="element()?">
                    <xsl:call-template name="rdfae:insert-row">
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="before" select="false()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="(($new/(td | th))[$i], ($new/(td | th))[last()])[1]">
                    <xsl:call-template name="rdfae:focus-caret">
                        <xsl:with-param name="node" select="."/>
                        <xsl:with-param name="offset" select="0"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ................................ toolbar state ................................ -->

    <!-- riding rdfae:update-breadcrumb, the single caret-awareness choke point -->
    <xsl:template name="rdfae:sync-table-toolbar">
        <xsl:variable name="enabled" as="xs:boolean"
            select="exists(rdfae:current-cell()[not(rdfae:has-spans(rdfae:table-of(.)))])"/>
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//button[contains-token(@class, 'table-op')]">
            <ixsl:set-property name="disabled" select="not($enabled)" object="."/>
        </xsl:for-each>
        <!-- the whole cluster switches on when the caret is in a table -->
        <xsl:for-each select="id('edit-toolbar', ixsl:page())//*[contains-token(@class, 'table-ops')]">
            <ixsl:set-attribute name="class"
                select="if ($enabled) then 'tb-group table-ops active' else 'tb-group table-ops'" object="."/>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
