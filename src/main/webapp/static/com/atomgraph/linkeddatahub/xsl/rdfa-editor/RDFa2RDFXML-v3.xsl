<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfax="https://w3id.org/atomgraph/rdfa-editor/rdfa#"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs map rdfax"
    version="3.0">

<!--
    RDFa 1.1 (Lite) to RDF/XML extraction. Pure XSLT 3.0 - no ixsl: dependencies,
    so it runs headless via xslt3 for testing (see tests/run-tests.sh).

    Supported: @about, @typeof, @property, @content, @datatype, @resource, @href,
    @src, @prefix (and xmlns:*), @vocab with bare-term resolution, @lang/@xml:lang
    inheritance, base-URI resolution (about="" = the document).

    Semantics follow the RDFa 1.1 processing rules strictly - no profile deviations.
    Note for LinkedDataHub v6 alignment: the conformant containment idiom is
    <article property="https://schema.org/hasPart" resource="#part" typeof="...">
    (object chaining via @resource); @about + @property without @content/@resource
    is, per spec, a text literal on the @about subject.

    Subtrees carrying any @data-role (LDH v6 convention: hydrated 'rendering' output,
    injected editor 'chrome') plus head, script and style are excluded - both from
    traversal and from literal values.

    Future work (out of scope): @rel/@rev, @inlist, safe CURIEs, @datetime/<time>,
    xml:base.
-->

    <xsl:mode name="rdfax:extract" on-no-match="deep-skip"/>

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <!-- overrides base-uri($doc): required when the input's static base URI is meaningless (CLI fixtures) -->
    <xsl:param name="base-uri" as="xs:string?" select="()"/>

    <!-- RDFa 1.1 initial context (subset) -->
    <xsl:variable name="rdfax:default-prefixes" as="map(xs:string, xs:string)" select="map{
        'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        'rdfs': 'http://www.w3.org/2000/01/rdf-schema#',
        'xsd': 'http://www.w3.org/2001/XMLSchema#',
        'schema': 'http://schema.org/',
        'foaf': 'http://xmlns.com/foaf/0.1/',
        'dc': 'http://purl.org/dc/terms/',
        'dct': 'http://purl.org/dc/terms/'
    }"/>

    <!-- named entry only — an unnamed-mode match="/" here would intercept every default-mode dispatch against a document node in the host stylesheet (see be7c4ebc8 for the normalize-rdfxml instance of the same bug) -->
    <xsl:template name="rdfax:extract-rdfa">
        <xsl:param name="doc" as="document-node()" select="."/>
        <xsl:param name="base" as="xs:string" select="($base-uri, string(base-uri($doc)))[1]"/>
        <xsl:variable name="effective-base" as="xs:string"
            select="if ($doc//base/@href) then string(resolve-uri(($doc//base/@href)[1], $base)) else $base"/>

        <rdf:RDF>
            <xsl:apply-templates select="$doc/*" mode="rdfax:extract">
                <!-- RDFa initializes the parent object to the base URI -->
                <xsl:with-param name="subject" select="$effective-base"/>
                <xsl:with-param name="base" select="$effective-base" tunnel="yes"/>
            </xsl:apply-templates>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="head | script | style | *[@data-role]" mode="rdfax:extract"/>

    <xsl:template match="*" mode="rdfax:extract">
        <xsl:param name="subject" as="xs:string?" select="()"/>
        <xsl:param name="prefixes" as="map(xs:string, xs:string)" select="$rdfax:default-prefixes"/>
        <xsl:param name="vocab" as="xs:string?" select="()"/>
        <xsl:param name="lang" as="xs:string?" select="()"/>
        <xsl:param name="base" as="xs:string" tunnel="yes"/>

        <!-- evaluation context updates. Empty @vocab/@lang reset; @xml:lang wins over @lang -->
        <xsl:variable name="prefixes" as="map(xs:string, xs:string)"
            select="map:merge(($prefixes, rdfax:in-scope-namespaces(.), rdfax:parse-prefix-attr(@prefix)), map{ 'duplicates': 'use-last' })"/>
        <xsl:variable name="vocab" as="xs:string?"
            select="if (exists(@vocab)) then @vocab[. ne ''] else $vocab"/>
        <xsl:variable name="lang" as="xs:string?"
            select="if (exists((@xml:lang, @lang))) then string((@xml:lang, @lang)[1])[. ne ''] else $lang"/>

        <xsl:variable name="new-subject" as="xs:string?" select="rdfax:new-subject(., $prefixes, $base)"/>

        <!-- section 7.5 step 2: @vocab asserts (base, rdfa:usesVocabulary, vocab IRI) -->
        <xsl:for-each select="@vocab[. ne '']">
            <rdf:Description rdf:about="{$base}">
                <xsl:element name="usesVocabulary" namespace="http://www.w3.org/ns/rdfa#">
                    <xsl:attribute name="rdf:resource" select="resolve-uri(., $base)"/>
                </xsl:element>
            </rdf:Description>
        </xsl:for-each>

        <!-- @typeof: one rdf:type triple per token; the typed node is the new subject -->
        <xsl:for-each select="@typeof ! tokenize(.) ! rdfax:resolve-term-or-curie(., $prefixes, $vocab)">
            <rdf:Description>
                <xsl:sequence select="rdfax:subject-attribute($new-subject)"/>
                <rdf:type rdf:resource="{.}"/>
            </rdf:Description>
        </xsl:for-each>

        <!-- @property: determine subject/object once, emit one triple per token -->
        <xsl:variable name="statement" as="map(*)?">
            <xsl:choose>
                <xsl:when test="not(@property)"/>
                <!-- literal object: @content overrides text content; @datatype forces a literal reading.
                     Subject establishment follows rule 5.2, so @resource/@href/@src set it (via new-subject) -->
                <xsl:when test="@content or @datatype">
                    <xsl:sequence select="map{
                        'subject': ($new-subject, $subject)[1],
                        'literal': string((@content, rdfax:literal-value(.))[1]),
                        'datatype': @datatype ! rdfax:resolve-term-or-curie(., $prefixes, $vocab),
                        'lang': $lang
                    }"/>
                </xsl:when>
                <!-- IRI object from @resource/@href/@src (rule 5.1 + step 11) -->
                <xsl:when test="@resource or @href or @src">
                    <xsl:sequence select="map{
                        'subject': (@about ! $new-subject, $subject)[1],
                        'object': rdfax:resolve-iri((@resource, @href, @src)[1], $prefixes, $base)
                    }"/>
                </xsl:when>
                <!-- @typeof without @about: the typed node becomes the object (RDFa 1.1 chaining) -->
                <xsl:when test="@typeof and not(@about)">
                    <xsl:sequence select="map{ 'subject': $subject, 'object': $new-subject }"/>
                </xsl:when>
                <!-- plain literal from text content -->
                <xsl:otherwise>
                    <xsl:sequence select="map{
                        'subject': (@about ! $new-subject, $subject)[1],
                        'literal': rdfax:literal-value(.),
                        'lang': $lang
                    }"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="exists($statement) and exists($statement?subject)">
            <xsl:for-each select="tokenize(@property) ! rdfax:resolve-term-or-curie(., $prefixes, $vocab)">
                <xsl:variable name="property-parts" as="map(xs:string, xs:string)" select="rdfax:split-uri(.)"/>
                <xsl:choose>
                    <xsl:when test="matches($property-parts?local, '^[\i-[:]][\c-[:]]*$') and $property-parts?namespace ne ''">
                        <rdf:Description>
                            <xsl:sequence select="rdfax:subject-attribute($statement?subject)"/>
                            <xsl:element name="{rdfax:prefixed-name($property-parts, $prefixes)}" namespace="{$property-parts?namespace}">
                                <xsl:choose>
                                    <xsl:when test="exists($statement?object)">
                                        <xsl:sequence select="rdfax:object-attribute($statement?object)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:choose>
                                            <xsl:when test="exists($statement?datatype)">
                                                <xsl:attribute name="rdf:datatype" select="$statement?datatype"/>
                                            </xsl:when>
                                            <xsl:when test="exists($statement?lang)">
                                                <xsl:attribute name="xml:lang" select="$statement?lang"/>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:value-of select="$statement?literal"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                        </rdf:Description>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message select="'[RDFa] Skipping property IRI not splittable into namespace/local name: ' || ."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>

        <!-- descendants inherit the current object resource - set only by a typed resource
             (@typeof without @about, rule 5.1) - else the new subject, else the current one -->
        <xsl:variable name="chains" as="xs:boolean"
            select="exists(@property) and not(@content) and not(@datatype) and exists(@typeof) and not(@about)"/>
        <xsl:apply-templates select="*" mode="rdfax:extract">
            <xsl:with-param name="subject" select="if ($chains) then $statement?object else ($new-subject, $subject)[1]"/>
            <xsl:with-param name="prefixes" select="$prefixes"/>
            <xsl:with-param name="vocab" select="$vocab"/>
            <xsl:with-param name="lang" select="$lang"/>
        </xsl:apply-templates>
    </xsl:template>

    <!--
        New subject / typed resource of an element per RDFa 1.1 section 7.5:
        @about always wins; under rule 5.2 (no @property, or @content/@datatype
        present) @resource/@href/@src establish the subject; @typeof mints a node
        identified by @resource/@href/@src or a fresh blank node; else none (inherit).
    -->
    <xsl:function name="rdfax:new-subject" as="xs:string?">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="prefixes" as="map(xs:string, xs:string)"/>
        <xsl:param name="base" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$element/@about">
                <xsl:sequence select="rdfax:resolve-iri($element/@about, $prefixes, $base)"/>
            </xsl:when>
            <xsl:when test="$element/(@resource, @href, @src)
                    and (not($element/@property) or $element/@content or $element/@datatype)">
                <xsl:sequence select="rdfax:resolve-iri(($element/@resource, $element/@href, $element/@src)[1], $prefixes, $base)"/>
            </xsl:when>
            <xsl:when test="$element/@typeof">
                <xsl:sequence select="if ($element/(@resource, @href, @src))
                    then rdfax:resolve-iri(($element/@resource, $element/@href, $element/@src)[1], $prefixes, $base)
                    else '_:' || rdfax:bnode-label($element)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- the subject in scope at an element, for UI display: fold new-subject over the ancestor axis -->
    <xsl:function name="rdfax:in-scope-subject" as="xs:string?">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="base" as="xs:string"/>

        <xsl:sequence select="fold-left($element/ancestor-or-self::*, $base,
            function($subject, $e) { (rdfax:new-subject($e, $rdfax:default-prefixes, $base), $subject)[1] })"/>
    </xsl:function>

    <!-- IRI attribute values (@about/@resource/@href/@src): blank node, CURIE, or (relative) IRI -->
    <xsl:function name="rdfax:resolve-iri" as="xs:string">
        <xsl:param name="value" as="xs:string"/>
        <xsl:param name="prefixes" as="map(xs:string, xs:string)"/>
        <xsl:param name="base" as="xs:string"/>

        <xsl:variable name="value" as="xs:string" select="normalize-space($value)"/>
        <xsl:choose>
            <xsl:when test="starts-with($value, '_:')">
                <xsl:sequence select="$value"/>
            </xsl:when>
            <xsl:when test="map:contains($prefixes, substring-before($value, ':')) and not(starts-with(substring-after($value, ':'), '//'))">
                <xsl:sequence select="$prefixes(substring-before($value, ':')) || substring-after($value, ':')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="string(resolve-uri($value, $base))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- @property/@typeof/@datatype values: absolute IRI, CURIE, or bare term against @vocab -->
    <xsl:function name="rdfax:resolve-term-or-curie" as="xs:string?">
        <xsl:param name="value" as="xs:string"/>
        <xsl:param name="prefixes" as="map(xs:string, xs:string)"/>
        <xsl:param name="vocab" as="xs:string?"/>

        <xsl:variable name="value" as="xs:string" select="normalize-space($value)"/>
        <xsl:choose>
            <xsl:when test="map:contains($prefixes, substring-before($value, ':')) and not(starts-with(substring-after($value, ':'), '//'))">
                <xsl:sequence select="$prefixes(substring-before($value, ':')) || substring-after($value, ':')"/>
            </xsl:when>
            <xsl:when test="matches($value, '^[a-zA-Z][a-zA-Z0-9+.-]*:')">
                <xsl:sequence select="$value"/>
            </xsl:when>
            <xsl:when test="exists($vocab) and matches($value, '^[\i-[:]][\c-[:]]*$')">
                <xsl:sequence select="$vocab || $value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'[RDFa] Dropping unresolvable term ''' || $value || ''' (no in-scope vocab or prefix)'"/>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- @prefix attribute: 'prefix: IRI prefix: IRI ...' -->
    <xsl:function name="rdfax:parse-prefix-attr" as="map(xs:string, xs:string)">
        <xsl:param name="attr" as="xs:string?"/>

        <xsl:variable name="entries" as="map(xs:string, xs:string)*">
            <xsl:analyze-string select="string($attr)" regex="([^\s:]+):\s+(\S+)">
                <xsl:matching-substring>
                    <xsl:sequence select="map{ regex-group(1): regex-group(2) }"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="map:merge($entries, map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <!-- legacy xmlns:* declarations, via the namespace axis (XDM) and attribute names (HTML DOM) -->
    <xsl:function name="rdfax:in-scope-namespaces" as="map(xs:string, xs:string)">
        <xsl:param name="element" as="element()"/>

        <xsl:variable name="entries" as="map(xs:string, xs:string)*" select="
            in-scope-prefixes($element)[not(. = ('', 'xml'))] ! map{ . : string(namespace-uri-for-prefix(., $element)) },
            $element/@*[starts-with(name(), 'xmlns:')] ! map{ substring-after(name(), 'xmlns:'): string(.) }"/>
        <xsl:sequence select="map:merge($entries, map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <!-- literal value of an element: its text content minus rendering/script/style subtrees -->
    <xsl:function name="rdfax:literal-value" as="xs:string">
        <xsl:param name="element" as="element()"/>

        <xsl:sequence select="normalize-space(string-join(
            $element//text()[not(ancestor::*[@data-role] | ancestor::script | ancestor::style)]))"/>
    </xsl:function>

    <!-- stable across processors and runs, unlike generate-id(): position path of the element -->
    <xsl:function name="rdfax:bnode-label" as="xs:string">
        <xsl:param name="element" as="element()"/>

        <xsl:sequence select="'b' || string-join($element/ancestor-or-self::* ! string(count(preceding-sibling::*) + 1), '.')"/>
    </xsl:function>

    <xsl:function name="rdfax:subject-attribute" as="attribute()">
        <xsl:param name="subject" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="starts-with($subject, '_:')">
                <xsl:attribute name="rdf:nodeID" select="substring-after($subject, '_:')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="rdf:about" select="$subject"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="rdfax:object-attribute" as="attribute()">
        <xsl:param name="object" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="starts-with($object, '_:')">
                <xsl:attribute name="rdf:nodeID" select="substring-after($object, '_:')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="rdf:resource" select="$object"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- namespace/local split on the last '#' or '/' for RDF/XML property element names -->
    <xsl:function name="rdfax:split-uri" as="map(xs:string, xs:string)">
        <xsl:param name="uri" as="xs:string"/>

        <xsl:variable name="namespace" as="xs:string"
            select="(replace($uri, '^(.*[#/])[^#/]*$', '$1')[. ne $uri], '')[1]"/>
        <xsl:sequence select="map{
            'namespace': $namespace,
            'local': substring($uri, string-length($namespace) + 1)
        }"/>
    </xsl:function>

    <!-- prefer a declared prefix for readable RDF/XML output -->
    <xsl:function name="rdfax:prefixed-name" as="xs:string">
        <xsl:param name="parts" as="map(xs:string, xs:string)"/>
        <xsl:param name="prefixes" as="map(xs:string, xs:string)"/>

        <xsl:variable name="prefix" as="xs:string?"
            select="map:for-each($prefixes, function($prefix, $namespace) { $prefix[$namespace eq $parts?namespace] })[1]"/>
        <xsl:sequence select="if (exists($prefix)) then $prefix || ':' || $parts?local else $parts?local"/>
    </xsl:function>

</xsl:stylesheet>
