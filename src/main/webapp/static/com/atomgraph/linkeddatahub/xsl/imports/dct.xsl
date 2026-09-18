<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:foaf="&foaf;"
xmlns:dct="&dct;"
exclude-result-prefixes="#all">

    <xsl:preserve-space elements="dct:description"/>
    
    <xsl:template match="dct:format/@rdf:nodeID" mode="ac:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <!-- the form will submit a literal value but the SkolemizingModelProvider will convert it to a URI resource -->
        <xsl:apply-templates select="." mode="ac:SelectShell">
            <xsl:with-param name="select" as="item()*">
        <select name="ol">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$disabled">
                <xsl:attribute name="disabled" select="'disabled'"/>
            </xsl:if>
            
            <option value=""><xsl:apply-templates select="key('resources', 'media-type-browser-defined', ldh:translations())" mode="ac:label"/></option>
            <optgroup label="{ac:label(key('resources', 'media-type-group-triples', ldh:translations()))}">
                <option value="text/turtle">
                    <xsl:if test="ends-with(., 'text/turtle')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    
                    <xsl:apply-templates select="key('resources', 'media-type-turtle', ldh:translations())" mode="ac:label"/>
                </option>
                <option value="application/n-triples">
                    <xsl:if test="ends-with(., 'application/n-triples')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    
                    <xsl:apply-templates select="key('resources', 'media-type-ntriples', ldh:translations())" mode="ac:label"/>
                </option>
                <option value="application/rdf+xml">
                    <xsl:if test="ends-with(., 'application/rdf+xml')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:apply-templates select="key('resources', 'media-type-rdfxml', ldh:translations())" mode="ac:label"/>
                </option>
            </optgroup>
            <optgroup label="{ac:label(key('resources', 'media-type-group-quads', ldh:translations()))}">
                <option value="text/trig">
                    <xsl:if test="ends-with(., 'text/trig')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:apply-templates select="key('resources', 'media-type-trig', ldh:translations())" mode="ac:label"/>
                </option>
                <option value="application/n-quads">
                    <xsl:if test="ends-with(., 'application/n-quads')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:apply-templates select="key('resources', 'media-type-nquads', ldh:translations())" mode="ac:label"/>
                </option>
            </optgroup>
            <optgroup label="{ac:label(key('resources', 'other', ldh:translations()))}">
                <option value="text/csv">
                    <xsl:if test="ends-with(., 'text/csv')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:apply-templates select="key('resources', 'media-type-csv', ldh:translations())" mode="ac:label"/>
                </option>
            </optgroup>
        </select>
            </xsl:with-param>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations"/>
        </xsl:if>
    </xsl:template>
     
</xsl:stylesheet>