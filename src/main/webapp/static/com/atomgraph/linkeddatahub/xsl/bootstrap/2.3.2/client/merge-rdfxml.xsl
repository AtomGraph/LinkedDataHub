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
            <xsl:for-each-group select="* | key('resources', $resource-uri, $new-rdf)/*"
                group-by="concat(node-name(.), '|', (@rdf:resource, @rdf:nodeID, string(.))[1])">
                <xsl:apply-templates select="current-group()[1]" mode="#current"/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
