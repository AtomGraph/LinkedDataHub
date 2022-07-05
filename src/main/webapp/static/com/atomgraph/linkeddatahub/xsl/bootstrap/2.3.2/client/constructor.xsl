<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh        "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs       "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd        "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt        "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->

    <!-- render constructor template -->

    <xsl:template name="ldh:LoadConstructor">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="uri" as="xs:anyURI"/> <!-- document URI -->
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:variable name="constructor-uri" select="@about" as="xs:anyURI"/>
        <xsl:variable name="construct-string" select="input[@name = 'construct-string']/@value" as="xs:string"/>
        <!--<xsl:message>$construct-string: <xsl:value-of select="serialize($construct-string)"/></xsl:message>-->
        <xsl:variable name="construct-json" as="item()">
            <xsl:variable name="construct-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromString', [ $construct-string ])"/>
            <xsl:sequence select="ixsl:call($construct-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="construct-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $construct-json ])" as="xs:string"/>
        <xsl:variable name="construct-xml" select="json-to-xml($construct-json-string)" as="document-node()"/>

        <xsl:result-document href="?." method="ixsl:replace-content">
            <div class="offset2 span7">
                <div class="row-fluid">
                    <div class="span4">
                        <p>
                            <strong>Property</strong>
                        </p>
                    </div>
                    <div class="span4">
                        <p>
                            <strong>Object kind</strong>
                        </p>
                    </div>
                    <div class="span4">
                        <p>
                            <strong>Object type</strong>
                        </p>
                    </div>
                </div>
                
                <xsl:for-each select="$construct-xml/json:map/json:array[@key = 'template']/json:map[json:string[@key = 'subject'] = '?this']">
                    <xsl:sort select="json:string[@key = 'predicate']"/>

                    <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': ac:document-uri($predicate), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                    <div class="row-fluid">
                        <div class="span4">
                            <p>
                                <span>
                                    <xsl:apply-templates select="key('resources', $predicate, document($request-uri))" mode="ldh:Typeahead">
                                        <xsl:with-param name="class" select="'btn add-typeahead add-property-typeahead'"/>
                                    </xsl:apply-templates>
                                </span>
                            </p>
                            
                            <!-- used by typeahead to set $Type -->
                            <input type="hidden" class="forClass" value="&rdf;Property" autocomplete="off"/>
                        </div>
                        <div class="span4">
                            <p>
                                <select>
                                    <option value="&rdfs;Resource">Resource</option>
                                    <option value="&rdfs;Literal">Literal</option>
                                </select>
                            </p>
                        </div>
                        <div class="span4">
                            <xsl:variable name="object-bnode-id" select="json:string[@key = 'object']" as="xs:string"/>
                            <xsl:variable name="object-type" select="../json:map[json:string[@key = 'subject'] = $object-bnode-id]/json:string[@key = 'object']" as="xs:anyURI"/>
                            <xsl:choose>
                                <xsl:when test="starts-with($object-type, '&xsd;')">
                                    <p>
                                        <xsl:value-of select="$object-type"/>
                                    </p>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': ac:document-uri($object-type), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                                    <p>
                                        <span>
                                            <xsl:apply-templates select="key('resources', $object-type, document($request-uri))" mode="ldh:Typeahead">
                                                <xsl:with-param name="class" select="'btn add-typeahead add-class-typeahead'"/>
                                            </xsl:apply-templates>
                                        </span>
                                    </p>

                                    <!-- used by typeahead to set $Type -->
                                    <input type="hidden" class="forClass" value="&rdfs;Class" autocomplete="off"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </div>
                </xsl:for-each>
            </div>
        </xsl:result-document>
    </xsl:template>

    <!-- EVENT HANDLERS -->
    
    <!-- classes and properties are looked up in the <ns> endpoint -->
    <xsl:template match="input[contains-token(@class, 'class-typeahead')] | input[contains-token(@class, 'property-typeahead')]" mode="ixsl:onkeyup" priority="1">
        <xsl:next-match>
            <xsl:with-param name="endpoint" select="resolve-uri('ns', $ldt:base)"/>
            <xsl:with-param name="select-string" select="$select-labelled-string"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'class-typeahead')]/li" mode="ixsl:onmousedown" priority="2">
        <xsl:next-match>
            <xsl:with-param name="typeahead-class" select="'btn add-typeahead add-class-typeahead'"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'property-typeahead')]/li" mode="ixsl:onmousedown" priority="2">
        <xsl:next-match>
            <xsl:with-param name="typeahead-class" select="'btn add-typeahead add-property-typeahead'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- special case for class lookups -->
    <xsl:template match="button[contains-token(@class, 'add-class-typeahead')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'class-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'class-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>

    <!-- special case for property lookups -->
    <xsl:template match="button[contains-token(@class, 'add-property-typeahead')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'property-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'property-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>

</xsl:stylesheet>