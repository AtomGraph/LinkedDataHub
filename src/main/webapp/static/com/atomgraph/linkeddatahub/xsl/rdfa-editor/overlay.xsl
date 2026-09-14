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

    <!-- select value marking the free-text custom-IRI state ('' means none/unset) -->
    <xsl:variable name="rdfae:custom" as="xs:string" select="'https://w3id.org/atomgraph/rdfa-editor#custom'"/>
    <!-- id of the annotation overlay element; host UIs may shadow this variable -->
    <xsl:variable name="rdfae:overlay-id" as="xs:string" select="'rdfa-editor-overlay'"/>

<!--
    The annotation overlay: rendered once at startup (hidden), then only populated,
    shown and hidden. The form is framed as the statement being asserted - subject,
    predicate, object rows - with type/subject/object overrides in a details
    disclosure. There is no mode selection: the emitted RDFa attributes follow from
    which fields are filled. Form state is read and written via live DOM properties
    (checked/value/disabled/open) - attributes never reflect user input.
-->

    <xsl:template name="rdfae:init-overlay">
        <xsl:for-each select="ixsl:page()//body">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:call-template name="rdfae:render-overlay"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="rdfae:render-overlay">
        <div id="{$rdfae:overlay-id}" class="rdfa-editor-ui" role="dialog" aria-modal="true" aria-label="{rdfae:label('rdfa-annotation')}" style="display: none;">
            <div class="overlay-header">
                <h3><xsl:value-of select="rdfae:label('rdfa-annotation')"/></h3>
            </div>
            <form id="annotation-form">
                <div class="statement">
                    <span class="stmt-role" title="{rdfae:label('rdfa-subject')}">S</span>
                    <div id="stmt-subject" class="stmt-value"/>
                    <span class="stmt-role" title="{rdfae:label('rdfa-predicate')}">P</span>
                    <div class="stmt-control">
                        <xsl:sequence select="rdfae:typeahead-field('property')"/>
                    </div>
                    <span class="stmt-role" title="{rdfae:label('rdfa-object')}">O</span>
                    <div class="stmt-control">
                        <input type="text" name="value" placeholder="{rdfae:label('rdfa-value-placeholder')}"/>
                        <span class="{$helper-text-class}">The selected text; change it to emit a machine-readable content value</span>
                    </div>
                </div>

                <details id="advanced-fields">
                    <summary><xsl:value-of select="rdfae:label('rdfa-advanced-summary')"/></summary>
                    <fieldset>
                        <label><xsl:value-of select="rdfae:label('rdfa-type-typeof')"/></label>
                        <xsl:sequence select="rdfae:typeahead-field('typeof')"/>
                        <span class="{$helper-text-class}">Types the annotated resource; without a subject the typed
                            resource becomes the object of the property (chaining)</span>
                    </fieldset>
                    <fieldset>
                        <label><xsl:value-of select="rdfae:label('rdfa-subject-about')"/></label>
                        <input type="text" name="subject" placeholder="{rdfae:label('rdfa-subject-placeholder')}"/>
                        <span class="{$helper-text-class}"><xsl:value-of select="rdfae:label('rdfa-subject-help')"/></span>
                    </fieldset>
                    <fieldset>
                        <label><xsl:value-of select="rdfae:label('rdfa-object-resource')"/></label>
                        <input type="text" name="object" placeholder="{rdfae:label('rdfa-object-placeholder')}"/>
                        <span class="{$helper-text-class}"><xsl:value-of select="rdfae:label('rdfa-object-help')"/></span>
                    </fieldset>
                    <fieldset>
                        <label><xsl:value-of select="rdfae:label('rdfa-datatype')"/></label>
                        <select name="datatype">
                            <option value="">(plain literal)</option>
                            <xsl:variable name="xsd" as="xs:string" select="'http://www.w3.org/2001/XMLSchema#'"/>
                            <xsl:for-each select="'string', 'date', 'dateTime', 'time', 'integer',
                                    'decimal', 'double', 'float', 'boolean', 'anyURI'">
                                <option value="{$xsd || .}">xsd:<xsl:value-of select="."/></option>
                            </xsl:for-each>
                            <option value="{$rdfae:custom}">-- Custom datatype --</option>
                        </select>
                        <input type="text" name="custom-datatype" placeholder="{rdfae:label('rdfa-datatype-placeholder')}" style="display: none;"/>
                        <span class="{$helper-text-class}">Types the literal (e.g. xsd:date, xsd:integer);
                            mutually exclusive with a language tag</span>
                    </fieldset>
                    <fieldset>
                        <label><xsl:value-of select="rdfae:label('rdfa-language')"/></label>
                        <input type="text" name="lang" placeholder="{rdfae:label('rdfa-language-placeholder')}"/>
                        <span class="{$helper-text-class}"><xsl:value-of select="rdfae:label('rdfa-language-help')"/></span>
                    </fieldset>
                </details>

                <div class="action-buttons">
                    <button type="button" class="{$button-danger-class} remove-action" style="display: none;"><xsl:value-of select="rdfae:label('remove')"/></button>
                    <button type="button" class="{$button-primary-class} spo-action"><xsl:value-of select="rdfae:label('annotate')"/></button>
                    <button type="button" class="{$button-secondary-class} cancel-action"><xsl:value-of select="rdfae:label('cancel')"/></button>
                </div>
            </form>
        </div>
    </xsl:template>

    <!-- all form reads via live properties: the checked/value attributes never change on user input -->
    <xsl:function name="rdfae:form-values" as="map(xs:string, xs:string?)">
        <xsl:param name="form" as="element()"/>

        <xsl:map>
            <xsl:map-entry key="'property'" select="rdfae:typeahead-value($form, 'property')"/>
            <xsl:map-entry key="'typeof'" select="rdfae:typeahead-value($form, 'typeof')"/>
            <xsl:map-entry key="'subject'" select="rdfae:input-value($form, 'subject')[. ne '']"/>
            <xsl:map-entry key="'object'" select="rdfae:input-value($form, 'object')[. ne '']"/>
            <xsl:map-entry key="'value'" select="rdfae:input-value($form, 'value')[. ne '']"/>
            <xsl:map-entry key="'datatype'" select="rdfae:select-or-custom($form, 'datatype', 'custom-datatype')"/>
            <xsl:map-entry key="'lang'" select="rdfae:input-value($form, 'lang')[. ne '']"/>
        </xsl:map>
    </xsl:function>

    <!-- a select whose empty value defers to its free-text custom input -->
    <xsl:function name="rdfae:select-or-custom" as="xs:string?">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="select-name" as="xs:string"/>
        <xsl:param name="custom-name" as="xs:string"/>

        <xsl:variable name="value" as="xs:string"
            select="string(ixsl:get(($form//select[@name = $select-name])[1], 'value'))"/>
        <xsl:sequence select="if ($value eq $rdfae:custom)
            then rdfae:input-value($form, $custom-name)[. ne '']
            else $value[. ne '']"/>
    </xsl:function>

    <!-- reset the form; when editing, pre-fill it from the annotated element.
         $value prefills the object row: the selected text, or @content/text when editing -->
    <xsl:template name="rdfae:populate-form">
        <xsl:param name="span" as="element()?" select="()"/>
        <xsl:param name="value" as="xs:string?" select="()"/>

        <xsl:for-each select="id('annotation-form', ixsl:page())">
            <xsl:variable name="form" as="element()" select="."/>
            <xsl:sequence select="ixsl:call(., 'reset', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:for-each select=".//input[@name = 'custom-datatype']">
                <ixsl:set-style name="display" select="'none'"/>
            </xsl:for-each>
            <!-- the typeahead widgets are not native controls, so form.reset() leaves
                 them as they were: reset both explicitly (empty in create mode, the
                 committed button in edit mode) -->
            <xsl:call-template name="rdfae:typeahead-set-value">
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="field" select="'property'"/>
                <xsl:with-param name="iri" select="string($span/@property)"/>
            </xsl:call-template>
            <xsl:call-template name="rdfae:typeahead-set-value">
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="field" select="'typeof'"/>
                <xsl:with-param name="iri" select="string($span/@typeof)"/>
            </xsl:call-template>
            <xsl:for-each select=".//button[tokenize(@class) = 'remove-action']">
                <ixsl:set-style name="display" select="if (exists($span)) then 'inline-block' else 'none'"/>
            </xsl:for-each>
            <xsl:for-each select=".//input[@name = 'value']">
                <ixsl:set-property name="value" select="($value, '')[1]" object="."/>
            </xsl:for-each>
            <xsl:call-template name="rdfae:reveal-fields">
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="span" select="$span"/>
            </xsl:call-template>
            <!-- datatype and language are mutually exclusive (datatype wins): a datatype
                 on the edited annotation disables the language input -->
            <xsl:for-each select=".//input[@name = 'lang']">
                <ixsl:set-property name="disabled" select="exists($span/@datatype)" object="."/>
            </xsl:for-each>

            <xsl:for-each select="$span">
                <xsl:for-each select="$form//input[@name = 'subject']">
                    <ixsl:set-property name="value" select="string($span/@about)" object="."/>
                </xsl:for-each>
                <xsl:for-each select="$form//input[@name = 'object']">
                    <ixsl:set-property name="value" select="string($span/@resource)" object="."/>
                </xsl:for-each>
                <xsl:for-each select="@datatype">
                    <xsl:call-template name="rdfae:set-select-or-custom">
                        <xsl:with-param name="form" select="$form"/>
                        <xsl:with-param name="select-name" select="'datatype'"/>
                        <xsl:with-param name="custom-name" select="'custom-datatype'"/>
                        <xsl:with-param name="value" select="string(.)"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:for-each select="$form//input[@name = 'lang']">
                    <ixsl:set-property name="value" select="string(($span/@lang, $span/@xml:lang)[1])" object="."/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- reflect the edited annotation's non-value state into the form's chrome: here, the disclosure
         that holds the type/subject/object overrides. The one shape-dependent step in populate-form,
         so it is its own template - a host whose overlay groups those fields differently (tabs, a
         segmented object switch) overrides this and leaves the rest of the prefill alone -->
    <xsl:template name="rdfae:reveal-fields">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="span" as="element()?"/>

        <xsl:for-each select="id('advanced-fields', ixsl:page())">
            <ixsl:set-property name="open"
                select="exists($span/(@about | @resource | @typeof | @datatype | @lang | @xml:lang))" object="."/>
        </xsl:for-each>
    </xsl:template>





    <!-- set a select's value via the live property; an IRI absent from the options
         leaves the select empty, so route it to the custom input instead -->
    <xsl:template name="rdfae:set-select-or-custom">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="select-name" as="xs:string"/>
        <xsl:param name="custom-name" as="xs:string"/>
        <xsl:param name="value" as="xs:string"/>

        <xsl:for-each select="($form//select[@name = $select-name])[1]">
            <ixsl:set-property name="value" select="$value" object="."/>
            <xsl:if test="string(ixsl:get(., 'value')) ne $value">
                <ixsl:set-property name="value" select="$rdfae:custom" object="."/>
                <xsl:for-each select="($form//input[@name = $custom-name])[1]">
                    <ixsl:set-property name="value" select="$value" object="."/>
                    <ixsl:set-style name="display" select="'block'"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- show an element at the event position, clamped to the viewport with 10px
         padding. Positioned absolutely in page coordinates (client + scroll offset)
         so it scrolls with the content -->
    <xsl:template name="rdfae:show-at">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="event"/>

        <xsl:call-template name="rdfae:show-at-point">
            <xsl:with-param name="element" select="$element"/>
            <xsl:with-param name="x" select="ixsl:get($event, 'clientX')"/>
            <xsl:with-param name="y" select="ixsl:get($event, 'clientY')"/>
        </xsl:call-template>
    </xsl:template>

    <!-- the positioning core: shared by mouse-driven dialogs (rdfae:show-at) and the
         caret-anchored popups (slash menu) which have no mouse event -->
    <xsl:template name="rdfae:show-at-point">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="x" as="xs:double"/>
        <xsl:param name="y" as="xs:double"/>

        <xsl:for-each select="$element">
            <ixsl:set-style name="display" select="'block'"/>
            <ixsl:set-style name="position" select="'absolute'"/>

            <xsl:variable name="client-x" as="xs:double" select="$x"/>
            <xsl:variable name="client-y" as="xs:double" select="$y"/>
            <xsl:variable name="scroll-x" as="xs:double" select="ixsl:get(ixsl:window(), 'scrollX')"/>
            <xsl:variable name="scroll-y" as="xs:double" select="ixsl:get(ixsl:window(), 'scrollY')"/>
            <xsl:variable name="viewport-width" as="xs:double" select="ixsl:get(ixsl:window(), 'innerWidth')"/>
            <xsl:variable name="viewport-height" as="xs:double" select="ixsl:get(ixsl:window(), 'innerHeight')"/>
            <xsl:variable name="width" as="xs:double" select="ixsl:get(., 'offsetWidth')"/>
            <xsl:variable name="height" as="xs:double" select="ixsl:get(., 'offsetHeight')"/>

            <ixsl:set-style name="left" select="((if ($client-x + $width + 10 gt $viewport-width)
                then max(($viewport-width - $width - 10, 10)) else $client-x) + $scroll-x) || 'px'"/>
            <ixsl:set-style name="top" select="((if ($client-y + $height + 10 gt $viewport-height)
                then max(($viewport-height - $height - 10, 10)) else $client-y) + $scroll-y) || 'px'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="rdfae:show-overlay">
        <xsl:param name="event"/>
        <xsl:param name="in-scope-subject" as="xs:string?" select="()"/>

        <!-- the overlay is a render-once singleton, but a host may re-render the page
             DOM (or dispose it as a modal) between invocations; rebuild on demand so
             show-at always has an element to position -->
        <xsl:if test="empty(id($rdfae:overlay-id, ixsl:page()))">
            <xsl:call-template name="rdfae:init-overlay"/>
        </xsl:if>

        <xsl:call-template name="rdfae:show-at">
            <xsl:with-param name="element" select="id($rdfae:overlay-id, ixsl:page())"/>
            <xsl:with-param name="event" select="$event"/>
        </xsl:call-template>

        <xsl:for-each select="id('stmt-subject', ixsl:page())">
            <ixsl:set-attribute name="data-inherited-subject" select="($in-scope-subject, '')[1]"/>
            <ixsl:set-property name="textContent" select="($in-scope-subject, '')[1]" object="."/>
            <!-- the readout is a single line that may be narrower than the IRI; @title is where the whole of it
                 stays reachable. Written wherever textContent is, so the two cannot say different things -->
            <ixsl:set-attribute name="title" select="($in-scope-subject, '')[1]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- the browser drops the visible selection once focus moves into the overlay
         form: paint the stored range's client rects as pointer-transparent hint
         boxes (no content mutation), cleared on hide -->
    <xsl:template name="rdfae:show-selection-hint">
        <xsl:param name="range"/>

        <xsl:variable name="scroll-x" as="xs:double" select="ixsl:get(ixsl:window(), 'scrollX')"/>
        <xsl:variable name="scroll-y" as="xs:double" select="ixsl:get(ixsl:window(), 'scrollY')"/>
        <!-- getClientRects returns a DOMRectList; Array.from marshals it to a sequence -->
        <xsl:for-each select="ixsl:call(ixsl:get(ixsl:window(), 'Array'), 'from',
                [ ixsl:call($range, 'getClientRects', []) ])"><!-- -->
            <xsl:variable name="rect" select="."/>
            <xsl:for-each select="ixsl:page()//body">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div class="rdfa-editor-selection-hint" style="left: {ixsl:get($rect, 'left') + $scroll-x}px;
                        top: {ixsl:get($rect, 'top') + $scroll-y}px; width: {ixsl:get($rect, 'width')}px;
                        height: {ixsl:get($rect, 'height')}px;"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="rdfae:hide-selection-hint">
        <xsl:for-each select="ixsl:page()//body/div[contains-token(@class, 'rdfa-editor-selection-hint')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- single teardown point: hiding the overlay always clears the interaction state -->
    <xsl:template name="rdfae:hide-overlay">
        <xsl:call-template name="rdfae:hide-selection-hint"/>
        <xsl:for-each select="id($rdfae:overlay-id, ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
        <ixsl:set-property name="editingSpan" select="()" object="rdfae:editor-state()"/>
        <ixsl:set-property name="range" select="()" object="rdfae:editor-state()"/>
        <!-- return focus to the content -->
        <xsl:for-each select="ixsl:get(rdfae:editor-state(), 'activeBlock')[exists(rdfae:block-of(.))]">
            <xsl:call-template name="rdfae:focus">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="div[@id = $rdfae:overlay-id]" mode="ixsl:onkeydown">
        <xsl:if test="string(ixsl:get(ixsl:event(), 'key')) = 'Escape'">
            <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:call-template name="rdfae:hide-overlay"/>
        </xsl:if>
    </xsl:template>

    <!-- a subject override is reflected in the statement's S row -->
    <xsl:template match="input[@name = 'subject']" mode="ixsl:onchange">
        <xsl:variable name="value" as="xs:string" select="string(ixsl:get(., 'value'))"/>
        <xsl:for-each select="id('stmt-subject', ixsl:page())">
            <ixsl:set-property name="textContent"
                select="($value[. ne ''], string(@data-inherited-subject))[1]" object="."/>
            <ixsl:set-attribute name="title" select="($value[. ne ''], string(@data-inherited-subject))[1]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- the datatype select's 'Custom' option reveals the free-text IRI input;
         a chosen datatype wins over language, disabling the language input -->
    <xsl:template match="select[@name = 'datatype']" mode="ixsl:onchange">
        <xsl:variable name="value" as="xs:string" select="string(ixsl:get(., 'value'))"/>
        <xsl:variable name="custom" as="xs:boolean" select="$value eq $rdfae:custom"/>
        <xsl:for-each select="ancestor::form//input[@name = 'custom-datatype']">
            <ixsl:set-style name="display" select="if ($custom) then 'block' else 'none'"/>
            <xsl:if test="$custom">
                <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="ancestor::form//input[@name = 'lang']">
            <ixsl:set-property name="disabled" select="$value ne ''" object="."/>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
