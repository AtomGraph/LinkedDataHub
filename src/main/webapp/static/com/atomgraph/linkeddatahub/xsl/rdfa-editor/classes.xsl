<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
exclude-result-prefixes="#all"
version="3.0">

<!--
    The classes the editor's chrome wears, as opposed to the ones it runs on. A host
    with a design system of its own redeclares these and its buttons and helper text
    join the rest of its UI, without forking the templates that emit them.

    Only presentational tokens belong here. Everything else the editor emits is
    load-bearing - rdfa-editor-content, slash-item, typeahead-input, remove-action
    and the rest are what its own ixsl:on* rules match on and its stylesheets select,
    so a host that changed them would break dispatch rather than restyle anything.
    The defaults are what the editor's own CSS styles, so a standalone editor looks
    the same whether or not a host configures anything.
-->

    <xsl:param name="button-primary-class" as="xs:string" select="'btn-primary'"/>

    <xsl:param name="button-secondary-class" as="xs:string" select="'btn-secondary'"/>

    <xsl:param name="button-danger-class" as="xs:string" select="'btn-danger'"/>

    <xsl:param name="helper-text-class" as="xs:string" select="'helper-text'"/>

    <xsl:param name="checkbox-label-class" as="xs:string" select="'checkbox-label'"/>

</xsl:stylesheet>
