<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
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
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->
    
    <xsl:template match="*[@rdf:nodeID = 'run']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-run-query')"/>
    </xsl:template>
    
    <!-- set query string -->

    <xsl:template match="sp:text/text()" mode="ldh:Identity" priority="1">
        <xsl:param name="query-string" as="xs:string" tunnel="yes"/>

        <xsl:sequence select="$query-string"/>
    </xsl:template>
    
    <!-- render query editor -->
    
    <xsl:template match="textarea[@id][contains-token(@class, 'sparql-query-string')]" mode="ldh:RenderRowForm" priority="1">
        <xsl:variable name="textarea-id" select="ixsl:get(., 'id')" as="xs:string"/>
        <!-- initialize YASQE SPARQL editor on the textarea -->
        <xsl:variable name="js-statement" as="element()">
            <root statement="YASQE.fromTextArea(document.getElementById('{$textarea-id}'), {{ persistent: null }})"/>
        </xsl:variable>
        <ixsl:set-property name="{$textarea-id}" select="ixsl:eval(string($js-statement/@statement))" object="ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe')"/>
    </xsl:template>
    
<!--    <xsl:template name="onQueryServiceLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="forClass" as="xs:anyURI"/>
        <xsl:param name="service-uri" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="results" select="?body" as="document-node()"/>

                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:apply-templates select="key('resources', $service-uri, $results)" mode="ldh:Typeahead">
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="response" select="." as="map(*)"/>
                 error response - could not load service 
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error loading service:</strong>
                            <pre>
                                <xsl:value-of select="$response?message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
                
                <xsl:sequence select="
                    error(
                      QName('&ldh;', 'ldh:HTTPError'),
                      concat('HTTP ', ?status, ' returned: ', ?message),
                      $response
                    )
                "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    
    <!-- render query block -->
    
    <xsl:template match="*[@typeof = ('&sp;Ask', '&sp;Select', '&sp;Describe', '&sp;Construct')][descendant::*[@property = '&sp;text'][pre/text()]]" mode="ldh:RenderRow" as="function(item()?) as map(*)" priority="2 "> <!-- prioritize above block.xsl -->
        <xsl:param name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="graph" select="descendant::*[@property = '&ldh;graph']/@resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="descendant::*[@property = '&ac;mode']/@resource" as="xs:anyURI?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="show-edit-button" select="false()" as="xs:boolean?"/>
        <xsl:param name="textarea-id" select="generate-id() || '-textarea'" as="xs:string?"/>
        <xsl:param name="textarea-class" select="'span12 sparql-query-string'" as="xs:string?"/>
        <xsl:param name="textarea-name" select="'query'" as="xs:string?"/>
        <xsl:param name="textarea-rows" select="15" as="xs:integer?"/>
        <xsl:param name="service-uri" select="descendant::*[@property = '&ldh;service']/@resource" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="string(descendant::*[@property = '&sp;text']/pre)" as="xs:string"/>
        <xsl:param name="show-properties" select="false()" as="xs:boolean"/>
        <xsl:param name="forClass" select="xs:anyURI('&sd;Service')" as="xs:anyURI"/>
        
        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
            <ixsl:set-style name="width" select="'66%'" object="."/>
        </xsl:for-each>

        <xsl:variable name="context" as="map(*)" select="
          map{
            'container': $container,
            'textarea-id': $textarea-id,
            'textarea-class': $textarea-class,
            'textarea-name': $textarea-name,
            'textarea-rows': $textarea-rows,
            'query': $query,
            'service-uri': $service-uri,
            'forClass': $forClass
          }"/>
  
        <xsl:sequence select="
            ldh:load-block#3(
                $context,
                ldh:query-self-thunk#1,
                ?
            )
        "/>
    </xsl:template>
    
    <xsl:function name="ldh:query-self-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:message>ldh:chart-self-thunk</xsl:message>
        <xsl:sequence select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:render-query#1)
        "/>
    </xsl:function>
    
    <xsl:function name="ldh:render-query" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="textarea-id" select="$context('textarea-id')" as="xs:string?"/>
        <xsl:variable name="textarea-class" select="$context('textarea-class')" as="xs:string?"/>
        <xsl:variable name="textarea-name" select="$context('textarea-name')" as="xs:string?"/>
        <xsl:variable name="textarea-rows" select="$context('textarea-rows')" as="xs:integer?"/>
        <xsl:variable name="query" select="$context('query')" as="xs:string"/>
        <xsl:variable name="service-uri" select="$context('service-uri')" as="xs:anyURI?"/>
        <xsl:variable name="forClass" select="$context('forClass')" as="xs:anyURI"/>
        
        <xsl:message>ldh:render-query</xsl:message>

        <xsl:for-each select="$container//div[contains-token(@class, 'main')]">
            <xsl:variable name="header" select="./div/div[@class = 'well']" as="element()"/>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$header"/>
                                
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
                                    <!-- TO-DO: refactor asynchronously -->
                                    <xsl:apply-templates select="key('resources', $service-uri, document($request-uri))" mode="ldh:Typeahead">
                                        <xsl:with-param name="forClass" select="$forClass"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="bs2:Lookup">
                                        <xsl:with-param name="forClass" select="$forClass"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </div>

                    <textarea>
                        <xsl:if test="$textarea-id">
                            <xsl:attribute name="id" select="$textarea-id"/>
                        </xsl:if>
                        <xsl:if test="$textarea-class">
                            <xsl:attribute name="class" select="$textarea-class"/>
                        </xsl:if>
                        <xsl:if test="$textarea-name">
                            <xsl:attribute name="name" select="$textarea-name"/>
                        </xsl:if>
                        <xsl:if test="$textarea-rows">
                            <xsl:attribute name="rows" select="$textarea-rows"/>
                        </xsl:if>
                        
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
        
        <!-- initialize YASQE SPARQL editor on the textarea -->
        <xsl:variable name="js-statement" as="element()">
            <root statement="YASQE.fromTextArea(document.getElementById('{$textarea-id}'), {{ persistent: null }})"/>
        </xsl:variable>
        <ixsl:set-property name="{$textarea-id}" select="ixsl:eval(string($js-statement/@statement))" object="ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe')"/>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <!-- EVENT LISTENERS -->
    
    <!-- submit SPARQL query form (prioritize over default template in form.xsl) -->
    
    <xsl:template match="div[@typeof = ('&sp;Ask', '&sp;Select', '&sp;Describe', '&sp;Construct')]//form[contains-token(@class, 'sparql-query-form ')]" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="textarea-id" select="descendant::textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-control-group" select="descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&ldh;service']]" as="element()"/>
        <xsl:variable name="service-uri" select="$service-control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="$block" as="element()"/> <!-- since we're not in content mode -->
        <xsl:variable name="block-id" select="$block/@id" as="xs:string"/>
        <xsl:variable name="block-uri" select="if ($block/@about) then $block/@about else xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $block-id)" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }" as="map(xs:string, item())"/>
        <xsl:variable name="results-container-id" select="$block-id || '-query-results'" as="xs:string"/>
        <xsl:variable name="results-container-class" select="'sparql-query-results'" as="xs:string"/>
        <xsl:variable name="results-container-about" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $results-container-id)" as="xs:anyURI"/>

        <!-- create results/error container element if it doesn't exist  -->
        <xsl:if test="not(id($results-container-id, ixsl:page()))">
            <!-- TO-DO: find a better solution. $container in ContentMode is the whole .content row but in ReadMode it's .main -->
            <xsl:for-each select="if ($container//div[contains-token(@class, 'main')]) then $container//div[contains-token(@class, 'main')] else $container">
                <xsl:variable name="active-mode" select="xs:anyURI('&ac;ChartMode')" as="xs:anyURI"/>

                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:if test="$query-string">
                        <ul class="nav nav-tabs nav-query-results">
                            <li class="chart-mode">
                                <xsl:if test="$active-mode = '&ac;ChartMode'">
                                    <xsl:attribute name="class" select="'chart-mode active'"/>
                                </xsl:if>

                                <a>
                                    <xsl:apply-templates select="key('resources', '&ldh;Chart', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                                </a>
                            </li>
                            
                            <!-- view mode only avaible for SELECT query results -->
                            <xsl:if test="ancestor::*[@typeof][1]/@typeof = '&sp;Select'">
                                <li class="view-mode">
                                    <xsl:if test="$active-mode = '&ac;ViewMode'">
                                        <xsl:attribute name="class" select="'view-mode active'"/>
                                    </xsl:if>

                                    <a>
                                        <xsl:apply-templates select="key('resources', '&ldh;View', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                                    </a>
                                </li>
                            </xsl:if>
                        </ul>
                    </xsl:if>

                    <div class="{$results-container-class}" id="{$results-container-id}" about="{$results-container-about}"></div>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
        
        <!-- TO-DO: refactor as promise -->
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="$request">
                <xsl:call-template name="onSPARQLResultsLoad">
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="results-uri" select="$results-uri"/>
                    <xsl:with-param name="block-uri" select="$block-uri"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="chart-canvas-id" select="$block-id || '-chart-canvas'"/>
                    <xsl:with-param name="results-container" select="id($results-container-id, ixsl:page())"/>
                    <xsl:with-param name="query-string" select="$query-string"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- toggle query results to chart mode (prioritize over view.xsl) -->
    
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
        
        <xsl:variable name="view-container" select="$container//div[contains-token(@class, 'sparql-query-results')]" as="element()"/>
        <!-- ensure the HTML structure is compatible with what view expects -->
        <xsl:for-each select="$view-container">
            <ixsl:set-attribute name="typeof" select="'&ldh;View'" object="$view-container"/>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="main"></div>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:apply-templates select="$form" mode="ixsl:onsubmit"/>
    </xsl:template>
    
    <!-- toggle query results to view mode (prioritize over view.xsl) -->
    
    <xsl:template match="ul[contains-token(@class, 'nav-tabs')][contains-token(@class, 'nav-query-results')]/li[contains-token(@class, 'view-mode')][not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick" priority="1">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="form" select="$container//form[contains-token(@class, 'sparql-query-form')]" as="element()"/>
        <xsl:variable name="textarea-id" select="$form//textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="$form//select[contains-token(@class, 'input-query-service')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="query-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="query-uri" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $query-id)" as="xs:anyURI"/>
        <xsl:variable name="query-form" select="ldh:query-type($query-string)" as="xs:string?"/>
        <xsl:variable name="query-type" select="xs:anyURI('&sp;' || upper-case(substring($query-form, 1, 1)) || lower-case(substring($query-form, 2)))" as="xs:anyURI"/>
        <xsl:variable name="view-block-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="view-block-uri" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#' || $view-block-id)" as="xs:anyURI"/>
        <xsl:variable name="view-html" as="document-node()"> <!-- make sure the structure will match the ldh:RenderRow pattern in view.xsl -->
            <xsl:document>
                <div about="{$view-block-uri}" typeof="&ldh;View">
                    <div property="&spin;query" resource="{$block/@about}"/>
                </div>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="this" select="ancestor::div[@about][1]/@about" as="xs:anyURI"/> <!-- not the same as $block/@about! -->

        <!-- deactivate other tabs -->
        <xsl:for-each select="../../li">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="..">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

<!--        <xsl:for-each select="$block//div[contains-token(@class, 'bar')]">
             update progress bar 
            <ixsl:set-style name="width" select="'50%'" object="."/>
        </xsl:for-each>-->
                
        <xsl:variable name="view-container" select="$container//div[contains-token(@class, 'sparql-query-results')]" as="element()"/>
        <!-- ensure the HTML structure is compatible with what view expects -->
        <xsl:for-each select="$view-container">
            <ixsl:set-attribute name="typeof" select="'&ldh;View'" object="$view-container"/>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="main"></div>
            </xsl:result-document>
        </xsl:for-each>
        
        <xsl:variable name="factory" as="function(item()?) as item()*?">
            <xsl:apply-templates select="$view-html" mode="ldh:RenderRow">
                <xsl:with-param name="block" select="$block"/>
                <xsl:with-param name="container" select="$view-container"/>
                <xsl:with-param name="this" select="$this"/>
                <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <!-- invoke the factory -->
        <xsl:sequence select="$factory(())"/>
    </xsl:template>
    
    <!-- save query onclick -->
    <!-- TO-DO: use @typeof in match so that we don't need a custom button.btn-save-query class -->
    
    <xsl:template match="div[@typeof]//button[contains-token(@class, 'btn-save-query')]" mode="ixsl:onclick">
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="about" select="$block/@about" as="xs:anyURI"/>
        <xsl:variable name="textarea" select="ancestor::form/descendant::textarea[@name = 'query']" as="element()"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea/ixsl:get(., 'id'))"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string?"/> <!-- get query string from YASQE -->
        <xsl:variable name="method" select="'PATCH'" as="xs:string"/>
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
            <xsl:apply-templates select="$query" mode="ldh:Identity">
                <xsl:with-param name="query-string" select="$query-string" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="triples" select="ldh:descriptions-to-triples($query)" as="element()*"/>
        <xsl:variable name="update-string" select="ldh:insertdelete-update(ldh:triples-to-bgp(ldh:uri-po-pattern($about)), ldh:triples-to-bgp($triples), ldh:triples-to-bgp(ldh:uri-po-pattern($about)))" as="xs:string"/>
        <xsl:variable name="resources" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:sequence select="ldh:triples-to-descriptions($triples)"/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="request-uri" select="ldh:href($action, map{})" as="xs:anyURI"/>
        <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile -->
        <xsl:variable name="request" select="map{ 'method': $method, 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string, 'headers': map{ 'If-Match': $etag, 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'doc-uri': ac:absolute-path(ldh:base-uri(.)),
            'block': $block,
            'resources': $resources
          }"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:row-form-response#1)
        "/>
    </xsl:template>
    
    <!-- open query onclick -->
    
    <xsl:template match="button[contains-token(@class, 'btn-open-query')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="content-value" select="ixsl:get($container//div[contains-token(@class, 'main')]//input[@name = 'ou'], 'value')" as="xs:anyURI"/>
        <xsl:variable name="textarea" select="ancestor::form/descendant::textarea[@name = 'query']" as="element()"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea/ixsl:get(., 'id'))"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string?"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="descendant::select[contains-token(@class, 'input-query-service')]/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string?"/>

        <xsl:choose>
            <!-- query string value missing/invalid, throw an error -->
            <xsl:when test="not($query-type = ('DESCRIBE', 'CONSTRUCT'))">
                <xsl:message>Can only open DESCRIBE or CONSTRUCT query results</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="href" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>

                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
                
                <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'saxonController')">
                    <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                    <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.saxonController'), 'abort', [])"/>
                </xsl:if>
                <xsl:variable name="controller" select="ixsl:abort-controller()"/>
                <ixsl:set-property name="saxonController" select="$controller" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }" as="map(*)"/>
                <xsl:variable name="context" select="
                  map{
                    'request': $request,
                    'href': $href,
                    'push-state': true()
                  }" as="map(*)"/>
                <ixsl:promise select="
                  ixsl:http-request($context('request'), $controller)
                    => ixsl:then(ldh:rethread-response($context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:xhtml-document-loaded#1)
                " on-failure="ldh:promise-failure#1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- callbacks -->
    
    <xsl:template name="onSPARQLResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="results-uri" as="xs:anyURI"/>
        <xsl:param name="block-uri" as="xs:anyURI"/>
        <xsl:param name="chart-canvas-id" as="xs:string"/>
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="query-string" as="xs:string?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="content-method" select="xs:QName('ixsl:replace-content')" as="xs:QName"/>
        <xsl:param name="show-editor" select="true()" as="xs:boolean"/>
        <xsl:param name="show-chart-save" select="true()" as="xs:boolean"/>
        <xsl:param name="results-container" as="element()"/>
        
        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                    <xsl:variable name="category" select="if (exists($category)) then $category else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name()))[1] else srx:sparql/srx:head/srx:variable[1]/@name)" as="xs:string?"/>
                    <xsl:variable name="series" select="if (exists($series)) then $series else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name())) else srx:sparql/srx:head/srx:variable/@name)" as="xs:string*"/>

                    <xsl:for-each select="$results-container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:apply-templates select="$results" mode="bs2:Chart">
                                <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                                <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                                <xsl:with-param name="form-actions" as="element()">
                                    <div class="form-actions">
                                        <button class="btn btn-primary btn-create-chart" type="button">
                                            <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                                                <xsl:with-param name="class" select="'btn btn-primary create-action btn-create-chart'"/>
                                            </xsl:apply-templates>

                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </button>
                                    </div>
                                </xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:result-document>
                    </xsl:for-each>

                    <!-- create new cache entry using content URI as key -->
                    <ixsl:set-property name="{'`' || $block-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                    <ixsl:set-property name="results" select="$results" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>
                    <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
                    <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

                    <xsl:call-template name="ldh:RenderChart">
                        <xsl:with-param name="data-table" select="$data-table"/>
                        <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                        <xsl:with-param name="chart-type" select="$chart-type"/>
                        <xsl:with-param name="category" select="$category"/>
                        <xsl:with-param name="series" select="$series"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
                <xsl:for-each select="$results-container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error during query execution:</strong>
                            <pre>
                                <xsl:value-of select="$response?message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
                
                <!-- TO-DO: $context -->
                <xsl:sequence select="ldh:hide-block-progress-bar(map{}, ())[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="
                    error(
                      QName('&ldh;', 'ldh:HTTPError'),
                      concat('HTTP ', ?status, ' returned: ', ?message),
                      $response
                    )
                "/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
</xsl:stylesheet>