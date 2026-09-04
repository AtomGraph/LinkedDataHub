<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
xmlns:rdfax="https://w3id.org/atomgraph/rdfa-editor/rdfa#"
xmlns:lint="https://w3id.org/atomgraph/rdfa-editor/lint#"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Document navigation and awareness (FontoXML-inspired): the ToC drawer (outline
    view with section drag-reorder), the breadcrumb bar (element path + RDFa subject
    in scope at the caret), lint surfacing (markers + badge; logic in lint-rdfa.xsl),
    and find & replace. All UI lives outside #content - no data-role needed; the only
    thing ever written into content is the rdfa-invalid class (canonicalization-
    stripped, extractor-invisible; @title is forbidden - it would serialize).
-->

    <xsl:template name="rdfae:init-navigate">
        <xsl:for-each select="ixsl:page()//body">
            <xsl:result-document href="?." method="ixsl:append-content">
                <aside id="toc-drawer" class="rdfa-editor-ui" role="navigation" aria-label="Table of contents" style="display: none;">
                    <button type="button" id="toc-close" class="toc-close" title="Close" aria-label="Close table of contents">&#215;</button>
                    <h2>Contents</h2>
                    <div id="toc-list"/>
                </aside>
                <aside id="inspector-drawer" class="rdfa-editor-ui" role="complementary" aria-label="Subject properties" style="display: none;">
                    <button type="button" id="inspector-close" class="inspector-close" title="Close" aria-label="Close properties">&#215;</button>
                    <h2>Properties</h2>
                    <div id="inspector-subject"/>
                    <div id="inspector-body"/>
                </aside>
                <footer id="rdfa-editor-breadcrumb" class="rdfa-editor-ui" role="navigation" aria-label="Document position">
                    <div id="rdfa-editor-breadcrumb-path"/>
                    <div id="rdfa-editor-breadcrumb-meta">
                        <span id="rdfa-editor-breadcrumb-subject"/>
                        <button type="button" id="lint-badge" class="lint-badge"
                            aria-label="RDFa validation issues" style="display: none;"/>
                    </div>
                </footer>
                <xsl:call-template name="rdfae:render-find-dialog"/>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:call-template name="rdfae:run-lint"/>
        <xsl:call-template name="rdfae:update-breadcrumb"/>
    </xsl:template>

    <!-- ................................ ToC drawer ................................ -->

    <xsl:function name="rdfae:rank" as="xs:integer">
        <xsl:param name="heading" as="element()"/>
        <xsl:sequence select="xs:integer(substring(local-name($heading), 2))"/>
    </xsl:function>

    <xsl:template name="rdfae:render-toc">
        <xsl:variable name="root" as="element()?" select="rdfae:active-root()"/>
        <xsl:variable name="headings" as="element()*" select="$root/(h1 | h2 | h3)"/>
        <!-- remembered for item click/drag resolution (roots are never replaced, only
             their children, so the reference stays valid across undo restores) -->
        <ixsl:set-property name="tocRoot" select="$root" object="rdfae:editor-state()"/>
        <xsl:for-each select="id('toc-list', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:choose>
                    <xsl:when test="exists($headings)">
                        <xsl:call-template name="rdfae:toc-level">
                            <xsl:with-param name="headings" select="$headings"/>
                            <xsl:with-param name="root" select="$root"/>
                            <xsl:with-param name="rank" select="1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <p class="helper-text">No headings yet.</p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- hierarchical outline by heading rank; handles skipped ranks naturally -->
    <xsl:template name="rdfae:toc-level">
        <xsl:param name="headings" as="element()*"/>
        <xsl:param name="root" as="element()"/>
        <xsl:param name="rank" as="xs:integer"/>

        <ul>
            <xsl:for-each-group select="$headings" group-starting-with="*[rdfae:rank(.) le $rank]">
                <li class="toc-item toc-{local-name(current-group()[1])}" draggable="true"
                    data-index="{count($root/(h1 | h2 | h3)[. &lt;&lt; current-group()[1]]) + 1}">
                    <span class="toc-label">
                        <xsl:value-of select="rdfae:block-text(current-group()[1])"/>
                    </span>
                    <xsl:if test="exists(current-group()[position() gt 1])">
                        <xsl:call-template name="rdfae:toc-level">
                            <xsl:with-param name="headings" select="current-group()[position() gt 1]"/>
                            <xsl:with-param name="root" select="$root"/>
                            <xsl:with-param name="rank" select="$rank + 1"/>
                        </xsl:call-template>
                    </xsl:if>
                </li>
            </xsl:for-each-group>
        </ul>
    </xsl:template>

    <xsl:template match="button[@id = 'toc-toggle']" mode="ixsl:onclick">
        <xsl:for-each select="id('toc-drawer', ixsl:page())">
            <xsl:choose>
                <xsl:when test="ixsl:get(., 'style.display') = 'none'">
                    <xsl:call-template name="rdfae:render-toc"/>
                    <ixsl:set-style name="display" select="'block'"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[@id = 'toc-close']" mode="ixsl:onclick">
        <xsl:for-each select="id('toc-drawer', ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ subject inspector ................................ -->

    <xsl:template match="button[@id = 'inspector-toggle']" mode="ixsl:onclick">
        <xsl:for-each select="id('inspector-drawer', ixsl:page())">
            <xsl:choose>
                <xsl:when test="ixsl:get(., 'style.display') = 'none'">
                    <ixsl:set-style name="display" select="'block'"/>
                    <xsl:call-template name="rdfae:sync-inspector"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[@id = 'inspector-close']" mode="ixsl:onclick">
        <xsl:for-each select="id('inspector-drawer', ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="span[contains-token(@class, 'toc-label')]" mode="ixsl:onclick">
        <xsl:variable name="index" as="xs:integer" select="xs:integer(../@data-index)"/>
        <xsl:for-each select="(ixsl:get(rdfae:editor-state(), 'tocRoot')/(h1 | h2 | h3))[$index]">
            <xsl:sequence select="ixsl:call(., 'scrollIntoView', [ map{ 'block': 'start' } ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:focus-caret">
    <xsl:with-param name="node" select="."/>
    <xsl:with-param name="offset" select="rdfae:chrome-count(.)"/>
</xsl:call-template>
            <xsl:call-template name="rdfae:update-breadcrumb"/>
        </xsl:for-each>
    </xsl:template>

    <!-- ................................ ToC section drag ................................ -->

    <!-- a section = the heading plus everything up to the next same-or-higher heading -->
    <xsl:function name="rdfae:section-of" as="element()+">
        <xsl:param name="heading" as="element()"/>
        <xsl:variable name="stop" as="element()?"
            select="$heading/following-sibling::*[self::h1 or self::h2 or self::h3]
                [rdfae:rank(.) le rdfae:rank($heading)][1]"/>
        <xsl:sequence select="$heading | $heading/following-sibling::*[empty($stop) or . &lt;&lt; $stop]"/>
    </xsl:function>

    <xsl:template match="li[contains-token(@class, 'toc-item')]" mode="ixsl:ondragstart">
        <xsl:variable name="transfer" select="ixsl:get(ixsl:event(), 'dataTransfer')"/>
        <xsl:variable name="index" as="xs:integer" select="xs:integer(@data-index)"/>
        <ixsl:set-property name="draggedSectionHeading"
            select="(ixsl:get(rdfae:editor-state(), 'tocRoot')/(h1 | h2 | h3))[$index]" object="rdfae:editor-state()"/>
        <ixsl:set-property name="effectAllowed" select="'move'" object="$transfer"/>
        <xsl:sequence select="ixsl:call($transfer, 'setData', [ 'application/vnd.atomgraph.rdfa-editor.section', '' ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="li[contains-token(@class, 'toc-item')]" mode="ixsl:ondragover">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="exists(ixsl:get(rdfae:editor-state(), 'draggedSectionHeading'))
                and rdfae:has-transfer-type($event, 'application/vnd.atomgraph.rdfa-editor.section')">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <ixsl:set-property name="dropEffect" select="'move'" object="ixsl:get($event, 'dataTransfer')"/>
            <xsl:call-template name="rdfae:clear-drop-marks">
            <xsl:with-param name="scope" select="id('toc-list', ixsl:page())//li"/>
        </xsl:call-template>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add',
                [ if (rdfae:drop-before($event, .)) then 'drop-before' else 'drop-after' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="li[contains-token(@class, 'toc-item')]" mode="ixsl:ondrop">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="item" as="element()" select="."/>
        <xsl:variable name="source" select="ixsl:get(rdfae:editor-state(), 'draggedSectionHeading')"/>
        <xsl:variable name="before" as="xs:boolean" select="rdfae:drop-before($event, $item)"/>
        <xsl:call-template name="rdfae:clear-drop-marks">
            <xsl:with-param name="scope" select="id('toc-list', ixsl:page())//li"/>
        </xsl:call-template>
        <xsl:if test="exists($source) and rdfae:has-transfer-type($event, 'application/vnd.atomgraph.rdfa-editor.section')">
            <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <!-- bare-variable positional predicate: SaxonJS evaluates computed numeric
                 predicates as booleans in this context -->
            <xsl:variable name="index" as="xs:integer" select="xs:integer($item/@data-index)"/>
            <xsl:variable name="target" as="element()?"
                select="(ixsl:get(rdfae:editor-state(), 'tocRoot')/(h1 | h2 | h3))[$index]"/>
            <!-- no-op: dropping onto itself or into its own section (incl. subsections) -->
            <xsl:if test="exists($target) and not($target is $source)
                    and empty($target intersect rdfae:section-of($source))">
                <xsl:call-template name="rdfae:push-undo"/>
                <xsl:variable name="section" as="element()+" select="rdfae:section-of($source)"/>
                <xsl:choose>
                    <xsl:when test="$before">
                        <xsl:for-each select="$section">
                            <xsl:sequence select="ixsl:call($target, 'before', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:iterate select="$section">
                            <xsl:param name="anchor" as="element()" select="rdfae:section-of($target)[last()]"/>
                            <xsl:sequence select="ixsl:call($anchor, 'after', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:next-iteration>
                                <xsl:with-param name="anchor" select="."/>
                            </xsl:next-iteration>
                        </xsl:iterate>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- after-mutation re-renders the (open) ToC -->
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="li[contains-token(@class, 'toc-item')]" mode="ixsl:ondragend">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'dragging' ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:clear-drop-marks">
            <xsl:with-param name="scope" select="id('toc-list', ixsl:page())//li"/>
        </xsl:call-template>
        <ixsl:set-property name="draggedSectionHeading" select="()" object="rdfae:editor-state()"/>
    </xsl:template>

    <!-- ................................ breadcrumb ................................ -->

    <xsl:function name="rdfae:compact-term" as="xs:string">
        <xsl:param name="term" as="xs:string"/>
        <xsl:sequence select="if (matches($term, '^[a-zA-Z][a-zA-Z0-9+.-]*:'))
            then rdfax:prefixed-name(rdfax:split-uri($term), $rdfax:default-prefixes)
            else $term"/>
    </xsl:function>

    <xsl:function name="rdfae:crumb-label" as="xs:string">
        <xsl:param name="element" as="element()"/>
        <xsl:choose>
            <xsl:when test="contains-token($element/@class, 'rdfa-editor-content')">content</xsl:when>
            <xsl:otherwise>
                <xsl:variable name="term" as="xs:string?"
                    select="($element/@property, $element/@typeof)[1] ! tokenize(.)[1]"/>
                <xsl:sequence select="local-name($element) || ($term ! ('[' || rdfae:compact-term(.) || ']'), '')[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="rdfae:update-breadcrumb">
        <xsl:variable name="node" select="(rdfae:anchor-node(),
            ixsl:get(rdfae:editor-state(), 'activeBlock'))[1]"/>
        <xsl:variable name="leaf" as="element()?" select="$node/ancestor-or-self::*[1]"/>
        <xsl:choose>
            <xsl:when test="exists($leaf) and exists(rdfae:block-of($leaf))">
                <ixsl:set-property name="breadcrumbLeaf" select="$leaf" object="rdfae:editor-state()"/>
                <xsl:variable name="ancestors" as="element()*"
                    select="$leaf/ancestor-or-self::* intersect rdfae:root-of($leaf)/descendant-or-self::*"/>
                <xsl:for-each select="id('rdfa-editor-breadcrumb-path', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:for-each select="$ancestors">
                            <xsl:if test="position() gt 1">
                                <span class="crumb-sep">&#x203A;</span>
                            </xsl:if>
                            <span class="crumb" data-index="{position()}">
                                <xsl:value-of select="rdfae:crumb-label(.)"/>
                            </span>
                        </xsl:for-each>
                    </xsl:result-document>
                </xsl:for-each>
                <xsl:for-each select="id('rdfa-editor-breadcrumb-subject', ixsl:page())">
                    <ixsl:set-property name="textContent"
                        select="rdfax:in-scope-subject($leaf, rdfae:document-uri())" object="."/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-property name="breadcrumbLeaf" select="()" object="rdfae:editor-state()"/>
                <xsl:for-each select="id('rdfa-editor-breadcrumb-path', ixsl:page())">
                    <ixsl:set-property name="textContent" select="''" object="."/>
                </xsl:for-each>
                <xsl:for-each select="id('rdfa-editor-breadcrumb-subject', ixsl:page())">
                    <ixsl:set-property name="textContent" select="rdfae:document-uri()" object="."/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="rdfae:sync-table-toolbar"/>
        <xsl:call-template name="rdfae:sync-format-toolbar"/>
        <xsl:call-template name="rdfae:sync-inspector"/>
    </xsl:template>

    <!-- the property sheet for the subject in scope at the caret. Read-only: it
         re-presents the extractor's own output (grouped per subject) so its verdicts
         can never drift from "Extract RDF"/lint. Only does work while the drawer is
         open; rides rdfae:update-breadcrumb, so it tracks the caret and refreshes
         after every mutation (annotate/undo route through rdfae:after-mutation). -->
    <xsl:template name="rdfae:sync-inspector">
        <xsl:for-each select="id('inspector-drawer', ixsl:page())[ixsl:get(., 'style.display') ne 'none']">
            <xsl:variable name="base" as="xs:string" select="rdfae:document-uri()"/>
            <xsl:variable name="leaf" select="ixsl:get(rdfae:editor-state(), 'breadcrumbLeaf')"/>
            <xsl:variable name="subject" as="xs:string"
                select="((if (exists($leaf)) then rdfax:in-scope-subject($leaf, $base) else ())[. ne ''], $base)[1]"/>
            <xsl:variable name="rdf" as="element(rdf:RDF)">
                <xsl:call-template name="rdfax:extract-rdfa">
                    <xsl:with-param name="doc" select="ixsl:page()"/>
                    <xsl:with-param name="base" select="$base"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="desc" as="element(rdf:Description)?" select="
                rdfae:group-triples($rdf)/rdf:Description[
                    (@rdf:about = $subject)
                    or (starts-with($subject, '_:') and @rdf:nodeID = substring-after($subject, '_:'))
                ]"/>

            <xsl:for-each select="id('inspector-subject', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <span class="inspector-subject-iri">
                        <xsl:value-of select="rdfae:short-iri($subject, $base)"/>
                    </span>
                    <xsl:for-each select="$desc/rdf:type/@rdf:resource">
                        <span class="inspector-type">
                            <xsl:value-of select="rdfae:compact-term(.)"/>
                        </span>
                    </xsl:for-each>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:for-each select="id('inspector-body', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:variable name="props" as="element()*" select="$desc/*[not(self::rdf:type)]"/>
                    <xsl:choose>
                        <xsl:when test="exists($props)">
                            <xsl:for-each select="$props">
                                <div class="inspector-row">
                                    <span class="inspector-pred">
                                        <xsl:value-of select="rdfae:compact-term(namespace-uri() || local-name())"/>
                                    </span>
                                    <span class="inspector-obj">
                                        <xsl:choose>
                                            <xsl:when test="@rdf:resource">
                                                <span class="inspector-obj-iri">
                                                    <xsl:value-of select="rdfae:short-iri(@rdf:resource, $base)"/>
                                                </span>
                                            </xsl:when>
                                            <xsl:when test="@rdf:nodeID">
                                                <span class="inspector-obj-iri">_:<xsl:value-of select="@rdf:nodeID"/></span>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <span class="inspector-obj-lit"><xsl:value-of select="."/></span>
                                                <xsl:if test="@rdf:datatype">
                                                    <span class="inspector-obj-dt"><xsl:value-of select="rdfae:compact-term(@rdf:datatype)"/></span>
                                                </xsl:if>
                                                <xsl:if test="@xml:lang">
                                                    <span class="inspector-obj-lang">@<xsl:value-of select="@xml:lang"/></span>
                                                </xsl:if>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </span>
                                </div>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <p class="helper-text">No properties on this subject.</p>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- readable object/subject: the document itself, a same-document fragment, or a CURIE -->
    <xsl:function name="rdfae:short-iri" as="xs:string">
        <xsl:param name="iri" as="xs:string"/>
        <xsl:param name="base" as="xs:string"/>
        <xsl:sequence select="
            if ($iri eq $base) then 'this document'
            else if (starts-with($iri, '_:')) then $iri
            else if (starts-with($iri, $base)) then substring-after($iri, $base)
            else rdfae:compact-term($iri)"/>
    </xsl:function>

    <xsl:template match="span[contains-token(@class, 'crumb')]" mode="ixsl:onmousedown">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="span[contains-token(@class, 'crumb')]" mode="ixsl:onclick">
        <xsl:variable name="index" as="xs:integer" select="xs:integer(@data-index)"/>
        <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'breadcrumbLeaf')[exists(rdfae:block-of(.))]">
            <xsl:variable name="target" as="element()?"
                select="(ancestor-or-self::* intersect rdfae:root-of(.)/descendant-or-self::*)[$index]"/>
            <xsl:for-each select="$target">
                <xsl:sequence select="ixsl:call(rdfae:selection(),
                    'selectAllChildren', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:call-template name="rdfae:update-breadcrumb"/>
    </xsl:template>

    <!-- caret movement awareness: keyup and mouseup on hosts (no document-level
         selectionchange - unproven in SaxonJS); focusin is handled in edit.xsl -->
    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onkeyup">
        <xsl:if test="exists(rdfae:block-of(.))">
            <xsl:call-template name="rdfae:update-breadcrumb"/>
            <xsl:if test="(self::h1 or self::h2 or self::h3)
                    and id('toc-drawer', ixsl:page()) ! (ixsl:get(., 'style.display') ne 'none')">
                <xsl:call-template name="rdfae:render-toc"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:onmouseup">
        <!-- innermost-match dispatch: a sweep ending over a host lands here, not
             on the body/html disarm template (select.xsl) -->
        <xsl:call-template name="rdfae:disarm-sweep"/>
        <xsl:if test="exists(rdfae:block-of(.))">
            <xsl:call-template name="rdfae:update-breadcrumb"/>
        </xsl:if>
    </xsl:template>

    <!-- ................................ lint surfacing ................................ -->

    <xsl:template name="rdfae:run-lint">
        <xsl:for-each select="rdfae:roots()//*[contains-token(@class, 'rdfa-invalid')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'rdfa-invalid' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- the issue functions run once per element: markers and the badge count
             both derive from the same evaluation (this fires on every mutation) -->
        <xsl:variable name="linted" as="map(*)*" select="rdfae:roots() ! lint:lintable(.) ! map{
            'element': .,
            'issues': count((lint:element-issues(.), lint:nesting-issues(.))) }"/>
        <xsl:for-each select="$linted[?issues gt 0]?element">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'rdfa-invalid' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:variable name="count" as="xs:integer" select="sum($linted?issues)"/>
        <xsl:for-each select="id('lint-badge', ixsl:page())">
            <xsl:choose>
                <xsl:when test="$count gt 0">
                    <ixsl:set-property name="textContent"
                        select="$count || ' issue' || (if ($count gt 1) then 's' else '')" object="."/>
                    <ixsl:set-style name="display" select="'inline-block'"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[@id = 'lint-badge']" mode="ixsl:onclick">
        <xsl:variable name="lines" as="xs:string*"
            select="rdfae:roots() ! lint:lintable(.) ! (lint:element-issues(.), lint:nesting-issues(.))
                ! (string(@code) || ' &#x2014; ' || normalize-space(string(.)))"/>
        <xsl:call-template name="rdfae:show-output">
            <xsl:with-param name="title" select="'Validation issues'"/>
            <xsl:with-param name="text" select="string-join($lines, '&#10;')"/>
        </xsl:call-template>
    </xsl:template>

    <!-- ................................ find &amp; replace ................................ -->

    <xsl:function name="rdfae:norm" as="xs:string">
        <xsl:param name="s" as="xs:string"/>
        <xsl:param name="ci" as="xs:boolean"/>
        <xsl:sequence select="if ($ci) then lower-case($s) else $s"/>
    </xsl:function>

    <!-- 1-based position of the next occurrence at or after $from, or empty -->
    <xsl:function name="rdfae:find-in" as="xs:integer?">
        <xsl:param name="hay" as="xs:string"/>
        <xsl:param name="from" as="xs:integer"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:param name="ci" as="xs:boolean"/>
        <xsl:variable name="tail" as="xs:string" select="rdfae:norm(substring($hay, $from), $ci)"/>
        <xsl:variable name="q" as="xs:string" select="rdfae:norm($query, $ci)"/>
        <xsl:sequence select="if (contains($tail, $q))
            then $from + string-length(substring-before($tail, $q)) else ()"/>
    </xsl:function>

    <!-- all occurrences replaced within one string; returns map{'value','count'} -->
    <xsl:function name="rdfae:replace-in-string" as="map(*)">
        <xsl:param name="hay" as="xs:string"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:param name="replacement" as="xs:string"/>
        <xsl:param name="ci" as="xs:boolean"/>
        <xsl:variable name="p" as="xs:integer?" select="rdfae:find-in($hay, 1, $query, $ci)"/>
        <xsl:choose>
            <xsl:when test="empty($p)">
                <xsl:sequence select="map{ 'value': $hay, 'count': 0 }"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="rest" as="map(*)" select="rdfae:replace-in-string(
                    substring($hay, $p + string-length($query)), $query, $replacement, $ci)"/>
                <xsl:sequence select="map{
                    'value': substring($hay, 1, $p - 1) || $replacement || $rest?value,
                    'count': 1 + xs:integer($rest?count) }"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="rdfae:render-find-dialog">
        <div id="find-dialog" class="rdfa-editor-ui edit-dialog" role="dialog" aria-modal="true"
                aria-label="Find and replace" style="display: none;">
            <label>Find</label>
            <input type="text" name="find"/>
            <label>Replace with</label>
            <input type="text" name="replace"/>
            <label class="checkbox-label">
                <input type="checkbox" name="match-case"/> Match case
            </label>
            <div class="action-buttons">
                <button type="button" class="ldhc-btn in-primary ap-solid sz-sm find-next">Find next</button>
                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm replace-current">Replace</button>
                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm replace-all">Replace all</button>
                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm find-close">Close</button>
            </div>
            <span id="find-status" class="helper-text"/>
        </div>
    </xsl:template>

    <xsl:template match="button[@id = 'find-open']" mode="ixsl:onclick">
        <xsl:variable name="dialog" as="element()" select="id('find-dialog', ixsl:page())"/>
        <xsl:call-template name="rdfae:show-at">
            <xsl:with-param name="element" select="$dialog"/>
            <xsl:with-param name="event" select="ixsl:event()"/>
        </xsl:call-template>
        <xsl:for-each select="($dialog//input[@name = 'find'])[1]">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- keep the content selection (the match highlight) alive across button clicks -->
    <xsl:template match="div[@id = 'find-dialog']//button" mode="ixsl:onmousedown">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'find-close')]" mode="ixsl:onclick">
        <xsl:call-template name="rdfae:hide-dialogs"/>
    </xsl:template>

    <xsl:template name="rdfae:find-status">
        <xsl:param name="message" as="xs:string"/>
        <xsl:for-each select="id('find-status', ixsl:page())">
            <ixsl:set-property name="textContent" select="$message" object="."/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'find-next')]" mode="ixsl:onclick">
        <xsl:call-template name="rdfae:find-next"/>
    </xsl:template>

    <xsl:template name="rdfae:find-next">
        <xsl:variable name="dialog" as="element()" select="id('find-dialog', ixsl:page())"/>
        <xsl:variable name="query" as="xs:string"
            select="string(ixsl:get(($dialog//input[@name = 'find'])[1], 'value'))"/>
        <xsl:variable name="ci" as="xs:boolean"
            select="not(ixsl:get(($dialog//input[@name = 'match-case'])[1], 'checked'))"/>
        <xsl:choose>
            <xsl:when test="$query = ''">
                <xsl:call-template name="rdfae:find-status">
                    <xsl:with-param name="message" select="'Enter a search term.'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="texts" select="rdfae:roots()//text()[not(ancestor::*[@data-role])]"/>
                <xsl:variable name="current" select="ixsl:get(rdfae:editor-state(), 'findNode')[exists(rdfae:block-of(.))]"/>
                <xsl:variable name="offset" as="xs:integer"
                    select="(ixsl:get(rdfae:editor-state(), 'findOffset') ! xs:integer(.), 1)[1]"/>
                <!-- wrap-around scan plan: current node from the last match onward,
                     following nodes, preceding nodes, current node from the top -->
                <xsl:variable name="plan" as="map(*)*" select="
                    if (exists($current)) then (
                        map{ 'n': $current, 'from': $offset },
                        for $t in $texts[. &gt;&gt; $current] return map{ 'n': $t, 'from': 1 },
                        for $t in $texts[. &lt;&lt; $current] return map{ 'n': $t, 'from': 1 },
                        map{ 'n': $current, 'from': 1 })
                    else for $t in $texts return map{ 'n': $t, 'from': 1 }"/>
                <xsl:iterate select="$plan">
                    <xsl:on-completion>
                        <xsl:call-template name="rdfae:find-status">
                            <xsl:with-param name="message" select="'No matches.'"/>
                        </xsl:call-template>
                        <ixsl:set-property name="findNode" select="()" object="rdfae:editor-state()"/>
                        <ixsl:set-property name="findOffset" select="1" object="rdfae:editor-state()"/>
                    </xsl:on-completion>
                    <xsl:variable name="node" select="?n"/>
                    <xsl:variable name="position" as="xs:integer?"
                        select="rdfae:find-in(string($node), ?from, $query, $ci)"/>
                    <xsl:choose>
                        <xsl:when test="exists($position)">
                            <xsl:for-each select="rdfae:host-of($node)">
                                <xsl:call-template name="rdfae:focus">
                                    <xsl:with-param name="element" select="."/>
                                </xsl:call-template>
                            </xsl:for-each>
                            <xsl:sequence select="ixsl:call(rdfae:selection(),
                                'setBaseAndExtent', [ $node, $position - 1, $node,
                                    $position - 1 + string-length($query) ])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:sequence select="ixsl:call(ixsl:get($node, 'parentElement'), 'scrollIntoView',
                                [ map{ 'block': 'center' } ])[current-date() lt xs:date('2000-01-01')]"/>
                            <ixsl:set-property name="findNode" select="$node" object="rdfae:editor-state()"/>
                            <ixsl:set-property name="findOffset"
                                select="$position + string-length($query)" object="rdfae:editor-state()"/>
                            <xsl:call-template name="rdfae:find-status">
                                <xsl:with-param name="message" select="''"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:update-breadcrumb"/>
                            <xsl:break/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:next-iteration/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:iterate>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'replace-current')]" mode="ixsl:onclick">
        <xsl:variable name="dialog" as="element()" select="id('find-dialog', ixsl:page())"/>
        <xsl:variable name="query" as="xs:string"
            select="string(ixsl:get(($dialog//input[@name = 'find'])[1], 'value'))"/>
        <xsl:variable name="replacement" as="xs:string"
            select="string(ixsl:get(($dialog//input[@name = 'replace'])[1], 'value'))"/>
        <xsl:variable name="ci" as="xs:boolean"
            select="not(ixsl:get(($dialog//input[@name = 'match-case'])[1], 'checked'))"/>
        <xsl:variable name="selection" select="rdfae:selection()"/>
        <xsl:choose>
            <!-- the current selection is the match found by find-next -->
            <xsl:when test="$query ne '' and ixsl:get($selection, 'rangeCount') ge 1
                    and not(ixsl:get($selection, 'isCollapsed'))
                    and (ixsl:get($selection, 'anchorNode') ! exists(rdfae:block-of(.)))
                    and rdfae:norm(string(ixsl:call($selection, 'toString', [])), $ci) eq rdfae:norm($query, $ci)">
                <xsl:variable name="range" select="rdfae:caret-range()"/>
                <xsl:call-template name="rdfae:push-undo"/>
                <xsl:sequence select="ixsl:call($range, 'deleteContents', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:if test="$replacement ne ''">
                    <xsl:variable name="node" select="ixsl:call(ixsl:page(), 'createTextNode', [ $replacement ])"/>
                    <xsl:sequence select="ixsl:call($range, 'insertNode', [ $node ])[current-date() lt xs:date('2000-01-01')]"/>
                    <ixsl:set-property name="findNode" select="$node" object="rdfae:editor-state()"/>
                    <ixsl:set-property name="findOffset" select="string-length($replacement) + 1" object="rdfae:editor-state()"/>
                </xsl:if>
                <xsl:call-template name="rdfae:after-mutation"/>
                <xsl:call-template name="rdfae:find-next"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:find-next"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- pure nodeValue rewrites: no structural change, annotation-safe by construction -->
    <xsl:template match="button[contains-token(@class, 'replace-all')]" mode="ixsl:onclick">
        <xsl:variable name="dialog" as="element()" select="id('find-dialog', ixsl:page())"/>
        <xsl:variable name="query" as="xs:string"
            select="string(ixsl:get(($dialog//input[@name = 'find'])[1], 'value'))"/>
        <xsl:variable name="replacement" as="xs:string"
            select="string(ixsl:get(($dialog//input[@name = 'replace'])[1], 'value'))"/>
        <xsl:variable name="ci" as="xs:boolean"
            select="not(ixsl:get(($dialog//input[@name = 'match-case'])[1], 'checked'))"/>
        <xsl:variable name="matched" select="rdfae:roots()//text()[not(ancestor::*[@data-role])]
            [$query ne ''][contains(rdfae:norm(string(.), $ci), rdfae:norm($query, $ci))]"/>
        <xsl:choose>
            <xsl:when test="empty($matched)">
                <xsl:call-template name="rdfae:find-status">
                    <xsl:with-param name="message"
                        select="if ($query = '') then 'Enter a search term.' else 'No matches.'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="rdfae:push-undo"/>
                <xsl:iterate select="$matched">
                    <xsl:param name="total" as="xs:integer" select="0"/>
                    <xsl:on-completion>
                        <xsl:call-template name="rdfae:find-status">
                            <xsl:with-param name="message" select="$total || ' occurrence'
                                || (if ($total ne 1) then 's' else '') || ' replaced.'"/>
                        </xsl:call-template>
                    </xsl:on-completion>
                    <xsl:variable name="result" as="map(*)"
                        select="rdfae:replace-in-string(string(.), $query, $replacement, $ci)"/>
                    <ixsl:set-property name="nodeValue" select="$result?value" object="."/>
                    <xsl:next-iteration>
                        <xsl:with-param name="total" select="$total + xs:integer($result?count)"/>
                    </xsl:next-iteration>
                </xsl:iterate>
                <ixsl:set-property name="findNode" select="()" object="rdfae:editor-state()"/>
                <ixsl:set-property name="findOffset" select="1" object="rdfae:editor-state()"/>
                <xsl:call-template name="rdfae:after-mutation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
