<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps/domain#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY lsm    "https://w3id.org/atomgraph/linkeddatahub/admin/sitemap/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY aplt   "https://w3id.org/atomgraph/linkeddatahub/templates#">
    <!ENTITY google "https://w3id.org/atomgraph/linkeddatahub/services/google#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xhv    "http://www.w3.org/1999/xhtml/vocab#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
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
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
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
xmlns:geo="&geo;"
xmlns:google="&google;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="imports/xml-to-string.xsl"/>
    <xsl:import href="../../../../client/xsl/converters/RDFXML2JSON-LD.xsl"/>
    <xsl:import href="../../../../client/xsl/bootstrap/2.3.2/internal-layout.xsl"/>
    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="imports/apl.xsl"/>
    <xsl:import href="imports/dct.xsl"/>
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

    <xsl:param name="apl:baseUri" as="xs:anyURI" static="yes"/>
    <xsl:param name="lapp:Application" as="document-node()?"/>
    <xsl:param name="sd:endpoint" select="if ($ldt:base) then resolve-uri('sparql', $ldt:base) else ()" as="xs:anyURI?"/>
    <xsl:param name="a:graphStore" select="if ($ldt:base) then resolve-uri('service', $ldt:base) else ()" as="xs:anyURI?"/>
    <xsl:param name="lacl:Agent" as="document-node()?"/>
    <xsl:param name="force-exclude-all-namespaces" select="true()"/>
    <xsl:param name="ldt:template" as="xs:anyURI?"/>
    <xsl:param name="ac:httpHeaders" as="xs:string"/> 
    <xsl:param name="ac:method" as="xs:string"/>
    <xsl:param name="ac:requestUri" as="xs:anyURI?"/>
    <xsl:param name="ac:uri" as="xs:anyURI"/>
    <xsl:param name="ac:mode" select="xs:anyURI('&ac;ReadMode')" as="xs:anyURI*"/>
    <xsl:param name="ac:googleMapsKey" select="'AIzaSyCQ4rt3EnNCmGTpBN0qoZM1Z_jXhUnrTpQ'" as="xs:string"/>
    <xsl:param name="lacl:mode" select="$lacl:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource, key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource/apl:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>
    <xsl:param name="google:clientID" as="xs:string?"/>

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
                <xsl:value-of>
                    <xsl:apply-templates select="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> - </xsl:text>
            </xsl:if>

            <xsl:apply-templates mode="#current"/>
        </title>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][not(key('resources', $ac:uri))]" mode="xhtml:Title" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="." mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = $ac:uri]" mode="xhtml:Title" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="." mode="ac:label"/>
        </xsl:value-of>
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
        <xsl:param name="load-wymeditor" select="exists($lacl:Agent//@rdf:about)" as="xs:boolean"/>
        
        <xsl:apply-imports/>

        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/bootstrap.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        <xsl:if test="$load-wymeditor">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/skins/default/skin.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        </xsl:if>
    </xsl:template>

    <!-- SCRIPT -->

    <xsl:template match="rdf:RDF" mode="xhtml:Script">
        <xsl:param name="client-stylesheet" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json', $ac:contextUri)" as="xs:anyURI"/>
        <xsl:param name="saxon-js-log-level" select="10" as="xs:integer"/>
        <xsl:param name="load-wymeditor" select="exists($lacl:Agent//@rdf:about)" as="xs:boolean"/>
        <xsl:param name="load-saxon-js" select="$ldt:base and not($ac:mode = ('&ac;ModalMode', '&aplt;InfoWindowMode')) and not($ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="load-sparql-builder" select="$ldt:base and not($ac:mode = ('&ac;ModalMode', '&aplt;InfoWindowMode')) and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="load-sparql-map" select="$ldt:base and not($ac:mode = ('&ac;ModalMode', '&aplt;InfoWindowMode')) and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="load-google-charts" select="$ldt:base and not($ac:mode = ('&ac;ModalMode', '&aplt;InfoWindowMode')) and not($ac:mode = ('&ac;ModalMode', '&aplt;InfoWindowMode')) and (not(key('resources-by-type', '&http;Response')) or $ac:uri = resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base))" as="xs:boolean"/>
        <xsl:param name="output-json-ld" select="false()" as="xs:boolean"/>

        <!-- Web-Client scripts -->
        <script type="text/javascript" src="{resolve-uri('static/js/jquery.min.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/js/bootstrap.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/client/js/UUID.js', $ac:contextUri)}" defer="defer"></script>
        <!-- LinkedDataHub scripts -->
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/jquery.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript">
            <![CDATA[
                var baseUri = "]]><xsl:value-of select="$ldt:base"/><![CDATA[";
                var ontologyUri = "]]><xsl:value-of select="$ldt:ontology"/><![CDATA[";
                var contextUri = "]]><xsl:value-of select="$ac:contextUri"/><![CDATA[";
            ]]>
        </script>
        <xsl:if test="$load-wymeditor">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/jquery.wymeditor.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-saxon-js">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/saxon-js/SaxonJS2.rt.js', $ac:contextUri)}" defer="defer"></script>
            <script type="text/javascript">
                <![CDATA[
                    window.onload = function() {
                        const locationMapping = [ 
                            { name: contextUri + "static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf", altName: contextUri + "static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf" },
                            { name: "https://w3id.org/atomgraph/client", altName: baseUri + "?uri=" + encodeURIComponent("https://w3id.org/atomgraph/client") + "&accept=" + encodeURIComponent("application/rdf+xml") }
                            ]]>
                            <!--
                            <xsl:variable name="ontology-imports" select="apl:ontologyImports($ldt:ontology)" as="xs:anyURI*"/>
                            <xsl:if test="exists($ontology-imports)">
                                <xsl:text>,</xsl:text>
                                <xsl:for-each select="apl:ontologyImports($ldt:ontology)">
                                    <xsl:text>{ name: "</xsl:text>
                                    <xsl:value-of select="ac:document-uri(.)"/>
                                    <xsl:text>", altName: baseUri + "?uri=" + encodeURIComponent("</xsl:text>
                                    <xsl:value-of select="ac:document-uri(.)"/>
                                    <xsl:text>") + "&amp;accept=" + encodeURIComponent("application/rdf+xml") }</xsl:text>
                                    <xsl:if test="position() != last()">
                                        <xsl:text>, </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:if>
                            -->
                            <![CDATA[
                        ];
                        const docPromises = locationMapping.map(mapping => SaxonJS.getResource({location: mapping.altName, type: "xml"}));
    
                        Promise.all(docPromises)
                        .then(resources => {
                            const cache = {};
                            for (var i = 0; i < resources.length; i++) {
                                cache[locationMapping[i].name] = resources[i]
                            };
                            return SaxonJS.transform({
                                documentPool: cache,
                                stylesheetLocation: "]]><xsl:value-of select="$client-stylesheet"/><![CDATA[",
                                initialTemplate: "main",
                                logLevel: ]]><xsl:value-of select="$saxon-js-log-level"/><![CDATA[,
                                stylesheetParams: {
                                    "Q{https://w3id.org/atomgraph/client#}contextUri": contextUri, // servlet context URI
                                    "Q{https://www.w3.org/ns/ldt#}base": baseUri,
                                    "Q{https://www.w3.org/ns/ldt#}ontology": ontologyUri
                                    }
                            }, "async");
                        })
                        .catch(err => console.log("Transformation failed: " + err));
                    }
                ]]>
            </script>
        </xsl:if>
        <xsl:if test="$load-sparql-builder">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQLBuilder.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-sparql-map">
            <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key={$ac:googleMapsKey}" defer="defer"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQLMap.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-google-charts">
            <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
            <script type="text/javascript">
                <![CDATA[
                    google.charts.load('current', {packages: ['corechart', 'table', 'timeline', 'map']});
                ]]>
            </script>
        </xsl:if>
        <xsl:if test="$output-json-ld">
            <!-- output structured data: https://developers.google.com/search/docs/guides/intro-structured-data -->
            <script type="application/ld+json">
                <xsl:apply-templates select="." mode="ac:JSON-LD"/>
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
                        
                        <xsl:value-of>
                            <xsl:apply-templates select="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]" mode="ac:label"/>
                        </xsl:value-of>
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

    <xsl:template match="rdf:RDF[$ldt:base][$lacl:mode = '&acl;Read']" mode="bs2:SearchBar" priority="1">
        <form action="{$ac:requestUri}" method="get" class="navbar-form pull-left" accept-charset="UTF-8" title="{ac:label(key('resources', 'search-title', document('translations.rdf')))}">
            <div class="input-append">
                <select id="search-service" name="service">
                    <option value="">[SPARQL service]</option>
                </select>
                
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

    <xsl:template match="rdf:RDF" mode="bs2:ActionBarLeft">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span2'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:sequence select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:sequence select="$class"/></xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Create"/>
            
            <xsl:apply-templates select="." mode="bs2:AddData"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ActionBarMain">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:ContentToggle"/>

            <div id="result-counts">
                <!-- placeholder for client.xsl callbacks -->
            </div>

            <div id="breadcrumb-nav">
                <!-- placeholder for client.xsl callbacks -->
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ActionBarRight">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span3'" as="xs:string?"/>

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
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:NavBarNavList">
        <xsl:if test="$lacl:Agent//@rdf:about">
            <ul class="nav pull-right">
                <li>
                    <xsl:if test="$ac:mode = '&ac;QueryEditorMode'">
                        <xsl:attribute name="class" select="'active'"/>
                    </xsl:if>

                    <a href="{ac:build-uri((), map{ 'mode': '&ac;QueryEditorMode' })}">SPARQL editor</a>
                </li>
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
        </xsl:if>

        <xsl:apply-templates select="." mode="bs2:SignUp"/>
    </xsl:template>

    <xsl:template match="rdf:RDF[not($lacl:Agent//@rdf:about)][$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="bs2:SignUp" priority="1">
        <xsl:param name="uri" select="ac:build-uri(resolve-uri(concat('admin/', encode-for-uri('sign up')), $ldt:base), map{ 'forClass': string(resolve-uri('admin/ns#Person', $ldt:base)) })" as="xs:anyURI"/>
        <xsl:param name="google-signup" select="exists($google:clientID)" as="xs:boolean"/>
        <xsl:param name="webid-signup" select="true()" as="xs:boolean"/>
        
        <xsl:if test="$google-signup or $webid-signup">
            <p class="pull-right">
                <xsl:if test="$google-signup">
                    <a class="btn btn-primary" href="{ac:build-uri(resolve-uri('admin/oauth2/authorize/google', $apl:baseUri), map{ 'referer': string($ac:uri) })}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'login-google', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </xsl:if>
                <xsl:if test="$webid-signup">
                    <a class="btn btn-primary" href="{if (not(starts-with($ldt:base, $apl:baseUri))) then ac:build-uri((), map{ 'uri': string($uri) }) else $uri}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'sign-up', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </xsl:if>
            </p>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:SignUp"/>
    
    <xsl:template match="*[ldt:base/@rdf:resource]" mode="bs2:AppListItem">
        <xsl:param name="active" as="xs:boolean?"/>
        
        <li>
            <xsl:if test="$active">
                <xsl:attribute name="class">active</xsl:attribute>
            </xsl:if>

            <a href="{ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}" title="{ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </a>
        </li>
    </xsl:template>

    <xsl:template match="rdf:RDF[$ldt:base]" mode="xhtml:Body">
        <body>
            <xsl:apply-templates select="." mode="bs2:NavBar"/>

            <div id="content-body" class="container-fluid">
                <xsl:apply-templates mode="#current"/>
            </div>

            <xsl:apply-templates select="." mode="bs2:Footer"/>
        </body>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="xhtml:Body">
        <div class="row-fluid">
            <xsl:apply-templates select="." mode="bs2:Left"/>

            <xsl:apply-templates select="." mode="bs2:Main"/>

            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
    </xsl:template>
    
    <!-- always show errors (except ConstraintViolations) in block mode -->
    <xsl:template match="rdf:RDF[not(key('resources', $ac:uri))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="xhtml:Body" priority="1">
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

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Main">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Block"/>
        </div>
    </xsl:template>

    <!-- CREATE -->
    
    <xsl:template match="rdf:RDF[$lacl:mode = '&acl;Append'][$ldt:ontology]" mode="bs2:Create" priority="1">
        <div class="btn-group pull-left">
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <xsl:variable name="this" select="@rdf:about"/>
            <ul class="dropdown-menu">
                <xsl:variable name="default-classes" select="key('resources', (resolve-uri('ns/domain/system#GenericService', $ldt:base), resolve-uri('ns/domain/system#DydraService', $ldt:base), resolve-uri('ns/domain/system#Construct', $ldt:base), resolve-uri('ns/domain/system#Describe', $ldt:base), resolve-uri('ns/domain/system#Select', $ldt:base), resolve-uri('ns/domain/system#Ask', $ldt:base), resolve-uri('ns/domain/system#File', $ldt:base), resolve-uri('ns/domain/system#CSVImport', $ldt:base), resolve-uri('ns/domain/system#RDFImport', $ldt:base), resolve-uri('ns/domain/system#GraphChart', $ldt:base), resolve-uri('ns/domain/system#ResultSetChart', $ldt:base)), document(resolve-uri('ns/domain/system', $ldt:base)))" as="element()*"/>
                <xsl:variable name="constructor-list" as="element()*">
                    <xsl:call-template name="bs2:ConstructorList">
                        <xsl:with-param name="ontology" select="$ldt:ontology"/>
                        <xsl:with-param name="visited-classes" select="$default-classes"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:copy-of select="$constructor-list"/>
                
                <xsl:if test="$constructor-list and $default-classes">
                    <li class="divider"></li>
                </xsl:if>

                <!--if the current resource is a Container, show Container and Item constructors--> 
                <xsl:variable name="document-classes" select="key('resources', (resolve-uri('ns/domain/default#Container', $ldt:base), resolve-uri('ns/domain/default#Item', $ldt:base)), document(resolve-uri('ns/domain/default', $ldt:base)))" as="element()*"/>
                <!-- current resource is a container -->
                <xsl:if test="exists($document-classes) and key('resources', $ac:uri)/rdf:type/@rdf:resource = (resolve-uri('ns/domain/default#Root', $ldt:base), resolve-uri('ns/domain/default#Container', $ldt:base))">
                    <xsl:apply-templates select="$document-classes" mode="bs2:ConstructorListItem">
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>

                    <xsl:if test="$default-classes">
                        <li class="divider"></li>
                    </xsl:if>
                </xsl:if>

                <xsl:apply-templates select="$default-classes" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
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
                <!-- eliminate matches where a class is a subclass of itself (happens in inferenced ontology models) -->
                <xsl:apply-templates select="$classes[not(@rdf:about = $visited-classes/@rdf:about)][let $about := @rdf:about return not(@rdf:about = ($classes, $visited-classes)[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)][not((@rdf:about, apl:listSuperClasses(@rdf:about)) = ('&dh;Document', '&ldt;Parameter'))]" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>

                <!-- show user-defined classes. Apply to owl:imported ontologies recursively -->
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
                
    <xsl:template match="*[*][@rdf:about]" mode="bs2:ConstructorListItem">
        <xsl:param name="with-label" select="true()" as="xs:boolean"/>

        <!-- the class document has to be available -->
        <xsl:if test="doc-available(ac:document-uri(@rdf:about))">
            <li>
                <xsl:apply-templates select="." mode="bs2:Constructor">
                    <xsl:with-param name="id" select="()"/>
                    <xsl:with-param name="with-label" select="$with-label"/>
                </xsl:apply-templates>
            </li>
        </xsl:if>
    </xsl:template>
    
    <!-- ADD DATA -->
    
    <xsl:template match="rdf:RDF[$lacl:mode = '&acl;Append'][$ldt:ontology]" mode="bs2:AddData" priority="1">
        <div class="btn-group pull-left">
            <button type="button" title="{ac:label(key('resources', 'add-data-title', document('translations.rdf')))}" class="btn btn-primary add-data">
<!--                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>-->
<!--                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="ac:label"/>
                </xsl:value-of>-->
                <xsl:text>Add data</xsl:text>
            </button>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:AddData"/>

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
                <div id="container-nav">
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
                                            <xsl:value-of>
                                                <xsl:apply-templates select="." mode="ac:label"/>
                                            </xsl:value-of>
                                        </xsl:for-each>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Left"/>
    
    <!-- RIGHT NAV MODE -->
    
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri]" mode="bs2:Right">
        <xsl:apply-imports>
            <xsl:with-param name="id" select="'right-nav'"/>
            <xsl:with-param name="class" select="'span3'"/>
        </xsl:apply-imports>
    </xsl:template>

    <!-- suppress most properties of the current document in the right nav, except some basic metadata -->
    <xsl:template match="*[@rdf:about = $ac:uri][dct:created or dct:modified or foaf:maker or acl:owner or foaf:primaryTopic or dh:select]" mode="bs2:Right" priority="1">
        <xsl:variable name="definitions" as="document-node()">
            <xsl:document>
                <dl class="dl-horizontal">
                    <xsl:apply-templates select="dct:created | dct:modified | foaf:maker | acl:owner | foaf:primaryTopic | dh:select" mode="bs2:PropertyList">
                        <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}"/>
                        <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                    </xsl:apply-templates>
                </dl>
            </xsl:document>
        </xsl:variable>

        <xsl:if test="$definitions/*/*">
            <div class="well well-small">
                <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
            </div>
        </xsl:if>
    </xsl:template>
    
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

            <a href="{if (not(starts-with($href, $ac:contextUri))) then ac:build-uri((), map{ 'uri': string($href), 'mode': string(@rdf:about) }) else if (contains($ac:uri, '?')) then concat($ac:uri, '&amp;mode=', encode-for-uri(@rdf:about)) else ac:build-uri($ac:uri, map{ 'mode': string(@rdf:about) })}" title="{@rdf:about}">
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

    <xsl:template match="*[@rdf:nodeID = 'notifications']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-notifications')"/>
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
                        <xsl:variable name="accept-href" select="ac:build-uri($ac:uri, map{ 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                        <xsl:choose>
                            <xsl:when test="starts-with($ac:uri, $ldt:base)">
                                <xsl:sequence select="$accept-href"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="ac:build-uri($ac:uri, map{ 'uri': encode-for-uri($accept-href) })"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a href="{$href}" title="application/rdf+xml">RDF/XML</a>
                </li>
                <li>
                    <xsl:variable name="href" as="xs:anyURI">
                        <xsl:variable name="accept-href" select="ac:build-uri($ac:uri, map{ 'accept': 'text/turtle' })" as="xs:anyURI"/>
                        <xsl:choose>
                            <xsl:when test="starts-with($ac:uri, $ldt:base)">
                                <xsl:sequence select="$accept-href"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="ac:build-uri($ac:uri, map{ 'uri': encode-for-uri($accept-href) })"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a href="{$href}" title="text/turtle">Turtle</a>
                </li>
                <xsl:if test="key('resources', $ac:uri)">
                    <li class="divider"></li>
                    
                    <xsl:variable name="href" select="ac:build-uri($ac:uri, map{ 'debug': 'http://www.w3.org/ns/sparql-service-description#SPARQL11Query' })" as="xs:anyURI"/>
                    <li>
                        <a href="{$href}" title="application/sparql-query">SPARQL query</a>
                    </li>
                </xsl:if>
            </ul>
        </div>
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
                
                <a href="{if (not(starts-with(lacl:requestAccess/@rdf:resource, $ldt:base))) then ac:build-uri($ldt:base, map{ 'uri': string(lacl:requestAccess/@rdf:resource), 'access-to': string($ac:uri) }) else concat(lacl:requestAccess/@rdf:resource, '&amp;access-to=', encode-for-uri($ac:uri))}" class="btn btn-primary pull-right">Request access</a>
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
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </h2>
        </div>
    </xsl:template>

    <!-- FORM -->

    <xsl:template match="rdf:RDF[$ac:forClass]" mode="bs2:Form" priority="2">
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="action" select="ac:build-uri($a:graphStore, let $params := map{ 'forClass': string($ac:forClass) } return if ($modal) then map:merge($params, map{ 'mode': '&ac;ModalMode' }) else $params)" as="xs:anyURI"/>

        <xsl:next-match> <!-- TO-DO: account for external $ac:uri -->
            <xsl:with-param name="action" select="$action"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- override form action in Client template -->
    <xsl:template match="rdf:RDF[$ac:mode = '&ac;EditMode']" mode="bs2:Form" priority="2">
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="action" select="if (not(starts-with($ac:uri, $ac:contextUri))) then ac:build-uri(lapp:base($ac:contextUri, $lapp:Application), map{ 'uri': string($ac:uri), '_method': 'PUT', 'mode': for $mode in $ac:mode return string($mode) }) else if (contains($ac:uri, '?')) then xs:anyURI(concat($ac:uri, '&amp;_method=PUT', string-join(for $mode in $ac:mode return concat('&amp;mode=', encode-for-uri($mode)), ''))) else ac:build-uri($ac:uri, map{ '_method': 'PUT', 'mode': for $mode in $ac:mode return string($mode) })" as="xs:anyURI"/>

        <xsl:next-match>
            <xsl:with-param name="action" select="$action" as="xs:anyURI"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:Form" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>
        <!-- append client mode parameter (which does not reach the server and therefore is not part of the hypermedia state arguments -->
        <!-- TO-DO: make action a tunnel param? -->
        <xsl:param name="action" select="xs:anyURI(if (not(starts-with($ac:uri, $ac:contextUri))) then ac:build-uri(lapp:base($ac:contextUri, $lapp:Application), map { 'uri': string($ac:uri), 'mode': if ($modal) then '&ac;ModalMode' else () }) else if ($modal) then if (contains($ac:uri, '?')) then concat($ac:uri, '&amp;mode=', encode-for-uri('&ac;ModalMode')) else ac:build-uri($ac:uri, map{ 'mode': '&ac;ModalMode' }) else $ac:uri)" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?">
            <xsl:for-each select="apl:listSuperTemplates($ldt:template)/../../aplt:consumes[1]">
                <xsl:sequence select="key('resources', (@rdf:nodeID, @rdf:resource))/aplt:mediaType"/>
            </xsl:for-each>
        </xsl:param>

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
                            
                            <xsl:apply-templates select="." mode="bs2:Create"/>
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

    <!-- hide constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation'] | *[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Form" priority="2"/>

    <!-- TO-DO: move to resource.xsl? -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/*" mode="bs2:TypeControl" priority="1"/>
    
    <!-- hide property dropdown -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/*" mode="bs2:PropertyControl" priority="1"/>

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="legend" select="false()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- hide Content's rdf:first property -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/rdf:first" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"/>
        
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- hide Content's rdf:rest property and object -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/rdf:rest" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- TARGET CONTAINER -->
    
    <xsl:template match="rdf:RDF" mode="bs2:TargetContainer">
        <fieldset class="action-container">
            <div class="control-group">
                <label class="control-label" for="input-container">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', '&dh;Container', document('&dh;'))" mode="ac:label"/>
                    </xsl:value-of>
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
            <xsl:value-of>
                <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document('&apl;'))" mode="ac:label"/>
            </xsl:value-of>
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
                        <xsl:value-of>
                            <xsl:apply-templates select="." mode="ac:label"/>
                        </xsl:value-of>
                    </legend>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <legend title="{$forClass}">
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo"/>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <xsl:when test="doc-available(ac:document-uri($forClass))">
                            <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="ac:label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$forClass"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </legend>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Legend"/>

    <!-- FORM CONTROL -->

    <!-- TO-DO: move to resource.xsl? -->
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

            <div class="btn-group pull-right">
                <button type="button" class="btn btn-large pull-right btn-remove-resource" title="Remove this resource">&#x2715;</button>
            </div>

            <xsl:if test="$legend">
                <legend>
                    <xsl:value-of select="ac:label(.)"/>
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
                <xsl:sort select="not(preceding-sibling::*[concat(namespace-uri(), local-name()) = current()/concat(namespace-uri(), local-name())]) and (if (../rdf:type/@rdf:resource and $ldt:ontology) then (key('resources', key('resources', (../rdf:type/@rdf:resource, ../rdf:type/@rdf:resource/apl:listSuperClasses(.)))/spin:constraint/(@rdf:resource|@rdf:nodeID))[rdf:type/@rdf:resource = '&apl;MissingPropertyValue'][sp:arg1/@rdf:resource = current()/concat(namespace-uri(), local-name())]) else true())" order="descending"/>
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
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="ac:label"/>
                        </xsl:value-of>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of>
                            <xsl:apply-templates select="." mode="ac:label"/>
                        </xsl:value-of>
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

            <xsl:if test="not($ac:mode = '&ac;EditMode')">
                <div class="pull-right">
                    <xsl:variable name="graph-uri" select="ac:build-uri($ac:uri, map{ 'mode': ('&ac;EditMode', '&ac;ModalMode') })" as="xs:anyURI"/>
                    <button title="{ac:label(key('resources', 'nav-bar-action-edit-graph-title', document('translations.rdf')))}">
                        <xsl:apply-templates select="key('resources', '&ac;EditMode', document('&ac;'))" mode="apl:logo">
                            <xsl:with-param name="class" select="'btn'"/>
                        </xsl:apply-templates>

                        <input type="hidden" value="{$graph-uri}"/>
                    </button>
                </div>
            </xsl:if>
            
            <div class="pull-right">
                <form action="{$ac:uri}?ban=true" method="post">
                    <!--<input type="hidden" name="ban" value="true"/>-->
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
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
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
                        <a href="https://linkeddatahub.com/linkeddatahub/docs/" target="_blank">Documentation</a>
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
            <xsl:value-of>
                <xsl:apply-templates select="." mode="ac:label"/>
            </xsl:value-of>
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
    <xsl:template match="*[$ldt:ontology][@rdf:about = $ac:uri][apl:listSuperClasses(rdf:type/@rdf:resource) = ('&dh;Container', '&dh;Item')]" mode="bs2:Block">
        <xsl:apply-templates select="key('resources', apl:content/@rdf:*)" mode="apl:ContentList"/>
        <xsl:apply-templates select="rdf:type/@rdf:resource/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource/key('resources', ., document(ac:document-uri(.)))" mode="apl:ContentList"/>
    </xsl:template>

    <!-- hide Content instances in bs2:Block mode as they will be rendered by apl:Content mode -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']" mode="bs2:Block" priority="2"/>

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

    <!-- suppress types in property list - we show them in the bs2:Header instead -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:PropertyList"/>
    
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

                <xsl:for-each select="apl:service/@rdf:resource">
                    <input type="hidden" name="service" value="{.}"/>
                </xsl:for-each>
                <input type="hidden" name="mode" value="&ac;QueryEditorMode"/>
                <input type="hidden" name="query" value="{sp:text}"/>

                <button type="submit" class="btn btn-primary">Open</button>
            </form>
        </div>
        
        <xsl:next-match/>
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
                                <a href="https://www.youtube.com/channel/UCtrdvnVjM99u9hrjESwfCeg" target="_blank">Screencasts</a>
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