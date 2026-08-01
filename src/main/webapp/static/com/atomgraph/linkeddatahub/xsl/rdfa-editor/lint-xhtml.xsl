<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cm="https://w3id.org/atomgraph/rdfa-editor/content-model#"
    xmlns:lint="https://w3id.org/atomgraph/rdfa-editor/lint#"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs cm"
    version="3.0">

<!--
    XHTML nesting lint: flags markup the content model disallows. Pure XSLT 3.0 -
    no ixsl: - tested headless via tests/lint-driver.xsl. Consults content-model.xsl
    (cm:*) - the same single source of truth the boundary normalization
    (canonical-xhtml.xsl) applies - so lint verdicts and normalization behavior
    cannot drift apart. Paths come from lint:path (lint-rdfa.xsl). Not standalone-
    compilable: include/import alongside content-model.xsl and lint-rdfa.xsl.

    Checks:
    - invalid-nesting     a known element not allowed as a child of its known parent
                          (e.g. blocks inside p, non-li children of ul)
    - stray-text          non-whitespace text directly inside an element-only
                          container (e.g. bare text in blockquote or ul)
    - prohibited-nesting  XHTML 1.0 Appendix B prohibitions (a in a, img in pre, ...)
    - unknown-element     an element outside the XHTML Strict (+figure) content
                          model - preserved, but unvalidated
-->

    <xsl:function name="lint:nesting-issues" as="element(lint:issue)*">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="name" as="xs:string" select="local-name($element)"/>

        <!-- unknown-element -->
        <xsl:for-each select="$element[not(cm:known($name))]">
            <lint:issue code="unknown-element" path="{lint:path($element)}">element '<xsl:value-of
                select="$name"/>' is outside the XHTML content model - preserved, but its nesting is unvalidated</lint:issue>
        </xsl:for-each>

        <!-- invalid-nesting -->
        <xsl:for-each select="$element[cm:known($name)]/parent::*[cm:known(local-name(.))]
                [not(cm:allows-child(local-name(.), $name))]">
            <lint:issue code="invalid-nesting" path="{lint:path($element)}">'<xsl:value-of
                select="$name"/>' is not allowed inside '<xsl:value-of select="local-name(.)"/>'</lint:issue>
        </xsl:for-each>

        <!-- stray-text -->
        <xsl:for-each select="$element[cm:structural($name)][text()[normalize-space()]]">
            <lint:issue code="stray-text" path="{lint:path($element)}">'<xsl:value-of
                select="$name"/>' allows no text content - stray text will be wrapped by canonicalization</lint:issue>
        </xsl:for-each>

        <!-- prohibited-nesting -->
        <xsl:for-each select="$element/ancestor::*[local-name() = cm:prohibited-ancestors($name)][1]">
            <lint:issue code="prohibited-nesting" path="{lint:path($element)}">'<xsl:value-of
                select="$name"/>' must not appear inside '<xsl:value-of
                select="local-name(.)"/>' (XHTML 1.0 Appendix B)</lint:issue>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>
