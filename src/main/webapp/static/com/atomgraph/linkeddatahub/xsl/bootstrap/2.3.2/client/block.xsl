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
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE
            {
                $this ?seq $block .
                $block ?p ?o .
            }
            WHERE
            {
                $this ?seq $block .
                FILTER(strstarts(str(?seq), concat(str(rdf:), "_")))
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

    <xsl:template match="*[@typeof = ('&sp;Ask', '&sp;Select', '&sp;Describe', '&sp;Construct')][descendant::*[@property = '&sp;text'][text()]]" mode="ldh:RenderBlock" priority="1">
        <xsl:param name="block" select="ancestor::*[@about][1]" as="element()"/>
        <xsl:param name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:param name="block-uri" select="$about" as="xs:anyURI"/>
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="show-edit-button" select="false()" as="xs:boolean?"/>
        <xsl:param name="textarea-id" select="generate-id() || '-textarea'" as="xs:string"/>
        <xsl:param name="service-uri" select="descendant::*[@property = '&ldh;service']/@resource" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="string(descendant::*[@property = '&sp;text'])" as="xs:string"/>
        <xsl:param name="show-properties" select="false()" as="xs:boolean"/>
        <xsl:param name="forClass" select="xs:anyURI('&sd;Service')" as="xs:anyURI"/>
        
        <xsl:message>
            Query ldh:RenderBlock @typeof: <xsl:value-of select="@typeof"/> $about: <xsl:value-of select="$about"/>
            $service-uri: <xsl:value-of select="$service-uri"/>
        </xsl:message>
        
        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <ixsl:set-style name="width" select="'66%'" object="."/>
        </xsl:for-each>

        <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
            <xsl:result-document href="?." method="ixsl:append-content">
                <form class="sparql-query-form form-horizontal" method="get" action="">
                    <div class="control-group">
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'pu'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                            <xsl:with-param name="value" select="'&ldh;service'"/>
                        </xsl:call-template>

                        <label class="control-label">
                            <xsl:apply-templates select="key('resources', '&ldh;service', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                        </label>
                        <div class="controls">
                            <xsl:choose>
                                <xsl:when test="$service-uri">
                                    <!-- need to explicitly request RDF/XML, otherwise we get HTML -->
                                    <xsl:variable name="request-uri" select="ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                                    <xsl:message>
                                        $request-uri: <xsl:value-of select="$request-uri"/>
                                    </xsl:message>
                                    <!-- TO-DO: refactor asynchronously -->
                                    <xsl:apply-templates select="key('resources', $service-uri, document($request-uri))" mode="ldh:Typeahead">
                                        <xsl:with-param name="forClass" select="$forClass"/>
                                    </xsl:apply-templates>

                                    <!--
                                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $query-uri)" as="xs:anyURI"/>
                                    <xsl:variable name="request" as="item()*">
                                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                            <xsl:call-template name="onQueryServiceLoad">
                                                <xsl:with-param name="container" select="$container"/>
                                                <xsl:with-param name="forClass" select="$forClass"/>
                                                <xsl:with-param name="service-uri" select="$service-uri"/>
                                            </xsl:call-template>
                                        </ixsl:schedule-action>
                                    </xsl:variable>
                                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                                    -->
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="bs2:Lookup">
                                        <xsl:with-param name="forClass" select="$forClass"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </div>

                    <textarea id="{$textarea-id}" name="query" class="span12 sparql-query-string" rows="15">
                        <xsl:value-of select="$query"/>
                    </textarea>

                    <div class="form-actions">
                        <button type="submit">
                            <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn btn-primary btn-run-query'"/>
                            </xsl:apply-templates>

                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="button" class="btn btn-primary btn-open-query">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'open', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="button" class="btn btn-primary btn-save btn-save-query">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </form>
            </xsl:result-document>
        </xsl:for-each>
        
        <xsl:apply-templates select="." mode="ldh:PostConstruct"/>
    </xsl:template>
    
    <!-- object block (RDF resource) -->
    
    <xsl:template match="*[@typeof = '&ldh;Object'][descendant::*[@property = '&rdf;value'][@resource]]" mode="ldh:RenderBlock" priority="1">
        <xsl:param name="block" select="ancestor::*[@about][1]" as="element()"/>
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
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>
        
        <!-- don't use ldh:base-uri(.) because its value comes from the last HTML document load -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, if (starts-with($graph, $ldt:base)) then $graph else ac:absolute-path(xs:anyURI(ixsl:location())), map{}, ac:document-uri($resource-uri), $graph, ())" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:LoadBlockObjectValue">
<!--                    <xsl:with-param name="this" select="$about"/>-->
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
                    </xsl:apply-templates>
                </xsl:variable>

            <!--
            <xsl:message>
                ldh:LoadBlockObjectMetadata $resource: <xsl:value-of select="serialize($resource)"/>
                ldh:LoadBlockObjectMetadata $row: <xsl:value-of select="serialize($row)"/>
            </xsl:message>
            -->
        
                <!-- hide the row with the block controls -->
                <ixsl:set-style name="z-index" select="'-1'" object="key('elements-by-class', 'row-block-controls', $block)"/>
                
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <!-- wrap the row -->
                        <div class="span12">
                            <xsl:copy-of select="$row"/>
                        </div>
                    </xsl:result-document>
                    
                    <xsl:apply-templates mode="ldh:RenderBlock"/> <!-- recurse down the block hierarchy -->
                </xsl:for-each>
                
                <!-- hide the progress bar -->
                <xsl:for-each select="$block/div[contains-token(@class, 'span12')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->
    
    <!-- show block controls -->
    
    <xsl:template match="div[contains-token(@class, 'block')]" mode="ixsl:onmousemove"> <!-- TO-DO: better selector -->
        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')" as="xs:double"/>
        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')" as="xs:double"/>
        <xsl:variable name="bound" select="ixsl:call(., 'getBoundingClientRect', [])"/>
        <xsl:variable name="offset-x" select="$dom-x - ixsl:get($bound, 'x')" as="xs:double"/>
        <xsl:variable name="offset-y" select="$dom-y - ixsl:get($bound, 'y')" as="xs:double"/>
        <xsl:variable name="offset-x-treshold" select="120" as="xs:double"/>
        <xsl:variable name="offset-y-treshold" select="20" as="xs:double"/>

<!--        <xsl:message>
            .block onmousemove @id: <xsl:value-of select="@id"/> $offset-y: <xsl:value-of select="$offset-y"/>
        </xsl:message>-->
        
        <xsl:variable name="row-block-controls" select="key('elements-by-class', 'row-block-controls', .)" as="element()"/>
        <xsl:message>
            .row-block-controls z-index: <xsl:value-of select="ixsl:style($row-block-controls)?z-index"/>
            $offset-x: <xsl:value-of select="$offset-x"/> $offset-y: <xsl:value-of select="$offset-y"/>
        </xsl:message>
        <!-- check that the mouse is on the top edge and show the block controls if they're not already shown -->
        <xsl:if test="$offset-x &lt;= $offset-x-treshold and $offset-y &lt;= $offset-y-treshold and ixsl:style($row-block-controls)?z-index = '-1'">
            <ixsl:set-style name="z-index" select="'1'" object="$row-block-controls"/>
        </xsl:if>
        <!-- check that the mouse is outside the top edge and hide the block controls if they're not already hidden -->
        <xsl:if test="$offset-x &gt; $offset-x-treshold and $offset-y &gt; $offset-y-treshold and ixsl:style($row-block-controls)?z-index = '1'">
            <ixsl:set-style name="z-index" select="'-1'" object="$row-block-controls"/>
        </xsl:if>
    </xsl:template>

    <!-- override inline editing form for content types (do nothing if the button is disabled) - prioritize over form.xsl -->
    
    <xsl:template match="div[following-sibling::div[@typeof = ('&ldh;XHTML', '&ldh;View', '&ldh;Object')]]//button[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick" priority="1">
        <xsl:param name="block" select="ancestor::div[@about][1]" as="element()"/>
        <!-- for content types, button.btn-edit is placed in its own div.row-fluid, therefore the next row is the actual container -->
        <xsl:param name="container" select="$block/descendant::div[@typeof][1]" as="element()"/> <!-- other resources can be nested within object -->

        <xsl:message>
            content types .btn-edit onclick
            $container: <xsl:value-of select="serialize($container)"/>
        </xsl:message>
        
        <xsl:next-match>
<!--            <xsl:with-param name="container" select="$container"/>-->
        </xsl:next-match>
    </xsl:template>
    
    <!-- append new block form onsubmit (using POST) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;View', '&ldh;Object')]//form[contains-token(@class, 'form-horizontal')][upper-case(@method) = 'POST']" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:param name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:param name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI(.//input[@name = 'su'] => ixsl:get('value'))" as="xs:anyURI"/>
        <xsl:variable name="sequence-number" select="count($block/preceding-sibling::div[@about]) + 1" as="xs:integer"/>
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
            <xsl:with-param name="block" select="$block"/>
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
    <!-- TO-DO: use @typeof in match so that we don't need a custom button.btn-save-query class -->
    
    <xsl:template match="div[@typeof]//button[contains-token(@class, 'btn-save-query')]" mode="ixsl:onclick">
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="about" select="$block/@about" as="xs:anyURI"/>
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

        <!-- replace the query string (sp:text value) on the query resource -->
        <xsl:variable name="query" as="element()">
            <xsl:apply-templates select="$query" mode="ldh:SetQueryString">
                <xsl:with-param name="query-string" select="$query-string" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="triples" select="ldh:descriptions-to-triples($query)" as="element()*"/>
        <xsl:message>
            $query: <xsl:value-of select="serialize($query)"/>
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
                    <xsl:with-param name="block" select="$block"/>
                    <xsl:with-param name="container" select="$container"/>
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
    
    <xsl:template match="button[contains-token(@class, 'btn-open-query')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
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
    
    <xsl:template match="div[@about][@typeof]//button[contains-token(@class, 'btn-save-chart')]" mode="ixsl:onclick">
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="textarea-id" select="$container//textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('query-service'), 'value'))" as="xs:anyURI?"/> <!-- TO-DO: fix content-embedded queries -->
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string"/>
        <xsl:variable name="forClass" select="if ($query-type = ('SELECT', 'ASK')) then xs:anyURI('&ldh;ResultSetChart') else xs:anyURI('&ldh;GraphChart')" as="xs:anyURI"/>
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

        <xsl:message>SAVE CHART query URI: <xsl:value-of select="$container/@about"/></xsl:message>
        
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description>
                        <rdf:type rdf:resource="{$forClass}"/>
                        <dct:title rdf:nodeID="title"/>
                        <ldh:chartType rdf:resource="{$chart-type}"/>
                        <ldh:categoryVarName><xsl:value-of select="$category"/></ldh:categoryVarName>
                        <xsl:for-each select="$series">
                            <ldh:seriesVarName><xsl:value-of select="."/></ldh:seriesVarName>
                        </xsl:for-each>
                        <spin:query rdf:resource="{$container/@about}"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="title">
                        <rdf:type rdf:resource="&xsd;string"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        
        <xsl:message>Save chart $constructor: <xsl:value-of select="serialize($constructor)"/></xsl:message>
    </xsl:template>
    
    <!-- delete content onclick (increased priority to take precedence over form.xsl .btn-remove-resource) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;View', '&ldh;Object')]//button[contains-token(@class, 'btn-remove-resource')]" mode="ixsl:onclick" priority="3">
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>

        <xsl:choose>
            <!-- delete existing content -->
            <xsl:when test="$block/@about">
                <!-- show a confirmation prompt -->
                <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))) ])">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <xsl:variable name="block-uri" select="$block/@about" as="xs:anyURI"/>
                    <xsl:variable name="update-string" select="replace($content-delete-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$block', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="onBlockDelete">
                                <xsl:with-param name="block" select="$block"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:when>
            <!-- remove content that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- XHTML block cancel onclick - prioritize over resource content -->
    
    <xsl:template match="div[@typeof = '&ldh;XHTML']//button[contains-token(@class, 'btn-cancel')]" mode="ixsl:onclick" priority="2">
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>

        <xsl:message>XHTML block cancel onclick</xsl:message>
        
        <xsl:choose>
            <!-- restore existing block -->
            <xsl:when test="$block/@about">
                <xsl:variable name="textarea" select="ancestor::div[contains-token(@class, 'main')]//textarea[contains-token(@class, 'wymeditor')]" as="element()"/>
                <xsl:variable name="old-xhtml-string" select="string($textarea)" as="xs:string"/>
                <xsl:variable name="xhtml" select="ldh:parse-html('&lt;div&gt;' || $old-xhtml-string || '&lt;/div&gt;', 'application/xhtml+xml')" as="document-node()"/>

                <xsl:for-each select="$container/div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:copy-of select="$xhtml"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <!-- remove block that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- resource content/SPARQL content cancel onclick -->
    
    <xsl:template match="div[@typeof = ('&ldh;View', '&ldh;Object')]//button[contains-token(@class, 'btn-cancel')]" mode="ixsl:onclick" priority="1"> <!-- prioritize over form.xsl -->
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>
<!--        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>-->

        <xsl:message>resource block</xsl:message>

        <xsl:choose>
            <!-- updating existing block -->
            <xsl:when test="$block/@about">
                <xsl:for-each select="$block">
                    <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(xs:anyURI(ixsl:location())) || '`'), 'results')" as="document-node()"/>
                    <!-- TO-DO: restore block HTML from cache -->
                    <!-- 
                    <xsl:apply-templates select="." mode="ldh:LoadBlock">
                        <xsl:with-param name="doc" select="$doc"/>
                    </xsl:apply-templates>
                    -->
                </xsl:for-each>
            </xsl:when> 
            <!-- remove content that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'add-constructor')][@data-for-class = '&ldh;XHTML']" mode="ixsl:onclick" priority="2">  prioritize over form.xsl 
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')][1]" as="element()"/>

        <xsl:message>
            ldh:XHTML .add-constructor onclick
        </xsl:message>
        
         call the default handler in form.xsl 
        <xsl:next-match/>
        
        <xsl:message>Toggle .content.xhtml-content</xsl:message>
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'xhtml-content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
     appends new resource block to the content list 
    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'add-constructor')][@data-for-class = ('&ldh;View', '&ldh;Object')]" mode="ixsl:onclick" priority="2">  prioritize over form.xsl 
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')][1]" as="element()"/>
    
         call the default handler in form.xsl 
        <xsl:next-match/>
        
        <xsl:message>Toggle .content</xsl:message>
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>-->
    
    <!-- submit SPARQL query form (prioritize over default template in form.xsl) -->
    
    <xsl:template match="div[@typeof = ('&sp;Ask', '&sp;Select', '&sp;Describe', '&sp;Construct')]//form[contains-token(@class, 'sparql-query-form ')]" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:message>.sparql-query-form onsubmit</xsl:message>
        <xsl:variable name="textarea-id" select="descendant::textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-control-group" select="descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&ldh;service']]" as="element()"/>
        <xsl:variable name="service-uri" select="$service-control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>
        <xsl:variable name="container" select="$block" as="element()"/> <!-- since we're not in content mode -->
        <xsl:variable name="block-id" select="$block/@id" as="xs:string"/>
        <xsl:variable name="block-uri" select="if ($block/@about) then $block/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $block-id)" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $ldt:base, map{}, $results-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }" as="map(xs:string, item())"/>

        <xsl:message>
            $service-uri: <xsl:value-of select="$service-uri"/>
            $endpoint: <xsl:value-of select="$endpoint"/>
        </xsl:message>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="$request">
                <xsl:call-template name="onSPARQLResultsLoad">
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="results-uri" select="$results-uri"/>
                    <xsl:with-param name="block-uri" select="$block-uri"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="chart-canvas-id" select="$block-id || '-chart-canvas'"/>
                    <xsl:with-param name="results-container-id" select="$block-id || '-query-results'"/>
                    <xsl:with-param name="query-string" select="$query-string"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- toggle query results to chart mode (prioritize over container.xsl) -->
    
    <xsl:template match="ul[contains-token(@class, 'nav-tabs')][contains-token(@class, 'nav-query-results')]/li[contains-token(@class, 'chart-mode')][not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick" priority="1">
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
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
    
    <xsl:template match="ul[contains-token(@class, 'nav-tabs')][contains-token(@class, 'nav-query-results')]/li[contains-token(@class, 'container-mode')][not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick" priority="1">
        <xsl:variable name="block" select="ancestor::div[@about][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
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
        <xsl:variable name="block-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="block-uri" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $block-id)" as="xs:anyURI"/>
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
                    <rdf:Description rdf:about="{$block-uri}">
                        <rdf:type rdf:resource="&ldh;View"/>
                        <spin:query rdf:resource="{$query-uri}"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="value" select="$constructor//*[@rdf:about = $block-uri]" as="element()"/>

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
        <ixsl:set-property name="{'`' || $block-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        <!-- store this content element -->
        <ixsl:set-property name="content" select="$value" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <!-- update progress bar -->
            <ixsl:set-style name="width" select="'50%'" object="."/>
        </xsl:for-each>
                
        <xsl:apply-templates select="$value" mode="ldh:RenderBlock">
            <xsl:with-param name="this" select="ancestor::div[@about][1]/@about"/>
            <xsl:with-param name="container" select="$container//div[contains-token(@class, 'sparql-query-results')]"/>
            <xsl:with-param name="block-uri" select="$block-uri"/>
            <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))"/>
            <xsl:with-param name="select-query" select="$constructor//*[@rdf:about = $query-uri]"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- start dragging content (or its descendants) -->
    
    <xsl:template match="div[contains-token(@class, 'container-fluid')]/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'row-fluid')]/descendant-or-self::*" mode="ixsl:ondragstart">
        <xsl:message>ixsl:ondragstart</xsl:message>
        
        <xsl:choose>
            <!-- allow drag on the block element itself -->
            <xsl:when test="self::div[@typeof][contains-token(@class, 'row-fluid')]">
                <ixsl:set-property name="dataTransfer.effectAllowed" select="'move'" object="ixsl:event()"/>
                <xsl:variable name="block-uri" select="@about" as="xs:anyURI"/>
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'setData', [ 'text/uri-list', $block-uri ])"/>
            </xsl:when>
            <!-- prevent drag on its descendants. This makes sure that content drag-and-drop doesn't interfere with drag events in the Map and Graph modes -->
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- dragging content over other content -->
    
    <xsl:template match="div[contains-token(@class, 'container-fluid')]/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragover">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <ixsl:set-property name="dataTransfer.dropEffect" select="'move'" object="ixsl:event()"/>
    </xsl:template>

    <!-- change the style of elements when content is dragged over them -->
    
    <xsl:template match="div[contains-token(@class, 'container-fluid')]/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragenter">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', true() ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="div[contains-token(@class, 'container-fluid')]/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragleave">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element drag entered (optional) -->

        <!-- only remove class if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- dropping content over other content -->
    
    <xsl:template match="div[contains-token(@class, 'container-fluid')]/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][acl:mode() = '&acl;Write']" mode="ixsl:ondrop">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="block-uri" select="@about" as="xs:anyURI?"/>
        <xsl:variable name="drop-block-uri" select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'getData', [ 'text/uri-list' ])" as="xs:anyURI"/>
        <xsl:message>ixsl:ondrop $drop-block-uri: <xsl:value-of select="$drop-block-uri"/></xsl:message>
        
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- only persist the change if the content is already saved and has an @about -->
        <xsl:if test="$block-uri">
            <!-- move dropped element after this element, if they're not the same -->
            <xsl:if test="not($block-uri = $drop-block-uri)">
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="drop-content" select="key('content-by-about', $drop-block-uri)" as="element()"/>
                <xsl:sequence select="ixsl:call(., 'after', [ $drop-content ])"/>
                <!-- TO-DO: use a VALUES block instead -->
                <xsl:variable name="update-string" select="replace($content-swap-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$targetBlock', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$sourceBlock', '&lt;' || $drop-block-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                        <xsl:call-template name="onBlockSwap"/>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
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
                    <!-- <ixsl:set-style name="display" select="'none'" object="$block//div[@class = 'progress-bar']"/> -->

                    <xsl:variable name="row" as="element()*">
                        <xsl:apply-templates select="." mode="bs2:Row">
                            <xsl:with-param name="mode" select="$mode"/>
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:copy-of select="$row/*"/>
                        </xsl:result-document>
                        
<!--                        <xsl:apply-templates select="." mode="ldh:BlockRendered"/>-->
                    </xsl:for-each>
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
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- resource content update -->
    
<!--    <xsl:template name="onSPARQLContentUpdate">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-value" as="xs:anyURI"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="$container">
                     set @about attribute 
                    <ixsl:set-attribute name="about" select="$content-uri"/>

                    <xsl:call-template name="ldh:LoadBlock"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not update resource content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    
    <!-- content delete -->

    <xsl:template name="onBlockDelete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="block" as="element()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = (200, 204)">
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not delete content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- content swap (drag & drop) -->
    
    <xsl:template name="onBlockSwap">
        <xsl:context-item as="map(*)" use="required"/>

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