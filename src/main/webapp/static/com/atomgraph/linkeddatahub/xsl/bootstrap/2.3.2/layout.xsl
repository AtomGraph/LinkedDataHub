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
xmlns:orcid="&orcid;"
xmlns:schema="&schema;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="../../../../client/xsl/converters/RDFXML2JSON-LD.xsl"/>
    <xsl:import href="../../../../client/xsl/bootstrap/2.3.2/internal-layout.xsl"/>
    <xsl:import href="resource.xsl"/>
    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="imports/ac.xsl"/>
    <xsl:import href="imports/dct.xsl"/>
    <xsl:import href="imports/nfo.xsl"/>
    <xsl:import href="imports/rdf.xsl"/>
    <xsl:import href="imports/rdfs.xsl"/>
    <xsl:import href="imports/sioc.xsl"/>
    <xsl:import href="imports/sp.xsl"/>
    <xsl:import href="imports/sh.xsl"/>
    <xsl:import href="imports/lapp.xsl"/>
    <xsl:import href="imports/services/youtube.xsl"/>
    <xsl:import href="document.xsl"/>
    
    <!--  To use xsl:import-schema, you need the schema-aware version of Saxon -->
    <!-- <xsl:import-schema namespace="http://www.w3.org/1999/xhtml" schema-location="http://www.w3.org/2002/08/xhtml/xhtml1-transitional.xsd"/> -->

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="application/xhtml+xml"/>

    <xsl:param name="lapp:origin" as="xs:anyURI?"/>
    <xsl:param name="ldh:requestUri" as="xs:anyURI"/>
    <xsl:param name="ac:uri" as="xs:anyURI?"/>
    <xsl:param name="acl:agent" as="xs:anyURI?"/>
    <xsl:param name="lapp:Context" as="document-node()"/>
    <xsl:param name="foaf:Agent" select="if ($acl:agent) then document(ac:document-uri($acl:agent)) else ()" as="document-node()?"/>
    <xsl:param name="ac:httpHeaders" as="xs:string"/>
    <xsl:param name="ac:method" as="xs:string"/>
    <xsl:param name="ldh:httpHeaders" select="map{}" as="map(xs:string, xs:string*)"/>
    <xsl:param name="ldh:ajaxRendering" select="true()" as="xs:boolean"/>
    <xsl:param name="ldhc:enableWebIDSignUp" as="xs:boolean"/>
    <xsl:param name="ldh:renderSystemResources" select="false()" as="xs:boolean"/>
    <xsl:param name="google:clientID" as="xs:string?"/>
    <xsl:param name="orcid:clientID" as="xs:string?"/>
    <xsl:param name="doc-types" select="key('resources', ac:absolute-path(ldh:base-uri(.)))/rdf:type/@rdf:resource[ . = ('&def;Root', '&dh;Container', '&dh;Item')]" as="xs:anyURI*"/>
    <xsl:param name="location-mapping" as="map(xs:anyURI, xs:anyURI)">
        <xsl:map>
            <xsl:if test="lapp:origin()">
                <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', lapp:origin())" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', lapp:origin())"/>
                <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/http-statusCodes.rdf', lapp:origin())" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/http-statusCodes.rdf', lapp:origin())"/>
                <xsl:map-entry key="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/admin/countries.rdf', lapp:origin())" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/admin/countries.rdf', lapp:origin())"/>                
            </xsl:if>

            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&ac;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&ac;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&adm;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&adm;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&lacl;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&lacl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&lapp;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&lapp;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&ldh;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&ldh;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&def;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&def;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&dh;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&dh;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&sp;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sp;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&spin;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&spin;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&rdf;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&rdf;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&rdfs;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&rdfs;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&owl;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&owl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&acl;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&acl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&sd;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sd;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&sh;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sh;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&nfo;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&nfo;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://www.semanticdesktop.org/ontologies/2007/01/19/nie#')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://www.semanticdesktop.org/ontologies/2007/01/19/nie#'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&http;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&http;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&sc;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sc;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&ldt;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&ldt;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&c;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&c;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&sioc;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&sioc;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&void;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&void;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&foaf;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&foaf;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&spl;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&spl;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&cert;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&cert;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://www.w3.org/ns/prov#')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://www.w3.org/ns/prov#'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&geo;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&geo;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://www.w3.org/2004/02/skos/core#')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://www.w3.org/2004/02/skos/core#'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://www.w3.org/2006/time#')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://www.w3.org/2006/time#'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://purl.org/dc/elements/1.1/')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://purl.org/dc/elements/1.1/'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('&dct;')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('&dct;'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://purl.org/dc/dcmitype/')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://purl.org/dc/dcmitype/'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://purl.org/goodrelations/v1#')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://purl.org/goodrelations/v1#'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:map-entry key="xs:anyURI(ac:document-uri(xs:anyURI('http://usefulinc.com/ns/doap#')))" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(xs:anyURI('http://usefulinc.com/ns/doap#'))), 'accept': 'application/rdf+xml' })"/>
            <xsl:if test="$acl:agent">
                <xsl:map-entry key="ac:document-uri($acl:agent)" select="ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri($acl:agent)), 'accept': 'application/rdf+xml' })"/>
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
                $this ?p ?literal .
              }
            WHERE
              { GRAPH ?graph
                  { $this  ?p  ?literal
                    FILTER ( ( datatype(?literal) = xsd:string ) || ( datatype(?literal) = rdf:langString ) )
                    FILTER ( ?p IN (rdfs:label, dc:title, dct:title, foaf:name, foaf:givenName, foaf:familyName, sioc:name, skos:prefLabel, schema1:name, schema2:name) )
                  }
              }
        ]]>
        <!-- VALUES $this goes here -->
    </xsl:param>
    
    <xsl:key name="violations-by-root" match="*[@rdf:about] | *[@rdf:nodeID]" use="spin:violationRoot/@rdf:resource | spin:violationRoot/@rdf:nodeID"/>
    <xsl:key name="violations-by-value" match="*" use="ldh:violationValue/text()"/>
    <xsl:key name="violations-by-focus-node" match="*" use="sh:focusNode/@rdf:resource | sh:focusNode/@rdf:nodeID"/>
    <xsl:key name="apps-by-origin" match="*" use="lapp:origin/@rdf:resource"/>

    <rdf:Description rdf:about="">
    </rdf:Description>
    
    <!-- TITLE -->

    <xsl:template match="rdf:RDF" mode="xhtml:Title">
        <title>
            <xsl:for-each select="key('apps-by-origin', lapp:origin(), $lapp:Context)">
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

        <xsl:for-each select="key('apps-by-origin', lapp:origin(), $lapp:Context)">
            <meta property="og:site_name" content="{ac:label(.)}"/>
        </xsl:for-each>
    </xsl:template>

    <!-- STYLE -->
    
    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="xhtml:Style">
        <xsl:param name="load-wymeditor" select="exists($foaf:Agent//@rdf:about)" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="true()" as="xs:boolean"/>

        <link href="{resolve-uri('static/css/bootstrap.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <link href="{resolve-uri('static/css/bootstrap-responsive.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <link href="{resolve-uri('static/com/atomgraph/client/css/bootstrap.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/css/bootstrap.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        <xsl:if test="$load-wymeditor">
            <link href="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/skins/default/skin.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        </xsl:if>
        <xsl:if test="$load-yasqe">
            <link href="{resolve-uri('static/css/yasqe.css', lapp:origin())}" rel="stylesheet" type="text/css"/>
        </xsl:if>
    </xsl:template>

    <!-- SCRIPT -->

    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="xhtml:Script">
        <xsl:param name="client-stylesheet" select="resolve-uri('static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json', lapp:origin())" as="xs:anyURI"/>
        <xsl:param name="saxon-js-log-level" select="10" as="xs:integer"/>
        <xsl:param name="load-wymeditor" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-yasqe" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-saxon-js" select="$ldh:ajaxRendering and not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-builder" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-sparql-map" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-google-charts" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-xml-c14n" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="load-graph3d" select="not(ac:mode(root()) = ('&ac;ModalMode', '&ldht;InfoWindowMode'))" as="xs:boolean"/>
        <xsl:param name="output-schema-org" select="true()" as="xs:boolean"/>
        <xsl:param name="location-mapping" select="$location-mapping" as="map(xs:anyURI, xs:anyURI)"/>

        <!-- Web-Client scripts -->
        <script type="text/javascript" src="{resolve-uri('static/js/jquery.min.js', lapp:origin())}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/js/bootstrap.js', lapp:origin())}" defer="defer"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/client/js/UUID.js', lapp:origin())}" defer="defer"></script>
        <!-- LinkedDataHub scripts -->
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/jquery.js', lapp:origin())}" defer="defer"></script>
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
        <xsl:if test="$load-wymeditor">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/wymeditor/jquery.wymeditor.js', lapp:origin())}" defer="defer"></script>
        </xsl:if>
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
        <xsl:if test="$load-xml-c14n">
            <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/xml-c14n-sync.js', lapp:origin())}" defer="defer"></script>
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
    
    <xsl:template match="rdf:RDF[$lapp:origin] | srx:sparql[$lapp:origin]" mode="bs2:NavBar" priority="1">
        <div class="navbar navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container-fluid">
                    <button class="btn btn-navbar">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>

                    <div id="collapsing-top-navbar" class="nav-collapse collapse">
                        <div class="row-fluid">
                            <xsl:apply-templates select="." mode="bs2:NavBarLeft"/>

                            <xsl:apply-templates select="." mode="bs2:NavBarMain"/>

                            <xsl:apply-templates select="." mode="bs2:NavBarRight"/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:NavBar"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:NavBarLeft">
        <xsl:param name="class" select="'span2'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Brand"/>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:NavBarMain">
        <xsl:param name="class" select="'span7'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:if test="$ldh:ajaxRendering">
                <xsl:apply-templates select="." mode="bs2:SearchBar"/>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:NavBarRight">
        <xsl:param name="class" select="'span3'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:NavBarNavList"/>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF[key('apps-by-origin', lapp:origin(), $lapp:Context)] | srx:sparql[key('apps-by-origin', lapp:origin(), $lapp:Context)]" mode="bs2:Brand" priority="1">
        <a class="brand" href="{$ldt:base}">
            <xsl:for-each select="key('apps-by-origin', lapp:origin(), $lapp:Context)">
                <xsl:if test="rdf:type/@rdf:resource = '&lapp;AdminApplication'">
                    <xsl:attribute name="class" select="'brand admin'"/>
                </xsl:if>

                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </xsl:for-each>
        </a>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:Brand"/>

    <!-- check if agent has access to the user endpoint by executing a dummy query ASK {} -->
    <xsl:template match="rdf:RDF[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', $ldt:base))] | srx:sparql[doc-available(resolve-uri('sparql?query=ASK%20%7B%7D', $ldt:base))]" mode="bs2:SearchBar" priority="1">
        <form action="{ac:absolute-path(ldh:request-uri())}" method="get" class="navbar-form" accept-charset="UTF-8" title="{ac:label(key('resources', 'address-bar-title', document('translations.rdf')))}">
            <div>
                <input type="text" id="uri" name="uri" class="input-xxlarge"/>
            </div>
        </form>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:SearchBar"/>

    <xsl:template match="rdf:RDF | srx:sparql" mode="bs2:NavBarNavList">
        <xsl:apply-templates select="." mode="bs2:DataspaceNavList"/>

        <xsl:apply-templates select="." mode="bs2:SignUp"/>
    </xsl:template>

    <xsl:template match="rdf:RDF[lapp:origin()][key('apps-by-origin', lapp:origin(), $lapp:Context)/rdf:type/@rdf:resource = '&lapp;EndUserApplication'] | srx:sparql[lapp:origin()][key('apps-by-origin', lapp:origin(), $lapp:Context)/rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="bs2:DataspaceNavList" priority="1">
        <xsl:param name="id"  as="xs:string?"/>
        <xsl:param name="class" select="'nav pull-right'" as="xs:string?"/>

        <ul>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:variable name="user-defined-apps" select="if (doc-available($app-request-uri)) then document($app-request-uri)//*[lapp:origin/@rdf:resource] else ()" as="element()*"/>
            <xsl:variable name="system-apps" select="$lapp:Context//*[rdf:type/@rdf:resource = '&lapp;EndUserApplication'][lapp:origin/@rdf:resource]" as="element()*"/>

            <xsl:if test="exists($user-defined-apps) or exists($system-apps)">
                <li>
                    <div class="btn-group">
                        <button class="btn dropdown-toggle" title="{ac:label(key('resources', 'application-list-title', document('translations.rdf')))}">
                            <xsl:apply-templates select="key('resources', 'applications', document('translations.rdf'))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                            </xsl:apply-templates>
                        </button>
                        <ul class="dropdown-menu pull-right">
                            <xsl:if test="exists($user-defined-apps)">
                                <li class="nav-header">
                                    <xsl:value-of select="ac:label(key('resources', 'user-defined-apps', document('translations.rdf')))"/>
                                </li>
                                <xsl:for-each select="$user-defined-apps">
                                    <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                    <li>
                                        <a href="{lapp:origin/@rdf:resource}/" title="{lapp:origin/@rdf:resource}">
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </a>
                                    </li>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:if test="exists($system-apps)">
                                <xsl:if test="exists($user-defined-apps)">
                                    <li class="divider"/>
                                </xsl:if>
                                <li class="nav-header">
                                    <xsl:value-of select="ac:label(key('resources', 'system-apps', document('translations.rdf')))"/>
                                </li>
                                <xsl:for-each select="$system-apps">
                                    <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                    <li>
                                        <a href="{lapp:origin/@rdf:resource}/" title="{lapp:origin/@rdf:resource}">
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </a>
                                    </li>
                                </xsl:for-each>
                            </xsl:if>
                        </ul>
                    </div>
                </li>
            </xsl:if>
            
            <xsl:if test="$foaf:Agent//*[@rdf:about]">
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
            </xsl:if>
        </ul>        
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:DataspaceNavList"/>

    <!-- SIGNUP -->
    
    <xsl:template match="rdf:RDF[lapp:origin()][not($foaf:Agent//@rdf:about)][key('apps-by-origin', lapp:origin(), $lapp:Context)/rdf:type/@rdf:resource = '&lapp;EndUserApplication'] | srx:sparql[lapp:origin()][not($foaf:Agent//@rdf:about)][key('apps-by-origin', lapp:origin(), $lapp:Context)/rdf:type/@rdf:resource = '&lapp;EndUserApplication']" mode="bs2:SignUp" priority="1">
        <!-- resolve links against the origin URI of the admin app -->
        <xsl:param name="google-signup" select="exists($google:clientID)" as="xs:boolean"/>
        <xsl:param name="orcid-signup" select="exists($orcid:clientID)" as="xs:boolean"/>
        <xsl:param name="webid-signup" select="$ldhc:enableWebIDSignUp" as="xs:boolean"/>
        <xsl:param name="admin-origin" select="xs:anyURI(replace(string($ac:contextUri), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:param name="webid-signup-uri" select="ac:build-uri(resolve-uri('sign%20up', $admin-origin), map{ 'referer': string(ac:absolute-path(ldh:request-uri())) })" as="xs:anyURI"/>

        <!-- OAuth providers dropdown -->
        <xsl:if test="$google-signup or $orcid-signup">
            <div class="btn-group pull-right">
                <button type="button" class="btn btn-primary dropdown-toggle">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'login', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                    <xsl:text> </xsl:text>
                    <span class="caret"></span>
                </button>
                <ul class="dropdown-menu pull-right">
                    <xsl:if test="$google-signup">
                        <li>
                            <xsl:variable name="google-signup-uri" select="ac:build-uri(resolve-uri('oauth2/authorize/google', $ac:contextUri), map{ 'referer': string(ac:absolute-path(ldh:request-uri())) })" as="xs:anyURI"/>
                            <a href="{$google-signup-uri}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'login-google', document('translations.rdf'))" mode="ac:label"/>
                                </xsl:value-of>
                            </a>
                        </li>
                    </xsl:if>
                    <xsl:if test="$orcid-signup">
                        <li>
                            <xsl:variable name="orcid-signup-uri" select="ac:build-uri(resolve-uri('oauth2/authorize/orcid', $ac:contextUri), map{ 'referer': string(ac:absolute-path(ldh:request-uri())) })" as="xs:anyURI"/>
                            <a href="{$orcid-signup-uri}">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'login-orcid', document('translations.rdf'))" mode="ac:label"/>
                                </xsl:value-of>
                            </a>
                        </li>
                    </xsl:if>
                </ul>
            </div>
        </xsl:if>
        <!-- WebID signup - separate button -->
        <xsl:if test="$webid-signup">
            <div class="pull-right">
                <a class="btn btn-primary" href="{if (not(starts-with($ldt:base, lapp:origin()))) then ac:build-uri((), map{ 'uri': string($webid-signup-uri) }) else $webid-signup-uri}">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'sign-up', document('translations.rdf'))" mode="ac:label"/>
                    </xsl:value-of>
                </a>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:SignUp"/>
    
    <!-- BODY -->

    <xsl:template match="rdf:RDF[$lapp:origin] | srx:sparql[$lapp:origin]" mode="xhtml:Body" priority="1">
        <body>
            <div id="visible-body">
                <xsl:apply-templates select="." mode="bs2:NavBar"/>

                <div id="tab-body">
                    <!-- tab bar — sticky, hidden until first external tab is opened -->
                    <div id="tab-bar" class="navbar-inner" style="display: none">
                        <div class="container-fluid">
                            <div class="row-fluid">
                                <ul class="nav nav-tabs span12" id="tab-bar-list">
                                    <li data-uri="{ac:absolute-path(ldh:base-uri(.))}">
                                        <a href="{ldh:href(ac:absolute-path(ldh:base-uri(.)), ldh:build-query(ac:mode(root())))}">
                                            <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="ac:label"/>
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>

                    <!-- document content panes using Bootstrap 2.3.2 tab-content/tab-pane classes -->
                    <div id="tab-content" class="tab-content">
                        <xsl:variable name="object-uris" select="rdf:Description/*/@rdf:resource[not(key('resources', .))]" as="xs:anyURI*"/>
                        <xsl:variable name="object-metadata" as="document-node()?">
                            <xsl:if test="exists($object-uris)">
                                <xsl:try select="ldh:send-request(sd:endpoint(), 'POST', 'application/sparql-query', $object-metadata-query || ' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }', map{ 'Accept': 'application/rdf+xml' })">
                                    <xsl:catch/>
                                </xsl:try>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="local-pane" as="element()">
                            <xsl:apply-templates select="." mode="bs2:TabBody">
                                <xsl:with-param name="mode" select="ac:mode(root())"/>
                                <xsl:with-param name="base" select="ldt:base()"/>
                                <xsl:with-param name="endpoint" select="sd:endpoint()"/>
                                <xsl:with-param name="about" select="ac:absolute-path(ldh:base-uri(.))"/>
                                <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
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

                <xsl:apply-templates select="." mode="bs2:Footer"/>
            </div>

        </body>
    </xsl:template>
    
    <!-- only lookup resource locally using DESCRIBE if it's external (not relative to the app's base URI) and the agent is authenticated -->
    <xsl:template match="*[*][@rdf:about = ac:absolute-path(ldh:base-uri(.))][not(starts-with(@rdf:about, $ldt:base))][$foaf:Agent//@rdf:about]" mode="bs2:PropertyList">
        <xsl:param name="endpoint" select="sd:endpoint()" as="xs:anyURI"/>
        <xsl:param name="property-uris" select="distinct-values(*/concat(namespace-uri(), local-name()))" as="xs:anyURI*"/>
        <xsl:param name="property-metadata" select="ldh:send-request(resolve-uri('ns', $ldt:base), 'POST', 'application/sparql-query', 'DESCRIBE ' || string-join(for $uri in distinct-values(/rdf:RDF/*/*/concat(namespace-uri(), local-name())) return '&lt;' || $uri || '&gt;', ' '), map{ 'Accept': 'application/rdf+xml' })" as="document-node()"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:variable name="local-doc" select="ldh:query-result($endpoint, 'DESCRIBE &lt;' || @rdf:about || '&gt;')" as="document-node()"/>
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
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{$ldt:lang}"/>
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
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{$ldt:lang}"/>
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
                                <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            </xsl:apply-templates>
                        </dl>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
            </div>
        </xsl:if>
    </xsl:template>
   
    <!-- CONTENT HEADER -->

    <!-- hide the header of def:SelectChildren content -->
    <xsl:template match="*[*][$ldh:ajaxRendering][rdf:value/@rdf:resource = '&ldh;SelectChildren']" mode="bs2:RowContentHeader"/>
    
    <!-- ACCESS LIST ITEM -->
    
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
    
    <xsl:template match="rdf:RDF[lapp:origin()] | srx:sparql[lapp:origin()]" mode="bs2:Settings" priority="1">
        <div class="btn-group pull-right">
            <button type="button" title="{ac:label(key('resources', 'nav-bar-action-settings-title', document('translations.rdf')))}">
                <xsl:apply-templates select="key('resources', 'settings', document('translations.rdf'))" mode="ldh:logo">
                    <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                </xsl:apply-templates>
            </button>

            <ul class="dropdown-menu">
                <xsl:if test="$foaf:Agent//@rdf:about and key('apps-by-origin', lapp:origin(), $lapp:Context)/rdf:type/@rdf:resource = '&lapp;EndUserApplication'">
                    <li>
                        <button class="btn btn-app-settings">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', '&lapp;Application', document(ac:document-uri('&lapp;')))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </li>
                    <li>
                        <a href="{replace(string(lapp:origin()), '^(https?://)', '$1admin.')}" class="external" target="_blank">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'administration', document('translations.rdf'))" mode="ac:label"/>
                            </xsl:value-of>
                        </a>
                    </li>
                    <li>
                        <a href="{resolve-uri('ns', $ldt:base)}">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'namespace-ontology', document('translations.rdf'))" mode="ac:label"/>
                            </xsl:value-of>
                        </a>
                    </li>
                </xsl:if>
            </ul>
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