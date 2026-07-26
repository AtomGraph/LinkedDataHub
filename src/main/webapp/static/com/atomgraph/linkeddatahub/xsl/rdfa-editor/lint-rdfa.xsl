<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:rdfa="urn:rdfa:functions"
    xmlns:lint="urn:rdfa-editor:lint"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs map rdfa"
    version="3.0">

<!--
    RDFa lint: flags markup that extracts to something almost certainly unintended.
    Pure XSLT 3.0 - no ixsl: - tested headless via tests/lint-driver.xsl. Reuses the
    extractor's resolution functions (rdfa:resolve-term-or-curie, rdfa:literal-value,
    rdfa:bnode-label, $rdfa:default-prefixes), so lint verdicts and extraction
    semantics cannot drift apart. Not standalone-compilable: include/import it
    alongside RDFa2RDFXML-v3.xsl.

    Checks:
    - term-unresolvable        @property/@typeof/@datatype token that neither resolves
                               as CURIE/term nor is scheme-shaped
    - empty-href               a[@href] with a whitespace-only target
    - content-resource-conflict @property + @content + @resource (RDFa step 11:
                               @content wins, the resource is silently orphaned)
    - empty-literal            @property whose extracted literal value is ''
    - about-relative           @about that is neither '', '#...', '_:...', a CURIE,
                               nor an absolute IRI (the editor emits absolute IRIs)
-->

    <!-- elements the extractor traverses: everything except head/script/style/@data-role subtrees -->
    <xsl:function name="lint:lintable" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:sequence select="$root/descendant-or-self::*[not(ancestor-or-self::head
            | ancestor-or-self::script | ancestor-or-self::style | ancestor-or-self::*[@data-role])]"/>
    </xsl:function>

    <!-- nearest-wins prefix map, mirroring the extractor's top-down merge -->
    <xsl:function name="lint:in-scope-prefixes" as="map(xs:string, xs:string)">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="map:merge(($rdfa:default-prefixes,
            $element/ancestor-or-self::* ! (rdfa:in-scope-namespaces(.), rdfa:parse-prefix-attr(@prefix))),
            map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <!-- nearest @vocab; an empty value resets, mirroring the extractor -->
    <xsl:function name="lint:in-scope-vocab" as="xs:string?">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="$element/ancestor-or-self::*[@vocab][1]/@vocab[. ne ''] ! string(.)"/>
    </xsl:function>

    <!-- deterministic element path, shared with the extractor's bnode labelling -->
    <xsl:function name="lint:path" as="xs:string">
        <xsl:param name="element" as="element()"/>
        <xsl:sequence select="rdfa:bnode-label($element)"/>
    </xsl:function>

    <xsl:function name="lint:element-issues" as="element(lint:issue)*">
        <xsl:param name="element" as="element()"/>

        <xsl:variable name="prefixes" as="map(xs:string, xs:string)" select="lint:in-scope-prefixes($element)"/>
        <xsl:variable name="vocab" as="xs:string?" select="lint:in-scope-vocab($element)"/>

        <!-- term-unresolvable -->
        <xsl:for-each select="$element/(@property, @typeof, @datatype)">
            <xsl:variable name="attribute" as="xs:string" select="name(.)"/>
            <xsl:for-each select="tokenize(.)[empty(rdfa:resolve-term-or-curie(., $prefixes, $vocab))]">
                <lint:issue code="term-unresolvable" path="{lint:path($element)}">@<xsl:value-of
                    select="$attribute"/> term '<xsl:value-of select="."/>' resolves to no IRI (no in-scope vocab or prefix)</lint:issue>
            </xsl:for-each>
        </xsl:for-each>

        <!-- empty-href -->
        <xsl:for-each select="$element[self::a][@href][normalize-space(@href) = '']">
            <lint:issue code="empty-href" path="{lint:path($element)}">link has an empty @href</lint:issue>
        </xsl:for-each>

        <!-- content-resource-conflict -->
        <xsl:for-each select="$element[@property][@content][@resource]">
            <lint:issue code="content-resource-conflict" path="{lint:path($element)}">@content and @resource
                on the same @property element: @content wins, the resource is orphaned</lint:issue>
        </xsl:for-each>

        <!-- empty-literal: the extractor's statement branches, restricted to literal outcomes -->
        <xsl:for-each select="$element[@property][
                (: literal via @content/@datatype (rule 5.2 branch) :)
                ((@content or @datatype) and string((@content, rdfa:literal-value($element))[1]) = '')
                or
                (: plain text literal branch: no IRI object, no typeof chaining :)
                (not(@content) and not(@datatype) and not(@resource) and not(@href) and not(@src)
                    and not(@typeof and not(@about)) and rdfa:literal-value($element) = '')]">
            <lint:issue code="empty-literal" path="{lint:path($element)}">@property '<xsl:value-of
                select="@property"/>' extracts an empty literal</lint:issue>
        </xsl:for-each>

        <!-- unsafe-attribute: event handlers are stripped by canonicalization; flag them early -->
        <xsl:for-each select="$element/@*[matches(local-name(), '^on', 'i')]">
            <lint:issue code="unsafe-attribute" path="{lint:path($element)}">event-handler attribute
                @<xsl:value-of select="name(.)"/> will be stripped from the canonical document</lint:issue>
        </xsl:for-each>

        <!-- unsafe-url: scripting/data schemes in link and media targets -->
        <xsl:for-each select="$element/@href[matches(normalize-space(.), '^(javascript|vbscript|data):', 'i')],
                $element/@src[matches(normalize-space(.), '^(javascript|vbscript):', 'i')],
                $element/@src[matches(normalize-space(.), '^data:', 'i')][not(matches(normalize-space(.), '^data:image/', 'i'))]">
            <lint:issue code="unsafe-url" path="{lint:path($element)}">@<xsl:value-of select="name(.)"/>
                uses an unsafe URL scheme and will be stripped from the canonical document</lint:issue>
        </xsl:for-each>

        <!-- about-relative -->
        <xsl:for-each select="$element/@about[normalize-space(.) ne '']
                [not(starts-with(normalize-space(.), '#'))]
                [not(starts-with(normalize-space(.), '_:'))]
                [not(map:contains($prefixes, substring-before(normalize-space(.), ':')))]
                [not(matches(normalize-space(.), '^[a-zA-Z][a-zA-Z0-9+.-]*:'))]">
            <lint:issue code="about-relative" path="{lint:path($element)}">@about '<xsl:value-of
                select="."/>' is a relative reference - likely a typo for '#...' or an absolute IRI</lint:issue>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>
