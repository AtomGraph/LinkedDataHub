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
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
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
xmlns:srx="&srx;"
xmlns:google="&google;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="imports/xml-to-string.xsl"/>
    <xsl:import href="../../../../client/xsl/converters/RDFXML2JSON-LD.xsl"/>
    <xsl:import href="../../../../client/xsl/bootstrap/2.3.2/internal-layout.xsl"/>
    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="imports/ac.xsl"/>
    <xsl:import href="imports/ldh.xsl"/>
    <xsl:import href="imports/dct.xsl"/>
    <xsl:import href="imports/nfo.xsl"/>
    <xsl:import href="imports/rdf.xsl"/>
    <xsl:import href="imports/sioc.xsl"/>
    <xsl:import href="imports/sp.xsl"/>
    <xsl:import href="imports/void.xsl"/>
    <xsl:import href="resource.xsl"/>
    <xsl:import href="document.xsl"/>
    
    <!--  To use xsl:import-schema, you need the schema-aware version of Saxon -->
    <!-- <xsl:import-schema namespace="http://www.w3.org/1999/xhtml" schema-location="http://www.w3.org/2002/08/xhtml/xhtml1-transitional.xsd"/> -->
  
    <xsl:include href="signup.xsl"/>
    <xsl:include href="request-access.xsl"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="application/xhtml+xml"/>

    <xsl:param name="ldh:base" as="xs:anyURI" static="yes"/>
    <xsl:param name="ldh:absolutePath" as="xs:anyURI"/>
    <xsl:param name="ldh:requestUri" as="xs:anyURI"/>
    <xsl:param name="ac:endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
    <xsl:param name="a:graphStore" select="resolve-uri('service', $ldt:base)" as="xs:anyURI"/> <!-- TO-DO: rename to ac:graphStore? -->
    <xsl:param name="sd:endpoint" as="xs:anyURI?"/>
    <xsl:param name="lapp:Application" as="document-node()?"/>
    <xsl:param name="foaf:Agent" as="document-node()?"/>
    <xsl:param name="force-exclude-all-namespaces" select="true()"/>
    <xsl:param name="ac:httpHeaders" as="xs:string"/> 
    <xsl:param name="ac:method" as="xs:string"/>
    <xsl:param name="ac:uri" as="xs:anyURI"/>
    <xsl:param name="ac:mode" as="xs:anyURI*"/> <!-- select="xs:anyURI('&ac;ReadMode')"  -->
    <xsl:param name="ac:googleMapsKey" select="'AIzaSyCQ4rt3EnNCmGTpBN0qoZM1Z_jXhUnrTpQ'" as="xs:string"/>
    <xsl:param name="acl:agent" as="xs:anyURI?"/>
    <xsl:param name="acl:mode" select="$foaf:Agent[doc-available($ldh:absolutePath)]//*[acl:accessToClass/@rdf:resource = (key('resources', $ldh:absolutePath, document($ldh:absolutePath))/rdf:type/@rdf:resource, key('resources', $ldh:absolutePath, document($ldh:absolutePath))/rdf:type/@rdf:resource/ldh:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>
    <xsl:param name="ldh:createGraph" select="false()" as="xs:boolean"/>
    <xsl:param name="ldh:localGraph" as="document-node()?"/>
    <xsl:param name="ldh:originalGraph" as="document-node()?"/>
    <xsl:param name="ldh:ajaxRendering" select="true()" as="xs:boolean"/> <!-- TO-DO: rename to ldhc:ajaxRendering? -->
    <xsl:param name="ldhc:enableWebIDSignUp" as="xs:boolean"/>
    <xsl:param name="google:clientID" as="xs:string?"/>
    <xsl:param name="default-classes" as="map(xs:string, xs:anyURI)">
        <xsl:map>
            <xsl:map-entry key="'&lapp;Application'" select="resolve-uri('apps/', $ldt:base)"/>
            <xsl:map-entry key="'&sd;Service'" select="resolve-uri('services/', $ldt:base)"/>
            <xsl:map-entry key="'&nfo;FileDataObject'" select="resolve-uri('files/', $ldt:base)"/>
            <xsl:map-entry key="'&sp;Construct'" select="resolve-uri('queries/', $ldt:base)"/>
            <xsl:map-entry key="'&sp;Describe'" select="resolve-uri('queries/', $ldt:base)"/>
            <xsl:map-entry key="'&sp;Select'" select="resolve-uri('queries/', $ldt:base)"/>
            <xsl:map-entry key="'&sp;Ask'" select="resolve-uri('queries/', $ldt:base)"/>
            <xsl:map-entry key="'&ldh;RDFImport'" select="resolve-uri('imports/', $ldt:base)"/>
            <xsl:map-entry key="'&ldh;CSVImport'" select="resolve-uri('imports/', $ldt:base)"/>
            <xsl:map-entry key="'&ldh;GraphChart'" select="resolve-uri('charts/', $ldt:base)"/>
            <xsl:map-entry key="'&ldh;ResultSetChart'" select="resolve-uri('charts/', $ldt:base)"/>
        </xsl:map>
    </xsl:param>

    <!-- the query has to support services that do not belong to any app -->
    <xsl:variable name="app-query" as="xs:string">
        DESCRIBE  ?resource
        WHERE
          { GRAPH ?graph
              {
                  { ?resource  &lt;&ldt;base&gt;     ?base }
                  UNION
                  { ?resource  &lt;&sd;endpoint&gt;  ?endpoint }
              }
          }
    </xsl:variable>
    <xsl:variable name="app-request-uri" select="ac:build-uri(resolve-uri('sparql', $ldt:base), map{ 'query': $app-query })" as="xs:anyURI"/>
    <xsl:variable name="template-query" as="xs:string">
        <![CDATA[
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>

            SELECT  *
            WHERE
              {
                ?Type  ldh:template  ?content
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="constraint-query" as="xs:string">
        <![CDATA[
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  sp:   <http://spinrdf.org/sp#>
            PREFIX  spin: <http://spinrdf.org/spin#>

            SELECT  ?property
            WHERE
              { ?Type (rdfs:subClassOf)*/spin:constraint  ?constraint .
                ?constraint  a             ldh:MissingPropertyValue ;
                          sp:arg1          ?property
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="constructor-query" as="xs:string">
        <![CDATA[
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  sp:   <http://spinrdf.org/sp#>
            PREFIX  spin: <http://spinrdf.org/spin#>

            SELECT  ?construct
            WHERE
              { ?Type (rdfs:subClassOf)*/spin:constructor  ?constructor .
                ?constructor sp:text ?construct .
              }
        ]]>
    </xsl:variable>
    <xsl:param name="explore-service-query" as="xs:string">
<![CDATA[SELECT DISTINCT  ?type (COUNT(?s) AS ?count) (SAMPLE(?s) AS ?sample)
WHERE
  {   { ?s  a  ?type }
    UNION
      { GRAPH ?g
          { ?s  a  ?type }
      }
  }
GROUP BY ?type
ORDER BY DESC(COUNT(?s))
LIMIT   100
]]></xsl:param>
    
    <xsl:key name="resources-by-primary-topic" match="*[@rdf:about] | *[@rdf:nodeID]" use="foaf:primaryTopic/@rdf:resource"/>
    <xsl:key name="violations-by-root" match="*" use="spin:violationRoot/@rdf:resource"/>
    <xsl:key name="violations-by-value" match="*" use="ldh:violationValue/text()"/>
    <xsl:key name="resources-by-container" match="*[@rdf:about] | *[@rdf:nodeID]" use="sioc:has_parent/@rdf:resource | sioc:has_container/@rdf:resource"/>
    
    <rdf:Description rdf:about="">
    </rdf:Description>

    <xsl:function name="ac:uri" as="xs:anyURI">
        <xsl:sequence select="$ac:uri"/>
    </xsl:function>
    
    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:sequence select="$ldh:requestUri"/>
    </xsl:function>
    
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

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][not(key('resources', ac:uri()))]" mode="xhtml:Title" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="." mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = ac:uri()]" mode="xhtml:Title" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="." mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="xhtml:Title"/>
    
    <!-- META -->
    
    <xsl:template match="rdf:RDF" mode="xhtml:Meta">
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

        <meta name="og:url" content="{ac:uri()}"/>
        <meta name="twitter:url" content="{ac:uri()}"/>

        <xsl:for-each select="key('resources', ac:uri())">
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
        <xsl:param name="load-wymeditor" select="exists($foaf:Agent//@rdf:about)" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="true()" as="xs:boolean"/>

        <xsl:apply-imports/>

        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/bootstrap.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        <xsl:if test="$load-wymeditor">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/skins/default/skin.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        </xsl:if>
        <xsl:if test="$load-yasqe">
            <link href="{resolve-uri('static/css/yasqe.css', $ac:contextUri)}" rel="stylesheet" type="text/css"/>
        </xsl:if>
    </xsl:template>

    <!-- SCRIPT -->

    <xsl:template match="rdf:RDF" mode="xhtml:Script">
        <xsl:param name="client-stylesheet" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json', $ac:contextUri)" as="xs:anyURI"/>
        <xsl:param name="saxon-js-log-level" select="10" as="xs:integer"/>
        <xsl:param name="load-wymeditor" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-saxon-js" select="$ldh:ajaxRendering and not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-builder" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-map" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-google-charts" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="output-json-ld" select="false()" as="xs:boolean"/>

        <!-- Web-Client scripts -->
        <script type="text/javascript" src="{resolve-uri('static/js/jquery.min.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/js/bootstrap.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/client/js/UUID.js', $ac:contextUri)}" defer="defer"></script>
        <!-- LinkedDataHub scripts -->
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/jquery.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript">
            <![CDATA[
                var baseUri = ]]><xsl:value-of select="'&quot;' || $ldt:base || '&quot;'"/><![CDATA[;
                var absolutePath = ]]><xsl:value-of select="'&quot;' || $ldh:absolutePath || '&quot;'"/><![CDATA[;
                var ontologyUri = ]]><xsl:value-of select="'&quot;' || $ldt:ontology || '&quot;'"/><![CDATA[;
                var endpointUri = ]]><xsl:value-of select="if ($sd:endpoint) then '&quot;' || $sd:endpoint || '&quot;'  else 'null'"/><![CDATA[;
                var contextUri = ]]><xsl:value-of select="if ($ac:contextUri) then '&quot;' || $ac:contextUri || '&quot;'  else 'null'"/><![CDATA[;
                var accessModeUri = []]><xsl:value-of select="string-join(for $mode in $acl:mode return '&quot;' || $mode || '&quot;', ', ')"/><![CDATA[];
            ]]>
        </script>
        <xsl:if test="$load-wymeditor">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/jquery.wymeditor.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-yasqe">
            <script src="{resolve-uri('static/js/yasqe.js', $ac:contextUri)}" type="text/javascript"></script>
        </xsl:if>
        <xsl:if test="$load-saxon-js">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/saxon-js/SaxonJS2.rt.js', $ac:contextUri)}" defer="defer"></script>
            <script type="text/javascript">
                <![CDATA[
                    window.onload = function() {
                        const locationMapping = [ 
                            // not using entities as we don't want the # in the end
                            { name: contextUri + "static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf", altName: contextUri + "static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf" },
                            { name: "https://w3id.org/atomgraph/client", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("https://w3id.org/atomgraph/client") + "&accept=" + encodeURIComponent("application/rdf+xml") },
                            { name: "https://w3id.org/atomgraph/linkeddatahub/admin", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("https://w3id.org/atomgraph/linkeddatahub/admin") + "&accept=" + encodeURIComponent("application/rdf+xml") },
                            { name: "https://w3id.org/atomgraph/linkeddatahub", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("https://w3id.org/atomgraph/linkeddatahub") + "&accept=" + encodeURIComponent("application/rdf+xml") },
                            { name: "https://w3id.org/atomgraph/linkeddatahub/default", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("https://w3id.org/atomgraph/linkeddatahub/default") + "&accept=" + encodeURIComponent("application/rdf+xml") },
                            { name: "https://www.w3.org/ns/ldt/document-hierarchy", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("https://www.w3.org/ns/ldt/document-hierarchy") + "&accept=" + encodeURIComponent("application/rdf+xml") },
                            { name: "http://spinrdf.org/sp", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("http://spinrdf.org/sp") + "&accept=" + encodeURIComponent("application/rdf+xml") },
                            { name: "http://www.w3.org/1999/02/22-rdf-syntax-ns", altName: "]]><xsl:value-of select="$ldt:base"/><![CDATA[" + "?uri=" + encodeURIComponent("http://www.w3.org/1999/02/22-rdf-syntax-ns") + "&accept=" + encodeURIComponent("application/rdf+xml") }
                            ]]>
                            <!--<xsl:variable name="ontology-imports" select="for $value in distinct-values(ldh:ontologyImports($ldt:ontology)) return xs:anyURI($value)" as="xs:anyURI*"/>
                            <xsl:if test="exists($ontology-imports)">
                                <xsl:text>,</xsl:text>
                                <xsl:for-each select="$ontology-imports">
                                    <xsl:text>{ name: "</xsl:text>
                                    <xsl:value-of select="ac:document-uri(.)"/>
                                    <xsl:text>", altName: baseUri + "?uri=" + encodeURIComponent("</xsl:text>
                                    <xsl:value-of select="ac:document-uri(.)"/>
                                    <xsl:text>") + "&amp;accept=" + encodeURIComponent("application/rdf+xml") }</xsl:text>
                                    <xsl:if test="position() != last()">
                                        <xsl:text>,&#xa;</xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:if> -->
                            <![CDATA[
                        ];
                        const docPromises = locationMapping.map(mapping => SaxonJS.getResource({location: mapping.altName, type: "xml"}));
                        const servicesRequestUri = "]]><xsl:value-of select="$app-request-uri"/><![CDATA[";
                        const stylesheetParams = {
                            "Q{https://w3id.org/atomgraph/client#}contextUri": contextUri, // servlet context URI
                            "Q{https://www.w3.org/ns/ldt#}base": baseUri,
                            "Q{https://www.w3.org/ns/ldt#}ontology": ontologyUri,
                            "Q{http://www.w3.org/ns/sparql-service-description#}endpoint": endpointUri,
                            "Q{https://w3id.org/atomgraph/linkeddatahub#}absolutePath": absolutePath,
                            "Q{http://www.w3.org/ns/auth/acl#}mode": accessModeUri,
                            "Q{}app-request-uri": servicesRequestUri
                            };
                        
                        SaxonJS.getResource({location: servicesRequestUri, type: "xml", headers: { "Accept": "application/rdf+xml" } }).
                            then(resource => {
                                stylesheetParams["Q{https://w3id.org/atomgraph/linkeddatahub#}apps"] = resource;
                                return Promise.all(docPromises);
                            }, error => {
                                return Promise.all(docPromises);
                            }).
                            then(resources => {
                                const cache = {};
                                for (var i = 0; i < resources.length; i++) {
                                    cache[locationMapping[i].name] = resources[i]
                                };
                                return SaxonJS.transform({
                                    documentPool: cache,
                                    stylesheetLocation: "]]><xsl:value-of select="$client-stylesheet"/><![CDATA[",
                                    initialTemplate: "main",
                                    logLevel: ]]><xsl:value-of select="$saxon-js-log-level"/><![CDATA[,
                                    stylesheetParams: stylesheetParams
                                }, "async");
                            }).
                            catch(err => console.log("Transformation failed: " + err));
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
                        
                    <xsl:apply-templates select="." mode="bs2:Brand"/>

                    <div id="collapsing-top-navbar" class="nav-collapse collapse" style="margin-left: 17%;">
                        <xsl:if test="$ldh:ajaxRendering">
                            <xsl:apply-templates select="." mode="bs2:SearchBar"/>
                        </xsl:if>

                        <xsl:apply-templates select="." mode="bs2:NavBarNavList"/>
                    </div>
                </div>
            </div>

            <xsl:apply-templates select="." mode="bs2:ActionBar"/>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="bs2:Brand">
        <a class="brand" href="{$ldt:base}">
            <xsl:if test="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;AdminApplication'">
                <xsl:attribute name="class" select="'brand admin'"/>
            </xsl:if>

            <xsl:value-of>
                <xsl:apply-templates select="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]" mode="ac:label"/>
            </xsl:value-of>
        </a>
    </xsl:template>
    
    <!-- check if agent has access to the user endpoint by executing a dummy query ASK {} -->
    <xsl:template match="rdf:RDF[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', $ldt:base))]" mode="bs2:SearchBar" priority="1">
        <form action="" method="get" class="navbar-form pull-left" accept-charset="UTF-8" title="{ac:label(key('resources', 'search-title', document('translations.rdf')))}">
            <div class="input-append">
                <select id="search-service" name="service">
                    <option value="">
                        <xsl:value-of>
                            <xsl:text>[</xsl:text>
                            <xsl:apply-templates select="key('resources', 'sparql-service', document('translations.rdf'))" mode="ac:label"/>
                            <xsl:text>]</xsl:text>
                        </xsl:value-of>
                    </option>
                </select>
                
                <input type="text" id="uri" name="uri" class="input-xxlarge typeahead">
                    <xsl:if test="not(starts-with(ac:uri(), $ldt:base))">
                        <xsl:attribute name="value" select="ac:uri()"/>
                    </xsl:if>
                </input>

                <button type="submit">
                    <xsl:apply-templates select="key('resources', 'search', document('translations.rdf'))" mode="ldh:logo">
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
        <xsl:param name="classes" select="for $class-uri in map:keys($default-classes) return key('resources', $class-uri, document(ac:document-uri($class-uri)))" as="element()*"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Create">
                <xsl:with-param name="class" select="'btn-group pull-left'"/>
                <xsl:with-param name="classes" select="$classes"/>
                <xsl:with-param name="create-graph" select="true()"/>
            </xsl:apply-templates>
            
            <xsl:if test="$ldh:ajaxRendering">
                <xsl:apply-templates select="." mode="bs2:AddData"/>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ActionBarMain">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <div id="result-counts">
                <!-- placeholder for client.xsl callbacks -->
            </div>

            <div id="breadcrumb-nav">
                <!-- placeholder for client.xsl callbacks -->

                <xsl:if test="not($ldh:ajaxRendering)">
                    <ul class="breadcrumb pull-left">
                        <!-- render breadcrumbs server-side -->
                        <xsl:apply-templates select="key('resources', ac:uri())" mode="bs2:BreadCrumbListItem"/>
                    </ul>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ActionBarRight">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span3'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:MediaTypeList"/>

            <xsl:apply-templates select="." mode="bs2:NavBarActions"/>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:NavBarNavList">
        <xsl:if test="$foaf:Agent//@rdf:about">
            <ul class="nav pull-right">
                <li>
                    <xsl:if test="$ac:mode = '&ac;QueryEditorMode'">
                        <xsl:attribute name="class" select="'active'"/>
                    </xsl:if>

                    <a href="{ac:build-uri((), map{ 'mode': '&ac;QueryEditorMode' })}" class="query-editor">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'sparql-editor', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </li>
                <xsl:if test="doc-available($app-request-uri)">
                    <li>
                        <div class="btn-group">
                            <button class="btn dropdown-toggle" title="{ac:label(key('resources', 'application-list-title', document('translations.rdf')))}">
                                <xsl:apply-templates select="key('resources', 'applications', document('translations.rdf'))" mode="ldh:logo">
                                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                </xsl:apply-templates>
                            </button>
                            <ul class="dropdown-menu pull-right">
                                <xsl:variable name="apps" select="document($app-request-uri)" as="document-node()"/>
                                <xsl:for-each select="$apps//*[ldt:base/@rdf:resource]">
                                    <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                    <li>
<!--                                        <xsl:if test="$active">
                                            <xsl:attribute name="class" select="'active'"/>
                                        </xsl:if>-->

                                        <a href="{ldt:base/@rdf:resource}" title="{ldt:base/@rdf:resource}">
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </a>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </li>
                </xsl:if>
                <li>
                    <xsl:apply-templates select="." mode="bs2:Settings"/>
                </li>
                <!-- overridden in acl/layout.xsl! TO-DO: extract into separate template -->
                <li>
                    <div class="btn-group">
                        <button type="button" title="{ac:label($foaf:Agent//*[@rdf:about][1])}">
                            <xsl:apply-templates select="key('resources', '&foaf;Agent', document(ac:document-uri('&foaf;')))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                            </xsl:apply-templates>
                        </button>
                        <ul class="dropdown-menu pull-right">
                            <li>
                                <xsl:for-each select="key('resources-by-type', '&foaf;Agent', $foaf:Agent)">
                                    <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor"/>
                                </xsl:for-each>
                            </li>
                        </ul>
                    </div>
                </li>
            </ul>
        </xsl:if>

        <xsl:apply-templates select="." mode="bs2:SignUp"/>
    </xsl:template>

    <xsl:template match="rdf:RDF[not($foaf:Agent//@rdf:about)][$lapp:Application//rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="bs2:SignUp" priority="1">
        <!-- resolve links against the base URI of LinkedDataHub and not of the current app, as we want signups to always go the root app -->
        <xsl:param name="google-signup-uri" select="ac:build-uri(resolve-uri('admin/oauth2/authorize/google', $ldh:base), map{ 'referer': string(ac:uri()) })" as="xs:anyURI"/>
        <xsl:param name="webid-signup-uri" select="resolve-uri('admin/sign%20up', $ldh:base)" as="xs:anyURI"/>
        <xsl:param name="google-signup" select="exists($google:clientID)" as="xs:boolean"/>
        <xsl:param name="webid-signup" select="$ldhc:enableWebIDSignUp" as="xs:boolean"/>
        
        <xsl:if test="$google-signup or $webid-signup">
            <p class="pull-right">
                <xsl:if test="$google-signup">
                    <a class="btn btn-primary" href="{$google-signup-uri}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'login-google', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </xsl:if>
                <xsl:if test="$webid-signup">
                    <a class="btn btn-primary" href="{if (not(starts-with($ldt:base, $ldh:base))) then ac:build-uri((), map{ 'uri': string($webid-signup-uri) }) else $webid-signup-uri}">
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
                <xsl:attribute name="class" select="'active'"/>
            </xsl:if>

            <a href="{ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}" title="{ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </a>
        </li>
    </xsl:template>
    
    <!-- BODY -->

    <xsl:template match="rdf:RDF[key('resources', ac:uri())][$ac:mode = '&ldht;InfoWindowMode']" mode="xhtml:Body" priority="1">
        <body>
            <div> <!-- SPARQLMap renders the first child of <body> as InfoWindow -->
                <xsl:apply-templates select="." mode="bs2:Block">
                    <xsl:with-param name="display" select="true()" tunnel="yes"/>
                </xsl:apply-templates>
            </div>
        </body>
    </xsl:template>

    <xsl:template match="rdf:RDF[key('resources', ac:uri())][$ac:mode = '&ldht;ObjectMode']" mode="xhtml:Body" priority="2">
        <body class="embed">
            <div>
                <xsl:apply-templates select="." mode="bs2:Object">
                    <xsl:with-param name="show-controls" select="false()" tunnel="yes"/>
                </xsl:apply-templates>
            </div>
        </body>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="xhtml:Body">
        <xsl:param name="classes" select="for $class-uri in map:keys($default-classes) return key('resources', $class-uri, document(ac:document-uri($class-uri)))" as="element()*"/>
        <xsl:param name="content-values" select="key('resources', ac:uri())/rdf:type/@rdf:resource[ . = ('&def;Root', '&dh;Container', '&dh;Item')][doc-available(resolve-uri('ns?query=ASK%20%7B%7D', $ldt:base))]/ldh:templates(., resolve-uri('ns', $ldt:base), $template-query)//srx:binding[@name = 'content']/srx:uri/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="has-content" select="key('resources', key('resources', ac:uri())/rdf:_1/@rdf:resource) or exists($content-values)" as="xs:boolean"/>

        <body>
            <xsl:apply-templates select="." mode="bs2:NavBar"/>

            <div about="{ac:uri()}" id="content-body" class="container-fluid">
                <xsl:apply-templates select="." mode="bs2:ModeTabs">
                    <xsl:with-param name="has-content" select="$has-content"/>
                    <xsl:with-param name="active-mode" select="$ac:mode"/>
                    <xsl:with-param name="forClass" select="$ac:forClass"/>
                    <xsl:with-param name="ajax-rendering" select="$ldh:ajaxRendering"/>
                </xsl:apply-templates>
            
                <xsl:choose>
                    <!-- error responses always rendered in bs2:RowBlock mode, no matter what $ac:mode specifies -->
                    <xsl:when test="key('resources-by-type', '&http;Response') and not(key('resources-by-type', '&spin;ConstraintViolation'))">
                        <xsl:apply-templates select="." mode="bs2:RowBlock">
                            <xsl:with-param name="template-query" select="$template-query" tunnel="yes"/>
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$ac:forClass and $ac:method = 'GET'">
                        <xsl:variable name="constructor" as="document-node()">
                            <xsl:apply-templates select="." mode="ldh:Constructor">
                                <xsl:with-param name="forClass" select="$ac:forClass"/>
                                <xsl:with-param name="createGraph" select="$ldh:createGraph"/>
                                <xsl:with-param name="constructor-query" select="$constructor-query"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        <xsl:choose>
                            <xsl:when test="$ac:mode = '&ac;ModalMode'">
                                <xsl:apply-templates select="$constructor" mode="bs2:ModalForm">
                                    <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
                                    <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
                                    <xsl:sort select="ac:label(.)"/>
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="$constructor" mode="bs2:RowForm">
                                    <xsl:with-param name="classes" select="$classes"/>
                                    <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
                                    <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
                                    <xsl:sort select="ac:label(.)"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- check if the current document has content or its class has content -->
                    <xsl:when test="(empty($ac:mode) or $ac:mode = '&ldh;ContentMode') and $has-content">
                        <xsl:for-each select="key('resources', ac:uri())">
                            <xsl:apply-templates select="." mode="ldh:ContentList"/>
                            
                            <xsl:for-each select="$content-values">
                                <xsl:if test="doc-available(ac:document-uri(.))">
                                    <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="bs2:RowContent"/>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="$ac:mode = '&ac;MapMode'">
                        <xsl:apply-templates select="." mode="bs2:Map">
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$ac:mode = '&ac;ChartMode'">
                        <xsl:apply-templates select="." mode="bs2:Chart">
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$ac:mode = '&ac;GraphMode'">
                        <xsl:apply-templates select="." mode="bs2:Graph">
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$ac:mode = '&ac;EditMode' and $ac:mode = '&ac;ModalMode'">
                        <xsl:apply-templates select="." mode="bs2:ModalForm">
                            <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
                            <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$ac:mode = '&ac;EditMode'">
                        <xsl:apply-templates select="." mode="bs2:RowForm">
                            <xsl:with-param name="classes" select="$classes"/>
                            <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
                            <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="bs2:RowBlock">
                            <xsl:with-param name="template-query" select="$template-query" tunnel="yes"/>
                            <xsl:sort select="ac:label(.)"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </div>

            <xsl:apply-templates select="." mode="bs2:DocumentTree"/>
            
            <xsl:apply-templates select="." mode="bs2:Footer"/>
        </body>
    </xsl:template>

    <!-- don't show document-level tabs if the response returned an error or if we're in EditMode -->
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')] | rdf:RDF[$ac:forClass or $ac:mode = '&ac;EditMode']" mode="bs2:ModeTabs" priority="1"/>
    
    <xsl:template match="*[*][@rdf:about = ac:uri()][$ldh:originalGraph][$ldh:localGraph]" mode="bs2:PropertyList">
        <xsl:variable name="original-doc" select="$ldh:originalGraph"/>
        <xsl:variable name="local-doc" select="$ldh:localGraph"/>

        <xsl:variable name="triples-original" as="map(xs:string, element())">
            <xsl:map>
                <xsl:for-each select="$original-doc/rdf:RDF/rdf:Description/*">
                    <xsl:map-entry key="concat(../@rdf:about, '|', ../@rdf:nodeID, '|', namespace-uri(), local-name(), '|', @rdf:resource, @rdf:nodeID, if (text() castable as xs:float) then xs:float(text()) else text(), '|', @rdf:datatype, @xml:lang)" select="."/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="triples-local" as="map(xs:string, element())">
            <xsl:map>
                <xsl:for-each select="$local-doc/rdf:RDF/rdf:Description/*">
                    <xsl:map-entry key="concat(../@rdf:about, '|', ../@rdf:nodeID, '|', namespace-uri(), local-name(), '|', @rdf:resource, @rdf:nodeID, if (text() castable as xs:float) then xs:float(text()) else text(), '|', @rdf:datatype, @xml:lang)" select="."/>
                </xsl:for-each>
            </xsl:map>
        </xsl:variable>

        <xsl:variable name="properties-original" select="for $triple-key in ac:value-except(map:keys($triples-original), map:keys($triples-local)) return map:get($triples-original, $triple-key)" as="element()*"/>
        <xsl:if test="exists($properties-original)">
            <div>
                <h2 class="nav-header btn">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'from-origin', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>

                <xsl:variable name="definitions" as="document-node()">
                    <xsl:document>
                        <dl class="dl-horizontal">
                            <xsl:apply-templates select="$properties-original" mode="#current">
                                <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
            </div>
        </xsl:if>

        <xsl:variable name="properties-local" select="for $triple-key in ac:value-except(map:keys($triples-local), map:keys($triples-original)) return map:get($triples-local, $triple-key)" as="element()*"/>
        <xsl:if test="exists($properties-local)">
            <div>
                <h2 class="nav-header btn">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'local', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>
                
                <xsl:variable name="definitions" as="document-node()">
                    <xsl:document>
                        <dl class="dl-horizontal">
                            <xsl:apply-templates select="$properties-local" mode="#current">
                                <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
            </div>
        </xsl:if>
        
        <xsl:variable name="properties-common" select="for $triple-key in ac:value-intersect(map:keys($triples-original), map:keys($triples-local)) return map:get($triples-original, $triple-key)" as="element()*"/>
        <xsl:if test="exists($properties-common)">
            <div>
                <h2 class="nav-header btn">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'common', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>

                <xsl:variable name="definitions" as="document-node()">
                    <xsl:document>
                        <dl class="dl-horizontal">
                            <xsl:apply-templates select="$properties-common" mode="#current">
                                <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
            </div>
        </xsl:if>
    </xsl:template>
    
    <!-- ADD DATA -->
    
    <xsl:template match="rdf:RDF[$acl:mode = '&acl;Append']" mode="bs2:AddData" priority="1">
        <div class="btn-group pull-left">
            <button type="button" title="{ac:label(key('resources', 'add-data-title', document('translations.rdf')))}" class="btn btn-primary btn-add-data">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'add-data', document('translations.rdf'))" mode="ac:label"/>
                </xsl:value-of>
            </button>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:AddData"/>
    
    <!-- MODE LIST -->
        
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="bs2:ModeList" priority="1"/>

    <xsl:template match="rdf:RDF[ac:uri()]" mode="bs2:ModeList">
        <div class="btn-group pull-right">
            <button type="button" title="{ac:label(key('resources', 'mode-list-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', $ac:mode, document(ac:document-uri('&ac;'))) | key('resources', $ac:mode, document(ac:document-uri('&ldh;')))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <ul class="dropdown-menu">
                <xsl:for-each select="key('resources-by-type', '&ac;Mode', document(ac:document-uri('&ac;'))) | key('resources', ('&ac;QueryEditorMode'), document(ac:document-uri('&ac;')))">
                    <xsl:sort select="ac:label(.)"/>
                    <xsl:apply-templates select="." mode="bs2:ModeListItem">
                        <xsl:with-param name="active" select="$ac:mode"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </ul>
        </div>
    </xsl:template>
       
    <xsl:template match="*" mode="bs2:ModeListItem"/>

    <!-- MEDIA TYPE LIST  -->
        
    <xsl:template match="rdf:RDF" mode="bs2:MediaTypeList" priority="1">
        <div class="btn-group pull-right">
            <button type="button" id="export-rdf" title="{ac:label(key('resources', 'nav-bar-action-export-rdf-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', '&ac;Export', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="key('resources', '&ac;Export', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                
                <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li>
                    <xsl:variable name="href" select="ac:build-uri($ldh:absolutePath, let $params := map{ 'accept': 'application/rdf+xml' } return if (not(starts-with(ac:uri(), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:uri()) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="application/rdf+xml" target="_blank">RDF/XML</a>
                </li>
                <li>
                    <xsl:variable name="href" select="ac:build-uri($ldh:absolutePath, let $params := map{ 'accept': 'text/turtle' } return if (not(starts-with(ac:uri(), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:uri()) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="text/turtle" target="_blank">Turtle</a>
                </li>
                <li>
                    <xsl:variable name="href" select="ac:build-uri($ldh:absolutePath, let $params := map{ 'accept': 'application/ld+json' } return if (not(starts-with(ac:uri(), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:uri()) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="application/ld+json" target="_blank">JSON-LD</a>
                </li>
            </ul>
        </div>
    </xsl:template>
    
    <!-- HEADER  -->

    <!-- TO-DO: move http:Response templates to error.xsl -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][lacl:requestAccess/@rdf:resource][$foaf:Agent]" mode="bs2:Header" priority="2">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'alert alert-info well'" as="xs:string?"/>

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
                
                <xsl:variable name="request-access-to" select="ac:build-uri(lacl:requestAccess/@rdf:resource, map{ 'access-to': string(ac:uri()) } )" as="xs:anyURI"/>
                <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $request-access-to)}" class="btn btn-primary pull-right">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'request-access', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </a>
            </h2>
        </div>
    </xsl:template>
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Header" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'alert alert-error well'" as="xs:string?"/>

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

    <!-- CONTENT HEADER -->

    <!-- hide the header of def:SelectChildren content -->
    <xsl:template match="*[*][$ldh:ajaxRendering][@rdf:about = '&ldh;SelectChildren']" mode="ldh:ContentHeader"/>

    <!-- FORM CONTROL -->

    <xsl:template match="*[rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')]" mode="bs2:FormControl">
        <xsl:param name="id" select="concat('form-control-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="show-subject" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="required" select="true()" as="xs:boolean"/>
        
        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="legend" select="$legend"/>
            <xsl:with-param name="show-subject" select="$show-subject"/>
            <xsl:with-param name="required" select="$required"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID][$ac:forClass]/sioc:has_parent/@rdf:nodeID | *[@rdf:about or @rdf:nodeID][$ac:forClass]/sioc:has_container/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="container" select="if (map:contains($default-classes, $ac:forClass)) then map:get($default-classes, $ac:forClass) else ac:uri()" as="xs:anyURI"/>

        <xsl:next-match>
            <xsl:with-param name="container" select="$container" as="xs:anyURI"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- NAVBAR ACTIONS -->

    <xsl:template match="rdf:RDF" mode="bs2:NavBarActions" priority="1">
        <xsl:if test="$foaf:Agent//@rdf:about">
            <div class="pull-right">
                <button type="button" title="{ac:label(key('resources', 'nav-bar-action-delete-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>
                    
                    <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </button>
            </div>

            <div class="pull-right">
                <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ac:uri(), xs:anyURI('&ac;EditMode'))}" title="{ac:label(key('resources', 'nav-bar-action-edit-graph-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn' || (if ($ac:mode = '&ac;EditMode') then ' active' else ())"/>
                    </xsl:apply-templates>
                    
                    <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </a>
            </div>
            
<!--            <div class="pull-right">
                <button type="button" title="{ac:label(key('resources', 'skolemize-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', 'skolemize', document('translations.rdf'))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>
                </button>
            </div>-->
            
            <xsl:if test="$ldh:ajaxRendering">
                <div class="pull-right">
                    <button type="button" title="{key('resources', 'save-as-title', document('translations.rdf'))}">
                        <xsl:apply-templates select="key('resources', 'save-as', document('translations.rdf'))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn'"/>
                        </xsl:apply-templates>

                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save-as', document('translations.rdf'))" mode="ac:label"/>
                            <xsl:text>...</xsl:text>
                        </xsl:value-of>
                    </button>
                </div>
            </xsl:if>
            
<!--            <div class="pull-right">
                <form action="{ac:uri()}?ban=true" method="post">
                    <input type="hidden" name="ban" value="true"/>
                    <button type="submit" title="{ac:label(key('resources', 'nav-bar-action-refresh-title', document('translations.rdf')))}">
                        <xsl:apply-templates select="key('resources', '&ldht;Ban', document(ac:document-uri('&ldht;')))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn'"/>
                        </xsl:apply-templates>
                        
                        <xsl:apply-templates select="key('resources', '&ldht;Ban', document(ac:document-uri('&ldht;')))" mode="ac:label"/>
                    </button>
                </form>
            </div>-->
            
            <div class="btn-group pull-right">
                <button type="button" title="{ac:label(key('resources', 'acl-list-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ac:label"/>
                    <xsl:text> </xsl:text>
                    <span class="caret"></span>
                </button>

                <ul class="dropdown-menu">
                    <xsl:for-each select="key('resources-by-subclass', '&acl;Access', document(ac:document-uri('&acl;')))">
                        <xsl:sort select="ac:label(.)"/>
                        <xsl:apply-templates select="." mode="bs2:AccessListItem">
                            <xsl:with-param name="enabled" select="$acl:mode"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about]" mode="bs2:AccessListItem" priority="1">
        <xsl:param name="enabled" as="xs:anyURI*"/>
        <xsl:variable name="href" select="ac:uri()" as="xs:anyURI"/>

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
        <div class="btn-group pull-right">
            <button type="button" title="{ac:label(key('resources', 'nav-bar-action-settings-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', 'settings', document('translations.rdf'))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
            </button>

            <ul class="dropdown-menu">
                <xsl:if test="$foaf:Agent//@rdf:about and $lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]/rdf:type/@rdf:resource = '&lapp;EndUserApplication'">
                    <li>
                        <xsl:for-each select="$lapp:Application">
                            <a href="{key('resources', //*[ldt:base/@rdf:resource = $ldt:base]/lapp:adminApplication/(@rdf:resource, @rdf:nodeID))/ldt:base/@rdf:resource[starts-with(., $ac:contextUri)]}" target="_blank">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'administration', document('translations.rdf'))" mode="ac:label"/>
                                </xsl:value-of>
                            </a>
                        </xsl:for-each>
                    </li>
                    <li>
                        <a href="{resolve-uri('ns', $ldt:base)}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'namespace-ontology', document('translations.rdf'))" mode="ac:label"/>
                            </xsl:value-of>
                        </a>
                    </li>
                </xsl:if>
                <li>
                    <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/" target="_blank">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'documentation', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </li>
            </ul>
        </div>
    </xsl:template>

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
            <form method="{$method}" action="{$action}" class="form-open-query">
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

                <xsl:for-each select="ldh:service/@rdf:resource">
                    <input type="hidden" name="service" value="{.}"/>
                </xsl:for-each>
                <input type="hidden" name="mode" value="&ac;QueryEditorMode"/>
                <input type="hidden" name="query" value="{sp:text}"/>

                <button type="submit" class="btn btn-primary">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'open', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
            </form>
        </div>
        
        <xsl:next-match/>
    </xsl:template>

    <xsl:template match="*[@rdf:about][sd:endpoint/@rdf:resource]" mode="bs2:Actions" priority="2">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        
        <div class="pull-right">
            <form method="{$method}" action="{$action}" class="form-open-query">
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

                <input type="hidden" name="service" value="{@rdf:about}"/>
                <input type="hidden" name="mode" value="&ac;QueryEditorMode"/>
                <input type="hidden" name="query" value="{$explore-service-query}"/>

                <button type="submit" class="btn btn-primary">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'explore', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
            </form>
        </div>
        
        <xsl:next-match/>
    </xsl:template>
    
    <!-- DOCUMENT TREE -->
    
    <xsl:template match="rdf:RDF" mode="bs2:DocumentTree">
        <xsl:param name="id" select="'doc-tree'" as="xs:string?"/>
        <xsl:param name="class" select="'well well-small sidebar-nav'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <!-- placeholder for client-side ldh:DocTree template -->
        </div>
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
                                <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/about/" target="_blank">LinkedDataHub</a>
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
                                <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/" target="_blank">Documentation</a>
                            </li>
                            <li>
                                <a href="https://www.youtube.com/channel/UCtrdvnVjM99u9hrjESwfCeg" target="_blank">Screencasts</a>
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
<!--                            <li>
                                <a href="https://www.facebook.com/AtomGraph" target="_blank">facebook.com/AtomGraph</a>
                            </li>-->
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
</xsl:stylesheet>