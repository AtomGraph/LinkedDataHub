<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY java   "http://xml.apache.org/xalan/java/">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps/domain#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY lsm    "https://w3id.org/atomgraph/linkeddatahub/admin/sitemap/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY aplt   "https://w3id.org/atomgraph/linkeddatahub/templates#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xhv    "http://www.w3.org/1999/xhtml/vocab#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY sparql "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY cert   "http://www.w3.org/ns/auth/cert#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY c      "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY ct     "https://www.w3.org/ns/ldt/core/templates#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY spl    "http://spinrdf.org/spl#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY list   "http://jena.hpl.hp.com/ARQ/list#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:lapp="&lapp;"
xmlns:lacl="&lacl;"
xmlns:apl="&apl;"
xmlns:aplt="&aplt;"
xmlns:rdf="&rdf;"
xmlns:xhv="&xhv;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:sparql="&sparql;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:cert="&cert;"
xmlns:sd="&sd;"
xmlns:ldt="&ldt;"
xmlns:core="&c;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:spin="&spin;"
xmlns:sp="&sp;"
xmlns:spl="&spl;"
xmlns:void="&void;"
xmlns:nfo="&nfo;"
xmlns:list="&list;"
xmlns:geo="&geo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:url="java:java.net.URLDecoder"
exclude-result-prefixes="#all">

    <xsl:import href="imports/xml-to-string.xsl"/>
    <xsl:import href="../../../../client/xsl/bootstrap/2.3.2/layout.xsl"/>
    <xsl:import href="../../../../client/xsl/converters/RDFXML2SVG.xsl"/>
    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="imports/apl.xsl"/>
    <xsl:import href="imports/dh.xsl"/>
    <xsl:import href="imports/nfo.xsl"/>
    <xsl:import href="imports/rdf.xsl"/>
    <xsl:import href="imports/sioc.xsl"/>
    <xsl:import href="imports/sp.xsl"/>
    <xsl:import href="imports/void.xsl"/>
    <xsl:import href="resource.xsl"/>
    
    <!--  To use xsl:import-schema, you need the schema-aware version of Saxon -->
    <!-- <xsl:import-schema namespace="http://www.w3.org/1999/xhtml" schema-location="http://www.w3.org/2002/08/xhtml/xhtml1-transitional.xsd"/> -->
  
    <xsl:include href="sparql.xsl"/>
    <xsl:include href="signup.xsl"/>
    <xsl:include href="request-access.xsl"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="application/xhtml+xml"/>

    <xsl:param name="lapp:Application" as="document-node()?"/>
    <xsl:param name="lacl:Agent" as="document-node()?"/>
    <xsl:param name="force-exclude-all-namespaces" select="true()"/>
    <xsl:param name="spin:query" as="xs:string?"/>
    <xsl:param name="ldt:query" as="document-node()?"/>
    <xsl:param name="ldt:template" as="xs:anyURI?"/>
    <xsl:param name="ac:httpHeaders" as="xs:string"/> 
    <xsl:param name="ac:method" as="xs:string"/>
    <xsl:param name="ac:requestUri" as="xs:anyURI?"/>
    <xsl:param name="ac:uri" as="xs:anyURI"/>
    <xsl:param name="ac:mode" select="xs:anyURI('&ac;ReadMode')" as="xs:anyURI*"/>
    <xsl:param name="ac:chart-type" as="xs:anyURI?"/>
    <xsl:param name="ac:category" as="xs:string?"/>
    <xsl:param name="ac:series" as="xs:string*"/>
    <xsl:param name="ac:googleMapsKey" select="'AIzaSyCQ4rt3EnNCmGTpBN0qoZM1Z_jXhUnrTpQ'" as="xs:string"/>
    <xsl:param name="dh:select" as="xs:string?"/>
    <xsl:param name="lacl:mode" select="if (key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource) then $lacl:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource, apl:listSuperClasses(key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource))]/acl:mode/@rdf:resource else ()" as="xs:anyURI*"/>

    <xsl:variable name="root-containers" select="($ldt:base, resolve-uri('latest/', $ldt:base), resolve-uri('geo/', $ldt:base), resolve-uri('services/', $ldt:base), resolve-uri('files/', $ldt:base), resolve-uri('imports/', $ldt:base), resolve-uri('queries/', $ldt:base), resolve-uri('charts/', $ldt:base))" as="xs:anyURI*"/>
    
    <xsl:key name="resources-by-primary-topic" match="*[@rdf:about] | *[@rdf:nodeID]" use="foaf:primaryTopic/@rdf:resource"/>
    <xsl:key name="resources-by-primary-topic-of" match="*[@rdf:about] | *[@rdf:nodeID]" use="foaf:isPrimaryTopicOf/@rdf:resource"/>
    <xsl:key name="resources-by-dataset" match="*[@rdf:about]" use="void:inDataset/@rdf:resource"/>
    <xsl:key name="resources-by-defined-by" match="*[@rdf:about]" use="rdfs:isDefinedBy/@rdf:resource"/>
    <xsl:key name="violations-by-path" match="*" use="spin:violationPath/@rdf:resource"/>
    <xsl:key name="violations-by-root" match="*" use="spin:violationRoot/@rdf:resource"/>
    <xsl:key name="violations-by-value" match="*" use="apl:violationValue/text()"/>
    <xsl:key name="resources-by-container" match="*[@rdf:about] | *[@rdf:nodeID]" use="sioc:has_parent/@rdf:resource | sioc:has_container/@rdf:resource"/>
    <xsl:key name="resources-by-expression" match="*[@rdf:nodeID]" use="sp:expression/@rdf:about | sp:expression/@rdf:nodeID"/>
    <xsl:key name="resources-by-varname" match="*[@rdf:nodeID]" use="sp:varName"/>
    <xsl:key name="resources-by-arg1" match="*[@rdf:nodeID]" use="sp:arg1/@rdf:about | sp:arg1/@rdf:nodeID"/>
    <xsl:key name="restrictions-by-container" match="*[rdf:type/@rdf:resource = '&owl;Restriction'][owl:onProperty/@rdf:resource = ('&sioc;has_parent', '&sioc;has_container')]" use="owl:allValuesFrom/@rdf:resource"/>
    
    <rdf:Description rdf:about="">
    </rdf:Description>

    <!-- show only form when ac:ModalMode combined with ac:EditMode -->
    <xsl:template match="rdf:RDF[$ac:mode = '&ac;ModalMode'][$ac:mode = '&ac;EditMode']" mode="xhtml:Body" priority="1">
        <body>
            <xsl:apply-templates select="." mode="bs2:Form">
                <xsl:with-param name="modal" select="true()" tunnel="yes"/>
            </xsl:apply-templates>
        </body>
    </xsl:template>

    <!-- show only form when ac:ModalMode combined with ac:forClass -->
    <xsl:template match="rdf:RDF[$ac:mode = '&ac;ModalMode'][$ac:forClass]" mode="xhtml:Body" priority="1">
        <body>
            <xsl:choose>
                <xsl:when test="not(key('resources-by-type', '&spin;ConstraintViolation'))">
                    <xsl:apply-templates select="ac:construct-doc($ldt:ontology, $ac:forClass, $ldt:base)" mode="bs2:Form">
                        <xsl:with-param name="modal" select="true()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="bs2:Form">
                        <xsl:with-param name="modal" select="true()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[key('resources', $ac:uri)][$ac:mode = '&aplt;InfoWindowMode']" mode="xhtml:Body" priority="1">
        <body>
            <div> <!-- SPARQLMap renders the first child of <body> as InfoWindow -->
                <xsl:apply-templates select="." mode="bs2:Block">
                    <xsl:with-param name="display" select="true()" tunnel="yes"/>
                </xsl:apply-templates>
            </div>
        </body>
    </xsl:template>

    <xsl:template match="rdf:RDF[key('resources', $ac:uri)][$ac:mode = '&aplt;ObjectMode']" mode="xhtml:Body" priority="2">
        <body class="embed">
            <div>
                <xsl:apply-templates select="." mode="bs2:Object">
                    <xsl:with-param name="show-controls" select="false()" tunnel="yes"/>
                </xsl:apply-templates>
            </div>
        </body>
    </xsl:template>
    
    <!-- HEAD - TO-DO: move to Web-Client -->
    <xsl:template match="rdf:RDF" mode="xhtml:Head">
        <head>
            <xsl:apply-templates select="." mode="xhtml:Meta"/>
    
            <xsl:apply-templates select="." mode="xhtml:Title"/>
            
            <xsl:apply-templates select="." mode="xhtml:Style"/>

            <xsl:apply-templates select="." mode="xhtml:Script"/>
        </head>
    </xsl:template>
    
    <!-- TITLE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Title">
        <title>
            <xsl:if test="$lapp:Application">
                <xsl:apply-templates select="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]" mode="ac:label"/>
                <xsl:text> - </xsl:text>
            </xsl:if>

            <xsl:apply-templates mode="#current"/>
        </title>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][not(key('resources', $ac:uri))]" mode="xhtml:Title" priority="1">
        <xsl:apply-templates select="." mode="ac:label"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = $ac:uri]" mode="xhtml:Title" priority="1">
        <xsl:apply-templates select="." mode="ac:label"/>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="xhtml:Title"/>
    
    <!-- META -->
    
    <xsl:template match="rdf:RDF" mode="xhtml:Meta">
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

        <meta name="og:url" content="{$ac:uri}"/>
        <meta name="twitter:url" content="{$ac:uri}"/>

        <xsl:for-each select="key('resources', $ac:uri)">
            <meta name="og:title" content="{ac:label(.)}"/>
            <meta name="twitter:title" content="{ac:label(.)}"/>

            <meta name="twitter:card" content="summary_large_image"/>

            <xsl:if test="ac:description(.)">
                <meta name="description" content="{ac:description(.)}"/>
                <meta property="og:description" content="{ac:description(.)}"/>
                <meta name="twitter:description" content="{ac:description(.)}"/>
            </xsl:if>

            <xsl:if test="ac:image(.)">
                <meta property="og:image" content="{ac:image(.)}"/>
                <meta name="twitter:image" content="{ac:image(.)}"/>
            </xsl:if>

            <xsl:for-each select="foaf:maker/@rdf:resource">
                <xsl:if test="doc-available(ac:document-uri(.))">
                    <xsl:for-each select="key('resources', ., document(ac:document-uri(.)))">
                        <meta name="author" content="{ac:label(.)}"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:if test="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]">
            <meta property="og:site_name" content="{ac:label($lapp:Application//*[ldt:base/@rdf:resource = $ldt:base])}"/>
        </xsl:if>
    </xsl:template>

    <!-- STYLE -->
    
    <xsl:template match="rdf:RDF" mode="xhtml:Style">
        <xsl:param name="load-wymeditor" select="not(empty($lacl:Agent//@rdf:about))" as="xs:boolean"/>
        
        <xsl:apply-imports/>

        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/bootstrap.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        <xsl:if test="$load-wymeditor">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/skins/default/skin.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        </xsl:if>
    </xsl:template>

    <!-- SCRIPT -->

    <xsl:template match="rdf:RDF" mode="xhtml:Script">
        <xsl:param name="client-stylesheet" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json', $ac:contextUri)" as="xs:anyURI"/>
        <xsl:param name="saxon-ce-log-level" select="'FINE'" as="xs:string"/>
        <xsl:param name="load-wymeditor" select="not(empty($lacl:Agent//@rdf:about))" as="xs:boolean"/>
        <xsl:param name="load-saxon-js" select="$ldt:base and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="load-sparql-builder" select="$ldt:base and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="load-sparql-map" select="$ldt:base and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="load-google-charts" select="$ldt:base and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>

        <script type="text/javascript" src="{resolve-uri('static/js/jquery.min.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/js/bootstrap.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/client/js/UUID.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/client/js/jquery.js', $ac:contextUri)}"></script>

        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/jquery.js', $ac:contextUri)}"></script>
        <script type="text/javascript">
            <![CDATA[
                var baseUri = "]]><xsl:value-of select="$ldt:base"/><![CDATA[";
                var ontologyUri = "]]><xsl:value-of select="$ldt:ontology"/><![CDATA[";
                var contextUri = "]]><xsl:value-of select="$ac:contextUri"/><![CDATA[";
            ]]>
        </script>
        <xsl:if test="$load-wymeditor">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/jquery.wymeditor.js', $ac:contextUri)}"></script>
        </xsl:if>
        <xsl:if test="$load-saxon-js">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/saxon-js/SaxonJS2.rt.js', $ac:contextUri)}"></script>
            <script type="text/javascript">
                <![CDATA[
                    window.onload = function() {
                       SaxonJS.transform({
                          stylesheetLocation: "]]><xsl:value-of select="$client-stylesheet"/><![CDATA[",
                          initialTemplate: "main",
                          logLevel: 10,
                          stylesheetParams: {
                                "context-uri-string": contextUri, // servlet context URI
                                "base-uri-string": baseUri,
                                "ontology-uri-string": ontologyUri
                                }
                       }, "async");
                    }
                ]]>
            </script>
        </xsl:if>
        <xsl:if test="$load-sparql-builder">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQLBuilder.js', $ac:contextUri)}"></script>
        </xsl:if>
        <xsl:if test="$load-sparql-map">
            <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key={$ac:googleMapsKey}"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQLMap.js', $ac:contextUri)}"></script>
        </xsl:if>
        <xsl:if test="$load-google-charts">
            <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
            <script type="text/javascript">
                <![CDATA[
                    google.charts.load('current', {packages: ['corechart', 'table', 'timeline', 'map']});
                ]]>
            </script>
        </xsl:if>
    </xsl:template>
    
    <!-- NAVBAR -->
    
    <xsl:template match="rdf:RDF" mode="bs2:NavBar">
        <div class="navbar navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container-fluid">
                    <button class="btn btn-navbar">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>

                    <xsl:if test="$ldt:base">
                        <xsl:if test="not($ldt:base = $ac:contextUri)">
                            <a class="brand context" href="{resolve-uri('..', $ldt:base)}"/>
                        </xsl:if>
                    </xsl:if>
                        
                    <a class="brand" href="{if ($lapp:Application) then lapp:base($ac:contextUri, $lapp:Application) else $ldt:base}">
                        <xsl:if test="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;AdminApplication'">
                            <xsl:attribute name="class" select="'brand admin'"/>
                        </xsl:if>
                        
                        <xsl:apply-templates select="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]" mode="ac:label"/>
                    </a>

                    <div id="collapsing-top-navbar" class="nav-collapse collapse" style="margin-left: 17%;">
                        <xsl:apply-templates select="." mode="bs2:SearchBar"/>

                        <xsl:apply-templates select="." mode="bs2:NavBarNavList"/>
                    </div>
                </div>
            </div>

            <xsl:apply-templates select="." mode="bs2:ActionBar"/>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF[$ldt:base]" mode="bs2:SearchBar" priority="1">
        <form action="{$ac:requestUri}" method="get" class="navbar-form pull-left" accept-charset="UTF-8" title="{ac:label(key('resources', 'search-title', document('translations.rdf')))}">
            <div class="input-append">
                <input type="text" id="uri" name="uri" class="input-xxlarge typeahead">
                    <xsl:if test="not(starts-with($ac:uri, $ldt:base))">
                        <xsl:attribute name="value">
                            <xsl:value-of select="$ac:uri"/>
                        </xsl:attribute>
                    </xsl:if>
                </input>

                <button type="submit">
                    <xsl:apply-templates select="key('resources', 'search', document('translations.rdf'))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn btn-primary'"/>
                    </xsl:apply-templates>
                </button>
            </div>
        </form>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:SearchBar"/>

    <xsl:template match="rdf:RDF" mode="bs2:ActionBarMain">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span6'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:ContentToggle"/>
            
            <xsl:apply-templates select="." mode="bs2:BreadCrumbList"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ActionBarRight">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span4'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Settings"/>

            <xsl:apply-templates select="." mode="bs2:MediaTypeList"/>

            <xsl:apply-templates select="." mode="bs2:NavBarActions"/>

            <xsl:apply-templates select="." mode="bs2:ModeList"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:NavBarNavList">
        <xsl:choose>
            <xsl:when test="$lacl:Agent//@rdf:about">
                <ul class="nav pull-right">
                    <li>
                        <xsl:if test="$ac:mode = '&ac;QueryEditorMode'">
                            <xsl:attribute name="class" select="'active'"/>
                        </xsl:if>
                        
                        <a href="?mode={encode-for-uri('&ac;QueryEditorMode')}">SPARQL editor</a>
                    </li>

                    <xsl:if test="$ldt:base">
                        <xsl:variable name="apps-uri" select="resolve-uri('..', $ldt:base)" as="xs:anyURI"/>
                        <xsl:if test="doc-available($apps-uri)">
                            <li>
                                <div class="btn-group">
                                    <button title="{ac:label(key('resources', 'application-list-title', document('translations.rdf')))}">
                                        <xsl:apply-templates select="key('resources', 'applications', document('translations.rdf'))" mode="apl:logo">
                                            <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                        </xsl:apply-templates>
                                    </button>
                                    <ul class="dropdown-menu pull-right">
                                        <xsl:variable name="apps" select="document($apps-uri)" as="document-node()"/>
                                        <xsl:for-each select="$apps//*[ldt:base/@rdf:resource]">
                                            <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                            <xsl:apply-templates select="." mode="bs2:AppListItem">
                                                <xsl:with-param name="active" select="ldt:base/@rdf:resource = $ldt:base"/>
                                            </xsl:apply-templates>
                                        </xsl:for-each>
                                    </ul>
                                </div>
                            </li>
                        </xsl:if>
                    </xsl:if>

                    <li>
                        <div class="btn-group">
                            <button type="button" title="{ac:label($lacl:Agent//*[@rdf:about][1])}">
                                <xsl:apply-templates select="key('resources', '&lacl;Agent', document('&lacl;'))" mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                </xsl:apply-templates>
                            </button>
                            <ul class="dropdown-menu pull-right">
                                <li>
                                    <xsl:for-each select="key('resources-by-type', '&lacl;Agent', $lacl:Agent)">
                                        <xsl:apply-templates select="." mode="xhtml:Anchor"/>
                                    </xsl:for-each>
                                </li>
                            </ul>
                        </div>
                    </li>
                </ul>
            </xsl:when>
            <xsl:when test="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;EndUserApplication'">
                <p class="pull-right">
                    <xsl:variable name="signup-uri" select="xs:anyURI(concat(resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base), '?forClass=', encode-for-uri(resolve-uri('admin/ns#Person', $ldt:base))))" as="xs:anyURI"/>
                    <a class="btn btn-primary" href="{if (not(starts-with($ldt:base, $ac:contextUri))) then concat('?uri=', encode-for-uri($signup-uri)) else $signup-uri}">Sign up</a>
                </p>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[ldt:base/@rdf:resource]" mode="bs2:AppListItem">
        <xsl:param name="active" as="xs:boolean?"/>
        
        <li>
            <xsl:if test="$active">
                <xsl:attribute name="class">active</xsl:attribute>
            </xsl:if>

            <a href="{ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}" title="{ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}">
                <xsl:apply-templates select="." mode="ac:label"/>
            </a>
        </li>
    </xsl:template>

    <xsl:template match="rdf:RDF[$ldt:base]" mode="xhtml:Body">
        <body>
            <xsl:apply-templates select="." mode="bs2:NavBar"/>

            <div id="content-body" class="container-fluid">
                <div class="row-fluid">
                    <xsl:apply-templates select="." mode="bs2:Left"/>

                    <xsl:apply-templates select="." mode="bs2:Main"/>

                    <xsl:apply-templates select="." mode="bs2:Right"/>
                </div>
            </div>

            <xsl:apply-templates select="." mode="bs2:Footer"/>
        </body>
    </xsl:template>

    <!-- always show errors (except ConstraintViolations) in block mode -->
    <xsl:template match="rdf:RDF[not(key('resources', $ac:uri))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="bs2:Main" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span12'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
        
            <xsl:apply-templates mode="bs2:Block"/>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF[$ldt:base]" mode="bs2:Main">
        <xsl:param name="id" select="'main-content'" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>
        <xsl:variable name="create-or-edit" select="$ac:mode = '&ac;EditMode' or $ac:forClass" as="xs:boolean"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
        
            <xsl:if test="not($create-or-edit)">
                <xsl:apply-templates select="." mode="apl:ChildrenCountMode"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="apl:Content"/>

            <xsl:apply-templates select="." mode="ac:ModeChoice"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="ac:ModeChoice">
        <xsl:choose>
            <xsl:when test="$ac:mode = '&ac;EditMode' or ($ac:forClass and not(contains($ac:httpHeaders, 'Location')))">
                <xsl:apply-templates select="." mode="bs2:Form"/>
            </xsl:when>
            <xsl:when test="$ac:mode = '&ac;GraphMode'">
                <xsl:apply-templates select="." mode="bs2:Graph"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="bs2:Block"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- CREATE -->
    
    <xsl:template match="rdf:RDF[$lacl:Agent][$ldt:ontology]" mode="bs2:Create" priority="1">
        <div class="btn-group pull-left">
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="ac:label"/>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <xsl:variable name="this" select="@rdf:about"/>
            <ul class="dropdown-menu">
                <xsl:variable name="constructor-list" as="element()*">
                    <xsl:call-template name="bs2:ConstructorList">
                        <xsl:with-param name="ontology" select="$ldt:ontology"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$constructor-list"/>

                <xsl:if test="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;EndUserApplication'">
                    <xsl:if test="$constructor-list">
                        <li class="divider"></li>
                    </xsl:if>

                    <xsl:variable name="default-classes" select="key('resources', (concat($ldt:ontology, 'GenericService'), concat($ldt:ontology, 'DydraService'), concat($ldt:ontology, 'Construct'), concat($ldt:ontology, 'Describe'), concat($ldt:ontology, 'Select'), concat($ldt:ontology, 'Ask'), concat($ldt:ontology, 'File'), concat($ldt:ontology, 'CSVImport'), concat($ldt:ontology, 'GraphChart'), concat($ldt:ontology, 'ResultSetChart')))" as="element()*"/>

                    <xsl:if test="key('resources', $ac:uri)/rdf:type/@rdf:resource">
                         <!--if the current resource is a Container, show Container and Item constructors--> 
                        <xsl:if test="key('resources', $ac:uri)/rdf:type/@rdf:resource = (resolve-uri('ns/default#Root', $ldt:base), resolve-uri('ns/default#Container', $ldt:base))">
                            <xsl:for-each select="key('resources', (resolve-uri('ns/default#Container', $ldt:base), resolve-uri('ns/default#Item', $ldt:base)), document(resolve-uri('ns/default', $ldt:base)))">
                                <xsl:sort select="ac:label(.)"/>
                                <li>
                                    <xsl:apply-templates select="." mode="bs2:Constructor">
                                        <xsl:with-param name="id" select="()"/>
                                        <xsl:with-param name="with-label" select="true()"/>
                                    </xsl:apply-templates>
                                </li>
                            </xsl:for-each>

                            <xsl:if test="$constructor-list or $default-classes">
                                <li class="divider"></li>
                            </xsl:if>
                        </xsl:if>
                    </xsl:if>

                    <xsl:for-each select="$default-classes">
                        <xsl:sort select="ac:label(.)"/>
                        <li>
                            <xsl:apply-templates select="." mode="bs2:Constructor">
                                <xsl:with-param name="id" select="()"/>
                                <xsl:with-param name="with-label" select="true()"/>
                            </xsl:apply-templates>
                        </li>
                    </xsl:for-each>
                </xsl:if>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:Create"/>

    <xsl:template name="bs2:ConstructorList">
        <xsl:param name="ontology" as="xs:anyURI"/>
        <xsl:param name="visited-classes" as="element()*"/>

        <!-- check if ontology document is available -->
        <xsl:if test="doc-available(ac:document-uri($ontology))">
            <xsl:variable name="ont-doc" select="document(ac:document-uri($ontology))" as="document-node()"/>
            <xsl:variable name="constructor-list" as="element()*">
                <xsl:variable name="classes" select="$ont-doc/rdf:RDF/*[@rdf:about][rdfs:isDefinedBy/@rdf:resource = $ontology][spin:constructor or (rdfs:subClassOf and apl:listSuperClasses(@rdf:about)/../../spin:constructor)]" as="element()*"/>
                <!-- do not show superclass constructor if we've already shown subclass constructor -->
                <!-- [not(apl:listSuperClasses(@rdf:about)/../. = ('&dh;Document', '&apl;Service', '&apl;Query', '&apl;File', '&apl;Import', '&apl;Chart'))] -->
                <xsl:apply-templates select="$classes[not(@rdf:about = ($classes, $visited-classes)/rdfs:subClassOf/@rdf:resource)][not((@rdf:about, apl:listSuperClasses(@rdf:about)) = ('&dh;Document', '&ldt;Parameter'))]" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>

                <!-- apply to owl:imported ontologies recursively -->
                <xsl:for-each select="key('resources', $ontology, $ont-doc)/owl:imports/@rdf:resource">
                    <xsl:call-template name="bs2:ConstructorList">
                        <xsl:with-param name="ontology" select="."/>
                        <xsl:with-param name="visited-classes" select="($visited-classes, $classes)"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:variable>
            <!-- avoid nesting lists without items (classes) -->
            <xsl:if test="$constructor-list">
                <ul>
                    <xsl:copy-of select="$constructor-list"/>
                </ul>
            </xsl:if>
        </xsl:if>
    </xsl:template>
                
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:ConstructorListItem">
<!--        <xsl:param name="ontology" as="xs:anyURI"/>-->
<!--        <xsl:param name="ont-doc" as="document-node()"/>-->
        <xsl:param name="with-label" select="true()" as="xs:boolean"/>
        
        <li>
            <xsl:apply-templates select="." mode="bs2:Constructor">
                <xsl:with-param name="id" select="()"/>
                <xsl:with-param name="with-label" select="$with-label"/>
            </xsl:apply-templates>
        </li>
    </xsl:template>
    
    <!-- LEFT NAV MODE -->
    
    <xsl:template match="rdf:RDF[$ldt:base][not(key('resources-by-type', '&http;Response'))]" mode="bs2:Left" priority="1">
        <xsl:param name="id" select="'left-nav'" as="xs:string?"/>
        <xsl:param name="class" select="'span2'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:if test="$ldt:base"> <!-- $lacl:Agent//@rdf:about -->
                <xsl:apply-templates select="." mode="bs2:RootChildrenList"/>

                <div class="well well-small">
                    <ul class="nav nav-list">
                        <xsl:for-each select="$root-containers[not(. = $ldt:base)]">
                            <li>
                                <xsl:if test="starts-with($ac:uri, .)">
                                    <xsl:attribute name="class">active</xsl:attribute>
                                </xsl:if>
                                
                                <!-- TO-DO: resolve as Linked Data resources? -->
                                <a href="{.}">
                                    <xsl:for-each select="key('resources', substring-before(substring-after(., $ldt:base), '/'), document('translations.rdf'))">
                                        <xsl:apply-templates select="." mode="apl:logo"/>
                                        <xsl:text> </xsl:text>
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </xsl:for-each>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Left"/>
    
    <!-- RIGHT NAV MODE -->
    
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri]" mode="bs2:Right">
        <xsl:apply-imports>
            <xsl:with-param name="class" select="'span3'"/>
        </xsl:apply-imports>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = $ac:uri]" mode="bs2:Right" priority="1">
        <div class="well well-small">
            <xsl:apply-templates select="." mode="bs2:PropertyList">
                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Right"/>
    
    <!-- ROOT CHILDREN MODE -->
    
    <xsl:template match="rdf:RDF" mode="bs2:RootChildrenList">
        <xsl:if test="doc-available($ldt:base)">
            <xsl:variable name="root-doc" select="document($ldt:base)" as="document-node()"/>
            <xsl:variable name="select" select="key('resources', $ldt:base, $root-doc)/dh:select/@rdf:resource" as="xs:anyURI?"/>
            <xsl:if test="$select">
                <xsl:if test="doc-available(ac:document-uri($select))">
                    <xsl:variable name="query" select="key('resources', $select, document(ac:document-uri($select)))" as="element()?"/>
                    <xsl:variable name="query-string" select="$query/sp:text" as="xs:string?"/>
                    <xsl:if test="$query-string">
                        <xsl:variable name="container-list" as="element()*">
                            <xsl:variable name="query-string" select="replace($query-string, 'DISTINCT', '')" as="xs:string"/>
                            <xsl:variable name="query-string" select="replace($query-string, 'SELECT', 'DESCRIBE')" as="xs:string"/>
                            <xsl:variable name="query-string" select="replace($query-string, '\?this', concat('&lt;', $ldt:base, '&gt;'))" as="xs:string"/>
                            <xsl:variable name="endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
                            <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($query-string)))" as="xs:anyURI"/>

                            <xsl:choose>
                                <xsl:when test="doc-available($results-uri)">
                                    <xsl:variable name="results" select="document($results-uri)" as="document-node()"/>

                                    <xsl:for-each select="key('resources-by-container', $ldt:base, $results)">
                                        <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                        <xsl:apply-templates select="." mode="bs2:List">
                                            <xsl:with-param name="active" select="starts-with($ac:uri, @rdf:about)"/>
                                        </xsl:apply-templates>
                                    </xsl:for-each>
                                </xsl:when>
                                <!-- show error if results could not be loaded -->
                                <xsl:otherwise>
                                    <div class="alert alert-block">
                                        <strong>
                                            <a href="{$select}">
                                                <xsl:apply-templates select="$query" mode="ac:label"/>
                                            </a>
                                            <xsl:text> result could not be loaded</xsl:text>
                                        </strong>
                                        <p>
                                            <a href="{concat(resolve-uri('admin/request%20access', $ldt:base), '?', 'forClass=', encode-for-uri(resolve-uri('admin/ns#AuthorizationRequest', $ldt:base)), '&amp;access-to=', encode-for-uri(resolve-uri('sparql', $ldt:base)))}" class="btn btn-small">Request access</a>
                                        </p>
                                    </div>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:if test="$container-list">
                            <div class="well well-small">
                                <h2 class="nav-header">
                                    <a href="{$ldt:base}" title="{$ldt:base}">
                                        <xsl:apply-templates select="key('resources', 'root', document('translations.rdf'))" mode="ac:label"/>
                                    </a>
                                </h2>
                                <ul class="nav nav-list">
                                    <xsl:copy-of select="$container-list"/>
                                </ul>
                            </div>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:RootChildrenList"/>
    
    <!-- MODE LIST -->
        
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="bs2:ModeList" priority="1"/>

    <xsl:template match="rdf:RDF[key('resources', key('resources', $ac:uri)/foaf:primaryTopic/@rdf:resource)/rdf:type/@rdf:resource = '&apl;Dataset']" mode="bs2:ModeList"/>

    <xsl:template match="rdf:RDF[$ac:uri]" mode="bs2:ModeList">
        <div class="btn-group pull-right">
            <button type="button" title="{ac:label(key('resources', 'mode-list-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', $ac:mode, document('&ac;')) | key('resources', $ac:mode, document('&apl;'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <xsl:for-each select="key('resources-by-type', '&ac;Mode', document('&ac;')) | key('resources', ('&ac;QueryEditorMode'), document('&ac;'))">
                    <xsl:sort select="ac:label(.)"/>
                    <xsl:apply-templates select="." mode="bs2:ModeListItem">
                        <xsl:with-param name="active" select="$ac:mode"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </ul>
        </div>
    </xsl:template>

    <!-- hide ac:EditMode if the current resource belongs is edited via its named graph (and has a separate Edit button) -->
    <xsl:template match="*[@rdf:about = '&ac;EditMode'][key('resources', $ac:uri, $main-doc)/void:inDataset/@rdf:resource]" mode="bs2:ModeListItem" priority="3"/>
    
    <!-- always show ac:DocumentModes and ac:QueryEditorMode; only show ac:ContainerModes for dh:Container (subclass) instances -->
    <xsl:template match="*[@rdf:about][$ac:uri][(rdf:type/@rdf:resource = '&ac;ContainerMode' and (key('resources', key('resources', $ac:uri, $main-doc)/core:stateOf/@rdf:resource, $main-doc)/sioc:has_parent/@rdf:resource) or key('resources', $ac:uri, $main-doc)/core:stateOf/@rdf:resource = $ldt:base) or rdf:type/@rdf:resource = '&ac;DocumentMode' or @rdf:about = '&ac;QueryEditorMode']" mode="bs2:ModeListItem" priority="1">
        <xsl:param name="active" as="xs:anyURI*"/>
        <xsl:variable name="href" select="$ac:uri" as="xs:anyURI"/>

        <li>
            <xsl:if test="@rdf:about = $active">
                <xsl:attribute name="class">active</xsl:attribute>
            </xsl:if>

            <a href="{if (not(starts-with($href, $ac:contextUri))) then xs:anyURI(concat('?uri=', encode-for-uri($href), '&amp;mode=', encode-for-uri(@rdf:about))) else if (contains($ac:uri, '?')) then concat($ac:uri, '&amp;mode=', encode-for-uri(@rdf:about)) else concat($ac:uri, '?mode=', encode-for-uri(@rdf:about))}" title="{@rdf:about}">
                <xsl:apply-templates select="." mode="apl:logo"/>
            </a>
        </li>
    </xsl:template>
       
    <xsl:template match="*" mode="bs2:ModeListItem"/>
    
    <!-- LOGO MODE -->
    
    <xsl:template match="*[@rdf:about = '&ac;ConstructMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-action')"/>
        <!-- <xsl:sequence select="ac:label(.)"/> -->
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&dh;Container'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&dh;Container']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-container')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&dh;Item'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&dh;Item']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-item')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;Service'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Service']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-service')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;Construct'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Construct']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-construct')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;Describe'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Describe']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-describe')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;Select'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Select']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-select')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;Ask'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Ask']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-ask')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;File'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;File']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-file')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&apl;Import'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Import']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-import')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&apl;Chart'] | *[@rdf:about][$ldt:ontology][apl:listSuperClasses(@rdf:about) = '&apl;Chart']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-chart')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&apl;URISyntaxViolation', '&spin;ConstraintViolation', '&apl;ResourceExistsException')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'violation')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = ('latest', 'files', 'imports', 'geo', 'queries', 'charts', 'services')]" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', @rdf:nodeID)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'toggle-content']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-toggle-content')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&aplt;Ban']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-ban')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
        
    <xsl:template match="*[@rdf:about = '&ac;Delete']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-delete')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;Export']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-export')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'settings']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-settings')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'save']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-save')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'close']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-close')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'reset']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-reset')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'search']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-search')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'applications']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-context')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&lacl;Agent']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-agent')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ReadMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-read')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;EditMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-edit')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;MapMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-map')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;GraphMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-graph')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;QueryEditorMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-query')"/>
        <text>Query editor</text>
<!--        <xsl:sequence select="ac:label(.)"/>-->
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&acl;Access']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-acl')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][lacl:requestAccess/@rdf:resource]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'access-required')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <!-- CONTENT TOGGLE MODE -->
    
    <xsl:template match="rdf:RDF[key('resources', $ac:uri)/sioc:content]" mode="bs2:ContentToggle" priority="1">
        <div class="pull-right">
            <button class="btn" title="Collapse/expand document content">
                <xsl:apply-templates select="key('resources', 'toggle-content', document('translations.rdf'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="bs2:ContentToggle"/>

    <!-- BREADCRUMB MODE -->

    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="bs2:BreadCrumbList" priority="1"/>

    <xsl:template match="*[@rdf:about]" mode="bs2:BreadCrumbListItem">
        <xsl:param name="leaf" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:choose>
            <xsl:when test="key('resources', sioc:has_container/@rdf:resource | sioc:has_parent/@rdf:resource)">
                <xsl:apply-templates select="key('resources', sioc:has_container/@rdf:resource | sioc:has_parent/@rdf:resource)" mode="#current">
                    <xsl:with-param name="leaf" select="false()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="sioc:has_container/@rdf:resource | sioc:has_parent/@rdf:resource">
                <xsl:if test="doc-available((sioc:has_container/@rdf:resource | sioc:has_parent/@rdf:resource)[1])">
                    <xsl:variable name="parent-doc" select="document(sioc:has_container/@rdf:resource | sioc:has_parent/@rdf:resource)" as="document-node()?"/>
                    <xsl:apply-templates select="key('resources', sioc:has_container/@rdf:resource | sioc:has_parent/@rdf:resource, $parent-doc)" mode="#current">
                        <xsl:with-param name="leaf" select="false()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
        </xsl:choose>
        
        <li>
            <xsl:apply-templates select="." mode="apl:logo"/>

            <xsl:apply-templates select="." mode="xhtml:Anchor"/>

            <xsl:if test="not($leaf)">
                <span class="divider">/</span>
            </xsl:if>
        </li>
    </xsl:template>

    <!-- HEADER MODE -->
        
    <xsl:template match="rdf:RDF" mode="bs2:MediaTypeList" priority="1">
        <div class="btn-group pull-right">
            <button type="button" title="{ac:label(key('resources', 'nav-bar-action-export-rdf-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', '&ac;Export', document('&ac;'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
                
                <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li>
                    <xsl:variable name="href" as="xs:anyURI">
                        <xsl:choose>
                            <xsl:when test="$ac:uri">
                                <xsl:value-of select="xs:anyURI(if (contains($ac:requestUri, '?')) then concat($ac:requestUri, '&amp;uri=', encode-for-uri(ac:document-uri($ac:uri)), '&amp;accept=', encode-for-uri('application/rdf+xml')) else concat($ac:requestUri, '?uri=', encode-for-uri(ac:document-uri($ac:uri)), '&amp;accept=', encode-for-uri('application/rdf+xml')))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="xs:anyURI(if (contains($ac:requestUri, '?')) then concat($ac:requestUri, '&amp;accept=', encode-for-uri('application/rdf+xml')) else concat($ac:requestUri, '?accept=', encode-for-uri('application/rdf+xml')))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a href="{$href}" title="application/rdf+xml">RDF/XML</a>
                </li>
                <li>
                    <xsl:variable name="href" as="xs:anyURI">
                        <xsl:choose>
                            <xsl:when test="$ac:uri">
                                <xsl:value-of select="xs:anyURI(if (contains($ac:requestUri, '?')) then concat($ac:requestUri, '&amp;uri=', encode-for-uri(ac:document-uri($ac:uri)), '&amp;accept=', encode-for-uri('text/turtle')) else concat($ac:requestUri, '?uri=', encode-for-uri(ac:document-uri($ac:uri)), '&amp;accept=', encode-for-uri('text/turtle')))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="xs:anyURI(if (contains($ac:requestUri, '?')) then concat($ac:requestUri, '&amp;accept=', encode-for-uri('text/turtle')) else concat($ac:requestUri, '?accept=', encode-for-uri('text/turtle')))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a href="{$href}" title="text/turtle">Turtle</a>
                </li>
                <xsl:if test="key('resources', $ac:uri)">
                    <li class="divider"></li>
                    
                    <xsl:variable name="href" select="xs:anyURI(concat($ac:uri, '?debug=', encode-for-uri('http://www.w3.org/ns/sparql-service-description#SPARQL11Query')))" as="xs:anyURI"/>
                    <li>
                        <a href="{$href}" title="application/sparql-query">SPARQL query</a>
                    </li>
                </xsl:if>
            </ul>
        </div>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="apl:ChildrenCountMode"/>

    <xsl:template match="*[*][@rdf:about][apl:count]" mode="apl:ChildrenCountMode" priority="1">
        <!-- <xsl:variable name="count-uri" select="xs:anyURI(key('resources-by-counter-of', @rdf:about)/@rdf:about)" as="xs:anyURI"/> -->
        <!-- <xsl:if test="doc-available($count-uri)"> -->
            <p class="pull-right ChildrenCountMode">
                <!-- <xsl:variable name="count-doc" select="document($count-uri)" as="document-node()?"/> -->
                <span class="badge">
                    <xsl:value-of select="format-number(apl:count, '0')"/>
                </span>
                <xsl:text> result(s)</xsl:text>
            </p>
        <!-- </xsl:if> -->
    </xsl:template>
    
    <!-- HEADER MODE -->

    <!-- TO-DO: move http:Response templates to error.xsl -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][lacl:requestAccess/@rdf:resource][$lacl:Agent]" mode="bs2:Header" priority="2">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'alert alert-info well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <h2>
                <xsl:apply-templates select="." mode="apl:logo"/>
                
                <a href="{if (not(starts-with(lacl:requestAccess/@rdf:resource, $ldt:base))) then resolve-uri(concat('?uri=', encode-for-uri(lacl:requestAccess/@rdf:resource), '&amp;access-to=', encode-for-uri($ac:uri)), $ldt:base) else concat(lacl:requestAccess/@rdf:resource, '&amp;access-to=', encode-for-uri($ac:uri))}" class="btn btn-primary pull-right">Request access</a>
            </h2>
        </div>
    </xsl:template>
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Header" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'alert alert-error well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <h2>
                <xsl:apply-templates select="." mode="ac:label"/>
            </h2>
        </div>
    </xsl:template>

    <!-- CONTENT MODE -->

    <xsl:template match="*[$ac:mode = '&ac;EditMode']" mode="apl:Content" priority="1"/>

    <xsl:template match="*[@rdf:about = $ac:uri][sioc:content[@rdf:parseType = 'Literal']/xhtml:div]" mode="apl:Content" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ContentMode'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <!--  remove XHTML namespace -->
            <!-- <xsl:copy-of copy-namespaces="no" select="sioc:content/xhtml:div"/> -->
            <xsl:apply-templates select="sioc:content/xhtml:div" mode="apl:XHTMLContent"/>
        </div>
    </xsl:template>

    <xsl:template match="*[@rdf:about = $ac:uri][sioc:attachment/@rdf:resource]" mode="apl:Content" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ContentMode'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <object data="{sioc:attachment/@rdf:resource}?mode={encode-for-uri('&aplt;ObjectMode')}" type="text/html"></object>
        </div>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="apl:Content"/>

    <!-- FORM MODE -->

    <xsl:template match="rdf:RDF[$ac:forClass]" mode="bs2:Form" priority="2">
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>

        <xsl:next-match> <!-- TO-DO: account for external $ac:uri -->
            <xsl:with-param name="action" select="xs:anyURI(concat($ac:uri, '?forClass=', encode-for-uri($ac:forClass), if ($modal) then concat('&amp;mode=', encode-for-uri('&ac;ModalMode')) else ()))" as="xs:anyURI"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- override form action in Client template -->
    <xsl:template match="rdf:RDF[$ac:mode = '&ac;EditMode']" mode="bs2:Form" priority="2">
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>

        <xsl:next-match>
            <xsl:with-param name="action" select="if (not(starts-with($ac:uri, $ac:contextUri))) then xs:anyURI(concat(lapp:base($ac:contextUri, $lapp:Application), '?uri=', encode-for-uri($ac:uri), '&amp;_method=PUT', string-join(for $mode in $ac:mode return concat('&amp;mode=', encode-for-uri($mode)), ''))) else if (contains($ac:uri, '?')) then xs:anyURI(concat($ac:uri, '&amp;_method=PUT', string-join(for $mode in $ac:mode return concat('&amp;mode=', encode-for-uri($mode)), ''))) else xs:anyURI(concat($ac:uri, '?_method=PUT', string-join(for $mode in $ac:mode return concat('&amp;mode=', encode-for-uri($mode)), '')))" as="xs:anyURI"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:Form" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>
        <!-- append client mode parameter (which does not reach the server and therefore is not part of the hypermedia state arguments -->
        <!-- TO-DO: make action a tunnel param? -->
        <xsl:param name="action" select="xs:anyURI(if (not(starts-with($ac:uri, $ac:contextUri))) then xs:anyURI(resolve-uri(concat('?uri=', encode-for-uri($ac:uri), if ($modal) then concat('&amp;mode=', encode-for-uri('&ac;ModalMode')) else ()), lapp:base($ac:contextUri, $lapp:Application))) else if ($modal) then if (contains($ac:uri, '?')) then concat($ac:uri, '&amp;mode=', encode-for-uri('&ac;ModalMode')) else concat($ac:uri, '?mode=', encode-for-uri('&ac;ModalMode')) else $ac:uri)" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="if (doc-available(ac:document-uri($ldt:template))) then key('resources', key('resources', $ldt:template, document(ac:document-uri($ldt:template)))/aplt:consumes/(@rdf:nodeID, @rdf:resource))/aplt:mediaType else ()" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="$modal">
                <div class="modal modal-constructor fade in">
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

                        <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'rdf'"/>
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:call-template>

                        <input type="hidden" class="target-id"/>

                        <div class="modal-header">
                            <button type="button" class="close">&#215;</button>

                            <xsl:apply-templates select="." mode="bs2:Legend"/>
                        </div>

                        <div class="modal-body">
                            <xsl:apply-templates mode="bs2:Exception"/>

                            <xsl:choose>
                                <xsl:when test="$ac:forClass and not(key('resources-by-type', '&spin;ConstraintViolation'))">
                                    <xsl:apply-templates select="ac:construct-doc($ldt:ontology, $ac:forClass, $ldt:base)/rdf:RDF/*" mode="#current">
                                        <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates mode="#current"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>

                        <xsl:apply-templates select="." mode="bs2:FormActions">
                            <xsl:with-param name="button-class" select="$button-class"/>
                        </xsl:apply-templates>
                    </form>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match>
                    <xsl:with-param name="action" select="$action"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="accept-charset" select="$accept-charset"/>
                    <xsl:with-param name="enctype" select="$enctype"/>
                </xsl:next-match>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- hide object blank nodes (that only have a single rdf:type property) from constructed models -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][not(* except rdf:type)]" mode="bs2:Form" priority="2"/>

    <!-- hide current resource, state resource, constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[@rdf:about = $ac:uri] | *[core:stateOf/@rdf:resource] | *[rdf:type/@rdf:resource = '&spin;ConstraintViolation'] | *[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Form" priority="2"/>
       
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- TARGET CONTAINER -->
    
    <xsl:template match="rdf:RDF" mode="bs2:TargetContainer">
        <fieldset class="action-container">
            <div class="control-group">
                <label class="control-label" for="input-container">
                    <xsl:apply-templates select="key('resources', '&dh;Container', document('&dh;'))" mode="ac:label"/>
                </label>
                <div class="controls">
                    <span>
                        <xsl:apply-templates select="key('resources', $ac:uri, $main-doc)" mode="apl:Typeahead">
                            <xsl:with-param name="disabled" select="true()"/>
                        </xsl:apply-templates>
                    </span>
                    <span class="help-inline">Resource</span>
                </div>
            </div>
        </fieldset>
    </xsl:template>
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document('&apl;'))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document('&apl;'))" mode="ac:label"/>
        </div>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Exception"/>

    <!-- FORM ACTIONS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:FormActions">
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div class="form-actions modal-footer">
            <button type="submit" class="{$button-class}">
                <xsl:apply-templates select="key('resources', 'save', document('translations.rdf'))" mode="apl:logo">
                    <xsl:with-param name="class" select="$button-class"/>
                </xsl:apply-templates>
            </button>
            <button type="button" class="btn">
                <xsl:apply-templates select="key('resources', 'close', document('translations.rdf'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
            <button type="reset" class="btn">
                <xsl:apply-templates select="key('resources', 'reset', document('translations.rdf'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
        </div>
    </xsl:template>
    
    <!-- LEGEND -->
    
    <xsl:template match="*[rdf:type/@rdf:resource = $ac:forClass][*[not(self::rdf:type)]]" mode="bs2:Legend" priority="1">
        <xsl:param name="forClass" select="$ac:forClass" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="key('resources', $forClass)">
                <xsl:for-each select="key('resources', $forClass)">
                    <legend title="{@rdf:about}">
                        <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo"/>
                        <xsl:text> </xsl:text>
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </legend>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <legend title="{$forClass}">
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$forClass"/>
                </legend>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Legend"/>

    <!-- FORM CONTROL -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:FormControl">
        <xsl:param name="id" select="concat('form-control-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="violations" select="key('violations-by-value', */@rdf:resource) | key('violations-by-root', (@rdf:about, @rdf:nodeID))" as="element()*"/>
        <xsl:param name="forClass" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>
        <xsl:param name="template-doc" select="ac:construct-doc($ldt:ontology, $forClass, $ldt:base)" as="document-node()?"/>
        <xsl:param name="template" select="$template-doc/rdf:RDF/*[@rdf:nodeID][every $type in rdf:type/@rdf:resource satisfies current()/rdf:type/@rdf:resource = $type]" as="element()*"/>
        <xsl:param name="template-properties" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="traversed-ids" select="@rdf:*" as="xs:string*" tunnel="yes"/>
        <xsl:param name="show-subject" select="false()" as="xs:boolean" tunnel="yes"/>

        <fieldset>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:if test="$legend">
                <legend>
                    <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="xhtml:Anchor"/>
                </legend>
            </xsl:if>

            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current">
                <xsl:with-param name="type" select="if ($show-subject) then 'text' else 'hidden'"/>
            </xsl:apply-templates>
    
            <xsl:apply-templates select="." mode="bs2:TypeControl"/>

            <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
            
            <!-- create inputs for both resource description and constructor template properties -->
            <xsl:apply-templates select="* | $template/*[not(concat(namespace-uri(), local-name()) = current()/*/concat(namespace-uri(), local-name()))][not(self::rdf:type)][not(self::foaf:isPrimaryTopicOf)]" mode="#current">
                <!-- move required properties up -->
                <xsl:sort select="not(preceding-sibling::*[concat(namespace-uri(), local-name()) = current()/concat(namespace-uri(), local-name())]) and (if (../rdf:type/@rdf:resource and $ldt:ontology) then (key('resources', key('resources', (../rdf:type/@rdf:resource, apl:listSuperClasses(../rdf:type/@rdf:resource)))/spin:constraint/(@rdf:resource|@rdf:nodeID))[rdf:type/@rdf:resource = '&apl;MissingPropertyValue'][sp:arg1/@rdf:resource = current()/concat(namespace-uri(), local-name())]) else true())" order="descending"/>
                <xsl:sort select="ac:property-label(.)"/>
                <xsl:with-param name="violations" select="$violations"/>
                <xsl:with-param name="template-doc" select="$template-doc"/>
                <xsl:with-param name="traversed-ids" select="$traversed-ids" tunnel="yes"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="$template/*[1]" mode="bs2:PropertyControl"> <!-- [not(self::rdf:type)][not(self::foaf:isPrimaryTopicOf)] -->
                <xsl:with-param name="template" select="$template"/>
                <xsl:with-param name="forClass" select="$forClass"/>
                <xsl:with-param name="required" select="true()"/>
            </xsl:apply-templates>
        </fieldset>
    </xsl:template>
    
    <!-- TYPE CONTROL -->
    
    <!-- turn off default form controls for rdf:type as we are handling it specially with bs2:TypeControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:FormControl"/>
    
    <!-- container/document types are hidden -->
    <xsl:template match="*[rdf:type/@rdf:resource][$ldt:ontology][apl:listSuperClasses(rdf:type/@rdf:resource) = ('&dh;Container', '&dh;Item')]" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- turn off blank node resources from constructor graph -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][rdf:type/starts-with(@rdf:resource, '&xsd;')] | *[@rdf:nodeID][$ac:forClass][rdf:type/@rdf:resource = '&rdfs;Resource']" mode="bs2:FormControl" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:TypeControl">
        <xsl:param name="forClass" select="resolve-uri('admin/ns#Class', $ldt:base)" as="xs:anyURI?"/> <!-- allow subclasses of lsm:Class? -->
        <xsl:param name="hidden" select="false()" as="xs:boolean"/>

        <xsl:apply-templates mode="#current">
            <xsl:sort select="ac:label(..)"/>
            <xsl:with-param name="forClass" select="$forClass"/>
            <xsl:with-param name="hidden" select="$hidden"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- TYPEAHEAD -->
    
    <xsl:template match="*[*][@rdf:about]" mode="apl:Typeahead">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'btn add-typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="title" select="@rdf:about" as="xs:string?"/>

        <button type="button">
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$disabled">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
            </xsl:if>
            <xsl:if test="$title">
                <xsl:attribute name="title"><xsl:value-of select="$title"/></xsl:attribute>
            </xsl:if>
            
            <span class="pull-left">
                <xsl:choose>
                    <xsl:when test="key('resources', foaf:primaryTopic/@rdf:resource)">
                        <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="ac:label"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
            <span class="caret pull-right"></span>
            <input type="hidden" name="ou" value="{@rdf:about}"/>
        </button>
    </xsl:template>
    
    <!-- NAVBAR ACTIONS -->

    <xsl:template match="rdf:RDF" mode="bs2:NavBarActions" priority="1">
        <xsl:if test="$lacl:Agent//@rdf:about">
                <div class="pull-right">
                    <form action="{$ac:uri}?_method=DELETE" method="post">
                        <button type="submit" title="{ac:label(key('resources', 'nav-bar-action-delete-title', document('translations.rdf')))}">
                            <xsl:apply-templates select="key('resources', '&ac;Delete', document('&ac;'))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn'"/>
                            </xsl:apply-templates>
                        </button>
                    </form>
                </div>

            <xsl:for-each select="key('resources', $ac:uri)/void:inDataset/@rdf:resource">
                <xsl:if test="not($ac:mode = '&ac;EditMode')">
                    <div class="pull-right">
                        <xsl:variable name="graph-uri" select="xs:anyURI(concat(ac:document-uri(.), '?mode=', encode-for-uri('&ac;EditMode'), '&amp;mode=', encode-for-uri('&ac;ModalMode')))" as="xs:anyURI"/>
                        <button title="{ac:label(key('resources', 'nav-bar-action-edit-graph-title', document('translations.rdf')))}">
                            <xsl:apply-templates select="key('resources', '&ac;EditMode', document('&ac;'))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn'"/>
                            </xsl:apply-templates>
                            
                            <input type="hidden" value="{$graph-uri}"/>
                        </button>
                    </div>
                </xsl:if>
            </xsl:for-each>
            
            <div class="pull-right">
                <form action="" method="get"> <!-- TO-DO: change to POST -->
                    <input type="hidden" name="ban" value="true"/>
                    <button type="submit" title="{ac:label(key('resources', 'nav-bar-action-refresh-title', document('translations.rdf')))}">
                        <xsl:apply-templates select="key('resources', '&aplt;Ban', document('&aplt;'))" mode="apl:logo">
                            <xsl:with-param name="class" select="'btn'"/>
                        </xsl:apply-templates>
                    </button>
                </form>
            </div>
            
            <div class="btn-group pull-right">
                <button type="button" title="{ac:label(key('resources', 'acl-list-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', '&acl;Access', document('&acl;'))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                    </xsl:apply-templates>
                    <xsl:text> </xsl:text>
                    <span class="caret"></span>
                </button>

                <ul class="dropdown-menu">
                    <xsl:for-each select="key('resources-by-subclass', '&acl;Access', document('&acl;'))">
                        <xsl:sort select="ac:label(.)"/>
                        <xsl:apply-templates select="." mode="bs2:AccessListItem">
                            <xsl:with-param name="enabled" select="$lacl:mode"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about]" mode="bs2:AccessListItem" priority="1">
        <xsl:param name="enabled" as="xs:anyURI*"/>
        <xsl:variable name="href" select="$ac:uri" as="xs:anyURI"/>

        <li>
            <a title="{@rdf:about}">
                <xsl:choose>
                    <xsl:when test="@rdf:about = $enabled">
                        <xsl:text>&#x2714;</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>&#x2718;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="ac:label"/>
            </a>
        </li>
    </xsl:template>
        
    <!-- SETTINGS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Settings" priority="1">
        <xsl:if test="$lacl:Agent//@rdf:about and $lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;EndUserApplication'">
            <div class="btn-group pull-right">
                <button type="button" title="{ac:label(key('resources', 'nav-bar-action-settings-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', 'settings', document('translations.rdf'))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                    </xsl:apply-templates>
                    <xsl:text> </xsl:text>
                    <span class="caret"></span>
                </button>

                <ul class="dropdown-menu">
                    <li>
                        <xsl:for-each select="$lapp:Application">
                            <a href="{key('resources', //*[ldt:base/@rdf:resource = $ldt:base]/lapp:adminApplication/(@rdf:resource, @rdf:nodeID))/ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}" target="_blank">
                                Administration
                            </a>
                        </xsl:for-each>
                    </li>
                    <li>
                        <a href="{resolve-uri('ns', $ldt:base)}" target="_blank">Namespace</a>
                    </li>
                    <li>
                        <a href="https://linkeddatahub.com/linkeddatahub/docs/" target="_blank">Help</a>
                    </li>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- VIOLATION -->

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;URISyntaxViolation']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;URISyntaxViolation', document('&apl;'))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of select="rdfs:label"/>
        </div>
    </xsl:template>
        
    <!-- take constraint labels from sitemap instead of response, if possible -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&spin;ConstraintViolation', document('&spin;'))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="ac:label"/>
        </div>
    </xsl:template>

    <!-- GRAPH MODE  -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <xsl:apply-templates select="." mode="ac:SVG">
            <xsl:with-param name="width" select="'100%'"/>
            <xsl:with-param name="spring-length" select="150" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- BLOCK MODE -->
    
    <!-- hide only those documents (already shown in the breadcrumb bar) which types are subclasses of dh:Container/dh:Item -->
    <xsl:template match="*[$ldt:ontology][@rdf:about = $ac:uri][apl:listSuperClasses(rdf:type/@rdf:resource) = ('&dh;Container', '&dh;Item')]" mode="bs2:Block"/>

    <!-- SERVER-SIDE BLOCK LIST -->
    
    <!-- embed file content -->
    <xsl:template match="*[*][dct:format]" mode="bs2:Block" priority="2">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Header"/>

            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
            
            <xsl:variable name="media-type" select="substring-after(dct:format[1]/@rdf:resource, 'http://www.sparontologies.net/mediatype/')" as="xs:string"/>
            <object data="{@rdf:about}" type="{$media-type}"></object>
        </div>
    </xsl:template>

    <!-- OBJECT -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Object"/>

    <!-- SPARQL QUERY -->
    
    <!-- Query over POST does not work -->
    <xsl:template match="*[sp:text]" mode="bs2:Actions" priority="2">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        
        <div class="pull-right">
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

                <xsl:if test="apl:endpoint/@rdf:resource">
                    <input type="hidden" name="endpoint" value="{apl:endpoint/@rdf:resource}"/>
                </xsl:if>
                <input type="hidden" name="mode" value="&ac;QueryEditorMode"/>
                <input type="hidden" name="query" value="{sp:text}"/>

                <button type="submit" class="btn btn-primary">Open</button>
            </form>
        </div>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about][sp:text][$ac:chart-type][$ac:series][$ac:category or ends-with(rdf:type/@rdf:resource, 'Construct') or ends-with(rdf:type/@rdf:resource, 'Describe')]" mode="bs2:SaveAs" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="type" select="if (ends-with(rdf:type/@rdf:resource, 'Construct') or ends-with(rdf:type/@rdf:resource, 'Describe')) then resolve-uri('ns/default#GraphChart', $ldt:base) else resolve-uri('ns/default#ResultSetChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="doc-type" select="resolve-uri('ns#ChartItem', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="query" select="@rdf:about" as="xs:anyURI"/>
        <xsl:param name="chart-type" select="$ac:chart-type" as="xs:anyURI"/>
        <xsl:param name="category" select="$ac:category" as="xs:string"/>
        <xsl:param name="series" select="$ac:series" as="xs:string"/>
        <xsl:param name="action" select="resolve-uri(concat('charts/?forClass=', encode-for-uri(resolve-uri($type, $ldt:base))), $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="id" select="'query-form'" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>

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
        
            <p>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'rdf'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'sb'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'chart'"/>
                </xsl:call-template>

                <label>
                    <xsl:apply-templates select="key('resources', '&dct;title', document('&dct;title'))" mode="ac:label"/>
                </label>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&dct;title'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="'text'"/>
                </xsl:call-template>

                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&rdf;type'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="$type"/>
                </xsl:call-template>
                <xsl:if test="$ac:endpoint">
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&apl;endpoint'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="$ac:endpoint"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&spin;query'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="$query"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&apl;chartType'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="$chart-type"/>
                </xsl:call-template>

                <xsl:for-each select="$category">
                    <xsl:choose>
                        <xsl:when test="$type = resolve-uri('ns/default#GraphChart', $ldt:base)">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;categoryProperty'"/>
                            </xsl:call-template>
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'ou'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="."/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;categoryVarName'"/>
                            </xsl:call-template>
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'ol'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="."/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <xsl:for-each select="$series">
                    <xsl:choose>
                        <xsl:when test="$type = resolve-uri('ns/default#GraphChart', $ldt:base)">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;seriesProperty'"/>
                            </xsl:call-template>
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'ou'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="."/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'pu'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="'&apl;seriesVarName'"/>
                                </xsl:call-template>
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'ol'"/>
                                    <xsl:with-param name="type" select="'hidden'"/>
                                    <xsl:with-param name="value" select="."/>
                                </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                        
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ob'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'this'"/>
                </xsl:call-template>

                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'sb'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'this'"/>
                </xsl:call-template>

                <label>
                    Document <xsl:apply-templates select="key('resources', '&dct;title', document('&dct;title'))" mode="ac:label"/>
                </label>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&dct;title'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="'text'"/>
                </xsl:call-template>

                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&rdf;type'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="$doc-type"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ob'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'chart'"/>
                </xsl:call-template>
            </p>
        
            <p>
                <button type="submit">
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn btn-primary'"/>
                    </xsl:apply-templates>

                    <xsl:text> Save</xsl:text> <!-- to do: use query class in apl:logo mode -->
                </button>
            </p>
        </form>
    </xsl:template>

    <!-- FOOTER -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Footer">
        <div class="footer container-fluid">
            <div class="row-fluid">
                <div class="offset2 span8">
                    <div class="span3">
                        <h2 class="nav-header">About</h2>
                        <ul class="nav nav-list">
                            <li>
                                <a href="https://linkeddatahub.com/linkeddatahub/docs/about/" target="_blank">LinkedDataHub</a>
                            </li>
                            <li>
                                <a href="https://atomgraph.com" target="_blank">AtomGraph</a>
                            </li>
                        </ul>
                    </div>
                    <div class="span3">
                        <h2 class="nav-header">Resources</h2>
                        <ul class="nav nav-list">
                            <li>
                                <a href="https://linkeddatahub.com/linkeddatahub/docs/" target="_blank">Documentation</a>
                            </li>
                            <li>
                                <a href="https://www.youtube.com/playlist?list=PLnDXST4pVcQQr-j3YXrVvGRP46E2Nnn5l" target="_blank">Screencasts</a>
                            </li>
                            <li>
                                <a href="https://linkeddatahub.com/demo/" target="_blank">Demo apps</a> <!-- built-in Context -->
                            </li>
                            <li>
                                <a href="https://atomgraph.github.io/Linked-Data-Templates/" target="_blank">LDT specification</a>
                            </li>
                        </ul>
                    </div>
                    <div class="span3">
                        <h2 class="nav-header">Support</h2>
                        <ul class="nav nav-list">
                            <li>
                                <a href="https://groups.io/g/linkeddatahub" target="_blank">Mailing list</a>
                            </li>
                            <li>
                                <a href="https://github.com/AtomGraph/LinkedDataHub/issues" target="_blank">Report issues</a>
                            </li>
                            <li>
                                <a href="mailto:support@linkeddatahub.com">Contact support</a>
                            </li>
                        </ul>
                    </div>
                    <div class="span3">
                        <h2 class="nav-header">Follow us</h2>
                        <ul class="nav nav-list">
                            <li>
                                <a href="https://twitter.com/atomgraphhq" target="_blank">@atomgraphhq</a>
                            </li>
                            <li>
                                <a href="https://github.com/AtomGraph" target="_blank">github.com/AtomGraph</a>
                            </li>
                            <li>
                                <a href="https://www.facebook.com/AtomGraph" target="_blank">facebook.com/AtomGraph</a>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
</xsl:stylesheet>