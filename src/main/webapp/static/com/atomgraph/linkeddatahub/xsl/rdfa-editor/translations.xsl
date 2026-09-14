<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
exclude-result-prefixes="#all"
version="3.0">

<!--
    Every user-visible string the editor emits comes from here, so the chrome can be
    translated without touching the templates that render it. The catalog is plain
    RDF/XML - rdf:Description carrying rdfs:label per language, keyed by rdf:nodeID -
    which is the same shape a host is likely to keep its own strings in.

    A host translates the editor by overriding rdfae:translations() to return its own
    catalog (import precedence decides), or by pointing $translations-href at another
    document. Overriding rdfae:label() as well replaces the language selection, for a
    host that resolves it from something richer than a parameter.
-->

    <!-- the string catalog. A relative href resolves against the page URI and the host
         page must preload it into the SaxonJS document pool, exactly as $vocab-hrefs does -->
    <xsl:param name="translations-href" as="xs:string" select="'translations.rdf'"/>

    <!-- the reader's languages as the browser reports them, reduced to primary subtags so a catalog
         tagged es-ES answers a browser asking for es-419, deduplicated because es-ES,es yields the same
         subtag twice, and floored at 'en' when the reader expressed no preference. Two declarations:
         navigator exists only in the browser, and the editor also compiles under Saxon for its headless
         tests, where there is no reader to ask -->

    <xsl:function name="rdfae:langs" as="xs:string*" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:variable name="langs" as="xs:string*" select="distinct-values(for $lang in ixsl:get(ixsl:window(), 'navigator.languages') return tokenize($lang, '-')[1])[not(. = ('', '*'))]"/>

        <xsl:sequence select="if (exists($langs)) then $langs else 'en'"/>
    </xsl:function>

    <xsl:function name="rdfae:langs" as="xs:string*" use-when="not(system-property('xsl:product-name') = 'SaxonJS')">
        <xsl:sequence select="'en'"/>
    </xsl:function>

    <!-- the language labels are selected in, defaulting to the reader's own. A host that resolves it
         from something else - a negotiated Accept-Language, a profile setting - redeclares this -->
    <xsl:param name="translations-lang" as="xs:string" select="rdfae:langs()[1]"/>

    <!-- keyed by rdf:nodeID, the catalog's own identifiers; also matches rdf:about so a
         host catalog that names its terms with IRIs resolves through the same lookup -->
    <xsl:key name="resources" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>

    <!-- one declaration for both products: a relative href resolves against the stylesheet,
         which is src/ under Saxon and - because the SEF is compiled with -relocate:on - the
         SEF's load location under SaxonJS, where generate-sef.sh puts a copy. A host page
         must still preload it into the document pool under that same URI, as it does the
         vocabularies -->

    <xsl:function name="rdfae:translations" as="document-node()">
        <xsl:sequence select="document($translations-href)"/>
    </xsl:function>

    <!-- the label for a catalog key: the exact language, else any variant of it (es-ES
         answering es), else whatever the catalog holds, else the key itself - an untranslated
         string is a visible key rather than an empty control -->
    <xsl:function name="rdfae:label" as="xs:string">
        <xsl:param name="key" as="xs:string"/>

        <xsl:variable name="labels" as="element()*" select="key('resources', $key, rdfae:translations())/rdfs:label"/>
        <xsl:sequence select="string(($labels[@xml:lang = $translations-lang], $labels[starts-with(@xml:lang, substring($translations-lang, 1, 2))], $labels, $key)[1])"/>
    </xsl:function>

</xsl:stylesheet>
