<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:cm="https://w3id.org/atomgraph/rdfa-editor/content-model#"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
exclude-result-prefixes="#all"
version="3.0">

<!--
    Canonical XHTML+RDFa serialization form. Pure XSLT 3.0 - no ixsl: dependencies,
    so it runs headless for testing (see tests/run-tests.sh), but NOT standalone-
    compilable: it consults content-model.xsl (cm:*) - include/import both together
    (index.xsl does; the test driver is tests/canonical-driver.xsl).

    Two passes in a fixed order:
    1. mode="cm:canonical"     strips editing ephemera per the LDH v6 convention
                            (everything carrying @data-role is removable by
                            construction), sanitizes, and normalizes browser mess.
                            Nesting analysis must never see chrome, so this runs first.
    2. mode="cm:normalize"  coerces the result to the XHTML Strict content model
                            (blockquote is block-only, p is inline-only, ul holds
                            only li, ...), always RDFa-preserving. The load-init
                            path (edit.xsl) runs this pass ALONE on host content.

    The entry template finally applies the editor contract - region children are
    blocks - which is deliberately not part of the DTD transcription.
    RDFa attributes and pre whitespace are never touched; text is never reflowed.
-->

    <!-- serialization is the caller's job (view-source runs exclusive XML c14n via
         rdfae:canonicalize-xml in edit.xsl, tests use -o output); no xsl:output
         here - it would conflict with the including stylesheet's -->
    <xsl:mode name="cm:canonical" on-no-match="shallow-copy"/>
    <xsl:mode name="cm:normalize" on-no-match="shallow-copy"/>

    <xsl:template name="cm:canonical-xhtml">
        <xsl:param name="content" as="element()" select="/*"/>
        <xsl:variable name="pass1" as="node()*">
            <xsl:apply-templates select="$content" mode="cm:canonical"/>
        </xsl:variable>
        <xsl:for-each select="$pass1/self::*">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <!-- editor contract (not the DTD's rule): region children are blocks -->
                <xsl:sequence select="cm:wrap-inline-runs(cm:normalize(node()), 'p')"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>

    <!-- -im:canonical entry for CLI fallback -->
    <xsl:template match="/" mode="cm:canonical">
        <xsl:call-template name="cm:canonical-xhtml"/>
    </xsl:template>

    <!-- ................ shared coercion primitives ................ -->

    <xsl:function name="cm:normalize" as="node()*">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:apply-templates select="$nodes" mode="cm:normalize"/>
    </xsl:function>

    <!-- the wrapper is inline-only, so only text and KNOWN-INLINE elements may be
         pulled into it; everything else passes through bare - blocks and ephemera
         by design, and both unknown elements (an RDFa-bearing article) and known
         non-inline strays (an li outside any list) stay put for lint to report
         rather than being wrapped into fresh invalid nesting. Adjacent runs with
         substance (an element or non-whitespace text) get wrapped; whitespace-only
         runs between blocks stay bare. The one grouping axis shared by the entry
         coercion, N2 and the paste handler (edit.xsl) -->
    <xsl:function name="cm:wrap-inline-runs" as="node()*">
        <xsl:param name="kids" as="node()*"/>
        <xsl:param name="wrapper" as="xs:string"/>
        <xsl:for-each-group select="$kids"
                group-adjacent="boolean(self::*[not(cm:inline(local-name(.))) or @data-role])">
            <xsl:choose>
                <xsl:when test="current-grouping-key()">
                    <xsl:sequence select="current-group()"/>
                </xsl:when>
                <xsl:when test="exists(current-group()[self::* or self::text()[normalize-space()]])">
                    <xsl:element name="{$wrapper}">
                        <xsl:sequence select="current-group()"/>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="current-group()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:function>

    <!-- element-only containers (ul, dl, tr): allowed/@data-role children pass,
         adjacent runs of anything else get wrapped in the container's item kind -->
    <xsl:function name="cm:coerce-children" as="node()*">
        <xsl:param name="kids" as="node()*"/>
        <xsl:param name="allowed" as="xs:string*"/>
        <xsl:param name="wrapper" as="xs:string"/>
        <xsl:for-each-group select="$kids"
                group-adjacent="boolean(self::*[local-name() = $allowed or @data-role])">
            <xsl:choose>
                <xsl:when test="current-grouping-key()">
                    <xsl:sequence select="current-group()"/>
                </xsl:when>
                <xsl:when test="exists(current-group()[self::* or self::text()[normalize-space()]])">
                    <xsl:element name="{$wrapper}">
                        <xsl:sequence select="current-group()"/>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="current-group()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:function>

    <!-- ................ pass 1: mode="cm:canonical" ................ -->

    <!-- C1: everything carrying @data-role is ephemeral (chrome, rendering) -->
    <xsl:template match="*[@data-role]" mode="cm:canonical" priority="2"/>

    <!-- S1: active/embedding elements never survive into stored content (the
         canonical form is the sanitization boundary for multi-user content).
         button is exempt: inert markup once S2 strips its handlers, and content
         components (e.g. tab strips) legitimately store it -->
    <xsl:template match="script | style | iframe | object | embed | applet
        | form | input | select | textarea | link | meta | base" mode="cm:canonical" priority="3"/>

    <!-- S1b: comments and processing instructions are noise (Word/HTML paste junk) -->
    <xsl:template match="comment() | processing-instruction()" mode="cm:canonical"/>

    <!-- S2: event-handler attributes are always stripped -->
    <xsl:template match="@*[matches(local-name(), '^on', 'i')]" mode="cm:canonical"/>

    <!-- S3: scripting/data URL schemes are dropped from link and media targets
         (the attribute, not the element); data:image/* remains valid in @src -->
    <xsl:template match="@href[matches(normalize-space(.), '^(javascript|vbscript|data):', 'i')]
        | @src[matches(normalize-space(.), '^(javascript|vbscript):', 'i')]
        | @src[matches(normalize-space(.), '^data:', 'i')][not(matches(normalize-space(.), '^data:image/', 'i'))]"
        mode="cm:canonical"/>

    <!-- the class tokens the editor itself puts on content elements: the region and
         run/island markers plus transient gesture and lint state. Everything else in
         @class is authored content -->
    <xsl:function name="cm:authored-class-tokens" as="xs:string*">
        <xsl:param name="class" as="xs:string?"/>
        <xsl:sequence select="tokenize($class, '\s+')[.][not(starts-with(., 'rdfa-editor-') or . = ('dragging', 'drop-before', 'drop-after', 'drop-into', 'rdfa-invalid'))]"/>
    </xsl:function>

    <!-- attributes that survive canonicalization and so count as authored meaning:
         everything except the editor's own injections (C2) and stripped handlers (S2).
         C6/C7's meaninglessness tests consult this, so an element keeping an authored
         class, id, aria-* etc. is never unwrapped as browser junk -->
    <xsl:function name="cm:authored-attributes" as="attribute()*">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="$element/@*[not(name() = ('contenteditable', 'draggable', 'style') or (name() = 'tabindex' and . = '-1') or matches(local-name(), '^on', 'i') or (name() = 'class' and empty(cm:authored-class-tokens(.))))]"/>
    </xsl:function>

    <!-- C2: only the editing-state attributes the editor itself injects are stripped
         (tabindex="-1" makes block images/islands focusable navigation islands), plus
         @style, which no editing gesture can author - browsers mint styled spans during
         editing and paste, so inline style is browser mess like font/u, not content.
         Authored attributes - class, id, aria-*, data-*, role, hidden - are content
         and round-trip untouched: the canonical form owes the author fidelity. A host
         with a stricter storage policy layers its own stripping by overriding these
         templates at higher import precedence -->
    <xsl:template match="@contenteditable | @draggable | @style | @tabindex[. = '-1']" mode="cm:canonical"/>

    <!-- C2b: the editor's own class tokens are subtracted from @class; authored tokens
         survive, and an attribute left empty drops -->
    <xsl:template match="@class" mode="cm:canonical">
        <xsl:variable name="tokens" select="cm:authored-class-tokens(.)" as="xs:string*"/>
        <xsl:if test="exists($tokens)">
            <xsl:attribute name="class" select="string-join($tokens, ' ')"/>
        </xsl:if>
    </xsl:template>

    <!-- C3/C4: presentational aliases to their semantic elements -->
    <xsl:template match="b" mode="cm:canonical">
        <strong>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </strong>
    </xsl:template>

    <xsl:template match="i" mode="cm:canonical">
        <em>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </em>
    </xsl:template>

    <!-- C5: legacy presentational wrappers are dropped, content kept -->
    <xsl:template match="font | u" mode="cm:canonical">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

    <!-- C6: a span left without any authored attribute carries no meaning; RDFa,
         language, class, id etc. all count as meaning -->
    <xsl:template match="span[empty(cm:authored-attributes(.))]" mode="cm:canonical">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

    <!-- C7a: browser-generated attributeless div with inline content becomes a
         paragraph; divs bearing any authored attribute pass -->
    <xsl:template match="div[empty(cm:authored-attributes(.))]
            [empty(*[cm:block(local-name(.))])]" mode="cm:canonical">
        <p>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </p>
    </xsl:template>

    <!-- C7b: an attributeless div holding blocks is a semantics-free grouping
         wrapper (p may not contain blocks) - unwrap to its children; stray inline
         residue is re-coerced by pass 2 in the parent's context -->
    <xsl:template match="div[empty(cm:authored-attributes(.))]
            [exists(*[cm:block(local-name(.))])]" mode="cm:canonical">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

    <!-- C11: the editing-DOM run wrapper (edit.xsl wraps stray inline runs of mixed
         flow containers in p.rdfa-editor-run so they stay editable) unwraps, so
         <li>text<ul>...</ul></li> round-trips byte-identical. An annotated wrapper
         has become real content and stays a p -->
    <xsl:template match="p[contains-token(@class, 'rdfa-editor-run')]
            [not(@property or @about or @typeof or @resource or @content or @datatype)]"
        mode="cm:canonical" priority="1">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

    <!-- C12: HTML5 sectioning wrappers have no XHTML Strict equivalent - unwrap
         clipboard/host wrappers, keep RDFa-bearing ones (dropping them would lose
         triples; lint reports them as unknown-element) -->
    <xsl:template match="(section | article | main | aside | header | footer | nav | hgroup)
            [not(@property or @about or @typeof or @resource)]" mode="cm:canonical">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

    <!-- C8: empty non-RDFa inline elements are junk; RDFa-bearing empties
         (hidden <span property resource/> definitions) are kept by C6's predicates,
         and an empty a[@id] is an anchor target, not junk -->
    <xsl:template match="(strong | em | a | code)[not(normalize-space(.))][not(.//img)][not(@id)]
            [not(@property or @about or @typeof or @resource or @content)]" mode="cm:canonical" priority="1"/>

    <!-- C10: line structure inside pre is text, not markup -->
    <xsl:template match="br[ancestor::pre]" mode="cm:canonical" priority="1">
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

    <!-- C9: a trailing <br> is a caret placeholder, not content -->
    <xsl:template match="br[not(following-sibling::node()[self::* or self::text()[normalize-space()]])]"
        mode="cm:canonical"/>

    <!-- ................ pass 2: mode="cm:normalize" ................ -->

    <!-- N0: ephemera are placed by the editor, not judged by the DTD (the load-init
         path runs this pass alone, where chrome and rendering subtrees still exist) -->
    <xsl:template match="*[@data-role]" mode="cm:normalize" priority="2">
        <xsl:copy-of select="."/>
    </xsl:template>

    <!-- N1: blocks inside an inline-only element (p, h1-h6, dt, caption, pre, inlines).
         Matches EVERY inline-only element and decides on the PROCESSED children, so
         blocks surfaced by inner splits are handled in the same bottom-up pass (one
         invocation reaches the fixed point). An RDFa-bearing parent stays whole -
         its block children demote to inline via mode="cm:demote" (recursive, all
         attributes kept), so the extracted literal and triples are unchanged. A
         plain parent splits around its block children; inline runs keep a shell
         copying ALL attributes (safe: this branch is non-RDFa by construction, so
         nothing duplicates a triple - an <a href> split by a block keeps its target
         on both halves); whitespace-only residue between blocks drops -->
    <xsl:template match="*[cm:inline-only(local-name(.))]" mode="cm:normalize">
        <xsl:variable name="name" as="xs:string" select="local-name(.)"/>
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="empty($kids/self::*[cm:block(local-name(.))])">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:sequence select="$kids"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="@property or @about or @typeof or @resource or @content or @datatype">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="$kids" mode="cm:demote"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="attributes" as="attribute()*" select="@*"/>
                <xsl:for-each-group select="$kids"
                        group-adjacent="boolean(self::*[cm:block(local-name(.))])">
                    <xsl:choose>
                        <xsl:when test="current-grouping-key()">
                            <xsl:sequence select="current-group()"/>
                        </xsl:when>
                        <xsl:when test="exists(current-group()[self::* or self::text()[normalize-space()]])">
                            <xsl:element name="{$name}">
                                <xsl:copy-of select="$attributes"/>
                                <xsl:sequence select="current-group()"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each-group>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- inline demotion for content preserved inside an RDFa-bearing inline-only
         element: every known non-inline element renames to span (all attributes
         kept), recursively - a demoted list becomes nested spans, never a bare li
         inside a span. Text, inline and unknown elements pass through with their
         children demoted likewise -->
    <xsl:mode name="cm:demote" on-no-match="shallow-copy"/>

    <xsl:template match="*[cm:known(local-name(.))][not(cm:inline(local-name(.)))]" mode="cm:demote">
        <span>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </span>
    </xsl:template>

    <!-- N2: blockquote (and noscript) is block-only per Strict - stray text/inline
         runs become paragraphs; RDFa attributes on the container are untouched -->
    <xsl:template match="blockquote | noscript" mode="cm:normalize">
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="cm:wrap-inline-runs($kids, 'p')"/>
        </xsl:copy>
    </xsl:template>

    <!-- N3: ul/ol hold only li - stray children become item content (li is flow) -->
    <xsl:template match="ul | ol" mode="cm:normalize">
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="cm:coerce-children($kids, 'li', 'li')"/>
        </xsl:copy>
    </xsl:template>

    <!-- N4: dl holds only dt/dd - strays become dd content (dd is flow, dt is not) -->
    <xsl:template match="dl" mode="cm:normalize">
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="cm:coerce-children($kids, ('dt', 'dd'), 'dd')"/>
        </xsl:copy>
    </xsl:template>

    <!-- N5: tr holds only th/td - strays become cell content (td is flow) -->
    <xsl:template match="tr" mode="cm:normalize">
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="cm:coerce-children($kids, ('th', 'td'), 'td')"/>
        </xsl:copy>
    </xsl:template>

    <!-- N5b: table sections hold only tr - a stray cell run keeps its cells in a
         fresh row; anything else becomes a one-cell row -->
    <xsl:template match="thead | tbody | tfoot" mode="cm:normalize">
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each-group select="$kids"
                    group-adjacent="boolean(self::*[local-name() = 'tr' or @data-role])">
                <xsl:choose>
                    <xsl:when test="current-grouping-key()">
                        <xsl:sequence select="current-group()"/>
                    </xsl:when>
                    <xsl:when test="exists(current-group()[self::* or self::text()[normalize-space()]])">
                        <tr>
                            <xsl:choose>
                                <xsl:when test="every $n in current-group()[self::*]
                                        satisfies local-name($n) = ('th', 'td')">
                                    <xsl:sequence select="current-group()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <td>
                                        <xsl:sequence select="current-group()"/>
                                    </td>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tr>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="current-group()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

    <!-- N6: children a table cannot hold are hoisted before it (mirrors browser
         foster parenting); whitespace and ephemera stay put -->
    <xsl:template match="table" mode="cm:normalize">
        <xsl:variable name="kids" as="node()*">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="valid" as="xs:string*"
            select="'caption', 'col', 'colgroup', 'thead', 'tfoot', 'tbody', 'tr'"/>
        <xsl:sequence select="$kids[(self::*[not(local-name() = $valid)][not(@data-role)])
            or self::text()[normalize-space()]]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="$kids[self::*[local-name() = $valid or @data-role]
                or self::text()[not(normalize-space())]]"/>
        </xsl:copy>
    </xsl:template>

    <!-- N7: Appendix B pre exclusions, text-preserving: size/position markup
         unwraps, replaced objects fall back to their alternative text -->
    <xsl:template match="(big | small | sub | sup)[ancestor::pre]" mode="cm:normalize" priority="1">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

    <xsl:template match="(img | object)[ancestor::pre]" mode="cm:normalize" priority="1">
        <xsl:value-of select="@alt"/>
    </xsl:template>

    <!-- N8: Appendix B nesting prohibitions - the inner element keeps all its
         attributes (RDFa preserved; a dead @href is harmless) under a valid name -->
    <xsl:template match="a[ancestor::a]" mode="cm:normalize" priority="1">
        <span>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </span>
    </xsl:template>

    <xsl:template match="label[ancestor::label]" mode="cm:normalize" priority="1">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>

</xsl:stylesheet>
