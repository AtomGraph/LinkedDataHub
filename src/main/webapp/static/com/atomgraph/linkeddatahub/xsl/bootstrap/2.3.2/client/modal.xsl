<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
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
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- EVENT HANDLERS -->

    <xsl:template match="button[contains-token(@class, 'btn-add-data')]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="graph" select="ldh:absolute-path(ldh:href())"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-add-ontology')]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="action" select="resolve-uri('transform', $ldt:base)"/>
            <xsl:with-param name="graph" select="ldh:absolute-path(ldh:href())"/>
            <xsl:with-param name="query" select="resolve-uri('queries/construct-constructors/#this', $ldt:base)"/>
            <xsl:with-param name="legend-label" select="ac:label(key('resources', 'import-ontology', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))"/>
        </xsl:call-template>
    </xsl:template>

    <!-- validate form before submitting it and show errors on control-groups where input values are missing -->
    <xsl:template match="form[@id = 'form-add-data'] | form[@id = 'form-clone-data']" mode="ixsl:onsubmit" priority="1">
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = ('&nfo;fileName', '&dct;source', '&sd;name')]]" as="element()*"/>
        <xsl:choose>
            <!-- values missing, throw an error -->
            <xsl:when test="some $input in $control-groups/descendant::input[@name = ('ol', 'ou')] satisfies not(ixsl:get($input, 'value'))">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
                <xsl:sequence select="$control-groups/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present, apply the default form onsubmit -->
            <xsl:otherwise>
                <xsl:sequence select="$control-groups/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- CALLBACKS -->
    
    <!-- show "Add data"/"Save as" form -->

    <xsl:template name="ldh:ShowAddDataForm">
        <xsl:param name="id" select="'add-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="action" select="resolve-uri('add', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="source" as="xs:anyURI?"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:anyURI?"/>
        <xsl:param name="legend-label" select="ac:label(key('resources', 'add-rdf-data', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))" as="xs:string"/>
        
        <!-- don't append the div if it's already there -->
        <xsl:if test="not(id($id, ixsl:page()))">
            <xsl:for-each select="ixsl:page()//body">
                <!-- append modal div to body -->
                <xsl:result-document href="?." method="ixsl:append-content">
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
                                    <li>
                                        <xsl:if test="not($source)">
                                            <xsl:attribute name="class" select="'active'"/>
                                        </xsl:if>

                                        <a>
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'upload-file', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </a>
                                    </li>
                                    <li>
                                        <xsl:if test="$source">
                                            <xsl:attribute name="class" select="'active'"/>
                                        </xsl:if>

                                        <a>
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'from-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </a>
                                    </li>
                                </ul>
                                <div class="tab-content">
                                    <div>
                                        <xsl:attribute name="class" select="'tab-pane ' || (if (not($source)) then 'active' else ())"/>

                                        <form id="form-add-data" method="POST" action="{$action}" enctype="multipart/form-data">
                                            <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
                                            <xsl:call-template name="xhtml:Input">
                                                <xsl:with-param name="name" select="'rdf'"/>
                                                <xsl:with-param name="type" select="'hidden'"/>
                                            </xsl:call-template>

                                            <fieldset>
                                                <input type="hidden" name="sb" value="file"/>
                                                <input type="hidden" name="pu" value="&rdf;type"/>
                                                <input type="hidden" name="ou" value="&nfo;FileDataObject"/>

                                                <!-- file title is unused, just needed to pass the ldh:File constraints -->
                                                <input type="hidden" name="pu" value="&dct;title"/>
                                                <input id="upload-rdf-title" type="hidden" name="ol" value="RDF upload"/>

                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&dct;format"/>
                                                    <!-- TO-DO: localize label -->
                                                    <label class="control-label" for="upload-rdf-format">Format</label>
                                                    <div class="controls">
                                                        <select id="upload-rdf-format" name="ol">
                                                            <!--<option value="">[browser-defined]</option>-->
                                                            <optgroup label="RDF triples">
                                                                <option value="text/turtle">Turtle (.ttl)</option>
                                                                <option value="application/n-triples">N-Triples (.nt)</option>
                                                                <option value="application/rdf+xml">RDF/XML (.rdf)</option>
                                                            </optgroup>
                                                            <optgroup label="RDF quads">
                                                                <option value="text/trig">TriG (.trig)</option>
                                                                <option value="application/n-quads">N-Quads (.nq)</option>
                                                            </optgroup>
                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&nfo;fileName"/>
                                                    <!-- TO-DO: localize label -->
                                                    <label class="control-label" for="upload-rdf-filename">FileName</label>
                                                    <div class="controls">
                                                        <input id="upload-rdf-filename" type="file" name="ol"/>
                                                    </div>
                                                </div>
                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&sd;name"/>
                                                    <label class="control-label" for="upload-rdf-doc">
                                                        <xsl:value-of>
                                                            <xsl:apply-templates select="key('resources', 'graph', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                                        </xsl:value-of>
                                                    </label>
                                                    <div class="controls">
                                                        <span>
                                                            <input type="text" name="ou" id="upload-rdf-doc" class="resource-typeahead typeahead"/>
                                                            <ul class="resource-typeahead typeahead dropdown-menu" id="ul-upload-rdf-doc" style="display: none;"></ul>
                                                        </span>

                                                        <input type="hidden" class="forClass" value="&dh;Container" autocomplete="off"/>
                                                        <input type="hidden" class="forClass" value="&dh;Item" autocomplete="off"/>
                                                        <div class="btn-group">
                                                            <button type="button" class="btn dropdown-toggle create-action"></button>
                                                            <ul class="dropdown-menu">
                                                                <li>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Container'))}" class="btn add-constructor" title="&dh;Container" id="{generate-id()}-upload-rdf-container">
                                                                        <xsl:value-of>
                                                                            <xsl:apply-templates select="key('resources', '&dh;Container', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                                        </xsl:value-of>
                                                                        
                                                                        <input type="hidden" class="forClass" value="&dh;Container"/>
                                                                    </a>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Item'))}" class="btn add-constructor" title="&dh;Item" id="{generate-id()}-upload-rdf-item">
                                                                        <xsl:value-of>
                                                                            <xsl:apply-templates select="key('resources', '&dh;Item', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                                        </xsl:value-of>

                                                                        <input type="hidden" class="forClass" value="&dh;Item"/>
                                                                    </a>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                        <span class="help-inline">
                                                            <xsl:value-of>
                                                                <xsl:apply-templates select="key('resources', '&dh;Document', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                            </xsl:value-of>
                                                        </span>
                                                    </div>
                                                </div>
                                                
                                                <xsl:if test="$query">
                                                    <input type="hidden" name="pu" value="&spin;query"/>
                                                    <input type="hidden" name="ou" value="{$query}"/>
                                                </xsl:if>
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
                                    </div>
                                    <div>
                                        <xsl:attribute name="class" select="'tab-pane ' || (if ($source) then 'active' else ())"/>

                                        <form id="form-clone-data" method="POST" action="{$action}">
                                            <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
                                            <xsl:call-template name="xhtml:Input">
                                                <xsl:with-param name="name" select="'rdf'"/>
                                                <xsl:with-param name="type" select="'hidden'"/>
                                            </xsl:call-template>

                                            <fieldset>
                                                <input type="hidden" name="sb" value="clone"/>

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
                                                                <xsl:apply-templates select="key('resources', '&rdf;Resource', document(ac:document-uri('&rdf;')))" mode="ac:label"/>
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

                                                        <input type="hidden" class="forClass" value="&dh;Container" autocomplete="off"/>
                                                        <input type="hidden" class="forClass" value="&dh;Item" autocomplete="off"/>
                                                        <div class="btn-group">
                                                            <button type="button" class="btn dropdown-toggle create-action"></button>
                                                            <ul class="dropdown-menu">
                                                                <li>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Container'))}" class="btn add-constructor" title="&dh;Container" id="{generate-id()}-remote-rdf-container">
                                                                        <xsl:value-of>
                                                                            <xsl:apply-templates select="key('resources', '&dh;Container', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                                        </xsl:value-of>

                                                                        <input type="hidden" class="forClass" value="&dh;Container"/>
                                                                    </a>
                                                                </li>
                                                                <li>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Item'))}" type="button" class="btn add-constructor" title="&dh;Item" id="{generate-id()}-remote-rdf-item">
                                                                        <xsl:value-of>
                                                                            <xsl:apply-templates select="key('resources', '&dh;Item', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                                        </xsl:value-of>

                                                                        <input type="hidden" class="forClass" value="&dh;Item"/>
                                                                    </a>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                        <span class="help-inline">
                                                            <xsl:value-of>
                                                                <xsl:apply-templates select="key('resources', '&dh;Document', document(ac:document-uri('&dh;')))" mode="ac:label"/>
                                                            </xsl:value-of>
                                                        </span>
                                                    </div>
                                                </div>
                                                
                                                <xsl:if test="$query">
                                                    <input type="hidden" name="pu" value="&spin;query"/>
                                                    <input type="hidden" name="ou" value="{$query}"/>
                                                </xsl:if>
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
                                    </div>
                                </div>
                            </div>

                            <div class="alert alert-info">
                                <p>Adding data this way will cause a blocking request, so use it for small amounts of data only (e.g. a few thousands of RDF triples). For larger data, use asynchronous <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/imports/rdf/" target="_blank">RDF imports</a>.</p>
                            </div>
                        </div>
                    </div>
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
    
</xsl:stylesheet>