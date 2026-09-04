<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
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
xmlns:lapp="&lapp;"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:owl="&owl;"
xmlns:acl="&acl;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sioc="&sioc;"
xmlns:dct="&dct;"
xmlns:dh="&dh;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
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
        <div class="ldhc-backdrop pos-center modal modal-first-time-message">
            <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true">
                <div class="ldhc-modal-head">
                    <span class="ldhc-modal-x">
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                    </span>
                </div>
                <div class="ldhc-modal-body is-flush">
                    <div class="hero-unit">
                        <h1>Your LinkedDataHub is ready!</h1>
                        <h2>Unlock the value of your Knowledge Graph with data-driven content and low code apps.</h2>
                        <p>Create structured content backed by live data, intuitively explore graph datasets, model and manage RDF data, control data quality and more. <em>Without writing code</em>.</p>
                        <p>
                            <a class="ldhc-btn in-primary ap-solid sz-lg" href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/get-started/" target="_blank"><xsl:value-of select="ac:label(key('resources', 'get-started', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))"/></a>
                            <a class="ldhc-btn in-neutral ap-solid sz-lg" href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/" target="_blank"><xsl:value-of select="ac:label(key('resources', 'learn-more', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))"/></a>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template name="ldh:AddDataForm">
        <xsl:param name="id" select="'add-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-md btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="source" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:anyURI?"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'add-rdf-data', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))" as="xs:string"/>

        <div class="ldhc-backdrop pos-top modal modal-constructor">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                <div class="ldhc-modal-head">
                    <div class="ldhc-modal-titles">
                        <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                            <xsl:value-of select="$legend-label"/>
                        </h2>
                    </div>
                    <span class="ldhc-modal-x">
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                    </span>
                </div>

                <div class="ldhc-modal-body">
                <form id="form-clone-data" method="POST">
                    <xsl:comment>The hidden pu/ou input pairs use RDF/POST-style naming to key the submit handler's data extraction; the form is never wire-submitted</xsl:comment>
                    <fieldset>
                        <xsl:if test="$query">
                            <input type="hidden" name="pu" value="&spin;query"/>
                            <input type="hidden" name="ou" value="{$query}"/>
                        </xsl:if>

                        <div class="control-group required">
                            <input type="hidden" name="pu" value="&dct;source"/>
                            <!-- TO-DO: localize label -->
                            <label class="control-label" for="remote-rdf-source">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'source', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <div class="controls">
                                <input type="text" id="remote-rdf-source" name="ou">
                                    <xsl:if test="$source">
                                        <xsl:attribute name="value" select="$source"/>
                                    </xsl:if>
                                </input>
                                <span class="help-inline">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </span>
                            </div>
                        </div>
                        <div class="control-group required">
                            <input type="hidden" name="pu" value="&sd;name"/>
                            <label class="control-label" for="remote-rdf-doc">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'graph', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <div class="controls">
                                <span data-for-class="&dh;Container &dh;Item">
                                    <input type="text" name="ou" id="remote-rdf-doc" class="resource-typeahead typeahead" autocomplete="off"/>
                                    <ul class="resource-typeahead typeahead dropdown-menu" id="ul-upload-rdf-doc" style="display: none;"></ul>
                                </span>

                                <!--
                                <div class="btn-group">
                                    <button type="button" class="btn dropdown-toggle create-action"></button>
                                    <ul class="dropdown-menu">
                                        <li>
                                            <button data-for-class="&dh;Container" class="btn add-constructor" title="&dh;Container" id="{generate-id()}-remote-rdf-container">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', '&dh;Container', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </button>
                                        </li>
                                        <li>
                                            <button data-for-class="&dh;Item" type="button" class="btn add-constructor" title="&dh;Item" id="{generate-id()}-remote-rdf-item">
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

                    <div class="ldh-block-foot">
                        <button type="button" class="ldhc-btn in-neutral ap-outline sz-md btn-close">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="reset" class="ldhc-btn in-neutral ap-outline sz-md btn-reset">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="submit" class="{$button-class}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </form>

                <div class="alert alert-info">
                    <p>Adding data this way fetches the source through the Linked Data proxy and appends it to the target document, so use it for small amounts of data only (e.g. a few thousand RDF triples). For larger data, use asynchronous <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/imports/rdf/" target="_blank">RDF imports</a>.</p>
                </div>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="ldh:GenerateContainersForm">
        <xsl:param name="id" select="'generate-containers'" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-md btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'generate-containers', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))" as="xs:string"/>
        <xsl:param name="default-limit" select="10" as="xs:integer"/>
        
        <div class="ldhc-backdrop pos-top modal modal-constructor">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                <div class="ldhc-modal-head">
                    <div class="ldhc-modal-titles">
                        <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                            <xsl:value-of select="$legend-label"/>
                        </h2>
                    </div>
                    <span class="ldhc-modal-x">
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                    </span>
                </div>

                <div class="ldhc-modal-body">
                <div class="tabbable">
                    <ul class="nav nav-tabs">
                        <li class="active">
                            <a>
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'from-sparql-service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </a>
                        </li>
                    </ul>
                    <div class="tab-content">
                        <div>
                            <!--<xsl:attribute name="class" select="'tab-pane ' || (if (not($source)) then 'active' else ())"/>-->

                            <!-- no @action: the submit handler orchestrates client-side PUTs of the generated container documents -->
                            <form id="form-generate-containers" method="POST">
                                <fieldset>
                                    <div class="control-group required">
                                        <input name="pu" type="hidden" value="&sioc;has_parent"/>
                                        <label class="control-label" for="generate-containers-parent">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'has-parent', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
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
                                                <xsl:apply-templates select="key('resources', 'limit', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </label>
                                        <div class="controls">
                                            <input type="text" name="ol" id="schema-class-limit" value="{$default-limit}"/>
                                            <input type="hidden" name="lt" value="&xsd;integer"/>
                                            
                                            <span class="help-inline">xsd:integer</span>
                                        </div>
                                    </div>
                                    <div class="control-group">
                                        <input name="pu" type="hidden" value="&ldh;service"/>
                                        <label class="control-label" for="source-service">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </label>
                                        <div class="controls">
                                            <span data-for-class="&sd;Service">
                                                <input type="text" name="ou" class="resource-typeahead typeahead" id="source-service" autocomplete="off"/>
                                                <ul class="resource-typeahead typeahead dropdown-menu" id="ul-source-service" style="display: none;"></ul>
                                            </span>

                                            <span class="help-inline">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', 'service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </span>
                                        </div>
                                    </div>
                                </fieldset>

                                <div class="ldh-block-foot">
                                    <button type="button" class="ldhc-btn in-primary ap-solid sz-md btn-load-endpoint-schema">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'load-schema', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <!-- disabled until the schema is loaded; ldh:endpoint-classes-response enables it -->
                                    <button type="submit" class="{$button-class}" disabled="disabled">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'generate', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <button type="button" class="ldhc-btn in-neutral ap-outline sz-md btn-close">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <button type="reset" class="ldhc-btn in-neutral ap-outline sz-md btn-reset">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
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
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="ldh:RequestAccessForm">
        <xsl:param name="id" select="'request-access'" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-md btn-access-form'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="action" select="ldh:href(resolve-uri('access/request', lapp:origin($this)))" as="xs:anyURI"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'request-access', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))" as="xs:string"/>
        <xsl:param name="agent" as="xs:anyURI"/>
        
        <div class="ldhc-backdrop pos-top modal modal-constructor">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                <div class="ldhc-modal-head">
                    <div class="ldhc-modal-titles">
                        <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                            <xsl:value-of select="$legend-label"/>
                        </h2>
                        <span class="ldhc-modal-sub">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'request-access-description', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </span>
                    </div>
                    <span class="ldhc-modal-x">
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                    </span>
                </div>

                <div class="ldhc-modal-body">
                <form id="form-request-access" class="ldh-prop-form" method="POST" action="{$action}">
                    <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
            
                    <fieldset>
                        <div>
                            <label for="request-access-for">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'request-access-for', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <select id="request-access-for" class="input-block-level">
                                <option value="{$agent}">
                                    <xsl:value-of select="$agent"/> (<xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'me', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>)
                                </option>
                            </select>
                        </div>
                    </fieldset>

                    <div id="request-access-matrix">
                        <!-- content replaced by the ldh:access-response callback -->
                    </div>
                   
                    <div class="ldh-block-foot">
                        <button type="button" class="ldhc-btn in-neutral ap-outline sz-md btn-close">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="reset" class="ldhc-btn in-neutral ap-outline sz-md btn-reset">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="submit" class="{$button-class}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'request', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </form>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="request-access-matrix">
        <xsl:param name="agent" as="xs:anyURI"/>
        <!-- TO-DO: support agent-group? -->
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="access-modes" select="(xs:anyURI('&acl;Read'), xs:anyURI('&acl;Append'), xs:anyURI('&acl;Write'))" as="xs:anyURI*"/>
        <xsl:param name="base" select="lapp:origin($this)" as="xs:anyURI"/>
        
        <fieldset>
            <legend>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'url-based-access', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </xsl:value-of>
            </legend>
            <table class="table">
                <colgroup>
                    <col style="width: 55%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                </colgroup>
                <thead>
                    <tr>
                        <th>
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'url', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </th>
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
                                        group-by="acl:accessTo/@rdf:resource[starts-with(., $base)]">
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
            <legend>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'class-based-access', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </xsl:value-of>
            </legend>
            <table class="table">
                <colgroup>
                    <col style="width: 55%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                    <col style="width: 15%;"/>
                </colgroup>
                <thead>
                    <tr>
                        <th>
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'class-name', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </th>
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
                    <xsl:for-each-group select="($this-auth, rdf:Description[acl:accessToClass/@rdf:resource])"
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
                    <xsl:choose>
                        <xsl:when test="doc-available(ac:document-uri($access-to-class)) and key('resources', $access-to-class, document(ac:document-uri($access-to-class)))">
                            <xsl:apply-templates select="key('resources', $access-to-class, document(ac:document-uri($access-to-class)))" mode="ac:label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- fallback to class URI if label not found -->
                            <xsl:value-of select="$access-to-class"/>
                        </xsl:otherwise>
                    </xsl:choose>
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
                        <xsl:attribute name="class" select="'checkbox'"/>
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
        <xsl:param name="id" select="'form-reconcile'" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-md btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="action" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'reconcile-entity', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))" as="xs:string"/>
        <xsl:param name="resource" as="xs:anyURI"/>
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="service" as="xs:anyURI"/>
        
        <div class="ldhc-backdrop pos-top modal modal-constructor">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                <div class="ldhc-modal-head">
                    <div class="ldhc-modal-titles">
                        <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                            <xsl:value-of select="$legend-label"/>
                        </h2>
                    </div>
                    <span class="ldhc-modal-x">
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                    </span>
                </div>

                <div class="ldhc-modal-body">
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
                            <label class="control-label" for="same-as-resource">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'same-as', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <div class="controls">
                                <input id="same-as-resource" type="text" value="{$label}"/>
                                
                                <span class="help-inline">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </span>
                            </div>
                        </div>
                    </fieldset>
                </form>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- EVENT HANDLERS -->

    <!-- close modal first time message -->
    
    <xsl:template match="div[contains-token(@class, 'modal-first-time-message')]//button[contains-token(@class, 'close')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match/>
        
        <!-- set a cookie to never show it again. path=/ is scoped to the page origin (cookies are
             always scoped to the page origin anyway); using ldt:base() here previously broke in proxy
             mode where ldt:base() is the proxied app's base, not the page's. -->
        <ixsl:set-property name="cookie" select="'LinkedDataHub.first-time-message=true; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT'" object="ixsl:page()"/>
    </xsl:template>

    <!-- close modal dialog -->

    <xsl:template match="div[contains-token(@class, 'modal')]//button[tokenize(@class, ' ') = ('close', 'btn-close')]" mode="ixsl:onclick" name="ldh:CloseModal">
        <xsl:for-each select="ancestor::div[contains-token(@class, 'modal')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- a press on the backdrop itself (outside the dialog card) dismisses the dialog; presses inside land on a child, which the containment test filters out -->

    <xsl:template match="div[contains-token(@class, 'ldhc-backdrop')]" mode="ixsl:onclick">
        <xsl:variable name="target" select="ixsl:get(ixsl:event(), 'target')"/>

        <xsl:if test="empty(*[ixsl:call(., 'contains', [ $target ])])">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- Esc closes the topmost modal; predicate guard keeps Esc available to other widgets when no modal is open. priority="1" wins over graph3d.xsl's body keydown if both happen to match. -->
    <xsl:template match="body[descendant::div[contains-token(@class, 'modal')]]" mode="ixsl:onkeydown" priority="1">
        <xsl:if test="ixsl:get(ixsl:event(), 'key') = 'Escape'">
            <xsl:variable name="modal" select="(.//div[contains-token(@class, 'modal')])[last()]" as="element()"/>
            <xsl:sequence select="ixsl:call($modal, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>
    
    <!-- submit instance creation modal form using PUT -->

    <xsl:template match="div[contains-token(@class, 'modal-constructor')]//form[tokenize(@class, ' ') = ('ldh-prop-form', 'ldh-edit-form')][upper-case(@method) = 'PUT']" mode="ixsl:onsubmit" priority="2">
        <!-- ldh:constructor-form-response stamps render-fn=ldh:render-constructor-form#2 (mode="bs2:Form") so the violation re-render keeps co-shipped peer Descriptions (content blocks) visible. Higher-priority flow templates (e.g. inline view creation) re-stamp $callback and/or supply $request-body via xsl:next-match. -->
        <xsl:param name="callback" select="ldh:constructor-form-response#1" as="function(map(*)) as item()*"/>
        <xsl:param name="request-body" as="document-node()?"/>
        <xsl:next-match>
            <xsl:with-param name="callback" select="$callback"/>
            <xsl:with-param name="request-body" select="$request-body"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- Terminal callback for the action-bar add-constructor onclick promise chain (below).
         Reads context('constructed-doc') as the async-fetched SPIN-construction; the remaining
         sync document() calls for type-metadata/property-metadata/constraints are scope for a
         follow-up refactor. -->
    <!-- Promise-chain step: after ldh:set-constructed-doc, extract the new resource (by $forClass) and compute the inputs the downstream type-metadata / property-metadata / constraints async pairs need. Pure-XSLT (no I/O). -->
    <xsl:function name="ldh:set-add-modal-form-resource" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="constructed-doc" select="$context('constructed-doc')" as="document-node()"/>
        <xsl:variable name="forClass" select="$context('forClass')" as="xs:anyURI"/>
        <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
        <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:sequence select="map:merge(($context, map{
            'resource': $resource,
            'types': $types,
            'property-uris': distinct-values($resource/*/concat(namespace-uri(), local-name()))
        }), map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <xsl:function name="ldh:render-add-modal-form" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="content-body" select="$context('content-body')" as="element()"/>
        <xsl:variable name="forClass" select="$context('forClass')" as="xs:anyURI"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="base-uri" select="$context('base-uri')" as="xs:anyURI"/>
        <xsl:variable name="constructed-doc" select="$context('constructed-doc')" as="document-node()"/>
        <xsl:variable name="type-metadata" select="$context('type-metadata')" as="document-node()?"/>
        <xsl:variable name="property-metadata" select="$context('property-metadata')" as="document-node()?"/>
        <xsl:variable name="constraints" select="$context('constraints')" as="document-node()?"/>
        <xsl:variable name="classes" select="()" as="element()*"/>

        <xsl:for-each select="$content-body">
            <xsl:variable name="form" as="element()*">
                <xsl:apply-templates select="$constructed-doc" mode="bs2:Form">
                    <xsl:with-param name="about" select="()"/>
                    <xsl:with-param name="method" select="'put'"/>
                    <xsl:with-param name="action" select="ldh:href($doc-uri)" as="xs:anyURI" tunnel="yes"/>
                    <xsl:with-param name="form-actions-class" select="'ldh-form-bar'" as="xs:string?"/>
                    <xsl:with-param name="show-close-button" select="true()"/>
                    <xsl:with-param name="classes" select="$classes"/>
                    <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                    <xsl:with-param name="constructor" select="$constructed-doc" tunnel="yes"/>
                    <xsl:with-param name="constructors" select="()" tunnel="yes"/> <!-- can be empty because modal form is only used to create Container/Item instances -->
                    <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                    <xsl:with-param name="shapes" select="()" tunnel="yes"/> <!-- there will be no shapes as modal form is only used to create Container/Item instances -->
                    <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    <xsl:with-param name="required" select="function($r as element()) as xs:boolean { $r/rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item') }" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>


            <!-- a modal takes over from the chrome that opened it: a drop-down the pick came from is dismissed here, once its own handler has run -->
            <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'btn-group')][contains-token(@class, 'open')] | ixsl:page()//*[contains-token(@class, 'ldh-form-actions-wrap')][contains-token(@class, 'is-open')]" mode="ldh:CloseDropdown"/>
            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="ldhc-backdrop pos-top modal modal-constructor" about="{$doc-uri}" typeof="{$forClass}"> <!-- @about identifies the new resource URL (uniform with edit/settings modals so submit handlers can read $block/@about without a fallback); $forClass used by ldh:ResourceUpdated in case of 4xx response -->
                    <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                        <div class="ldhc-modal-head">
                            <div class="ldhc-modal-titles">
                                <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                                    <xsl:try select="ac:object-label($forClass)">
                                        <xsl:catch select="replace($forClass, '.*[#/]', '')"/>
                                    </xsl:try>
                                </h2>
                            </div>
                            <span class="ldhc-modal-x">
                                <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                            </span>
                        </div>

                        <div class="ldhc-modal-body">
                            <xsl:copy-of select="$form"/>
                        </div>
                    </div>
                </div>
            </xsl:result-document>

            <xsl:if test="id($form/@id, ixsl:page())">
                <xsl:apply-templates select="id($form/@id, ixsl:page())" mode="ldh:RenderRowForm"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>

    <!-- shows new SPIN-constructed document as a modal form -->
    <xsl:template match="div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'add-constructor')][@data-for-class]" mode="ixsl:onclick" priority="2">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="content-body" select="ancestor::div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>
        <xsl:variable name="forClass" select="xs:anyURI(@data-for-class)" as="xs:anyURI"/>
        <xsl:variable name="doc-uri" select="resolve-uri(ac:uuid() || '/', ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/> <!-- build a relative URI for the child document -->
        <xsl:variable name="this" select="$doc-uri" as="xs:anyURI"/>
        <xsl:variable name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="context" as="map(*)" select="map{
            'content-body': $content-body,
            'forClass': $forClass,
            'doc-uri': $doc-uri,
            'base-uri': $base-uri,
            'this': $this
        }"/>

        <ixsl:promise select="ixsl:resolve($context) =>
            ixsl:then(ldh:fire-load-set-parallel(?, [
              [ ldh:load-constructed-doc#1, 'constructed-doc-request', 'constructed-doc-response', ldh:set-constructed-doc#1 ]
            ])) =>
            ixsl:then(ldh:set-add-modal-form-resource#1) =>
            ixsl:then(ldh:fire-load-set-parallel(?, [
              [ ldh:load-type-metadata#1,     'type-metadata-request',     'type-metadata-response',     ldh:set-type-metadata#1 ],
              [ ldh:load-property-metadata#1, 'property-metadata-request', 'property-metadata-response', ldh:set-property-metadata#1 ],
              [ ldh:load-constraints#1,       'constraints-request',       'constraints-response',       ldh:set-constraints#1 ]
            ])) =>
            ixsl:then(ldh:render-add-modal-form#1) =>
            ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- open a form for document editing -->
    
    <xsl:template match="div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:param name="about" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/> <!-- editing the current document resources -->
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="form-actions-class" select="'ldh-form-bar'" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-sm'" as="xs:string?"/>
        <xsl:variable name="content-body" select="ancestor::div[contains-token(@class, 'tab-pane')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

<!--        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`')">
            <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>
        </xsl:if>-->
        <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $about || '`'))">
            <ixsl:set-property name="{'`' || $about || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:if>

        <xsl:variable name="block-id" select="'block-' || generate-id()" as="xs:string"/>
        <xsl:for-each select="$content-body">

            <!-- a modal takes over from the chrome that opened it: a drop-down the pick came from is dismissed here, once its own handler has run -->
            <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'btn-group')][contains-token(@class, 'open')] | ixsl:page()//*[contains-token(@class, 'ldh-form-actions-wrap')][contains-token(@class, 'is-open')]" mode="ldh:CloseDropdown"/>
            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="ldhc-backdrop pos-top modal modal-constructor" about="{$about}">
                    <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true">
                        <div class="ldhc-modal-head">
                            <span class="ldhc-modal-x">
                                <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                            </span>
                        </div>
                        <div class="ldhc-modal-body">
                            <!-- empty host block, uniform with the inline edit flow: ldh:render-form transplants the rendered form's block root onto it -->
                            <div id="{$block-id}" class="block ldh-block">
                                <!-- to be injected -->
                            </div>
                        </div>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:variable name="block" select="id($block-id, ixsl:page())" as="element()"/>
        
        <!-- if the URI is external, dereference it through the proxy -->
        <xsl:variable name="request-uri" select="ldh:href($about)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'block': $block,
            'about': $about,
            'method': $method,
            'endpoint': sd:endpoint(),
            'required': function($r as element()) as xs:boolean { $r/rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item') }
          }"/>
        <!-- Same structure as the app-settings chain below: ldh:fetch-and-load-edited-resource bakes a GET-style type-metadata-request, so the type-metadata pair uses an identity load-fn. The constructed-doc/constructors/shapes pairs mirror the inline row-form EDIT chain; ldh:render-document-form folds shapes + constructed-doc via ldh:build-merged-constructor into the 'constructor' tunnel. ldh:render-form has its own cursor reset (shared with app-settings); the finally here is the backstop for the failure-on-parallel path. -->
        <ixsl:promise select="
          ixsl:resolve($context)
            => ixsl:then(ldh:fetch-and-load-edited-resource#1)
            => ixsl:then(ldh:fire-load-set-parallel(?, [
                 [ function($ctx as map(*)) as map(*) { $ctx }, 'type-metadata-request',     'type-metadata-response',     ldh:set-type-metadata#1 ],
                 [ ldh:load-constructed-doc#1,                  'constructed-doc-request',   'constructed-doc-response',   ldh:set-constructed-doc#1 ],
                 [ ldh:load-constructors#1,                     'constructors-request',      'constructors-response',      ldh:set-constructors#1 ],
                 [ ldh:load-shapes#1,                           'shapes-request',            'shapes-response',            ldh:set-shapes#1 ],
                 [ ldh:load-property-metadata#1,                'property-metadata-request', 'property-metadata-response', ldh:set-property-metadata#1 ],
                 [ ldh:load-constraints#1,                      'constraints-request',       'constraints-response',       ldh:set-constraints#1 ],
                 [ ldh:load-object-metadata#1,                  'metadata-request',          'metadata-response',          ldh:set-object-metadata#1 ],
                 [ ldh:load-object-metadata#1,                  'ns-metadata-request',       'ns-metadata-response',       ldh:set-object-metadata-ns#1 ]
               ]))
            => ixsl:then(ldh:merge-object-metadata#1)
            => ixsl:then(ldh:render-form#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- submit document update modal form using PATCH TO-DO: unify!!! -->
    
    <xsl:template match="div[contains-token(@class, 'modal-constructor')]//form[tokenize(@class, ' ') = ('ldh-prop-form', 'ldh-edit-form')][upper-case(@method) = 'PATCH']" mode="ixsl:onsubmit" priority="2">
        <xsl:param name="block" select="ancestor::div[contains-token(@class, 'modal-constructor')]" as="element()"/>
        <xsl:param name="about" select="$block/@about" as="xs:anyURI"/>
        <!-- ldh:edit-form-response stamps render-fn=ldh:render-document-form#2 (mode="ldh:DocumentForm", narrow @rdf:about=$about filter) so the violation re-render stays focused on the edited resource. -->
        <xsl:param name="callback" select="ldh:edit-form-response#1" as="function(map(*)) as item()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="form" select="." as="element()"/>
        <xsl:variable name="method" select="upper-case(@method)" as="xs:string"/>
        <xsl:variable name="id" select="ixsl:get($form, 'id')" as="xs:string"/>
        <xsl:variable name="action" select="ixsl:get($form, 'action')" as="xs:anyURI"/>
        <xsl:variable name="enctype" select="ixsl:get($form, 'enctype')" as="xs:string"/>
        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>

        <xsl:sequence select="ldh:busy-cursor()"/>
        
        <!-- pre-process form before submitting it -->
        <xsl:apply-templates select="." mode="ldh:FormPreSubmit"/>

        <xsl:variable name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:variable name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <!-- need a customer DELETE/WHERE pattern because the default $about ?p ?o would delete system properties such as dct:created or sioc:has_parent -->
        <xsl:variable name="where-pattern" as="element()*">
            <json:map>
                <json:string key="type">bgp</json:string>
                <json:array key="triples">
                    <json:map>
                        <json:string key="subject"><xsl:value-of select="$about"/></json:string>
                        <json:string key="predicate">?p</json:string>
                        <json:string key="object">?o</json:string>
                    </json:map>
                </json:array>
            </json:map>
            <json:map>
                <json:string key="type">filter</json:string>
                <json:map key="expression">
                    <json:string key="type">operation</json:string>
                    <json:string key="operator">notin</json:string>
                    <json:array key="args">
                        <json:string>?p</json:string>
                        <json:array>
                            <json:string>&dct;reated</json:string>
                            <json:string>&dct;modified</json:string>
                            <json:string>&sioc;has_parent</json:string>
                            <json:string>&sioc;has_container</json:string>
                            <json:string>&dct;creator</json:string>
                            <json:string>&acl;owner</json:string>
                        </json:array>
                    </json:array>
                </json:map>
            </json:map>
            <json:map>
                <json:string key="type">filter</json:string>
                <json:map key="expression">
                    <json:string key="type">operation</json:string>
                    <json:string key="operator">!</json:string>
                    <json:array key="args">
                        <json:map>
                            <json:string key="type">operation</json:string>
                            <json:string key="operator">strstarts</json:string>
                            <json:array key="args">
                                <json:map>
                                    <json:string key="type">operation</json:string>
                                    <json:string key="operator">str</json:string>
                                    <json:array key="args">
                                        <json:string>?p</json:string>
                                    </json:array>
                                </json:map>
                                <json:map>
                                    <json:string key="type">operation</json:string>
                                    <json:string key="operator">concat</json:string>
                                    <json:array key="args">
                                        <json:map>
                                            <json:string key="type">operation</json:string>
                                            <json:string key="operator">str</json:string>
                                            <json:array key="args">
                                                <json:string>http://www.w3.org/1999/02/22-rdf-syntax-ns#</json:string>
                                            </json:array>
                                        </json:map>
                                        <json:string>"_"</json:string>
                                    </json:array>
                                </json:map>
                            </json:array>
                        </json:map>
                    </json:array>
                </json:map>
            </json:map>
        </xsl:variable>
        <xsl:variable name="update-string" select="ldh:insertdelete-update(ldh:triples-to-bgp(ldh:uri-po-pattern($about)), ldh:triples-to-bgp($triples), $where-pattern)" as="xs:string"/>
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
        <!-- 'about' = the resource URL being submitted to; the wrapping block carries it on @about uniformly (btn-edit / btn-app-settings / Container-Item creation modals all set it). $doc-uri is the page URL and can't be used for this -->
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'doc-uri': ac:absolute-path(ldh:base-uri(.)),
            'about': xs:anyURI($block/@about),
            'block': $block,
            'form': $form,
            'resources': $resources
          }"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then($callback) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-add-ontology')]" mode="ixsl:onclick">
        <xsl:variable name="target" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>
        <xsl:variable name="graph" select="ldh:base-uri(.)" as="xs:anyURI"/>

        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:AddDataForm">
                    <xsl:with-param name="query" select="resolve-uri('queries/construct-constructors/#this', ldt:base())"/>
                    <xsl:with-param name="legend-label" select="ac:label(key('resources', 'import-ontology', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="target" select="$target"/>
        </xsl:call-template>

        <xsl:call-template name="ldh:LoadTypeaheads">
            <xsl:with-param name="typeahead-spans" select="(id('upload-rdf-doc', ixsl:page())/.., id('remote-rdf-doc', ixsl:page())/..)"/>
            <xsl:with-param name="graph" select="$graph"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-generate-containers')]" mode="ixsl:onclick">
        <xsl:variable name="target" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>
        <xsl:variable name="graph" select="ldh:base-uri(.)" as="xs:anyURI"/>

        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:GenerateContainersForm"/>
            </xsl:with-param>
            <xsl:with-param name="target" select="$target"/>
        </xsl:call-template>

        <!-- initialise the parent typeahead with the current container -->
        <xsl:call-template name="ldh:LoadTypeaheads">
            <xsl:with-param name="typeahead-spans" select="id('generate-containers-parent', ixsl:page())/.."/>
            <xsl:with-param name="graph" select="$graph"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-app-settings')]" mode="ixsl:onclick">
        <xsl:param name="id" select="'app-settings'" as="xs:string?"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:variable name="content-body" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:for-each select="$content-body">

            <!-- a modal takes over from the chrome that opened it: a drop-down the pick came from is dismissed here, once its own handler has run -->
            <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'btn-group')][contains-token(@class, 'open')] | ixsl:page()//*[contains-token(@class, 'ldh-form-actions-wrap')][contains-token(@class, 'is-open')]" mode="ldh:CloseDropdown"/>
            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="ldhc-backdrop pos-top modal modal-constructor" about="{lapp:application()}">
                    <xsl:if test="$id">
                        <xsl:attribute name="id" select="$id"/>
                    </xsl:if>

                    <div class="ldhc-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                    <div class="ldhc-modal-head">
                        <div class="ldhc-modal-titles">
                            <h2 class="ldhc-modal-title" id="modal-title-{generate-id()}">
                                <xsl:apply-templates select="key('resources', 'application-settings', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </h2>
                        </div>
                        <span class="ldhc-modal-x">
                            <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                        </span>
                    </div>
                    <div class="ldhc-modal-body">
                        <!-- to be injected -->
                    </div>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:variable name="modal" select="$content-body/div[contains-token(@class, 'modal')][last()]" as="element()"/>
        <xsl:variable name="block" select="($modal//div[contains-token(@class, 'ldhc-modal-body')])[1]" as="element()"/>
        <!-- settings UI is a single global button, not per-tab; target the local app's settings, not the active tab's dataspace -->
        <xsl:variable name="settings-uri" select="resolve-uri('settings', xs:anyURI(lapp:origin(ldh:request-uri()) || '/'))" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $settings-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'block': $block,
            'about': lapp:application(),
            'method': $method,
            'action': $settings-uri,
            'endpoint': sd:endpoint(),
            'required': function($r as element()) as xs:boolean { true() }
          }"/>
        <!-- ldh:fetch-and-load-edited-resource bakes a GET-style type-metadata-request into context, so the type-metadata pair uses an identity load-fn rather than ldh:load-type-metadata (which would build a different POST-style request). ldh:render-app-settings-form has its own cursor reset (shared with btn-edit modal); the finally here is the backstop for the failure-on-parallel path. -->
        <ixsl:promise select="
          ixsl:resolve($context)
            => ixsl:then(ldh:fetch-and-load-edited-resource#1)
            => ixsl:then(ldh:fire-load-set-parallel(?, [
                 [ function($ctx as map(*)) as map(*) { $ctx }, 'type-metadata-request',     'type-metadata-response',     ldh:set-type-metadata#1 ],
                 [ ldh:load-property-metadata#1,                'property-metadata-request', 'property-metadata-response', ldh:set-property-metadata#1 ],
                 [ ldh:load-constraints#1,                      'constraints-request',       'constraints-response',       ldh:set-constraints#1 ],
                 [ ldh:load-object-metadata#1,                  'metadata-request',          'metadata-response',          ldh:set-object-metadata#1 ],
                 [ ldh:load-object-metadata#1,                  'ns-metadata-request',       'ns-metadata-response',       ldh:set-object-metadata-ns#1 ],
                 [ ldh:load-package-catalog#1,                  'package-catalog-request',   'package-catalog-response',   ldh:set-package-catalog#1 ]
               ]))
            => ixsl:then(ldh:merge-object-metadata#1)
            => ixsl:then(ldh:render-app-settings-form#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- submit application settings modal form using PATCH with custom callback -->

    <xsl:template match="div[@id = 'app-settings']//form[upper-case(@method) = 'PATCH']" mode="ixsl:onsubmit" priority="3">
        <xsl:next-match>
            <xsl:with-param name="callback" select="ldh:settings-form-response#1"/>
        </xsl:next-match>
    </xsl:template>

    <!-- form-flavor wrapper mode parallel to ldh:DocumentForm; scopes the app-settings UI restrictions (dct:title / dct:description visible, everything else hidden) to this flow. The mode itself is the discriminator — instances of lapp:Application created via the generic Create button continue to render through ldh:DocumentForm → bs2:FormControl unaffected. -->
    <xsl:template match="rdf:RDF" mode="ldh:AppSettingsForm">
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="form-actions-class" select="'ldh-form-bar'" as="xs:string?"/>
        <xsl:param name="package-catalog" as="document-node()?" tunnel="yes"/>
        <xsl:call-template name="bs2:Form">
            <xsl:with-param name="method" select="$method"/>
            <xsl:with-param name="form-actions-class" select="$form-actions-class"/>
            <xsl:with-param name="show-close-button" select="true()"/>
            <xsl:with-param name="body" as="node()*">
                <xsl:apply-templates mode="bs2:Exception"/>
                <xsl:apply-templates mode="#current"/>

                <!-- package checkboxes serialize as RDF/POST ldh:import inputs, submitted by the same form -->
                <xsl:apply-templates select="$package-catalog/rdf:RDF" mode="ldh:PackageList">
                    <xsl:with-param name="installed" select="for $import in */ldh:import/@rdf:resource return xs:anyURI($import)"/>
                </xsl:apply-templates>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- per-Description for the editable lapp:Application: reuse the bs2:FormControl shell with type-hidden / no PropertyControl. Do NOT override $body: the shell's default body merges resource properties with the constructor template, sorts by constraints, and passes violations/constructor/type-constraints/type-shapes as with-params to per-property templates. Default body's mode="#current" = ldh:AppSettingsForm here (call-template doesn't change current mode), so the suppression / delegate templates below fire correctly. -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&lapp;Application']" mode="ldh:AppSettingsForm">
        <xsl:param name="about" as="xs:anyURI" tunnel="yes"/>
        <xsl:if test="@rdf:about = $about">
            <xsl:call-template name="bs2:FormControl">
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                <xsl:with-param name="required" select="true()"/>
                <xsl:with-param name="type-hidden" select="true()"/>
                <xsl:with-param name="show-property-control" select="false()"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- suppress unrelated Descriptions in the response graph (mirrors ldh:DocumentForm's @rdf:about = $about filter) -->
    <xsl:template match="*" mode="ldh:AppSettingsForm"/>

    <!-- restrict the application settings form UI to dct:title / dct:description; render every other app property as hidden inputs so the PATCH still carries them and they're preserved server-side. The value-bearing children (text / @rdf:resource / @rdf:nodeID / @xml:lang / @rdf:datatype) are dispatched in mode="bs2:FormControl" — that's where the per-type hidden-input renderers live (imports/default.xsl @rdf:resource, @rdf:datatype, text() templates). Using mode="#current" would dispatch them in ldh:AppSettingsForm mode where they have no template and XSLT defaults emit raw text. -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&lapp;Application']/*[not(self::dct:title or self::dct:description or self::rdf:type)]" mode="ldh:AppSettingsForm" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="bs2:FormControl">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="bs2:FormControl">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- ldh:import is represented by the package checkboxes in the same form, not round-tripped as hidden inputs -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&lapp;Application']/ldh:import" mode="ldh:AppSettingsForm" priority="2"/>

    <!-- dct:title / dct:description / rdf:type fall through to the generic bs2:FormControl rendering. Forward the with-params from the shell's default body iteration (violations / constructor / type-constraints / type-shapes) so the per-property template at imports/default.xsl:744 can compute $required correctly (required-class bolding) and render constraint violations. -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&lapp;Application']/*" mode="ldh:AppSettingsForm">
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="constructor" as="document-node()?"/>
        <xsl:param name="type-constraints" as="element()*"/>
        <xsl:param name="type-shapes" as="element()*"/>
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:with-param name="violations" select="$violations"/>
            <xsl:with-param name="constructor" select="$constructor"/>
            <xsl:with-param name="type-constraints" select="$type-constraints"/>
            <xsl:with-param name="type-shapes" select="$type-shapes"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-access-form')]" mode="ixsl:onclick">
        <!-- TO-DO: fix for admin apps -->
        <xsl:param name="this" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('access', lapp:origin($this)), map{ 'this': $this }))" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'agent': $acl:agent,
            'this': $this
          }"/>

        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:access-response#1)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-reconcile')]" mode="ixsl:onclick">
        <xsl:variable name="resource" select="input[@name = 'resource']/@value" as="xs:anyURI"/>
        <xsl:variable name="label" select="input[@name = 'label']/@value" as="xs:string"/>
        <xsl:variable name="service" select="input[@name = 'service']/@value" as="xs:anyURI"/>
        <xsl:variable name="target" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>

        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:ReconcileForm">
                    <xsl:with-param name="resource" select="$resource"/>
                    <xsl:with-param name="label" select="$label"/>
                    <xsl:with-param name="service" select="$service"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="target" select="$target"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- generate containers: client-orchestrated. For each checked class, build a container document (an Object-wrapped View over a $type-parameterized SELECT) and PUT it under the parent. Parallel fan-out joined by ixsl:all. Replaces the former server-side /generate endpoint. -->
    <xsl:template match="form[@id = 'form-generate-containers']" mode="ixsl:onsubmit" priority="2">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')]" as="element()*"/>
        <xsl:variable name="required-control-groups" select="$control-groups[contains-token(@class, 'required')]" as="element()*"/>
        <xsl:variable name="checked-classes" select="descendant::div[contains-token(@class, 'endpoint-classes')]//input[@type = 'checkbox'][ixsl:get(., 'checked')]" as="element()*"/>

        <!-- clear the errors initially -->
        <xsl:for-each select="$control-groups">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:choose>
            <!-- required input values missing (parent, limit), throw an error -->
            <xsl:when test="exists($required-control-groups/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:sequence select="$required-control-groups[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- no class checked (or schema never loaded): flag the classes control-group -->
            <xsl:when test="empty($checked-classes)">
                <xsl:sequence select="descendant::div[contains-token(@class, 'endpoint-classes')]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present: build and PUT one container document per checked class -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:busy-cursor()"/>

                <xsl:variable name="form" select="." as="element()"/>
                <xsl:variable name="parent" select="$control-groups[input[@name = 'pu'][@value = '&sioc;has_parent']]/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                <!-- normalize the parent to a trailing slash so container URIs resolve as its children -->
                <xsl:variable name="parent" select="xs:anyURI(if (ends-with($parent, '/')) then $parent else $parent || '/')" as="xs:anyURI"/>
                <xsl:variable name="service" select="$control-groups[input[@name = 'pu'][@value = '&ldh;service']]/descendant::input[@name = 'ou']/ixsl:get(., 'value')[. != '']" as="xs:anyURI?"/>
                <!-- extract the checked classes as pure data; the http-requests are fired later, inside the promise context (ldh:generate-containers-fanout) -->
                <xsl:variable name="parts" as="map(*)*" select="
                  for $checkbox in $checked-classes return
                    map{
                      'class': xs:anyURI(ixsl:get($checkbox, 'value')),
                      'query-uri': xs:anyURI($checkbox/ancestor::li/input[@name = 'ou'][@value = ('&ldh;SelectInstances', '&ldh;SelectInstancesInGraphs')]/@value)
                    }"/>

                <xsl:variable name="context" as="map(*)" select="map{ 'form': $form, 'parent': $parent, 'service': $service, 'parts': $parts }"/>

                <!-- seed a resolved promise so the fan-out's ixsl:http-request calls run in an active promise context (mirrors ldh:fire-load-set-parallel kickoff) -->
                <ixsl:promise select="
                  ixsl:resolve($context)
                    => ixsl:then(ldh:generate-containers-fanout#1) =>
                    ixsl:finally(ldh:reset-cursor#0)
                " on-failure="ldh:promise-failure#1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- import-ontology variant (carries a spin:query): client-orchestrated. Fetch the dct:source through the same-origin ?uri= proxy as RDF/XML and PUT it into a scratch document (document metadata + raw vocabulary in one graph), run the spin:query CONSTRUCT over the scratch graph via the SPARQL Protocol dataset specification (?default-graph-uri=) on the /sparql endpoint, append the derived constructors plus the annotation-ontology header (sd:name target a owl:Ontology; owl:imports dct:source) to the target document, then delete the scratch. Only the derived annotations persist - the vocabulary resolves live through the graph repository (bundled mapping or HTTP), so the target holds the same artifact shape a package ontology ships (constructors + owl:imports of the canonical vocabulary URI). -->
    <xsl:template match="form[@id = 'form-clone-data'][fieldset/input[@name = 'pu'][@value = '&spin;query']]" mode="ixsl:onsubmit" priority="2">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')]" as="element()*"/>
        <xsl:variable name="required-control-groups" select="$control-groups[contains-token(@class, 'required')]" as="element()*"/>

        <!-- clear the errors initially -->
        <xsl:for-each select="$control-groups">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:choose>
            <!-- required input values missing, throw an error -->
            <xsl:when test="exists($required-control-groups/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:sequence select="$required-control-groups[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present, orchestrate the import + constructor derivation -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:busy-cursor()"/>

                <!-- pre-process form before submitting it (trims ou values) -->
                <xsl:apply-templates select="." mode="ldh:FormPreSubmit"/>

                <xsl:variable name="form" select="." as="element()"/>
                <xsl:variable name="source" select="$control-groups[input[@name = 'pu'][@value = '&dct;source']]/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                <xsl:variable name="target" select="$control-groups[input[@name = 'pu'][@value = '&sd;name']]/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                <xsl:variable name="query-uri" select="fieldset/input[@name = 'pu'][@value = '&spin;query']/following-sibling::input[@name = 'ou'][1]/@value" as="xs:anyURI"/>
                <xsl:choose>
                    <!-- the target must be local because the constructor derivation runs on the local /sparql endpoint scoped to the target graph via ?default-graph-uri= - another instance's graphs are invisible to it (the add/clone variant below has no such constraint and accepts foreign targets) -->
                    <xsl:when test="not(starts-with($target, lapp:origin(ldh:request-uri()) || '/'))">
                        <xsl:sequence select="ldh:add-data-form-error(map{ 'form': $form }, 'target-must-be-local')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- ldh:href routes the arbitrary external $source through the same-origin ?uri= proxy (CORS); the proxy also converts any Jena-parseable format to the requested RDF/XML. The target is local, so its ldh:href is a pass-through and the POST goes directly to it. -->
                        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($source), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                        <xsl:variable name="context" as="map(*)" select="
                          map{
                            'request': $request,
                            'form': $form,
                            'source-uri': $source,
                            'target-uri': $target,
                            'query-uri': $query-uri,
                            'scratch-uri': resolve-uri(ac:uuid() || '/', ldt:base())
                          }"/>
                        <ixsl:promise select="
                          ixsl:http-request($context('request'))
                            => ixsl:then(ldh:rethread-response($context, ?))
                            => ixsl:then(ldh:handle-response#1)
                            => ixsl:then(ldh:import-ontology-source-response#1) =>
                            ixsl:finally(ldh:reset-cursor#0)
                        " on-failure="ldh:promise-failure#1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- add/clone variant (no spin:query): client-orchestrated. Fetch the dct:source through the same-origin ?uri= proxy as RDF/XML, then GSP-append it to the sd:name target document. Replaces the former server-side /add endpoint. -->
    <xsl:template match="form[@id = 'form-clone-data'][not(fieldset/input[@name = 'pu'][@value = '&spin;query'])]" mode="ixsl:onsubmit" priority="2">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')]" as="element()*"/>
        <xsl:variable name="required-control-groups" select="$control-groups[contains-token(@class, 'required')]" as="element()*"/>

        <!-- clear the errors initially -->
        <xsl:for-each select="$control-groups">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:choose>
            <!-- required input values missing, throw an error -->
            <xsl:when test="exists($required-control-groups/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:sequence select="$required-control-groups[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present, orchestrate the proxy fetch + append -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:busy-cursor()"/>

                <!-- pre-process form before submitting it (trims ou values) -->
                <xsl:apply-templates select="." mode="ldh:FormPreSubmit"/>

                <xsl:variable name="form" select="." as="element()"/>
                <xsl:variable name="source" select="$control-groups[input[@name = 'pu'][@value = '&dct;source']]/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                <xsl:variable name="target" select="$control-groups[input[@name = 'pu'][@value = '&sd;name']]/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                <!-- ldh:href routes the arbitrary external $source through the same-origin ?uri= proxy (CORS); the proxy also converts any Jena-parseable format to the requested RDF/XML. The target may be foreign too: its POST rides the same proxy, which forwards the method, body and delegated agent identity - the target instance's ACL arbitrates and a 403 surfaces as the form error -->
                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($source), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="context" as="map(*)" select="
                  map{
                    'request': $request,
                    'form': $form,
                    'target-uri': $target
                  }"/>
                <ixsl:promise select="
                  ixsl:http-request($context('request'))
                    => ixsl:then(ldh:rethread-response($context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:add-data-source-response#1) =>
                    ixsl:finally(ldh:reset-cursor#0)
                " on-failure="ldh:promise-failure#1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-load-endpoint-schema')]" mode="ixsl:onclick">
        <xsl:sequence select="ldh:busy-cursor()"/>

        <xsl:variable name="fieldset" select="ancestor::form/fieldset" as="element()"/>
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')]" as="element()*"/>
        <xsl:variable name="required-control-groups" select="$control-groups[contains-token(@class, 'required')]" as="element()*"/>
        <xsl:variable name="timeout" select="30000" as="xs:integer"/> <!-- schema load query timeout in milliseconds -->
        <xsl:variable name="service-control-group" select="$fieldset/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&ldh;service']]" as="element()"/>
        <xsl:variable name="service-uri" select="$service-control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI?"/>
        <xsl:variable name="limit-control-group" select="$fieldset/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sp;limit']]" as="element()"/>
        <xsl:variable name="limit-string" select="$limit-control-group/descendant::input[@name = 'ol']/ixsl:get(., 'value')" as="xs:string"/>
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
        <!-- resolve the endpoint (async fetch of the service description when a service is selected, otherwise local), then fetch the class-discovery results; keeps the whole flow non-blocking so the progress cursor shows -->
        <xsl:variable name="context" as="map(*)" select="
          map{
            'query-string': $query-string,
            'service-uri': $service-uri,
            'local-endpoint': sd:endpoint(),
            'fieldset': $fieldset
          }"/>
        <ixsl:promise select="
          ixsl:resolve($context)
            => ixsl:then(ldh:load-schema-endpoint#1)
            => ixsl:then(ldh:load-schema-results#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- resolve the SPARQL endpoint for schema discovery: when a service is selected, asynchronously fetch its description and read sd:endpoint; otherwise use the local endpoint. Returns a promise of the context with 'endpoint' set. -->
    <xsl:function name="ldh:load-schema-endpoint" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="service-uri" select="$context('service-uri')" as="xs:anyURI?"/>
        <xsl:choose>
            <xsl:when test="$service-uri">
                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href(ac:build-uri(ldt:base(), map{ 'uri': ac:document-uri($service-uri), 'accept': 'application/rdf+xml' })), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($request)
                    => ixsl:then(ldh:rethread-response($context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:load-schema-endpoint-from-service#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:resolve(map:put($context, 'endpoint', $context('local-endpoint')))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- extract the sd:endpoint of the selected service from its fetched description -->
    <xsl:function name="ldh:load-schema-endpoint-from-service" as="map(*)">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="service-uri" select="$context('service-uri')" as="xs:anyURI"/>
        <xsl:variable name="body" select="$context('response')?body" as="document-node()"/>
        <xsl:variable name="endpoint" select="key('resources', $service-uri, $body)/sd:endpoint/@rdf:resource" as="xs:anyURI"/>
        <xsl:sequence select="map:put($context, 'endpoint', $endpoint)"/>
    </xsl:function>

    <!-- fetch the class-discovery SELECT results from the resolved endpoint and render the class list -->
    <xsl:function name="ldh:load-schema-results" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="results-uri" select="ac:build-uri($context('endpoint'), map{ 'query': $context('query-string') })" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($results-uri), 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:variable name="ctx" as="map(*)" select="map:merge(($context, map{ 'request': $request, 'container': $context('fieldset') }))"/>
        <xsl:sequence select="
          ixsl:http-request($request)
            => ixsl:then(ldh:rethread-response($ctx, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:endpoint-classes-response#1)
        "/>
    </xsl:function>

    <!-- validate form before submitting it and show errors on required control-groups where input values are missing -->
    <xsl:template match="form[@id = 'form-request-access']" mode="ixsl:onsubmit" priority="1">
        <xsl:param name="callback" select="ldh:request-access-form-response#1" as="function(map(*)) as item()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="form" select="." as="element()"/>

        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- disable hidden inputs on table rows where all acl:mode checkboxes are a) disabled by default b) enabled but left unchecked -->
        <!-- otherwise RDF/POST will generate acl:Authorization instances without acl:mode values which will fail constraint validation -->
        <!-- we don't want to use the values of disabled checkboxes in the request because those authorizations already exist -->
        <xsl:for-each select="$form//tbody/tr[every $checkbox in descendant::input[@type = 'checkbox'][@name = 'ou'] satisfies (ixsl:get($checkbox, 'disabled') or not(ixsl:get($checkbox, 'disabled')) and not(ixsl:get($checkbox, 'checked')))]//input">
            <ixsl:set-property name="disabled" select="true()" object="."/>
        </xsl:for-each>

        <xsl:variable name="method" select="ixsl:get(., 'method')" as="xs:string"/>
        <xsl:variable name="action" select="ixsl:get(., 'action')" as="xs:anyURI"/>
        <xsl:variable name="enctype" select="ixsl:get(., 'enctype')" as="xs:string"/>
        <xsl:variable name="form-data" select="ixsl:new('URLSearchParams', [ ixsl:new('FormData', [ $form ]) ])"/>
        <xsl:variable name="request-uri" select="ldh:href($action, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': $method, 'href': $request-uri, 'media-type': $enctype, 'body': $form-data, 'headers': map{} }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'form': $form
          }"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then($callback) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <xsl:template match="input[contains-token(@class, 'subject-slug')]" mode="ixsl:onkeyup" priority="1">
        <xsl:param name="slug" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:param name="rdf-post-subj-input" select="preceding-sibling::input[@name = 'su']" as="element()"/>
        <xsl:param name="form" select="ancestor::form" as="element()?"/>
        <xsl:param name="modal" select="ancestor::div[contains-token(@class, 'modal-constructor')]" as="element()?"/>
        <!-- URL-encode the slug value, resolve it against base URI and add trailing slash -->
        <xsl:param name="new-uri" select="ac:absolute-path(ldh:base-uri(.)) || encode-for-uri($slug) || '/'" as="xs:string"/>

        <!-- set it as the new subject URI ("su" input value) -->
        <ixsl:set-attribute name="value" select="$new-uri" object="$rdf-post-subj-input"/>
        <!-- also set it as the new form action value -->
        <ixsl:set-attribute name="action" select="$new-uri" object="$form"/>
        <!-- keep the modal wrapper @about in sync so the submit handler's $block/@about discriminator matches the resource the form will PUT to -->
        <xsl:if test="exists($modal)">
            <ixsl:set-attribute name="about" select="$new-uri" object="$modal"/>
        </xsl:if>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <!-- Per-flow wrappers that stamp 'render-fn' and 'required' before delegating to the shared ldh:modal-form-response. The 'required' function mirrors each flow's initial-render chain so the violation re-render agrees with it. ixsl:updating="yes" is required because ldh:modal-form-response writes to result documents (via ldh:DocumentNavigate / ldh:form-submit-created); an inline function literal can't carry that attribute, hence these named wrappers. -->
    <xsl:function name="ldh:constructor-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:sequence select="ldh:modal-form-response(map:merge(($context, map{ 'render-fn': ldh:render-constructor-form#2, 'required': function($r as element()) as xs:boolean { $r/rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item') } }), map{ 'duplicates': 'use-last' }))"/>
    </xsl:function>

    <xsl:function name="ldh:edit-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <!-- 'load-pairs' rides the violation chain's shared pair list so the re-render gets the same constructed-doc/constructors/shapes input as the initial edit render (ldh:render-document-form folds them into the 'constructor' tunnel) -->
        <xsl:sequence select="ldh:modal-form-response(map:merge(($context, map{
            'render-fn': ldh:render-document-form#2,
            'required': function($r as element()) as xs:boolean { $r/rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item') },
            'load-pairs': [
                [ ldh:load-constructed-doc#1, 'constructed-doc-request', 'constructed-doc-response', ldh:set-constructed-doc#1 ],
                [ ldh:load-constructors#1,    'constructors-request',    'constructors-response',    ldh:set-constructors#1 ],
                [ ldh:load-shapes#1,          'shapes-request',          'shapes-response',          ldh:set-shapes#1 ]
            ]
        }), map{ 'duplicates': 'use-last' }))"/>
    </xsl:function>

    <xsl:function name="ldh:modal-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>
        
        <xsl:message>ldh:modal-form-response</xsl:message>

        <xsl:choose>
            <xsl:when test="$status = (200, 204)">
                <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
                <xsl:variable name="form" select="$context('form')" as="element()?"/>
                <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="fragment" select="()"/>
                    <!-- carry the active layout mode over the reload, but only when reloading the document the page currently displays (a PUT overwrite lands here too, with $doc-uri pointing at a different document); ?version/?timemap must not survive the save — they would pin the pre-edit snapshot -->
                    <xsl:with-param name="query-params" select="if ($doc-uri = ldh:parse-href(ldh:request-uri())?doc-uri and exists(ldh:query-params()?mode)) then map{ 'mode': ldh:query-params()?mode } else map{}"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$status = 201 and map:contains($response?headers, 'location')">
                <xsl:sequence select="ldh:form-submit-created($context)"/>
            </xsl:when>
            <xsl:when test="$status = (400, 422) and starts-with($media-type, 'application/rdf+xml')">
              <xsl:sequence select="ldh:modal-form-submit-violation($context)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:error-response-alert($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    

    <!-- show modal form -->

    <xsl:template name="ldh:ShowModalForm">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="target" as="element()"/>

        <!-- the menu pick that reached here has served its purpose - the drop-down it came from closes behind the modal -->
        <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'btn-group')][contains-token(@class, 'open')] | ixsl:page()//*[contains-token(@class, 'ldh-form-actions-wrap')][contains-token(@class, 'is-open')]" mode="ldh:CloseDropdown"/>

        <!-- per-pane modal ids guarantee uniqueness, so the page-wide existence check suffices -->
        <xsl:if test="not(id($form/@id, ixsl:page()))">
            <xsl:for-each select="$target">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:sequence select="$form"/>
                </xsl:result-document>

                <ixsl:set-style name="cursor" select="'default'"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- populate typeahead spans inside a freshly-appended form modal with values from $graph -->

    <xsl:template name="ldh:LoadTypeaheads">
        <xsl:param name="typeahead-spans" as="element()*"/>
        <xsl:param name="graph" as="xs:anyURI"/>

        <xsl:variable name="request-uri" select="ldh:href($graph, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:for-each select="$typeahead-spans">
            <xsl:variable name="context" as="map(*)" select="
              map{
                'request': $request,
                'resource-uri': $graph,
                'typeahead-span': .
              }"/>
            <ixsl:promise select="
              ixsl:http-request($context('request'))
                => ixsl:then(ldh:rethread-response($context, ?))
                => ixsl:then(ldh:handle-response#1)
                => ixsl:then(ldh:typeahead-resource-response#1)
            " on-failure="ldh:promise-failure#1"/>
        </xsl:for-each>
    </xsl:template>

    <!-- render schema classes loaded from a SPARQL endpoint -->

    <xsl:function name="ldh:endpoint-classes-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>

        <xsl:message>ldh:endpoint-classes-response</xsl:message>

        <!-- append the controls for the class list if they don't exist -->
        <xsl:for-each select="$container[not(./div[contains-token(@class, 'endpoint-classes')])]">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="control-group required endpoint-classes">
                    <label class="control-label">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'classes', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </label>
                    <div class="controls"></div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="$status = 200 and $media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="$response?body">
                    <xsl:variable name="results" select="." as="document-node()"/>

                    <!-- populate the class list within div.controls -->
                    <xsl:for-each select="$container//div[contains-token(@class, 'endpoint-classes')]/div">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <ul class="unstyled">
                                <xsl:for-each select="$results/srx:sparql/srx:results/srx:result">
                                    <li>
                                        <!-- the query URI the submit handler reads (SELECT whose $type it substitutes with the checked class); the checkbox carries the class URI -->
                                        <xsl:choose>
                                            <xsl:when test="srx:binding[@name = 'namedGraph']/srx:uri">
                                                <input type="hidden" name="ou" value="&ldh;SelectInstancesInGraphs"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <input type="hidden" name="ou" value="&ldh;SelectInstances"/>
                                            </xsl:otherwise>
                                        </xsl:choose>

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

                    <!-- schema loaded: enable the Generate button -->
                    <xsl:for-each select="$container/ancestor::form//button[contains-token(@class, 'btn-save')]">
                        <ixsl:set-property name="disabled" select="false()" object="."/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[contains-token(@class, 'endpoint-classes')]/div">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <!-- a region of the modal form, not a block body, so the bare alert -->
                        <xsl:sequence select="ldh:error-alert('classes-not-loaded', ldh:http-error-key($response?status), ())"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="ldh:typeahead-resource-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>
        <xsl:variable name="resource-uri" select="$context('resource-uri')" as="xs:anyURI"/>
        <xsl:variable name="typeahead-span" select="$context('typeahead-span')" as="element()"/>

        <xsl:message>ldh:typeahead-resource-response</xsl:message>

        <xsl:choose>
            <xsl:when test="$status = 200 and $media-type = 'application/rdf+xml'">
                <xsl:for-each select="$response?body">
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
                <xsl:sequence select="ldh:error-response-alert($context)"/>
            </xsl:otherwise>
        </xsl:choose>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:function>
    
    <xsl:function name="ldh:access-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>
        <xsl:variable name="agent" select="$context('agent')" as="xs:anyURI"/>
        <xsl:variable name="this" select="$context('this')" as="xs:anyURI"/>

        <xsl:message>ldh:access-response</xsl:message>

        <xsl:choose>
            <xsl:when test="$status = 200 and $media-type = 'application/rdf+xml'">
                <xsl:variable name="body" select="$response?body" as="document-node()"/>
                <xsl:variable name="target" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>

                <xsl:call-template name="ldh:ShowModalForm">
                    <xsl:with-param name="form" as="element()">
                        <xsl:apply-templates select="$body" mode="ldh:RequestAccessForm">
                            <xsl:with-param name="this" select="$this"/>
                            <xsl:with-param name="agent" select="$agent"/>
                        </xsl:apply-templates>
                    </xsl:with-param>
                    <xsl:with-param name="target" select="$target"/>
                </xsl:call-template>

                <xsl:for-each select="id('request-access-matrix', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:apply-templates select="$body/rdf:RDF" mode="request-access-matrix">
                            <xsl:with-param name="agent" select="$agent"/>
                            <xsl:with-param name="this" select="$this"/>
                        </xsl:apply-templates>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:error-response-alert($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:settings-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>
        <xsl:variable name="form" select="$context('form')" as="element()?"/>

        <xsl:message>ldh:settings-form-response</xsl:message>

        <xsl:choose>
            <!-- 200/204: settings saved successfully, reload so the page re-renders with the updated settings and stylesheet composition -->
            <xsl:when test="$status = (200, 204)">
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'location'), 'reload', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- validation errors: inject render-fn so the violation re-render uses ldh:AppSettingsForm mode (the modal-form-submit-violation chain is shared with the Container/Item flow which renders via ldh:DocumentForm); 'required' mirrors the always-true function of the initial app-settings chain; the package-catalog load pair rides as 'load-pairs' so the re-rendered form keeps the package checkboxes - without them Save would submit no ldh:import triples and uninstall every package -->
            <xsl:when test="$status = (400, 422) and starts-with($media-type, 'application/rdf+xml')">
                <xsl:sequence select="ldh:modal-form-submit-violation(map:merge(($context, map{ 'render-fn': ldh:render-app-settings-form#2, 'required': function($r as element()) as xs:boolean { true() }, 'load-pairs': [ [ ldh:load-package-catalog#1, 'package-catalog-request', 'package-catalog-response', ldh:set-package-catalog#1 ] ] }), map{ 'duplicates': 'use-last' }))"/>
            </xsl:when>
            <!-- other errors -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:error-response-alert($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:request-access-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="form" select="$context('form')" as="element()?"/>

        <xsl:message>ldh:request-access-form-response</xsl:message>

        <xsl:choose>
            <!-- Success: close the modal -->
            <xsl:when test="$status = 200">
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <!-- close the modal -->
                <xsl:if test="$form">
                    <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:when>
            <!-- Error -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:error-response-alert($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- build the PUT request for one generated container: mint the container URI under $parent, load the SELECT text from the ldh ontology and substitute $type with the class IRI, then build the container document -->
    <xsl:function name="ldh:generate-container-request" as="map(*)">
        <xsl:param name="parent" as="xs:anyURI"/>
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>
        <xsl:param name="service" as="xs:anyURI?"/>

        <xsl:variable name="uuid" select="ac:uuid()" as="xs:string"/>
        <xsl:variable name="container-uri" select="xs:anyURI($parent || encode-for-uri($uuid) || '/')" as="xs:anyURI"/>
        <xsl:variable name="query-text" select="key('resources', $query-uri, document(ac:document-uri('&ldh;')))/sp:text" as="xs:string"/>
        <!-- substitute the $type variable with the class IRI (literal-pattern replace, precedent navigation.xsl SelectChildren/$this) -->
        <xsl:variable name="query-text" select="replace($query-text, '$type', '&lt;' || $class || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="body" select="ldh:generate-container-doc($container-uri, $parent, $class, $query-text, $uuid, $service)" as="document-node()"/>
        <xsl:sequence select="map{ 'method': 'PUT', 'href': ldh:href($container-uri), 'media-type': 'application/rdf+xml', 'body': $body, 'headers': map{ 'Accept': 'application/rdf+xml' } }"/>
    </xsl:function>

    <!-- build a container document graph equivalent to the former Generate.java output, with the content block correctly wrapped as ldh:Object -> rdf:value -> ldh:View (the bare ldh:View the endpoint wrote bypassed validation and would be rejected by ldh:InvalidContentBlockType on the HTTP path). The server stamps dct:created/creator/owner and skolemizes the blank nodes on PUT. -->
    <xsl:function name="ldh:generate-container-doc" as="document-node()">
        <xsl:param name="container-uri" as="xs:anyURI"/>
        <xsl:param name="parent" as="xs:anyURI"/>
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="query-text" as="xs:string"/>
        <xsl:param name="slug" as="xs:string"/>
        <xsl:param name="service" as="xs:anyURI?"/>

        <xsl:variable name="local-name" select="if (contains($class, '#')) then substring-after($class, '#') else tokenize($class, '/')[last()]" as="xs:string"/>
        <xsl:document>
            <rdf:RDF>
                <rdf:Description rdf:about="{$container-uri}">
                    <rdf:type rdf:resource="&dh;Container"/>
                    <sioc:has_parent rdf:resource="{$parent}"/>
                    <dct:title><xsl:value-of select="$local-name || 's'"/></dct:title>
                    <dh:slug><xsl:value-of select="$slug"/></dh:slug>
                    <rdf:_1>
                        <rdf:Description>
                            <rdf:type rdf:resource="&ldh;Object"/>
                            <rdf:value>
                                <rdf:Description>
                                    <rdf:type rdf:resource="&ldh;View"/>
                                    <spin:query>
                                        <rdf:Description>
                                            <rdf:type rdf:resource="&sp;Select"/>
                                            <dct:title><xsl:value-of select="'Select ' || $local-name"/></dct:title>
                                            <sp:text><xsl:value-of select="$query-text"/></sp:text>
                                            <xsl:if test="$service">
                                                <ldh:service rdf:resource="{$service}"/>
                                            </xsl:if>
                                        </rdf:Description>
                                    </spin:query>
                                </rdf:Description>
                            </rdf:value>
                        </rdf:Description>
                    </rdf:_1>
                </rdf:Description>
            </rdf:RDF>
        </xsl:document>
    </xsl:function>

    <!-- fan-out driver: runs as a promise callback (so ixsl:http-request is called in an active promise context), fires one PUT per class part, and joins them with ixsl:all. Returns the joined promise chain for the outer ixsl:then to adopt (idiom: ldh:fire-load-set-parallel). -->
    <xsl:function name="ldh:generate-containers-fanout" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:variable name="promises" as="array(*)" select="
          array {
            for $part in $context('parts') return
              ixsl:http-request(ldh:generate-container-request($context('parent'), $part('class'), $part('query-uri'), $context('service')))
                => ixsl:then(ldh:rethread-response(map{ 'class': $part('class') }, ?))
                => ixsl:then(ldh:handle-response#1)
          }"/>

        <xsl:sequence select="ixsl:all($promises) => ixsl:then(ldh:generate-containers-join($context, ?))"/>
    </xsl:function>

    <!-- join callback for the generate fan-out. ixsl:all resolves to an array of the per-PUT contexts (each { class, response }); $results?* expands its members. If every container was created, close the modal and navigate to the parent; otherwise leave the created containers in place and report the failed classes inline. -->
    <xsl:function name="ldh:generate-containers-join" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="results" as="array(*)"/>

        <xsl:message>ldh:generate-containers-join</xsl:message>

        <xsl:variable name="form" select="$context('form')" as="element()?"/>
        <xsl:variable name="failures" select="$results?*[?response?status ge 400]" as="item()*"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="empty($failures)">
                <!-- all containers created: remove the modal and navigate to the parent -->
                <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="ac:absolute-path($context('parent'))"/>
                    <xsl:with-param name="fragment" select="()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- partial failure: created containers stay; the classes that failed are the technical detail,
                     one 'HTTP <status> <class>' line each, so this reports through the same form error surface -->
                <xsl:sequence select="ldh:render-form-error($form, 'containers-not-created', 'containers-partial-failure', string-join($failures ! ('HTTP ' || ?response?status || ' ' || ?class), '&#xA;'))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- callback for the add/clone source fetch (T3): on a successful RDF/XML response, GSP-append the fetched triples to the target document, then reuse ldh:add-data-form-response to close the modal and navigate. Returns the append promise chain so the outer ixsl:then adopts it (idiom: ldh:fetch-and-load-edited-resource). -->
    <xsl:function name="ldh:add-data-source-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>

        <xsl:message>ldh:add-data-source-response</xsl:message>

        <xsl:choose>
            <!-- source fetched as RDF/XML: append it to the target document graph -->
            <xsl:when test="$status = 200 and starts-with($media-type, 'application/rdf+xml')">
                <xsl:variable name="target-uri" select="$context('target-uri')" as="xs:anyURI"/>
                <xsl:variable name="post-request" select="map{ 'method': 'POST', 'href': ldh:href($target-uri), 'media-type': 'application/rdf+xml', 'body': $response?body, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <!-- re-thread 'request' so ldh:handle-response's 429/Retry-After retry re-issues the POST, not the original GET -->
                <xsl:variable name="post-context" select="map:put($context, 'request', $post-request)" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($post-request)
                    => ixsl:then(ldh:rethread-response($post-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:add-data-form-response#1)
                "/>
            </xsl:when>
            <!-- 200 but not RDF/XML (e.g. the source URI returned an HTML page): explicit error, do NOT fall through to the success navigation of ldh:add-data-form-response -->
            <xsl:when test="$status = 200">
                <xsl:sequence select="ldh:add-data-form-error($context, 'source-not-rdf')"/>
            </xsl:when>
            <!-- fetch failed -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:add-data-form-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- import-ontology chain, step 1 (source fetched): PUT the raw ontology into the scratch document (scaffolding for the constructor derivation - deleted at the end of the chain). The PUT body carries the scratch document's own metadata alongside the vocabulary so the document-hierarchy constraints validate. -->
    <xsl:function name="ldh:import-ontology-source-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="media-type" select="$response?media-type" as="xs:string?"/>

        <xsl:message>ldh:import-ontology-source-response</xsl:message>

        <xsl:choose>
            <!-- source fetched as RDF/XML: PUT it into the scratch document graph -->
            <xsl:when test="$status = 200 and starts-with($media-type, 'application/rdf+xml')">
                <xsl:variable name="scratch-uri" select="$context('scratch-uri')" as="xs:anyURI"/>
                <xsl:variable name="scratch-body" as="document-node()">
                    <xsl:document>
                        <rdf:RDF>
                            <rdf:Description rdf:about="{$scratch-uri}">
                                <rdf:type rdf:resource="&dh;Item"/>
                                <sioc:has_container rdf:resource="{ldt:base()}"/>
                                <dct:title>Import ontology scratch</dct:title>
                            </rdf:Description>
                            <xsl:copy-of select="$response?body/rdf:RDF/*"/>
                        </rdf:RDF>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="put-request" select="map{ 'method': 'PUT', 'href': ldh:href($scratch-uri), 'media-type': 'application/rdf+xml', 'body': $scratch-body, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <!-- re-thread 'request' so ldh:handle-response's 429/Retry-After retry re-issues the PUT, not the original GET; 'scratch-created' arms the error wrapper's cleanup from here on -->
                <xsl:variable name="put-context" select="map:merge(($context, map{ 'request': $put-request, 'scratch-created': true() }), map{ 'duplicates': 'use-last' })" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($put-request)
                    => ixsl:then(ldh:rethread-response($put-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:import-ontology-query-thunk#1)
                "/>
            </xsl:when>
            <!-- 200 but not RDF/XML (e.g. the source URI returned an HTML page): explicit error -->
            <xsl:when test="$status = 200">
                <xsl:sequence select="ldh:add-data-form-error($context, 'source-not-rdf')"/>
            </xsl:when>
            <!-- fetch failed -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:add-data-form-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- import-ontology chain, step 2 (raw ontology PUT into the scratch document): fetch the spin:query document as RDF/XML so its sp:text can be read -->
    <xsl:function name="ldh:import-ontology-query-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:import-ontology-query-thunk</xsl:message>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 201, 204)">
                <xsl:variable name="query-uri" select="$context('query-uri')" as="xs:anyURI"/>
                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href(ac:document-uri($query-uri)), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="query-context" select="map:put($context, 'request', $request)" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($request)
                    => ixsl:then(ldh:rethread-response($query-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:import-ontology-query-response#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:import-ontology-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- import-ontology chain, step 3 (query document fetched): run its sp:text CONSTRUCT over the scratch document's graph via the SPARQL Protocol dataset specification (?default-graph-uri=) on the /sparql endpoint -->
    <xsl:function name="ldh:import-ontology-query-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:import-ontology-query-response</xsl:message>

        <xsl:variable name="query-string" select="if ($response?status = 200 and starts-with($response?media-type, 'application/rdf+xml')) then key('resources', $context('query-uri'), $response?body)/sp:text else ()" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="$query-string">
                <xsl:variable name="scratch-uri" select="$context('scratch-uri')" as="xs:anyURI"/>
                <xsl:variable name="endpoint" select="ac:build-uri(resolve-uri('sparql', ldt:base()), map{ 'default-graph-uri': string($scratch-uri) })" as="xs:anyURI"/>
                <xsl:variable name="request" select="map{ 'method': 'POST', 'href': $endpoint, 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="construct-context" select="map:put($context, 'request', $request)" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($request)
                    => ixsl:then(ldh:rethread-response($construct-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:import-ontology-constructors-response#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:import-ontology-error($context, 'transformation-query-not-loaded')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- import-ontology chain, step 4 (constructors constructed): GSP-append the derived constructors plus the annotation-ontology header (target a owl:Ontology; owl:imports source) to the target document. The header is appended even when the CONSTRUCT result is empty - the owl:imports wiring is the import's essence; the vocabulary itself resolves live through the graph repository. -->
    <xsl:function name="ldh:import-ontology-constructors-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:import-ontology-constructors-response</xsl:message>

        <xsl:choose>
            <xsl:when test="$response?status = 200 and starts-with($response?media-type, 'application/rdf+xml')">
                <xsl:variable name="target-uri" select="$context('target-uri')" as="xs:anyURI"/>
                <xsl:variable name="target-body" as="document-node()">
                    <xsl:document>
                        <rdf:RDF>
                            <rdf:Description rdf:about="{$target-uri}">
                                <rdf:type rdf:resource="&owl;Ontology"/>
                                <owl:imports rdf:resource="{$context('source-uri')}"/>
                            </rdf:Description>
                            <xsl:copy-of select="$response?body/rdf:RDF/*"/>
                        </rdf:RDF>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="post-request" select="map{ 'method': 'POST', 'href': ldh:href($target-uri), 'media-type': 'application/rdf+xml', 'body': $target-body, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="post-context" select="map:put($context, 'request', $post-request)" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($post-request)
                    => ixsl:then(ldh:rethread-response($post-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:import-ontology-scratch-delete#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:import-ontology-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- import-ontology chain, step 5 (annotations appended to the target): delete the scratch document - the vocabulary scaffolding must not outlive the derivation -->
    <xsl:function name="ldh:import-ontology-scratch-delete" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:import-ontology-scratch-delete</xsl:message>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 204)">
                <xsl:variable name="delete-request" select="map{ 'method': 'DELETE', 'href': ldh:href($context('scratch-uri')), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="delete-context" select="map:put($context, 'request', $delete-request)" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($delete-request)
                    => ixsl:then(ldh:rethread-response($delete-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:import-ontology-clear#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:import-ontology-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- error wrapper for the import-ontology chain: once the scratch document exists ('scratch-created'), delete it best-effort before rendering the error; the original failed 'response' stays in $context for the message -->
    <xsl:function name="ldh:import-ontology-error" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="explanation-key" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="map:contains($context, 'scratch-created')">
                <xsl:sequence select="
                  ixsl:http-request(map{ 'method': 'DELETE', 'href': ldh:href($context('scratch-uri')) })
                    => ixsl:then(ldh:import-ontology-error-cleaned($context, $explanation-key, ?))
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:add-data-form-error($context, $explanation-key)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- renders the error after the scratch cleanup; the DELETE response is ignored -->
    <xsl:function name="ldh:import-ontology-error-cleaned" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="explanation-key" as="xs:string?"/>
        <xsl:param name="delete-response" as="map(*)"/>

        <xsl:sequence select="ldh:add-data-form-error($context, $explanation-key)"/>
    </xsl:function>

    <!-- import-ontology chain, step 6 (scratch deleted): clear the end-user app ontology from the server-side cache so its owl:imports closure picks up the annotation document (idempotent when the app ontology does not import it yet), then terminate via ldh:add-data-form-response -->
    <xsl:function name="ldh:import-ontology-clear" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:import-ontology-clear</xsl:message>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 204)">
                <!-- the admin app manages its parent dataspace's end-user app, whose ontology is <ns#> on the parent origin -->
                <xsl:variable name="ontology-uri" select="resolve-uri('ns#', ldh:parent-origin(ldh:request-uri()))" as="xs:anyURI"/>
                <xsl:variable name="request" select="map{ 'method': 'POST', 'href': resolve-uri('clear', ldt:base()), 'media-type': 'application/x-www-form-urlencoded', 'body': 'uri=' || encode-for-uri($ontology-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="clear-context" select="map:put($context, 'request', $request)" as="map(*)"/>
                <xsl:sequence select="
                  ixsl:http-request($request)
                    => ixsl:then(ldh:rethread-response($clear-context, ?))
                    => ixsl:then(ldh:handle-response#1)
                    => ixsl:then(ldh:add-data-form-response#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:add-data-form-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:add-data-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>
        <xsl:variable name="form" select="$context('form')" as="element()?"/>

        <xsl:message>ldh:add-data-form-response</xsl:message>

        <xsl:choose>
            <!-- Success: redirect to target container with ReadMode -->
            <xsl:when test="$status = (200, 204)">
                <xsl:variable name="control-group" select="$form/descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = '&sd;name']]" as="element()*"/>
                <xsl:variable name="uri" select="$control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                <!-- Remove the modal -->
                <xsl:sequence select="ixsl:call($form/ancestor::div[contains-token(@class, 'modal')], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="ac:absolute-path($uri)"/>
                    <xsl:with-param name="fragment" select="ac:fragment-id($uri)"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Error: render error message inline in the form's fieldset -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:add-data-form-error($context, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- render an inline error alert in the add/clone form's fieldset. $explanation-key names the sentence for a
         failure that never reached the network (e.g. a non-local target); pass () to derive it from the response
         status instead. 'response' is optional for the same reason. -->
    <xsl:function name="ldh:add-data-form-error" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="explanation-key" as="xs:string?"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)?"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:sequence select="ldh:render-form-error($context('form'), 'data-not-added', ($explanation-key, ldh:http-error-key($response?status))[1], ldh:response-detail($response))"/>
    </xsl:function>

    <!-- Kicks off the async metadata-fetch chain for the constraint-violation re-render of a modal form (Container/Item creation and document edit). $context carries response/about/block/form from the form submit handler — $about is the resource discriminator (set by the submit handler from $block/@about or $form/@action). Harvest types/property-uris from the edited resource; object-uris from the whole body. Terminates in ldh:render-modal-form-violation. -->
    <xsl:function name="ldh:modal-form-submit-violation" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="about" select="$context('about')" as="xs:anyURI"/>

        <xsl:message>ldh:modal-form-submit-violation</xsl:message>

        <xsl:variable name="body" select="$response?body" as="document-node()"/>
        <!-- inverse $types expression compared to ldh:row-form-submit-violation: types come from the *edited* resource, not from the violation-attached ones -->
        <xsl:variable name="types" select="distinct-values($body/rdf:RDF/*[@rdf:about = $about]/rdf:type/@rdf:resource)" as="xs:anyURI*"/>

        <xsl:variable name="new-context" as="map(*)" select="map:merge((
            $context,
            map{
                'body': $body,
                'types': $types,
                'forClass': $types,
                'endpoint': sd:endpoint(),
                'property-uris': distinct-values($body/rdf:RDF/*[@rdf:about = $about]/*/concat(namespace-uri(), local-name())),
                'object-uris': distinct-values($body/rdf:RDF/*[not(rdf:type/@rdf:resource = $system-types)]/*/@rdf:resource[not(key('resources', .))])
            }
        ), map{ 'duplicates': 'use-last' })"/>

        <!-- flow-specific pairs stamped as 'load-pairs' by the response handler (e.g. the app-settings package catalog) join the shared list; every pair must bake a request, so optional fetches ride per flow rather than in the shared list -->
        <xsl:variable name="pairs" as="array(*)" select="array:join(([
              [ ldh:load-type-metadata#1,     'type-metadata-request',     'type-metadata-response',     ldh:set-type-metadata#1 ],
              [ ldh:load-property-metadata#1, 'property-metadata-request', 'property-metadata-response', ldh:set-property-metadata#1 ],
              [ ldh:load-constraints#1,       'constraints-request',       'constraints-response',       ldh:set-constraints#1 ],
              [ ldh:load-object-metadata#1,   'metadata-request',          'metadata-response',          ldh:set-object-metadata#1 ],
              [ ldh:load-object-metadata#1,   'ns-metadata-request',       'ns-metadata-response',       ldh:set-object-metadata-ns#1 ]
            ], ($context('load-pairs'), [ ])[1]))"/>

        <!-- $new-context is built synchronously above; types/property-uris/object-uris populated from the violation response body. No pre-baked type-metadata-request here, so the type-metadata pair uses the normal ldh:load-type-metadata. -->
        <ixsl:promise select="ixsl:resolve($new-context) =>
            ixsl:then(ldh:fire-load-set-parallel(?, $pairs)) =>
            ixsl:then(ldh:merge-object-metadata#1) =>
            ixsl:then(ldh:render-modal-form-violation#1) =>
            ixsl:finally(ldh:reset-cursor#0)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:function>

    <!-- Terminal callback for the modal-form-submit-violation chain. All metadata is in $context from the upstream chain steps. constructors/shapes/constructed-doc arrive per flow: a flow that stamps them as 'load-pairs' in its response handler (the document-edit flow) gets the same constructor input as its initial render; the other flows leave them unset and bs2:FormControl's constructor param default sources the constructor client-side. $context('render-fn') and $context('required') are uniformly populated by each flow's response handler — ldh:constructor-form-response stamps ldh:render-constructor-form#2 (mode="bs2:Form") for Container/Item creation (PUT), ldh:edit-form-response stamps ldh:render-document-form#2 (mode="ldh:DocumentForm") for Container/Item edit (PATCH), ldh:settings-form-response stamps ldh:render-app-settings-form#2 for app-settings — so the violation re-render uses the same mode as the initial render. The mode-per-flow split keeps the edit form's narrow @rdf:about=$about filter while letting the creation flow surface co-shipped peer Descriptions (content blocks). -->
    <xsl:function name="ldh:render-modal-form-violation" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="body" select="$context('body')" as="document-node()"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>
        <xsl:variable name="form" select="$context('form')" as="element()?"/>

        <!-- no 'base-uri' entry: the render dispatchers fall back to $ctx('about'), same as the initial render. The response body's base URI equals $about in the creation/edit flows but not in the app-settings flow (urn: subject), where it flipped $show-subject and exposed the URI control. No 'required' entry either: the response handlers stamp it per flow, matching each flow's initial chain -->
        <xsl:variable name="render-ctx" as="map(*)" select="map:merge(($context, map{
            'method':            string($form/@method),
            'action':            xs:anyURI(string($form/@action))
        }), map{ 'duplicates': 'use-last' })"/>
        <xsl:variable name="render-fn" select="$context('render-fn')" as="function(document-node(), map(*)) as element()*"/>
        <xsl:variable name="rendered" select="$render-fn($body, $render-ctx)" as="element()*"/>

        <!-- resolve the dialog shell from whichever element the flow stamped as 'block': the backdrop (edit/create submits) or the modal body (app-settings) -->
        <xsl:variable name="dialog" select="($block/ancestor-or-self::div[contains-token(@class, 'ldhc-modal')], $block/descendant::div[contains-token(@class, 'ldhc-modal')])[1]" as="element()"/>
        <xsl:for-each select="$dialog">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="ldhc-modal-head">
                    <span class="ldhc-modal-x">
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost close" aria-label="{ac:label(key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}"><span class="msi sm">close</span></button>
                    </span>
                </div>

                <div class="ldhc-modal-body">
                    <xsl:copy-of select="$rendered"/>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <!-- cannot be in $rendered context because it contains old DOM (pre-ixsl:replace-content) -->
        <xsl:for-each select="id($rendered/@id, ixsl:page())">
            <xsl:apply-templates select="." mode="ldh:RenderRowForm"/>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>