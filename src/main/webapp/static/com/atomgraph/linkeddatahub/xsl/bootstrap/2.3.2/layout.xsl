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
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
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
    <!ENTITY schema "https://schema.org/">
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
xmlns:schema="&schema;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="../../../../client/xsl/converters/RDFXML2JSON-LD.xsl"/>
    <xsl:import href="../../../../client/xsl/bootstrap/2.3.2/internal-layout.xsl"/>
    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="imports/ac.xsl"/>
    <xsl:import href="imports/dct.xsl"/>
    <xsl:import href="imports/nfo.xsl"/>
    <xsl:import href="imports/rdf.xsl"/>
    <xsl:import href="imports/sioc.xsl"/>
    <xsl:import href="imports/sp.xsl"/>
    <xsl:import href="resource.xsl"/>
    <xsl:import href="document.xsl"/>
    
    <!--  To use xsl:import-schema, you need the schema-aware version of Saxon -->
    <!-- <xsl:import-schema namespace="http://www.w3.org/1999/xhtml" schema-location="http://www.w3.org/2002/08/xhtml/xhtml1-transitional.xsd"/> -->

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="application/xhtml+xml"/>

    <xsl:param name="ldh:base" as="xs:anyURI" static="yes"/>
    <xsl:param name="ldh:requestUri" as="xs:anyURI"/>
    <xsl:param name="ac:endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
    <xsl:param name="sd:endpoint" as="xs:anyURI?"/>
    <xsl:param name="acl:agent" as="xs:anyURI?"/>
    <xsl:param name="lapp:Application" as="document-node()?"/>
    <xsl:param name="foaf:Agent" select="if ($acl:agent) then document(ac:document-uri($acl:agent)) else ()" as="document-node()?"/>
    <xsl:param name="force-exclude-all-namespaces" select="true()"/>
    <xsl:param name="ac:uri" as="xs:anyURI"/>
    <xsl:param name="ac:httpHeaders" as="xs:string"/> 
    <xsl:param name="ac:method" as="xs:string"/>
    <xsl:param name="ac:mode" as="xs:anyURI*"/> <!-- select="xs:anyURI('&ac;ReadMode')" -->
    <xsl:param name="acl:mode" as="xs:anyURI*"/>
    <!-- <xsl:param name="ldh:forShape" as="xs:anyURI?"/> -->
    <xsl:param name="ldh:createGraph" select="false()" as="xs:boolean"/>
    <xsl:param name="ldh:ajaxRendering" select="true()" as="xs:boolean"/>
    <xsl:param name="ldhc:enableWebIDSignUp" as="xs:boolean"/>
    <xsl:param name="ldh:renderSystemResources" select="false()" as="xs:boolean"/>
    <xsl:param name="google:clientID" as="xs:string?"/>
    <xsl:param name="default-classes" select="(xs:anyURI('&lapp;Application'), xs:anyURI('&sd;Service'), xs:anyURI('&nfo;FileDataObject'), xs:anyURI('&sp;Construct'), xs:anyURI('&sp;Describe'), xs:anyURI('&sp;Select'), xs:anyURI('&sp;Ask'), xs:anyURI('&ldh;RDFImport'), xs:anyURI('&ldh;CSVImport'), xs:anyURI('&ldh;GraphChart'), xs:anyURI('&ldh;ResultSetChart'), xs:anyURI('&ldh;View'))" as="xs:anyURI*"/>
    <xsl:param name="location-mapping" as="map(xs:anyURI, xs:anyURI)">
        <xsl:map>
            <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)"/>
            <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/http-statusCodes.rdf', $ac:contextUri)" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/http-statusCodes.rdf', $ac:contextUri)"/>
            <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/admin/countries.rdf', $ac:contextUri)" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/admin/countries.rdf', $ac:contextUri)"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&ac;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&ac;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&adm;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&adm;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&lacl;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&lacl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&ldh;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&ldh;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&def;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&def;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&dh;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&dh;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&sp;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sp;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&spin;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&spin;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&rdf;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&rdf;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&rdfs;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&rdfs;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&owl;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&owl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&acl;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&acl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&sd;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sd;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&sh;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sh;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="resolve-uri(ac:document-uri(xs:anyURI('&nfo;')), $ac:contextUri)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&nfo;'))), 'accept': 'application/rdf+xml' })"/>
        </xsl:map>
    </xsl:param>
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

    <!-- the query has to support services that do not belong to any app. Use type URIs because that is what triggers Varnish invalidation. -->
    <xsl:variable name="app-query" as="xs:string">
        <![CDATA[
            DESCRIBE ?resource
            WHERE
              { GRAPH ?graph
                  {   { ?resource  a                    <https://w3id.org/atomgraph/linkeddatahub/apps#Application> ;
                                  <https://www.w3.org/ns/ldt#base>  ?base
                      }
                    UNION
                      { ?resource  a                    <http://www.w3.org/ns/sparql-service-description#Service> ;
                                  <http://www.w3.org/ns/sparql-service-description#endpoint>  ?endpoint
                      }
                  }
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="app-request-uri" select="ac:build-uri(resolve-uri('sparql', $ldt:base), map{ 'query': $app-query })" as="xs:anyURI"/>
    <xsl:variable name="template-query" as="xs:string">
        <![CDATA[
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>

            SELECT  *
            WHERE
              {
                $Type  ldh:template  ?block
              }
        ]]>
        <!-- VALUES $Type goes here -->
    </xsl:variable>
    <xsl:variable name="constraint-query" as="xs:string">
        <![CDATA[
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  sp:   <http://spinrdf.org/sp#>
            PREFIX  spin: <http://spinrdf.org/spin#>

            SELECT  $Type ?property
            WHERE
              { $Type (rdfs:subClassOf)*/spin:constraint  ?constraint .
                ?constraint  a             ldh:MissingPropertyValue ;
                          sp:arg1          ?property
              }
        ]]>
        <!-- VALUES $Type goes here -->
    </xsl:variable>
    <xsl:variable name="constructor-query" as="xs:string">
        <![CDATA[
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  sp:   <http://spinrdf.org/sp#>
            PREFIX  spin: <http://spinrdf.org/spin#>

            SELECT  $Type ?constructor ?construct
            WHERE
              { $Type (rdfs:subClassOf)*/spin:constructor  ?constructor .
                ?constructor sp:text ?construct .
              }
        ]]>
        <!-- VALUES $Type goes here -->
    </xsl:variable>
    <xsl:variable name="shape-query" as="xs:string">
        <![CDATA[
            PREFIX  sh:   <http://www.w3.org/ns/shacl#>

            DESCRIBE $Shape ?property
            WHERE
              { $Shape  sh:targetClass  $Type
                OPTIONAL
                  { $Shape  sh:property  ?property }
              }
        ]]>
        <!-- VALUES $Type goes here -->
    </xsl:variable>
    <xsl:param name="object-metadata-query" as="xs:string">
        <![CDATA[
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
            PREFIX  dct:  <http://purl.org/dc/terms/>
            PREFIX  schema2: <https://schema.org/>
            PREFIX  schema1: <http://schema.org/>
            PREFIX  skos: <http://www.w3.org/2004/02/skos/core#>
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  foaf: <http://xmlns.com/foaf/0.1/>
            PREFIX  sioc: <http://rdfs.org/sioc/ns#>
            PREFIX  dc:   <http://purl.org/dc/elements/1.1/>

            CONSTRUCT 
              { 
                ?this ?p ?literal .
              }
            WHERE
              { GRAPH ?graph
                  { ?this  ?p  ?literal
                    FILTER ( ( datatype(?literal) = xsd:string ) || ( datatype(?literal) = rdf:langString ) )
                    FILTER ( ?p IN (rdfs:label, dc:title, dct:title, foaf:name, foaf:givenName, foaf:familyName, sioc:name, skos:prefLabel, schema1:name, schema2:name) )
                  }
              }
        ]]>
        <!-- VALUES $Type goes here -->
    </xsl:param>
    
    <xsl:key name="violations-by-root" match="*[@rdf:about] | *[@rdf:nodeID]" use="spin:violationRoot/@rdf:resource | spin:violationRoot/@rdf:nodeID"/>
    <xsl:key name="violations-by-value" match="*" use="ldh:violationValue/text()"/>
    <xsl:key name="violations-by-focus-node" match="*" use="sh:focusNode/@rdf:resource | sh:focusNode/@rdf:nodeID"/>

    <rdf:Description rdf:about="">
    </rdf:Description>
    
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

        <xsl:if test="$lapp:Application//*[ldt:base/@rdf:resource = $ldt:base]">
            <meta property="og:site_name" content="{ac:label($lapp:Application//*[ldt:base/@rdf:resource = $ldt:base])}"/>
        </xsl:if>
    </xsl:template>

    <!-- STYLE -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="xhtml:Style">
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

    <xsl:template match="rdf:RDF | srx:sparql" mode="xhtml:Script">
        <xsl:param name="client-stylesheet" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json', $ac:contextUri)" as="xs:anyURI"/>
        <xsl:param name="saxon-js-log-level" select="10" as="xs:integer"/>
        <xsl:param name="load-wymeditor" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-saxon-js" select="$ldh:ajaxRendering and not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-builder" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-map" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-google-charts" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-xml-c14n" select="not($ac:mode = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="output-schema-org" select="true()" as="xs:boolean"/>
        <xsl:param name="location-mapping" select="$location-mapping" as="map(xs:anyURI, xs:anyURI)"/>

        <!-- Web-Client scripts -->
        <script type="text/javascript" src="{resolve-uri('static/js/jquery.min.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/js/bootstrap.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/client/js/UUID.js', $ac:contextUri)}" defer="defer"></script>
        <!-- LinkedDataHub scripts -->
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/jquery.js', $ac:contextUri)}" defer="defer"></script>
        <script type="text/javascript">
            <xsl:text disable-output-escaping="yes">
              //&lt;![CDATA[
            </xsl:text>
            <![CDATA[
                var baseUri = ]]><xsl:value-of select="'&quot;' || $ldt:base || '&quot;'" disable-output-escaping="yes"/><![CDATA[;
                var absolutePath = ]]><xsl:value-of select="'&quot;' || ac:absolute-path(ldh:base-uri(.)) || '&quot;'" disable-output-escaping="yes"/><![CDATA[;
                var ontologyUri = ]]><xsl:value-of select="'&quot;' || $ldt:ontology || '&quot;'" disable-output-escaping="yes"/><![CDATA[;
                var endpointUri = ]]><xsl:value-of select="if ($sd:endpoint) then '&quot;' || $sd:endpoint || '&quot;'  else 'null'" disable-output-escaping="yes"/><![CDATA[;
                var contextUri = ]]><xsl:value-of select="if ($ac:contextUri) then '&quot;' || $ac:contextUri || '&quot;'  else 'null'" disable-output-escaping="yes"/><![CDATA[;
                var agentUri = []]><xsl:value-of select="if ($acl:agent) then '&quot;' || $acl:agent || '&quot;'  else 'null'" disable-output-escaping="yes"/><![CDATA[];
                var accessModeUri = []]><xsl:value-of select="string-join(for $mode in $acl:mode return '&quot;' || $mode || '&quot;', ', ')" disable-output-escaping="yes"/><![CDATA[];
            ]]>
            <xsl:text disable-output-escaping="yes">
              //]]&gt;
            </xsl:text>
        </script>
        <xsl:if test="$load-wymeditor">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/jquery.wymeditor.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-yasqe">
            <script src="{resolve-uri('static/js/yasqe.js', $ac:contextUri)}" type="text/javascript"></script>
        </xsl:if>
        <xsl:if test="$load-saxon-js">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/saxon-js/SaxonJS3.rt.js', $ac:contextUri)}" defer="defer"></script>
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
                            <xsl:text disable-output-escaping="yes">
                            <![CDATA[
                        ];
                        const docPromises = locationMapping.map(mapping => SaxonJS.getResource({location: mapping.altName, type: "xml"}));
                        const servicesRequestUri = "]]></xsl:text><xsl:value-of select="$app-request-uri"/><xsl:text disable-output-escaping="yes"><![CDATA[";
                        const stylesheetParams = {
                            "Q{https://w3id.org/atomgraph/client#}contextUri": contextUri, // servlet context URI
                            "Q{https://www.w3.org/ns/ldt#}base": baseUri,
                            "Q{https://www.w3.org/ns/ldt#}ontology": ontologyUri,
                            "Q{http://www.w3.org/ns/sparql-service-description#}endpoint": endpointUri,
                            "Q{https://w3id.org/atomgraph/linkeddatahub#}absolutePath": absolutePath,
                            "Q{http://www.w3.org/ns/auth/acl#}agent": agentUri,
                            "Q{http://www.w3.org/ns/auth/acl#}mode": accessModeUri,
                            "Q{}app-request-uri": servicesRequestUri
                            };
                        
                        SaxonJS.setConfigurationProperty("nativeGetElementById", true);
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
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQLBuilder.js', $ac:contextUri)}" defer="defer"></script>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/SPARQL.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$load-sparql-map">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/ol.css', $ac:contextUri)}" rel="stylesheet" type="text/css"></link>
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/ol.js', $ac:contextUri)}"></script>
        </xsl:if>
        <xsl:if test="$load-google-charts">
            <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
            <script type="text/javascript">
                <![CDATA[
                    google.charts.load('current', {packages: ['corechart', 'table', 'timeline', 'map']});
                ]]>
            </script>
        </xsl:if>
        <xsl:if test="$load-xml-c14n">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/xml-c14n-sync.js', $ac:contextUri)}" defer="defer"></script>
        </xsl:if>
        <xsl:if test="$output-schema-org">
            <xsl:variable name="rdf" as="element()?">
                <xsl:apply-templates select="." mode="schema:BreadCrumbList"/>
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
    
    <!-- NAVBAR -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:NavBar">
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

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:Brand">
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
    <xsl:template match="rdf:RDF[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', $ldt:base))] | srx:sparql[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', $ldt:base))]" mode="bs2:SearchBar" priority="1">
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
                    <xsl:if test="not(starts-with(ac:absolute-path(ldh:base-uri(.)), $ldt:base))">
                        <xsl:attribute name="value" select="ac:absolute-path(ldh:base-uri(.))"/>
                    </xsl:if>
                </input>
                <!-- placeholder used by the client-side typeahead -->
                 <ul id="ul-{generate-id()}" class="search-typeahead typeahead dropdown-menu" style="display: none"/> 

                <button type="submit">
                    <xsl:apply-templates select="key('resources', 'search', document('translations.rdf'))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn btn-primary'"/>
                    </xsl:apply-templates>
                </button>
            </div>
        </form>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:SearchBar"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBarLeft">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span2'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:if test="$acl:mode = '&acl;Write' and not(key('resources-by-type', '&http;Response')) and doc-available(ac:absolute-path($ldh:requestUri))">
                <!-- child documents can be created only if the current document is the Root or a container -->
                <xsl:if test="key('resources', ac:absolute-path($ldh:requestUri), document(ac:absolute-path($ldh:requestUri)))/rdf:type/@rdf:resource = ('&def;Root', '&dh;Container')">
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
                <xsl:apply-templates select="." mode="bs2:BreadCrumbBar"/>
                
                <div id="created-modified-date" class="span3">
                    <p>
                        <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="bs2:Timestamp"/>
                    </p>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:ActionBarRight">
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
    
    <xsl:template match="rdf:RDF" mode="bs2:BreadCrumbBar">
        <xsl:param name="id" select="'breadcrumb-nav'" as="xs:string?"/>
        <xsl:param name="class" select="'span9'" as="xs:string?"/>

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
                    <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="bs2:BreadCrumbListItem"/>
                </ul>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="srx:sparql" mode="bs2:BreadCrumbBar"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:NavBarNavList">
        <xsl:if test="$foaf:Agent//@rdf:about">
            <ul class="nav pull-right">
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

    <xsl:template match="rdf:RDF[not($foaf:Agent//@rdf:about)][$lapp:Application//rdf:type/@rdf:resource = '&lapp;EndUserApplication'] | srx:sparql[not($foaf:Agent//@rdf:about)][$lapp:Application//rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="bs2:SignUp" priority="1">
        <!-- resolve links against the base URI of LinkedDataHub and not of the current app, as we want signups to always go the root app -->
        <xsl:param name="google-signup-uri" select="ac:build-uri(resolve-uri('admin/oauth2/authorize/google', $ldh:base), map{ 'referer': string(ac:absolute-path($ldh:requestUri)) })" as="xs:anyURI"/>
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
    
    <xsl:template match="*" mode="bs2:SignUp"/>
    
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

    <xsl:template match="rdf:RDF | srx:sparql" mode="xhtml:Body">
        <body>
            <div id="visible-body">
                <xsl:apply-templates select="." mode="bs2:NavBar"/>

                <xsl:apply-templates select="." mode="bs2:ContentBody"/>

                <xsl:apply-templates select="." mode="bs2:Footer"/>
            </div>
            
            <xsl:apply-templates select="." mode="bs2:DocumentTree"/>
        </body>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:ContentBody">
        <xsl:param name="id" select="'content-body'" as="xs:string?"/>
        <xsl:param name="class" select="'container-fluid'" as="xs:string?"/>
        <xsl:param name="about" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="key('resources', ac:absolute-path(ldh:base-uri(.)))/rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="classes" select="for $class-uri in $default-classes return key('resources', $class-uri, document(ac:document-uri($class-uri)))" as="element()*"/>
        <xsl:param name="doc-types" select="key('resources', ac:absolute-path(ldh:base-uri(.)))/rdf:type/@rdf:resource[ . = ('&def;Root', '&dh;Container', '&dh;Item')]" as="xs:anyURI*"/>
        <!-- take care not to load unnecessary documents over HTTP when $doc-types is empty -->
        <xsl:param name="block-values" select="if (exists($doc-types)) then (if (doc-available(resolve-uri('ns?query=ASK%20%7B%7D', $ldt:base))) then (ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $template-query || ' VALUES $Type { ' || string-join(for $type in $doc-types return '&lt;' || $type || '&gt;', ' ') || ' }')//srx:binding[@name = 'content']/srx:uri/xs:anyURI(.)) else ()) else ()" as="xs:anyURI*"/>
        <xsl:param name="has-content" select="key('resources', key('resources', ac:absolute-path(ldh:base-uri(.)))/rdf:*[starts-with(local-name(), '_')]/@rdf:resource) or exists($block-values)" as="xs:boolean"/>

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
            
            <xsl:apply-templates select="." mode="bs2:ModeTabs">
                <xsl:with-param name="has-content" select="$has-content"/>
                <xsl:with-param name="active-mode" select="$ac:mode"/>
                <xsl:with-param name="ajax-rendering" select="$ldh:ajaxRendering"/>
            </xsl:apply-templates>

            <xsl:choose>
                <!-- error responses always rendered in bs2:Block mode, no matter what $ac:mode specifies -->
                <xsl:when test="key('resources-by-type', '&http;Response') and not(key('resources-by-type', '&spin;ConstraintViolation')) and not(key('resources-by-type', '&sh;ValidationResult'))">
                    <xsl:apply-templates select="." mode="bs2:Row">
                        <xsl:with-param name="template-query" select="$template-query" tunnel="yes"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:when>
                <!-- check if the current document has content or its class has content -->
                <xsl:when test="(empty($ac:mode) and $has-content) or $ac:mode = '&ldh;ContentMode'">
                    <xsl:apply-templates select="." mode="ldh:ContentList"/>

                    <xsl:for-each select="$block-values">
                        <xsl:if test="doc-available(ac:document-uri(.))">
                            <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="bs2:Row"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$ac:mode = '&ac;MapMode'">
                    <xsl:apply-templates select="." mode="bs2:Map">
                        <xsl:with-param name="id" select="generate-id() || '-map-canvas'"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$ac:mode = '&ac;ChartMode'">
                    <xsl:apply-templates select="." mode="bs2:Chart">
                        <xsl:with-param name="canvas-id" select="generate-id() || '-chart-canvas'"/>
                        <xsl:with-param name="show-save" select="false()"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$ac:mode = '&ac;GraphMode'">
                    <xsl:apply-templates select="." mode="bs2:Graph">
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="bs2:Row">
                        <xsl:with-param name="classes" select="$classes"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
        
    <!-- don't show document-level tabs if the response returned an error or if we're in EditMode -->
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')]" mode="bs2:ModeTabs" priority="1"/>

    <xsl:template match="srx:sparql" mode="bs2:ContentBody">
        <xsl:param name="id" select="'content-body'" as="xs:string?"/>
        <xsl:param name="class" select="'container-fluid'" as="xs:string?"/>
        <xsl:param name="about" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI?"/>

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
    
    <!-- only lookup resource locally using DESCRIBE if it's external (not relative to the app's base URI) and the agent is authenticated -->
    <xsl:template match="*[*][@rdf:about = ac:absolute-path(ldh:base-uri(.))][not(starts-with(@rdf:about, $ldt:base))][$foaf:Agent//@rdf:about]" mode="bs2:PropertyList">
        <xsl:param name="endpoint" select="($sd:endpoint, $ac:endpoint)[1]" as="xs:anyURI"/>
        <xsl:param name="property-uris" select="distinct-values(*/concat(namespace-uri(), local-name()))" as="xs:anyURI*"/>
        <xsl:param name="property-metadata" select="ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', 'DESCRIBE ' || string-join(for $uri in distinct-values(/rdf:RDF/*/*/concat(namespace-uri(), local-name())) return '&lt;' || $uri || '&gt;', ' '), map{ 'Accept': 'application/rdf+xml' })" as="document-node()"/>
        <xsl:variable name="local-doc" select="ldh:query-result(map{}, $endpoint, 'DESCRIBE &lt;' || @rdf:about || '&gt;')" as="document-node()"/>
        <xsl:variable name="original-doc" as="document-node()">
            <xsl:try>
                <!-- try loading resource by deferencing its URI -->
                <xsl:variable name="full-doc" select="document(ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(@rdf:about)), 'accept': 'application/rdf+xml' }))" as="document-node()"/>
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
                                <xsl:sort select="ac:property-label(., $property-metadata)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
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
                                <xsl:sort select="ac:property-label(., $property-metadata)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
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
                                <xsl:sort select="ac:property-label(., $property-metadata)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
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
            <button type="button" class="btn btn-primary dropdown-toggle" title="{ac:label(key('resources', 'add', document('translations.rdf')))}">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'add', document('translations.rdf'))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>
            
            <ul class="dropdown-menu">
                <li>
                    <button type="button" title="{ac:label(key('resources', 'generate-containers-title', document('translations.rdf')))}" class="btn btn-generate-containers">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'generate-containers', document('translations.rdf'))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </li>
            </ul>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:AddData"/>
    
    <!-- MODE LIST -->
        
    <xsl:template match="rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))] | rdf:RDF[key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&sh;ValidationResult'))]" mode="bs2:ModeList" priority="1"/>

    <!-- MEDIA TYPE LIST  -->
        
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:MediaTypeList" priority="1">
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
                    <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:base-uri(.)), let $params := map{ 'accept': 'application/rdf+xml' } return if (not(starts-with(ac:absolute-path(ldh:base-uri(.)), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:absolute-path(ldh:base-uri(.))) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="application/rdf+xml" target="_blank">RDF/XML</a>
                </li>
                <li>
                    <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:base-uri(.)), let $params := map{ 'accept': 'text/turtle' } return if (not(starts-with(ac:absolute-path(ldh:base-uri(.)), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:absolute-path(ldh:base-uri(.))) })) else $params)" as="xs:anyURI"/>
                    <a href="{$href}" title="text/turtle" target="_blank">Turtle</a>
                </li>
                <li>
                    <xsl:variable name="href" select="ac:build-uri(ac:absolute-path(ldh:base-uri(.)), let $params := map{ 'accept': 'application/ld+json' } return if (not(starts-with(ac:absolute-path(ldh:base-uri(.)), $ldt:base))) then map:merge(($params, map{ 'uri': string(ac:absolute-path(ldh:base-uri(.))) })) else $params)" as="xs:anyURI"/>
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
                
                <button type="button" class="btn btn-primary btn-access-form pull-right">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'request-access', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
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
    <xsl:template match="*[*][$ldh:ajaxRendering][rdf:value/@rdf:resource = '&ldh;SelectChildren']" mode="bs2:RowContentHeader"/>
    
    <!-- NAVBAR ACTIONS -->

    <xsl:template match="rdf:RDF" mode="bs2:NavBarActions" priority="1">
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        
        <xsl:if test="$foaf:Agent//@rdf:about">
            <div class="pull-right">
                <button type="button" title="{ac:label(key('resources', 'nav-bar-action-delete-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn' || (if (not($acl:mode = '&acl;Write')) then ' disabled' else ())"/>
                    </xsl:apply-templates>
                    
                    <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </button>
            </div>

            <xsl:if test="$ldh:ajaxRendering">
                <div class="pull-right">
                    <button type="button" title="{ac:label(key('resources', 'save-as-title', document('translations.rdf')))}">
                        <xsl:apply-templates select="key('resources', 'save-as', document('translations.rdf'))" mode="ldh:logo">
                            <!-- disable button if external document is not being browsed or the agent has no acl:Write access -->
                            <xsl:with-param name="class" select="'btn' || (if ((ac:absolute-path(ldh:base-uri(.)) = ac:absolute-path($ldh:requestUri)) or not($acl:mode = '&acl;Write')) then ' disabled' else ())"/>
                        </xsl:apply-templates>

                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save-as', document('translations.rdf'))" mode="ac:label"/>
                            <xsl:text>...</xsl:text>
                        </xsl:value-of>
                    </button>
                </div>
            </xsl:if>
            
            <div class="btn-group pull-right">
                <button type="button" title="{ac:label(key('resources', 'acl-list-title', document('translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn'"/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="key('resources', '&acl;Access', document(ac:document-uri('&acl;')))" mode="ac:label"/>
                </button>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about]" mode="bs2:AccessListItem" priority="1">
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
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:Settings" priority="1">
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
    
    <!-- DOCUMENT TREE -->
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:DocumentTree">
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
    
    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:Footer">
        <div class="footer container-fluid">
            <div class="row-fluid">
                <div class="offset2 span8">
                    <div class="span3">
                        <h2 class="nav-header">About</h2>
                        <ul class="nav nav-list">
                            <li>
                                <a href="https://linkeddatahub.com" target="_blank">LinkedDataHub</a>
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