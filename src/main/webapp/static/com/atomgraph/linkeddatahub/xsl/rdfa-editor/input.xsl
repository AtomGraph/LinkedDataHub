<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:local="urn:rdfa-editor:functions"
xmlns:cm="urn:rdfa-editor:content-model"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Notion-style input affordances, ported from the notion-affordances branch
    (PR #10) onto the content-model era: one priority-raised ixsl:onbeforeinput
    dispatcher intercepts printable-character triggers - the / slash menu in an
    empty host and the markdown shorthands in a paragraph host - and next-matches
    to undo.xsl's typing coalescer for everything else, so plain typing still
    snapshots for undo.

    All triggers act on the HOST the caret sits in (a paragraph in a quote or
    cell, a run wrapper, a list item), never blindly on the top-level block, and
    every conversion is gated on the content model, so a shorthand that would
    produce invalid nesting stays literal text. Markdown '> ' wraps in a
    blockquote (blockquote > p - converting the p itself would be invalid).
    The slash menu is keyboard framing over the existing toolbar actions:
    convert-block, the quote toggle's wrap, the list builder and the
    figure/table dialogs.
-->

    <!-- ................................ caret-anchored popups ................................ -->

    <!-- show a popup below the caret; a collapsed caret in an empty block yields a
         degenerate (all-zero) client rect, so fall back to the host's own box -->
    <xsl:template name="local:show-at-caret">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="anchor" as="element()?" select="local:current-host()"/>
        <xsl:variable name="range" select="local:caret-range()"/>
        <xsl:variable name="caret" select="$range ! ixsl:call(., 'getBoundingClientRect', [])"/>
        <xsl:variable name="degenerate" as="xs:boolean" select="empty($caret)
            or (ixsl:get($caret, 'width') = 0 and ixsl:get($caret, 'height') = 0
                and ixsl:get($caret, 'left') = 0 and ixsl:get($caret, 'top') = 0)"/>
        <xsl:variable name="rect" select="if ($degenerate and exists($anchor))
            then ixsl:call($anchor, 'getBoundingClientRect', []) else $caret"/>
        <xsl:call-template name="local:show-at-point">
            <xsl:with-param name="element" select="$element"/>
            <xsl:with-param name="x" select="ixsl:get($rect, 'left')"/>
            <xsl:with-param name="y" select="ixsl:get($rect, 'bottom')"/>
        </xsl:call-template>
    </xsl:template>

    <!-- show a popup below an anchor element's box (no live caret needed) -->
    <xsl:template name="local:show-at-element">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="anchor" as="element()"/>
        <xsl:variable name="rect" select="ixsl:call($anchor, 'getBoundingClientRect', [])"/>
        <xsl:call-template name="local:show-at-point">
            <xsl:with-param name="element" select="$element"/>
            <xsl:with-param name="x" select="ixsl:get($rect, 'left')"/>
            <xsl:with-param name="y" select="ixsl:get($rect, 'bottom')"/>
        </xsl:call-template>
    </xsl:template>

    <!-- ................................ input triggers ................................ -->

    <!-- printable-character triggers run at higher priority than undo.xsl's
         typing-coalescing onbeforeinput rule; anything that is not a trigger
         falls through via next-match so plain typing still snapshots for undo -->
    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onbeforeinput" priority="1">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="type" as="xs:string" select="string(ixsl:get($event, 'inputType'))"/>
        <xsl:variable name="data" as="xs:string" select="string((ixsl:get($event, 'data'), '')[1])"/>
        <xsl:variable name="range" select="local:caret-range()"/>
        <xsl:variable name="kind" as="xs:string" select="if ($type = 'insertText'
                and exists(local:block-of(.)) and exists($range)
                and not(ixsl:get($event, 'isComposing')))
            then local:trigger-kind(., $data) else ''"/>
        <xsl:choose>
            <xsl:when test="$kind ne ''">
                <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:choose>
                    <xsl:when test="$kind = 'slash'">
                        <xsl:call-template name="local:open-slash">
                            <xsl:with-param name="host" select="."/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="local:apply-markdown">
                            <xsl:with-param name="host" select="."/>
                            <xsl:with-param name="kind" select="$kind"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- classify a would-be-inserted character: 'slash' (/ in an empty host), a
         markdown shorthand 'md:*' completed in a paragraph host, or '' for none.
         A shorthand whose result the content model would reject stays literal -->
    <xsl:function name="local:trigger-kind" as="xs:string">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="data" as="xs:string"/>

        <xsl:variable name="text" as="xs:string" select="local:block-text($host)"/>
        <xsl:variable name="paragraph" as="xs:boolean" select="exists($host/self::p)"/>
        <xsl:variable name="kind" as="xs:string" select="
            if ($data = '/' and $text = '') then 'slash'
            else if ($paragraph and $data = ' ' and $text = '#') then 'md:h1'
            else if ($paragraph and $data = ' ' and $text = '##') then 'md:h2'
            else if ($paragraph and $data = ' ' and $text = '###') then 'md:h3'
            else if ($paragraph and $data = ' ' and ($text = '-' or $text = '*')) then 'md:ul'
            else if ($paragraph and $data = ' ' and $text = '1.') then 'md:ol'
            else if ($paragraph and $data = ' ' and $text = '&gt;') then 'md:blockquote'
            else if ($paragraph and $data = '`' and $text = '``') then 'md:pre'
            else ''"/>
        <!-- substring-after over an empty sequence yields the zero-length STRING,
             which would send '' into the content-model gate - branch explicitly -->
        <xsl:variable name="target" as="xs:string?"
            select="if (starts-with($kind, 'md:')) then substring-after($kind, 'md:') else ()"/>
        <xsl:sequence select="if (exists($target) and not(local:parent-admits($host, $target)))
            then '' else $kind"/>
    </xsl:function>

    <!-- the region admits any block by contract; elsewhere the content model rules -->
    <xsl:function name="local:parent-admits" as="xs:boolean">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="exists($host/parent::*[contains-token(@class, 'rdfa-editor-content')])
            or cm:allows-child(local-name($host/parent::*), $name)"/>
    </xsl:function>

    <xsl:template name="local:apply-markdown">
        <xsl:param name="host" as="element()"/>
        <xsl:param name="kind" as="xs:string"/>

        <xsl:choose>
            <!-- '> ' wraps (blockquote > p; converting the p itself would be
                 invalid bare text): the wrap pushes the pre-strip state, so undo
                 restores the literal '>' -->
            <xsl:when test="$kind = 'md:blockquote'">
                <xsl:call-template name="local:wrap-in-blockquote">
                    <xsl:with-param name="block" select="$host"/>
                </xsl:call-template>
                <xsl:call-template name="local:strip-marker">
                    <xsl:with-param name="host" select="$host"/>
                </xsl:call-template>
                <xsl:call-template name="local:after-mutation"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- capture the pre-strip state; the conversion pushes it as ONE
                     undo entry (mirrors the wrap-range capture-then-push pattern) -->
                <xsl:variable name="snapshot-root" as="element()?" select="local:root-of($host)"/>
                <xsl:variable name="snapshot" as="xs:string?"
                    select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>
                <xsl:call-template name="local:strip-marker">
                    <xsl:with-param name="host" select="$host"/>
                </xsl:call-template>
                <xsl:choose>
                    <xsl:when test="$kind = ('md:ul', 'md:ol')">
                        <xsl:call-template name="local:push-undo">
                            <xsl:with-param name="root" select="$snapshot-root"/>
                            <xsl:with-param name="snapshot" select="$snapshot"/>
                        </xsl:call-template>
                        <xsl:call-template name="local:replace-with-list">
                            <xsl:with-param name="block" select="$host"/>
                            <xsl:with-param name="kind" select="substring-after($kind, 'md:')"/>
                        </xsl:call-template>
                        <xsl:call-template name="local:after-mutation"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="local:convert-block">
                            <xsl:with-param name="block" select="$host"/>
                            <xsl:with-param name="name" select="substring-after($kind, 'md:')"/>
                            <xsl:with-param name="snapshot-root" select="$snapshot-root"/>
                            <xsl:with-param name="snapshot" select="$snapshot"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- drop the typed shorthand marker, keeping chrome and the caret placeholder -->
    <xsl:template name="local:strip-marker">
        <xsl:param name="host" as="element()"/>
        <xsl:for-each select="$host/node()[not(self::*[@data-role])]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:call-template name="local:ensure-placeholder">
            <xsl:with-param name="host" select="$host"/>
        </xsl:call-template>
    </xsl:template>

    <!-- swap a block for a fresh single-item list of the given kind, caret in the
         item; a run wrapper swaps like any host (a structural gesture promotes it) -->
    <xsl:template name="local:replace-with-list">
        <xsl:param name="block" as="element()"/>
        <xsl:param name="kind" as="xs:string"/>

        <xsl:variable name="list" as="element()" select="local:element($kind)"/>
        <xsl:variable name="li" as="element()" select="local:element('li')"/>
        <ixsl:set-attribute name="contenteditable" select="'true'" object="$li"/>
        <xsl:sequence select="ixsl:call($li, 'appendChild', [ local:element('br') ])[current-date() lt xs:date('2000-01-01')],
            ixsl:call($list, 'appendChild', [ $li ])[current-date() lt xs:date('2000-01-01')],
            ixsl:call($block, 'replaceWith', [ $list ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:if test="$list/parent::*[contains-token(@class, 'rdfa-editor-content')]">
            <xsl:call-template name="local:inject-chrome">
                <xsl:with-param name="block" select="$list"/>
            </xsl:call-template>
        </xsl:if>
        <ixsl:set-property name="activeBlock" select="()" object="local:editor-state()"/>
        <xsl:call-template name="local:focus-caret">
            <xsl:with-param name="node" select="$li"/>
            <xsl:with-param name="offset" select="0"/>
        </xsl:call-template>
    </xsl:template>

    <!-- ................................ slash menu ................................ -->

    <xsl:template name="local:render-slash-menu">
        <div id="slash-menu" class="rdfa-editor-ui" role="listbox" aria-label="Insert block" style="display: none;">
            <input type="text" class="slash-filter" placeholder="Filter blocks..." aria-label="Filter blocks"/>
            <ul class="slash-items">
                <li class="slash-item" data-command="p" role="option">Paragraph</li>
                <li class="slash-item" data-command="h1" role="option">Heading 1</li>
                <li class="slash-item" data-command="h2" role="option">Heading 2</li>
                <li class="slash-item" data-command="h3" role="option">Heading 3</li>
                <li class="slash-item" data-command="blockquote" role="option">Quote</li>
                <li class="slash-item" data-command="pre" role="option">Code</li>
                <li class="slash-item" data-command="ul" role="option">Bulleted list</li>
                <li class="slash-item" data-command="ol" role="option">Numbered list</li>
                <li class="slash-item" data-command="figure" role="option">Figure&#x2026;</li>
                <li class="slash-item" data-command="table" role="option">Table&#x2026;</li>
                <!-- extension items (dispatched via local:run-extra-slash-command;
                     the generic filter/arrow/Enter machinery applies untouched) -->
                <xsl:call-template name="local:render-extra-slash-items"/>
            </ul>
        </div>
    </xsl:template>

    <!-- open with only the commands the caret context admits: conversions for
         text-block hosts (per the block-type select), Quote where the wrap is
         legal and not already inside one, lists where the model places one,
         figure/table always (they insert after the top-level block) -->
    <xsl:template name="local:open-slash">
        <xsl:param name="host" as="element()"/>

        <ixsl:set-property name="slashHost" select="$host" object="local:editor-state()"/>
        <xsl:variable name="menu" as="element()" select="id('slash-menu', ixsl:page())"/>
        <xsl:variable name="convertible" as="xs:boolean"
            select="exists($host/(self::p | self::h1 | self::h2 | self::h3 | self::pre))"/>
        <xsl:variable name="quotable" as="xs:boolean" select="cm:block(local-name($host))
            and local:parent-admits($host, 'blockquote')
            and empty($host/ancestor::blockquote[exists(local:block-of(.))])"/>
        <xsl:for-each select="$menu//input[contains-token(@class, 'slash-filter')]">
            <ixsl:set-property name="value" select="''" object="."/>
        </xsl:for-each>
        <xsl:variable name="items" as="element()*" select="$menu//li[contains-token(@class, 'slash-item')]"/>
        <xsl:for-each select="$items">
            <xsl:variable name="command" as="xs:string" select="string(@data-command)"/>
            <xsl:variable name="applies" as="xs:boolean" select="
                if ($command = ('p', 'h1', 'h2', 'h3', 'pre'))
                    then ($convertible and local:parent-admits($host, $command))
                else if ($command = 'blockquote') then $quotable
                else if ($command = ('ul', 'ol'))
                    then (exists($host/self::p) and local:parent-admits($host, $command))
                else true()"/>
            <xsl:choose>
                <xsl:when test="$applies">
                    <ixsl:remove-attribute name="data-disabled"/>
                    <ixsl:set-style name="display" select="'block'"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-attribute name="data-disabled" select="'true'"/>
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:otherwise>
            </xsl:choose>
            <ixsl:remove-attribute name="aria-selected"/>
        </xsl:for-each>
        <xsl:for-each select="($items[empty(@data-disabled)])[1]">
            <ixsl:set-attribute name="aria-selected" select="'true'"/>
        </xsl:for-each>
        <xsl:call-template name="local:show-at-caret">
            <xsl:with-param name="element" select="$menu"/>
            <xsl:with-param name="anchor" select="$host"/>
        </xsl:call-template>
        <xsl:for-each select="($menu//input[contains-token(@class, 'slash-filter')])[1]">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="local:run-slash-command">
        <xsl:param name="command" as="xs:string"/>
        <xsl:variable name="host" as="element()?"
            select="ixsl:get(local:editor-state(), 'slashHost')[exists(local:block-of(.))]"/>
        <!-- teardown first: it clears slashHost and insertHost, so the
             figure/table branches re-arm them after -->
        <xsl:call-template name="local:hide-dialogs"/>
        <xsl:for-each select="$host">
            <xsl:choose>
                <xsl:when test="$command = ('p', 'h1', 'h2', 'h3', 'pre')">
                    <xsl:for-each select="$host[self::p or self::h1 or self::h2 or self::h3
                            or self::pre][local-name() ne $command]">
                        <xsl:call-template name="local:convert-block">
                            <xsl:with-param name="block" select="."/>
                            <xsl:with-param name="name" select="$command"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$command = 'blockquote'">
                    <xsl:call-template name="local:wrap-in-blockquote">
                        <xsl:with-param name="block" select="$host"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$command = ('ul', 'ol')">
                    <xsl:call-template name="local:push-undo">
                        <xsl:with-param name="host" select="$host"/>
                    </xsl:call-template>
                    <xsl:call-template name="local:replace-with-list">
                        <xsl:with-param name="block" select="$host"/>
                        <xsl:with-param name="kind" select="$command"/>
                    </xsl:call-template>
                    <xsl:call-template name="local:after-mutation"/>
                </xsl:when>
                <xsl:when test="$command = 'figure'">
                    <ixsl:set-property name="insertHost" select="$host" object="local:editor-state()"/>
                    <xsl:variable name="dialog" as="element()" select="id('figure-dialog', ixsl:page())"/>
                    <xsl:for-each select="$dialog//input">
                        <ixsl:set-property name="value" select="''" object="."/>
                    </xsl:for-each>
                    <xsl:call-template name="local:show-at-element">
                        <xsl:with-param name="element" select="$dialog"/>
                        <xsl:with-param name="anchor" select="$host"/>
                    </xsl:call-template>
                    <xsl:for-each select="($dialog//input[@name = 'src'])[1]">
                        <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$command = 'table'">
                    <ixsl:set-property name="insertHost" select="$host" object="local:editor-state()"/>
                    <xsl:variable name="dialog" as="element()" select="id('table-dialog', ixsl:page())"/>
                    <!-- same defaults as the toolbar opener -->
                    <xsl:for-each select="($dialog//input[@name = 'rows'])[1], ($dialog//input[@name = 'cols'])[1]">
                        <ixsl:set-property name="value" select="'3'" object="."/>
                    </xsl:for-each>
                    <xsl:for-each select="($dialog//input[@name = 'caption'])[1]">
                        <ixsl:set-property name="value" select="''" object="."/>
                    </xsl:for-each>
                    <xsl:for-each select="($dialog//input[@name = 'header-row'])[1]">
                        <ixsl:set-property name="checked" select="true()" object="."/>
                    </xsl:for-each>
                    <xsl:call-template name="local:show-at-element">
                        <xsl:with-param name="element" select="$dialog"/>
                        <xsl:with-param name="anchor" select="$host"/>
                    </xsl:call-template>
                    <xsl:for-each select="($dialog//input[@name = 'rows'])[1]">
                        <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:when>
                <!-- extension commands (mirror the figure/table branches: teardown
                     already ran, the extension re-arms insertHost itself) -->
                <xsl:otherwise>
                    <xsl:call-template name="local:run-extra-slash-command">
                        <xsl:with-param name="command" select="$command"/>
                        <xsl:with-param name="host" select="$host"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="input[contains-token(@class, 'slash-filter')]" mode="ixsl:oninput">
        <xsl:variable name="q" as="xs:string" select="lower-case(normalize-space(string(ixsl:get(., 'value'))))"/>
        <xsl:variable name="items" as="element()*"
            select="id('slash-menu', ixsl:page())//li[contains-token(@class, 'slash-item')][empty(@data-disabled)]"/>
        <xsl:variable name="visible" as="element()*"
            select="$items[$q = '' or contains(lower-case(string(.)), $q)]"/>
        <xsl:for-each select="$items">
            <ixsl:set-style name="display" select="if (. intersect $visible) then 'block' else 'none'"/>
            <ixsl:remove-attribute name="aria-selected"/>
        </xsl:for-each>
        <xsl:for-each select="$visible[1]">
            <ixsl:set-attribute name="aria-selected" select="'true'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="input[contains-token(@class, 'slash-filter')]" mode="ixsl:onkeydown">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="key" as="xs:string" select="string(ixsl:get($event, 'key'))"/>
        <xsl:variable name="items" as="element()*"
            select="id('slash-menu', ixsl:page())//li[contains-token(@class, 'slash-item')]
                [empty(@data-disabled)][ixsl:get(., 'style.display') ne 'none']"/>
        <xsl:variable name="current" as="element()?" select="$items[@aria-selected = 'true'][1]"/>
        <xsl:choose>
            <xsl:when test="$key = 'Escape'">
                <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:call-template name="local:hide-dialogs"/>
            </xsl:when>
            <xsl:when test="$key = 'Enter'">
                <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:for-each select="($current, $items[1])[1]">
                    <xsl:call-template name="local:run-slash-command">
                        <xsl:with-param name="command" select="string(@data-command)"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$key = ('ArrowDown', 'ArrowUp')">
                <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:variable name="pos" as="xs:integer"
                    select="if (exists($current)) then count($items[. &lt;&lt; $current]) + 1 else 1"/>
                <xsl:variable name="next" as="xs:integer" select="if ($key = 'ArrowDown')
                    then min(($pos + 1, count($items))) else max(($pos - 1, 1))"/>
                <xsl:for-each select="$items">
                    <ixsl:remove-attribute name="aria-selected"/>
                </xsl:for-each>
                <xsl:for-each select="$items[$next]">
                    <ixsl:set-attribute name="aria-selected" select="'true'"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="li[contains-token(@class, 'slash-item')]" mode="ixsl:onclick">
        <xsl:call-template name="local:run-slash-command">
            <xsl:with-param name="command" select="string(@data-command)"/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
