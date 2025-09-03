<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
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
xmlns:acl="&acl;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:param name="endpoint-classes-string" as="xs:string">
<![CDATA[
SELECT DISTINCT  ?type (COUNT(?s) AS ?count) (SAMPLE(?g) AS ?namedGraph)
WHERE
  {   { ?s  a  ?type }
    UNION
      { GRAPH ?g
          { ?s  a  ?type }
      }
  }
GROUP BY ?type
ORDER BY DESC(COUNT(?s))
LIMIT   10
]]>
    </xsl:param>
    
    <!-- TEMPLATES -->
    
    <xsl:template name="ldh:FirstTimeMessage">
        <div class="modal modal-first-time-message">
            <div class="hero-unit">
                <button type="button" class="close">×</button>
                <h1>Your LinkedDataHub is ready!</h1>
                <h2>Unlock the value of your Knowledge Graph with data-driven content and low code apps.</h2>
                <p>Create structured content backed by live data, intuitively explore graph datasets, model and manage RDF data, control data quality and more. <em>Without writing code</em>.</p>
                <p>
                    <a class="btn btn-primary btn-large" href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/get-started/" target="_blank">Get started</a>
                    <a class="btn btn-large" href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/" target="_blank">Learn more</a>
                </p>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template name="ldh:AddDataForm">
        <xsl:param name="id" select="'add-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="action" select="resolve-uri('add', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="source" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:anyURI?"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'add-rdf-data', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))" as="xs:string"/>

        <div class="modal modal-constructor fade in">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="modal-header">
                <button type="button" class="close">&#215;</button>

                <legend>
                    <xsl:value-of select="$legend-label"/>
                </legend>
            </div>

            <div class="modal-body">
                <form id="form-clone-data" method="POST" action="{$action}">
                    <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>

                    <fieldset>
                        <input type="hidden" name="sb" value="clone"/>

                        <xsl:if test="$query">
                            <input type="hidden" name="pu" value="&spin;query"/>
                            <input type="hidden" name="ou" value="{$query}"/>
                        </xsl:if>

                        <div class="control-group required">
                            <input type="hidden" name="pu" value="&dct;source"/>
                            <!-- TO-DO: localize label -->
                            <label class="control-label" for="remote-rdf-source">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'source', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <div class="controls">
                                <input type="text" id="remote-rdf-source" name="ou" class="input-xxlarge">
                                    <xsl:if test="$source">
                                        <xsl:attribute name="value" select="$source"/>
                                    </xsl:if>
                                </input>
                                <span class="help-inline">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </span>
                            </div>
                        </div>
                        <div class="control-group required">
                            <input type="hidden" name="pu" value="&sd;name"/>
                            <label class="control-label" for="remote-rdf-doc">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'graph', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <div class="controls">
                                <span>
                                    <input type="text" name="ou" id="remote-rdf-doc" class="resource-typeahead typeahead"/>
                                    <ul class="resource-typeahead typeahead dropdown-menu" id="ul-upload-rdf-doc" style="display: none;"></ul>
                                </span>

                                <!--
                                <div class="btn-group">
                                    <button type="button" class="btn dropdown-toggle create-action"></button>
                                    <ul class="dropdown-menu">
                                        <li>
                                            <button data-for-class="&dh;Container" href="{ldh:href(ac:absolute-path(ldh:base-uri(.)), ldh:query-params(xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Container')))}" class="btn add-constructor" title="&dh;Container" id="{generate-id()}-remote-rdf-container">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', '&dh;Container', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                        </li>
                                        <li>
                                            <button data-for-class="&dh;Item" href="{ldh:href(ac:absolute-path(ldh:base-uri(.)), ldh:query-params(xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Item')))}" type="button" class="btn add-constructor" title="&dh;Item" id="{generate-id()}-remote-rdf-item">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', '&dh;Item', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                        </li>
                                    </ul>
                                </div>
                                -->
                                <span class="help-inline">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', '&dh;Document', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                    </xsl:value-of>
                                </span>
                            </div>
                        </div>
                    </fieldset>

                    <div class="form-actions modal-footer">
                        <button type="submit" class="{$button-class}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="button" class="btn btn-close">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="reset" class="btn btn-reset">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </form>

                <div class="alert alert-info">
                    <p>Adding data this way will cause a blocking request, so use it for small amounts of data only (e.g. a few thousands of RDF triples). For larger data, use asynchronous <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/imports/rdf/" target="_blank">RDF imports</a>.</p>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="ldh:GenerateContainersForm">
        <xsl:param name="id" select="'generate-containers'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="action" select="resolve-uri('generate', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'generate-containers', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))" as="xs:string"/>
        <xsl:param name="arg-bnode-id" select="'generate'" as="xs:string"/>
        <xsl:param name="default-limit" select="10" as="xs:integer"/>
        
        <div class="modal modal-constructor fade in">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="modal-header">
                <button type="button" class="close">&#215;</button>

                <legend>
                    <xsl:value-of select="$legend-label"/>
                </legend>
            </div>

            <div class="modal-body">
                <div class="tabbable">
                    <ul class="nav nav-tabs">
                        <li class="active">
                            <a>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'from-sparql-service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </a>
                        </li>
                    </ul>
                    <div class="tab-content">
                        <div>
                            <!--<xsl:attribute name="class" select="'tab-pane ' || (if (not($source)) then 'active' else ())"/>-->

                            <form id="form-generate-containers" method="POST" action="{$action}">
                                <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'rdf'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                </xsl:call-template>
            
                                <fieldset>
                                    <input type="hidden" name="sb" value="{$arg-bnode-id}"/>

                                    <div class="control-group required">
                                        <input name="pu" type="hidden" value="&sioc;has_parent"/>
                                        <label class="control-label" for="generate-containers-parent">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'has-parent', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </label>
                                        <div class="controls">
                                            <span data-for-class="&def;Root &dh;Container">
                                                <input type="text" name="ou" class="resource-typeahead typeahead" id="generate-containers-parent" autocomplete="off"/>
                                                <ul class="resource-typeahead typeahead dropdown-menu" id="ul-parent-container" style="display: none;"></ul>
                                            </span>

                                            <span class="help-inline">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', '&dh;Container', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </span>
                                        </div>
                                    </div>
                                    <div class="control-group required">
                                        <input name="pu" type="hidden" value="&sp;limit"/>
                                        <label class="control-label" for="schema-class-limit">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'limit', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </label>
                                        <div class="controls">
                                            <input type="text" name="ol" id="schema-class-limit" value="{$default-limit}"/>
                                            <input type="hidden" name="lt" value="&xsd;integer"/>
                                            
                                            <span class="help-inline">xsd:integer</span>
                                        </div>
                                    </div>
                                    <div class="control-group required">
                                        <input name="pu" type="hidden" value="&ldh;service"/>
                                        <label class="control-label" for="source-service">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </label>
                                        <div class="controls">
                                            <span data-for-class="&sd;Service">
                                                <input type="text" name="ou" class="resource-typeahead typeahead" id="source-service" autocomplete="off"/>
                                                <ul class="resource-typeahead typeahead dropdown-menu" id="ul-source-service" style="display: none;"></ul>
                                            </span>

                                            <span class="help-inline">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', 'service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </span>
                                        </div>
                                    </div>
                                </fieldset>

                                <div class="form-actions modal-footer">
                                    <button type="button" class="btn btn-primary btn-load-endpoint-schema">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'load-schema', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <button type="submit" class="{$button-class}">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'generate', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <button type="button" class="btn btn-close">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <button type="reset" class="btn btn-reset">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
<!--                <div class="alert alert-info">
                    <p>Adding data this way will cause a blocking request, so use it for small amounts of data only (e.g. a few thousands of RDF triples). For larger data, use asynchronous <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/imports/rdf/" target="_blank">RDF imports</a>.</p>
                </div>-->
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="ldh:RequestAccessForm">
        <xsl:param name="id" select="'request-access'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary btn-access-form'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="action" select="resolve-uri('admin/access/request', $ldt:base)" as="xs:anyURI"/> <!-- TO-DO: handle for admin apps -->
        <xsl:param name="legend-label" select="ac:label(key('resources', 'request-access', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))" as="xs:string"/>
        <xsl:param name="agent" as="xs:anyURI"/>
        
        <div class="modal modal-constructor fade in">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="modal-header">
                <button type="button" class="close">&#215;</button>

                <legend>
                    <xsl:value-of select="$legend-label"/>
                </legend>
                
                <p class="text-info">Ask for access to a restricted resource by making a request. It will be reviewed by the application's administrators.</p>
            </div>

            <div class="modal-body">
                <form id="form-request-access" class="form-horizontal" method="POST" action="{$action}">
                    <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
            
                    <fieldset>
                        <div>
                            <label for="request-access-for">Request access for</label>
                            <select id="request-access-for" class="input-block-level">
                                <option value="{$agent}">
                                    <xsl:value-of select="$agent"/> (me)
                                </option>
                            </select>
                        </div>
                    </fieldset>

                    <div id="request-access-matrix">
                        <!-- content replaced by the onAccessResponseLoad callback -->
                    </div>
                   
                    <div class="form-actions modal-footer">
                        <button type="submit" class="{$button-class}">
                            <xsl:value-of>
                                <!-- <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/> -->
                                Request
                            </xsl:value-of>
                        </button>
                        <button type="button" class="btn btn-close">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="reset" class="btn btn-reset">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="request-access-matrix">
        <xsl:param name="agent" as="xs:anyURI"/>
        <!-- TO-DO: support agent-group? -->
        <xsl:param name="this" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="access-modes" select="(xs:anyURI('&acl;Read'), xs:anyURI('&acl;Append'), xs:anyURI('&acl;Write'))" as="xs:anyURI*"/>
        
        <fieldset>
            <legend>URL-based access</legend>
            <table class="table table-striped">
                <colgroup>
                    <col style="width: 55%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                </colgroup>
                <thead>
                    <tr>
                        <th>URL</th>
                        <xsl:for-each select="$access-modes">
                            <th>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', ., document(ac:document-uri('&acl;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </th>
                        </xsl:for-each>
                    </tr>
                </thead>
                <tbody>
                    <!-- the current document's URL is always shown -->
                    <xsl:variable name="this-auth" as="element()">
                        <rdf:Description>
                            <rdf:type rdf:resource="&acl;Authorization"/>
                            <acl:agent rdf:resource="{$agent}"/>
                            <acl:accessTo rdf:resource="{$this}"/>
                        </rdf:Description>
                    </xsl:variable>

                    <!-- append an authorization for the current URL unless such already exists (e.g. lacl:OwnerAuthorization) -->
                    <xsl:variable name="has-access-to-this-auth" select="exists(rdf:Description[acl:accessTo/@rdf:resource = $this])" as="xs:boolean"/>
                    <xsl:for-each-group select="if ($has-access-to-this-auth) then rdf:Description[acl:accessTo/@rdf:resource] else ($this-auth, rdf:Description[acl:accessTo/@rdf:resource])"
                                        group-by="acl:accessTo/@rdf:resource[starts-with(., $ldt:base)]">
                        <xsl:variable name="granted-access-modes" select="distinct-values(current-group()/acl:mode/@rdf:resource)" as="xs:anyURI*"/>

                        <!-- applying on the first authorization in the group -->
                        <xsl:apply-templates select="." mode="access-to">
                            <xsl:with-param name="agent" select="$agent"/>
                            <xsl:with-param name="access-modes" select="$access-modes"/>
                            <xsl:with-param name="access-to" select="current-grouping-key()"/>
                            <xsl:with-param name="granted-access-modes" select="$granted-access-modes"/>
                        </xsl:apply-templates>
                    </xsl:for-each-group>
                </tbody>
            </table>
        </fieldset>

        <fieldset>
            <legend>Class-based access</legend>
            <table class="table table-striped">
                <colgroup>
                    <col style="width: 55%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                </colgroup>
                <thead>
                    <tr>
                        <th>Class name</th>
                        <xsl:for-each select="$access-modes">
                            <th>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', ., document(ac:document-uri('&acl;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </th>
                        </xsl:for-each>
                    </tr>
                </thead>
                <tbody>
                    <xsl:variable name="default-classes" select="(xs:anyURI('&def;Root'), xs:anyURI('&dh;Container'), xs:anyURI('&dh;Item'), xs:anyURI('&nfo;FileDataObject'))" as="xs:anyURI*"/>
                    <!-- the current document's class is always shown -->
                    <xsl:variable name="this-auth" as="element()*">
                        <xsl:for-each select="$default-classes">
                            <rdf:Description>
                                <rdf:type rdf:resource="&acl;Authorization"/>
                                <acl:agent rdf:resource="{$agent}"/>
                                <acl:accessToClass rdf:resource="{.}"/>
                            </rdf:Description>
                        </xsl:for-each>
                    </xsl:variable>

                    <!-- the types of this document that are not already show as $default-classes -->
                    <xsl:for-each-group select="($this-auth, rdf:Description[acl:accessToClass/@rdf:resource[not(. = $default-classes)]])"
                                        group-by="acl:accessToClass/@rdf:resource">
                        <xsl:variable name="granted-access-modes" select="distinct-values(current-group()/acl:mode/@rdf:resource)" as="xs:anyURI*"/>

                        <!-- applying on the first authorization in the group -->                        
                        <xsl:apply-templates select="." mode="access-to-class">
                            <xsl:with-param name="agent" select="$agent"/>
                            <xsl:with-param name="access-modes" select="$access-modes"/>
                            <xsl:with-param name="access-to-class" select="current-grouping-key()"/>
                            <xsl:with-param name="granted-access-modes" select="$granted-access-modes"/>
                        </xsl:apply-templates>
                    </xsl:for-each-group>
                </tbody>
            </table>
        </fieldset>
    </xsl:template>
    
    <xsl:template match="rdf:Description" mode="access-to">
        <xsl:param name="agent" as="xs:anyURI"/>
        <xsl:param name="access-to" as="xs:anyURI"/>
        <xsl:param name="access-modes" as="xs:anyURI*"/>
        <xsl:param name="granted-access-modes" as="xs:anyURI*"/>

        <tr>
            <td>
                <a href="{$access-to}" target="_blank">
                    <xsl:value-of select="$access-to"/>
                </a>
                
                <input type="hidden" name="sb" value="access-to-class-{generate-id()}"/>
                <input type="hidden" name="pu" value="&rdf;type"/>
                <input type="hidden" name="ou" value="&acl;Authorization"/>
                <input type="hidden" name="pu" value="&acl;agent"/> <!-- TO-DO: support acl:agentGroup -->
                <input type="hidden" name="ou" value="{$agent}"/>
                <input type="hidden" name="pu" value="&acl;accessTo"/>
                <input type="hidden" name="ou" value="{$access-to}"/>
                <input type="hidden" name="pu" value="&acl;mode"/>
            </td>
            
            <xsl:apply-templates select="." mode="access-table">
                <xsl:with-param name="access-modes" select="$access-modes"/>
                <xsl:with-param name="granted-access-modes" select="$granted-access-modes"/>
            </xsl:apply-templates>
        </tr>
    </xsl:template>

    <xsl:template match="rdf:Description" mode="access-to-class">
        <xsl:param name="agent" as="xs:anyURI"/>
        <xsl:param name="access-to-class" as="xs:anyURI"/>
        <xsl:param name="access-modes" as="xs:anyURI*"/>
        <xsl:param name="granted-access-modes" as="xs:anyURI*"/>

        <tr>
            <td>
                <a href="{$access-to-class}" target="_blank">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', $access-to-class, document(ac:document-uri($access-to-class)))" mode="ac:label"/>
                    </xsl:value-of>
                </a>
                
                <input type="hidden" name="sb" value="access-to-class-{generate-id()}"/>
                <input type="hidden" name="pu" value="&rdf;type"/>
                <input type="hidden" name="ou" value="&acl;Authorization"/>
                <input type="hidden" name="pu" value="&acl;agent"/> <!-- TO-DO: support acl:agentGroup -->
                <input type="hidden" name="ou" value="{$agent}"/>
                <input type="hidden" name="pu" value="&acl;accessToClass"/>
                <input type="hidden" name="ou" value="{$access-to-class}"/>
                <input type="hidden" name="pu" value="&acl;mode"/>
            </td>
            
            <xsl:apply-templates select="." mode="access-table">
                <xsl:with-param name="access-modes" select="$access-modes"/>
                <xsl:with-param name="granted-access-modes" select="$granted-access-modes"/>
            </xsl:apply-templates>
        </tr>
    </xsl:template>
    
    <xsl:template match="rdf:Description" mode="access-table">
        <xsl:param name="access-modes" as="xs:anyURI*"/>
        <xsl:param name="granted-access-modes" as="xs:anyURI*"/>
        <xsl:param name="is-owner" select="rdf:type/@rdf:resource = '&lacl;OwnerAuthorization'" as="xs:boolean"/>

        <xsl:for-each select="$access-modes">
            <xsl:variable name="current-mode" select="."/>
            <td>
                <label class="checkbox">
                    <xsl:if test="$is-owner">
                        <xsl:attribute name="class" select="'checkbox label label-info'"/>
                    </xsl:if>
                    
                    <input type="checkbox" name="ou" value="{$current-mode}">
                        <xsl:if test="$current-mode = $granted-access-modes">
                            <!-- the modes that the agent already has access to are disabled since the agent cannot ask for less access, only more -->
                            <xsl:attribute name="checked">checked</xsl:attribute>
                            <xsl:attribute name="disabled">disabled</xsl:attribute>
                        </xsl:if>
                    </input>

                    <xsl:if test="$is-owner">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', '&acl;owner', document(ac:document-uri('&acl;')))" mode="ac:label"/>
                        </xsl:value-of>
                    </xsl:if>
                </label>
            </td>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ldh:ReconcileForm">
        <xsl:param name="id" select="'reconcile'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="action" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'reconcile-entity', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))" as="xs:string"/>
        <xsl:param name="resource" as="xs:anyURI"/>
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="service" as="xs:anyURI"/>
        
        <div class="modal modal-constructor fade in">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="modal-header">
                <button type="button" class="close">&#215;</button>

                <legend>
                    <xsl:value-of select="$legend-label"/>
                </legend>
            </div>

            <div class="modal-body">
                <form id="form-reconcile" method="POST" action="{$action}">
                    <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
            
                    <fieldset>
                        <input type="hidden" name="su" value="{$resource}"/>

                        <div class="control-group required">
                            <input type="hidden" name="pu" value="&owl;sameAs"/>
                            <!-- TO-DO: localize label -->
                            <label class="control-label" for="same-as-resource">
                                <xsl:value-of>
                                    Same as
                                </xsl:value-of>
                            </label>
                            <div class="controls">
                                <input id="same-as-resource" type="text" value="{$label}" class="input-xxlarge"/>
                                
                                <span class="help-inline">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </span>
                            </div>
                        </div>
                    </fieldset>
                </form>
            </div>
        </div>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->

    <!-- close modal first time message -->
    
    <xsl:template match="div[contains-token(@class, 'modal-first-time-message')]//button[contains-token(@class, 'close')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match/>
        
        <!-- set a cookie to never show it again -->
        <ixsl:set-property name="cookie" select="concat('LinkedDataHub.first-time-message=true; path=/', substring-after($ldt:base, $ac:contextUri), '; expires=Fri, 31 Dec 9999 23:59:59 GMT')" object="ixsl:page()"/>
    </xsl:template>

    <!-- close modal dialog -->

    <xsl:template match="div[contains-token(@class, 'modal')]//button[tokenize(@class, ' ') = ('close', 'btn-close')]" mode="ixsl:onclick" name="ldh:CloseModal">
        <xsl:for-each select="ancestor::div[contains-token(@class, 'modal')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-add-ontology')]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:AddDataForm">
                    <xsl:with-param name="action" select="resolve-uri('transform', $ldt:base)"/>
                    <xsl:with-param name="query" select="resolve-uri('queries/construct-constructors/#this', $ldt:base)"/>
                    <xsl:with-param name="legend-label" select="ac:label(key('resources', 'import-ontology', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-generate-containers')]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:GenerateContainersForm"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-access-form')]" mode="ixsl:onclick">
        <!-- TO-DO: fix for admin apps -->
        <xsl:variable name="request-uri" select="ldh:href(resolve-uri('admin/access', $ldt:base), map{ 'this': string(ac:absolute-path(ldh:base-uri(.))) })" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onAccessResponseLoad">
                    <xsl:with-param name="agent" select="$acl:agent"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-reconcile')]" mode="ixsl:onclick">
        <xsl:variable name="resource" select="input[@name = 'resource']/@value" as="xs:anyURI"/>
        <xsl:variable name="label" select="input[@name = 'label']/@value" as="xs:string"/>
        <xsl:variable name="service" select="input[@name = 'service']/@value" as="xs:anyURI"/>
        
        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:ReconcileForm">
                    <xsl:with-param name="resource" select="$resource"/>
                    <xsl:with-param name="label" select="$label"/>
                    <xsl:with-param name="service" select="$service"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- validate form before submitting it and show errors on required control-groups where input values are missing -->
    <xsl:template match="form[@id = 'form-add-data'] | form[@id = 'form-clone-data'] | form[@id = 'form-generate-containers']" mode="ixsl:onsubmit" priority="1">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')][contains-token(@class, 'required')]" as="element()*"/>
        <xsl:choose>
            <!-- input values missing, throw an error -->
            <xsl:when test="exists($control-groups/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
                <xsl:sequence select="$control-groups[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present, proceed to submit form-->
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:sequence select="$control-groups/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:variable name="form" select="." as="element()"/>
                <xsl:variable name="method" select="ixsl:get(., 'method')" as="xs:string"/>
                <xsl:variable name="action" select="ixsl:get(., 'action')" as="xs:anyURI"/>
                <xsl:variable name="enctype" select="ixsl:get(., 'enctype')" as="xs:string"/>
                <xsl:variable name="form-data" select="ldh:new('URLSearchParams', [ ldh:new('FormData', [ $form ]) ])"/>
                <xsl:variable name="request-uri" select="ldh:href($action, map{})" as="xs:anyURI"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': $method, 'href': $request-uri, 'media-type': $enctype, 'body': $form-data, 'headers': map{} }"> <!-- 'Accept': $accept -->
                        <xsl:call-template name="ldh:ModalFormSubmit">
                            <xsl:with-param name="action" select="$action"/>
                            <xsl:with-param name="form" select="$form"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-load-endpoint-schema')]" mode="ixsl:onclick">
        <xsl:variable name="fieldset" select="ancestor::form/fieldset" as="element()"/>
        <xsl:variable name="service-control-group" select="$fieldset/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&ldh;service']]" as="element()"/>
        <xsl:variable name="service-uri" select="$service-control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="limit-control-group" select="$fieldset/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sp;limit']]" as="element()"/>
        <xsl:variable name="limit-string" select="$limit-control-group/descendant::input[@name = 'ol']/ixsl:get(., 'value')" as="xs:string"/>
        <xsl:variable name="timeout" select="30000" as="xs:integer"/> <!-- schema load query timeout in milliseconds -->

        <xsl:choose>
            <!-- service value missing, throw an error -->
            <xsl:when test="not($service-uri)">
                <xsl:sequence select="$service-control-group/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- limit value missing, throw an error -->
            <xsl:when test="not($limit-string) or not($limit-string castable as xs:integer)">
                <xsl:sequence select="$service-control-group/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="$limit-control-group/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present/valid, load schema -->
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:sequence select="$service-control-group/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="$limit-control-group/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:variable name="limit" select="xs:integer($limit-string)" as="xs:integer"/>
                <xsl:variable name="select-string" select="$endpoint-classes-string" as="xs:string"/>
                <xsl:variable name="select-json" as="item()">
                    <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                    <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
                </xsl:variable>
                <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
                <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
                <!-- set LIMIT $limit -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit">
                            <xsl:with-param name="limit" select="$limit" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="query-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
                <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
                <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
                <xsl:variable name="service-doc" select="document(ac:build-uri($ldt:base, map{ 'uri': ac:document-uri($service-uri), 'accept': 'application/rdf+xml' }))" as="document-node()"/> <!-- TO-DO: replace with <ixsl:schedule-action> -->
                <xsl:variable name="endpoint" select="key('resources', $service-uri, $service-doc)/sd:endpoint/@rdf:resource" as="xs:anyURI"/>
                <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" wait="$timeout">
                        <xsl:call-template name="onEndpointClassesLoad">
                            <xsl:with-param name="container" select="$fieldset"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- validate form before submitting it and show errors on required control-groups where input values are missing -->
    <xsl:template match="form[@id = 'form-request-access']" mode="ixsl:onsubmit" priority="1">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="form" select="." as="element()"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- disable hidden inputs on table rows where all acl:mode checkboxes are a) disabled by default b) enabled but left unchecked -->
        <!-- otherwise RDF/POST will generate acl:Authorization instances without acl:mode values which will fail constraint validation -->
        <!-- we don't want to use the values of disabled checkboxes in the request because those authorizations already exist -->
        <xsl:for-each select="$form//tbody/tr[every $checkbox in descendant::input[@type = 'checkbox'][@name = 'ou'] satisfies (ixsl:get($checkbox, 'disabled') or not(ixsl:get($checkbox, 'disabled')) and not(ixsl:get($checkbox, 'checked')))]//input">
            <ixsl:set-property name="disabled" select="true()" object="."/>
        </xsl:for-each>

        <xsl:variable name="method" select="ixsl:get(., 'method')" as="xs:string"/>
        <xsl:variable name="action" select="ixsl:get(., 'action')" as="xs:anyURI"/>
        <xsl:variable name="enctype" select="ixsl:get(., 'enctype')" as="xs:string"/>
        <xsl:variable name="form-data" select="ldh:new('URLSearchParams', [ ldh:new('FormData', [ $form ]) ])"/>
        <xsl:variable name="request-uri" select="ldh:href($action, map{})" as="xs:anyURI"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': $method, 'href': $request-uri, 'media-type': $enctype, 'body': $form-data, 'headers': map{} }"> <!-- 'Accept': $accept -->
                <xsl:call-template name="ldh:ModalFormSubmit">
                    <xsl:with-param name="action" select="$action"/>
                    <xsl:with-param name="form" select="$form"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="input[contains-token(@class, 'subject-slug')]" mode="ixsl:onkeyup" priority="1">
        <xsl:param name="slug" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:param name="su-input" select="preceding-sibling::input[@name = 'su']" as="element()"/>
        <xsl:param name="form" select="ancestor::form" as="element()?"/>
        <!-- URL-encode the slug value, resolve it against base URI and add trailing slash -->
        <xsl:param name="new-uri" select="ac:absolute-path(ldh:base-uri(.)) || encode-for-uri($slug) || '/'" as="xs:string"/>

        <!-- set it as the new subject URI ("su" input value) -->
        <ixsl:set-property name="value" select="$new-uri" object="$su-input"/>
        <!-- also set it as the new form action value -->
        <ixsl:set-property name="action" select="$new-uri" object="$form"/>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- show "Add data"/"Save as" form -->

    <xsl:template name="ldh:ShowAddDataForm">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="graph" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI?"/>
        
        <!-- don't append the div if it's already there -->
        <xsl:if test="not(id($form/@id, ixsl:page()))">
            <xsl:for-each select="ixsl:page()//body">
                <!-- append modal div to body -->
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:sequence select="$form"/>
                </xsl:result-document>
                
                <xsl:if test="$graph">
                    <!-- fill the container typeahead values for both #upload-rdf-doc and #remote-rdf-doc -->
                    <xsl:for-each select="(id('upload-rdf-doc', ixsl:page())/.., id('remote-rdf-doc', ixsl:page())/..)">
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $graph, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="onTypeaheadResourceLoad">
                                    <xsl:with-param name="resource-uri" select="$graph"/>
                                    <xsl:with-param name="typeahead-span" select="."/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:if>

                <ixsl:set-style name="cursor" select="'default'"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- show modal form -->
    
    <xsl:template name="ldh:ShowModalForm">
        <xsl:param name="form" as="element()"/>
        
        <!-- don't append the div if it's already there -->
        <xsl:if test="not(id($form/@id, ixsl:page()))">
            <xsl:for-each select="ixsl:page()//body">
                <!-- append modal div to body -->
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:sequence select="$form"/>
                </xsl:result-document>

                <ixsl:set-style name="cursor" select="'default'"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <!-- form is submitted. TO-DO: split into multiple callbacks and avoid <xsl:choose>? -->
    
    <xsl:template name="ldh:ModalFormSubmit">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:param name="action" as="xs:anyURI"/>
        <xsl:param name="form" as="element()"/>
        
        <xsl:choose>
            <!-- special case for add/clone data forms: redirect to the container -->
            <xsl:when test="ixsl:get($form, 'id') = ('form-add-data', 'form-clone-data')">
                <xsl:variable name="control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sd;name']]" as="element()*"/>
                <xsl:variable name="uri" select="$control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                
                <xsl:choose>
                    <xsl:when test="?status = (200, 204)">
                        <!-- load document -->
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                                <xsl:call-template name="ldh:DocumentLoaded">
                                    <xsl:with-param name="href" select="ac:build-uri(ac:absolute-path($uri), map{ 'mode': '&ac;ReadMode'})"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>

                        <!-- remove the modal div -->
                        <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                        
                        <xsl:variable name="status-code" select="xs:integer(?status)" as="xs:integer"/>
                        <xsl:variable name="message" select="?message" as="xs:string?"/>
                        <!-- render error message -->
                        <xsl:for-each select="$form//fieldset">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <div class="alert">
                                    <p>
                                        <!-- lookup status message by code because Tomcat does not send any -->
                                        <xsl:apply-templates select="key('status-by-code', $status-code, document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/http-statusCodes.rdf', $ac:contextUri)))" mode="ac:label"/>
                                    </p>
                                    <xsl:if test="$message">
                                        <p>
                                            <xsl:value-of select="$message"/>
                                        </p>
                                    </xsl:if>
                                </div>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- special case for generate containers form: redirect to the parent container -->
            <xsl:when test="ixsl:get($form, 'id') = 'form-generate-containers'">
                <xsl:variable name="control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sioc;has_parent']]" as="element()*"/>
                <xsl:variable name="uri" select="$control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                
                <!-- load document -->
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="ldh:DocumentLoaded">
                            <xsl:with-param name="href" select="ac:absolute-path($uri)"/>
                            <xsl:with-param name="refresh-content" select="true()"/> <!-- make sure content (e.g. containers) do not use a stale response -->
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                
                <!-- remove the modal div -->
                <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:when test="?status = 200 and ixsl:get($form, 'id') = 'form-request-access'">
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

                <!-- remove the modal div -->
                <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- POST created new resource successfully -->
            <xsl:when test="?status = 201 and ?headers?location">
                <xsl:variable name="created-uri" select="?headers?location" as="xs:anyURI"/>
                <xsl:choose>
                    <!-- special case for signup form -->
                    <xsl:when test="ixsl:get($form, 'id') = 'form-signup'">
                        <xsl:call-template name="bs2:SignUpComplete"/>
                    </xsl:when>
                    <!-- if the form submit did not originate from a typeahead (target), load the created resource -->
                    <xsl:otherwise>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $created-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                                <xsl:call-template name="ldh:DocumentLoaded">
                                    <xsl:with-param name="href" select="ac:absolute-path($created-uri)"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- render schema classes loaded from a SPARQL endpoint -->
    
    <xsl:template name="onEndpointClassesLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="arg-bnode-id" select="'generate'" as="xs:string"/>
        
        <!-- append the controls for the class list if they don't exist -->
        <xsl:for-each select="$container[not(./div[contains-token(@class, 'endpoint-classes')])]">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="control-group required endpoint-classes">
                    <label class="control-label">Classes</label>
                    <div class="controls"></div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                    
                    <!-- populate the class list within div.controls -->
                    <xsl:for-each select="$container//div[contains-token(@class, 'endpoint-classes')]/div">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <ul class="unstyled">
                                <xsl:for-each select="$results/srx:sparql/srx:results/srx:result">
                                    <li>
                                        <input type="hidden" name="sb" value="{$arg-bnode-id}"/>
                                        <input type="hidden" name="pu" value="&dct;hasPart"/>
                                        <input type="hidden" name="ob" value="dataset-{position()}"/> <!-- unique bnode ID for each item -->
                                        <input type="hidden" name="sb" value="dataset-{position()}"/> <!-- unique bnode ID for each item -->
                                        <input type="hidden" name="pu" value="&spin;query"/>
                                        
                                        <xsl:choose>
                                            <xsl:when test="srx:binding[@name = 'namedGraph']/srx:uri">
                                                <input type="hidden" name="ou" value="{resolve-uri('queries/select-instances-in-graphs/#this', $ldt:base)}"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <input type="hidden" name="ou" value="{resolve-uri('queries/select-instances/#this', $ldt:base)}"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        
                                        <input type="hidden" name="pu" value="&void;class"/>

                                        <label class="checkbox">
                                            <input type="checkbox" checked="checked" name="ou" value="{srx:binding[@name = 'type']/srx:uri}"/>
                                            <samp>
                                                <xsl:value-of select="srx:binding[@name = 'type']/srx:uri"/>
                                            </samp>
                                        </label>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="message" select="?message" as="xs:string?"/>
                
                <xsl:for-each select="$container//div[contains-token(@class, 'endpoint-classes')]/div">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error during query execution:</strong>
                            <pre>
                                <xsl:value-of select="$message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onTypeaheadResourceLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="resource-uri" as="xs:anyURI"/>
        <xsl:param name="typeahead-span" as="element()"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="resource" select="key('resources', $resource-uri)" as="element()?"/>

                    <xsl:choose>
                        <xsl:when test="$resource">
                            <xsl:for-each select="$typeahead-span">
                                <xsl:variable name="typeahead" as="element()">
                                    <xsl:apply-templates select="$resource" mode="ldh:Typeahead">
                                        <!-- <xsl:with-param name="forClass" select="$forClass"/> -->
                                    </xsl:apply-templates>
                                </xsl:variable>

                                <xsl:result-document href="?." method="ixsl:replace-content">
                                    <xsl:sequence select="$typeahead/*"/>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- resource description not found, render lookup input -->
                            <xsl:call-template name="bs2:Lookup">
                                <xsl:with-param name="class" select="'resource-typeahead typeahead'"/>
                                <xsl:with-param name="list-class" select="'resource-typeahead typeahead dropdown-menu'"/>
                                <xsl:with-param name="value" select="$resource-uri"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template name="onAccessResponseLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="agent" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="body" select="?body" as="document-node()"/>
                
                <xsl:call-template name="ldh:ShowModalForm">
                    <xsl:with-param name="form" as="element()">
                        <xsl:apply-templates select="$body" mode="ldh:RequestAccessForm">
                            <xsl:with-param name="agent" select="$agent"/>
                        </xsl:apply-templates>
                    </xsl:with-param>
                </xsl:call-template>
                
                <xsl:for-each select="id('request-access-matrix', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:apply-templates select="$body/rdf:RDF" mode="request-access-matrix">
                            <xsl:with-param name="agent" select="$agent"/>
                        </xsl:apply-templates>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>