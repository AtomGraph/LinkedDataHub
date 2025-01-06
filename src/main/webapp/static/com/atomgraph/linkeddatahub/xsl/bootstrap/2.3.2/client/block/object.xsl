<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
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
xmlns:rdfs="&rdfs;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Object']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- provide a property label which otherwise would default to local-name() client-side (since $property-metadata is not loaded) -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Object']/rdfs:label | *[rdf:type/@rdf:resource = '&ldh;Object']/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- object block (RDF resource) -->
    
    <xsl:template match="*[@typeof = '&ldh;Object'][descendant::*[@property = '&rdf;value'][@resource]]" mode="ldh:RenderRow" priority="1">
        <xsl:param name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:param name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:param name="block-uri" select="$about" as="xs:anyURI"/>
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="resource-uri" select="descendant::*[@property = '&rdf;value']/@resource" as="xs:anyURI?"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="show-edit-button" select="false()" as="xs:boolean?"/>

        <xsl:message>ldh:Object ldh:RenderBlock @about: <xsl:value-of select="@about"/></xsl:message>

        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'50%'" object="."/>
        </xsl:for-each>
        
        <!-- don't use ldh:base-uri(.) because its value comes from the last HTML document load -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, if (starts-with($graph, $ldt:base)) then $graph else ac:absolute-path(xs:anyURI(ixsl:location())), map{}, ac:document-uri($resource-uri), $graph, ())" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:LoadBlockObjectValue">
                    <xsl:with-param name="block" select="$block"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="resource-uri" select="$resource-uri"/>
                    <xsl:with-param name="graph" select="$graph"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="show-edit-button" select="$show-edit-button"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template name="ldh:LoadBlockObjectValue">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="block" as="element()"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="resource-uri" as="xs:anyURI"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="show-edit-button" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
                    <!-- update progress bar -->
                    <ixsl:set-style name="width" select="'88%'" object="."/>
                </xsl:for-each>
                    
                <xsl:for-each select="?body">
                    <xsl:message>ldh:LoadBlockObjectValue ldh:RenderBlock</xsl:message>
                    <xsl:variable name="resource" select="key('resources', $resource-uri)" as="element()?"/>
                    <xsl:variable name="object-uris" select="distinct-values($resource/*/@rdf:resource[not(key('resources', ., root($resource)))])" as="xs:string*"/>
                    <xsl:variable name="query-string" select="$object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                    <xsl:message>$object-uris: <xsl:value-of select="$object-uris"/></xsl:message>
                    <xsl:message>$resource-uri: <xsl:value-of select="$resource-uri"/> $resource: <xsl:value-of select="serialize($resource)"/></xsl:message>
                    
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': sd:endpoint(), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                            <xsl:call-template name="ldh:LoadBlockObjectMetadata">
                                <xsl:with-param name="block" select="$block"/>
                                <xsl:with-param name="container" select="$container"/>
                                <xsl:with-param name="resource" select="$resource"/>
                                <xsl:with-param name="graph" select="$graph"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="show-edit-button" select="$show-edit-button"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="?status = 406">
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="offset2 span7 main">
                            <object data="{$resource-uri}"/>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load resource: <a href="{$resource-uri}"><xsl:value-of select="$resource-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
 <!-- replaces the block with a row -->
    
    <xsl:template name="ldh:LoadBlockObjectMetadata">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="block" as="element()"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="show-edit-button" as="xs:boolean?"/>

        <xsl:message>
            ldh:LoadBlockObjectMetadata
            ?body: <xsl:value-of select="serialize(?body)"/>
        </xsl:message>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="object-metadata" select="?body" as="document-node()"/>

                <xsl:variable name="row" as="node()*">
                    <xsl:apply-templates select="$resource" mode="bs2:Row">
                        <xsl:with-param name="graph" select="$graph" tunnel="yes"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="show-edit-button" select="$show-edit-button" tunnel="yes"/>
                        <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                        <xsl:with-param name="show-row-block-controls" select="false()"/> <!-- blocks nested within ldh:Object do not show their own progress bars -->
                    </xsl:apply-templates>
                </xsl:variable>

                <xsl:message>
                    ldh:LoadBlockObjectMetadata $resource: <xsl:value-of select="serialize($resource)"/>
                    ldh:LoadBlockObjectMetadata $row: <xsl:value-of select="serialize($row)"/>
                </xsl:message>
        
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <!-- wrap the row -->
                        <div class="span12">
                            <xsl:copy-of select="$row"/>
                        </div>
                    </xsl:result-document>
                    
                    <xsl:apply-templates mode="ldh:RenderRow"/> <!-- recurse down the block hierarchy -->
                </xsl:for-each>

                <!-- hide the row with the block controls -->
<!--                <ixsl:set-style name="z-index" select="'-1'" object="key('elements-by-class', 'row-block-controls', $block)"/>-->
                
                <!-- hide the progress bar -->
<!--                <xsl:for-each select="$block/div[contains-token(@class, 'span12')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>-->
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>