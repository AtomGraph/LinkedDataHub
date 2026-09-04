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

<!--
    Object blocks: RDF-defined blocks embedded in content as self-describing
    RDFa placeholders, in two kinds:

    - a DEFINED block - a div whose @typeof matches $object-block-types,
      carrying its defining triples as property spans (LinkedDataHub queries,
      charts, views, ...);
    - a REFERENCE block - an empty div whose @about names a resource OUTSIDE
      this document by an absolute URI. No wrapper node, no rdf:value
      indirection (the v5 ldh:Object idiom is obsolete per the v6 document
      format): naming the resource IS the reference, placement is carried by
      the XHTML structure, and the RDFa extraction of an empty div[@about] is
      zero triples. Blocks defined in the document keep fragment @about values
      (they are document parts); an absolute non-document @about therefore
      unambiguously reads as "dereference and render".

    The editor treats both as atomic islands: never a text host, focusable
    like a block image, a hard boundary for merges and cross-host deletes. The
    visual rendering is injected into an ephemeral div[@data-role='rendering']
    child (canonicalization-stripped, extractor-skipped), so the placeholder
    round-trips byte-identically wherever the content model admits a div.

    The core knows no block vocabulary: $object-block-types is empty and the
    rdfae:render-island mode ships a neutral placeholder card. An extension
    stylesheet (src/ldh-blocks.xsl here; LinkedDataHub's client.xsl in
    production) imports the editor, re-declares the param and overrides the mode
    per @typeof - and for reference blocks by dereferencing the @about URI -
    with real (async) renderers - see the render-hook contract below.
-->

    <!-- island classes: absolute class IRIs matched against tokenize(@typeof).
         Empty in core - re-declared at higher import precedence by an extension
         entry (a same-precedence duplicate would be static error XTSE0630) -->
    <xsl:param name="object-block-types" as="xs:string*" select="()"/>

    <!-- a reference block: an effectively-empty div (ephemeral children and
         whitespace only) whose @about is an absolute URI naming a different
         document than the page. String tests only - no resolve-uri, so a
         malformed @about can never error out of a predicate that runs on every
         gesture; relative/fragment @about values (document parts, or the
         about-relative lint case) are never islands -->
    <xsl:function name="rdfae:reference-block" as="xs:boolean">
        <xsl:param name="element" as="element()?"/>
        <xsl:sequence select="exists($element[self::div]
            [matches(normalize-space(@about), '^[A-Za-z][A-Za-z0-9+.\-]*:')]
            [substring-before(normalize-space(@about) || '#', '#') ne rdfae:document-uri()]
            [empty((node() except *[@data-role])[not(self::text()[not(normalize-space())])])])"/>
    </xsl:function>

    <!-- THE island predicate: every island decision (init, navigation, merge
         boundaries, the delete machine, undo re-render) routes through here -->
    <xsl:function name="rdfae:island" as="xs:boolean">
        <xsl:param name="element" as="element()?"/>
        <xsl:sequence select="exists($element[self::div][tokenize(@typeof) = $object-block-types])
            or rdfae:reference-block($element)"/>
    </xsl:function>

    <!-- the render hook. Context item = the island div. Contract: inject exactly
         one div[@data-role='rendering'] as the island's last child via
         rdfae:replace-rendering - async renderers only in the completion callback
         (loading state = the ephemeral rdfa-editor-loading class), so an island
         without a rendering div always reads as "render needed" (the undo-restore
         re-render pass keys on that); never touch the RDFa spans; never push undo
         (rendering is ephemeral by construction); idempotent (replace, not append) -->
    <xsl:mode name="rdfae:render-island" on-no-match="deep-skip"/>

    <!-- neutral default: a static card naming the block's type (a reference
         block has none - it reads as 'Resource') and resource. Extension
         templates matching per @typeof / reference win on import precedence -->
    <xsl:template match="*" mode="rdfae:render-island">
        <xsl:variable name="type" as="xs:string?"
            select="(tokenize(@typeof)[. = $object-block-types], tokenize(@typeof), 'Resource')[1]"/>
        <xsl:call-template name="rdfae:replace-rendering">
            <xsl:with-param name="island" select="."/>
            <xsl:with-param name="content">
                <div class="rdfa-editor-island-card">
                    <strong><xsl:value-of select="replace($type, '^.*[#/]', '')"/></strong>
                    <xsl:for-each select="(@resource, @about)[1]">
                        <xsl:text> </xsl:text>
                        <code><xsl:value-of select="."/></code>
                    </xsl:for-each>
                </div>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- idempotent rendering-container swap: the only writer of the rendering div -->
    <xsl:template name="rdfae:replace-rendering">
        <xsl:param name="island" as="element()"/>
        <xsl:param name="content" as="node()*"/>
        <xsl:variable name="rendering" as="element()">
            <div data-role="rendering">
                <xsl:copy-of select="$content"/>
            </div>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$island/*[@data-role = 'rendering']">
                <xsl:for-each select="($island/*[@data-role = 'rendering'])[1]">
                    <xsl:result-document href="?." method="ixsl:replace-element">
                        <xsl:copy-of select="$rendering"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$island">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <xsl:copy-of select="$rendering"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ............................ extension hooks ............................ -->

    <!-- no-op extension points, overridden at higher import precedence: dialogs
         appended to body at init, toolbar Insert-group buttons, slash-menu items,
         and slash-command dispatch for those items -->
    <xsl:template name="rdfae:render-extra-dialogs"/>

    <xsl:template name="rdfae:render-extra-insert-buttons"/>

    <xsl:template name="rdfae:render-extra-slash-items"/>

    <xsl:template name="rdfae:run-extra-slash-command">
        <xsl:param name="command" as="xs:string"/>
        <xsl:param name="host" as="element()?"/>
    </xsl:template>

</xsl:stylesheet>
