<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
]>
<xsl:stylesheet version="3.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:sd="&sd;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:saxon="http://saxon.sf.net/"
exclude-result-prefixes="#all"
>

    <xsl:param name="default-query" as="xs:string">SELECT DISTINCT *
WHERE
{
    GRAPH ?g
    { ?s ?p ?o }
}
LIMIT 100</xsl:param>

    <!-- TEMPLATES -->
    
    <xsl:template match="*[@rdf:nodeID = 'run']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-run-query')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template name="bs2:QueryEditor" >
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>
        <xsl:param name="mode" select="$ac:mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="$ac:query" as="xs:string?"/>
        
        <div class="row-fluid">
            <div class="left-nav span2"></div>

            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>

                <!--<legend>SPARQL editor</legend>-->
                
                <xsl:call-template name="bs2:QueryForm">
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="service" select="$service"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="query" select="$query"/>
                    <xsl:with-param name="default-query" select="$default-query"/>
                </xsl:call-template>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="bs2:QueryForm">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" select="'query-form'" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <!--<xsl:param name="uri" as="xs:anyURI?"/>-->
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="default-query" as="xs:string"/>
        
        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
            </xsl:if>

            <fieldset>
<!--                <label for="query-uri">Query</label>
                <xsl:text> </xsl:text>
                <select id="query-uri" name="query-uri" class="input-xxlarge">
                    <option value="">[Query]</option>
                </select>-->
                
                <label for="service">Service</label>
                <xsl:text> </xsl:text>
                <select id="query-service" name="service" class="input-xxlarge">
                    <option value="">[SPARQL service]</option>
                </select>
        
                <textarea id="query-string" name="query" class="span12" rows="15">
                    <xsl:value-of select="if ($query) then $query else $default-query"/>
                </textarea>

                <div class="form-actions">
                    <!-- retain URL parameters -->
<!--                    <xsl:if test="ac:uri()">
                        <input type="hidden" name="uri" value="{ac:uri()}"/>
                    </xsl:if>-->
                    <xsl:if test="$service">
                        <input type="hidden" name="service" value="{$service}"/>
                    </xsl:if>
                    <xsl:for-each select="$mode">
                        <input type="hidden" name="mode" value="{.}"/>
                    </xsl:for-each>
    
                    <button type="submit">
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn btn-primary'"/>
                        </xsl:apply-templates>
                    </button>
                    <button class="btn btn-save-query" type="button">
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn btn-save-query'"/>
                        </xsl:apply-templates>
                    </button>
                </div>
            </fieldset>
        </form>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->

    <!-- open SPARQL editor and pass a query string -->
    
    <xsl:template match="form[contains-token(@class, 'form-open-query')]" mode="ixsl:onsubmit" priority="1">
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="textarea-id" select="'query-string'" as="xs:string"/>
        <xsl:variable name="form" select="." as="element()"/>
        <xsl:variable name="query" select="$form//input[@name = 'query']/ixsl:get(., 'value')" as="xs:string"/>
        <xsl:variable name="service" select="$form//input[@name = 'service']/ixsl:get(., 'value')" as="xs:anyURI?"/>
        
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <!-- set textarea's value to the query string from the hidden input -->
                <xsl:call-template name="bs2:QueryEditor">
                    <xsl:with-param name="query" select="$query"/>
                    <xsl:with-param name="service" select="$service"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>
        
        <!-- initialize SPARQL query service dropdown -->
        <xsl:variable name="service-uri" select="if (id('search-service', ixsl:page())) then xs:anyURI(ixsl:get(id('search-service', ixsl:page()), 'value')) else ()" as="xs:anyURI?"/>
        <xsl:call-template name="ldh:RenderServices">
            <xsl:with-param name="select" select="id('query-service', ixsl:page())"/>
            <xsl:with-param name="apps" select="ixsl:get(ixsl:window(), 'LinkedDataHub.apps')"/>
            <xsl:with-param name="selected-service" select="$service"/>
        </xsl:call-template>
        
        <!-- initialize YASQE on the textarea -->
        <xsl:variable name="js-statement" as="element()">
            <root statement="YASQE.fromTextArea(document.getElementById('{$textarea-id}'), {{ persistent: null }})"/>
        </xsl:variable>
        <ixsl:set-property name="{$textarea-id}" select="ixsl:eval(string($js-statement/@statement))" object="ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe')"/>
    </xsl:template>
    
    <!-- run SPARQL query in editor -->
    
    <!-- TO-DO: change to 'query-form' @class? -->
    <xsl:template match="form[@id = 'query-form']" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="textarea-id" select="descendant::textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('query-service'), 'value'))" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $results-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }" as="map(xs:string, item())"/>
        <xsl:variable name="content-uri" select="xs:anyURI(translate($results-uri, '.', '-'))" as="xs:anyURI"/> <!-- replace dots -->

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="$request">
                <xsl:call-template name="onSPARQLResultsLoad">
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="query" select="$query"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- save query -->
    
    <xsl:template match="button[contains-token(@class, 'btn-save-query')]" mode="ixsl:onclick">
        <xsl:variable name="textarea-id" select="ancestor::form/descendant::textarea[@name = 'query']/ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="yasqe" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id)"/>
        <xsl:variable name="query-string" select="ixsl:call($yasqe, 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('query-service'), 'value'))" as="xs:anyURI?"/>
        <xsl:variable name="query-type" select="ldh:query-type($query-string)" as="xs:string"/>
        <xsl:variable name="forClass" select="xs:anyURI('&sp;' || upper-case(substring($query-type, 1, 1)) || lower-case(substring($query-type, 2)))" as="xs:anyURI"/>
        <xsl:message>Query type: <xsl:value-of select="$query-type"/> forClass: <xsl:value-of select="$forClass"/></xsl:message>
        <!--- show a modal form if this button is in a <fieldset>, meaning on a resource-level and not form level. Otherwise (e.g. for the "Create" button) show normal form -->
        <xsl:variable name="modal-form" select="true()" as="xs:boolean"/>
        <xsl:variable name="href" select="ac:build-uri(ldh:absolute-path(ldh:href()), let $params := map{ 'forClass': string($forClass), 'createGraph': string(true()) } return if ($modal-form) then map:merge(($params, map{ 'mode': '&ac;ModalMode' })) else $params)" as="xs:anyURI"/>
        <xsl:message>Form $href: <xsl:value-of select="$href"/> $service-uri: <xsl:value-of select="$service-uri"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddSaveQueryForm">
                    <xsl:with-param name="query-string" select="$query-string"/>
                    <xsl:with-param name="service-uri" select="$service-uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <xsl:template name="onAddSaveQueryForm">
        <xsl:param name="query-string" as="xs:string"/>
        <xsl:param name="form-id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string?"/>
        <xsl:param name="add-class" select="'form-save-query'" as="xs:string?"/>
        <xsl:param name="target-id" as="xs:string?"/>
        <xsl:param name="service-uri" as="xs:anyURI?"/>

        <!-- override the form @id coming from the server with a value we can use for form lookup afterwards -->
        <xsl:call-template name="onAddForm">
            <xsl:with-param name="container" select="id('content-body', ixsl:page())"/>
            <xsl:with-param name="add-class" select="$add-class"/>
            <xsl:with-param name="new-form-id" select="$form-id"/>
            <xsl:with-param name="new-target-id" select="$target-id"/>
        </xsl:call-template>
        
        <xsl:variable name="form" select="id($form-id, ixsl:page())" as="element()"/>
        
        <xsl:variable name="query-string-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sp;text']]" as="element()"/>
        <ixsl:set-property name="value" select="$query-string" object="$query-string-control-group/descendant::textarea[@name = 'ol']"/>

        <xsl:variable name="item-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sioc;has_container']]" as="element()"/>
        <xsl:variable name="container" select="resolve-uri('queries/', $ldt:base)" as="xs:anyURI"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $container, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onTypeaheadResourceLoad">
                    <xsl:with-param name="resource-uri" select="$container"/>
                    <xsl:with-param name="typeahead-span" select="$item-control-group/div[contains-token(@class, 'controls')]/span[1]"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            
        <xsl:if test="$service-uri">
            <xsl:variable name="service-control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&ldh;service']]" as="element()"/>
            
            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $service-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="onTypeaheadResourceLoad">
                        <xsl:with-param name="resource-uri" select="$service-uri"/>
                        <xsl:with-param name="typeahead-span" select="$service-control-group/div[contains-token(@class, 'controls')]/span[1]"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>