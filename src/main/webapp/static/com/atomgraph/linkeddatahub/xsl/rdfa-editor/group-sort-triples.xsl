<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2012 Martynas Jusevičius <martynas@atomgraph.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
<xsl:stylesheet
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:local="urn:rdfa-editor:functions"
exclude-result-prefixes="xsl xs local"
version="3.0">

    <!--
        Groups striped RDF/XML (one rdf:Description per triple, as the extractor in
        RDFa2RDFXML-v3.xsl emits) into one rdf:Description per subject, with the
        properties sorted - easing per-entity rendering (the inspector pane in
        navigate.xsl). Adapted to a pure function from AtomGraph Web-Client's
        group-sort-triples.xsl (ac:GroupTriples mode): no top-level xsl:output or
        xsl:strip-space here, since this module is xsl:included into the editor
        stylesheet and must not impose global serialization or whitespace handling.
    -->
    <xsl:function name="local:group-triples" as="element(rdf:RDF)">
        <xsl:param name="rdf" as="element(rdf:RDF)"/>

        <rdf:RDF>
            <!-- one rdf:Description per subject; URI resources first ('0 '), then blank nodes ('1 ') -->
            <xsl:for-each-group select="$rdf/rdf:Description[@rdf:about or @rdf:nodeID]"
                    group-by="if (@rdf:about) then '0 ' || @rdf:about else '1 ' || @rdf:nodeID">
                <xsl:sort select="current-grouping-key()" data-type="text" order="ascending"/>
                <rdf:Description>
                    <xsl:copy-of select="(@rdf:about, @rdf:nodeID)[1]"/>
                    <xsl:perform-sort select="current-group()/*">
                        <xsl:sort select="namespace-uri() || local-name()" data-type="text" order="ascending"/>
                        <xsl:sort select="@rdf:resource" data-type="text" order="ascending"/>
                        <xsl:sort select="@rdf:nodeID" data-type="text" order="ascending"/>
                        <xsl:sort select="@rdf:datatype" data-type="text" order="ascending"/>
                        <xsl:sort select="@xml:lang" data-type="text" order="ascending"/>
                        <xsl:sort select="." data-type="text" order="ascending"/>
                    </xsl:perform-sort>
                </rdf:Description>
            </xsl:for-each-group>
        </rdf:RDF>
    </xsl:function>

</xsl:stylesheet>
