<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
xmlns:rdfax="https://w3id.org/atomgraph/rdfa-editor/rdfa#"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
version="3.0">

<!--
    Event handling. One interaction model: right-click inside editable content.
    On an existing annotation it opens the editor pre-filled (with a Remove action);
    on a plain selection it validates the range and opens the create form.
    Plain clicks never open the overlay, so the caret stays usable while editing text.
-->

    <xsl:template match="*[@contenteditable = 'true']" mode="ixsl:oncontextmenu">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="target" select="ixsl:get($event, 'target')"/>
        <!-- innermost annotated element inside this editable root, plus the block
             itself when it carries its own @property (e.g. h1[property=dct:title]) -
             a genuine block-level annotation. A block that only declares a subject
             (@about/@typeof/@resource) stays structural and is left to create mode. -->
        <xsl:variable name="annotation" as="element()?"
            select="($target/ancestor-or-self::*[@property or @typeof or @about or @resource]
                intersect (descendant::* | self::*[@property]))[last()]"/>
        <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:choose>
            <!-- edit mode -->
            <xsl:when test="exists($annotation)">
                <ixsl:set-property name="editingSpan" select="$annotation" object="rdfae:editor-state()"/>
                <xsl:call-template name="rdfae:populate-form">
                    <xsl:with-param name="span" select="$annotation"/>
                    <!-- rdfax:literal-value, not string(): a block annotation contains a
                         chrome span whose ⠿ text would otherwise leak into the value -->
                    <xsl:with-param name="value" select="if (exists($annotation/@content))
                        then string($annotation/@content) else rdfax:literal-value($annotation)"/>
                </xsl:call-template>
                <xsl:call-template name="rdfae:show-overlay">
                    <xsl:with-param name="event" select="$event"/>
                    <xsl:with-param name="in-scope-subject"
                        select="($annotation/@about ! string(.),
                            $annotation/parent::* ! rdfax:in-scope-subject(., rdfae:document-uri()))[1]"/>
                </xsl:call-template>
            </xsl:when>
            <!-- create mode -->
            <xsl:otherwise>
                <xsl:variable name="selection" select="rdfae:selection()"/>
                <xsl:if test="ixsl:get($selection, 'rangeCount') ge 1 and not(ixsl:get($selection, 'isCollapsed'))">
                    <xsl:variable name="range" select="rdfae:caret-range()"/>
                    <xsl:choose>
                        <xsl:when test="rdfae:selection-valid($range)">
                            <ixsl:set-property name="range" select="$range" object="rdfae:editor-state()"/>
                            <ixsl:set-property name="editingSpan" select="()" object="rdfae:editor-state()"/>
                            <xsl:call-template name="rdfae:show-selection-hint">
                                <xsl:with-param name="range" select="$range"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:populate-form">
                                <xsl:with-param name="value" select="string(ixsl:call($selection, 'toString', []))"/>
                            </xsl:call-template>
                            <xsl:call-template name="rdfae:show-overlay">
                                <xsl:with-param name="event" select="$event"/>
                                <xsl:with-param name="in-scope-subject" select="rdfax:in-scope-subject(., rdfae:document-uri())"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="rdfae:show-flash">
                                <xsl:with-param name="range" select="$range"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- surroundContents() succeeds when the range starts and ends in the same
         container, or in sibling text nodes; xsl:try in the Annotate handler backstops
         the partial-selection cases this misses -->
    <xsl:function name="rdfae:selection-valid" as="xs:boolean">
        <xsl:param name="range"/>

        <xsl:variable name="start" select="ixsl:get($range, 'startContainer')"/>
        <xsl:variable name="end" select="ixsl:get($range, 'endContainer')"/>
        <xsl:sequence select="ixsl:call($start, 'isSameNode', [ $end ])
            or (ixsl:get($start, 'nodeType') = 3 and ixsl:get($end, 'nodeType') = 3
                and ixsl:call(ixsl:get($start, 'parentNode'), 'isSameNode', [ ixsl:get($end, 'parentNode') ]))"/>
    </xsl:function>

    <!-- the single write path for RDFa attributes, shared by create and edit. No modes:
         the attributes follow from the filled fields. A value differing from the display
         text becomes @content - unless @resource is the object (RDFa step 11: @content
         would take precedence and orphan the resource) -->
    <xsl:template name="rdfae:apply-annotation">
        <xsl:param name="target" as="element()"/>
        <xsl:param name="values" as="map(xs:string, xs:string?)"/>
        <xsl:param name="reference-text" as="xs:string"/>

        <xsl:for-each select="$target">
            <xsl:variable name="element" select="."/>
            <xsl:for-each select="'about', 'typeof', 'property', 'resource', 'content', 'datatype', 'lang', 'xml:lang'">
                <ixsl:remove-attribute name="{.}" object="$element"/>
            </xsl:for-each>

            <xsl:if test="exists($values?subject)">
                <ixsl:set-attribute name="about" select="$values?subject"/>
            </xsl:if>
            <xsl:if test="exists($values?typeof)">
                <ixsl:set-attribute name="typeof" select="$values?typeof"/>
            </xsl:if>
            <xsl:if test="exists($values?property)">
                <ixsl:set-attribute name="property" select="$values?property"/>
            </xsl:if>
            <xsl:if test="exists($values?object)">
                <ixsl:set-attribute name="resource" select="$values?object"/>
            </xsl:if>
            <xsl:if test="exists($values?value[. ne $reference-text]) and empty($values?object)">
                <ixsl:set-attribute name="content" select="$values?value"/>
            </xsl:if>
            <!-- literal-type markup only when the object is a literal; @datatype wins over
                 @lang (RDFa: a datatype forces a typed literal and language is ignored) -->
            <xsl:if test="empty($values?object)">
                <xsl:choose>
                    <xsl:when test="exists($values?datatype)">
                        <ixsl:set-attribute name="datatype" select="$values?datatype"/>
                    </xsl:when>
                    <xsl:when test="exists($values?lang)">
                        <ixsl:set-attribute name="lang" select="$values?lang"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[tokenize(@class) = 'spo-action']" mode="ixsl:onclick">
        <xsl:variable name="values" as="map(xs:string, xs:string?)" select="rdfae:form-values(ancestor::form)"/>
        <xsl:variable name="editing" select="ixsl:get(rdfae:editor-state(), 'editingSpan')"/>

        <xsl:choose>
            <xsl:when test="exists($editing)">
                <xsl:call-template name="rdfae:push-undo"/>
                <xsl:call-template name="rdfae:apply-annotation">
                    <xsl:with-param name="target" select="$editing"/>
                    <xsl:with-param name="values" select="$values"/>
                    <!-- chrome-excluded, so an unchanged block value doesn't spuriously emit @content -->
                    <xsl:with-param name="reference-text" select="rdfax:literal-value($editing)"/>
                </xsl:call-template>
                <xsl:call-template name="rdfae:after-mutation"/>
                <xsl:call-template name="rdfae:hide-overlay"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="range" select="ixsl:get(rdfae:editor-state(), 'range')"/>
                <xsl:variable name="reference-text" as="xs:string" select="string(ixsl:call($range, 'toString', []))"/>
                <!-- capture pre-wrap state; push only when the wrap succeeded -->
                <xsl:variable name="snapshot-root" as="element()?" select="rdfae:active-root()"/>
                <xsl:variable name="snapshot" as="xs:string?"
                    select="$snapshot-root ! string(ixsl:get(., 'innerHTML'))"/>
                <xsl:variable name="span" as="element()?">
                    <xsl:call-template name="rdfae:wrap-range">
                        <xsl:with-param name="range" select="$range"/>
                        <xsl:with-param name="name" select="'span'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="$span">
                    <xsl:call-template name="rdfae:push-undo">
                        <xsl:with-param name="root" select="$snapshot-root"/>
                        <xsl:with-param name="snapshot" select="$snapshot"/>
                    </xsl:call-template>
                    <xsl:call-template name="rdfae:apply-annotation">
                        <xsl:with-param name="target" select="."/>
                        <xsl:with-param name="values" select="$values"/>
                        <xsl:with-param name="reference-text" select="$reference-text"/>
                    </xsl:call-template>
                    <xsl:call-template name="rdfae:after-mutation"/>
                </xsl:for-each>
                <xsl:call-template name="rdfae:hide-overlay"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- unwrap an element: move its children up, drop it, merge text nodes -->
    <xsl:template name="rdfae:unwrap-element">
        <xsl:param name="element" as="element()"/>

        <xsl:variable name="parent" select="ixsl:get($element, 'parentNode')"/>
        <xsl:for-each select="1 to xs:integer(ixsl:get($element, 'childNodes.length'))">
            <xsl:sequence select="ixsl:call($parent, 'insertBefore', [ ixsl:get($element, 'firstChild'), $element ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:sequence select="ixsl:call($parent, 'removeChild', [ $element ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call($parent, 'normalize', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- wrap a range in a fresh element; on boundary-crossing selections flash and return nothing -->
    <xsl:template name="rdfae:wrap-range" as="element()?">
        <xsl:param name="range"/>
        <xsl:param name="name" as="xs:string"/>

        <xsl:variable name="element" as="element()" select="ixsl:call(ixsl:page(), 'createElement', [ $name ])"/>
        <xsl:try>
            <xsl:sequence select="ixsl:call($range, 'surroundContents', [ $element ])[current-date() lt xs:date('2000-01-01')]"/>
            <!-- surroundContents leaves the selection undefined; re-select the wrapped
                 contents so subsequent toggles resolve their target -->
            <xsl:sequence select="ixsl:call(rdfae:selection(), 'selectAllChildren',
                [ $element ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="$element"/>
            <xsl:catch errors="*">
                <xsl:call-template name="rdfae:show-flash">
                    <xsl:with-param name="range" select="$range"/>
                </xsl:call-template>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="button[tokenize(@class) = 'remove-action']" mode="ixsl:onclick">
        <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'editingSpan')">
            <xsl:call-template name="rdfae:push-undo"/>
            <xsl:choose>
                <!-- a block carries its annotation on itself: strip the RDFa attributes
                     but keep the block (unwrapping would dissolve the heading/paragraph) -->
                <xsl:when test="rdfae:block-of(.) is .">
                    <xsl:variable name="element" select="."/>
                    <xsl:for-each select="'about', 'typeof', 'property', 'resource', 'content', 'datatype', 'lang', 'xml:lang'">
                        <ixsl:remove-attribute name="{.}" object="$element"/>
                    </xsl:for-each>
                </xsl:when>
                <!-- an inline annotation is a wrapper element: unwrap it -->
                <xsl:otherwise>
                    <xsl:call-template name="rdfae:unwrap-element">
                        <xsl:with-param name="element" select="."/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="rdfae:after-mutation"/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:hide-overlay"/>
    </xsl:template>

    <xsl:template match="button[tokenize(@class) = 'cancel-action']" mode="ixsl:onclick">
        <xsl:call-template name="rdfae:hide-overlay"/>
    </xsl:template>

    <!-- brief red flash over an invalid selection, in page coordinates so it scrolls with the text -->
    <xsl:template name="rdfae:show-flash">
        <xsl:param name="range"/>

        <xsl:variable name="rect" select="ixsl:call($range, 'getBoundingClientRect', [])"/>
        <xsl:variable name="scroll-x" as="xs:double" select="ixsl:get(ixsl:window(), 'scrollX')"/>
        <xsl:variable name="scroll-y" as="xs:double" select="ixsl:get(ixsl:window(), 'scrollY')"/>
        <xsl:for-each select="ixsl:page()//body">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div id="selection-flash" class="invalid-selection-flash"
                    style="position: absolute; pointer-events: none; z-index: 9999; left: {ixsl:get($rect, 'left') + $scroll-x}px; top: {ixsl:get($rect, 'top') + $scroll-y}px; width: {ixsl:get($rect, 'width')}px; height: {ixsl:get($rect, 'height')}px;"/>
            </xsl:result-document>
        </xsl:for-each>
        <ixsl:promise select="ixsl:sleep(1200) => ixsl:then(rdfae:hide-flash#1)"/>
    </xsl:template>

    <xsl:function name="rdfae:hide-flash" as="empty-sequence()" ixsl:updating="yes">
        <xsl:param name="ignored" as="item()?"/>

        <xsl:for-each select="id('selection-flash', ixsl:page())">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:function>

    <!-- the editor renders its own output modal (host pages provide only content regions) -->
    <xsl:template name="rdfae:init-annotate">
        <xsl:for-each select="ixsl:page()//body">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div id="output-modal" class="rdfa-editor-ui" style="display: none;">
                    <div class="modal-content">
                        <span class="modal-close">&#215;</span>
                        <h3 id="output-title">Output</h3>
                        <button id="output-download" type="button" style="display: none;">Download</button>
                        <pre id="output-content"/>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- shared output modal (Extract RDF / View source / lint issues); callers
         passing $filename get a Download button (hidden otherwise) -->
    <xsl:template name="rdfae:show-output">
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="filename" as="xs:string?"/>
        <xsl:param name="media-type" as="xs:string?"/>

        <xsl:for-each select="id('output-title', ixsl:page())">
            <ixsl:set-property name="textContent" select="$title" object="."/>
        </xsl:for-each>
        <xsl:for-each select="id('output-content', ixsl:page())">
            <ixsl:set-property name="textContent" select="$text" object="."/>
        </xsl:for-each>
        <xsl:for-each select="id('output-download', ixsl:page())">
            <xsl:choose>
                <xsl:when test="exists($filename)">
                    <ixsl:set-attribute name="data-filename" select="$filename"/>
                    <ixsl:set-attribute name="data-media-type" select="($media-type, 'text/plain')[1]"/>
                    <ixsl:set-style name="display" select="'inline-block'"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="id('output-modal', ixsl:page())">
            <ixsl:set-style name="display" select="'flex'"/>
        </xsl:for-each>
    </xsl:template>

    <!-- client-side file download: the shown text becomes a Blob clicked through
         an ephemeral object-URL anchor - no server involved, so it works on any
         static hosting (gh-pages included) -->
    <xsl:template match="button[@id = 'output-download']" mode="ixsl:onclick">
        <xsl:variable name="js-function" select="ixsl:eval('(function (text, type, filename) { var url = URL.createObjectURL(new Blob([ text ], { type: type })); var a = document.createElement(''a''); a.href = url; a.download = filename; document.body.appendChild(a); a.click(); a.remove(); setTimeout(function () { URL.revokeObjectURL(url); }, 1000); })')"/>
        <xsl:sequence select="ixsl:call($js-function, 'call',
            [ (), ixsl:get(id('output-content', ixsl:page()), 'textContent'), string(@data-media-type), string(@data-filename) ])
            [current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- extract RDF/XML from the page and display it in the modal, grouped one
         rdf:Description per subject (via rdfae:group-triples) for readability -->
    <xsl:template match="button[@id = 'parse-rdf']" mode="ixsl:onclick">
        <xsl:variable name="rdf" as="element(rdf:RDF)">
            <xsl:call-template name="rdfax:extract-rdfa">
                <xsl:with-param name="doc" select="ixsl:page()"/>
                <xsl:with-param name="base" select="rdfae:document-uri()"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="rdfae:show-output">
            <xsl:with-param name="title" select="'Extracted RDF/XML'"/>
            <xsl:with-param name="text" select="serialize(rdfae:group-triples($rdf), map{ 'method': 'xml', 'indent': true() })"/>
            <xsl:with-param name="filename" select="'content.rdf'"/>
            <xsl:with-param name="media-type" select="'application/rdf+xml'"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="span[tokenize(@class) = 'modal-close']" mode="ixsl:onclick">
        <xsl:for-each select="id('output-modal', ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <!-- clicking the backdrop (not the content) closes the modal -->
    <xsl:template match="div[@id = 'output-modal']" mode="ixsl:onclick">
        <xsl:if test="ixsl:call(ixsl:get(ixsl:event(), 'target'), 'isSameNode', [ . ])">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
