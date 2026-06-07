<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp       "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY def        "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY adm        "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ldh        "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY a          "https://w3id.org/atomgraph/core#">
    <!ENTITY typeahead  "http://graphity.org/typeahead#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs       "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd        "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl        "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo        "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY skos       "http://www.w3.org/2004/02/skos/core#">
    <!ENTITY srx        "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http       "http://www.w3.org/2011/http#">
    <!ENTITY acl        "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt        "https://www.w3.org/ns/ldt#">
    <!ENTITY dh         "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd         "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sh         "http://www.w3.org/ns/shacl#">
    <!ENTITY sp         "http://spinrdf.org/sp#">
    <!ENTITY dct        "http://purl.org/dc/terms/">
    <!ENTITY foaf       "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc       "http://rdfs.org/sioc/ns#">
    <!ENTITY nfo        "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY schema1    "http://schema.org/">
    <!ENTITY schema2    "https://schema.org/">
    <!ENTITY dbpo       "http://dbpedia.org/ontology/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:style="http://saxonica.com/ns/html-style-property"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:saxon="http://saxon.sf.net/"
xmlns:typeahead="&typeahead;"
xmlns:a="&a;"
xmlns:ac="&ac;"
xmlns:lapp="&lapp;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:geo="&geo;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:sd="&sd;"
xmlns:sh="&sh;"
xmlns:sp="&sp;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:skos="&skos;"
xmlns:schema1="&schema1;"
xmlns:schema2="&schema2;"
xmlns:dbpo="&dbpo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>

    <xsl:import href="../../../../com/atomgraph/client/xsl/functions.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/imports/rdf.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/imports/sp.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/document.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/container.xsl"/>
    <xsl:import href="bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/ac.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/acl.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/cert.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/ldh.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/dct.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/nfo.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/rdf.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/rdfs.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/sioc.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/sp.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/sh.xsl"/>
    <xsl:import href="bootstrap/2.3.2/document.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/services/youtube.xsl"/>
    <xsl:import href="converters/RDFXML2DataTable.xsl"/>
    <xsl:import href="converters/SPARQLXMLResults2DataTable.xsl"/>
    <xsl:import href="converters/RDFXML2GeoJSON.xsl"/>
    
    <xsl:include href="bootstrap/2.3.2/client/admin/signup.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/query-transforms.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/typeahead.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/functions.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/navigation.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/block.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/modal.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/form.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/map.xsl"/> <!-- include in view.xsl and object.xsl instead? -->
    <xsl:include href="bootstrap/2.3.2/client/graph3d.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/constructor.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/block/object.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/block/view.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/block/chart.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/block/query.xsl"/>

    <xsl:param name="ldh:ajaxRendering" select="true()" as="xs:boolean"/>
    <xsl:param name="ldh:renderSystemResources" select="false()" as="xs:boolean"/>
    <xsl:param name="ac:contextUri" as="xs:anyURI"/>
    <xsl:param name="ldt:base" as="xs:anyURI?"/> <!-- used in Web-Client TO-DO: remove -->
    <xsl:param name="ldt:ontology" as="xs:anyURI?"/> <!-- used in Web-Client TO-DO: remove -->
    <xsl:param name="acl:agent" as="xs:anyURI?"/>
    <xsl:param name="foaf:Agent" select="if ($acl:agent) then document(ac:document-uri($acl:agent)) else ()" as="document-node()?"/> <!-- should be in SaxonJS documentPool -->
    <xsl:param name="ac:lang" select="tokenize(ixsl:get(ixsl:get(ixsl:window(), 'navigator'), 'language'), '-')[1]" as="xs:string"/>
    <xsl:param name="ac:forClass" as="xs:anyURI?"/> <!-- used by Web-Client -->
    <xsl:param name="ac:query" select="ldh:query-params()?query" as="xs:string?"/>
    <xsl:param name="ac:googleMapsKey" select="''" as="xs:string"/>  <!-- cannot remove yet as it's used by container.xsl in Web-Client -->
    <xsl:param name="sparql-parser" select="ixsl:call(ixsl:window(), 'Reflect.construct', [ ixsl:get(ixsl:get(ixsl:window(), '`' || 'SPARQL.js' || '`'), 'Parser'), [] ] )"/>
    <xsl:param name="sparql-generator" select="ixsl:call(ixsl:window(), 'Reflect.construct', [ ixsl:get(ixsl:get(ixsl:window(), '`' || 'SPARQL.js' || '`'), 'Generator'), [] ] )"/>
    <xsl:param name="page-size" select="20" as="xs:integer"/>
    <xsl:param name="select-labelled-string" as="xs:string">
<![CDATA[
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX  sh:   <http://www.w3.org/ns/shacl#>
PREFIX  foaf: <http://xmlns.com/foaf/0.1/>
PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dc:   <http://purl.org/dc/elements/1.1/>
PREFIX  dct:  <http://purl.org/dc/terms/>
PREFIX  schema1: <http://schema.org/>
PREFIX  schema2: <https://schema.org/>

SELECT DISTINCT  ?resource
WHERE
  {
    {
    GRAPH ?graph
      { ?resource  a  $Type .
        ?resource rdfs:label|sh:name|dc:title|dct:title|foaf:name|foaf:givenName|foaf:familyName|sioc:name|skos:prefLabel|schema1:name|schema2:name $label
        FILTER isURI(?resource)
      }
    }
    UNION
    {
        ?resource  a  $Type .
        ?resource rdfs:label|sh:name|dc:title|dct:title|foaf:name|foaf:givenName|foaf:familyName|sioc:name|skos:prefLabel|schema1:name|schema2:name $label
        FILTER isURI(?resource)
    }
  }
ORDER BY ?label
]]>
    </xsl:param>
    <xsl:param name="backlinks-string" as="xs:string">
<![CDATA[
DESCRIBE ?subject
WHERE
  { SELECT DISTINCT  ?subject
    WHERE
      {   { ?subject  ?p  $this }
        UNION
          { GRAPH ?g
              { ?subject  ?p  $this }
          }
        FILTER isURI(?subject)
      }
    LIMIT   10
  }
]]></xsl:param>
    <xsl:param name="constraint-query" as="xs:string">
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
    </xsl:param>
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
    <xsl:param name="property-metadata-query" as="xs:string">
        <![CDATA[
            DESCRIBE $Type
        ]]>
        <!-- VALUES $Type goes here -->
    </xsl:param>
    <xsl:param name="body-id" select="'visible-body'" as="xs:string"/>
    
    <xsl:key name="resources" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>
    <xsl:key name="elements-by-class" match="*" use="tokenize(@class, ' ')"/>
    <xsl:key name="status-by-code" match="*[@rdf:about] | *[@rdf:nodeID]" use="http:statusCodeNumber/xs:integer(.)"/>

    <xsl:strip-space elements="*"/>
    
    <!-- INITIAL TEMPLATE -->
    
    <xsl:template name="main">
        <xsl:message>xsl:product-name: <xsl:value-of select="system-property('xsl:product-name')"/></xsl:message>
        <xsl:message>saxon:platform: <xsl:value-of select="system-property('saxon:platform')"/></xsl:message>
        <xsl:message>$ac:contextUri: <xsl:value-of select="$ac:contextUri"/></xsl:message>
        <xsl:message>$ac:lang: <xsl:value-of select="$ac:lang"/></xsl:message>
        <xsl:message>$acl:agent: <xsl:value-of select="$acl:agent"/></xsl:message>
        <xsl:message>ac:uri(): <xsl:value-of select="ac:uri()"/></xsl:message>
        <xsl:message>UTC offset: <xsl:value-of select="implicit-timezone()"/></xsl:message>

        <!-- create a LinkedDataHub namespace -->
        <ixsl:set-property name="LinkedDataHub" select="ldh:new-object()"/>
        <ixsl:set-property name="contents" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="typeahead" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/> <!-- used by typeahead.xsl -->
        <ixsl:set-property name="graphs" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/> <!-- used by graph3d.xsl -->
        <ixsl:set-property name="yasqe" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <!-- handle OAuth ID token from URL fragment -->
        <xsl:variable name="location-hash" select="ixsl:get(ixsl:get(ixsl:window(), 'location'), 'hash')" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="$location-hash and starts-with($location-hash, '#id_token=')">
                <xsl:variable name="id-token" select="substring-after($location-hash, '#id_token=')" as="xs:string"/>
                <xsl:variable name="href" select="xs:anyURI(substring-before(ixsl:get(ixsl:get(ixsl:window(), 'location'), 'href'), '#'))" as="xs:anyURI"/>
                <!-- set cookie with id_token -->
                <ixsl:set-property name="cookie" select="concat('LinkedDataHub.id_token=', $id-token, '; path=/; secure')" object="ixsl:page()"/>
                <!-- do a full page refresh to reload with authenticated context -->
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'location'), 'replace', [ $href ])"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- only show first time message for authenticated agents -->
                <xsl:if test="$acl:agent and not(contains(ixsl:get(ixsl:page(), 'cookie'), 'LinkedDataHub.first-time-message'))">
                    <xsl:for-each select="ixsl:page()//body">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <xsl:call-template name="ldh:FirstTimeMessage"/>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:if>
                <!-- initialize navigation (e.g. the left sidebar) -->
                <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'left-sidebar')]">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:call-template name="ldh:LeftSidebar"/>
                    </xsl:result-document>
                </xsl:for-each>
                <!-- if the URI is external, set it in the address bar -->
                <xsl:if test="ac:uri()">
                    <xsl:for-each select="id('uri', ixsl:page())">
                        <ixsl:set-property name="value" select="ac:uri()" object="."/>
                    </xsl:for-each>
                </xsl:if>

                <!-- doc URI: proxied target if ?uri= set, else local request URI; both via ac:absolute-path to drop ?query and #fragment.
                     fragment: always from the OUTER URL (ldh:request-uri()) per RFC 3986 — LDH-built URLs put the fragment outside ?uri= -->
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="if (ac:uri()) then ac:absolute-path(ac:uri()) else ac:absolute-path(ldh:request-uri())"/>
                    <xsl:with-param name="fragment" select="ac:fragment-id(ldh:request-uri())"/>
                    <xsl:with-param name="push-state" select="false()"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATES -->
  
    <!-- we don't want to include per-vocabulary stylesheets -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:label">
        <xsl:choose>
            <xsl:when test="skos:prefLabel[lang($ac:lang)]">
                <xsl:sequence select="skos:prefLabel[lang($ac:lang)]/text()"/>
            </xsl:when>
            <xsl:when test="rdfs:label[lang($ac:lang)]">
                <xsl:sequence select="rdfs:label[lang($ac:lang)]/text()"/>
            </xsl:when>
            <xsl:when test="dct:title[lang($ac:lang)]">
                <xsl:sequence select="dct:title[lang($ac:lang)]/text()"/>
            </xsl:when>
            <xsl:when test="skos:prefLabel">
                <xsl:sequence select="skos:prefLabel/text()"/>
            </xsl:when>
            <xsl:when test="rdfs:label">
                <xsl:sequence select="rdfs:label/text()"/>
            </xsl:when>
            <xsl:when test="dct:title">
                <xsl:sequence select="dct:title/text()"/>
            </xsl:when>
            <xsl:when test="foaf:name">
                <xsl:sequence select="foaf:name/text()"/>
            </xsl:when>
            <xsl:when test="foaf:givenName and foaf:familyName">
                <xsl:sequence select="concat(foaf:givenName, ' ', foaf:familyName)"/>
            </xsl:when>
            <xsl:when test="foaf:familyName">
                <xsl:sequence select="foaf:familyName/text()"/>
            </xsl:when>
            <xsl:when test="foaf:nick">
                <xsl:sequence select="foaf:nick/text()"/>
            </xsl:when>
            <xsl:when test="sioc:name">
                <xsl:sequence select="sioc:name/text()"/>
            </xsl:when>
            <xsl:when test="schema1:name">
                <xsl:sequence select="schema1:name/text()"/>
            </xsl:when>
            <xsl:when test="schema2:name">
                <xsl:sequence select="schema2:name/text()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:description">
        <xsl:choose>
            <xsl:when test="rdfs:comment[lang($ac:lang)]">
                <xsl:sequence select="rdfs:comment[lang($ac:lang)]/text()"/>
            </xsl:when>
            <xsl:when test="dct:description[lang($ac:lang)]">
                <xsl:sequence select="dct:description[lang($ac:lang)]/text()"/>
            </xsl:when>
            <xsl:when test="rdfs:comment">
                <xsl:sequence select="rdfs:comment/text()"/>
            </xsl:when>
            <xsl:when test="dct:description">
                <xsl:sequence select="dct:description/text()"/>
            </xsl:when>
            <xsl:when test="schema1:description">
                <xsl:sequence select="schema1:description/text()"/>
            </xsl:when>
            <xsl:when test="schema2:description">
                <xsl:sequence select="schema2:description/text()"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:image">
        <xsl:choose>
            <xsl:when test="foaf:img/@rdf:resource">
                <xsl:sequence select="foaf:img/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="foaf:logo/@rdf:resource">
                <xsl:sequence select="foaf:logo/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="foaf:depiction/@rdf:resource">
                <xsl:sequence select="foaf:depiction/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="schema1:image/@rdf:resource">
                <xsl:sequence select="schema1:image/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="schema1:logo/@rdf:resource">
                <xsl:sequence select="schema1:logo/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="schema2:image/@rdf:resource">
                <xsl:sequence select="schema2:image/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="schema2:logo/@rdf:resource">
                <xsl:sequence select="schema2:logo/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="schema1:thumbnailUrl/@rdf:resource">
                <xsl:sequence select="schema1:thumbnailUrl/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="schema2:thumbnailUrl/@rdf:resource">
                <xsl:sequence select="schema2:thumbnailUrl/@rdf:resource"/>
            </xsl:when>
            <xsl:when test="dbpo:thumbnail/@rdf:resource">
                <xsl:sequence select="dbpo:thumbnail/@rdf:resource"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="foaf:img/@rdf:resource | foaf:logo/@rdf:resource | foaf:depiction/@rdf:resource | schema1:image/@rdf:resource | schema2:image/@rdf:resource | schema1:logo/@rdf:resource | schema2:logo/@rdf:resource | schema1:thumbnailUrl/@rdf:resource | schema2:thumbnailUrl/@rdf:resource | dbpo:thumbnail/@rdf:resource">
        <a href="{.}">
            <img src="{.}">
                <xsl:attribute name="alt">
                    <xsl:value-of>
                        <xsl:apply-templates select="." mode="ac:object-label"/>
                    </xsl:value-of>
                </xsl:attribute>
            </img>
        </a>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <xsl:template name="ldh:PopulateBreadcrumbNav">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="response" as="map(*)"/>
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <ul class="breadcrumb pull-left"/>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:sequence select="ldh:breadcrumb-resource-response(map{
            'response': $response,
            'container': $container,
            'uri': $uri,
            'leaf': true()
        })"/>
    </xsl:template>

    <xsl:function name="ldh:rdf-document-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="fragment" select="$context('fragment')" as="xs:string?"/>
        <xsl:variable name="refresh-content" select="$context('refresh-content')" as="xs:boolean?"/>

        <xsl:for-each select="$response">
            <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

            <!-- checking acl:mode here because this template is called after every document load (also the initial load) and has access to ?headers -->
            <!-- set LinkedDataHub.acl-modes objects which are later used by the acl:mode function -->
            <!-- doing it here because this template is called after every document load (also the initial load) and has access to ?headers -->
            <xsl:variable name="acl-mode-links" select="tokenize(?headers?link, ',')[contains(., '&acl;mode')]" as="xs:string*"/>
            <xsl:variable name="acl-modes" select="for $mode-link in $acl-mode-links return xs:anyURI(substring-before(substring-after(substring-before($mode-link, ';'), '&lt;'), '&gt;'))" as="xs:anyURI*"/>
            <ixsl:set-property name="acl-modes" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <xsl:if test="$acl-modes = '&acl;Read'">
                <ixsl:set-property name="read" select="true()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.acl-modes')"/>
            </xsl:if>
            <xsl:if test="$acl-modes = '&acl;Append'">
                <ixsl:set-property name="append" select="true()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.acl-modes')"/>
            </xsl:if>
            <xsl:if test="$acl-modes = '&acl;Write'">
                <ixsl:set-property name="write" select="true()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.acl-modes')"/>
            </xsl:if>
            <xsl:if test="$acl-modes = '&acl;Control'">
                <ixsl:set-property name="control" select="true()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.acl-modes')"/>
            </xsl:if>

            <xsl:variable name="etag" select="?headers?etag" as="xs:string?"/>

            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <!-- store external SPARQL endpoint from Link header, same pattern as acl:mode above -->
                    <xsl:variable name="endpoint-link" select="tokenize(?headers?link, ',')[contains(., '&sd;endpoint')]" as="xs:string?"/>
                    <xsl:variable name="endpoint" select="if ($endpoint-link) then xs:anyURI(substring-before(substring-after(substring-before($endpoint-link, ';'), '&lt;'), '&gt;')) else ()" as="xs:anyURI?"/>
                    <xsl:if test="$endpoint">
                        <ixsl:set-property name="endpoint" select="$endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                    </xsl:if>
                    <!-- store application URI from Link header -->
                    <xsl:variable name="application-link" select="tokenize(?headers?link, ',')[contains(., '&lapp;application')]" as="xs:string?"/>
                    <xsl:variable name="application" select="if ($application-link) then xs:anyURI(substring-before(substring-after(substring-before($application-link, ';'), '&lt;'), '&gt;')) else ()" as="xs:anyURI?"/>
                    <xsl:if test="$application">
                        <ixsl:set-property name="application" select="$application" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                    </xsl:if>
                    <xsl:for-each select="?body">
                        <xsl:variable name="results" select="." as="document-node()"/>
                        <ixsl:set-property name="{'`' || $doc-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                        <!-- store document under window.LinkedDataHub.contents[$doc-uri].results -->
                        <!-- should be possible to cache the document using SaxonJS when this issue is resolved: https://saxonica.plan.io/issues/6355 -->
                        <ixsl:set-property name="results" select="." object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`')"/>
                        <!-- store ETag header value under window.LinkedDataHub.contents[$doc-uri].etag -->
                        <ixsl:set-property name="etag" select="$etag" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`')"/>

                        <xsl:variable name="tab-pane" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')]/@about = $doc-uri]" as="element()?"/>
                        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>
                        <xsl:variable name="tab-body-id" select="'tab-pane-' || ac:uuid()" as="xs:string"/>
                        <xsl:variable name="tab-base" select="if ($application) then resolve-uri('/', lapp:origin($doc-uri)) else ()" as="xs:anyURI?"/>

                        <!-- set document title from RDF; look up by the resource URI (with fragment) since SKOS Concepts etc. live at doc/#frag -->
                        <xsl:variable name="resource-uri" select="xs:anyURI($doc-uri || (if ($fragment) then '#' || $fragment else ''))" as="xs:anyURI"/>
                        <xsl:variable name="label" select="if (exists(key('resources', $resource-uri, $results))) then ac:label(key('resources', $resource-uri, $results)) else string($resource-uri)" as="xs:string"/>
                        <ixsl:set-property name="title" select="$label" object="ixsl:page()"/>

                        <!-- align URL with the mode detected from the RDF document -->
                        <xsl:call-template name="ldh:PushState">
                            <xsl:with-param name="href" select="ldh:href($doc-uri, ldh:build-query($mode), $fragment)"/>
                            <xsl:with-param name="title" select="$label"/>
                            <xsl:with-param name="container" select="id($body-id, ixsl:page())"/>
                        </xsl:call-template>

                        <!-- reuse exact-match pane, or same-origin pane (avoids accumulating panes for the same dataspace) -->
                        <xsl:variable name="reuse-pane" select="($tab-pane, id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')][starts-with(@about, lapp:origin($doc-uri))]])[1]" as="element()?"/>
                        <xsl:variable name="effective-pane-id" select="if ($reuse-pane) then $reuse-pane/@id else $tab-body-id" as="xs:string"/>

                        <!-- external-only, new pane only: add tab bar item and hide local pane -->
                        <xsl:if test="not(starts-with($doc-uri, lapp:origin(ldh:request-uri()))) and not($reuse-pane)">
                            <xsl:call-template name="ldh:AddTabNavBarListItem">
                                <xsl:with-param name="doc-uri" select="$doc-uri"/>
                                <xsl:with-param name="fragment" select="$fragment"/>
                                <xsl:with-param name="label" select="$label"/>
                                <xsl:with-param name="mode" select="$mode"/>
                            </xsl:call-template>

                            <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')][starts-with(@about, lapp:origin(ldh:request-uri()) || '/')]]">
                                <ixsl:set-style name="display" select="'none'" object="."/>
                            </xsl:for-each>
                        </xsl:if>

                        <xsl:choose>
                            <!-- pane exists: replace document-body content, leave sidebar intact -->
                            <xsl:when test="$reuse-pane">
                                <xsl:variable name="old-about" select="string($reuse-pane/div[contains-token(@class, 'document-body')]/@about)" as="xs:string"/>

                                <xsl:for-each select="$reuse-pane/div[contains-token(@class, 'document-body')]">
                                    <xsl:result-document href="?." method="ixsl:replace-element">
                                        <xsl:apply-templates select="$results/rdf:RDF" mode="bs2:DocumentBody">
                                            <xsl:with-param name="mode" select="$mode"/>
                                            <xsl:with-param name="about" select="$doc-uri"/>
                                            <xsl:with-param name="object-metadata" select="$context('object-metadata')" tunnel="yes"/>
                                            <xsl:with-param name="property-metadata" select="$context('property-metadata')" tunnel="yes"/>
                                        </xsl:apply-templates>
                                    </xsl:result-document>
                                </xsl:for-each>

                                <!-- sync the corresponding tab <li> to the new doc URI; data-uri keys downstream lookups -->
                                <xsl:if test="string($doc-uri) ne $old-about">
                                    <xsl:for-each select="id('tab-bar-list', ixsl:page())/li[ixsl:get(., 'dataset.uri') = $old-about]">
                                        <ixsl:set-attribute name="data-uri" select="string($doc-uri)" object="."/>
                                        <xsl:for-each select="a">
                                            <ixsl:set-attribute name="href" select="string(ldh:href($doc-uri, ldh:build-query($mode), $fragment))" object="."/>
                                            <ixsl:set-attribute name="title" select="string($resource-uri)" object="."/>
                                            <xsl:result-document href="?." method="ixsl:replace-content">
                                                <xsl:value-of select="$label"/>
                                            </xsl:result-document>
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </xsl:if>
                            </xsl:when>
                            <!-- no pane: create one with sidebar -->
                            <xsl:otherwise>
                                <xsl:variable name="tab-body" as="element()">
                                    <xsl:apply-templates select="$results/rdf:RDF" mode="bs2:TabBody">
                                        <xsl:with-param name="id" select="$tab-body-id"/>
                                        <xsl:with-param name="mode" select="$mode"/>
                                        <xsl:with-param name="base" select="$tab-base"/>
                                        <xsl:with-param name="endpoint" select="$endpoint"/>
                                        <xsl:with-param name="application" select="$application"/>
                                        <xsl:with-param name="about" select="$doc-uri"/>
                                        <xsl:with-param name="object-metadata" select="$context('object-metadata')" tunnel="yes"/>
                                        <xsl:with-param name="property-metadata" select="$context('property-metadata')" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:variable>

                                <xsl:result-document href="#tab-content" method="ixsl:append-content">
                                    <xsl:sequence select="$tab-body"/>
                                </xsl:result-document>

                                <!-- populate sidebar for newly created pane -->
                                <xsl:if test="$tab-base">
                                    <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][last()]/div[contains-token(@class, 'left-sidebar')]">
                                        <xsl:result-document href="?." method="ixsl:replace-content">
                                            <xsl:call-template name="ldh:LeftSidebar">
                                                <xsl:with-param name="base" select="$tab-base"/>
                                            </xsl:call-template>
                                        </xsl:result-document>
                                    </xsl:for-each>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>

                        <xsl:call-template name="ldh:RenderTab">
                            <xsl:with-param name="tab-pane-id" select="$effective-pane-id"/>
                            <xsl:with-param name="doc-uri" select="$doc-uri"/>
                            <xsl:with-param name="fragment" select="$fragment"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="response" select="$response"/>
                            <xsl:with-param name="refresh-content" select="$refresh-content"/>
                        </xsl:call-template>

                        <!-- initialize maps -->
                        <xsl:if test="key('elements-by-class', 'map-canvas', ixsl:page())">
                            <xsl:variable name="canvas-id" select="key('elements-by-class', 'map-canvas', ixsl:page())/@id" as="xs:string"/>
                            <xsl:variable name="initial-load" select="not(ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`'), 'map'))" as="xs:boolean"/>
                            <xsl:variable name="map" select="if ($initial-load) then ldh:create-map($canvas-id, 0, 0, 4) else ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`'), 'map')" as="item()"/>

                            <xsl:if test="$initial-load">
                                <ixsl:set-property name="map" select="$map" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`')"/>
                            </xsl:if>

                            <xsl:call-template name="ldh:DrawMap">
                                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                                <xsl:with-param name="initial-load" select="$initial-load"/>
                                <xsl:with-param name="map" select="$map"/>
                            </xsl:call-template>
                        </xsl:if>

                        <!-- initialize charts -->
                        <xsl:for-each select="key('elements-by-class', 'chart-canvas', ixsl:page())">
                            <xsl:variable name="canvas-id" select="@id" as="xs:string"/>
                            <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
                            <xsl:variable name="category" as="xs:string?"/>
                            <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                            <xsl:variable name="data-table" select="ac:rdf-data-table($results, $category, $series)"/>

                            <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                            <xsl:call-template name="ldh:RenderChart">
                                <xsl:with-param name="data-table" select="$data-table"/>
                                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                            </xsl:call-template>
                        </xsl:for-each>

                        <!-- initialize 3D force graphs -->
                        <xsl:for-each select="key('elements-by-class', 'graph-3d-canvas', ixsl:page())">
                            <xsl:variable name="canvas-id" select="@id" as="xs:string"/>
                            <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.graphs'), $canvas-id))">
                                <xsl:call-template name="ldh:InitDocumentGraph3D">
                                    <xsl:with-param name="canvas" select="."/>
                                    <xsl:with-param name="canvas-id" select="$canvas-id"/>
                                    <xsl:with-param name="rdf-doc" select="$results"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- LDH error responses arrive as http:Response RDF; non-LDH errors (e.g. 401 JSON from an external API) carry no RDF body, so synthesize a matching http:Response so the same render path can show the error -->
                    <xsl:variable name="results" as="document-node()">
                        <xsl:choose>
                            <xsl:when test="?media-type = 'application/rdf+xml' and exists(?body)">
                                <xsl:sequence select="?body"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="status-resource" select="key('status-by-code', xs:integer(?status), document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/http-statusCodes.rdf', lapp:origin())))" as="element()?"/>
                                <xsl:document>
                                    <rdf:RDF>
                                        <rdf:Description rdf:nodeID="error">
                                            <rdf:type rdf:resource="&http;Response"/>
                                            <http:statusCodeValue rdf:datatype="&xsd;int"><xsl:value-of select="?status"/></http:statusCodeValue>
                                            <xsl:if test="?message">
                                                <http:reasonPhrase><xsl:value-of select="?message"/></http:reasonPhrase>
                                                <dct:title><xsl:value-of select="?message"/></dct:title>
                                            </xsl:if>
                                            <xsl:if test="$status-resource">
                                                <http:sc rdf:resource="{resolve-uri($status-resource/@rdf:about, base-uri($status-resource))}"/>
                                            </xsl:if>
                                        </rdf:Description>
                                    </rdf:RDF>
                                </xsl:document>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <xsl:variable name="mode" select="xs:anyURI('&ac;ReadMode')" as="xs:anyURI"/>
                    <xsl:variable name="tab-pane" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')]/@about = $doc-uri]" as="element()?"/>
                    <xsl:variable name="tab-body-id" select="'tab-pane-' || ac:uuid()" as="xs:string"/>
                    <xsl:variable name="effective-pane-id" select="if ($tab-pane) then $tab-pane/@id else $tab-body-id" as="xs:string"/>
                    <xsl:variable name="label" select="concat('HTTP ', ?status, if (?message) then ' ' || ?message else '')" as="xs:string"/>

                    <ixsl:set-property name="title" select="$label" object="ixsl:page()"/>

                    <xsl:call-template name="ldh:PushState">
                        <xsl:with-param name="href" select="ldh:href($doc-uri, ldh:build-query($mode), $fragment)"/>
                        <xsl:with-param name="title" select="$label"/>
                        <xsl:with-param name="container" select="id($body-id, ixsl:page())"/>
                    </xsl:call-template>

                    <!-- external-only, new pane only: add tab bar item and hide local panes (mirrors the 200/RDF success path) -->
                    <xsl:if test="not(starts-with($doc-uri, lapp:origin(ldh:request-uri()))) and not($tab-pane)">
                        <xsl:call-template name="ldh:AddTabNavBarListItem">
                            <xsl:with-param name="doc-uri" select="$doc-uri"/>
                            <xsl:with-param name="fragment" select="$fragment"/>
                            <xsl:with-param name="label" select="$label"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="error" select="true()"/>
                        </xsl:call-template>

                        <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')][starts-with(@about, lapp:origin(ldh:request-uri()) || '/')]]">
                            <ixsl:set-style name="display" select="'none'" object="."/>
                        </xsl:for-each>
                    </xsl:if>

                    <xsl:choose>
                        <xsl:when test="$tab-pane">
                            <xsl:for-each select="$tab-pane/div[contains-token(@class, 'document-body')]">
                                <xsl:result-document href="?." method="ixsl:replace-element">
                                    <xsl:apply-templates select="$results/rdf:RDF" mode="bs2:DocumentBody">
                                        <xsl:with-param name="mode" select="$mode"/>
                                        <xsl:with-param name="about" select="$doc-uri"/>
                                    </xsl:apply-templates>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="tab-body" as="element()">
                                <xsl:apply-templates select="$results/rdf:RDF" mode="bs2:TabBody">
                                    <xsl:with-param name="id" select="$tab-body-id"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="about" select="$doc-uri"/>
                                </xsl:apply-templates>
                            </xsl:variable>
                            <xsl:result-document href="#tab-content" method="ixsl:append-content">
                                <xsl:sequence select="$tab-body"/>
                            </xsl:result-document>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:call-template name="ldh:RenderTab">
                        <xsl:with-param name="tab-pane-id" select="$effective-pane-id"/>
                        <xsl:with-param name="doc-uri" select="$doc-uri"/>
                        <xsl:with-param name="fragment" select="$fragment"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="response" select="$response"/>
                        <xsl:with-param name="refresh-content" select="$refresh-content"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <!-- TAB MANAGEMENT TEMPLATES -->

    <!-- Create a new tab for an external URI and render its content into #external-pane -->
    <xsl:template name="ldh:AddTabNavBarListItem">
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="fragment" as="xs:string?"/>
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="mode" as="xs:anyURI"/>
        <xsl:param name="error" select="false()" as="xs:boolean"/>

        <!-- append the new tab <li> to the tab bar; data-uri keys lookups (document scope), @href round-trips the fragment for the user -->
        <xsl:result-document href="#tab-bar-list" method="ixsl:append-content">
            <li data-uri="{$doc-uri}">
                <a href="{ldh:href($doc-uri, ldh:build-query($mode), $fragment)}" title="{$doc-uri}{if ($fragment) then '#' || $fragment else ''}">
                    <xsl:if test="$error">
                        <i class="icon-warning-sign"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$label"/>
                </a>
                <span class="tab-close">&#xd7;</span>
            </li>
        </xsl:result-document>

        <!-- show the tab bar -->
        <ixsl:set-style name="display" select="'block'" object="id('tab-bar', ixsl:page())"/>
        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:page(), 'documentElement.style'), 'setProperty', ['--action-bar-top', '98px'])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- activate an existing tab; matches pane by @about = $doc-uri (document scope, no fragment) -->
    <xsl:template match="ul[@id = 'tab-bar-list']/li" mode="ldh:ActivateTab">
        <xsl:param name="doc-uri" select="xs:anyURI(ixsl:get(., 'dataset.uri'))" as="xs:anyURI"/>

        <!-- deactivate all tab <li>s -->
        <xsl:for-each select="id('tab-bar-list', ixsl:page())/li">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'active' ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab <li> -->
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'active' ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- deactivate and hide all tab panes -->
        <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', [ 'active' ])[current-date() lt xs:date('2000-01-01')]"/>
            <ixsl:set-style name="display" select="'none'" object="."/>
        </xsl:for-each>
        <!-- activate and show tab pane -->
        <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')]/@about = $doc-uri]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', [ 'active' ])[current-date() lt xs:date('2000-01-01')]"/>
            <ixsl:set-style name="display" select="'block'" object="."/>
        </xsl:for-each>
    </xsl:template>

    <!-- render RDF results into a tab pane identified by @about = $doc-uri -->
    <!-- works for both local (#content-body) and external panes -->
    <xsl:template name="ldh:RenderTab">
        <xsl:param name="tab-pane-id" as="xs:string"/>
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="fragment" as="xs:string?"/>
        <xsl:param name="tab-list-item" select="id('tab-bar-list', ixsl:page())/li[ixsl:get(., 'dataset.uri') = $doc-uri]" as="element()?"/>
        <xsl:param name="mode" as="xs:anyURI"/>
        <xsl:param name="response" as="map(*)"/>
        <xsl:param name="refresh-content" select="()" as="xs:boolean?"/>

        <!-- activate tab list item, or show pane directly for local docs (no tab bar item) -->
        <xsl:choose>
            <xsl:when test="$tab-list-item">
                <xsl:apply-templates select="$tab-list-item" mode="ldh:ActivateTab"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'remove', ['active'])[current-date() lt xs:date('2000-01-01')]"/>
                    <ixsl:set-style name="display" select="'none'" object="."/>
                </xsl:for-each>
                <xsl:for-each select="id($tab-pane-id, ixsl:page())">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'add', ['active'])[current-date() lt xs:date('2000-01-01')]"/>
                    <ixsl:set-style name="display" select="'block'" object="."/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

        <!-- update sidebar against the now-active pane (sd:endpoint() reads its data-endpoint) -->
        <xsl:call-template name="ldh:NavigationUpdate">
            <xsl:with-param name="href" select="ldh:href($doc-uri, ldh:build-query($mode), $fragment)"/>
        </xsl:call-template>

        <!-- fire factories for top-level content blocks in the rendered pane -->
        <xsl:for-each select="id($tab-pane-id, ixsl:page())/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]/div">
            <xsl:variable name="factories" as="(function(item()?) as item()*)*">
                <xsl:apply-templates select="." mode="ldh:RenderRow">
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:for-each select="$factories">
                <xsl:variable name="factory" select="."/>
                <ixsl:promise select="$factory(())" on-failure="ldh:promise-failure#1"/>
            </xsl:for-each>
        </xsl:for-each>

        <!-- bs2:ActionBar always renders breadcrumb-nav inside bs2:ActionBarMain -->
        <xsl:variable name="pane-breadcrumb-nav" select="id($tab-pane-id, ixsl:page())//*[contains-token(@class, 'breadcrumb-nav')]" as="element()?"/>
        <xsl:if test="$pane-breadcrumb-nav">
            <xsl:call-template name="ldh:PopulateBreadcrumbNav">
                <xsl:with-param name="container" select="$pane-breadcrumb-nav"/>
                <xsl:with-param name="response" select="$response"/>
                <xsl:with-param name="uri" select="$doc-uri"/>
            </xsl:call-template>
        </xsl:if>

        <!-- scroll to the fragment-targeted element if present, otherwise to top -->
        <!-- look up the rendered RDFa resource container in the active pane via @about; sidesteps the multi-pane @id uniqueness constraint (two panes may both render a resource at the same fragment) -->
        <xsl:variable name="resource-uri" select="xs:anyURI($doc-uri || (if ($fragment) then '#' || $fragment else ''))" as="xs:anyURI"/>
        <xsl:variable name="scroll-target" as="element()?" select="if ($fragment) then (id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]//*[@about = $resource-uri])[1] else ()"/>
        <xsl:choose>
            <xsl:when test="exists($scroll-target)">
                <xsl:sequence select="ixsl:call($scroll-target, 'scrollIntoView', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'scrollTo', [ 0, 0 ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- push state -->

    <xsl:template name="ldh:PushState">
         <!-- $href has to be a proxied URI with the actual URI encoded as ?uri, otherwise we get a "DOMException: The operation is insecure" -->
        <xsl:param name="href" as="xs:anyURI"/>
        <xsl:param name="title" as="xs:string?"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="query" as="xs:string?"/>
        
        <xsl:variable name="state" as="map(xs:string, item())">
            <xsl:map>
                <xsl:map-entry key="'href'" select="$href"/>
                <xsl:map-entry key="'container-id'" select="ixsl:get($container, 'id')"/>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="state-obj" select="ixsl:call(ixsl:window(), 'JSON.parse', [ $state => serialize(map{ 'method': 'json' }) ])"/>

        <!-- push the latest state into history -->
        <xsl:sequence select="ixsl:call(ixsl:window(), 'history.pushState', [ $state-obj, $title, $href ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- switch to a tab whose pane DOM and LinkedDataHub.contents[$doc-uri] are already populated: no fetch, no re-render -->
    <xsl:template name="ldh:TabSwitch">
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="fragment" as="xs:string?"/>
        <xsl:param name="query-params" select="map{}" as="map(xs:string, xs:string*)"/>
        <xsl:param name="tab-li" as="element()"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="container" as="element()" select="id($body-id, ixsl:page())"/>

        <!-- the user has switched intent; cancel any in-flight DocumentNavigate fetch so its response doesn't reactivate the previous tab -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'saxonController')">
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.saxonController'), 'abort', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:variable name="href" select="ldh:href($doc-uri, $query-params, $fragment)" as="xs:anyURI"/>

        <!-- address bar shows the resource URI (with fragment) for external, blank for local -->
        <xsl:for-each select="id('uri', ixsl:page())">
            <xsl:choose>
                <xsl:when test="not(starts-with($doc-uri, lapp:origin(ldh:request-uri()) || '/'))">
                    <ixsl:set-property name="value" select="$doc-uri || (if ($fragment) then '#' || $fragment else '')" object="."/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-property name="value" select="''" object="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:if test="$push-state">
            <xsl:call-template name="ldh:PushState">
                <xsl:with-param name="href" select="$href"/>
                <xsl:with-param name="title" select="()"/>
                <xsl:with-param name="container" select="$container"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:apply-templates select="$tab-li" mode="ldh:ActivateTab">
            <xsl:with-param name="doc-uri" select="$doc-uri"/>
        </xsl:apply-templates>

        <xsl:call-template name="ldh:NavigationUpdate">
            <xsl:with-param name="href" select="$href"/>
        </xsl:call-template>

        <!-- scroll to the fragment-targeted element if present, otherwise to top -->
        <!-- look up the rendered RDFa resource container in the active pane via @about; sidesteps the multi-pane @id uniqueness constraint (two panes may both render a resource at the same fragment) -->
        <xsl:variable name="resource-uri" select="xs:anyURI($doc-uri || (if ($fragment) then '#' || $fragment else ''))" as="xs:anyURI"/>
        <xsl:variable name="scroll-target" as="element()?" select="if ($fragment) then (id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]//*[@about = $resource-uri])[1] else ()"/>
        <xsl:choose>
            <xsl:when test="exists($scroll-target)">
                <xsl:sequence select="ixsl:call($scroll-target, 'scrollIntoView', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'scrollTo', [ 0, 0 ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- document navigation: handles local/external branching -->

    <xsl:template name="ldh:DocumentNavigate">
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="fragment" as="xs:string?"/>
        <xsl:param name="query-params" select="map{}" as="map(xs:string, xs:string*)"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="container" as="element()" select="id($body-id, ixsl:page())"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'saxonController')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.saxonController'), 'abort', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        <xsl:variable name="controller" select="ixsl:abort-controller()"/>
        <ixsl:set-property name="saxonController" select="$controller" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="href" select="ldh:href($doc-uri, $query-params, $fragment)" as="xs:anyURI"/>

        <!-- update address bar input: show resource URI (with fragment) for external, clear for local docs -->
        <!-- use browser origin (not ldt:base()) so the check is correct even when an external tab is active: ldt:base() reads the active pane's data-base, which would mis-classify same-origin proxy URIs as "local" and cross-dataspace URIs as "external" mid-switch -->
        <xsl:for-each select="id('uri', ixsl:page())">
            <xsl:choose>
                <xsl:when test="not(starts-with($doc-uri, lapp:origin(ldh:request-uri()) || '/'))">
                    <ixsl:set-property name="value" select="$doc-uri || (if ($fragment) then '#' || $fragment else '')" object="."/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-property name="value" select="''" object="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!-- hide local tab pane for external URIs -->
        <xsl:if test="not(starts-with($doc-uri, lapp:origin(ldh:request-uri()) || '/'))">
            <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')]/@about = ac:absolute-path(ldh:request-uri())]">
                <ixsl:set-style name="display" select="'none'" object="."/>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$push-state">
            <xsl:call-template name="ldh:PushState">
                <xsl:with-param name="href" select="$href"/>
                <xsl:with-param name="title" select="()"/>
                <xsl:with-param name="container" select="$container"/>
            </xsl:call-template>

            <!-- keep the matching tab's @href in lockstep with the address bar; data-uri is the document URI -->
            <xsl:for-each select="id('tab-bar-list', ixsl:page())/li[ixsl:get(., 'dataset.uri') = string($doc-uri)]/a">
                <ixsl:set-attribute name="href" select="string($href)" object="."/>
            </xsl:for-each>
        </xsl:if>

        <xsl:call-template name="ldh:RDFDocumentLoad">
            <xsl:with-param name="doc-uri" select="$doc-uri"/>
            <xsl:with-param name="fragment" select="$fragment"/>
            <xsl:with-param name="controller" select="$controller"/>
        </xsl:call-template>
    </xsl:template>

    <!-- load RDF document -->

    <xsl:template name="ldh:RDFDocumentLoad">
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="fragment" as="xs:string?"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <xsl:param name="controller" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'saxonController')"/>
        <!-- if the URI is external, dereference it through the proxy -->
        <!-- HTTP requests carry no fragment (protocol-level) -->
        <xsl:variable name="request-uri" select="ldh:href($doc-uri, map{}, ())" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'doc-uri': $doc-uri,
            'fragment': $fragment,
            'refresh-content': $refresh-content,
            'endpoint': sd:endpoint()
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request'), $controller) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:load-object-metadata#1) =>
            ixsl:then(ldh:http-request-threaded(?, 'metadata-request', 'metadata-response')) =>
            ixsl:then(ldh:handle-response(?, 'metadata-response')) =>
            ixsl:then(ldh:set-object-metadata#1) =>
            ixsl:then(ldh:load-property-metadata#1) =>
            ixsl:then(ldh:http-request-threaded(?, 'property-metadata-request', 'property-metadata-response')) =>
            ixsl:then(ldh:handle-response(?, 'property-metadata-response')) =>
            ixsl:then(ldh:set-property-metadata#1) =>
            ixsl:then(ldh:rdf-document-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- EVENT LISTENERS -->

    <!-- popstate -->
    
    <xsl:template match="." mode="ixsl:onpopstate">
        <xsl:variable name="state" select="ixsl:get(ixsl:event(), 'state')"/>
        <xsl:if test="not(empty($state))">
            <xsl:variable name="href" select="map:get($state, 'href')" as="xs:anyURI?"/>

            <!-- strip URL fragment before parsing query so it doesn't get glued onto the last query value -->
            <xsl:variable name="query-params" select="ldh:parse-query-params(substring-after(ac:document-uri($href), '?'))" as="map(xs:string, xs:string*)"/>
            <xsl:variable name="doc-uri" select="ac:absolute-path(if (map:contains($query-params, 'uri')) then xs:anyURI(map:get($query-params, 'uri')) else $href)" as="xs:anyURI"/>
            <!-- fragment lives on the OUTER URL per RFC 3986 -->
            <xsl:variable name="fragment" select="ac:fragment-id($href)" as="xs:string?"/>
            <xsl:variable name="tab-li" select="id('tab-bar-list', ixsl:page())/li[ixsl:get(., 'dataset.uri') = string($doc-uri)]" as="element()?"/>

            <xsl:choose>
                <xsl:when test="exists($tab-li) and ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`') and deep-equal(map:remove($query-params, 'uri'), map:remove(ldh:query-params(), 'uri'))">
                    <xsl:call-template name="ldh:TabSwitch">
                        <xsl:with-param name="doc-uri" select="$doc-uri"/>
                        <xsl:with-param name="fragment" select="$fragment"/>
                        <xsl:with-param name="query-params" select="map:remove($query-params, 'uri')"/>
                        <xsl:with-param name="tab-li" select="$tab-li"/>
                        <xsl:with-param name="push-state" select="false()"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="ldh:DocumentNavigate">
                        <xsl:with-param name="doc-uri" select="$doc-uri"/>
                        <xsl:with-param name="fragment" select="$fragment"/>
                        <xsl:with-param name="query-params" select="map:remove($query-params, 'uri')"/>
                        <xsl:with-param name="push-state" select="false()"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- do not intercept RDF download links -->
    <xsl:template match="button[@id = 'export-rdf']/following-sibling::ul//a" mode="ixsl:onclick" priority="1"/>
    
    <!-- intercept all HTML and SVG link clicks except to /uploads/ and those in the navbar (except breadcrumb bar, .brand and app list) and the footer -->
    <!-- resolve URLs against the current document URL because they can be relative -->
    <xsl:template match="a[not(@target)][starts-with(resolve-uri(@href, ldh:base-uri(.)), 'http://') or starts-with(resolve-uri(@href, ldh:base-uri(.)), 'https://')][not(starts-with(resolve-uri(@href, ldh:base-uri(.)), resolve-uri('uploads/', ldt:base())))][ancestor::div[contains-token(@class, 'breadcrumb-nav')] or not(ancestor::div[tokenize(@class, ' ') = ('navbar', 'footer')])] | a[contains-token(@class, 'brand')] | div[button[contains-token(@class, 'btn-apps')]]/ul//a | svg:a[not(@target)][starts-with(resolve-uri(@href, ldh:base-uri(.)), 'http://') or starts-with(resolve-uri(@href, ldh:base-uri(.)), 'https://')][not(starts-with(resolve-uri(@href, ldh:base-uri(.)), resolve-uri('uploads/', ldt:base())))]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <!-- resolve link href against base; ac:document-uri strips the URL's fragment so it doesn't corrupt query parsing -->
        <xsl:variable name="href" select="xs:anyURI(resolve-uri(@href, ldh:base-uri(.)))" as="xs:anyURI"/>
        <xsl:variable name="query-params" select="ldh:parse-query-params(substring-after(ac:document-uri($href), '?'))" as="map(xs:string, xs:string*)"/>
        <!-- proxied link: doc URI is the ?uri= value; local link: doc URI is $href without query/fragment -->
        <xsl:variable name="doc-uri" select="ac:absolute-path(if (map:contains($query-params, 'uri')) then xs:anyURI(map:get($query-params, 'uri')) else $href)" as="xs:anyURI"/>
        <!-- fragment lives on the OUTER URL per RFC 3986 / ldh:href convention -->
        <xsl:variable name="fragment" select="ac:fragment-id($href)" as="xs:string?"/>

        <xsl:variable name="tab-li" select="id('tab-bar-list', ixsl:page())/li[ixsl:get(., 'dataset.uri') = string($doc-uri)]" as="element()?"/>

        <xsl:choose>
            <!-- same-doc cached AND non-uri query params unchanged: switch (no fetch, no re-render), just scroll to the new fragment if any -->
            <xsl:when test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`') and exists($tab-li) and deep-equal(map:remove($query-params, 'uri'), map:remove(ldh:query-params(), 'uri'))">
                <xsl:call-template name="ldh:TabSwitch">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="query-params" select="map:remove($query-params, 'uri')"/>
                    <xsl:with-param name="tab-li" select="$tab-li"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="query-params" select="map:remove($query-params, 'uri')"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="form[contains-token(@class, 'navbar-form')]" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="uri-string" select=".//input[@name = 'uri']/ixsl:get(., 'value')" as="xs:string?"/>

        <!-- ignore form submission if the input value is not a valid http(s):// URI -->
        <xsl:if test="$uri-string castable as xs:anyURI and (starts-with($uri-string, 'http://') or starts-with($uri-string, 'https://'))">
            <xsl:variable name="resource-uri" select="xs:anyURI($uri-string)" as="xs:anyURI"/>

            <xsl:call-template name="ldh:DocumentNavigate">
                <xsl:with-param name="doc-uri" select="ac:absolute-path($resource-uri)"/>
                <xsl:with-param name="fragment" select="ac:fragment-id($resource-uri)"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="onDelete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="doc-uri" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="?status = 204"> <!-- No Content -->
                <!-- parent directory; no fragment relevant here -->
                <xsl:variable name="parent-doc-uri" select="resolve-uri('..', $doc-uri)" as="xs:anyURI"/>

                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$parent-doc-uri"/>
                    <xsl:with-param name="fragment" select="()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- open drop-down by toggling its CSS class -->

    <xsl:template match="*[contains-token(@class, 'btn-group')][*[contains-token(@class, 'dropdown-toggle')]]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'open' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-delete')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="request-uri" select="ldh:href(ac:absolute-path(ldh:base-uri(.)), map{})" as="xs:anyURI"/>

        <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', lapp:origin())))) ])">
            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'DELETE', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                    <xsl:call-template name="onDelete">
                        <xsl:with-param name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- content tabs (markup from Bootstrap) -->
    
    <xsl:template match="div[contains-token(@class, 'tabbable')]/ul[contains-token(@class, 'nav-tabs')]/li/a" mode="ixsl:onclick">
        <!-- deactivate other tabs -->
        <xsl:for-each select="../../li">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="..">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- deactivate other tab panes -->
        <xsl:for-each select="../../following-sibling::*[contains-token(@class, 'tab-content')]/*[contains-token(@class, 'tab-pane')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="../../following-sibling::*[contains-token(@class, 'tab-content')]/*[contains-token(@class, 'tab-pane')][count(preceding-sibling::*[contains-token(@class, 'tab-pane')]) = count(current()/../preceding-sibling::li)]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- copy resource's URI into clipboard -->
    
    <xsl:template match="button[contains-token(@class, 'btn-copy-uri')]" mode="ixsl:onclick">
        <!-- get resource URI from its heading title attribute, both in bs2:Actions and bs2:FormControl mode -->
        <xsl:variable name="uri-or-bnode" select="../../h2/a/@title | ../following-sibling::div//input[@name = ('su', 'sb')]/@value" as="xs:string"/>
        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'navigator.clipboard'), 'writeText', [ $uri-or-bnode ])"/>
    </xsl:template>

    <!-- open a form to save RDF document (do nothing if the button is disabled) -->
    
    <xsl:template match="button[contains-token(@class, 'btn-save-as')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="target" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]" as="element()"/>
        <xsl:variable name="graph" select="ldh:base-uri(.)" as="xs:anyURI"/>

        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:AddDataForm">
                    <xsl:with-param name="source" select="$graph"/> <!-- the arg should really be the RDF/XML document-node() -->
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="target" select="$target"/>
        </xsl:call-template>

        <xsl:call-template name="ldh:LoadTypeaheads">
            <xsl:with-param name="typeahead-spans" select="(id('upload-rdf-doc', ixsl:page())/.., id('remote-rdf-doc', ixsl:page())/..)"/>
            <xsl:with-param name="graph" select="$graph"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- tab bar: click on a tab link to activate it -->
    <xsl:template match="ul[@id = 'tab-bar-list']/li[not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="href" select="xs:anyURI(resolve-uri(@href, ldh:base-uri(.)))" as="xs:anyURI"/>
        <!-- ac:document-uri strips the URL's fragment so it doesn't get glued onto the last query value -->
        <xsl:variable name="query-params" select="ldh:parse-query-params(substring-after(ac:document-uri($href), '?'))" as="map(xs:string, xs:string*)"/>
        <!-- proxied tab: doc URI is the ?uri= value; local tab: doc URI is $href without query/fragment -->
        <xsl:variable name="doc-uri" select="ac:absolute-path(if (map:contains($query-params, 'uri')) then xs:anyURI(map:get($query-params, 'uri')) else $href)" as="xs:anyURI"/>
        <!-- fragment lives on the OUTER URL per RFC 3986 / ldh:href convention -->
        <xsl:variable name="fragment" select="ac:fragment-id($href)" as="xs:string?"/>

        <xsl:choose>
            <!-- cache populated AND non-uri query params unchanged: pure CSS toggle + scroll, no fetch, no re-render -->
            <xsl:when test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`') and deep-equal(map:remove($query-params, 'uri'), map:remove(ldh:query-params(), 'uri'))">
                <xsl:call-template name="ldh:TabSwitch">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="query-params" select="map:remove($query-params, 'uri')"/>
                    <xsl:with-param name="tab-li" select=".."/>
                    <xsl:with-param name="container" select=".."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="fragment" select="$fragment"/>
                    <xsl:with-param name="query-params" select="map:remove($query-params, 'uri')"/>
                    <xsl:with-param name="container" select=".."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ul[@id = 'tab-bar-list']/li/span[contains-token(@class, 'tab-close')]" mode="ixsl:onclick">
        <xsl:variable name="tab-li" select=".." as="element()"/>
        <xsl:variable name="doc-uri" select="xs:anyURI(ixsl:get($tab-li, 'dataset.uri'))" as="xs:anyURI"/>
        <xsl:variable name="was-active" select="contains-token($tab-li/@class, 'active')" as="xs:boolean"/>

        <!-- pick fallback BEFORE removing this li; prefer previous sibling, fall back to next -->
        <xsl:variable name="fallback-li" select="($tab-li/preceding-sibling::li[1], $tab-li/following-sibling::li[1])[1]" as="element()?"/>

        <!-- remove the associated tab pane (matched by document-body/@about = $doc-uri) -->
        <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][./div[contains-token(@class, 'document-body')]/@about = $doc-uri]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <!-- remove the tab <li> from the DOM -->
        <xsl:sequence select="ixsl:call($tab-li, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- if the closed tab was active, switch to the fallback (TabSwitch if cached; otherwise DocumentNavigate → RenderTab will activate after fetch) -->
        <xsl:if test="$was-active and $fallback-li">
            <xsl:variable name="fallback-href" select="xs:anyURI(resolve-uri($fallback-li/a/@href, ldh:base-uri(.)))" as="xs:anyURI"/>
            <xsl:variable name="fallback-query-params" select="ldh:parse-query-params(substring-after(ac:document-uri($fallback-href), '?'))" as="map(xs:string, xs:string*)"/>
            <xsl:variable name="fallback-doc-uri" select="ac:absolute-path(if (map:contains($fallback-query-params, 'uri')) then xs:anyURI(map:get($fallback-query-params, 'uri')) else $fallback-href)" as="xs:anyURI"/>
            <xsl:variable name="fallback-fragment" select="ac:fragment-id($fallback-href)" as="xs:string?"/>

            <xsl:choose>
                <xsl:when test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $fallback-doc-uri || '`') and deep-equal(map:remove($fallback-query-params, 'uri'), map:remove(ldh:query-params(), 'uri'))">
                    <xsl:call-template name="ldh:TabSwitch">
                        <xsl:with-param name="doc-uri" select="$fallback-doc-uri"/>
                        <xsl:with-param name="fragment" select="$fallback-fragment"/>
                        <xsl:with-param name="query-params" select="map:remove($fallback-query-params, 'uri')"/>
                        <xsl:with-param name="tab-li" select="$fallback-li"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="ldh:DocumentNavigate">
                        <xsl:with-param name="doc-uri" select="$fallback-doc-uri"/>
                        <xsl:with-param name="fragment" select="$fallback-fragment"/>
                        <xsl:with-param name="query-params" select="map:remove($fallback-query-params, 'uri')"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <!-- if only the base-uri tab is left, hide the whole tab-bar (mirror of ldh:AddTabNavBarListItem) -->
        <xsl:if test="count(id('tab-bar-list', ixsl:page())/li) le 1">
            <ixsl:set-style name="display" select="'none'" object="id('tab-bar', ixsl:page())"/>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:page(), 'documentElement.style'), 'removeProperty', ['--action-bar-top'])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- file drop -->

    <xsl:template match="div[acl:mode() = '&acl;Write']" mode="ixsl:ondragover">
        <xsl:variable name="uri" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>
        
        <xsl:if test="$mode = xs:anyURI('&ac;ReadMode')">
            <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="div[acl:mode() = '&acl;Write']" mode="ixsl:ondrop">
        <xsl:variable name="uri" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>
        
        <xsl:if test="$mode = xs:anyURI('&ac;ReadMode')">
            <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
            <xsl:variable name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI"/>
            <xsl:variable name="rdf-media-types" as="map(xs:string, xs:string)">
                <xsl:map>
                    <xsl:map-entry key="'nt'" select="'application/n-triples'"/>
                    <xsl:map-entry key="'ttl'" select="'text/turtle'"/>
                    <xsl:map-entry key="'rdf'" select="'application/rdf+xml'"/>
                    <xsl:map-entry key="'owl'" select="'application/rdf+xml'"/>
                    <xsl:map-entry key="'jsonld'" select="'application/ld+json'"/>
                </xsl:map>
            </xsl:variable>

            <xsl:if test="ixsl:get(ixsl:get(ixsl:event(), 'dataTransfer'), 'files.length') gt 0">
                <xsl:message>
                    <xsl:variable name="files" select="ixsl:get(ixsl:get(ixsl:event(), 'dataTransfer'), 'files')"/>
                    <xsl:for-each select="0 to xs:integer(ixsl:get($files, 'length')) - 1">
                        <xsl:variable name="file" select="map:get($files, .)"/>
                        <xsl:variable name="file-ext" select="replace(ixsl:get($file, 'name'), '.*\.', '')" as="xs:string?"/>
                        <xsl:variable name="file-type" select="if (ixsl:contains($file, 'type')) then ixsl:get($file, 'type') else ()" as="xs:string?"/>

                        <xsl:choose>
                            <!-- file extension is a map key or media type is a map value -->
                            <xsl:when test="map:contains($rdf-media-types, $file-ext) or $file-type = $rdf-media-types?*">
                                <!-- attempt to infer RDF media type from file extension first, fallback to file type -->
                                <xsl:variable name="media-type" select="if (map:contains($rdf-media-types, $file-ext)) then map:get($rdf-media-types, $file-ext) else $file-type" as="xs:string"/>
                                <xsl:message>Importing RDF file. Name: '<xsl:value-of select="ixsl:get($file, 'name')"/>' Media type: '<xsl:value-of select="$media-type"/>'</xsl:message>

                                <xsl:variable name="headers" select="ldh:new-object()"/>
                                <ixsl:set-property name="Content-Type" select="$media-type" object="$headers"/>
                                <ixsl:set-property name="Accept" select="'application/rdf+xml'" object="$headers"/>

                                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                                <xsl:sequence select="js:fetchDispatchXML($base-uri, 'POST', $headers, $file, ., (), (), (), 'RDFFileUpload')[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'The file extension or media type is not a supported RDF triple syntax' ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:message>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- this callback will be invoked for every uploaded file -->
    
    <xsl:template match="." mode="ixsl:onRDFFileUpload">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="response" select="ixsl:get(ixsl:get($event, 'detail'), 'response')"/>
        <xsl:variable name="status" select="ixsl:get($response, 'status')" as="xs:double"/>
        
        <xsl:choose>
            <xsl:when test="$status = (200, 204)">
                <!-- post-upload reload of the current document; ldh:base-uri already strips fragment -->
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="ldh:base-uri(.)"/>
                    <xsl:with-param name="fragment" select="()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:variable name="message" select="ixsl:get($response, 'statusText')" as="xs:string"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ $message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>