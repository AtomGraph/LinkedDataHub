<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:cm="urn:rdfa-editor:content-model"
exclude-result-prefixes="#all"
version="3.0">

<!--
    XHTML content model as data: a 1:1 transcription of the XHTML 1.0 Strict DTD
    (Second Edition, REC-xhtml1-20020801, Appendix A.1) parameter entities and
    element declarations, plus the Appendix B element prohibitions, extended with
    HTML5 figure/figcaption (WHATWG HTML 4.4.12-4.4.13) - the one editor block
    kind XHTML 1.0 lacks.

    Pure XSLT 3.0, include-free, namespace-agnostic (all predicates take element
    names, callers pass local-name()). The single source of truth for nesting
    decisions across the editor: editability init and the keyboard state machines
    (edit.xsl), boundary normalization (canonical-xhtml.xsl) and nesting lint
    (lint-xhtml.xsl) all consult these predicates, so their verdicts cannot drift
    apart. The editor contract "region children are blocks" is deliberately NOT
    encoded here - it is not the DTD's rule.
-->

    <!-- ................. Appendix A.1 parameter entities ................. -->

    <xsl:variable name="cm:special.pre"  as="xs:string*" select="'br', 'span', 'bdo', 'map'"/>
    <xsl:variable name="cm:special"      as="xs:string*" select="$cm:special.pre, 'object', 'img'"/>
    <xsl:variable name="cm:fontstyle"    as="xs:string*" select="'tt', 'i', 'b', 'big', 'small'"/>
    <xsl:variable name="cm:phrase"       as="xs:string*" select="'em', 'strong', 'dfn', 'code', 'q',
        'samp', 'kbd', 'var', 'cite', 'abbr', 'acronym', 'sub', 'sup'"/>
    <xsl:variable name="cm:inline.forms" as="xs:string*" select="'input', 'select', 'textarea', 'label', 'button'"/>
    <xsl:variable name="cm:misc.inline"  as="xs:string*" select="'ins', 'del', 'script'"/>
    <xsl:variable name="cm:misc"         as="xs:string*" select="'noscript', $cm:misc.inline"/>
    <xsl:variable name="cm:inline"       as="xs:string*" select="'a', $cm:special, $cm:fontstyle,
        $cm:phrase, $cm:inline.forms"/>
    <xsl:variable name="cm:heading"      as="xs:string*" select="'h1', 'h2', 'h3', 'h4', 'h5', 'h6'"/>
    <xsl:variable name="cm:lists"        as="xs:string*" select="'ul', 'ol', 'dl'"/>
    <xsl:variable name="cm:blocktext"    as="xs:string*" select="'pre', 'hr', 'blockquote', 'address'"/>
    <!-- %block; plus the figure extension (figure is flow/block content in HTML5,
         so it participates wherever %block; appears: regions, blockquote, li, td) -->
    <xsl:variable name="cm:block-set"    as="xs:string*" select="'p', $cm:heading, 'div', $cm:lists,
        $cm:blocktext, 'fieldset', 'table', 'figure'"/>

    <!-- content-model child sets: %Inline;, %Block;, %Flow;, %a.content;, %pre.content; -->
    <xsl:variable name="cm:Inline-children" as="xs:string*" select="$cm:inline, $cm:misc.inline"/>
    <xsl:variable name="cm:Block-children"  as="xs:string*" select="$cm:block-set, 'form', $cm:misc"/>
    <xsl:variable name="cm:Flow-children"   as="xs:string*" select="$cm:block-set, 'form', $cm:inline, $cm:misc"/>
    <xsl:variable name="cm:a-children"      as="xs:string*" select="$cm:special, $cm:fontstyle,
        $cm:phrase, $cm:inline.forms, $cm:misc.inline"/>
    <xsl:variable name="cm:pre-children"    as="xs:string*" select="'a', $cm:fontstyle, $cm:phrase,
        $cm:special.pre, $cm:misc.inline, $cm:inline.forms"/>

    <!-- ................. per-element content models ................. -->

    <!-- one entry per element declaration: allowed child element names ('children')
         and whether #PCDATA is allowed ('text'). Empty 'children' + false 'text'
         = EMPTY. Appendix B prohibitions are NOT folded in here (the DTD cannot
         express them either) - see $cm:prohibitions.
         map:merge over map:entry rather than one map literal: the SaxonJS 3
         compiler fails an internal assertion on large nested map literals -->
    <xsl:variable name="cm:model" as="map(xs:string, map(*))" select="map:merge((
        (: %Inline; elements :)
        ('p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'address', 'dt', 'caption', 'legend',
            'label', 'span', 'bdo', $cm:fontstyle, $cm:phrase)
            ! map:entry(., map{ 'children': $cm:Inline-children, 'text': true() }),
        (: %Flow; elements :)
        ('div', 'li', 'dd', 'td', 'th', 'ins', 'del')
            ! map:entry(., map{ 'children': $cm:Flow-children, 'text': true() }),
        (: restricted-inline and element-only content models :)
        map:entry('pre',        map{ 'children': $cm:pre-children, 'text': true() }),
        map:entry('a',          map{ 'children': $cm:a-children, 'text': true() }),
        map:entry('blockquote', map{ 'children': $cm:Block-children, 'text': false() }),
        map:entry('noscript',   map{ 'children': $cm:Block-children, 'text': false() }),
        (: %form.content; = (%block; | %misc;)* - unlike %Block;, it excludes form
           (forms must not be nested) :)
        map:entry('form',       map{ 'children': ($cm:block-set, $cm:misc), 'text': false() }),
        map:entry('fieldset',   map{ 'children': ('legend', $cm:Flow-children), 'text': true() }),
        map:entry('button',     map{ 'children': ('p', $cm:heading, 'div', $cm:lists, $cm:blocktext,
                                    'table', $cm:special, $cm:fontstyle, $cm:phrase, $cm:misc), 'text': true() }),
        map:entry('object',     map{ 'children': ('param', $cm:Flow-children), 'text': true() }),
        map:entry('map',        map{ 'children': ($cm:block-set, 'form', $cm:misc, 'area'), 'text': false() }),
        map:entry('ul',         map{ 'children': 'li', 'text': false() }),
        map:entry('ol',         map{ 'children': 'li', 'text': false() }),
        map:entry('dl',         map{ 'children': ('dt', 'dd'), 'text': false() }),
        map:entry('select',     map{ 'children': ('optgroup', 'option'), 'text': false() }),
        map:entry('optgroup',   map{ 'children': 'option', 'text': false() }),
        ('option', 'textarea', 'script')
            ! map:entry(., map{ 'children': (), 'text': true() }),
        (: table structure :)
        map:entry('table',      map{ 'children': ('caption', 'col', 'colgroup', 'thead', 'tfoot', 'tbody', 'tr'), 'text': false() }),
        ('thead', 'tfoot', 'tbody')
            ! map:entry(., map{ 'children': 'tr', 'text': false() }),
        map:entry('tr',         map{ 'children': ('th', 'td'), 'text': false() }),
        map:entry('colgroup',   map{ 'children': 'col', 'text': false() }),
        (: EMPTY elements :)
        ('hr', 'br', 'img', 'param', 'area', 'col', 'input')
            ! map:entry(., map{ 'children': (), 'text': false() }),
        (: HTML5 figure extension :)
        map:entry('figure',     map{ 'children': ($cm:Flow-children, 'figcaption'), 'text': true() }),
        map:entry('figcaption', map{ 'children': $cm:Flow-children, 'text': true() })
    ))"/>

    <!-- Appendix B element prohibitions: element name -> ancestor element names
         under which it must not appear, at any depth -->
    <xsl:variable name="cm:prohibitions" as="map(xs:string, xs:string*)" select="map{
        'a':        'a',
        'img':      'pre',
        'object':   'pre',
        'big':      'pre',
        'small':    'pre',
        'sub':      'pre',
        'sup':      'pre',
        'input':    'button',
        'select':   'button',
        'textarea': 'button',
        'label':    ('button', 'label'),
        'button':   'button',
        'form':     ('button', 'form'),
        'fieldset': 'button',
        'iframe':   'button',
        'isindex':  'button'
    }"/>

    <!-- ................. predicates ................. -->

    <xsl:function name="cm:known" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="map:contains($cm:model, $name)"/>
    </xsl:function>

    <!-- block-level per %block; (+ figure): the grouping axis for run wrapping -->
    <xsl:function name="cm:block" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="$name = $cm:block-set"/>
    </xsl:function>

    <xsl:function name="cm:inline" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="$name = $cm:Inline-children"/>
    </xsl:function>

    <xsl:function name="cm:allows-child" as="xs:boolean">
        <xsl:param name="parent" as="xs:string"/>
        <xsl:param name="child" as="xs:string"/>
        <xsl:sequence select="$child = $cm:model($parent)?children"/>
    </xsl:function>

    <xsl:function name="cm:allows-text" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="($cm:model($name)?text, false())[1]"/>
    </xsl:function>

    <!-- text-bearing element that admits no block children: p, h1-h6, dt, caption, pre, inlines -->
    <xsl:function name="cm:inline-only" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="cm:allows-text($name) and not($cm:model($name)?children = $cm:block-set)"/>
    </xsl:function>

    <!-- mixed-content element admitting text AND blocks: li, dd, td, th, div, figure, figcaption -->
    <xsl:function name="cm:flow" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="cm:allows-text($name) and $cm:model($name)?children = $cm:block-set"/>
    </xsl:function>

    <!-- element-only container: ul, ol, dl, blockquote, table structure - never a text host -->
    <xsl:function name="cm:structural" as="xs:boolean">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="cm:known($name) and not(cm:allows-text($name))
            and exists($cm:model($name)?children)"/>
    </xsl:function>

    <xsl:function name="cm:prohibited-ancestors" as="xs:string*">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="if (map:contains($cm:prohibitions, $name)) then $cm:prohibitions($name) else ()"/>
    </xsl:function>

    <!-- an element sits validly under its parent: child of a known parent must be
         declared, and no Appendix B ancestor prohibition may apply. Unknown child
         or parent names are not judged (lint reports them as unknown-element) -->
    <xsl:function name="cm:valid-nesting" as="xs:boolean">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="name" as="xs:string" select="local-name($element)"/>
        <xsl:sequence select="(empty($element/parent::*)
                or not(cm:known(local-name($element/parent::*)))
                or not(cm:known($name))
                or cm:allows-child(local-name($element/parent::*), $name))
            and empty($element/ancestor::*[local-name() = cm:prohibited-ancestors($name)])"/>
    </xsl:function>

</xsl:stylesheet>
