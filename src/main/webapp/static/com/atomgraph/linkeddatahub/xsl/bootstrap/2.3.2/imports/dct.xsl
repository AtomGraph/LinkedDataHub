<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ldt="&ldt;"
xmlns:foaf="&foaf;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

<!--    <xsl:template match="dct:title" mode="ac:JSON-LDContext" priority="1">
        <xsl:sequence select="concat('&quot;', local-name(), '&quot; : { &quot;@id&quot;: &quot;', 'http://schema.org/name', '&quot; }')"/>
    </xsl:template>
    
    <xsl:template match="dct:title" mode="ac:JSON-LDPropertyGroup">
        <xsl:param name="suppress" select="false()" as="xs:boolean"/>
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="grouping-key" as="xs:anyAtomicType?"/>
        <xsl:param name="group" as="item()*"/>
        
        <xsl:next-match>
            <xsl:with-param name="suppress" select="$suppress"/>
            <xsl:with-param name="resource" select="$resource"/>
            <xsl:with-param name="grouping-key" select="$grouping-key"/>
            <xsl:with-param name="group" select="$group"/>
        </xsl:next-match>
    </xsl:template>-->
    
    <!-- hide the dct:created/dct:modified properties of graph resources - those are managed automatically by the Graph Store -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')]/dct:created | *[rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')]/dct:modified | *[rdf:type/@rdf:resource = ('&adm;Root', '&dh;Container', '&dh;Item')]/dct:created | *[rdf:type/@rdf:resource = ('&adm;Root', '&dh;Container', '&dh;Item')]/dct:modified" mode="bs2:FormControl" priority="1"/>

    <xsl:template match="dct:format/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <!-- the form will submit a literal value but the SkolemizingModelProvider will convert it to a URI resource -->
        <select name="ol">
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$disabled">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
            </xsl:if>
            
            <option value="">[browser-defined]</option>
            <optgroup label="RDF triples">
                <option value="text/turtle">
                    <xsl:if test="ends-with(., 'text/turtle')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    
                    <xsl:text>Turtle (.ttl)</xsl:text>
                </option>
                <option value="application/n-triples">
                    <xsl:if test="ends-with(., 'application/n-triples')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    
                    <xsl:text>N-Triples (.nt)</xsl:text>
                </option>
                <option value="application/rdf+xml">
                    <xsl:if test="ends-with(., 'application/rdf+xml')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>RDF/XML (.rdf)</xsl:text>
                </option>
            </optgroup>
            <optgroup label="RDF quads">
                <option value="text/trig">
                    <xsl:if test="ends-with(., 'text/trig')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>TriG (.trig)</xsl:text>
                </option>
                <option value="application/n-quads">
                    <xsl:if test="ends-with(., 'application/n-quads')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>N-Quads (.nq)</xsl:text>
                </option>
            </optgroup>
            <optgroup label="Other">
                <option value="text/csv">
                    <xsl:if test="ends-with(., 'text/csv')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>CSV (.csv)</xsl:text>
                </option>
            </optgroup>
        </select>
        
        <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
            <xsl:with-param name="type-label" select="$type-label"/>
        </xsl:apply-templates>
    </xsl:template>
     
</xsl:stylesheet>