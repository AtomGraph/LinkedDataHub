<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
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
    <xsl:param name="acl:mode" select="$foaf:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', ac:absolute-path(ldh:base-uri(.)), $main-doc)/rdf:type/@rdf:resource, key('resources', ac:absolute-path(ldh:base-uri(.)), $main-doc)/rdf:type/@rdf:resource/ldh:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>
    
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
        <xsl:param name="class" select="'span12'" as="xs:string?"/>
        
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
        <xsl:param name="class" select="'span2'" as="xs:string?"/>
        
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
                        <xsl:with-param name="class" select="'btn-group pull-left'"/>
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
        <div class="btn-group pull-left">
            <button type="button" class="btn btn-primary dropdown-toggle" title="{ac:label(key('resources', 'add', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'add', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>
            
            <ul class="dropdown-menu">
                <li>
                    <button type="button" title="{ac:label(key('resources', 'generate-containers-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}" class="btn btn-generate-containers">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'generate-containers', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </li>
            </ul>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:AddData"/>
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBarMain">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <div class="row-fluid">
                <xsl:apply-templates select="." mode="bs2:BreadCrumbBar">
                    <xsl:with-param name="class" select="'breadcrumb-nav span8'"/>
                    <xsl:with-param name="uri" select="ac:absolute-path(ldh:base-uri(.))"/>
                </xsl:apply-templates>
                
                <div id="doc-controls" class="span4">
                    <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="bs2:Timestamp"/>
                </div>                
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBarRight">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span3'" as="xs:string?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:MediaTypeList">
                <xsl:with-param name="uri" select="ac:absolute-path(ldh:base-uri(.))"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="bs2:NavBarActions"/>
            
            <xsl:apply-templates select="." mode="bs2:ModeList">
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="ajax-rendering" select="$ldh:ajaxRendering"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:BreadCrumbBar">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span8'" as="xs:string?"/>
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
                <ul class="breadcrumb pull-left">
                    <!-- render breadcrumbs server-side -->
                    <xsl:apply-templates select="key('resources', $uri)" mode="bs2:BreadCrumbListItem"/>
                </ul>
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

    <xsl:template match="rdf:RDF" mode="bs2:NavBarActions">
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="delete-disabled" select="not(acl:mode() = '&acl;Write')" as="xs:boolean"/>
        <xsl:param name="save-as-disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="edit-disabled" select="not(acl:mode() = '&acl;Write')" as="xs:boolean"/>
        
        <xsl:if test="$foaf:Agent//@rdf:about">
            <div class="pull-right">
                <button type="button" title="{ac:label(key('resources', 'nav-bar-action-delete-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                    <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn' || (if ($delete-disabled) then ' disabled' else ())"/>
                    </xsl:apply-templates>
                    
                    <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </button>
            </div>
            
            <xsl:if test="$ldh:ajaxRendering">
                <div class="pull-right">
                    <button type="button" title="{ac:label(key('resources', 'save-as-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                        <xsl:apply-templates select="key('resources', 'save-as', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn' || (if ($save-as-disabled) then ' disabled' else ())"/>
                        </xsl:apply-templates>

                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save-as', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            <xsl:text>...</xsl:text>
                        </xsl:value-of>
                    </button>
                </div>
            
                <div class="pull-right">
                    <button type="button" title="{ac:label(key('resources', 'acl-list-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                        <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn'"/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ac:label"/>
                    </button>
                </div>

                <div class="pull-right">
                    <button type="button" class="btn btn-edit pull-right" title="{ac:label(key('resources', '&ac;EditMode', document(ac:document-uri('&ac;'))))}">
                        <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn' || (if ($edit-disabled) then ' disabled' else ())"/>
                        </xsl:apply-templates>

                        <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                    </button>
                </div>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- MODE LIST -->

    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))] | rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ModeList" priority="1"/>

    <xsl:template match="rdf:RDF" mode="bs2:ModeList" priority="2">
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="ajax-rendering" select="true()" as="xs:boolean"/>
        <xsl:param name="absolute-path" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>
        <xsl:param name="id" select="()" as="xs:string?"/>

        <div class="btn-group pull-right">
            <button type="button" class="layout-modes" title="{ac:label(key('resources', '&ac;Mode', document(ac:document-uri('&ac;'))))}">
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>

                <xsl:apply-templates select="key('resources', $active-mode, document(ac:document-uri(string($active-mode))))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <li class="content-mode{if ($active-mode = '&ldh;ContentMode') then ' active' else() }">
                    <a href="{ldh:href(ac:document-uri(ldh:base-uri(.)), ldh:build-query(xs:anyURI('&ldh;ContentMode')))}">
                        <xsl:apply-templates select="key('resources', '&ldh;ContentMode', document(ac:document-uri('&ldh;')))" mode="ldh:logo"/>
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'content', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </li>

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
            </ul>
        </div>
    </xsl:template>       

    <!-- MEDIA TYPE LIST  -->
        
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:MediaTypeList" priority="1">
        <xsl:param name="uri" as="xs:anyURI"/>
        
        <div class="btn-group pull-right">
            <button type="button" id="export-rdf" title="{ac:label(key('resources', 'nav-bar-action-export-rdf-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:apply-templates select="key('resources', '&ac;Export', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="key('resources', '&ac;Export', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                
                <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li>
                    <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:request-uri()), let $params := map{ 'accept': 'application/rdf+xml' } return if (ac:uri()) then map:merge(($params, map{ 'uri': string($uri) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="application/rdf+xml" target="_blank">RDF/XML</a>
                </li>
                <li>
                    <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:request-uri()), let $params := map{ 'accept': 'text/turtle' } return if (ac:uri()) then map:merge(($params, map{ 'uri': string($uri) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="text/turtle" target="_blank">Turtle</a>
                </li>
                <li>
                    <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:request-uri()), let $params := map{ 'accept': 'application/ld+json' } return if (ac:uri()) then map:merge(($params, map{ 'uri': string($uri) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="application/ld+json" target="_blank">JSON-LD</a>
                </li>
            </ul>
        </div>
    </xsl:template>
    
    <!-- TAB BODY -->
    
    <xsl:template match="rdf:RDF" mode="bs2:TabBody">
        <xsl:param name="id" select="'tab-pane-' || ac:uuid()" as="xs:string?"/>
        <xsl:param name="class" select="'tab-pane active'" as="xs:string?"/>
        <xsl:param name="mode" as="xs:anyURI"/>

        <div class="">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:ActionBar">
                <xsl:with-param name="active-mode" select="$mode"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="bs2:ContentBody"/>
        </div>
    </xsl:template>
    
    <!-- CONTENT BODY -->

    <xsl:template match="rdf:RDF[exists($ldh:requestUri) and key('resources-by-type', '&http;Response') and not(key('resources-by-type', '&spin;ConstraintViolation')) and not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ContentBody" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'container-fluid content-body'" as="xs:string?"/>

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
        <xsl:param name="class" select="'container-fluid content-body'" as="xs:string?"/>
        <xsl:param name="about" as="xs:anyURI?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Table"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ContentBody">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'container-fluid content-body'" as="xs:string?"/>
        <xsl:param name="about" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="key('resources', $about)/rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" select="ac:mode(root())" as="xs:anyURI"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
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
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- ACTION BAR -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBar">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'navbar-inner action-bar'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <div class="container-fluid">
                <div class="row-fluid">
                    <xsl:apply-templates select="." mode="bs2:ActionBarLeft"/>

                    <xsl:apply-templates select="." mode="bs2:ActionBarMain"/>
                    
                    <xsl:apply-templates select="." mode="bs2:ActionBarRight">
                        <xsl:with-param name="active-mode" select="ac:mode(root())"/>
                    </xsl:apply-templates>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- CONTENT LIST -->

    <xsl:template match="rdf:RDF" mode="ldh:ContentList">
        <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="#current"/>
        
        <!-- only show buttons to agents who have sufficient access to modify them -->
        <xsl:if test="acl:mode() = '&acl;Append'">
            <div class="create-resource row-fluid">
                <div class="main offset2 span7">
                    <p>
                        <button type="button" class="btn btn-primary create-action add-constructor" data-for-class="&ldh;XHTML">
                            <xsl:apply-templates select="key('resources', '&ldh;XHTML', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                        </button>
                        <button type="button" class="btn btn-primary create-action add-constructor" data-for-class="&ldh;Object">
                            <xsl:apply-templates select="key('resources', '&ldh;Object', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                        </button>
                    </p>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
        
    <!-- ROW -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Row">
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="class-uris" select="(xs:anyURI('&lapp;Application'), xs:anyURI('&sd;Service'), xs:anyURI('&nfo;FileDataObject'), xs:anyURI('&sp;Construct'), xs:anyURI('&sp;Describe'), xs:anyURI('&sp;Select'), xs:anyURI('&sp;Ask'), xs:anyURI('&ldh;RDFImport'), xs:anyURI('&ldh;CSVImport'), xs:anyURI('&ldh;GraphChart'), xs:anyURI('&ldh;ResultSetChart'), xs:anyURI('&ldh;View'))" as="xs:anyURI*"/>
        <xsl:param name="classes" select="for $class-uri in $class-uris return key('resources', $class-uri, document(ac:document-uri($class-uri)))" as="element()*"/>

        <!-- select elements explicitly, because Saxon-JS chokes on text nodes here -->
        <!-- hide the content resources - cannot suppress them in the resource-level bs2:Block because its being reused ldh:ContentList/bs2:Row modes -->
        <xsl:apply-templates select="*[not(rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object'))]" mode="#current">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
        
        <xsl:if test="$create-resource and acl:mode() = '&acl;Append' and not(key('resources-by-type', '&http;Response'))">
            <div class="create-resource row-fluid">
                <div class="main offset2 span7">
                    <xsl:apply-templates select="." mode="bs2:Create">
                        <xsl:with-param name="classes" select="$classes"/>
                    </xsl:apply-templates>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- TABLE MODE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Table">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'table table-bordered table-striped'" as="xs:string?"/>
        <xsl:param name="predicates" as="element()*">
            <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

                <xsl:sequence select="current-group()[1]"/>
            </xsl:for-each-group>
        </xsl:param>
        <xsl:param name="anchor-column" as="xs:boolean" select="true()" tunnel="yes"/>
        <xsl:param name="object-uris" select="rdf:Description/*/@rdf:resource[not(key('resources', .))]" as="xs:anyURI*"/>
        <xsl:param name="object-metadata" select="if (exists($object-uris)) then ldh:send-request($sd:endpoint, 'POST', 'application/sparql-query', $object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        
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

    <!-- graph chart (for RDF/XML results) -->

    <xsl:template match="rdf:RDF" mode="bs2:Chart">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&ldh;GraphChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
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
            <xsl:if test="$show-save">
                <div class="form-actions">
                    <button class="btn btn-primary btn-save-chart" type="button">
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                        </xsl:apply-templates>

                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </button>
                </div>
            </xsl:if>
        </xsl:param>

        <xsl:if test="$show-controls">
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
                
                <fieldset>
                    <div class="row-fluid">
                        <div class="span4">
                            <label for="{$chart-type-id}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <!-- TO-DO: replace with xsl:apply-templates on ac:Chart subclasses as in imports/ldh.xsl -->
                            <select id="{$chart-type-id}" name="ou" class="input-medium chart-type">
                                <option value="&ac;Table">
                                    <xsl:if test="$chart-type = '&ac;Table'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Table</xsl:text>
                                </option>
                                <option value="&ac;ScatterChart">
                                    <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Scatter chart</xsl:text>
                                </option>
                                <option value="&ac;LineChart">
                                    <xsl:if test="$chart-type = '&ac;LineChart'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Line chart</xsl:text>
                                </option>
                                <option value="&ac;BarChart">
                                    <xsl:if test="$chart-type = '&ac;BarChart'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Bar chart</xsl:text>
                                </option>
                                <option value="&ac;Timeline">
                                    <xsl:if test="$chart-type = '&ac;Timeline'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Timeline</xsl:text>
                                </option>
                            </select>
                        </div>
                        <div class="span4">
                            <label for="{$category-id}">Category</label>
                            <select id="{$category-id}" name="ou" class="input-large chart-category">
                                <option value="">
                                    <!-- URI is the default category -->
                                    <xsl:if test="not($category)">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>[URI/ID]</xsl:text>
                                </option>

                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

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
                        <div class="span4">
                            <label for="{$series-id}">Series</label>
                            <select id="{$series-id}" name="ou" multiple="multiple" class="input-large chart-series">
                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

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

    <!-- table chart (for SPARQL XML results) -->

    <xsl:template match="srx:sparql" mode="bs2:Chart">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="canvas-class" select="'chart-canvas'" as="xs:string?"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="xs:anyURI('&dh;Item')" as="xs:anyURI"/>
        <xsl:param name="type" select="xs:anyURI('&ldh;ResultSetChart')" as="xs:anyURI"/>
        <xsl:param name="action" select="ac:build-uri(resolve-uri('charts/', $ldt:base), map{ 'forClass': string($type) })" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
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
            <xsl:if test="$show-save">
                <div class="form-actions">
                    <button class="btn btn-primary btn-save-chart" type="button">
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn btn-primary btn-save-chart'"/>
                        </xsl:apply-templates>

                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </button>
                </div>
            </xsl:if>
        </xsl:param>
        
        <xsl:if test="$show-controls">
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
                
                <fieldset>
                    <div class="row-fluid">
                        <div class="span4">
                            <label for="{$chart-type-id}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', '&ldh;chartType', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                                </xsl:value-of>
                            </label>
                            <select id="{$chart-type-id}" name="ou" class="input-medium chart-type">
                                <option value="&ac;Table">
                                    <xsl:if test="$chart-type = '&ac;Table'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Table</xsl:text>
                                </option>
                                <option value="&ac;ScatterChart">
                                    <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Scatter chart</xsl:text>
                                </option>
                                <option value="&ac;LineChart">
                                    <xsl:if test="$chart-type = '&ac;LineChart'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Line chart</xsl:text>
                                </option>
                                <option value="&ac;BarChart">
                                    <xsl:if test="$chart-type = '&ac;BarChart'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Bar chart</xsl:text>
                                </option>
                                <option value="&ac;Timeline">
                                    <xsl:if test="$chart-type = '&ac;Timeline'">
                                        <xsl:attribute name="selected" select="'selected'"/>
                                    </xsl:if>

                                    <xsl:text>Timeline</xsl:text>
                                </option>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&ldh;categoryVarName'"/>
                            </xsl:call-template>

                            <label for="{$category-id}">Category</label>
                            <select id="{$category-id}" name="ol" class="input-large chart-category">
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
                        <div class="span4">
                            <label for="{$series-id}">Series</label>
                            <select id="{$series-id}" name="ol" multiple="multiple" class="input-large chart-series">
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
    
    <xsl:template match="rdf:RDF" mode="bs2:Form">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="action" select="ldh:href(ac:absolute-path($base-uri))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="form-actions-class" select="'form-actions'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="create-resource" select="true()" as="xs:boolean"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="types" select="distinct-values(rdf:Description/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:param name="constructors" select="if (exists($types)) then (ldh:query-result(resolve-uri('ns', $ldt:base), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="constraints" select="if (exists($types)) then (ldh:query-result(resolve-uri('ns', $ldt:base), $constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="shapes" select="if (exists($types)) then (ldh:query-result(resolve-uri('ns', $ldt:base), $shape-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="type-metadata" select="if (exists($types)) then ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="property-uris" select="distinct-values(rdf:Description/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
        <!-- TO-DO: optimize using CONSTRUCT? -->
        <xsl:param name="property-metadata" select="if (exists($property-uris)) then ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', 'DESCRIBE $Type' || ' VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>
        <xsl:param name="object-uris" select="rdf:Description/*/@rdf:resource[not(key('resources', .))]" as="xs:anyURI*"/>
        <xsl:param name="object-metadata" select="if (exists($object-uris)) then ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', $object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' }) else ()" as="document-node()?" tunnel="yes"/>

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
            
            <xsl:apply-templates mode="bs2:Exception"/>

            <!-- show the current document on the top -->
            <xsl:apply-templates select="*[@rdf:about = ac:absolute-path(ldh:base-uri(.))]" mode="#current">
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
            </xsl:apply-templates>
            <!-- show the rest of the resources (contents, instances) below it -->
            <xsl:apply-templates select="*[not(@rdf:about = ac:absolute-path(ldh:base-uri(.)))]" mode="#current">
                <xsl:sort select="ac:label(.)"/>
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                <xsl:with-param name="constructors" select="$constructors" tunnel="yes"/>
                <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/>
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
            </xsl:apply-templates>

            <div class="{$form-actions-class}">
                <button type="submit" class="btn btn-primary'">
                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="$button-class"/>
                    </xsl:apply-templates>

                    <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </button>

                <button type="reset" class="btn">
                    <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>

                    <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </button>
            </div>
        </form>
    </xsl:template>

    <!-- CREATE -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:Create" priority="1">
        <xsl:param name="class" select="'btn-group'" as="xs:string?"/>
        <xsl:param name="classes" as="element()*"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>
        <xsl:param name="show-instance" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <xsl:if test="$show-instance">
                    <xsl:apply-templates select="key('resources', '&owl;NamedIndividual', document(ac:document-uri('&owl;')))" mode="bs2:ConstructorListItem">
                        <xsl:with-param name="create-graph" select="$create-graph"/>
                        <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>

                    <li class="divider"></li>
                </xsl:if>
                
                <xsl:apply-templates select="$classes" mode="bs2:ConstructorListItem">
                    <xsl:with-param name="create-graph" select="$create-graph"/>
                    <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:Create"/>
    
    <!-- OBJECT -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
</xsl:stylesheet>
