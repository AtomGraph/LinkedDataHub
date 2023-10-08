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
xmlns:geo="&geo;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:variable name="content-append-string" as="xs:string">
        <!-- same as in append-content.sh CLI script -->
        <![CDATA[
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX  ac:   <https://w3id.org/atomgraph/client#>
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>

            INSERT
            {
                $this ?property $content .
                $content a ldh:Content ;
                    rdf:value $value ;
                    ac:mode $mode .
            }
            WHERE
            {
                { SELECT  (( MAX(?index) + 1 ) AS ?next)
                  WHERE
                    { $this
                                ?seq      ?oldContent .
                      ?oldContent  a  ldh:Content
                      BIND(xsd:integer(substr(str(?seq), 45)) AS ?index)
                    }
                }
                BIND(iri(concat(str(rdf:), "_", str(coalesce(?next, 1)))) AS ?property)
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="content-update-string" as="xs:string">
        <![CDATA[
            PREFIX ldh: <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX ac:  <https://w3id.org/atomgraph/client#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE
            {
                $this ?seq $content .
                $content a ldh:Content ;
                    rdf:value ?oldValue ;
                    ac:mode ?oldMode .
            }
            INSERT
            {
                $this ?seq $content .
                $content a ldh:Content ;
                    rdf:value $newValue ;
                    ac:mode $newMode .
            }
            WHERE
            {
                $this ?seq $content .
                $content a ldh:Content ;
                    rdf:value ?oldValue .
                OPTIONAL
                {
                    $content ac:mode ?oldMode
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="content-delete-string" as="xs:string">
        <![CDATA[
            PREFIX ldh: <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX  ac: <https://w3id.org/atomgraph/client#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE
            {
                $this ?seq $content .
                $content a ldh:Content ;
                    rdf:value ?value ;
                    ac:mode ?mode .
            }
            WHERE
            {
                $this ?seq $content .
                $content a ldh:Content ;
                    rdf:value ?value .
                OPTIONAL
                {
                    $content ac:mode ?mode
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="content-swap-string" as="xs:string">
        <![CDATA[
            PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX  ac:   <https://w3id.org/atomgraph/client#>
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE {
              $this ?sourceSeq $sourceContent .
              $this ?targetSeq $targetContent .
              $this ?seq ?content .
            }
            INSERT {
              $this ?newSourceSeq $sourceContent .
              $this ?newTargetSeq $targetContent .
              $this ?newSeq ?content .
            }
            WHERE
              { $this  ?sourceSeq  $sourceContent
                BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                $this  ?targetSeq  $targetContent
                BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ( ?targetIndex - 1 ), ?targetIndex) AS ?newTargetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ?targetIndex, ( ?targetIndex + 1 )) AS ?newSourceIndex)
                BIND(IRI(concat(str(rdf:), "_", str(?newSourceIndex))) AS ?newSourceSeq)
                BIND(IRI(concat(str(rdf:), "_", str(?newTargetIndex))) AS ?newTargetSeq)
                OPTIONAL
                  { $this  ?sourceSeq  $sourceContent
                    BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                    $this  ?targetSeq  $targetContent
                    BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                    $this  ?seq  ?content
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

    <!-- SELECT query -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&sp;Select'][sp:text]" mode="ldh:RenderContent" priority="1">
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="content-uri" select="xs:anyURI($container/@about)" as="xs:anyURI"/>
        <!-- set $this variable value unless getting the query string from state -->
        <xsl:param name="select-string" select="replace(sp:text, '$this', '&lt;' || $this || '&gt;', 'q')" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()">
            <xsl:variable name="select-json" as="item()">
                <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
            </xsl:variable>
            <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
            <xsl:sequence select="json-to-xml($select-json-string)"/>
        </xsl:param>
        <xsl:param name="initial-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <xsl:param name="focus-var-name" select="$initial-var-name" as="xs:string"/>
        <!-- service can be explicitly specified on content using ldh:service -->
        <xsl:param name="service-uri" select="xs:anyURI(ldh:service/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:param name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:param name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        
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
                    <ixsl:set-style name="width" select="'75%'" object="."/>
                </xsl:for-each>

                <xsl:call-template name="ldh:RenderContainer">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="content" select="."/>
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
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- DESCRIBE/CONSTRUCT queries -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&sp;Describe', '&sp;Construct')][sp:text]" mode="ldh:RenderContent" priority="1">
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="content-uri" select="xs:anyURI($container/@about)" as="xs:anyURI"/>
        <!-- set $this variable value unless getting the query string from state -->
        <xsl:param name="query-string" select="replace(sp:text, '$this', '&lt;' || $this || '&gt;', 'q')" as="xs:string"/>
        <!-- service can be explicitly specified on content using ldh:service -->
        <xsl:param name="service-uri" select="xs:anyURI(ldh:service/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:param name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:param name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>

        <xsl:choose>
            <!-- service URI is not specified or specified and can be loaded -->
            <xsl:when test="not($service-uri) or ($service-uri and exists($service))">
                <!-- window.LinkedDataHub.contents[{$content-uri}] object is already created -->
                <xsl:if test="$service-uri">
                    <!-- store (the URI of) the service -->
                    <ixsl:set-property name="service-uri" select="$service-uri" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                    <ixsl:set-property name="service" select="$service" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                </xsl:if>

                <!-- update progress bar -->
                <xsl:for-each select="$container//div[@class = 'bar']">
                    <ixsl:set-style name="width" select="'75%'" object="."/>
                </xsl:for-each>

                <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $results-uri)" as="xs:anyURI"/>
                
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="onQueryContentLoad">
                        <xsl:with-param name="container" select="$container"/>
                        <xsl:with-param name="query-uri" select="@rdf:about"/>
                        <xsl:with-param name="mode" select="$mode"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- .xhtml-content referenced from .resource-content (XHTML transclusion) -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;Content'][rdf:value[@rdf:parseType = 'Literal']/xhtml:div]" mode="ldh:RenderContent" priority="1">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>

        <!-- hide progress bar -->
        <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>

        <xsl:variable name="row" as="node()*">
            <xsl:apply-templates select="." mode="bs2:RowContent">
                <xsl:with-param name="class" select="'content xhtml-content'"/> <!-- no .row-fluid -->
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="transclude" select="true()"/>
                <xsl:with-param name="base" select="ac:document-uri(@rdf:about)"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$row"/> <!-- inject the content of div.row-fluid -->
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="ldh:ContentLoaded">
            <xsl:with-param name="container" select="$container"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- default content (RDF resource) -->
    
    <xsl:template match="*[*][@rdf:about]" mode="ldh:RenderContent">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>

        <!-- hide progress bar -->
        <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>
        
        <xsl:variable name="row" as="node()*">
            <xsl:apply-templates select="." mode="bs2:Row">
                <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$row/*"/> <!-- inject the content of div.row-fluid -->
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="ldh:ContentLoaded">
            <xsl:with-param name="container" select="$container"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="ldh:ContentLoaded">
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
    
    <!-- XHTML content edit button onclick -->
    <!-- Should not be triggered for embedded XHTML (.resource-content .xhtml-content), that's why we check we're at .row-fluid level -->
    
    <xsl:template match="div[contains-token(@class, 'xhtml-content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-edit')]" mode="ixsl:onclick">
        <xsl:variable name="button" select="." as="element()"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'xhtml-content')][contains-token(@class, 'row-fluid')]" as="element()"/>

        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description>
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:parseType="Literal">
                            <xsl:copy-of select="$container/div[contains-token(@class, 'main')]/*[not(. is $button)]"/> <!-- filter out the "Edit" button -->
                        </rdf:value>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="controls" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:value/xhtml:*" mode="bs2:FormControl"/>
        </xsl:variable>
        
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:for-each select="$container/div[contains-token(@class, 'left-nav')]">
                    <xsl:copy-of select="."/>
                </xsl:for-each>
                
                <xsl:for-each select="$container/div[contains-token(@class, 'main')]">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>

                        <div>
                            <xsl:copy-of select="$controls"/>
                        </div>

                        <div class="form-actions">
                            <button type="button" class="btn btn-primary btn-save">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                            <button type="button" class="btn btn-delete">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'delete', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                            <button type="button" class="btn btn-cancel">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                        </div>
                    </xsl:copy>
                </xsl:for-each>
                
                <xsl:for-each select="$container/div[contains-token(@class, 'right-nav')]">
                    <xsl:copy-of select="."/>
                </xsl:for-each>
            </xsl:result-document>
            
            <!-- initialize wymeditor textarea -->
            <xsl:apply-templates select="key('elements-by-class', 'wymeditor', .)" mode="ldh:PostConstruct"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- resource content edit button onclick -->
    
    <xsl:template match="div[contains-token(@class, 'resource-content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-edit')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'resource-content')][contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="content-value" select="ixsl:get($container, 'dataset.contentValue')" as="xs:anyURI"/> <!-- get the value of the @data-content-value attribute -->
        <xsl:variable name="mode" select="if (ixsl:contains($container, 'dataset.contentMode')) then xs:anyURI(ixsl:get($container, 'dataset.contentMode')) else ()" as="xs:anyURI?"/> <!-- get the value of the @data-content-mode attribute -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $content-value)"/>
        <!-- if this .resource-content transcludes .xhtml-content, redefine content container as the inner .xhtml-content -->
        <xsl:variable name="content-container" select="if ($container/div[contains-token(@class, 'xhtml-content')]) then $container/div[contains-token(@class, 'xhtml-content')] else $container" as="element()"/>

        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="A1">
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:nodeID="A2"/>
                        <ac:mode rdf:nodeID="A3"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A2">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A3">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="controls" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:value/@rdf:*" mode="bs2:FormControl"/>
            <xsl:apply-templates select="$constructor//ac:mode/@rdf:*" mode="bs2:FormControl">
                <xsl:with-param name="class" select="'content-mode'"/>
                <xsl:with-param name="type-label" select="false()"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:for-each select="$content-container/div[contains-token(@class, 'left-nav')]">
                    <xsl:copy-of select="."/>
                </xsl:for-each>

                <xsl:for-each select="$content-container/div[contains-token(@class, 'main')]">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        
                        <div>
                            <xsl:copy-of select="$controls"/>
                        </div>

                        <div class="form-actions">
                            <button type="button" class="btn btn-primary btn-save">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                            <button type="button" class="btn btn-delete">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'delete', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                            <button type="button" class="btn btn-cancel">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                        </div>
                    </xsl:copy>
                    
                    <xsl:for-each select="$content-container/div[contains-token(@class, 'right-nav')]">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:result-document>
        </xsl:for-each>
        
        <xsl:if test="$mode">
            <!-- set the select.content-mode value to $mode and remove its @name -->
            <xsl:for-each select="key('elements-by-class', 'content-mode', $container)">
                <ixsl:set-property name="value" select="$mode" object="."/>
                <ixsl:remove-attribute name="name"/>
            </xsl:for-each>
        </xsl:if>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onTypeaheadResourceLoad">
                    <xsl:with-param name="resource-uri" select="$content-value"/>
                    <xsl:with-param name="typeahead-span" select="$container/div[contains-token(@class, 'main')]//span[1]"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- save XHTML content onclick -->
    
    <xsl:template match="div[contains-token(@class, 'xhtml-content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'xhtml-content')][contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="textarea" select="ancestor::div[contains-token(@class, 'main')]//textarea[contains-token(@class, 'wymeditor')]" as="element()"/>
        <xsl:variable name="old-content-string" select="string($textarea)" as="xs:string"/>
        <xsl:variable name="wymeditor" select="ixsl:call(ixsl:get(ixsl:window(), 'jQuery'), 'getWymeditorByTextarea', [ $textarea ])" as="item()"/>
        <!-- update the textarea with WYMEditor content -->
        <xsl:sequence select="ixsl:call($wymeditor, 'update', [])[current-date() lt xs:date('2000-01-01')]"/> <!-- update HTML in the textarea -->
        <xsl:variable name="content-string" select="ixsl:call(ixsl:call(ixsl:window(), 'jQuery', [ $textarea ]), 'val', [])" as="xs:string"/>
        <xsl:variable name="content-value" select="ldh:parse-html('&lt;div&gt;' || $content-string || '&lt;/div&gt;', 'application/xhtml+xml')" as="document-node()"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:choose>
            <!-- updating existing content -->
            <xsl:when test="$container/@about">
                <xsl:variable name="content-uri" select="$container/@about" as="xs:anyURI"/>
                <xsl:variable name="update-string" select="replace($content-update-string, '$this', '&lt;' || ldh:base-uri(.) || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$content', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$newValue', '&quot;' || $content-string || '&quot;^^&lt;&rdf;XMLLiteral&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ldh:base-uri(.))" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                        <xsl:call-template name="onXHTMLContentUpdate">
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="content-value" select="$content-value"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- appending new content -->
            <xsl:otherwise>
                <xsl:variable name="content-id" select="'id' || ac:uuid()" as="xs:string"/>
                <xsl:variable name="content-uri" select="xs:anyURI(ldh:base-uri(.) || '#' || $content-id)" as="xs:anyURI"/> <!-- build content URI -->
                <ixsl:set-attribute name="id" select="$content-id" object="$container"/>
                <ixsl:set-attribute name="about" select="$content-uri" object="$container"/>

                <xsl:variable name="update-string" select="replace($content-append-string, '$this', '&lt;' || ldh:base-uri(.) || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$content', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$value', '&quot;' || $content-string || '&quot;^^&lt;&rdf;XMLLiteral&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ldh:base-uri(.))" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                        <xsl:call-template name="onXHTMLContentUpdate">
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="content-value" select="$content-value"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- save resource-content onclick -->
    
    <xsl:template match="div[contains-token(@class, 'resource-content')][contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'resource-content')][contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="old-content-value" select="ixsl:get($container, 'dataset.contentValue')" as="xs:anyURI"/>
        <xsl:variable name="content-value" select="ixsl:get($container//div[contains-token(@class, 'main')]//input[@name = 'ou'], 'value')" as="xs:anyURI"/>
        <xsl:variable name="mode" select="ixsl:get(key('elements-by-class', 'content-mode', $container), 'value')" as="xs:anyURI?"/>

        <xsl:choose>
            <!-- input values missing, throw an error -->
            <xsl:when test="exists($container/descendant::input[contains-token(@class, 'resource-typeahead')][@name = 'ou'][not(ixsl:get(., 'value'))])">
                <ixsl:set-style name="border-color" select="'#ff0039'" object="$container/descendant::input[contains-token(@class, 'resource-typeahead')][@name = 'ou'][not(ixsl:get(., 'value'))]"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:choose>
                    <!-- updating existing content -->
                    <xsl:when test="$container/@about">
                        <xsl:variable name="content-uri" select="$container/@about" as="xs:anyURI"/>
                        <xsl:variable name="update-string" select="replace($content-update-string, '$this', '&lt;' || ldh:base-uri(.) || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$content', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$newValue', '&lt;' || $content-value || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="if ($mode) then replace($update-string, '$newMode', '&lt;' || $mode || '&gt;', 'q') else $update-string" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ldh:base-uri(.))" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                                <xsl:call-template name="onResourceContentUpdate">
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="uri" select="ldh:base-uri(.)"/>
                                    <xsl:with-param name="content-value" select="$content-value"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:when> 
                    <!-- appending new content -->
                    <xsl:otherwise>
                        <xsl:variable name="content-id" select="'id' || ac:uuid()" as="xs:string"/>
                        <xsl:variable name="content-uri" select="xs:anyURI(ldh:base-uri(.) || '#' || $content-id)" as="xs:anyURI"/> <!-- build content URI -->
                        <ixsl:set-attribute name="id" select="$content-id" object="$container"/>
                        <ixsl:set-attribute name="about" select="$content-uri" object="$container"/>

                        <xsl:variable name="update-string" select="replace($content-append-string, '$this', '&lt;' || ldh:base-uri(.) || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$content', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$value', '&lt;' || $content-value || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="if ($mode) then replace($update-string, '$mode', '&lt;' || $mode || '&gt;', 'q') else $update-string" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ldh:base-uri(.))" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                                <xsl:call-template name="onResourceContentUpdate">
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="uri" select="ldh:base-uri(.)"/>
                                    <xsl:with-param name="content-value" select="$content-value"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- delete content onclick (increased priority to take precedence over document's .btn-delete) -->
    
    <xsl:template match="div[contains-token(@class, 'content')]//button[contains-token(@class, 'btn-delete')]" mode="ixsl:onclick" priority="1">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'content')]" as="element()"/>

        <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))) ])">
            <xsl:choose>
                <!-- delete existing content -->
                <xsl:when test="$container/@about">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <xsl:variable name="content-uri" select="$container/@about" as="xs:anyURI"/>
                    <xsl:variable name="update-string" select="replace($content-delete-string, '$this', '&lt;' || ldh:base-uri(.) || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$content', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ldh:base-uri(.))" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="onContentDelete">
                                <xsl:with-param name="container" select="$container"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:when>
                <!-- remove content that hasn't been saved yet -->
                <xsl:otherwise>
                    <xsl:for-each select="$container">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- XHTML content cancel onclick -->
    
    <xsl:template match="div[contains-token(@class, 'xhtml-content')]//button[contains-token(@class, 'btn-cancel')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'xhtml-content')]" as="element()"/>

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
    
    <!-- resource content cancel onclick -->
    
    <xsl:template match="div[contains-token(@class, 'resource-content')]//button[contains-token(@class, 'btn-cancel')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'resource-content')]" as="element()"/>

        <xsl:choose>
            <!-- updating existing content -->
            <xsl:when test="$container/@about">
                <xsl:for-each select="$container">
                    <xsl:call-template name="ldh:LoadContent"/>
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

    <!-- toggle between Content as HTML (rdf:XMLLiteral) and URI resource in inline editing mode (increased priority to take precedence over the template in form.xsl) -->
    <xsl:template match="div[contains-token(@class, 'xhtml-content')]//select[contains-token(@class, 'content-type')][ixsl:get(., 'value') = '&rdfs;Resource']" mode="ixsl:onchange" priority="1">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'xhtml-content')]" as="element()"/>
        <!-- TO-DO: reuse identical constructor from form.xsl -->
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="A1">
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:nodeID="A2"/>
                        <ac:mode rdf:nodeID="A3"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A2">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A3">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="new-controls" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:value/@rdf:*" mode="bs2:FormControl"/>
            <xsl:apply-templates select="$constructor//ac:mode/@rdf:*" mode="bs2:FormControl">
                <xsl:with-param name="class" select="'content-mode'"/>
                <xsl:with-param name="type-label" select="false()"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$new-controls"/>
            </xsl:result-document>
        </xsl:for-each>
        
        <xsl:sequence select="ixsl:call(ixsl:get($container, 'classList'), 'replace', [ 'xhtml-content', 'resource-content' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- toggle between Content as URI resource and HTML (rdf:XMLLiteral) in inline editing mode (increased priority to take precedence over the template in form.xsl) -->
    <xsl:template match="div[contains-token(@class, 'resource-content')]//select[contains-token(@class, 'content-type')][ixsl:get(., 'value') = '&rdf;XMLLiteral']" mode="ixsl:onchange" priority="1">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'resource-content')]" as="element()"/>
        <!-- TO-DO: reuse identical constructor from form.xsl -->
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="A1">
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:parseType="Literal">
                            <xhtml:div/>
                        </rdf:value>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="new-controls" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:value/xhtml:*" mode="bs2:FormControl"/>
        </xsl:variable>
        
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$new-controls"/>
            </xsl:result-document>
        
            <!-- initialize wymeditor textarea -->
            <xsl:apply-templates select="key('elements-by-class', 'wymeditor', .)" mode="ldh:PostConstruct"/>
        </xsl:for-each>
        
        <xsl:sequence select="ixsl:call(ixsl:get($container, 'classList'), 'replace', [ 'resource-content', 'xhtml-content' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- appends new XHTML content instance to the content list -->
    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'create-action')][contains-token(@class, 'add-xhtml-content')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <!-- TO-DO: reuse identical constructor from form.xsl -->
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description>
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:parseType="Literal">
                            <xhtml:div/>
                        </rdf:value>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="controls" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:value/xhtml:*" mode="bs2:FormControl"/>
        </xsl:variable>

        <!-- move the current row of controls to the bottom of the content list -->
        <xsl:for-each select="$container/..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select="$container"/>
            </xsl:result-document>
        </xsl:for-each>
        
        <!-- add .content.xhtml-content to div.row-fluid -->
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'xhtml-content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <xsl:for-each select="ancestor::div[contains-token(@class, 'main')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div>
                    <xsl:copy-of select="$controls"/>
                </div>
                
                <div class="form-actions">
                    <button type="button" class="btn btn-primary btn-save">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                    <button type="button" class="btn btn-cancel">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
            </xsl:result-document>
            
            <!-- initialize wymeditor textarea -->
            <xsl:apply-templates select="key('elements-by-class', 'wymeditor', .)" mode="ldh:PostConstruct"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- appends new resource content instance to the content list -->
    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'create-action')][contains-token(@class, 'add-resource-content')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <!-- TO-DO: reuse identical constructor from form.xsl -->
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="A1">
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:nodeID="A2"/>
                        <ac:mode rdf:nodeID="A3"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A2">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A3">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="controls" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:value/@rdf:*" mode="bs2:FormControl"/>
            <xsl:apply-templates select="$constructor//ac:mode/@rdf:*" mode="bs2:FormControl">
                <xsl:with-param name="class" select="'content-mode'"/>
                <xsl:with-param name="type-label" select="false()"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <!-- move the current row of controls to the bottom of the content list -->
        <xsl:for-each select="$container/..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select="$container"/>
            </xsl:result-document>
        </xsl:for-each>

        <!-- add .content.resource-content to div.row-fluid -->
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'resource-content', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <xsl:for-each select="ancestor::div[contains-token(@class, 'main')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div>
                    <xsl:copy-of select="$controls"/>
                </div>
                
                <div class="form-actions">
                    <button type="button" class="btn btn-primary btn-save">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                    <button type="button" class="btn btn-cancel">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- start dragging content (or its descendants) -->
    
    <xsl:template match="div[ac:mode() = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')]/descendant-or-self::*" mode="ixsl:ondragstart">
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
    
    <xsl:template match="div[ac:mode() = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragover">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <ixsl:set-property name="dataTransfer.dropEffect" select="'move'" object="ixsl:event()"/>
    </xsl:template>

    <!-- change the style of elements when content is dragged over them -->
    
    <xsl:template match="div[ac:mode() = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragenter">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', true() ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="div[ac:mode() = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondragleave">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element drag entered (optional) -->

        <!-- only remove class if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- dropping content over other content -->
    
    <xsl:template match="div[ac:mode() = '&ldh;ContentMode'][contains-token(@class, 'content')][contains-token(@class, 'row-fluid')][acl:mode() = '&acl;Write']" mode="ixsl:ondrop">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="." as="element()"/>
        <xsl:variable name="content-uri" select="@about" as="xs:anyURI"/>
        <xsl:variable name="drop-content-uri" select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'getData', [ 'text/uri-list' ])" as="xs:anyURI"/>
        
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- move dropped element after this element, if they're not the same -->
        <xsl:if test="not($content-uri = $drop-content-uri)">
            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <xsl:variable name="drop-content" select="key('content-by-about', $drop-content-uri)" as="element()"/>
            <xsl:sequence select="ixsl:call(., 'after', [ $drop-content ])"/>
            
            <xsl:variable name="update-string" select="replace($content-swap-string, '$this', '&lt;' || ldh:base-uri(.) || '&gt;', 'q')" as="xs:string"/>
            <xsl:variable name="update-string" select="replace($update-string, '$targetContent', '&lt;' || $content-uri || '&gt;', 'q')" as="xs:string"/>
            <xsl:variable name="update-string" select="replace($update-string, '$sourceContent', '&lt;' || $drop-content-uri || '&gt;', 'q')" as="xs:string"/>
            <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ldh:base-uri(.))" as="xs:anyURI"/>
            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                    <xsl:call-template name="onContentSwap">
                        <xsl:with-param name="container" select="$container"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- load content -->
    
    <xsl:template name="ldh:LoadContent">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:variable name="this" select="ancestor::div[@about][1]/@about" as="xs:anyURI"/>
        <xsl:variable name="content-uri" select="(@about, $this)[1]" as="xs:anyURI"/> <!-- fallback to @about for charts, queries etc. -->
        <xsl:variable name="content-value" select="ixsl:get(., 'dataset.contentValue')" as="xs:anyURI"/> <!-- get the value of the @data-content-value attribute -->
        <xsl:variable name="mode" select="if (ixsl:contains(., 'dataset.contentMode')) then xs:anyURI(ixsl:get(., 'dataset.contentMode')) else ()" as="xs:anyURI?"/> <!-- get the value of the @data-content-mode attribute -->
        <xsl:variable name="container" select="." as="element()"/>
        <xsl:variable name="progress-container" select="if (contains-token(@class, 'row-fluid')) then ./div[contains-token(@class, 'main')] else ." as="element()"/>

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

        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $content-value)" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': ac:document-uri($request-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onContentValueLoad">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="content-value" select="$content-value"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="acl-modes" select="$acl-modes"/>
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- embed content -->
    
    <xsl:template name="onContentValueLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="content-value" as="xs:anyURI"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        
        <!-- for some reason Saxon-JS 2.3 does not see this variable if it's inside <xsl:when> -->
        <xsl:variable name="value" select="key('resources', $content-value, ?body)" as="element()?"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml' and $value">
                <xsl:variable name="results" select="?body" as="document-node()"/>
                <!-- create new cache entry using content URI as key -->
                <ixsl:set-property name="{'`' || $content-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                <!-- store this content element -->
                <ixsl:set-property name="content" select="$value" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>

                <xsl:for-each select="$container//div[@class = 'bar']">
                    <!-- update progress bar -->
                    <ixsl:set-style name="width" select="'50%'" object="."/>
                </xsl:for-each>

                <xsl:apply-templates select="$value" mode="ldh:RenderContent">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="mode" select="$mode"/>
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
                <xsl:for-each select="key('elements-by-class', 'chart-canvas', $container)">
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
                </xsl:for-each>
            </xsl:when>
            <!-- content could not be loaded from Linked Data, attempt a fallback to a DESCRIBE query over the local endpoint -->
            <xsl:when test="?status = 502">
                <xsl:variable name="query-string" select="'DESCRIBE &lt;' || $content-value || '&gt;'" as="xs:string"/>
                <xsl:variable name="results-uri" select="ac:build-uri($sd:endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $results-uri)" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': ac:document-uri($request-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                        <xsl:call-template name="onContentValueLoad">
                            <xsl:with-param name="this" select="$this"/>
                            <xsl:with-param name="content-uri" select="$content-uri"/>
                            <xsl:with-param name="content-value" select="$content-value"/>
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="acl-modes" select="$acl-modes"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- content could not be loaded as RDF (e.g. binary file) -->
            <xsl:when test="?status = 406">
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="offset2 span7 main">
                            <object data="{$content-value}"/>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content resource: <a href="{$content-value}"><xsl:value-of select="$content-value"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
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

                    <xsl:call-template name="ldh:ContentLoaded">
                        <xsl:with-param name="container" select="$container"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content resource: <a href="{$query-uri}"><xsl:value-of select="$query-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- XHTML content update -->
    
    <xsl:template name="onXHTMLContentUpdate">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-value" as="document-node()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="$container/div[contains-token(@class, 'main')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <button type="button" class="btn btn-edit pull-right">
                            <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                        </button>

                        <xsl:copy-of select="$content-value"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not update XHTML content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- resource content update -->
    
    <xsl:template name="onResourceContentUpdate">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="uri" as="xs:anyURI"/> <!-- document URI -->
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-value" as="xs:anyURI"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="$container">
                    <!-- update @data-content-value value -->
                    <ixsl:set-property name="dataset.contentValue" select="$content-value" object="."/>

                    <xsl:choose>
                        <xsl:when test="$mode">
                            <!-- update @data-content-mode value -->
                            <ixsl:set-property name="dataset.contentMode" select="$mode" object="."/>
                        </xsl:when>
                        <xsl:when test="ixsl:contains(., 'dataset.contentMode')">
                            <!-- remove @data-content-mode -->
                            <ixsl:remove-property name="dataset.contentMode" object="."/>
                        </xsl:when>
                    </xsl:choose>
                    
                    <xsl:call-template name="ldh:LoadContent">
<!--                        <xsl:with-param name="uri" select="$uri"/>  content value gets read from dataset.contentValue -->
                    </xsl:call-template>
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
            <xsl:when test="?status = 200">
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
            <xsl:when test="?status = 200">
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not swap content' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>