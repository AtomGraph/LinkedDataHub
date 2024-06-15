<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
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
xmlns:rdfs="&rdfs;"
xmlns:geo="&geo;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:variable name="content-delete-string" as="xs:string">
        <!-- TO-DO: refactor to update the following index properties -->
        <![CDATA[
            DELETE
            {
                $this ?seq $block .
                $block ?p ?o .
            }
            WHERE
            {
                $this ?seq $block .
                OPTIONAL
                {
                    $block ?p ?o
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="content-swap-string" as="xs:string">
        <![CDATA[
            PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE {
              $this ?sourceSeq $sourceBlock .
              $this ?targetSeq $targetBlock .
              $this ?seq ?block .
            }
            INSERT {
              $this ?newSourceSeq $sourceBlock .
              $this ?newTargetSeq $targetBlock .
              $this ?newSeq ?block .
            }
            WHERE
              { $this  ?sourceSeq  $sourceBlock
                FILTER(strstarts(str(?sourceSeq), concat(str(rdf:), "_")))
                BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                $this  ?targetSeq  $targetBlock
                FILTER(strstarts(str(?targetSeq), concat(str(rdf:), "_")))
                BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ( ?targetIndex - 1 ), ?targetIndex) AS ?newTargetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ?targetIndex, ( ?targetIndex + 1 )) AS ?newSourceIndex)
                BIND(IRI(concat(str(rdf:), "_", str(?newSourceIndex))) AS ?newSourceSeq)
                BIND(IRI(concat(str(rdf:), "_", str(?newTargetIndex))) AS ?newTargetSeq)
                OPTIONAL
                  { $this  ?sourceSeq  $sourceBlock
                    FILTER(strstarts(str(?sourceSeq), concat(str(rdf:), "_")))
                    BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                    $this  ?targetSeq  $targetBlock
                    FILTER(strstarts(str(?targetSeq), concat(str(rdf:), "_")))
                    BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                    $this  ?seq  ?block
                    FILTER strstarts(str(?seq), str(rdf:_))
                    BIND(xsd:integer(substr(str(?seq), 45)) AS ?index)
                    BIND(( ( ?index > ?sourceIndex ) && ( ?index < ?targetIndex ) ) AS ?isBetweenSourceAndTarget)
                    BIND(( ( ?index < ?sourceIndex ) && ( ?index > ?targetIndex ) ) AS ?isBetweenTargetAndSource)
                    FILTER ( ?isBetweenSourceAndTarget || ?isBetweenTargetAndSource )
                    BIND(( ?index + if(?isBetweenSourceAndTarget, -1, +1) ) AS ?newIndex)
                    BIND(IRI(concat(str(rdf:), "_", str(?newIndex))) AS ?newSeq)
                  }
              }
        ]]>
    </xsl:variable>
    
    <xsl:key name="content-by-about" match="*[@about]" use="@about"/>

    <!-- TEMPLATES -->

    <xsl:template match="*[@rdf:nodeID = 'run']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-run-query')"/>
    </xsl:template>

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- provide a property label which otherwise would default to local-name() client-side (since $property-metadata is not loaded) -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]/rdfs:label | *[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']/rdf:value/xhtml:*" mode="bs2:FormControlTypeLabel" priority="1"/>

    <!-- VIEW -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;View'][spin:query/@rdf:resource]" mode="ldh:RenderBlock" priority="1">
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="block-type" select="rdf:type/@rdf:resource" as="xs:anyURI"/>
        <xsl:param name="graph" select="ldh:graph/@rdf:resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="ac:mode/@rdf:resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>
        <xsl:param name="content-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path($base-uri) || '#' || $container/@id)" as="xs:anyURI"/>
        <xsl:variable name="query-uri" select="xs:anyURI(spin:query/@rdf:resource)" as="xs:anyURI"/>
        <xsl:variable name="service-uri" select="xs:anyURI(ldh:service/@rdf:resource)" as="xs:anyURI?"/>
        
        <xsl:for-each select="$container">
            <ixsl:set-attribute name="typeof" select="$block-type" object="."/>
        </xsl:for-each>
        <xsl:message>ldh:View ldh:RenderBlock</xsl:message>
        
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:document-uri($query-uri))" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:ViewQueryLoad">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                    <xsl:with-param name="content" select="."/>
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="query-uri" select="$query-uri"/>
                    <xsl:with-param name="service-uri" select="$service-uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template name="ldh:ViewQueryLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="content" as="element()"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>
        <xsl:param name="service-uri" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="select-query" select="key('resources', $query-uri)" as="element()"/>
                    <!-- set $this variable value unless getting the query string from state -->
                    <xsl:variable name="select-string" select="replace($select-query/sp:text, '$this', '&lt;' || $this || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="select-xml" as="document-node()">
                        <xsl:variable name="select-json" as="item()">
                            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
                        </xsl:variable>
                        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
                        <xsl:sequence select="json-to-xml($select-json-string)"/>
                    </xsl:variable>
                    <xsl:variable name="initial-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
                    <xsl:variable name="focus-var-name" select="$initial-var-name" as="xs:string"/>
                    <!-- service can be explicitly specified on content using ldh:service -->
                    <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
                    <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>

                    <xsl:choose>
                        <!-- service URI is not specified or specified and can be loaded -->
                        <xsl:when test="not($service-uri) or ($service-uri and exists($service))">
                            <!-- window.LinkedDataHub.contents[{$content-uri}] object is already created -->
                            <!-- store the initial SELECT query (without modifiers) -->
                            <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                            <!-- store the first var name of the initial SELECT query -->
                            <ixsl:set-property name="initial-var-name" select="$initial-var-name" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                            <xsl:if test="$service-uri">
                                <!-- store (the URI of) the service -->
                                <ixsl:set-property name="service-uri" select="$service-uri" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                                <ixsl:set-property name="service" select="$service" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                            </xsl:if>

                            <xsl:variable name="select-xml" as="document-node()">
                                <xsl:document>
                                    <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit">
                                        <xsl:with-param name="limit" select="$page-size" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:document>
                            </xsl:variable>
                            <xsl:variable name="select-xml" as="document-node()">
                                <xsl:document>
                                    <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                                        <xsl:with-param name="offset" select="0" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:document>
                            </xsl:variable>

                            <!-- store the transformed query XML -->
                            <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                            <!-- update progress bar -->
                            <xsl:for-each select="$container//div[@class = 'bar']">
                                <ixsl:set-style name="width" select="'63%'" object="."/>
                            </xsl:for-each>

                            <xsl:call-template name="ldh:RenderView">
                                <xsl:with-param name="container" select="$container"/>
                                <xsl:with-param name="content-uri" select="$content-uri"/>
                                <xsl:with-param name="content" select="$content"/> <!-- unused? -->
                                <xsl:with-param name="select-string" select="$select-string"/>
                                <xsl:with-param name="select-xml" select="$select-xml"/>
                                <xsl:with-param name="endpoint" select="$endpoint"/>
                                <xsl:with-param name="initial-var-name" select="$initial-var-name"/>
                                <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                                <xsl:with-param name="active-mode" select="if ($mode) then $mode else xs:anyURI('&ac;ListMode')"/>
                                <xsl:with-param name="refresh-content" select="$refresh-content"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                                <xsl:result-document href="?." method="ixsl:replace-content">
                                    <div class="alert alert-block">
                                        <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                                    </div>
                                </xsl:result-document>
                            </xsl:for-each>

                            <xsl:call-template name="ldh:BlockRendered">
                                <xsl:with-param name="container" select="$container"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load query resource: <a href="{$query-uri}"><xsl:value-of select="$query-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- object block (RDF resource) -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;Object'][rdf:value/@rdf:resource]" mode="ldh:RenderBlock" priority="1">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="block-type" select="rdf:type/@rdf:resource" as="xs:anyURI"/>
        <xsl:param name="resource-uri" select="rdf:value/@rdf:resource" as="xs:anyURI?"/>
        <xsl:param name="graph" select="ldh:graph/@rdf:resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="ac:mode/@rdf:resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="show-edit-button" select="false()" as="xs:boolean?"/>

        <xsl:for-each select="$container//div[@class = 'bar']">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>
        <xsl:message>ldh:Object ldh:RenderBlock</xsl:message>

        <xsl:for-each select="$container">
            <ixsl:set-attribute name="typeof" select="$block-type" object="."/>
        </xsl:for-each>

        <!-- don't use ldh:base-uri(.) because its value comes from the last HTML document load -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, if (starts-with($graph, $ldt:base)) then $graph else ac:absolute-path(xs:anyURI(ixsl:location())), map{}, ac:document-uri($resource-uri), $graph, ())" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:LoadBlockObjectValue">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="block-type" select="$block-type"/>
                    <xsl:with-param name="resource-uri" select="$resource-uri"/>
                    <xsl:with-param name="graph" select="$graph"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="show-edit-button" select="$show-edit-button"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- default block (RDF resource) -->
    
    <xsl:template match="*[*][@rdf:about]" mode="ldh:RenderBlock">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="block-type" select="rdf:type/@rdf:resource" as="xs:anyURI"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="show-edit-button" select="false()" as="xs:boolean?"/>
        <xsl:variable name="object-uris" select="distinct-values(*/@rdf:resource[not(key('resources', .))])" as="xs:string*"/>
        <xsl:variable name="query-string" select="$object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>

        <xsl:for-each select="$container//div[@class = 'bar']">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>
        <xsl:message>default ldh:RenderBlock</xsl:message>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': sd:endpoint(), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:LoadBlockObjectMetadata">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="block-type" select="$block-type"/>
                    <xsl:with-param name="resource" select="."/>
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
        <xsl:param name="container" as="element()"/>
        <xsl:param name="block-type" as="xs:anyURI"/>
        <xsl:param name="resource-uri" as="xs:anyURI"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="show-edit-button" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:for-each select="$container//div[@class = 'bar']">
                        <!-- update progress bar -->
                        <ixsl:set-style name="width" select="'88%'" object="."/>
                    </xsl:for-each>
                    
                    <xsl:variable name="resource" select="key('resources', $resource-uri)" as="element()?"/>
                    <xsl:message>ldh:LoadBlockObjectValue ldh:RenderBlock</xsl:message>
                    <xsl:apply-templates select="$resource" mode="ldh:RenderBlock">
                        <xsl:with-param name="container" select="$container"/>
                    </xsl:apply-templates>
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
                
                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load resource: <a href="{$resource-uri}"><xsl:value-of select="$resource-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- replaces the block with a row -->
    
    <xsl:template name="ldh:LoadBlockObjectMetadata">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="block-type" as="xs:anyURI"/>
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="show-edit-button" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="object-metadata" select="?body" as="document-node()"/>
                
                <!-- hide progress bar, if any -->
                <xsl:for-each select="$container//div[@class = 'progress-bar']">
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:for-each>

                <xsl:variable name="row" as="node()*">
                    <xsl:apply-templates select="$resource" mode="bs2:Row">
                        <xsl:with-param name="graph" select="$graph" tunnel="yes"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="show-edit-button" select="$show-edit-button" tunnel="yes"/>
                        <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:variable>

                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:copy-of select="$row/*"/> <!-- inject the content of div.row-fluid -->
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
                
                <xsl:apply-templates select="$container/*" mode="ldh:PostConstruct"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="ldh:BlockRendered">
        <xsl:param name="container" as="element()"/>

        <!-- insert "Edit" button if the agent has acl:Write access -->
        <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
            <xsl:if test="not(button[contains-token(@class, 'btn-edit')])">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:if test="acl:mode() = '&acl;Write'">
                        <button type="button" class="btn btn-edit pull-right">
                            <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                        </button>
                    </xsl:if>

                    <xsl:copy-of select="$container//div[contains-token(@class, 'main')]/*"/>
                </xsl:result-document>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->
    
    <!-- append new block form onsubmit (using POST) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;View', '&ldh;Object')][contains-token(@class, 'row-fluid')]//form[contains-token(@class, 'form-horizontal')][upper-case(@method) = 'POST']" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:param name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:param name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI(.//input[@name = 'su'] => ixsl:get('value'))" as="xs:anyURI"/>
        <xsl:variable name="sequence-number" select="count($container/preceding-sibling::div[@about][contains-token(@class, 'content')]) + 1" as="xs:integer"/>
        <xsl:variable name="sequence-property" select="xs:anyURI('&rdf;_' || $sequence-number)" as="xs:anyURI"/>
        <xsl:variable name="sequence-triple" as="element()">
            <json:map>
                <json:string key="subject"><xsl:sequence select="ac:absolute-path(ldh:base-uri(.))"/></json:string>
                <json:string key="predicate"><xsl:sequence select="$sequence-property"/></json:string>
                <json:string key="object"><xsl:sequence select="$block-uri"/></json:string>
            </json:map>
        </xsl:variable>
        <xsl:message>
            block $triples: <xsl:value-of select="serialize($triples)"/>
        </xsl:message>
        <xsl:message>
            block $sequence-triple: <xsl:value-of select="serialize($sequence-triple)"/>
        </xsl:message>
        
        <xsl:next-match>
            <!-- append $sequence-triple to $request-body that is sent with the HTTP request, but not to $resources which are rendered after the block update (don't want to show it) -->
            <xsl:with-param name="request-body" as="document-node()">
                <xsl:document>
                    <rdf:RDF>
                        <xsl:sequence select="ldh:triples-to-descriptions(($triples, $sequence-triple))"/>
                    </rdf:RDF>
                </xsl:document>
            </xsl:with-param>
        </xsl:next-match>
    </xsl:template>
    
    <!-- save query onclick -->
    
    <xsl:template match="div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-save-query')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="about" select="$container/@about" as="xs:anyURI"/>
        <xsl:variable name="textarea" select="ancestor::form/descendant::textarea[@name = 'query']" as="element()"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea/ixsl:get(., 'id'))"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string?"/> <!-- get query string from YASQE -->
        <xsl:variable name="action" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="accept" select="'application/rdf+xml'" as="xs:string"/>
        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>
        <xsl:variable name="service-uri" select="ancestor::form/descendant::select[contains-token(@class, 'input-query-service')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string?"/>
        <!-- not using ldh:base-uri(.) because it goes stale when DOM is replaced -->
        <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(xs:anyURI(ixsl:location())) || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="query" select="key('resources', $about, $doc)" as="element()"/>

        <xsl:apply-templates select="$query" mode="ldh:SetQueryString">
            <xsl:with-param name="query-string" select="$query-string" tunnel="yes"/>
        </xsl:apply-templates>
        <xsl:variable name="triples" select="ldh:descriptions-to-triples($query)" as="element()*"/>
        <xsl:message>
            $query triples: <xsl:value-of select="serialize($triples)"/>
        </xsl:message>
        <xsl:variable name="update-string" select="ldh:triples-to-sparql-update($about, $triples)" as="xs:string"/>
        <xsl:variable name="resources" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:sequence select="ldh:triples-to-descriptions($triples)"/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $action)" as="xs:anyURI"/>
        
        <xsl:variable name="request" as="item()*">
            <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile --> 
            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string, 'headers': map{ 'If-Match': $etag, 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }">
                <xsl:call-template name="ldh:ResourceUpdated">
                    <xsl:with-param name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))"/>
                    <xsl:with-param name="container" select="$container"/>
                    <!-- <xsl:with-param name="form" select="$form"/> --> 
                    <xsl:with-param name="resources" select="$resources"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
   <!-- identity transform -->
   
    <xsl:template match="@* | node()" mode="ldh:SetQueryString">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- set query string -->

    <xsl:template match="sp:text/text()" mode="ldh:SetQueryString" priority="1">
        <xsl:param name="query-string" as="xs:string" tunnel="yes"/>

        <xsl:sequence select="$query-string"/>
    </xsl:template>
        
    <!-- open query onclick -->
    
    <xsl:template match="div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-open-query')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]" as="element()"/>
<!--        <xsl:variable name="old-content-value" select="ixsl:get($container, 'dataset.contentValue')" as="xs:anyURI"/>-->
        <xsl:variable name="content-value" select="ixsl:get($container//div[contains-token(@class, 'main')]//input[@name = 'ou'], 'value')" as="xs:anyURI"/>
        <xsl:variable name="textarea" select="ancestor::form/descendant::textarea[@name = 'query']" as="element()"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea/ixsl:get(., 'id'))"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string?"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="descendant::select[contains-token(@class, 'input-query-service')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string?"/>

        <xsl:choose>
            <!-- query string value missing/invalid, throw an error -->
            <xsl:when test="not($query-type = ('DESCRIBE', 'CONSTRUCT'))">
                <xsl:message>Can only open DESCRIBE or CONSTRUCT query results</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="href" select="ldh:href($ldt:base, $ldt:base, map{}, $results-uri)" as="xs:anyURI"/>

                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <!-- abort the previous request, if any -->
                <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
                    <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                    <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
                </xsl:if>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="ldh:DocumentLoaded">
                            <xsl:with-param name="href" select="$href"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>

                <!-- store the new request object -->
                <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- save chart onclick -->
    
    <xsl:template match="div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-save-chart')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="textarea-id" select="descendant::textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('query-service'), 'value'))" as="xs:anyURI?"/> <!-- TO-DO: fix content-embedded queries -->
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string"/>
        <xsl:variable name="forClass" select="if ($query-type = ('SELECT', 'ASK')) then xs:anyURI('&ldh;ResultSetChart') else xs:anyURI('&ldh;GraphChart')" as="xs:anyURI"/>
        <xsl:variable name="modal-form" select="true()" as="xs:boolean"/>
        <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:base-uri(.)), let $params := map{ 'forClass': string($forClass), 'createGraph': string(true()) } return if ($modal-form) then map:merge(($params, map{ 'mode': '&ac;ModalMode' })) else $params)" as="xs:anyURI"/>
        <xsl:variable name="chart-type" select="../..//select[contains-token(@class, 'chart-type')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="category" select="../..//select[contains-token(@class, 'chart-category')]/ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:variable name="series" as="xs:string*">
            <xsl:for-each select="../..//select[contains-token(@class, 'chart-series')]">
                <xsl:variable name="select" select="." as="element()"/>
                <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                    <xsl:sequence select="ixsl:get(ixsl:call(ixsl:get($select, 'selectedOptions'), 'item', [ . ]), 'value')"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="textarea" select="$container//descendant::textarea[@name = 'query']" as="element()"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea/ixsl:get(., 'id'))"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string?"/> <!-- get query string from YASQE -->

        <xsl:message>SAVE CHART $query-string: <xsl:value-of select="$query-string"/></xsl:message>
        
        <!--
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddSaveChartForm">
                    <xsl:with-param name="query-string" select="$query-string"/>
                    <xsl:with-param name="service-uri" select="$service-uri"/>
                    <xsl:with-param name="chart-type" select="$chart-type"/>
                    <xsl:with-param name="category" select="$category"/>
                    <xsl:with-param name="series" select="$series"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>-->
    </xsl:template>
    
    <xsl:template name="onSPARQLQuerySave">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="textarea" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="base-uri" as="xs:anyURI?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:variable name="content-value" select="$query-uri" as="xs:anyURI"/>
                <xsl:variable name="content-id" select="$container/@id" as="xs:string"/>
                <xsl:variable name="block-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)" as="xs:anyURI"/>
                <xsl:variable name="sequence-number" select="count($container/preceding-sibling::div[@about][contains-token(@class, 'content')]) + 1" as="xs:integer"/>
                <xsl:variable name="sequence-property" select="xs:anyURI('&rdf;_' || $sequence-number)" as="xs:anyURI"/>
                <xsl:message>$sequence-number: <xsl:value-of select="$sequence-number"/> $sequence-property: <xsl:value-of select="$sequence-property"/></xsl:message>
                <xsl:variable name="update-string" select="''" as="xs:string"/> <!--TO-DO: fix. Was: $block-update-string -->
                <xsl:variable name="update-string" select="replace($update-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$seq', '&lt;' || $sequence-property || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$type', '&lt;&ldh;View&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$block', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$valueProperty', '&lt;&spin;query&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$value', '&lt;' || $content-value || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="if ($mode) then replace($update-string, '$mode', '&lt;' || $mode || '&gt;', 'q') else $update-string" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($base-uri), map{}, ac:absolute-path($base-uri))" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                        <xsl:call-template name="onSPARQLContentUpdate">
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="content-uri" select="$block-uri"/>
                            <xsl:with-param name="content-value" select="$content-value"/>
                            <xsl:with-param name="mode" select="$mode"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- query string was invalid - show error -->
            <xsl:when test="?status = 422">
                <ixsl:set-style name="border-color" select="'#ff0039'" object="$textarea/following-sibling::div[contains-token(@class, 'CodeMirror')]"/> <!-- YASQE container -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not save content resource: <a href="{$query-uri}"><xsl:value-of select="$query-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
                
                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- delete content onclick (increased priority to take precedence over form.xsl .btn-remove-resource) -->
    
    <xsl:template match="div[contains-token(@class, 'content')]//button[contains-token(@class, 'btn-remove-resource')]" mode="ixsl:onclick" priority="3">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')]" as="element()"/>

        <xsl:choose>
            <!-- delete existing content -->
            <xsl:when test="$container/@about">
                <!-- show a confirmation prompt -->
                <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))) ])">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <xsl:variable name="block-uri" select="$container/@about" as="xs:anyURI"/>
                    <xsl:variable name="update-string" select="replace($content-delete-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$block', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="onContentDelete">
                                <xsl:with-param name="container" select="$container"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:when>
            <!-- remove content that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- XHTML content cancel onclick - prioritize over resource content -->
    
    <xsl:template match="div[contains-token(@class, 'xhtml-content')]//button[contains-token(@class, 'btn-cancel')]" mode="ixsl:onclick" priority="2">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'xhtml-content')]" as="element()"/>

        <xsl:message>XHTML content cancel onclick</xsl:message>
        
        <xsl:choose>
            <!-- restore existing content -->
            <xsl:when test="$container/@about">
                <xsl:variable name="textarea" select="ancestor::div[contains-token(@class, 'main')]//textarea[contains-token(@class, 'wymeditor')]" as="element()"/>
                <xsl:variable name="old-content-string" select="string($textarea)" as="xs:string"/>
                <xsl:variable name="content-value" select="ldh:parse-html('&lt;div&gt;' || $old-content-string || '&lt;/div&gt;', 'application/xhtml+xml')" as="document-node()"/>

                <xsl:for-each select="$container/div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <button type="button" class="btn btn-edit pull-right">
                            <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                        </button>

                        <xsl:copy-of select="$content-value"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <!-- remove content that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- resource content/SPARQL content cancel onclick -->
    
    <xsl:template match="div[contains-token(@class, 'content')]//button[contains-token(@class, 'btn-cancel')]" mode="ixsl:onclick" priority="1"> <!-- prioritize over form.xsl -->
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')]" as="element()"/>

        <xsl:message>resource content</xsl:message>

        <xsl:choose>
            <!-- updating existing content -->
            <xsl:when test="$container/@about">
                <xsl:for-each select="$container">
                    <xsl:call-template name="ldh:LoadBlock"/>
                </xsl:for-each>
            </xsl:when> 
            <!-- remove content that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'add-constructor')][@data-for-class = '&ldh;XHTML']" mode="ixsl:onclick" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>

        <xsl:message>
            ldh:XHTML .add-constructor onclick
        </xsl:message>
        
        <!-- call the default handler in form.xsl -->
        <xsl:next-match/>
        
        <xsl:message>Toggle .content.xhtml-content</xsl:message>
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'xhtml-content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- appends new resource block to the content list -->
    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'add-constructor')][@data-for-class = ('&ldh;View', '&ldh;Object')]" mode="ixsl:onclick" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
    
        <!-- call the default handler in form.xsl -->
        <xsl:next-match/>
        
        <xsl:message>Toggle .content</xsl:message>
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- submit SPARQL query form (prioritize over default template in form.xsl) -->
    
    <xsl:template match="div[@typeof = ('&sp;Ask', '&sp;Select', '&sp;Describe', '&sp;Construct')][contains-token(@class, 'row-fluid')]//form[contains-token(@class, 'sparql-query-form ')]" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:message>.sparql-query-form onsubmit</xsl:message>
        <xsl:variable name="textarea-id" select="descendant::textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="descendant::select[contains-token(@class, 'input-query-service')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="content-id" select="$container/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $ldt:base, map{}, $results-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }" as="map(xs:string, item())"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="$request">
                <xsl:call-template name="onSPARQLResultsLoad">
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="results-uri" select="$results-uri"/>
                    <xsl:with-param name="content-uri" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="chart-canvas-id" select="$content-id || '-chart-canvas'"/>
                    <xsl:with-param name="results-container-id" select="$content-id || '-query-results'"/>
                    <xsl:with-param name="query-string" select="$query-string"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- toggle query results to chart mode (prioritize over container.xsl) -->
    
    <xsl:template match="*[contains-token(@class, 'content')]//ul[contains-token(@class, 'nav-tabs')][contains-token(@class, 'nav-query-results')]/li[contains-token(@class, 'chart-mode')][not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick" priority="1">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')]" as="element()"/>
        <xsl:variable name="form" select="$container//form[contains-token(@class, 'sparql-query-form')]" as="element()"/>

        <!-- deactivate other tabs -->
        <xsl:for-each select="../../li">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="..">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:apply-templates select="$form" mode="ixsl:onsubmit"/>
    </xsl:template>
    
    <!-- toggle query results to container mode (prioritize over container.xsl) -->
    
    <xsl:template match="*[contains-token(@class, 'content')]//ul[contains-token(@class, 'nav-tabs')][contains-token(@class, 'nav-query-results')]/li[contains-token(@class, 'container-mode')][not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick" priority="1">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')]" as="element()"/>
        <xsl:variable name="form" select="$container//form[contains-token(@class, 'sparql-query-form')]" as="element()"/>
        <xsl:variable name="textarea-id" select="$form//textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="$form//select[contains-token(@class, 'input-query-service')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="query-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="query-uri" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $query-id)" as="xs:anyURI"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string?"/>
        <xsl:variable name="forClass" select="xs:anyURI('&sp;' || upper-case(substring($query-type, 1, 1)) || lower-case(substring($query-type, 2)))" as="xs:anyURI"/>
        <xsl:variable name="container-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="container-uri" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $container-id)" as="xs:anyURI"/>
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:about="{$query-uri}">
                        <rdf:type rdf:resource="&sp;Query"/>
                        <rdf:type rdf:resource="{$forClass}"/>
<!--                        <dct:title><xsl:value-of select="$title-input/ixsl:get(., 'value')"/></dct:title>-->
                        <sp:text rdf:datatype="&xsd;string"><xsl:value-of select="$query-string"/></sp:text>

                        <xsl:if test="$service-uri">
                            <ldh:service rdf:resource="$service-uri"/>
                        </xsl:if>
                    </rdf:Description>
                    <rdf:Description rdf:about="{$container-uri}">
                        <rdf:type rdf:resource="&ldh;View"/>
                        <spin:query rdf:resource="{$query-uri}"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="content-id" select="$container/@id" as="xs:string"/>
        <xsl:variable name="content-uri" select="if ($container/@about) then $container/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $content-id)" as="xs:anyURI"/>
        <xsl:variable name="value" select="$constructor//*[@rdf:about = $container-uri]" as="element()"/>

        <!-- deactivate other tabs -->
        <xsl:for-each select="../../li">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="..">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <!-- create new cache entry using content URI as key -->
        <ixsl:set-property name="{'`' || $content-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        <!-- store this content element -->
        <ixsl:set-property name="content" select="$value" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>

        <xsl:for-each select="$container//div[@class = 'bar']">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'50%'" object="."/>
        </xsl:for-each>
                
        <xsl:apply-templates select="$value" mode="ldh:RenderBlock">
            <xsl:with-param name="this" select="id('content-body', ixsl:page())/@about"/>
            <xsl:with-param name="container" select="$container//div[contains-token(@class, 'sparql-query-results')]"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))"/>
            <xsl:with-param name="select-query" select="$constructor//*[@rdf:about = $query-uri]"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- start dragging content (or its descendants) -->
    
    <xsl:template match="div[ixsl:query-params()?mode = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]/descendant-or-self::*" mode="ixsl:ondragstart">
        <xsl:choose>
            <!-- allow drag on the content <div> -->
            <xsl:when test="self::div[contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]">
                <xsl:variable name="content-uri" select="@about" as="xs:anyURI"/>
                <ixsl:set-property name="dataTransfer.effectAllowed" select="'move'" object="ixsl:event()"/>
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'setData', [ 'text/uri-list', $content-uri ])"/>
            </xsl:when>
            <!-- prevent drag on its descendants. This makes sure that content drag-and-drop doesn't interfere with drag events in the Map and Graph modes -->
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- dragging content over other content -->
    
    <xsl:template match="div[ixsl:query-params()?mode = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragover">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <ixsl:set-property name="dataTransfer.dropEffect" select="'move'" object="ixsl:event()"/>
    </xsl:template>

    <!-- change the style of elements when content is dragged over them -->
    
    <xsl:template match="div[ixsl:query-params()?mode = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragenter">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', true() ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="div[ixsl:query-params()?mode = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragleave">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element drag entered (optional) -->

        <!-- only remove class if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- dropping content over other content -->
    
    <xsl:template match="div[ixsl:query-params()?mode = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondrop">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="." as="element()"/>
        <xsl:variable name="content-uri" select="@about" as="xs:anyURI?"/>
        <xsl:variable name="drop-content-uri" select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'getData', [ 'text/uri-list' ])" as="xs:anyURI"/>
        
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- only persist the change if the content is already saved and has an @about -->
        <xsl:if test="$content-uri">
            <!-- move dropped element after this element, if they're not the same -->
            <xsl:if test="not($content-uri = $drop-content-uri)">
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="drop-content" select="key('content-by-about', $drop-content-uri)" as="element()"/>
                <xsl:sequence select="ixsl:call(., 'after', [ $drop-content ])"/>

                <xsl:variable name="update-string" select="replace($content-swap-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$targetBlock', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$sourceBlock', '&lt;' || $drop-content-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                        <xsl:call-template name="onContentSwap">
                            <xsl:with-param name="container" select="$container"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- load content -->
    
    <xsl:template name="ldh:LoadBlock">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:variable name="this" select="ancestor::div[@about][1]/@about" as="xs:anyURI"/>
        <xsl:variable name="content-uri" select="(@about, $this)[1]" as="xs:anyURI"/> <!-- fallback to @about for charts, queries etc. -->
        <xsl:variable name="container" select="." as="element()"/>
        <xsl:variable name="progress-container" select="if (contains-token(@class, 'row-fluid')) then ./div[contains-token(@class, 'main')] else ." as="element()"/>

        <!-- container could be hidden server-side -->
        <ixsl:set-style name="display" select="'block'"/>
        
        <!-- show progress bar in the middle column -->
        <xsl:for-each select="$progress-container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="progress-bar">
                    <div class="progress progress-striped active">
                        <div class="bar" style="width: 25%;"></div>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:document-uri($content-uri))" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': ac:document-uri($request-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:BlockLoaded">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="acl-modes" select="$acl-modes"/>
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- embed content -->
    
    <xsl:template name="ldh:BlockLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        
        <!-- for some reason Saxon-JS 2.3 does not see this variable if it's inside <xsl:when> -->
        <xsl:variable name="block" select="key('resources', $content-uri, ?body)" as="element()?"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml' and $block">
                <xsl:variable name="results" select="?body" as="document-node()"/>
                <!-- create new cache entry using content URI as key -->
                <ixsl:set-property name="{'`' || $content-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                <!-- store this content element -->
                <ixsl:set-property name="content" select="$block" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>

                <xsl:for-each select="$container//div[@class = 'bar']">
                    <!-- update progress bar -->
                    <ixsl:set-style name="width" select="'50%'" object="."/>
                </xsl:for-each>

                <xsl:apply-templates select="$block" mode="ldh:RenderBlock">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                </xsl:apply-templates>
            
                <!-- initialize map -->
                <xsl:if test="key('elements-by-class', 'map-canvas', $container)">
                    <xsl:for-each select="$results">
                        <xsl:call-template name="ldh:DrawMap">
                            <xsl:with-param name="content-uri" select="$content-uri"/>
                            <xsl:with-param name="canvas-id" select="key('elements-by-class', 'map-canvas', $container)/@id" />
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                
                <!-- initialize chart -->
<!--                <xsl:for-each select="key('elements-by-class', 'chart-canvas', $container)">
                    <xsl:variable name="canvas-id" select="@id" as="xs:string"/>
                    <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
                    <xsl:variable name="category" as="xs:string?"/>
                    <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                    <xsl:variable name="data-table" select="ac:rdf-data-table($results, $category, $series)"/>

                    <xsl:call-template name="ldh:RenderChart">
                        <xsl:with-param name="data-table" select="$data-table"/>
                        <xsl:with-param name="canvas-id" select="$canvas-id"/>
                        <xsl:with-param name="chart-type" select="$chart-type"/>
                        <xsl:with-param name="category" select="$category"/>
                        <xsl:with-param name="series" select="$series"/>
                    </xsl:call-template>
                </xsl:for-each>-->
            </xsl:when>
            <!-- content could not be loaded from Linked Data, attempt a fallback to a DESCRIBE query over the local endpoint -->
            <!--
            <xsl:when test="?status = 502">
                <xsl:variable name="query-string" select="'DESCRIBE &lt;' || $content-uri || '&gt;'" as="xs:string"/>
                <xsl:variable name="results-uri" select="ac:build-uri($sd:endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': ac:document-uri($request-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                        <xsl:call-template name="ldh:BlockLoaded">
                            <xsl:with-param name="this" select="$this"/>
                            <xsl:with-param name="content-uri" select="$content-uri"/>
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="acl-modes" select="$acl-modes"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            -->
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content block: <a href="{$content-uri}"><xsl:value-of select="$content-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
                
                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- embed DESCRIBE/CONSTRUCT result -->
    
    <xsl:template name="onQueryContentLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <!-- hide progress bar -->
                    <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>

                    <xsl:variable name="row" as="element()*">
                        <xsl:apply-templates select="." mode="bs2:Row">
                            <xsl:with-param name="mode" select="$mode"/>
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:copy-of select="$row/*"/>
                        </xsl:result-document>
                    </xsl:for-each>

                    <xsl:call-template name="ldh:BlockRendered">
                        <xsl:with-param name="container" select="$container"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content resource: <a href="{$query-uri}"><xsl:value-of select="$query-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
                
                <xsl:call-template name="ldh:BlockRendered">
                    <xsl:with-param name="container" select="$container"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- resource content update -->
    
    <xsl:template name="onSPARQLContentUpdate">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-value" as="xs:anyURI"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="$container">
                    <!-- set @about attribute -->
                    <ixsl:set-attribute name="about" select="$content-uri"/>
<!--                     update @data-content-value value 
                    <ixsl:set-property name="dataset.contentValue" select="$content-value" object="."/>

                    <xsl:choose>
                        <xsl:when test="$mode">
                             update @data-content-mode value 
                            <ixsl:set-property name="dataset.contentMode" select="$mode" object="."/>
                        </xsl:when>
                        <xsl:when test="ixsl:contains(., 'dataset.contentMode')">
                             remove @data-content-mode 
                            <ixsl:remove-property name="dataset.contentMode" object="."/>
                        </xsl:when>
                    </xsl:choose>-->
                    
                    <xsl:call-template name="ldh:LoadBlock"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not update resource content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- content delete -->

    <xsl:template name="onContentDelete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = (200, 204)">
                <xsl:for-each select="$container">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not delete content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- content swap (drag & drop) -->
    
    <xsl:template name="onContentSwap">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:choose>
            <xsl:when test="?status = 204">
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not swap content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>