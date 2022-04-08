<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->
    
    <xsl:template name="ldh:RDFDocumentLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"> <!-- using the ldh:SelectChildren query -->
            <xsl:variable name="select-string" select="key('resources', '&ldh;SelectChildren', document(ac:document-uri('&ldh;')))/sp:text" as="xs:string"/>
            <xsl:variable name="select-string" select="replace($select-string, '\$this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
            <xsl:variable name="select-json" as="item()">
                <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
            </xsl:variable>
            <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
            <xsl:sequence select="json-to-xml($select-json-string)"/>
        </xsl:param>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $results-uri)" as="xs:anyURI"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:DocTreeResourceLoaded">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="uri" select="$uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <xsl:template name="ldh:BreadCrumbResourceLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="leaf" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="resource" select="key('resources', $uri)" as="element()?"/>
                    <xsl:variable name="parent-uri" select="$resource/sioc:has_container/@rdf:resource | $resource/sioc:has_parent/@rdf:resource" as="xs:anyURI?"/>
                    <xsl:if test="$parent-uri">
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $parent-uri)" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="ldh:BreadCrumbResourceLoaded">
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="uri" select="$parent-uri"/>
                                    <xsl:with-param name="leaf" select="false()"/> <!-- parent resources cannot be leaves -->
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>

                    <!-- append to the breadcrumb list -->
                    <xsl:for-each select="$container/ul">
                        <xsl:variable name="content" select="*" as="element()*"/>
                        <!-- we want to prepend the parent resource to the beginning of the breadcrumb list -->
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:apply-templates select="$resource" mode="bs2:BreadCrumbListItem">
                                <xsl:with-param name="leaf" select="$leaf"/>
                            </xsl:apply-templates>
                            
                            <xsl:copy-of select="$content"/>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    Error loading breadcrumbs for URI :<xsl:value-of select="$uri"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ldh:DocTreeResourceLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="resources" select="rdf:RDF/*[@rdf:about]" as="element()*"/>
                    <!--<xsl:variable name="parent-uri" select="$resource/sioc:has_container/@rdf:resource | $resource/sioc:has_parent/@rdf:resource" as="xs:anyURI?"/>-->
<!--                    <xsl:if test="$parent-uri">
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $parent-uri)" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="ldh:DocTreeResourceLoad">
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="uri" select="$parent-uri"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>-->

                    <!-- append to the doc tree list -->
                    <xsl:for-each select="$container/ul">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:apply-templates select="$resources" mode="bs2:List">
                                <xsl:with-param name="active" select="@rdf:about = $uri"/>
                            </xsl:apply-templates>
                        </xsl:result-document>
                    </xsl:for-each>
                    
                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    Error loading document tree for URI :<xsl:value-of select="$uri"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>