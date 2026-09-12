<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ldht   "https://w3id.org/atomgraph/linkeddatahub/templates#">
    <!ENTITY ldhc   "https://w3id.org/atomgraph/linkeddatahub/config#">
    <!ENTITY google "https://w3id.org/atomgraph/linkeddatahub/services/google#">
    <!ENTITY orcid  "https://w3id.org/atomgraph/linkeddatahub/services/orcid#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xhv    "http://www.w3.org/1999/xhtml/vocab#">
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
    <!ENTITY c      "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY ct     "https://www.w3.org/ns/ldt/core/templates#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY spl    "http://spinrdf.org/spl#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY schema "https://schema.org/">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:lapp="&lapp;"
xmlns:lacl="&lacl;"
xmlns:ldh="&ldh;"
xmlns:ldhc="&ldhc;"
xmlns:ldht="&ldht;"
xmlns:rdf="&rdf;"
xmlns:xhv="&xhv;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:cert="&cert;"
xmlns:sd="&sd;"
xmlns:sh="&sh;"
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
xmlns:srx="&srx;"
xmlns:google="&google;"
xmlns:orcid="&orcid;"
xmlns:schema="&schema;"
exclude-result-prefixes="#all">

    <!-- the import tree, not this list, is the precedence order: Web-Client's internal-layout (its
         common layer + page layout) below LinkedDataHub's shared layer (common.xsl) - see §3.10.3 -->
    <xsl:import href="../../client/xsl/converters/RDFXML2JSON-LD.xsl"/>
    <xsl:import href="../../client/xsl/internal-layout.xsl"/>
    <xsl:import href="common.xsl"/>
    <xsl:import href="server.xsl"/> <!-- the server-side bindings of the product-dualed functions (client/functions.xsl mirrors them) -->


    <!-- signup page overrides, shared with the client (client.xsl includes it too); the browser-only submit handling inside is use-when-guarded to SaxonJS -->
    <xsl:include href="admin/signup.xsl"/>

    <!--  To use xsl:import-schema, you need the schema-aware version of Saxon -->
    <!-- <xsl:import-schema namespace="http://www.w3.org/1999/xhtml" schema-location="http://www.w3.org/2002/08/xhtml/xhtml1-transitional.xsd"/> -->

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="application/xhtml+xml"/>

    <xsl:param name="lapp:origin" as="xs:anyURI?"/>
    <xsl:param name="ldh:requestUri" as="xs:anyURI"/>
    <xsl:param name="ac:uri" as="xs:anyURI?"/>
    <xsl:param name="lapp:Context" as="document-node()"/>
    <xsl:param name="ldh:httpHeaders" select="map{}" as="map(xs:string, xs:string*)"/>
    <xsl:param name="ldh:ajaxRendering" select="true()" as="xs:boolean"/>
    <xsl:param name="ldhc:enableWebIDSignUp" as="xs:boolean"/>
    <xsl:param name="ldh:renderSystemResources" select="false()" as="xs:boolean"/>
    <xsl:param name="google:clientID" as="xs:string?"/>
    <xsl:param name="orcid:clientID" as="xs:string?"/>
    <!-- the ontologies the client resolves through the proxy rather than over the network; every one
         is fetched by the same recipe, so the list is data and the entry is written once -->
    <!-- the application this origin resolves to, as described in the system context -->
    <xsl:function name="lapp:application-description" as="element()*">
        <xsl:sequence select="key('apps-by-origin', lapp:origin(), $lapp:Context)"/>
    </xsl:function>

    <xsl:param name="ontology-namespaces" as="xs:anyURI*" select="(
        xs:anyURI('&ac;'), xs:anyURI('&adm;'), xs:anyURI('&lacl;'),
        xs:anyURI('&lapp;'), xs:anyURI('&ldh;'), xs:anyURI('&def;'),
        xs:anyURI('&dh;'), xs:anyURI('&sp;'), xs:anyURI('&spin;'),
        xs:anyURI('&rdf;'), xs:anyURI('&rdfs;'), xs:anyURI('&owl;'),
        xs:anyURI('&acl;'), xs:anyURI('&sd;'), xs:anyURI('&sh;'),
        xs:anyURI('&nfo;'), xs:anyURI('http://www.semanticdesktop.org/ontologies/2007/01/19/nie#'), xs:anyURI('&http;'),
        xs:anyURI('&sc;'), xs:anyURI('&ldt;'), xs:anyURI('&c;'),
        xs:anyURI('&sioc;'), xs:anyURI('&void;'), xs:anyURI('&foaf;'),
        xs:anyURI('&spl;'), xs:anyURI('&cert;'), xs:anyURI('http://www.w3.org/ns/prov#'),
        xs:anyURI('&geo;'), xs:anyURI('http://www.w3.org/2004/02/skos/core#'), xs:anyURI('http://www.w3.org/2006/time#'),
        xs:anyURI('http://purl.org/dc/elements/1.1/'), xs:anyURI('&dct;'), xs:anyURI('http://purl.org/dc/dcmitype/'),
        xs:anyURI('http://purl.org/goodrelations/v1#'), xs:anyURI('http://usefulinc.com/ns/doap#')
    )"/>

    <xsl:param name="location-mapping" as="map(xs:anyURI, xs:anyURI)">
        <xsl:map>
            <xsl:if test="lapp:origin()">
                <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', lapp:origin())" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', lapp:origin())"/>
                <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/http-statusCodes.rdf', lapp:origin())" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/http-statusCodes.rdf', lapp:origin())"/>
                <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/admin/countries.rdf', lapp:origin())" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/admin/countries.rdf', lapp:origin())"/>                
            </xsl:if>

            <xsl:for-each select="$ontology-namespaces">
                <xsl:map-entry key="ac:document-uri(.)" select="ac:build-uri(lapp:base(), map{ 'uri': string(ac:document-uri(.)), 'accept': 'application/rdf+xml' })"/>
            </xsl:for-each>
            <xsl:if test="$acl:agent">
                <xsl:map-entry key="ac:document-uri($acl:agent)" select="ac:build-uri(lapp:base(), map{ 'uri': string(ac:document-uri($acl:agent)), 'accept': 'application/rdf+xml' })"/>
            </xsl:if>
        </xsl:map>
    </xsl:param>

    <!-- the query has to support services that do not belong to any app. Use type URIs because that is what triggers Varnish invalidation. -->
    <xsl:variable name="app-query" as="xs:string">
        <![CDATA[
            DESCRIBE ?app ?service
            WHERE
              { GRAPH ?graph
                  {   { ?app <https://w3id.org/atomgraph/linkeddatahub/apps#origin> ?origin
                      }
                    UNION
                      { ?service <http://www.w3.org/ns/sparql-service-description#endpoint> ?endpoint
                      }
                  }
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="app-request-uri" select="ac:build-uri(sd:endpoint(), map{ 'query': $app-query })" as="xs:anyURI"/>
    <!-- graph-free variant of object-metadata-query for the /ns ontology endpoint: its dataset is the in-memory OntModel served as the default graph (no named graphs), so a GRAPH ?graph pattern would match nothing -->
    <!-- server-side twin of client.xsl's $property-metadata-query, so ac:property-label resolves predicate labels from
         the application ontology on the initial render as it does client-side -->

    <xsl:key name="apps-by-origin" match="*" use="lapp:origin/@rdf:resource"/>

    <rdf:Description rdf:about="">
    </rdf:Description>
    
    <!-- TITLE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Title">
        <title>
            <xsl:for-each select="lapp:application-description()">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> - </xsl:text>
            </xsl:for-each>

            <xsl:apply-templates mode="#current"/>
        </title>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][not(key('resources', ac:absolute-path(ldh:base-uri(.))))]" mode="xhtml:Title" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="." mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = ac:absolute-path(ldh:base-uri(.))]" mode="xhtml:Title" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="." mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="xhtml:Title"/>
    
    <!-- META -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="xhtml:Meta">
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

        <meta name="og:url" content="{ac:absolute-path(ldh:base-uri(.))}"/>
        <meta name="twitter:url" content="{ac:absolute-path(ldh:base-uri(.))}"/>

        <xsl:for-each select="key('resources', ac:absolute-path(ldh:base-uri(.)))">
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

        <xsl:for-each select="lapp:application-description()">
            <meta property="og:site_name" content="{ac:label(.)}"/>
        </xsl:for-each>
    </xsl:template>

    <!-- the m3 skin selector on the root element (retro.css keys on it) is the product's shipped look, not an optional theme.

         lang is the language the page is composed in, taken from the Content-Language this response already carries rather
         than from the languages the reader accepts - asking for German does not make the page German, and
         reporting the request here is what put lang="de" on a page written entirely in English. Deriving it from the header
         rather than recomputing it is what makes the two agree structurally instead of by two computations staying in step.
         Falls back to en, never to the request: with nothing to go on, the honest answer is the language the chrome ships in -->
    <xsl:template match="/">
        <html lang="{($ldh:httpHeaders('Content-Language')[1], 'en')[1]}" data-retro="m3" data-theme="light">
            <xsl:apply-templates/>
        </html>
    </xsl:template>

    <!-- STYLE -->

    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="ac:Stylesheets">
        <xsl:param name="load-rdfa-editor" select="exists($foaf:Agent//@rdf:about)" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="true()" as="xs:boolean"/>

        <xsl:if test="$load-rdfa-editor">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/rdfa-editor.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        </xsl:if>
        <xsl:if test="$load-yasqe">
            <link href="{resolve-uri('static/css/yasqe.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        </xsl:if>
        <!-- design system: fonts (vendored), tokens, components (app.css imports core.css, which imports controls.css and overlays.css), m3 skin -->
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/fonts.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/colors_and_type.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/app.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/retro.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <!-- LDH's app layer over the design kits: CSR state-token styling, LDH-only components, documented divergences - loaded last so it wins the ties it is written to win -->
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/ldh.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
    </xsl:template>

    <!-- SCRIPT -->

    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="xhtml:Script">
        <xsl:param name="client-stylesheet" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json', lapp:origin())" as="xs:anyURI"/>
        <xsl:param name="saxon-js-log-level" select="10" as="xs:integer"/>
        <xsl:param name="load-yasqe" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-saxon-js" select="$ldh:ajaxRendering and not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-builder" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-map" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-google-charts" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-graph3d" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="output-schema-org" select="true()" as="xs:boolean"/>
        <xsl:param name="location-mapping" select="$location-mapping" as="map(xs:anyURI, xs:anyURI)"/>

        <!-- LinkedDataHub scripts -->
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/functions.js', lapp:origin())}" defer="defer"></script>
        <script type="text/javascript">
            <xsl:text disable-output-escaping="yes">
              //&lt;![CDATA[
            </xsl:text>
            <![CDATA[
                var contextUri = ]]><xsl:value-of select="if (lapp:origin()) then '&quot;' || lapp:origin() || '&quot;'  else 'null'" disable-output-escaping="yes"/><![CDATA[;
                var agentUri = []]><xsl:value-of select="if ($acl:agent) then '&quot;' || $acl:agent || '&quot;'  else 'null'" disable-output-escaping="yes"/><![CDATA[];
            ]]>
            <xsl:text disable-output-escaping="yes">
              //]]&gt;
            </xsl:text>
        </script>
        <xsl:if test="$load-yasqe">
            <script src="{resolve-uri('static/js/yasqe.js', lapp:origin())}" type="text/javascript"></script>
        </xsl:if>
        <xsl:if test="$load-graph3d">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/three.min.js', lapp:origin())}"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/three-spritetext.min.js', lapp:origin())}"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/3d-force-graph.min.js', lapp:origin())}"></script>
        </xsl:if>
        <xsl:if test="$load-saxon-js">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/resource-resolver.js', lapp:origin())}"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/saxon-js/SaxonJS3.rt.js', lapp:origin())}" defer="defer"></script>
            <script type="text/javascript">
                <xsl:text disable-output-escaping="yes">
                  //&lt;![CDATA[
                </xsl:text>
                <xsl:text disable-output-escaping="yes"><![CDATA[
                    window.onload = function() {
                        const locationMapping = [
                            ]]></xsl:text>
                            <xsl:for-each select="map:keys($location-mapping)">
                                <xsl:text>{ name: "</xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text>", altName: "</xsl:text>
                                <xsl:value-of select="map:get($location-mapping, .)" disable-output-escaping="yes"/>
                                <xsl:text>" }</xsl:text>
                                <xsl:if test="position() != last()">
                                    <xsl:text>,&#xa;</xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text disable-output-escaping="yes">
                            <![CDATA[
                        ];
                        
                        const docPromises = locationMapping.map(mapping => 
                            getResourceWithRetry(mapping.altName).then(content => 
                                SaxonJS.getResource({text: content, type: "xml"})
                            )
                        );
                        const stylesheetParams = {
                            "Q{https://w3id.org/atomgraph/client#}contextUri": contextUri, // servlet context URI
                            "Q{http://www.w3.org/ns/auth/acl#}agent": agentUri
                            };
                        
                        SaxonJS.setConfigurationProperty("nativeGetElementById", true);
                        Promise.all(docPromises).
                            then(resources => {
                                const cache = {};
                                for (var i = 0; i < resources.length; i++) {
                                    cache[locationMapping[i].name] = resources[i]
                                };
                                return SaxonJS.transform({
                                    documentPool: cache,
                                    stylesheetLocation: "]]></xsl:text><xsl:value-of select="$client-stylesheet"/><xsl:text disable-output-escaping="yes"><![CDATA[",
                                    initialTemplate: "main",
                                    logLevel: ]]></xsl:text><xsl:value-of select="$saxon-js-log-level"/><xsl:text disable-output-escaping="yes"><![CDATA[,
                                    stylesheetParams: stylesheetParams
                                }, "async");
                            }).
                            catch(err => console.log("Transformation failed: " + err));
                    }
                ]]></xsl:text>
                <xsl:text disable-output-escaping="yes">
                  //]]&gt;
                </xsl:text>
            </script>
        </xsl:if>
        <xsl:if test="$load-sparql-builder">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQLBuilder.js', lapp:origin())}" defer="defer"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQL.js', lapp:origin())}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-sparql-map">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/ol.css', lapp:origin())}" rel="stylesheet" type="text/css"></link>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/ol.js', lapp:origin())}"></script>
        </xsl:if>
        <xsl:if test="$load-google-charts">
            <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
            <script type="text/javascript">
                <![CDATA[
                    google.charts.load('current', {packages: ['corechart', 'table', 'timeline', 'map']});
                ]]>
            </script>
        </xsl:if>
        <xsl:if test="$output-schema-org">
            <xsl:variable name="rdf" as="element()?">
                <xsl:apply-templates select="." mode="schema:BreadcrumbList"/>
            </xsl:variable>
            <xsl:if test="exists($rdf)">
                <!-- output structured data: https://developers.google.com/search/docs/guides/intro-structured-data -->
                <script type="application/ld+json">
                    <xsl:variable name="json-xml" as="element()">
                        <xsl:apply-templates select="$rdf" mode="ac:JSON-LD"/>
                    </xsl:variable>
                    <xsl:sequence select="xml-to-json($json-xml)"/>
                </script>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- HEADER -->
    
    <!-- design system Header: wordmark | address bar | actions. The CSR link interception and the
         address-bar handler anchor on .ldh-header / .ldh-address, the design system's own names -->
    <xsl:template match="rdf:RDF[$lapp:origin] | srx:sparql[$lapp:origin]" mode="ac:Header" priority="1">
        <div class="ldh-header" role="banner">
            <xsl:apply-templates select="." mode="ldh:Brand"/>

            <!-- the address form browses server-side (?uri= through the Linked Data proxy), so it renders
                 with or without CSR - which also keeps the 220px/1fr/auto header grid real, not propped -->
            <xsl:apply-templates select="." mode="ldh:AddressBar"/>

            <div class="ldh-header-actions">
                <xsl:apply-templates select="." mode="ldh:HeaderActions"/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="ac:Header"/>

    <xsl:template match="rdf:RDF[lapp:application-description()] | srx:sparql[lapp:application-description()]" mode="ldh:Brand" priority="1">
        <a class="ldh-wordmark" href="{lapp:base()}">
            <xsl:for-each select="lapp:application-description()">
                <xsl:if test="rdf:type/@rdf:resource = '&lapp;AdminApplication'">
                    <xsl:attribute name="class" select="'ldh-wordmark admin'"/>
                </xsl:if>

                <span class="mark"></span>
                <span>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </span>
            </xsl:for-each>
        </a>
    </xsl:template>

    <xsl:template match="*" mode="ldh:Brand"/>

    <!-- check if agent has access to the user endpoint by executing a dummy query ASK {} -->
    <xsl:template match="rdf:RDF[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', lapp:base()))] | srx:sparql[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', lapp:base()))]" mode="ldh:AddressBar" priority="1">
        <form action="{ac:absolute-path(ldh:request-uri())}" method="get" class="ldh-address" accept-charset="UTF-8" role="search" aria-label="{ac:label(key('resources', 'address-bar-title', document('translations.rdf')))}" title="{ac:label(key('resources', 'address-bar-title', document('translations.rdf')))}">
            <span class="msi outline" aria-hidden="true">public</span>
            <input type="url" id="uri" name="uri" value="{ac:absolute-path(ldh:request-uri())}" spellcheck="false" autocomplete="off" aria-label="{ac:label(key('resources', 'address-bar-title', document('translations.rdf')))}"/>
        </form>
    </xsl:template>

    <xsl:template match="*" mode="ldh:AddressBar"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="ldh:HeaderActions">
        <xsl:apply-templates select="." mode="ldh:DataspaceTabs"/>

        <xsl:apply-templates select="." mode="ldh:SignUp"/>
    </xsl:template>

    <!-- Admin app override: notification menu for pending AuthorizationRequests + account menu.
         Admin apps are identified by the 'admin.' subdomain prefix on lapp:origin() (nginx wildcard routing convention).
         TO-DO: refactor into component templates -->
    <xsl:template match="rdf:RDF[starts-with(replace(lapp:origin(), '^https?://', ''), 'admin.')]" mode="ldh:HeaderActions" priority="1">
        <xsl:if test="$foaf:Agent//@rdf:about">
                <xsl:variable name="notification-query" as="xs:string">
                    <![CDATA[
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  dct:  <http://purl.org/dc/terms/>
PREFIX  prov: <http://www.w3.org/ns/prov#>
PREFIX  foaf: <http://xmlns.com/foaf/0.1/>
PREFIX  sioc: <http://rdfs.org/sioc/ns#>

CONSTRUCT
{
    ?authRequest a $type .
    ?authRequest rdfs:label ?label .
    ?authRequest dct:created ?created .
}
WHERE
{ GRAPH ?authRequestGraph
  { ?authRequest  a                 $type ;
              rdfs:label            ?label .
    ?authRequestItem
              foaf:primaryTopic  ?authRequest ;
              sioc:has_container    $container
    FILTER NOT EXISTS { GRAPH ?authGraph
                          { ?auth  prov:wasDerivedFrom  ?authRequest }
                      }
    OPTIONAL
      { ?authRequest  dct:created  ?created }
  }
}
                    ]]>
                </xsl:variable>
                <xsl:variable name="notification-query" select="replace($notification-query, '$type', '&lt;&lacl;AuthorizationRequest&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="notification-query" select="replace($notification-query, '$container', '&lt;' || resolve-uri('acl/authorization-requests/', lapp:base()) || '&gt;', 'q')" as="xs:string"/>

                <xsl:if test="doc-available(ac:build-uri(resolve-uri('sparql', lapp:base()), map{ 'query': $notification-query }))">
                    <xsl:variable name="notifications" select="document(ac:build-uri(resolve-uri('sparql', lapp:base()), map{ 'query': $notification-query }))" as="document-node()"/>

                    <xsl:if test="$notifications/rdf:RDF/*[@rdf:about]">
                            <div class="ac-menu-anchor">
                                <!-- the button doubles as the badge anchor (ac-badge-wrap): the generic menu handler needs drop-toggle as a direct child of the ac-menu-anchor, so a wrapping span is not an option -->
                                <button class="drop-toggle ac-iconbtn sz-lg in-neutral ap-ghost ac-badge-wrap" aria-haspopup="menu" aria-expanded="false" title="{ac:label(key('resources', 'notifications', document('translations.rdf')))}">
                                    <span class="msi outline sm" aria-hidden="true">notifications</span>
                                    <span class="ac-badge sz-md pl-top-right is-dot" style="border-color: transparent">
                                        <span class="ac-vh">
                                            <xsl:value-of select="ac:label(key('resources', 'notifications', document('translations.rdf')))"/>
                                        </span>
                                    </span>
                                </button>
                                <div class="ac-menu al-end" role="menu">
                                    <xsl:for-each select="$notifications/rdf:RDF/*[@rdf:about]">
                                        <xsl:sort select="dct:created[1]/xs:dateTime(.)" order="descending"/>

                                        <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor">
                                            <xsl:with-param name="class" select="'ac-menu-item'"/>
                                            <xsl:with-param name="role" select="'menuitem'"/>
                                        </xsl:apply-templates>
                                    </xsl:for-each>
                                </div>
                            </div>
                    </xsl:if>
                </xsl:if>

                <xsl:apply-templates select="." mode="ldh:AccountMenu"/>
        </xsl:if>

        <xsl:apply-templates select="." mode="ldh:SignUp"/>
    </xsl:template>

    <xsl:template match="rdf:RDF[lapp:origin()][lapp:application-description()/rdf:type/@rdf:resource = '&lapp;EndUserApplication'] | srx:sparql[lapp:origin()][lapp:application-description()/rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="ldh:DataspaceTabs" priority="1">
            <xsl:variable name="user-defined-apps" select="if (doc-available($app-request-uri)) then document($app-request-uri)//*[lapp:origin/@rdf:resource] else ()" as="element()*"/>
            <xsl:variable name="system-apps" select="$lapp:Context//*[rdf:type/@rdf:resource = '&lapp;EndUserApplication'][lapp:origin/@rdf:resource]" as="element()*"/>

            <!-- .ldh-header-actions IS the flex cluster (AppShell): controls are its direct children,
                 no intermediate list -->
            <xsl:if test="exists($user-defined-apps) or exists($system-apps)">
                    <div class="ac-menu-anchor">
                        <button class="drop-toggle ac-iconbtn sz-lg in-neutral ap-ghost btn-apps" aria-haspopup="menu" aria-expanded="false" title="{ac:label(key('resources', 'application-list-title', document('translations.rdf')))}">
                            <span class="msi sm" aria-hidden="true">apps</span>
                        </button>
                        <div class="ac-menu al-end" role="menu">
                            <xsl:if test="exists($user-defined-apps)">
                                <div class="ac-menu-header" role="presentation">
                                    <xsl:value-of select="ac:label(key('resources', 'user-defined-apps', document('translations.rdf')))"/>
                                </div>
                                <xsl:for-each select="$user-defined-apps">
                                    <xsl:sort select="ac:label(.)" order="ascending" lang="{ac:langs()[1]}"/>
                                    <a class="ac-menu-item" role="menuitem" href="{lapp:origin/@rdf:resource}/" title="{lapp:origin/@rdf:resource}">
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </a>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:if test="exists($system-apps)">
                                <xsl:if test="exists($user-defined-apps)">
                                    <div class="ac-menu-sep" role="separator" aria-orientation="horizontal"/>
                                </xsl:if>
                                <div class="ac-menu-header" role="presentation">
                                    <xsl:value-of select="ac:label(key('resources', 'system-apps', document('translations.rdf')))"/>
                                </div>
                                <xsl:for-each select="$system-apps">
                                    <xsl:sort select="ac:label(.)" order="ascending" lang="{ac:langs()[1]}"/>
                                    <a class="ac-menu-item" role="menuitem" href="{lapp:origin/@rdf:resource}/" title="{lapp:origin/@rdf:resource}">
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </a>
                                </xsl:for-each>
                            </xsl:if>
                        </div>
                    </div>
            </xsl:if>
            
            <xsl:if test="$foaf:Agent//*[@rdf:about]">
                <xsl:apply-templates select="." mode="ldh:Settings"/>
                <!-- overridden in acl/layout.xsl! -->
                <xsl:apply-templates select="." mode="ldh:AccountMenu"/>
            </xsl:if>
    </xsl:template>

    <xsl:template match="*" mode="ldh:DataspaceTabs"/>

    <!-- account menu shared by the admin and end-user header actions -->
    <xsl:template match="rdf:RDF | srx:sparql" mode="ldh:AccountMenu">
            <!-- .ldh-avatar-wrap is the design's avatar anchor; .ac-menu-anchor keeps the CSR menu handler and its is-open state -->
            <div class="ac-menu-anchor ldh-avatar-wrap">
                <xsl:variable name="agent-label" select="ac:label($foaf:Agent//*[@rdf:about][1])" as="xs:string?"/>
                <button type="button" class="drop-toggle ldh-avatar" aria-haspopup="menu" aria-expanded="false" title="{$agent-label}">
                    <xsl:value-of select="string-join(for $word in tokenize(normalize-space($agent-label), ' ')[position() le 2] return upper-case(substring($word, 1, 1)))"/>
                </button>
                <div class="ac-menu al-end" role="menu">
                    <xsl:for-each select="key('resources-by-type', '&foaf;Agent', $foaf:Agent)">
                        <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor">
                            <xsl:with-param name="class" select="'ac-menu-item'"/>
                            <xsl:with-param name="role" select="'menuitem'"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </div>
            </div>
    </xsl:template>

    <!-- SIGNUP -->
    
    <xsl:template match="rdf:RDF[lapp:origin()][not($foaf:Agent//@rdf:about)][lapp:application-description()/rdf:type/@rdf:resource = '&lapp;EndUserApplication'] | srx:sparql[lapp:origin()][not($foaf:Agent//@rdf:about)][lapp:application-description()/rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="ldh:SignUp" priority="1">
        <!-- resolve links against the origin URI of the admin app -->
        <xsl:param name="google-signup" select="exists($google:clientID)" as="xs:boolean"/>
        <xsl:param name="orcid-signup" select="exists($orcid:clientID)" as="xs:boolean"/>
        <xsl:param name="webid-signup" select="$ldhc:enableWebIDSignUp" as="xs:boolean"/>
        <xsl:param name="admin-origin" select="xs:anyURI(replace(string($ac:contextUri), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:param name="webid-signup-uri" select="ac:build-uri(resolve-uri('sign%20up', $admin-origin), map{ 'referer': string(ac:absolute-path(ldh:request-uri())) })" as="xs:anyURI"/>

        <!-- OAuth providers menu -->
        <xsl:if test="$google-signup or $orcid-signup">
            <div class="ac-menu-anchor">
                <button type="button" class="drop-toggle ac-btn in-primary ap-solid sz-md" aria-haspopup="menu" aria-expanded="false">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'login', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                    <xsl:text> </xsl:text>
                    <span class="msi caret" aria-hidden="true">expand_more</span>
                </button>
                <div class="ac-menu al-end" role="menu">
                    <xsl:if test="$google-signup">
                        <xsl:variable name="google-signup-uri" select="ac:build-uri(resolve-uri('oauth2/authorize/google', $ac:contextUri), map{ 'referer': string(ac:absolute-path(ldh:request-uri())) })" as="xs:anyURI"/>
                        <a class="ac-menu-item" role="menuitem" href="{$google-signup-uri}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'login-google', document('translations.rdf'))" mode="ac:label"/>
                            </xsl:value-of>
                        </a>
                    </xsl:if>
                    <xsl:if test="$orcid-signup">
                        <xsl:variable name="orcid-signup-uri" select="ac:build-uri(resolve-uri('oauth2/authorize/orcid', $ac:contextUri), map{ 'referer': string(ac:absolute-path(ldh:request-uri())) })" as="xs:anyURI"/>
                        <a class="ac-menu-item" role="menuitem" href="{$orcid-signup-uri}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'login-orcid', document('translations.rdf'))" mode="ac:label"/>
                            </xsl:value-of>
                        </a>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
        <!-- WebID signup - separate button -->
        <xsl:if test="$webid-signup">
            <div>
                <a class="ac-btn in-primary ap-solid sz-md" href="{if (not(starts-with(lapp:base(), lapp:origin()))) then ac:build-uri((), map{ 'uri': string($webid-signup-uri) }) else $webid-signup-uri}">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'sign-up', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </a>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="ldh:SignUp"/>
    
    <!-- BODY -->

    <xsl:template match="rdf:RDF[$lapp:origin] | srx:sparql[$lapp:origin]" mode="ac:AppShell" priority="1">
        <body>
            <div id="visible-body">
                <xsl:apply-templates select="." mode="ac:Header"/>

                <div id="tab-body" role="main">
                    <!-- tab bar — sticky, hidden until first external tab is opened.
                         DataspaceTabs anatomy (§17b): ul.ldh-tabs > li.is-active > a.ldh-tab[href] + button.tab-close -->
                    <div id="tab-bar" role="navigation" aria-label="{ac:label(key('resources', 'dataspaces', document('translations.rdf')))}">
                        <ul class="ldh-tabs" id="tab-bar-list">
                            <!-- the same shape ldh:AddDataspaceTab appends client-side: state on the li, aria-current on the anchor, close as its sibling -->
                            <li class="is-active" data-uri="{ac:absolute-path(ldh:base-uri(.))}">
                                <a class="ldh-tab" aria-current="page" href="{ldh:href(ac:absolute-path(ldh:base-uri(.)), ldh:build-query(ac:mode(root())))}">
                                    <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="ac:label"/>
                                </a>
                                <button type="button" class="tab-close" aria-label="{ac:label(key('resources', 'close', document('translations.rdf')))}"><span class="msi">close</span></button>
                            </li>
                        </ul>
                    </div>

                    <!-- document content panes (.ldh-panes/.ldh-pane classes -->
                    <div id="tab-content" class="ldh-panes">
                        <xsl:variable name="object-uris" select="rdf:Description/*/@rdf:resource[not(key('resources', .))]" as="xs:anyURI*"/>
                        <xsl:variable name="object-metadata" as="document-node()?">
                            <xsl:if test="exists($object-uris)">
                                <xsl:variable name="values" select="' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                                <!-- instance labels from /sparql merged with ontology-term (rdf:type/class) labels from /ns, so ac:object-label resolves both on the initial server render (matches the client-side merge) -->
                                <xsl:variable name="sparql-metadata" as="document-node()?">
                                    <xsl:try select="ldh:send-request(sd:endpoint(), 'POST', 'application/sparql-query', $object-metadata-query || $values, map{ 'Accept': 'application/rdf+xml' })">
                                        <xsl:catch/>
                                    </xsl:try>
                                </xsl:variable>
                                <xsl:variable name="ns-metadata" as="document-node()?">
                                    <xsl:try select="ldh:send-request(resolve-uri('ns', lapp:base()), 'POST', 'application/sparql-query', $object-metadata-ns-query || $values, map{ 'Accept': 'application/rdf+xml' })">
                                        <xsl:catch/>
                                    </xsl:try>
                                </xsl:variable>
                                <xsl:sequence select="ldh:merge-metadata($sparql-metadata, $ns-metadata)"/>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="property-uris" select="distinct-values(rdf:Description/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                        <!-- predicate labels from /ns, the counterpart of the object labels above and of the client's own
                             property-metadata fetch. Without it ac:property-label finds nothing in $property-metadata and
                             falls through to the published vocabulary, whose labels are English-only - so a reader whose
                             language the application ontology does translate still got English predicates -->
                        <xsl:variable name="property-metadata" as="document-node()?">
                            <xsl:if test="exists($property-uris)">
                                <xsl:variable name="values" select="' VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                                <xsl:try select="ldh:send-request(resolve-uri('ns', lapp:base()), 'POST', 'application/sparql-query', $property-metadata-query || $values, map{ 'Accept': 'application/rdf+xml' })">
                                    <xsl:catch/>
                                </xsl:try>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="local-pane" as="element()">
                            <xsl:apply-templates select="." mode="ldh:TabPanel">
                                <xsl:with-param name="mode" select="ac:mode(root())"/>
                                <xsl:with-param name="base" select="lapp:base()"/>
                                <xsl:with-param name="endpoint" select="sd:endpoint()"/>
                                <xsl:with-param name="acl-modes" select="acl:mode()"/>
                                <xsl:with-param name="about" select="ac:absolute-path(ldh:base-uri(.))"/>
                                <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:for-each select="$local-pane">
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:if test="ac:uri()">
                                    <xsl:attribute name="style" select="'display: none'"/>
                                </xsl:if>
                                <xsl:sequence select="node()"/>
                            </xsl:copy>
                        </xsl:for-each>
                    </div>
                </div>

                <xsl:apply-templates select="." mode="ac:Footer"/>
            </div>

        </body>
    </xsl:template>
    
    <!-- only lookup resource locally using DESCRIBE if it's external (not relative to the app's base URI) and the agent is authenticated -->
    <xsl:template match="*[*][@rdf:about = ac:absolute-path(ldh:base-uri(.))][not(starts-with(@rdf:about, lapp:base()))][$foaf:Agent//@rdf:about]" mode="ac:PropertyEditor">
        <xsl:param name="endpoint" select="sd:endpoint()" as="xs:anyURI"/>
        <xsl:param name="property-uris" select="distinct-values(*/concat(namespace-uri(), local-name()))" as="xs:anyURI*"/>
        <xsl:param name="property-metadata" select="ldh:send-request(resolve-uri('ns', lapp:base()), 'POST', 'application/sparql-query', 'DESCRIBE ' || string-join(for $uri in distinct-values(/rdf:RDF/*/*/concat(namespace-uri(), local-name())) return '&lt;' || $uri || '&gt;', ' '), map{ 'Accept': 'application/rdf+xml' })" as="document-node()"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:variable name="local-doc" select="ldh:query-result($endpoint, 'DESCRIBE &lt;' || @rdf:about || '&gt;')" as="document-node()"/>
        <xsl:variable name="original-doc" as="document-node()">
            <xsl:try>
                <!-- try loading resource by deferencing its URI -->
                <xsl:variable name="full-doc" select="document(ac:build-uri(lapp:base(), map{ 'uri': string(ac:document-uri(@rdf:about)), 'accept': 'application/rdf+xml' }))" as="document-node()"/>
                <xsl:document>
                    <rdf:RDF>
                        <xsl:copy-of select="key('resources', @rdf:about, $full-doc)"/>
                    </rdf:RDF>
                </xsl:document>

                <!-- fallback to the $local-doc -->
                <xsl:catch>
                    <xsl:sequence select="$local-doc"/>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>

        <xsl:variable name="triples-original" select="ldh:triples-map($original-doc, true())" as="map(xs:string, element())"/>
        <xsl:variable name="triples-local" select="ldh:triples-map($local-doc, true())" as="map(xs:string, element())"/>

        <xsl:variable name="properties-original" select="for $triple-key in ac:value-except(map:keys($triples-original), map:keys($triples-local)) return map:get($triples-original, $triple-key)" as="element()*"/>
        <xsl:if test="exists($properties-original)">
            <div>
                <h2 class="ldh-section-heading">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'from-origin', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>

                <xsl:variable name="definitions" as="document-node()">
                    <xsl:document>
                        <dl>
                            <xsl:apply-templates select="$properties-original" mode="#current">
                                <xsl:sort select="ac:property-label(., $property-metadata)" order="ascending" lang="{ac:langs()[1]}"/>
                                <xsl:sort select="ac:lang-rank(.)" order="ascending"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{ac:langs()[1]}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="ac:PropertyGroups"/>
            </div>
        </xsl:if>

        <xsl:variable name="properties-local" select="for $triple-key in ac:value-except(map:keys($triples-local), map:keys($triples-original)) return map:get($triples-local, $triple-key)" as="element()*"/>
        <xsl:if test="exists($properties-local)">
            <div>
                <h2 class="ldh-section-heading">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'local', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>
                
                <xsl:variable name="definitions" as="document-node()">
                    <xsl:document>
                        <dl>
                            <xsl:apply-templates select="$properties-local" mode="#current">
                                <xsl:sort select="ac:property-label(., $property-metadata)" order="ascending" lang="{ac:langs()[1]}"/>
                                <xsl:sort select="ac:lang-rank(.)" order="ascending"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{ac:langs()[1]}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="ac:PropertyGroups"/>
            </div>
        </xsl:if>
        
        <xsl:variable name="properties-common" select="for $triple-key in ac:value-intersect(map:keys($triples-original), map:keys($triples-local)) return map:get($triples-original, $triple-key)" as="element()*"/>
        <xsl:if test="exists($properties-common)">
            <div>
                <h2 class="ldh-section-heading">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'common', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>

                <xsl:variable name="definitions" as="document-node()">
                    <xsl:document>
                        <dl>
                            <xsl:apply-templates select="$properties-common" mode="#current">
                                <xsl:sort select="ac:property-label(., $property-metadata)" order="ascending" lang="{ac:langs()[1]}"/>
                                <xsl:sort select="ac:lang-rank(.)" order="ascending"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{ac:langs()[1]}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="ac:PropertyGroups"/>
            </div>
        </xsl:if>
    </xsl:template>
   
    <!-- ACCESS LIST ITEM -->
    
    <xsl:template match="*[@rdf:about]" mode="ldh:AccessListItem" priority="1">
        <xsl:param name="enabled" as="xs:anyURI*"/>
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>

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
    
    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="ldh:Settings" priority="1">
        <div class="ac-menu-anchor">
            <button type="button" class="drop-toggle ac-iconbtn sz-lg in-neutral ap-ghost" aria-haspopup="menu" aria-expanded="false" title="{ac:label(key('resources', 'nav-bar-action-settings-title', document('translations.rdf')))}">
                <span class="msi outline sm" aria-hidden="true">settings</span>
            </button>

            <div class="ac-menu al-end" role="menu">
                <xsl:if test="$foaf:Agent//@rdf:about and lapp:application-description()/rdf:type/@rdf:resource = '&lapp;EndUserApplication'">
                    <button type="button" class="ac-menu-item btn-app-settings" role="menuitem">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', '&lapp;Application', document(ac:document-uri('&lapp;')))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                    <a href="{replace(string(lapp:origin()), '^(https?://)', '$1admin.')}" class="ac-menu-item external" role="menuitem" target="_blank">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'administration', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                    <a class="ac-menu-item" role="menuitem" href="{resolve-uri('ns', lapp:base())}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'namespace-ontology', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
    <!-- FOOTER -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="ac:Footer">
        <div class="ldh-footer" role="contentinfo">
            <div class="cols">
                <div class="col brand-col">
                    <a class="ldh-wordmark" href="{lapp:base()}">
                        <span class="mark"></span>
                        <span>LinkedDataHub</span>
                    </a>
                    <p><xsl:value-of select="ac:label(key('resources', 'footer-tagline', document('translations.rdf')))"/></p>
                </div>
                <div class="col">
                    <p class="ftitle"><xsl:value-of select="ac:label(key('resources', 'about', document('translations.rdf')))"/></p>
                    <a href="https://linkeddatahub.com" target="_blank">LinkedDataHub</a>
                    <a href="https://atomgraph.com" target="_blank">AtomGraph</a>
                </div>
                <div class="col">
                    <p class="ftitle"><xsl:value-of select="ac:label(key('resources', 'resources', document('translations.rdf')))"/></p>
                    <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/" target="_blank"><xsl:value-of select="ac:label(key('resources', 'documentation', document('translations.rdf')))"/></a>
                    <a href="https://www.youtube.com/channel/UCtrdvnVjM99u9hrjESwfCeg" target="_blank"><xsl:value-of select="ac:label(key('resources', 'screencasts', document('translations.rdf')))"/></a>
                </div>
                <div class="col">
                    <p class="ftitle"><xsl:value-of select="ac:label(key('resources', 'support', document('translations.rdf')))"/></p>
                    <a href="https://groups.io/g/linkeddatahub" target="_blank"><xsl:value-of select="ac:label(key('resources', 'mailing-list', document('translations.rdf')))"/></a>
                    <a href="https://github.com/AtomGraph/LinkedDataHub/issues" target="_blank"><xsl:value-of select="ac:label(key('resources', 'report-issues', document('translations.rdf')))"/></a>
                    <a href="mailto:support@linkeddatahub.com"><xsl:value-of select="ac:label(key('resources', 'contact-support', document('translations.rdf')))"/></a>
                </div>
                <div class="col">
                    <p class="ftitle"><xsl:value-of select="ac:label(key('resources', 'follow-us', document('translations.rdf')))"/></p>
                    <a href="https://twitter.com/atomgraphhq" target="_blank">@atomgraphhq</a>
                    <a href="https://github.com/AtomGraph" target="_blank">github.com/AtomGraph</a>
                </div>
            </div>
            <div class="legal">
                <span>© <xsl:value-of select="format-date(current-date(), '[Y]')"/> AtomGraph · LinkedDataHub</span>
                <span><xsl:value-of select="lapp:base()"/></span>
            </div>
        </div>
    </xsl:template>

</xsl:stylesheet>