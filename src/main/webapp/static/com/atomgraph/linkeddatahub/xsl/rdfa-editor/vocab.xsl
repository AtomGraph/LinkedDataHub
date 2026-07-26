<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
xmlns:owl="http://www.w3.org/2002/07/owl#"
xmlns:dc11="http://purl.org/dc/elements/1.1/"
xmlns:dct="http://purl.org/dc/terms/"
xmlns:local="urn:rdfa-editor:functions"
exclude-result-prefixes="#all"
version="3.0">

<!--
    Generic ontology RDF/XML consumption: populates the type and property dropdowns
    from plain vocabulary documents (FOAF, DCMI terms, ...) - no custom manifest format.

    Handles both common RDF/XML shapes: typed elements (<owl:Class rdf:about="...">)
    and rdf:Description with rdf:type children (possibly striped one-triple-per-
    description, as in the DCMI terms file); labels as attributes or child elements.
-->

    <!-- ontology documents (RDF/XML) feeding the type and property dropdowns.
         Relative hrefs resolve against the page URI; the host page preloads them
         into the SaxonJS document pool (must match its list) -->
    <xsl:param name="vocab-hrefs" as="xs:string*" select="('vocabs/foaf.rdf', 'vocabs/dcterms.rdf')"/>

    <xsl:variable name="local:class-types" as="xs:string*" select="(
        'http://www.w3.org/2000/01/rdf-schema#Class',
        'http://www.w3.org/2002/07/owl#Class'
    )"/>

    <xsl:variable name="local:property-types" as="xs:string*" select="(
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property',
        'http://www.w3.org/2002/07/owl#ObjectProperty',
        'http://www.w3.org/2002/07/owl#DatatypeProperty',
        'http://www.w3.org/2002/07/owl#AnnotationProperty'
    )"/>

    <!-- the ontology's own URI: owl:Ontology description, else the first rdfs:isDefinedBy target -->
    <xsl:function name="local:ontology-uri" as="xs:string?">
        <xsl:param name="vocab" as="document-node()"/>

        <xsl:sequence select="(
            $vocab/rdf:RDF/owl:Ontology/@rdf:about,
            $vocab/rdf:RDF/*[rdf:type/@rdf:resource = 'http://www.w3.org/2002/07/owl#Ontology']/@rdf:about,
            $vocab/rdf:RDF/*/rdfs:isDefinedBy/@rdf:resource
        )[1] ! string(.)"/>
    </xsl:function>

    <!--
        Terms of the requested kind ('class' | 'property') as maps with 'uri' and 'label'.
        Descriptions are grouped by @rdf:about so striped vocabularies work; terms outside
        the ontology namespace (e.g. FOAF's OWL-interop declarations) are dropped.
    -->
    <xsl:function name="local:vocab-terms" as="map(xs:string, xs:string)*">
        <xsl:param name="vocab" as="document-node()"/>
        <xsl:param name="kind" as="xs:string"/>

        <xsl:variable name="type-uris" as="xs:string*"
            select="if ($kind = 'class') then $local:class-types else $local:property-types"/>
        <xsl:variable name="ontology-uri" as="xs:string?" select="local:ontology-uri($vocab)"/>
        <xsl:for-each-group select="$vocab/rdf:RDF/*[@rdf:about]" group-by="@rdf:about">
            <xsl:if test="(current-group()/rdf:type/@rdf:resource, current-group() ! (namespace-uri() || local-name())) = $type-uris
                    and (empty($ontology-uri) or starts-with(current-grouping-key(), $ontology-uri))">
                <xsl:sequence select="map{
                    'uri': string(current-grouping-key()),
                    'label': (current-group()/@rdfs:label, current-group()/rdfs:label,
                        replace(current-grouping-key(), '^.*[#/]', ''))[1] ! string(.)
                }"/>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:function>

    <!-- local:vocab-terms feeds the property and type typeaheads (typeahead.xsl) -->

</xsl:stylesheet>
