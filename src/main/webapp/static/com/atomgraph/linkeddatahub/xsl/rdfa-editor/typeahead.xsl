<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
extension-element-prefixes="ixsl"
xpath-default-namespace="http://www.w3.org/1999/xhtml"
exclude-result-prefixes="xs"
version="3.0">

<!--
    Typeahead lookups for the annotation form's property and type fields (replacing
    long <select> dropdowns). LinkedDataHub's typeahead fires debounced SPARQL; here
    the vocabularies are already in the SaxonJS document pool, so filtering is a
    synchronous per-keystroke pass over rdfae:vocab-terms - no async, no debounce.

    A field is a stable wrapper span[@data-field] holding one of two states, swapped
    via result-document (literal result elements, the IXSL-idiomatic DOM build):
      - typing:    input.typeahead-input + ul.typeahead-menu (the option list)
      - committed: button.typeahead-value (label + hidden input carrying the IRI)
    The value is read from the hidden input when committed, else from the visible
    input's text when it is an absolute IRI (free entry) or, for an untouched
    button->edit, from @data-editing-iri (cleared on the first keystroke).
-->

    <!-- an absolute IRI has a scheme; free text lacking one is not a usable value -->
    <xsl:function name="rdfae:is-absolute-iri" as="xs:boolean">
        <xsl:param name="s" as="xs:string"/>
        <xsl:sequence select="matches($s, '^[A-Za-z][A-Za-z0-9+.\-]*:')"/>
    </xsl:function>

    <xsl:function name="rdfae:typeahead-placeholder" as="xs:string">
        <xsl:param name="field" as="xs:string"/>
        <xsl:sequence select="if ($field = 'typeof')
            then 'Type or paste a class IRI…' else 'Type or paste a property IRI…'"/>
    </xsl:function>

    <xsl:function name="rdfae:typeahead-kind" as="xs:string">
        <xsl:param name="field" as="xs:string"/>
        <xsl:sequence select="if ($field = 'typeof') then 'class' else 'property'"/>
    </xsl:function>

    <!-- all terms of the field's kind across every vocabulary, resolved the same way
         rdfae:render-overlay does so doc() hits the preloaded pool -->
    <xsl:function name="rdfae:typeahead-terms" as="map(xs:string, xs:string)*">
        <xsl:param name="field" as="xs:string"/>

        <xsl:variable name="kind" as="xs:string" select="rdfae:typeahead-kind($field)"/>
        <xsl:variable name="vocab-uris" as="xs:string*"
            select="$vocab-hrefs ! string(resolve-uri(., ixsl:location()))"/>
        <xsl:for-each select="$vocab-uris">
            <xsl:sequence select="rdfae:vocab-terms(doc(.), $kind)"/>
        </xsl:for-each>
    </xsl:function>

    <!-- the human label for a committed IRI: the vocabulary term's label, else the IRI -->
    <xsl:function name="rdfae:typeahead-label-for" as="xs:string">
        <xsl:param name="field" as="xs:string"/>
        <xsl:param name="iri" as="xs:string"/>

        <xsl:variable name="match" as="map(xs:string, xs:string)?"
            select="(rdfae:typeahead-terms($field)[?uri = $iri])[1]"/>
        <xsl:sequence select="(if (exists($match)) then $match?label else (), $iri)[1]"/>
    </xsl:function>

    <!-- the empty typing-state field, placed by rdfae:render-overlay -->
    <xsl:function name="rdfae:typeahead-field" as="element()">
        <xsl:param name="field" as="xs:string"/>

        <span class="typeahead-field rdfa-editor-ui" data-field="{$field}">
            <input type="text" class="typeahead-input" autocomplete="off"
                placeholder="{rdfae:typeahead-placeholder($field)}"/>
            <ul class="typeahead-menu" role="listbox" style="display: none;"/>
        </span>
    </xsl:function>

    <!-- the committed IRI, else a free-typed absolute IRI, else the untouched
         button->edit value, else nothing -->
    <xsl:function name="rdfae:typeahead-value" as="xs:string?">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="field" as="xs:string"/>

        <xsl:variable name="wrapper" as="element()?" select="($form//span[@data-field = $field])[1]"/>
        <xsl:variable name="hidden" as="element()?" select="$wrapper//input[@type = 'hidden']"/>
        <xsl:choose>
            <xsl:when test="exists($hidden)">
                <xsl:sequence select="string(ixsl:get($hidden, 'value'))[. ne '']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="input" as="element()?"
                    select="$wrapper//input[contains-token(@class, 'typeahead-input')]"/>
                <xsl:variable name="text" as="xs:string"
                    select="normalize-space(string(ixsl:get($input, 'value')))"/>
                <xsl:variable name="editing" as="xs:string" select="string($wrapper/@data-editing-iri)"/>
                <xsl:sequence select="
                    if ($text eq '') then ()
                    else if (rdfae:is-absolute-iri($text)) then $text
                    else if ($editing ne '') then $editing
                    else ()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- reset a field to reflect an IRI (empty -> empty input, non-empty -> button);
         drives form open and edit pre-fill, fully controlling the state (form.reset()
         leaves these custom widgets untouched) -->
    <xsl:template name="rdfae:typeahead-set-value">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="field" as="xs:string"/>
        <xsl:param name="iri" as="xs:string"/>

        <xsl:for-each select="($form//span[@data-field = $field])[1]">
            <ixsl:remove-attribute name="data-editing-iri"/>
            <xsl:choose>
                <xsl:when test="$iri ne ''">
                    <xsl:call-template name="rdfae:typeahead-commit">
                        <xsl:with-param name="wrapper" select="."/>
                        <xsl:with-param name="iri" select="$iri"/>
                        <xsl:with-param name="label" select="rdfae:typeahead-label-for($field, $iri)"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="rdfae:typeahead-to-input">
                        <xsl:with-param name="wrapper" select="."/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- swap the wrapper to the committed button carrying the IRI -->
    <xsl:template name="rdfae:typeahead-commit">
        <xsl:param name="wrapper" as="element()"/>
        <xsl:param name="iri" as="xs:string"/>
        <xsl:param name="label" as="xs:string"/>

        <xsl:variable name="field" as="xs:string" select="string($wrapper/@data-field)"/>
        <xsl:for-each select="$wrapper">
            <ixsl:remove-attribute name="data-editing-iri"/>
            <xsl:result-document href="?." method="ixsl:replace-content">
                <button type="button" class="typeahead-value" title="{$iri}">
                    <span class="typeahead-label"><xsl:value-of select="$label"/></span>
                    <span class="typeahead-clear" role="button" aria-label="Clear">&#215;</span>
                    <input type="hidden" name="{$field}" value="{$iri}"/>
                </button>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- swap the wrapper to the typing state; optionally seed the text, focus the
         input and open the menu (button->edit) -->
    <xsl:template name="rdfae:typeahead-to-input">
        <xsl:param name="wrapper" as="element()"/>
        <xsl:param name="text" as="xs:string" select="''"/>
        <xsl:param name="focus" as="xs:boolean" select="false()"/>
        <xsl:param name="open" as="xs:boolean" select="false()"/>

        <xsl:variable name="field" as="xs:string" select="string($wrapper/@data-field)"/>
        <xsl:for-each select="$wrapper">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <input type="text" class="typeahead-input" autocomplete="off"
                    placeholder="{rdfae:typeahead-placeholder($field)}" value="{$text}"/>
                <ul class="typeahead-menu" role="listbox" style="display: {if ($open) then 'block' else 'none'};">
                    <xsl:if test="$open">
                        <xsl:call-template name="rdfae:typeahead-options">
                            <xsl:with-param name="field" select="$field"/>
                            <xsl:with-param name="query" select="$text"/>
                        </xsl:call-template>
                    </xsl:if>
                </ul>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:if test="$focus">
            <xsl:for-each select="($wrapper//input[contains-token(@class, 'typeahead-input')])[1]">
                <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- render the option <li> list for a query (no result-document of its own: the
         caller places it inside one). Prefix matches rank first, then by label;
         capped so a large vocabulary stays snappy; the first option is pre-selected -->
    <xsl:template name="rdfae:typeahead-options">
        <xsl:param name="field" as="xs:string"/>
        <xsl:param name="query" as="xs:string"/>

        <xsl:variable name="q" as="xs:string" select="lower-case(normalize-space($query))"/>
        <xsl:variable name="matches" as="map(xs:string, xs:string)*" select="rdfae:typeahead-terms($field)
            [$q = '' or contains(lower-case(?label), $q) or contains(lower-case(?uri), $q)]"/>
        <xsl:variable name="ranked" as="map(xs:string, xs:string)*">
            <xsl:perform-sort select="$matches">
                <xsl:sort select="if (starts-with(lower-case(?label), $q)) then 0 else 1"/>
                <xsl:sort select="lower-case(?label)"/>
            </xsl:perform-sort>
        </xsl:variable>
        <xsl:for-each select="$ranked[position() le 50]">
            <xsl:variable name="pos" as="xs:integer" select="position()"/>
            <li class="typeahead-option" role="option" data-uri="{?uri}" data-label="{?label}">
                <xsl:if test="$pos = 1">
                    <xsl:attribute name="aria-selected" select="'true'"/>
                </xsl:if>
                <span class="typeahead-option-label">
                    <xsl:call-template name="rdfae:typeahead-highlight">
                        <xsl:with-param name="text" select="?label"/>
                        <xsl:with-param name="q" select="$q"/>
                    </xsl:call-template>
                </span>
                <span class="typeahead-option-uri"><xsl:value-of select="?uri"/></span>
            </li>
        </xsl:for-each>
    </xsl:template>

    <!-- re-render the menu for the current query and show/hide it -->
    <xsl:template name="rdfae:typeahead-refresh">
        <xsl:param name="wrapper" as="element()"/>
        <xsl:param name="query" as="xs:string"/>

        <xsl:variable name="field" as="xs:string" select="string($wrapper/@data-field)"/>
        <xsl:for-each select="$wrapper//ul[contains-token(@class, 'typeahead-menu')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="rdfae:typeahead-options">
                    <xsl:with-param name="field" select="$field"/>
                    <xsl:with-param name="query" select="$query"/>
                </xsl:call-template>
            </xsl:result-document>
            <ixsl:set-style name="display"
                select="if (exists(./li)) then 'block' else 'none'"/>
        </xsl:for-each>
    </xsl:template>

    <!-- the matched substring in bold (first occurrence, case-insensitive) -->
    <xsl:template name="rdfae:typeahead-highlight">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="q" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$q = '' or not(contains(lower-case($text), $q))">
                <xsl:value-of select="$text"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="i" as="xs:integer"
                    select="string-length(substring-before(lower-case($text), $q))"/>
                <xsl:value-of select="substring($text, 1, $i)"/>
                <strong><xsl:value-of select="substring($text, $i + 1, string-length($q))"/></strong>
                <xsl:value-of select="substring($text, $i + 1 + string-length($q))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ............................ event handlers ............................ -->

    <!-- typing filters the menu and invalidates a stale button->edit selection -->
    <xsl:template match="input[contains-token(@class, 'typeahead-input')]" mode="ixsl:oninput">
        <xsl:variable name="wrapper" as="element()"
            select="ancestor::span[contains-token(@class, 'typeahead-field')][1]"/>
        <ixsl:remove-attribute name="data-editing-iri" object="$wrapper"/>
        <xsl:call-template name="rdfae:typeahead-refresh">
            <xsl:with-param name="wrapper" select="$wrapper"/>
            <xsl:with-param name="query" select="string(ixsl:get(., 'value'))"/>
        </xsl:call-template>
    </xsl:template>

    <!-- the innermost template fires, so this fully owns the input's keys: Escape
         closes the menu (else the overlay, mirroring overlay.xsl's div handler);
         Enter commits a free IRI or the active option; arrows move the selection -->
    <xsl:template match="input[contains-token(@class, 'typeahead-input')]" mode="ixsl:onkeydown">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="key" as="xs:string" select="string(ixsl:get($event, 'key'))"/>
        <xsl:variable name="wrapper" as="element()"
            select="ancestor::span[contains-token(@class, 'typeahead-field')][1]"/>
        <xsl:variable name="field" as="xs:string" select="string($wrapper/@data-field)"/>
        <xsl:variable name="menu" as="element()" select="$wrapper//ul[contains-token(@class, 'typeahead-menu')]"/>
        <xsl:variable name="open" as="xs:boolean" select="string(ixsl:get($menu, 'style.display')) ne 'none'"/>
        <xsl:variable name="items" as="element()*" select="$menu//li[contains-token(@class, 'typeahead-option')]"/>
        <xsl:variable name="current" as="element()?" select="$items[@aria-selected = 'true'][1]"/>
        <xsl:variable name="text" as="xs:string" select="normalize-space(string(ixsl:get(., 'value')))"/>
        <xsl:choose>
            <xsl:when test="$key = 'Escape'">
                <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:choose>
                    <xsl:when test="$open">
                        <ixsl:set-style name="display" select="'none'" object="$menu"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="rdfae:hide-overlay"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$key = 'Enter'">
                <xsl:sequence select="ixsl:call($event, 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:choose>
                    <xsl:when test="rdfae:is-absolute-iri($text)">
                        <xsl:call-template name="rdfae:typeahead-commit">
                            <xsl:with-param name="wrapper" select="$wrapper"/>
                            <xsl:with-param name="iri" select="$text"/>
                            <xsl:with-param name="label" select="rdfae:typeahead-label-for($field, $text)"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="$open and exists($current)">
                        <xsl:call-template name="rdfae:typeahead-commit">
                            <xsl:with-param name="wrapper" select="$wrapper"/>
                            <xsl:with-param name="iri" select="string($current/@data-uri)"/>
                            <xsl:with-param name="label" select="string($current/@data-label)"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <ixsl:set-style name="display" select="'none'" object="$menu"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$key = ('ArrowDown', 'ArrowUp') and $open and exists($items)">
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
                    <xsl:variable name="opts" select="ixsl:call(ixsl:window(), 'Object', [])"/>
                    <ixsl:set-property name="block" select="'nearest'" object="$opts"/>
                    <xsl:sequence select="ixsl:call(., 'scrollIntoView', [ $opts ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

    <!-- focus leaving the field hides the menu; an option's mousedown preventDefault
         keeps focus, so mouse selection commits before this runs -->
    <xsl:template match="input[contains-token(@class, 'typeahead-input')]" mode="ixsl:onfocusout">
        <xsl:for-each select="ancestor::span[contains-token(@class, 'typeahead-field')][1]
                //ul[contains-token(@class, 'typeahead-menu')]">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <!-- mousedown (not click): fires before the input's focusout, so the option is
         still there to read. preventDefault keeps the caret/focus -->
    <xsl:template match="li[contains-token(@class, 'typeahead-option')]" mode="ixsl:onmousedown">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:call-template name="rdfae:typeahead-commit">
            <xsl:with-param name="wrapper" select="ancestor::span[contains-token(@class, 'typeahead-field')][1]"/>
            <xsl:with-param name="iri" select="string(@data-uri)"/>
            <xsl:with-param name="label" select="string(@data-label)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- the committed button: the × clears the field, the body re-opens it for
         editing (prefilled with the label, IRI parked on @data-editing-iri) -->
    <xsl:template match="button[contains-token(@class, 'typeahead-value')]" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="target" select="ixsl:get($event, 'target')"/>
        <xsl:variable name="wrapper" as="element()"
            select="ancestor-or-self::span[contains-token(@class, 'typeahead-field')][1]"/>
        <xsl:variable name="iri" as="xs:string" select="string(@title)"/>
        <xsl:variable name="label" as="xs:string"
            select="string(.//span[contains-token(@class, 'typeahead-label')])"/>
        <xsl:choose>
            <xsl:when test="exists($target/ancestor-or-self::*[contains-token(@class, 'typeahead-clear')])">
                <xsl:call-template name="rdfae:typeahead-to-input">
                    <xsl:with-param name="wrapper" select="$wrapper"/>
                    <xsl:with-param name="focus" select="true()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-attribute name="data-editing-iri" select="$iri" object="$wrapper"/>
                <xsl:call-template name="rdfae:typeahead-to-input">
                    <xsl:with-param name="wrapper" select="$wrapper"/>
                    <xsl:with-param name="text" select="$label"/>
                    <xsl:with-param name="focus" select="true()"/>
                    <xsl:with-param name="open" select="true()"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
