<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
    exclude-result-prefixes="#all"
    version="3.0">

    <!-- Identity template for ldh:MergeRDF mode -->
    <xsl:template match="@* | node()" mode="ldh:MergeRDF">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Merge new RDF descriptions into existing rdf:RDF element -->
    <xsl:template match="rdf:RDF" mode="ldh:MergeRDF">
        <xsl:param name="new-rdf" as="document-node()" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:variable name="existing-rdf" select="root()" as="document-node()"/>
            <!-- Add new descriptions (URI-identified or blank nodes) that don't exist in the existing document -->
            <!-- Blank node IDs are prefixed per-document during normalization, so no conflicts -->
            <xsl:for-each select="$new-rdf/rdf:RDF/*[@rdf:about or @rdf:nodeID]">
                <xsl:variable name="id" select="(@rdf:about, @rdf:nodeID)[1]" as="xs:string"/>
                <xsl:if test="not(key('resources', $id, $existing-rdf))">
                    <xsl:apply-templates select="." mode="#current"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <!-- Merge new properties into existing URI-identified rdf:Description -->
    <xsl:template match="rdf:Description[@rdf:about]" mode="ldh:MergeRDF">
        <xsl:param name="new-rdf" as="document-node()" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>

            <xsl:variable name="resource-uri" select="@rdf:about" as="xs:anyURI"/>
            <!-- the group key is the RDF triple's object, so it carries @xml:lang and @rdf:datatype: "Concept" and "Concept"@en are
                 distinct RDF terms, and keying on the lexical form alone collapsed them and kept whichever came first. Ontology terms
                 routinely carry both an untagged label from the vocabulary (dh.ttl: rdfs:label "Item") and tagged ones from the app
                 ontology, so the tagged label lost - dropping the only value a language the reader accepts could match.
                 The object value is bounded via ldh:bounded-key(): xsl:for-each-group hashes the key through SaxonJS's
                 per-character trie recursion, which oversized literal values (e.g. XHTML content blocks) overflow -->
            <xsl:for-each-group select="* | key('resources', $resource-uri, $new-rdf)/*"
                group-by="concat(node-name(.), '|', ldh:bounded-key((@rdf:resource, @rdf:nodeID, string(.))[1]), '|', @xml:lang, '|', @rdf:datatype)">
                <xsl:apply-templates select="current-group()[1]" mode="#current"/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

    <!-- Merge two RDF/XML documents into one via the ldh:MergeRDF mode. Guards an absent/failed side (e.g. a non-2xx metadata response) with an empty rdf:RDF so the merge still runs. -->
    <xsl:function name="ldh:merge-metadata" as="document-node()">
        <xsl:param name="base" as="document-node()?"/>
        <xsl:param name="new-rdf" as="document-node()?"/>

        <xsl:variable name="empty-rdf" as="document-node()">
            <xsl:document>
                <rdf:RDF/>
            </xsl:document>
        </xsl:variable>

        <xsl:document>
            <xsl:apply-templates select="($base[rdf:RDF], $empty-rdf)[1]" mode="ldh:MergeRDF">
                <xsl:with-param name="new-rdf" select="($new-rdf[rdf:RDF], $empty-rdf)[1]" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:function>

</xsl:stylesheet>
