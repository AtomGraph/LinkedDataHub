<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY cert   "http://www.w3.org/ns/auth/cert#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY schema "https://schema.org/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:lapp="&lapp;"
xmlns:lacl="&lacl;"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:sd="&sd;"
xmlns:sh="&sh;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:geo="&geo;"
xmlns:srx="&srx;"
xmlns:void="&void;"
xmlns:schema="&schema;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>
    
    <xsl:mode name="ldh:Shape" on-no-match="deep-skip"/>

    <xsl:param name="main-doc" select="/" as="document-node()"/>
    <xsl:param name="acl:Agent" as="document-node()?"/>

    <!-- schema.org BREADCRUMBS -->
    
    <xsl:template match="rdf:RDF" mode="schema:BreadCrumbList">
        <xsl:variable name="resource" select="key('resources', ac:absolute-path(ldh:base-uri(.)))" as="element()?"/>

        <xsl:if test="$resource">
            <xsl:variable name="doc-with-ancestors" select="ldh:doc-with-ancestors($resource)" as="element()*"/>

            <rdf:RDF>
                <rdf:Description rdf:nodeID="breadcrumb-list">
                    <rdf:type rdf:resource="&schema;BreadcrumbList"/>

                    <!-- position index has to start from Root=1, so we need to reverse the ancestor sequence -->
                    <xsl:for-each select="reverse($doc-with-ancestors)">
                        <schema:itemListElement rdf:nodeID="item{position()}"/> <!-- rdf:nodeID aligned with schema:BreadCrumbListItem output -->
                    </xsl:for-each>
                </rdf:Description>

                <!-- position index has to start from Root=1, so we need to reverse the ancestor sequence -->
                <xsl:apply-templates select="reverse($doc-with-ancestors)" mode="schema:BreadCrumbListItem"/>
            </rdf:RDF>
        </xsl:if>
    </xsl:template>

    <xsl:template match="srx:sparql" mode="schema:BreadCrumbList"/>

    <!-- walks up the ancestor document chain and collects them -->
    <xsl:function name="ldh:doc-with-ancestors" as="element()*">
        <xsl:param name="resource" as="element()"/>
        <xsl:variable name="parent-uri" select="$resource/sioc:has_container/@rdf:resource | $resource/sioc:has_parent/@rdf:resource" as="xs:anyURI?"/>
        
        <xsl:sequence select="$resource"/>

        <xsl:if test="$parent-uri">
            <xsl:if test="doc-available(ac:document-uri($parent-uri))">
                <xsl:variable name="parent-doc" select="document(ac:document-uri($parent-uri))" as="document-node()"/>
                <xsl:variable name="parent" select="key('resources', $parent-uri, $parent-doc)" as="element()?"/>

                <xsl:if test="$parent">
                    <xsl:sequence select="ldh:doc-with-ancestors($parent)"/>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:function>

    <!-- BODY -->
    
    <!-- always show errors (except ConstraintViolations) in block mode -->
    <xsl:template match="rdf:RDF[not(key('resources', ac:absolute-path(ldh:base-uri(.))))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))] | rdf:RDF[not(key('resources', ac:absolute-path(ldh:base-uri(.))))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&sh;ValidationResult'))]" mode="xhtml:Body" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'row-main'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
        
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!-- ACTION BAR -->
    
    <xsl:template match="rdf:RDF" mode="bs2:ActionBarLeft">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ab-left'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:if test="acl:mode() = '&acl;Write' and not(key('resources-by-type', '&http;Response'))">
                <!-- child documents can be created only if the current document is the Root or a container -->
                <xsl:if test="key('resources', ac:absolute-path(ldh:base-uri(.)))/rdf:type/@rdf:resource = ('&def;Root', '&dh;Container')">
                    <xsl:variable name="document-classes" select="key('resources', ('&dh;Container', '&dh;Item'), document(ac:document-uri('&def;')))" as="element()*"/>
                    <xsl:apply-templates select="." mode="bs2:Create">
                        <xsl:with-param name="class" select="'ldh-add-wrap btn-group'"/>
                        <xsl:with-param name="classes" select="$document-classes"/>
                        <xsl:with-param name="create-graph" select="true()"/>
                        <xsl:with-param name="show-instance" select="false()"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:if>
            
            <xsl:if test="$ldh:ajaxRendering">
                <xsl:apply-templates select="." mode="bs2:AddData"/>
            </xsl:if>
        </div>
    </xsl:template>
        
    <xsl:template match="rdf:RDF[acl:mode() = '&acl;Append']" mode="bs2:AddData" priority="1">
        <xsl:param name="menu-items" as="element()*">
            <button type="button" class="it btn-generate-containers" title="{ac:label(key('resources', 'generate-containers-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                <span class="msi sm" aria-hidden="true">library_add</span>
                <span class="it-txt">
                    <xsl:apply-templates select="key('resources', 'generate-containers', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </span>
            </button>
        </xsl:param>

        <div class="ldh-of-wrap btn-group">
            <button type="button" class="ldh-btn is-ghost dropdown-toggle" title="{ac:label(key('resources', 'add', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                <span class="msi sm" aria-hidden="true">upload</span>
                <span>
                    <xsl:apply-templates select="key('resources', 'add', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </span>
                <span class="msi caret" aria-hidden="true">expand_more</span>
            </button>

            <div class="ldh-of-menu">
                <xsl:sequence select="$menu-items"/>
            </div>
        </div>
    </xsl:template>

    <!-- Admin app override: replace the default "Generate containers" with "Import ontology".
         Admin apps are identified by the 'admin.' subdomain prefix on lapp:origin() (nginx wildcard routing convention). -->
    <xsl:template match="rdf:RDF[acl:mode() = '&acl;Append'][starts-with(replace(lapp:origin(), '^https?://', ''), 'admin.')]" mode="bs2:AddData" priority="2">
        <xsl:next-match>
            <xsl:with-param name="menu-items" as="element()*">
                <button type="button" class="it btn-add-ontology" title="{ac:label(key('resources', 'import-ontology-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                    <span class="msi sm" aria-hidden="true">library_add</span>
                    <span class="it-txt">
                        <xsl:apply-templates select="key('resources', 'import-ontology', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </span>
                </button>
            </xsl:with-param>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*" mode="bs2:AddData"/>

    <xsl:template match="*[rdf:type/@rdf:resource = '&owl;Ontology'][$foaf:Agent//@rdf:about]" mode="bs2:Actions">
        <form action="{resolve-uri('clear', ldt:base())}" method="post">
            <input type="hidden" name="uri" value="{@rdf:about}"/>

            <button class="ldhc-btn in-primary ap-solid sz-md" type="submit">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'clear', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </xsl:value-of>
            </button>
        </form>

        <xsl:next-match/>
    </xsl:template>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBarMain">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ab-mid'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:BreadCrumbBar">
                <xsl:with-param name="class" select="'breadcrumb-nav'"/>
                <xsl:with-param name="uri" select="ac:absolute-path(ldh:base-uri(.))"/>
            </xsl:apply-templates>

            <xsl:variable name="document" select="key('resources', ac:absolute-path(ldh:base-uri(.)))" as="element()?"/>
            <xsl:if test="$document/(dct:created, dct:modified)[exists(ldh:date-time(string(.)))]">
                <div id="doc-controls" class="ldh-ab-ts">
                    <span class="msi sm" aria-hidden="true">schedule</span>
                    <xsl:choose>
                        <!-- versioned document: the timestamp links to its version history (Memento TimeMap) -->
                        <xsl:when test="exists(ldh:timemap())">
                            <a href="{ldh:timemap()}" class="document-history" title="{ac:label(key('resources', 'history', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                                <xsl:apply-templates select="$document" mode="bs2:Timestamp"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$document" mode="bs2:Timestamp"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBarRight">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ldh-actions'" as="xs:string?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:NavBarActions"/>

            <xsl:apply-templates select="." mode="bs2:ModeList">
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="ajax-rendering" select="$ldh:ajaxRendering"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="bs2:MediaTypeList"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:BreadCrumbBar">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="()" as="xs:string?"/>
        <xsl:param name="uri" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <!-- placeholder for client.xsl callbacks -->

            <xsl:if test="not($ldh:ajaxRendering)">
                <div class="breadcrumb ldh-bc ldh-bc-pills">
                    <!-- render breadcrumbs server-side -->
                    <xsl:apply-templates select="key('resources', $uri)" mode="bs2:BreadCrumbListItem"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="srx:sparql" mode="bs2:BreadCrumbBar"/>
    
    <!-- NAVBAR ACTIONS -->

    <xsl:template match="srx:sparql" mode="bs2:NavBarActions" priority="1">
        <xsl:next-match>
            <xsl:with-param name="save-as-disabled" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')]" mode="bs2:NavBarActions" priority="1"/>

    <xsl:template match="rdf:RDF" mode="bs2:NavBarActions">
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="delete-disabled" select="not(acl:mode() = '&acl;Write')" as="xs:boolean"/>
        <xsl:param name="save-as-disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="edit-disabled" select="not(acl:mode() = '&acl;Write')" as="xs:boolean"/>

        <xsl:if test="$foaf:Agent//@rdf:about">
            <div class="ldh-of-wrap btn-group">
                <button type="button" class="ldh-btn is-ghost dropdown-toggle">
                    <span class="msi sm" aria-hidden="true">bolt</span>
                    <span>
                        <xsl:apply-templates select="key('resources', 'actions', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </span>
                    <span class="msi caret" aria-hidden="true">expand_more</span>
                </button>

                <div class="ldh-of-menu">
                    <xsl:if test="$ldh:ajaxRendering">
                        <button type="button" class="it btn-edit{if ($edit-disabled) then ' disabled' else ()}">
                            <span class="msi sm" aria-hidden="true">edit</span>
                            <span class="it-txt">
                                <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                            </span>
                        </button>

                        <button type="button" class="it btn-acl btn-access-form">
                            <span class="msi sm" aria-hidden="true">lock_person</span>
                            <span class="it-txt">
                                <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ac:label"/>
                            </span>
                        </button>

                        <button type="button" class="it btn-save-as{if ($save-as-disabled) then ' disabled' else ()}">
                            <span class="msi sm" aria-hidden="true">save_as</span>
                            <span class="it-txt">
                                <xsl:apply-templates select="key('resources', 'save-as', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </span>
                        </button>

                        <span class="ldh-of-div" aria-hidden="true"></span>
                    </xsl:if>

                    <button type="button" class="it is-danger btn-delete{if ($delete-disabled) then ' disabled' else ()}">
                        <span class="msi sm" aria-hidden="true">delete</span>
                        <span class="it-txt">
                            <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                        </span>
                    </button>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    
    <!-- EXPORT LIST -->

    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')]" mode="bs2:MediaTypeList" priority="1"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:MediaTypeList">
        <xsl:param name="uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>

        <div class="ldh-of-wrap btn-group">
            <button type="button" class="ldh-btn is-ghost dropdown-toggle">
                <xsl:attribute name="title">
                    <xsl:apply-templates select="key('resources', 'nav-bar-action-export-rdf-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </xsl:attribute>

                <span class="msi sm" aria-hidden="true">download</span>
            </button>

            <div class="ldh-of-menu">
                <!-- RDF export links, one per serialization (target=_blank exempts them from CSR link interception) -->
                <xsl:variable name="translations" select="document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))" as="document-node()"/>
                <xsl:variable name="request-uri" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI"/>
                <xsl:variable name="proxied" select="exists(ac:uri())" as="xs:boolean"/>
                <xsl:for-each select="map{ 'accept': 'application/rdf+xml', 'label': 'rdf-xml' }, map{ 'accept': 'text/turtle', 'label': 'turtle' }, map{ 'accept': 'application/ld+json', 'label': 'json-ld' }">
                    <a class="it" href="{ac:build-uri($request-uri, let $params := map{ 'accept': .('accept') } return if ($proxied) then map:merge(($params, map{ 'uri': string($uri) })) else $params)}" title="{.('accept')}" target="_blank">
                        <span class="msi sm" aria-hidden="true">download</span>
                        <span class="it-txt"><xsl:value-of select="ac:label(key('resources', .('label'), $translations))"/></span>
                    </a>
                </xsl:for-each>
            </div>
        </div>
    </xsl:template>

    <!-- MODE LIST -->

    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))] | rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ModeList" priority="1"/>

    <xsl:template match="rdf:RDF" mode="bs2:ModeList">
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="ajax-rendering" select="true()" as="xs:boolean"/>
        <xsl:param name="absolute-path" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>
        <xsl:param name="id" select="()" as="xs:string?"/>

        <div class="ldh-mode btn-group">
            <button type="button" class="label-row layout-modes dropdown-toggle" title="{ac:label(key('resources', '&ac;Mode', document(ac:document-uri('&ac;'))))}">
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>

                <span class="msi" aria-hidden="true">
                    <xsl:value-of select="map:get($ldh:mode-icons, string($active-mode))"/>
                </span>
                <span class="label">
                    <xsl:choose>
                        <xsl:when test="$active-mode = '&ldh;ContentMode'">
                            <xsl:apply-templates select="key('resources', 'content', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="key('resources', $active-mode, document(ac:document-uri('&ac;')))" mode="ac:label"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
                <span class="msi sm caret" aria-hidden="true">expand_more</span>
            </button>

            <div class="modes-pop">
                <a class="mi content-mode{if ($active-mode = '&ldh;ContentMode') then ' is-active' else() }" href="{ldh:href(ac:document-uri(ldh:base-uri(.)), ldh:build-query(xs:anyURI('&ldh;ContentMode')))}">
                    <span class="msi sm" aria-hidden="true">
                        <xsl:value-of select="map:get($ldh:mode-icons, '&ldh;ContentMode')"/>
                    </span>
                    <span class="label-col">
                        <xsl:apply-templates select="key('resources', 'content', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </span>
                </a>

                <xsl:for-each select="('&ac;ReadMode', '&ac;MapMode', if ($ajax-rendering) then ('&ac;ChartMode', '&ac;GraphMode') else ())">
                    <xsl:variable name="mode-uri" select="." as="xs:string"/>
                    <xsl:for-each select="key('resources', $mode-uri, document(ac:document-uri('&ac;')))">
                        <xsl:apply-templates select="." mode="bs2:ModeListItem">
                            <xsl:with-param name="active" select="@rdf:about = $active-mode"/>
                            <xsl:with-param name="absolute-path" select="$absolute-path" tunnel="yes"/>
                            <xsl:with-param name="base-uri" select="$base-uri"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:for-each>
            </div>
        </div>
    </xsl:template>       

    <!-- TAB BODY -->
    
    <xsl:template match="rdf:RDF" mode="bs2:TabBody">
        <xsl:param name="id" select="'tab-pane-' || ac:uuid()" as="xs:string?"/>
        <xsl:param name="class" select="'tab-pane active'" as="xs:string?"/>
        <xsl:param name="mode" as="xs:anyURI"/>
        <xsl:param name="base" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="application" as="xs:anyURI?"/>
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:param name="about" as="xs:anyURI"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$base">
                <xsl:attribute name="data-base" select="$base"/>
            </xsl:if>
            <xsl:if test="$endpoint">
                <xsl:attribute name="data-endpoint" select="$endpoint"/>
            </xsl:if>
            <xsl:if test="$application">
                <xsl:attribute name="data-application" select="$application"/>
            </xsl:if>
            <xsl:if test="exists($acl-modes)">
                <xsl:attribute name="data-acl-modes" select="string-join($acl-modes, ' ')"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:DocumentBody">
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="about" select="$about"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <!-- DOCUMENT BODY -->
    
     <xsl:template match="rdf:RDF" mode="bs2:DocumentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'document-body'" as="xs:string?"/>
        <xsl:param name="mode" as="xs:anyURI"/>
        <xsl:param name="about" as="xs:anyURI"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:attribute name="about" select="$about"/>

            <xsl:apply-templates select="." mode="bs2:ActionBar">
                <xsl:with-param name="active-mode" select="$mode"/>
            </xsl:apply-templates>

            <!-- notice shown when a historical version is displayed (?version= query parameter) -->
            <xsl:if test="map:contains(ldh:query-params(), 'version')">
                <div class="alert alert-info">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'historical-version-notice', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </xsl:value-of>
                    <xsl:if test="exists(ldh:memento-datetime())">
                        <xsl:text> (</xsl:text>
                        <strong>
                            <xsl:value-of select="ldh:memento-datetime()"/>
                        </strong>
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                    <xsl:text>. </xsl:text>
                    <a href="{ac:absolute-path(ldh:base-uri(.))}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'view-current-version', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </div>
            </xsl:if>

            <!-- legend shown when a version diff is displayed (?diff= query parameter): removed content comes from the compared version, added content from the viewed one, changed content exists in both -->
            <xsl:if test="map:contains(ldh:query-params(), 'diff')">
                <div class="alert alert-info">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'comparing-versions', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </xsl:value-of>
                    <xsl:text>: </xsl:text>
                    <span class="text-error">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'removed', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </span>
                    <xsl:text> / </xsl:text>
                    <span class="text-success">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'added', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </span>
                    <xsl:text> / </xsl:text>
                    <!-- the legend's .text-* classes resolve to the same tokens as the diff decorations (ldh-bridge.css) -->
                    <span class="text-warning">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'changed', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </span>
                </div>
            </xsl:if>

            <!-- host for the RDFa editor toolbar (appended by rdfae:init-editing); empty until an editable region initializes -->
            <div class="navbar-inner editor-bar">
                <div class="content-body"></div>
            </div>

            <xsl:apply-templates select="." mode="bs2:ContentBody">
                <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <!-- CONTENT BODY -->

    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response') and not(key('resources-by-type', '&spin;ConstraintViolation')) and not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ContentBody" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content-body'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if> 
 
            <!-- error responses always rendered in bs2:Row mode, no matter what $mode specifies -->
            <xsl:apply-templates select="." mode="bs2:Row">
                <xsl:sort select="ac:label(.)"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:template match="srx:sparql" mode="bs2:ContentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content-body'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Table"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ContentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content-body'" as="xs:string?"/>
        <xsl:param name="mode" select="ac:mode(root())" as="xs:anyURI"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:choose>
                <xsl:when test="$mode = '&ldh;ContentMode'">
                    <xsl:apply-templates select="." mode="ldh:ContentList"/>
                </xsl:when>
                <xsl:when test="$mode = '&ac;MapMode'">
                    <xsl:apply-templates select="." mode="bs2:Map">
                        <xsl:with-param name="id" select="generate-id() || '-map-canvas'"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$mode = '&ac;ChartMode'">
                    <xsl:apply-templates select="." mode="bs2:Chart">
                        <xsl:with-param name="canvas-id" select="generate-id() || '-chart-canvas'"/>
                        <xsl:with-param name="show-save" select="false()"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$mode = '&ac;GraphMode'">
                    <xsl:variable name="canvas-id" select="generate-id() || '-graph-canvas'" as="xs:string"/>
                    <div id="{$canvas-id}" class="graph-3d-canvas"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="bs2:Row">
                        <xsl:sort select="ac:label(.)"/>
                        <!-- block reorder is a ContentMode affordance: rows here are not rdf:_N content members -->
                        <xsl:with-param name="show-drag-handle" select="false()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- ACTION BAR -->
    
    <!-- error responses have no breadcrumbs, actions or modes - the bar would render as an empty strip -->
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response') and not(key('resources-by-type', '&spin;ConstraintViolation')) and not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ActionBar" priority="1"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBar">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'action-bar ldh-actionbar ldh-actionbar--zoned ldh-actionbar--bc-pills'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:ActionBarLeft"/>

            <xsl:apply-templates select="." mode="bs2:ActionBarMain"/>

            <xsl:apply-templates select="." mode="bs2:ActionBarRight">
                <xsl:with-param name="active-mode" select="ac:mode(root())"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <!-- CONTENT LIST -->

    <xsl:template match="rdf:RDF" mode="ldh:ContentList">
        <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="#current"/>
        
        <!-- only show buttons to agents who have sufficient access to modify them.
             The dock is a full-bleed sticky bar that parks on the footer, per tab pane -->
        <xsl:if test="acl:mode() = '&acl;Append'">
            <div class="create-resource ldh-create-dock">
                <button type="button" class="ldh-btn create-action add-constructor" data-for-class="&ldh;XHTML">
                    <span class="msi sm" aria-hidden="true">add</span>
                    <span>
                        <xsl:apply-templates select="key('resources', '&ldh;XHTML', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                    </span>
                </button>
                <button type="button" class="ldh-btn create-action add-constructor" data-for-class="&ldh;Object">
                    <span class="msi sm" aria-hidden="true">add</span>
                    <span>
                        <xsl:apply-templates select="key('resources', '&ldh;Object', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                    </span>
                </button>
            </div>
        </xsl:if>
    </xsl:template>
        
    <!-- ROW -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Row">
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="class-uris" select="(xs:anyURI('&lapp;Application'), xs:anyURI('&sd;Service'), xs:anyURI('&nfo;FileDataObject'), xs:anyURI('&sp;Construct'), xs:anyURI('&sp;Describe'), xs:anyURI('&sp;Select'), xs:anyURI('&sp;Ask'), xs:anyURI('&ldh;RDFImport'), xs:anyURI('&ldh;CSVImport'), xs:anyURI('&ldh;GraphChart'), xs:anyURI('&ldh;ResultSetChart'), xs:anyURI('&ldh;View'))" as="xs:anyURI*"/>
        <xsl:param name="classes" select="for $class-uri in $class-uris return key('resources', $class-uri, document(ac:document-uri($class-uri)))" as="element()*"/>
        
        <!-- bring the current document resource as well as its primary topic resource (if any) to the top of the page -->
        <xsl:variable name="doc" select="key('resources', ac:absolute-path(ldh:base-uri(.)))" as="element()?"/>
        <xsl:variable name="topic" select="key('resources', $doc/foaf:primaryTopic/@rdf:*)" as="element()?"/>

        <xsl:apply-templates select="$doc" mode="#current">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$topic" mode="#current">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
        
        <!-- render the rest of the resources -->
        <!-- hide the content resources - cannot suppress them in the resource-level bs2:Block because its being reused ldh:ContentList/bs2:Row modes -->
        <xsl:apply-templates select="*[not(rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object'))] except ($doc | $topic)" mode="#current">                                     
            <xsl:sort select="ac:label(.)"/>                                                                                                                                     
        </xsl:apply-templates>
        
        <xsl:if test="$create-resource and acl:mode() = '&acl;Append' and not(key('resources-by-type', '&http;Response'))">
            <div class="create-resource ldh-create-dock">
                <xsl:apply-templates select="." mode="bs2:Create">
                    <xsl:with-param name="classes" select="$classes"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- Admin app override: ontology/SHACL/ACL/foaf class list instead of the end-user default.
         Admin apps are identified by the 'admin.' subdomain prefix on lapp:origin() (nginx wildcard routing convention). -->
    <xsl:template match="rdf:RDF[starts-with(replace(lapp:origin(), '^https?://', ''), 'admin.')]" mode="bs2:Row">
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'block-row'" as="xs:string?"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="action" select="ldh:href(ac:build-uri(ac:absolute-path(ldh:base-uri(.)), map{ '_method': 'PUT' }))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="enctype" select="'multipart/form-data'" as="xs:string?"/>
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <!-- TO-DO: generate ontology classes from the OWL vocabulary -->
        <xsl:param name="class-uris" select="(xs:anyURI('&owl;Ontology'), xs:anyURI('&owl;Class'), xs:anyURI('&owl;DatatypeProperty'), xs:anyURI('&owl;ObjectProperty'), xs:anyURI('&owl;Restriction'), xs:anyURI('&ldh;Constructor'), xs:anyURI('&sh;NodeShape'), xs:anyURI('&sh;PropertyShape'), xs:anyURI('&acl;Authorization'), xs:anyURI('&foaf;Person'), xs:anyURI('&cert;PublicKey'), xs:anyURI('&sioc;UserAccount'), xs:anyURI('&foaf;Group'))" as="xs:anyURI*"/>
        <!-- on SaxonJS proxy via ldh:href (no browser catalog, cross-origin term URIs would otherwise hit mixed-content); on SAXON keep the raw URI so Jena's location-mapping resolves it locally -->
        <xsl:param name="classes" select="for $class-uri in $class-uris return key('resources', $class-uri, document(ldh:href(ac:document-uri($class-uri), map{ 'accept': 'application/rdf+xml' }, ())))" as="element()*" use-when="system-property('xsl:product-name') = 'SaxonJS'"/>
        <xsl:param name="classes" select="for $class-uri in $class-uris return key('resources', $class-uri, document(ac:document-uri($class-uri)))" as="element()*" use-when="system-property('xsl:product-name') = 'SAXON'"/>

        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="method" select="$method"/>
            <xsl:with-param name="action" select="$action" tunnel="yes"/>
            <xsl:with-param name="enctype" select="$enctype"/>
            <xsl:with-param name="create-resource" select="$create-resource"/>
            <xsl:with-param name="classes" select="$classes"/>
        </xsl:next-match>
    </xsl:template>

    <!-- TABLE MODE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Table">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'table'" as="xs:string?"/>
        <xsl:param name="property-uris" select="distinct-values(*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <xsl:param name="property-metadata" select="if (exists($property-uris)) then ldh:send-request(resolve-uri('ns', ldt:base()), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="predicates" as="element()*">
            <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                <xsl:sort select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)" order="ascending" lang="{ac:langs()[1]}"/>

                <xsl:sequence select="current-group()[1]"/>
            </xsl:for-each-group>
        </xsl:param>
        <xsl:param name="anchor-column" as="xs:boolean" select="true()" tunnel="yes"/>
        <xsl:param name="object-uris" select="rdf:Description/*/@rdf:resource[not(key('resources', .))]" as="xs:anyURI*"/>
        <xsl:param name="object-metadata" select="if (exists($object-uris)) then ldh:send-request(sd:endpoint(), 'POST', 'application/sparql-query', $object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="predicates" select="$predicates"/>
            <xsl:with-param name="anchor-column" select="$anchor-column"/>
            <xsl:with-param name="object-uris" select="$object-uris"/>
            <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- MAP -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Map">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="class" select="'map-canvas'" as="xs:string?"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean?"/> <!-- OpenLayers handles the map drag and drop events -->

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$draggable = true()">
                <xsl:attribute name="draggable" select="'true'"/>
            </xsl:if>
            <xsl:if test="$draggable = false()">
                <xsl:attribute name="draggable" select="'false'"/>
            </xsl:if>
        </div>
    </xsl:template>
    
    <!-- CHART -->

    <!-- chart form: shell around the bs2:ChartHeader controls, the canvas and the save action -->

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:Chart">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ldh-prop-form'" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-md'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/> <!-- table is the default chart type -->
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>
        <xsl:param name="show-save" select="true()" as="xs:boolean"/>
        <xsl:param name="form-actions" as="element()?">
            <!-- saving PATCHes the current document, so the button only appears to an agent who may write to it -->
            <xsl:if test="$show-save and acl:mode() = '&acl;Write'">
                <div class="ldh-block-foot">
                    <button class="ldh-btn btn-save-chart" type="button">
                        <span class="msi sm" aria-hidden="true">save</span>
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </button>
                </div>
            </xsl:if>
        </xsl:param>

        <xsl:if test="$show-controls">
            <form method="{$method}">
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

                <fieldset>
                    <xsl:apply-templates select="." mode="bs2:ChartHeader">
                        <xsl:with-param name="chart-type" select="$chart-type"/>
                        <xsl:with-param name="category" select="$category"/>
                        <xsl:with-param name="series" select="$series"/>
                        <xsl:with-param name="chart-type-id" select="$chart-type-id"/>
                        <xsl:with-param name="category-id" select="$category-id"/>
                        <xsl:with-param name="series-id" select="$series-id"/>
                    </xsl:apply-templates>
                </fieldset>

                <div>
                    <xsl:if test="$canvas-id">
                        <xsl:attribute name="id" select="$canvas-id"/>
                    </xsl:if>
                    <xsl:if test="$canvas-class">
                        <xsl:attribute name="class" select="$canvas-class"/>
                    </xsl:if>
                </div>

                <xsl:sequence select="$form-actions"/>
            </form>
        </xsl:if>
    </xsl:template>

    <!-- chart header (RDF/XML results): chart-controls grid, category/series options grouped from resource properties -->

    <xsl:template match="rdf:RDF" mode="bs2:ChartHeader">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/> <!-- table is the default chart type -->
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>

        <div class="chart-controls">
            <div class="field">
                <label for="{$chart-type-id}">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                    </xsl:value-of>
                </label>
                <select id="{$chart-type-id}" name="ou" class="chart-type">
                    <xsl:for-each select="key('resources-by-subclass', '&ac;Chart', document(ac:document-uri('&ldh;')))">
                        <xsl:sort select="ac:label(.)" lang="{ac:langs()[1]}"/>

                        <xsl:apply-templates select="." mode="xhtml:Option">
                            <xsl:with-param name="selected" select="@rdf:about = $chart-type"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </select>
            </div>
            <div class="field">
                <label for="{$category-id}">
                    <xsl:apply-templates select="key('resources', 'category', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </label>
                <select id="{$category-id}" name="ou" class="chart-category">
                    <option value="">
                        <!-- URI is the default category -->
                        <xsl:if test="not($category)">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>

                        <xsl:text>[URI/ID]</xsl:text>
                    </option>

                    <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="ac:property-label(.)" order="ascending" lang="{ac:langs()[1]}"/>

                        <option value="{current-grouping-key()}">
                            <xsl:if test="$category = current-grouping-key()">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of>
                                <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
                            </xsl:value-of>
                        </option>
                    </xsl:for-each-group>
                </select>
            </div>
            <div class="field">
                <label for="{$series-id}">
                    <xsl:apply-templates select="key('resources', 'series', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </label>
                <select id="{$series-id}" name="ou" multiple="multiple" class="chart-series">
                    <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="ac:property-label(.)" order="ascending" lang="{ac:langs()[1]}"/>

                        <option value="{current-grouping-key()}">
                            <xsl:if test="$series = current-grouping-key()">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of>
                                <xsl:apply-templates select="current-group()[1]" mode="ac:property-label"/>
                            </xsl:value-of>
                        </option>
                    </xsl:for-each-group>
                </select>
            </div>
        </div>
    </xsl:template>

    <!-- chart header (SPARQL XML results): chart-controls grid, category/series options from result variables -->

    <xsl:template match="srx:sparql" mode="bs2:ChartHeader">
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/> <!-- table is the default chart type -->
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>

        <div class="chart-controls">
            <div class="field">
                <label for="{$chart-type-id}">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                    </xsl:value-of>
                </label>
                <select id="{$chart-type-id}" name="ou" class="chart-type">
                    <xsl:for-each select="key('resources-by-subclass', '&ac;Chart', document(ac:document-uri('&ldh;')))">
                        <xsl:sort select="ac:label(.)" lang="{ac:langs()[1]}"/>

                        <xsl:apply-templates select="." mode="xhtml:Option">
                            <xsl:with-param name="selected" select="@rdf:about = $chart-type"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </select>
            </div>
            <div class="field">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&ldh;categoryVarName'"/>
                </xsl:call-template>

                <label for="{$category-id}">
                    <xsl:apply-templates select="key('resources', 'category', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </label>
                <select id="{$category-id}" name="ol" class="chart-category">
                    <xsl:for-each select="srx:head/srx:variable">
                        <!-- leave the original variable order so it can be controlled from query -->

                        <option value="{@name}">
                            <xsl:if test="$category = @name">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of select="@name"/>
                        </option>
                    </xsl:for-each>
                </select>
            </div>
            <div class="field">
                <label for="{$series-id}">
                    <xsl:apply-templates select="key('resources', 'series', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </label>
                <select id="{$series-id}" name="ol" multiple="multiple" class="chart-series">
                    <xsl:for-each select="srx:head/srx:variable">
                        <!-- leave the original variable order so it can be controlled from query -->

                        <option value="{@name}">
                            <xsl:if test="$series = @name">
                                <xsl:attribute name="selected" select="'selected'"/>
                            </xsl:if>

                            <xsl:value-of select="@name"/>
                        </option>
                    </xsl:for-each>
                </select>
            </div>
        </div>
    </xsl:template>

    <!-- SHAPE -->
    
    <!-- converts sh:NodeShape into an rdf:Description of the new instance -->
    
    <xsl:template match="rdf:RDF" mode="ldh:Shape" as="document-node()">
        <xsl:document>
            <rdf:RDF>
                <xsl:apply-templates mode="#current"/>
            </rdf:RDF>
        </xsl:document>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&sh;NodeShape']" mode="ldh:Shape">
        <rdf:Description rdf:nodeID="{generate-id()}-instance">
            <xsl:apply-templates mode="#current"/>
        </rdf:Description>
    </xsl:template>

    <xsl:template match="sh:targetClass[@rdf:resource]" mode="ldh:Shape">
        <rdf:type rdf:resource="{@rdf:resource}"/>
    </xsl:template>
    
    <xsl:template match="sh:property[key('resources', (@rdf:resource, @rdf:nodeID)[1])[sh:path/@rdf:resource][sh:minCount]]" mode="ldh:Shape" priority="1">
        <xsl:variable name="triple" as="element()*">
            <xsl:next-match/>
        </xsl:variable>

        <xsl:for-each select="1 to key('resources', (@rdf:resource, @rdf:nodeID)[1])/sh:minCount">
            <xsl:copy-of select="$triple"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="sh:property[key('resources', (@rdf:resource, @rdf:nodeID)[1])[sh:path/@rdf:resource]]" mode="ldh:Shape">
        <xsl:for-each select="key('resources', (@rdf:resource, @rdf:nodeID)[1])">
            <xsl:variable name="property" select="." as="element()"/>
            <xsl:variable name="namespace" select="if (contains(sh:path/@rdf:resource, '#')) then substring-before(sh:path/@rdf:resource, '#') || '#' else string-join(tokenize(sh:path/@rdf:resource, '/')[not(position() = last())], '/') || '/'" as="xs:string"/>
            <xsl:variable name="local-name" select="if (contains(sh:path/@rdf:resource, '#')) then substring-after(sh:path/@rdf:resource, '#') else tokenize(sh:path/@rdf:resource, '/')[last()]" as="xs:string"/>
            
            <xsl:element namespace="{$namespace}" name="{$local-name}">
                <rdf:Description>
                    <xsl:choose>
                        <xsl:when test="$property/sh:class/@rdf:resource">
                            <rdf:type rdf:resource="{$property/sh:class/@rdf:resource}"/>
                        </xsl:when>
                        <xsl:when test="$property/sh:nodeKind/@rdf:resource = ('&sh;BlankNode', '&sh;IRI', '&sh;BlankNodeOrIRI')">
                            <rdf:type rdf:resource="&rdfs;Resource"/>
                        </xsl:when>
                        <xsl:when test="$property/sh:datatype/@rdf:resource">
                            <rdf:type rdf:resource="{$property/sh:datatype/@rdf:resource}"/>
                        </xsl:when>
                        <xsl:when test="$property/sh:nodeKind/@rdf:resource = '&sh;Literal'">
                            <rdf:type rdf:resource="&rdfs;Literal"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Warning: PropertyShape <xsl:value-of select="(@rdf:about, @rdf:nodeID)[1]"/> for path <xsl:value-of select="sh:path/@rdf:resource"/> has no sh:class, sh:nodeKind, or sh:datatype specified. Defaulting to rdfs:Resource.</xsl:message>
                            <rdf:type rdf:resource="&rdfs;Resource"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </rdf:Description>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ROW FORM -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Form" name="bs2:Form">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="action" select="ldh:href(ac:absolute-path($base-uri))" as="xs:anyURI" tunnel="yes"/>
        <!-- predicate decides whether a given child resource is "required" (i.e. its fieldset hides the .btn-remove-resource); default treats no resource as required, callers opt in -->
        <xsl:param name="required" select="function($r as element()) as xs:boolean { false() }" as="function(element()) as xs:boolean" tunnel="yes"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'ldh-prop-form'" as="xs:string?"/>
        <xsl:param name="form-actions-class" select="'ldh-block-foot'" as="xs:string?"/>
        <xsl:param name="show-close-button" select="false()" as="xs:boolean"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldh-btn'" as="xs:string?"/>
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="types" select="distinct-values(rdf:Description/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:param name="constructors" select="if (exists($types)) then (ldh:query-result(resolve-uri('ns', ldt:base()), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="constraints" select="if (exists($types)) then (ldh:query-result(resolve-uri('ns', ldt:base()), $constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="shapes" select="if (exists($types)) then (ldh:query-result(resolve-uri('ns', ldt:base()), $shape-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="type-metadata" select="if (exists($types)) then ldh:send-request(resolve-uri('ns', ldt:base()), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="property-uris" select="distinct-values(rdf:Description/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <!-- TO-DO: optimize using CONSTRUCT? -->
        <xsl:param name="property-metadata" select="if (exists($property-uris)) then ldh:send-request(resolve-uri('ns', ldt:base()), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="object-uris" select="rdf:Description/*/@rdf:resource[not(key('resources', .))]" as="xs:anyURI*"/>
        <xsl:param name="object-metadata" select="if (exists($object-uris)) then ldh:send-request(resolve-uri('ns', ldt:base()), 'POST', 'application/sparql-query', $object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        <!-- inner form content; default is the exception alerts + primary/non-primary Description iteration. Override via xsl:with-param name="body" to substitute a different body (e.g. ldh:DocumentForm mode for declarative suppression) while reusing the form shell. -->
        <xsl:param name="body" as="node()*">
            <xsl:apply-templates mode="bs2:Exception"/>

            <xsl:variable name="abs-base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
            <!-- show the current document on the top: it's the focus of this form, so it cannot be removed from its own form -->
            <xsl:apply-templates select="*[@rdf:about = $abs-base-uri]" mode="#current">
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                <xsl:with-param name="required" select="true()" tunnel="yes"/>
            </xsl:apply-templates>
            <!-- show the rest of the resources (contents, instances) below it -->
            <xsl:for-each select="*[not(@rdf:about = $abs-base-uri)]">
                <xsl:sort select="ac:label(.)"/>
                <xsl:apply-templates select="." mode="#current">
                    <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                    <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                    <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                    <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                    <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                    <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                    <xsl:with-param name="required" select="$required(.)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:param>

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

            <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'rdf'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>

            <xsl:sequence select="$body"/>

            <div class="{$form-actions-class}">
                <xsl:if test="$show-close-button">
                    <button type="button" class="ldh-btn is-ghost btn-close">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </xsl:if>

                <button type="reset" class="ldh-btn is-ghost btn-reset">
                    <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </button>

                <button type="submit" class="{$button-class} btn-save">
                    <span class="msi sm" aria-hidden="true">save</span>
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </button>
            </div>
        </form>
    </xsl:template>

    <!-- CREATE -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:Create" priority="1">
        <xsl:param name="class" select="'ldh-add-wrap btn-group'" as="xs:string?"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>
        <xsl:param name="show-instance" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <button type="button" class="ldh-btn dropdown-toggle" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                <span class="msi sm" aria-hidden="true">add</span>
                <span>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </span>
                <span class="msi caret" aria-hidden="true">expand_more</span>
            </button>

            <div class="ldh-add-menu">
                <div class="hd">
                    <xsl:apply-templates select="key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </div>
                <xsl:if test="$show-instance">
                    <xsl:apply-templates select="key('resources', '&owl;NamedIndividual', document(ac:document-uri('&owl;')))" mode="bs2:ConstructorListItem">
                        <xsl:with-param name="create-graph" select="$create-graph"/>
                        <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>

                    <span class="ldh-of-div" aria-hidden="true"></span>
                </xsl:if>
                
                <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                    <xsl:with-param name="create-graph" select="$create-graph"/>
                    <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:Create"/>

    <!-- Admin app override: hide hardcoded NamedIndividual+divider so the dropdown only shows the admin $class-uris from bs2:Row. -->
    <xsl:template match="rdf:RDF[$foaf:Agent][starts-with(replace(lapp:origin(), '^https?://', ''), 'admin.')]" mode="bs2:Create" priority="2">
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>

        <div class="ldh-add-wrap btn-group">
            <button type="button" class="ldh-btn dropdown-toggle" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))))}">
                <span class="msi sm" aria-hidden="true">add</span>
                <span>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </span>
                <span class="msi caret" aria-hidden="true">expand_more</span>
            </button>

            <div class="ldh-add-menu">
                <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                    <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    <xsl:with-param name="create-graph" select="$create-graph"/>
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </div>
        </div>
    </xsl:template>

    <!-- OBJECT -->

    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <!-- HEADER -->

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][lacl:requestAccess/@rdf:resource][$foaf:Agent]" mode="bs2:Header" priority="2">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'alert alert-info'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <h2>
                <xsl:apply-templates select="." mode="ldh:logo"/>

                <xsl:apply-templates select="." mode="ac:label"/>

                <button type="button" class="ldhc-btn in-primary ap-solid sz-md btn-access-form">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'request-access', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
            </h2>
        </div>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Header" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <h2>
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </h2>
        </div>
    </xsl:template>

</xsl:stylesheet>
