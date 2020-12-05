<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <!-- override the value of dh:select in constructor with a default query -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID][$ac:forClass]/dh:select/@rdf:nodeID" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <span>
            <xsl:variable name="query-uri" select="resolve-uri('queries/default/select-children/#this', $ldt:base)" as="xs:anyURI"/>
            <!-- doc-available(ac:document-uri($query-uri)))? -->
            <xsl:apply-templates select="key('resources', $query-uri, document(ac:document-uri($query-uri)))" mode="apl:Typeahead"/>
        </span>
        <xsl:text> </xsl:text>

        <xsl:variable name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI"/>
        <!-- forClass input is used by typeahead's FILTER (?Type IN ()) in client.xsl -->
        <xsl:choose>
            <xsl:when test="not($forClass = '&rdfs;Resource') and doc-available(ac:document-uri($forClass))">
                <xsl:variable name="subclasses" select="apl:listSubClasses($forClass)" as="attribute()*"/>
                <!-- add subclasses as forClass -->
                <xsl:for-each select="distinct-values($subclasses)[not(. = $forClass)]">
                    <input type="hidden" class="forClass" value="{.}"/>
                </xsl:for-each>
                <!-- bs2:Constructor sets forClass -->
                <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                    <xsl:with-param name="subclasses" select="$subclasses"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <input type="hidden" class="forClass" value="{$forClass}"/> <!-- required by ?Type FILTER -->
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="not($type = 'hidden') and $type-label">
            <span class="help-inline">
                <xsl:choose>
                    <xsl:when test="doc-available(ac:document-uri($forClass))">
                        <xsl:choose>
                            <xsl:when test="$forClass = '&rdfs;Resource'">Resource</xsl:when>
                            <xsl:when test="doc-available(ac:document-uri($forClass)) and key('resources', $forClass, document(ac:document-uri($forClass)))">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$forClass"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$forClass"/>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>