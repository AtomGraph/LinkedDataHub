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
    </xsl:template>

    <xsl:template name="bs2:QueryEditor">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7 main'" as="xs:string?"/>
        <xsl:param name="mode" select="$ac:mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="$ac:query" as="xs:string?"/>
        
        <div class="row-fluid">
            <div class="left-nav span2"></div>

            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
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
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="textarea-id" as="xs:string"/>
        <!--<xsl:param name="uri" as="xs:anyURI?"/>-->
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="default-query" as="xs:string"/>
        
        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset" select="$accept-charset"/>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype" select="$enctype"/>
            </xsl:if>

<!--            <fieldset>-->
                <div class="control-group">
                    <label class="control-label">Service</label> <!-- for="service" -->

                    <div class="controls">
                        <select name="service" class="input-xxlarge input-query-service">
                            <option value="">
                                <xsl:value-of>
                                    <xsl:text>[</xsl:text>
                                    <xsl:apply-templates select="key('resources', 'sparql-service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                    <xsl:text>]</xsl:text>
                                </xsl:value-of>
                            </option>
                        </select>
                    </div>
                </div>
                
                <div class="control-group required">
                    <label class="control-label">Title</label> <!-- for="title" -->

                    <div class="controls">
                        <input type="text" name="title"/>
                    </div>
                </div>
        
                <textarea name="query" class="span12" rows="15">
                    <xsl:if test="$textarea-id">
                        <xsl:attribute name="id" select="$textarea-id"/>
                    </xsl:if>
                    
                    <xsl:value-of select="if ($query) then $query else $default-query"/>
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
                    <button type="button" class="btn btn-primary btn-save btn-save-query">
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
<!--            </fieldset>-->
        </form>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->

    <!-- open SPARQL editor and pass a query string -->
    
    <xsl:template match="form[contains-token(@class, 'form-open-query')]" mode="ixsl:onsubmit" priority="1">
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="textarea-id" select="'query-string'" as="xs:string"/> <!-- TO-DO: fix -->
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