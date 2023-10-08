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
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
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

    <xsl:import href="bootstrap/2.3.2/imports/xml-to-string.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/RDFXML2SVG.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/functions.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/container.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/ac.xsl"/>
    <xsl:import href="bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="bootstrap/2.3.2/document.xsl"/>
    <xsl:import href="converters/RDFXML2DataTable.xsl"/>
    <xsl:import href="converters/SPARQLXMLResults2DataTable.xsl"/>
    <xsl:import href="converters/RDFXML2GeoJSON.xsl"/>
    <xsl:import href="query-transforms.xsl"/>
    <xsl:import href="typeahead.xsl"/>

    <xsl:include href="bootstrap/2.3.2/client/functions.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/navigation.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/content.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/modal.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/chart.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/container.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/form.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/map.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/graph.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/sparql.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/constructor.xsl"/>
    
    <xsl:param name="ac:contextUri" as="xs:anyURI"/>
    <xsl:param name="ldt:base" as="xs:anyURI"/>
    <xsl:param name="ldt:ontology" as="xs:anyURI"/> <!-- used in default.xsl -->
    <xsl:param name="acl:agent" as="xs:anyURI?"/>
    <xsl:param name="sd:endpoint" as="xs:anyURI?"/>
    <xsl:param name="ldh:absolutePath" as="xs:anyURI"/>
    <xsl:param name="app-request-uri" as="xs:anyURI"/>
    <xsl:param name="ldh:apps" as="document-node()">
        <xsl:document>
            <rdf:RDF></rdf:RDF>
        </xsl:document>
    </xsl:param>
    <xsl:param name="ac:lang" select="ixsl:get(ixsl:get(ixsl:page(), 'documentElement'), 'lang')" as="xs:string"/>
    <xsl:param name="ac:mode" select="if (ixsl:query-params()?mode) then xs:anyURI(ixsl:query-params()?mode) else xs:anyURI('&ac;ReadMode')" as="xs:anyURI*"/>
    <xsl:param name="ac:query" select="ixsl:query-params()?query" as="xs:string?"/>
    <xsl:param name="ac:googleMapsKey" select="''" as="xs:string"/>  <!-- cannot remove yet as it's used by container.xsl in Web-Client -->
    <xsl:param name="page-size" select="20" as="xs:integer"/>
    <xsl:param name="select-labelled-string" as="xs:string">
<![CDATA[
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  skos: <http://www.w3.org/2004/02/skos/core#>
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
            ?resource ((((((((rdfs:label|dc:title)|dct:title)|foaf:name)|foaf:givenName)|foaf:familyName)|sioc:name)|skos:prefLabel)|schema1:name)|schema2:name $label
            FILTER isURI(?resource)
          }
    }
    UNION
    {
        ?resource  a  $Type .
        ?resource ((((((((rdfs:label|dc:title)|dct:title)|foaf:name)|foaf:givenName)|foaf:familyName)|sioc:name)|skos:prefLabel)|schema1:name)|schema2:name $label
        FILTER isURI(?resource)
    }  
  }
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
    <xsl:param name="force-exclude-all-namespaces" select="true()"/> <!-- used by xml-to-string.xsl -->
    <xsl:param name="system-containers" as="map(xs:anyURI, map(xs:string, xs:string))">
        <xsl:map>
            <xsl:map-entry key="resolve-uri('apps/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-app'"/>
                    <xsl:map-entry key="'label-id'" select="'applications'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('charts/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-chart'"/>
                    <xsl:map-entry key="'label-id'" select="'charts'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('files/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-file'"/>
                    <xsl:map-entry key="'label-id'" select="'files'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('geo/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-geo'"/>
                    <xsl:map-entry key="'label-id'" select="'geo'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('imports/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-import'"/>
                    <xsl:map-entry key="'label-id'" select="'imports'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('latest/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-latest'"/>
                    <xsl:map-entry key="'label-id'" select="'latest'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('queries/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-query'"/>
                    <xsl:map-entry key="'label-id'" select="'queries'"/>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="resolve-uri('services/', $ldt:base)">
                <xsl:map>
                    <xsl:map-entry key="'class'" select="'btn-service'"/>
                    <xsl:map-entry key="'label-id'" select="'services'"/>
                </xsl:map>
            </xsl:map-entry>
        </xsl:map>
    </xsl:param>
    <xsl:param name="body-id" select="'visible-body'" as="xs:string"/>
    
    <xsl:key name="resources" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>
    <xsl:key name="elements-by-class" match="*" use="tokenize(@class, ' ')"/>
    <xsl:key name="violations-by-value" match="*" use="ldh:violationValue/text()"/>
    <xsl:key name="violations-by-focus-node" match="*" use="sh:focusNode/@rdf:resource | sh:focusNode/@rdf:nodeID"/>
    <xsl:key name="resources-by-container" match="*[@rdf:about] | *[@rdf:nodeID]" use="sioc:has_parent/@rdf:resource | sioc:has_container/@rdf:resource"/>
    <xsl:key name="status-by-code" match="*[@rdf:about] | *[@rdf:nodeID]" use="http:statusCodeNumber/xs:integer(.)"/>

    <xsl:strip-space elements="*"/>
    
    <!-- INITIAL TEMPLATE -->
    
    <xsl:template name="main">
        <xsl:message>xsl:product-name: <xsl:value-of select="system-property('xsl:product-name')"/></xsl:message>
        <xsl:message>saxon:platform: <xsl:value-of select="system-property('saxon:platform')"/></xsl:message>
        <xsl:message>$ac:contextUri: <xsl:value-of select="$ac:contextUri"/></xsl:message>
        <xsl:message>$ldt:base: <xsl:value-of select="$ldt:base"/></xsl:message>
        <xsl:message>$ldh:absolutePath: <xsl:value-of select="$ldh:absolutePath"/></xsl:message>
        <xsl:message>$acl:agent: <xsl:value-of select="$acl:agent"/></xsl:message>
        <xsl:message>count($ldh:apps//*[rdf:type/@rdf:resource = '&sd;Service']): <xsl:value-of select="count($ldh:apps//*[rdf:type/@rdf:resource = '&sd;Service'])"/></xsl:message>
        <xsl:message>$ac:lang: <xsl:value-of select="$ac:lang"/></xsl:message>
        <xsl:message>$ac:mode: <xsl:value-of select="$ac:mode"/></xsl:message>
        <xsl:message>$sd:endpoint: <xsl:value-of select="$sd:endpoint"/></xsl:message>
        <xsl:message>ixsl:query-params()?uri: <xsl:value-of select="ixsl:query-params()?uri"/></xsl:message>
        <xsl:message>UTC offset: <xsl:value-of select="implicit-timezone()"/></xsl:message>
        
        <!-- create a LinkedDataHub namespace -->
        <ixsl:set-property name="LinkedDataHub" select="ldh:new-object()"/>
        <ixsl:set-property name="base" select="$ldt:base" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="contents" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="typeahead" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/> <!-- used by typeahead.xsl -->
        <ixsl:set-property name="graph" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/> <!-- used by graph.xsl -->
        <ixsl:set-property name="endpoint" select="$sd:endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="yasqe" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <xsl:apply-templates select="ixsl:page()" mode="ldh:HTMLDocumentLoaded">
            <xsl:with-param name="href" select="ldh:href()"/>
            <xsl:with-param name="endpoint" select="$sd:endpoint"/>
            <xsl:with-param name="container" select="id($body-id, ixsl:page())"/>
            <xsl:with-param name="replace-content" select="false()"/>
        </xsl:apply-templates>
        <!-- disable SPARQL editor's server-side submission -->
        <xsl:for-each select="ixsl:page()//button[contains(@class, 'btn-run-query')]"> <!-- TO-DO: use the 'elements-by-class' key -->
            <ixsl:set-attribute name="type" select="'button'"/> <!-- instead of "submit" -->
        </xsl:for-each>
        <!-- only show first time message for authenticated agents -->
        <xsl:if test="$acl:agent and not(contains(ixsl:get(ixsl:page(), 'cookie'), 'LinkedDataHub.first-time-message'))">
            <xsl:for-each select="ixsl:page()//body">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:call-template name="ldh:FirstTimeMessage"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
        <!-- initialize form if we're in editing mode -->
        <xsl:if test="ac:mode() = '&ac;EditMode'">
            <xsl:apply-templates select="id('content-body', ixsl:page())" mode="ldh:PostConstruct"/>
        </xsl:if>
        <!-- initialize LinkedDataHub.apps (and the search dropdown, if it's shown) -->
        <ixsl:set-property name="apps" select="$ldh:apps" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <!-- #search-service may be missing (e.g. suppressed by extending stylesheet) -->
        <xsl:for-each select="id('search-service', ixsl:page())">
            <xsl:call-template name="ldh:RenderServices">
                <xsl:with-param name="select" select="."/>
                <xsl:with-param name="apps" select="$ldh:apps"/>
            </xsl:call-template>
        </xsl:for-each>
        <!-- initialize document tree -->
        <xsl:for-each select="id('doc-tree', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="ldh:DocTree"/>
            </xsl:result-document>
            <xsl:call-template name="ldh:DocTreeActivateHref">
                <xsl:with-param name="href" select="ldh:href()"/>
            </xsl:call-template>
        </xsl:for-each>
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
    
    <!-- copied from rdf.xsl which is not imported -->
    <xsl:template match="rdf:type/@rdf:resource" priority="1">
        <span title="{.}" class="btn btn-type">
            <xsl:next-match/>
        </span>
    </xsl:template>
    
    <!-- if document has a topic, show it as the typeahead value instead -->
    <xsl:template match="*[*][key('resources', foaf:primaryTopic/@rdf:resource)]" mode="ldh:Typeahead">
        <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="#current"/>
    </xsl:template>
    
    <!-- classes for system container breadcrumbs -->
    
    <xsl:template match="*[@rdf:about = map:keys($system-containers)]" mode="bs2:BreadCrumbListItem" priority="1">
        <xsl:param name="leaf" select="true()" as="xs:boolean"/>

        <li>
            <a href="{@rdf:about}" class="btn-logo {map:get($system-containers, @rdf:about)?class}">
                <xsl:apply-templates select="key('resources', map:get($system-containers, @rdf:about)?label-id, document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </a>

            <xsl:if test="not($leaf)">
                <span class="divider">/</span>
            </xsl:if>
        </li>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <!-- ontology loaded -->
<!--    <xsl:template name="ixsl:onOntologyLoad">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:for-each select="?status">
            <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ . ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>-->
        
    <xsl:template name="ldh:RDFDocumentLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>

        <!-- load breadcrumbs -->
        <xsl:if test="id('breadcrumb-nav', ixsl:page())">
            <xsl:result-document href="#breadcrumb-nav" method="ixsl:replace-content">
                <!-- show label if the resource is external -->
                <xsl:if test="not(starts-with($uri, $ldt:base))">
                    <xsl:variable name="app" select="ldh:match-app($uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
                    <xsl:choose>
                        <!-- if a known app matches $uri, show link to its ldt:base -->
                        <xsl:when test="$app">
                            <a href="{$app/ldt:base/@rdf:resource}" class="label label-info pull-left">
                                <xsl:apply-templates select="$app" mode="ac:label"/>
                            </a>
                        </xsl:when>
                        <!-- otherwise show just a label with the hostname -->
                        <xsl:otherwise>
                            <xsl:variable name="hostname" select="tokenize(substring-after($uri, '://'), '/')[1]" as="xs:string"/>
                            <span class="label label-info pull-left">
                                <xsl:value-of select="$hostname"/>
                            </span>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>

                <ul class="breadcrumb pull-left">
                    <!-- list items will be injected by ldh:BreadCrumbResourceLoaded -->
                </ul>
            </xsl:result-document>

            <!-- passing response map(*) as the context here! -->
            <xsl:call-template name="ldh:BreadCrumbResourceLoaded">
                <xsl:with-param name="container" select="id('breadcrumb-nav', ixsl:page())"/>
                <!-- strip the query string if it's present -->
                <xsl:with-param name="uri" select="xs:anyURI(if (contains($uri, '?')) then substring-before($uri, '?') else $uri)"/>
            </xsl:call-template>
        </xsl:if>

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
        
        <xsl:for-each select="?body">
            <xsl:message>RDF base-uri(?body): <xsl:value-of select="base-uri()"/></xsl:message>
            <xsl:message>RDF base-uri(ixsl:page()): <xsl:value-of select="base-uri(ixsl:page())"/></xsl:message>
            <xsl:message>RDF ldh:base-uri(?body): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
            <xsl:message>RDF ldh:base-uri(ixsl:page()): <xsl:value-of select="ldh:base-uri(ixsl:page())"/></xsl:message>
        
            <xsl:variable name="results" select="." as="document-node()"/>
            <ixsl:set-property name="{'`' || $uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
            <!-- store document under window.LinkedDataHub[$content-uri].results -->
            <ixsl:set-property name="results" select="." object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`')"/>

            <!-- render current document's created/modified datetime -->
            <xsl:for-each select="id('created-modified-date', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <p>
                        <xsl:apply-templates select="key('resources', $uri, $results)" mode="bs2:Timestamp"/>
                    </p>
                </xsl:result-document>
            </xsl:for-each>
        
            <!-- this has to go after <xsl:result-document href="#{$container-id}"> because otherwise new elements will be injected and the $resource-content-ids lookup will not work anymore -->
            <!-- load resource contents -->
            <xsl:variable name="resource-content-ids" select="key('elements-by-class', 'resource-content', ixsl:page())/@id" as="xs:string*"/>
            <xsl:if test="not(empty($resource-content-ids))">
                <xsl:variable name="containers" select="id($resource-content-ids, ixsl:page())" as="element()*"/>
                <xsl:for-each select="$containers">
                    <xsl:call-template name="ldh:LoadContent">
                        <xsl:with-param name="acl-modes" select="$acl-modes"/>
                        <xsl:with-param name="refresh-content" select="$refresh-content"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>

            <xsl:if test="acl:mode() = '&acl;Write'">
                <xsl:variable name="xhtml-content-ids" select="key('elements-by-class', 'xhtml-content', ixsl:page())/@id" as="xs:string*"/>
                <xsl:if test="not(empty($xhtml-content-ids))">
                    <xsl:variable name="containers" select="id($xhtml-content-ids, ixsl:page())" as="element()*"/>
                    <xsl:for-each select="$containers">
                        <xsl:variable name="container" select="." as="element()"/>
                        
                        <xsl:call-template name="ldh:ContentLoaded">
                            <xsl:with-param name="container" select="$container"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>

            <!-- focus on current resource -->
            <xsl:for-each select="key('resources', $uri)">
                <!-- if the current resource is an Item, hide the <div> with the top/left "Create" dropdown as Items cannot have child documents -->
                <xsl:variable name="is-item" select="exists(sioc:has_container/@rdf:resource)" as="xs:boolean"/>
                <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'create-action')]/..">
                    <xsl:choose>
                        <xsl:when test="$is-item">
                            <ixsl:set-style name="display" select="'none'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <ixsl:set-style name="display" select="'block'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:for-each>

            <!-- is a new instance of Service was created, reload the LinkedDataHub.apps data and re-render the service dropdown -->
            <xsl:if test="//ldt:base or //sd:endpoint">
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $app-request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                        <xsl:call-template name="onServiceLoad"/>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
            
            <!-- initialize map -->
            <xsl:if test="key('elements-by-class', 'map-canvas', ixsl:page())">
                <xsl:call-template name="ldh:DrawMap">
                    <xsl:with-param name="content-uri" select="$uri"/>
                    <xsl:with-param name="canvas-id" select="key('elements-by-class', 'map-canvas', ixsl:page())/@id" />
                </xsl:call-template>
            </xsl:if>
            
            <!-- initialize chart -->
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
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="onServiceLoad">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:if test="?status = 200 and ?media-type = 'application/rdf+xml'">
            <xsl:for-each select="?body">
                <ixsl:set-property name="apps" select="." object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                
                <xsl:variable name="service-uri" select="if (id('search-service', ixsl:page())) then xs:anyURI(ixsl:get(id('search-service', ixsl:page()), 'value')) else ()" as="xs:anyURI?"/>
                <xsl:call-template name="ldh:RenderServices">
                    <xsl:with-param name="select" select="id('search-service', ixsl:page())"/>
                    <xsl:with-param name="apps" select="."/>
                    <xsl:with-param name="selected-service" select="$service-uri"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <!-- push state -->

    <xsl:template name="ldh:PushState">
         <!-- $href has to be a proxied URI with the actual URI encoded as ?uri, otherwise we get a "DOMException: The operation is insecure" -->
        <xsl:param name="href" as="xs:anyURI"/>
        <xsl:param name="title" as="xs:string?"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="sparql" select="false()" as="xs:boolean"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        
        <xsl:variable name="state" as="map(xs:string, item())">
            <xsl:map>
                <xsl:map-entry key="'href'" select="$href"/>
                <xsl:map-entry key="'container-id'" select="ixsl:get($container, 'id')"/>
                <xsl:map-entry key="'query-string'" select="$query"/>
                <xsl:map-entry key="'sparql'" select="$sparql"/>
                <xsl:if test="$endpoint">
                    <xsl:map-entry key="'endpoint'" select="$endpoint"/>
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="state-obj" select="ixsl:call(ixsl:window(), 'JSON.parse', [ $state => serialize(map{ 'method': 'json' }) ])"/>

        <!-- push the latest state into history -->
        <xsl:sequence select="ixsl:call(ixsl:window(), 'history.pushState', [ $state-obj, $title, $href ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- load RDF document -->
    
    <xsl:template name="ldh:RDFDocumentLoad">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <!-- if the URI is external, dereference it through the proxy -->
        <!-- add a bogus query parameter to give the RDF/XML document a different URL in the browser cache, otherwise it will clash with the HTML representation -->
        <!-- this is due to broken browser behavior re. Vary and conditional requests: https://stackoverflow.com/questions/60799116/firefox-if-none-match-headers-ignore-content-type-and-vary/60802443 -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{ 'param': 'dummy' }, ac:document-uri($uri))" as="xs:anyURI"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:RDFDocumentLoaded">
                    <xsl:with-param name="uri" select="$uri"/>
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- service select -->
    
    <xsl:template name="ldh:RenderServices">
        <xsl:param name="select" as="element()"/>
        <xsl:param name="apps" as="document-node()"/>
        <xsl:param name="selected-service" as="xs:anyURI?"/>
        
        <xsl:for-each select="$select">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <option value="">
                    <xsl:value-of>
                        <xsl:text>[</xsl:text>
                        <xsl:apply-templates select="key('resources', 'sparql-service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        <xsl:text>]</xsl:text>
                    </xsl:value-of>
                </option>
                
                <xsl:for-each select="$apps//*[rdf:type/@rdf:resource = '&sd;Service']">
                    <xsl:sort select="ac:label(.)"/>

                    <xsl:apply-templates select="." mode="xhtml:Option">
                        <xsl:with-param name="value" select="@rdf:about"/>
                        <xsl:with-param name="selected" select="@rdf:about = $selected-service"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="onSPARQLResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="results-uri" as="xs:anyURI"/>
        <xsl:param name="content-uri" select="$results-uri" as="xs:anyURI"/>
        <xsl:param name="chart-canvas-id" as="xs:string"/>
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="textarea-id" select="'query-string'" as="xs:string"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="content-method" select="xs:QName('ixsl:replace-content')" as="xs:QName"/>
        <xsl:param name="show-editor" select="true()" as="xs:boolean"/>
        <xsl:param name="show-chart-save" select="true()" as="xs:boolean"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = ('application/rdf+xml', 'application/sparql-results+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                    <xsl:variable name="category" select="if ($category) then $category else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name()))[1] else srx:sparql/srx:head/srx:variable[1]/@name)" as="xs:string?"/>
                    <xsl:variable name="series" select="if (exists($series)) then $series else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name())) else srx:sparql/srx:head/srx:variable/@name)" as="xs:string*"/>

                    <!-- disable buttons if the result is not RDF (e.g. SPARQL XML results), enable otherwise -->
                    <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//button[tokenize(@class, ' ') = ('btn-save-as', 'btn-skolemize')]">
                        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'disabled', not($results/rdf:RDF) ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>

                    <xsl:if test="$show-editor and not(id('query-form', ixsl:page()))">
                        <xsl:for-each select="$container">
                            <xsl:result-document href="?." method="{$content-method}">
                                <xsl:call-template name="bs2:QueryEditor">
                                    <xsl:with-param name="query" select="$query"/>
                                </xsl:call-template>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:if>

                    <xsl:if test="$show-editor and not(id('query-form', ixsl:page()))">
                        <!-- initialize YASQE on the textarea -->
                        <xsl:variable name="js-statement" as="element()">
                            <root statement="YASQE.fromTextArea(document.getElementById('{$textarea-id}'), {{ persistent: null }})"/>
                        </xsl:variable>
                        <ixsl:set-property name="{$textarea-id}" select="ixsl:eval(string($js-statement/@statement))" object="ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe')"/>
                    </xsl:if>

                    <!-- workaround until SPARQL editor is refactored as a content block -->
                    <xsl:for-each select="if (contains-token($container/@class, 'row-fluid')) then $container/div[contains-token(@class, 'main')] else $container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:apply-templates select="$results" mode="bs2:Chart">
                                <xsl:with-param name="endpoint" select="if (not($endpoint = sd:endpoint())) then $endpoint else ()" tunnel="yes"/>
                                <xsl:with-param name="id" select="$chart-canvas-id"/>
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                                <xsl:with-param name="show-save" select="$show-chart-save"/>
                            </xsl:apply-templates>
                        </xsl:result-document>
                    </xsl:for-each>
                        
                    <!-- post-process the container if it's a chart instance being rendered and not SPARQL results -->
                    <xsl:if test="not($query)">
                        <xsl:call-template name="ldh:ContentLoaded">
                            <xsl:with-param name="container" select="$container"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- create new cache entry using content URI as key -->
                    <ixsl:set-property name="{'`' || $content-uri || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                    <ixsl:set-property name="results" select="$results" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                    <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
                    <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')"/>
                    
                    <xsl:call-template name="ldh:RenderChart">
                        <xsl:with-param name="data-table" select="$data-table"/>
                        <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                        <xsl:with-param name="chart-type" select="$chart-type"/>
                        <xsl:with-param name="category" select="$category"/>
                        <xsl:with-param name="series" select="$series"/>
                    </xsl:call-template>

                    <xsl:for-each select="$container//div[@class = 'progress-bar']">
                        <ixsl:set-style name="display" select="'none'" object="."/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container//div[@class = 'progress-bar']">
                    <ixsl:set-style name="display" select="'none'" object="."/>
                </xsl:for-each>
                    
                <!-- error response - could not load query results -->
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error during query execution:</strong>
                            <pre>
                                <xsl:value-of select="$response?message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Linked Data browser -->
    
    <xsl:template name="ldh:DocumentLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="href" as="xs:anyURI?"/> <!-- absolute URI! -->
        <xsl:param name="service-uri" select="if (id('search-service', ixsl:page())) then xs:anyURI(ixsl:get(id('search-service', ixsl:page()), 'value')) else ()" as="xs:anyURI?"/>
        <xsl:param name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <!-- decode raw document URL (without fragment) from the ?uri query param, if it's present -->
        <xsl:variable name="uri" select="if (contains($href, '?')) then let $query-params := ldh:parse-query-params(substring-after(ac:document-uri($href), '?')) return if (exists($query-params?uri)) then ldh:decode-uri($query-params?uri[1]) else ldh:absolute-path($href) else ldh:absolute-path($href)" as="xs:anyURI"/>
        <xsl:variable name="doc-uri" select="ac:document-uri($uri)" as="xs:anyURI"/>
        <!--<xsl:message>onDocumentLoad $href: <xsl:value-of select="$href"/> $uri: <xsl:value-of select="$uri"/> $doc-uri: <xsl:value-of select="$doc-uri"/></xsl:message>-->

        <!-- set #uri value -->
        <xsl:for-each select="id('uri', ixsl:page())">
            <ixsl:set-property name="value" select="if (not(starts-with($uri, $ldt:base))) then $uri else ()" object="."/>
        </xsl:for-each>
        
        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 0">
                <!-- HTTP request was terminated - do nothing -->
            </xsl:when>
            <xsl:when test="starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:variable name="endpoint-link" select="tokenize(?headers?link, ',')[contains(., '&sd;endpoint')]" as="xs:string?"/>
                <xsl:variable name="endpoint" select="if ($endpoint-link) then xs:anyURI(substring-before(substring-after(substring-before($endpoint-link, ';'), '&lt;'), '&gt;')) else ()" as="xs:anyURI?"/>
                <xsl:variable name="base-link" select="tokenize(?headers?link, ',')[contains(., '&ldt;base')]" as="xs:string?"/>
                <!-- set new base URI if the current app has changed -->
                <xsl:if test="$base-link">
                    <xsl:variable name="base" select="xs:anyURI(substring-before(substring-after(substring-before($base-link, ';'), '&lt;'), '&gt;'))" as="xs:anyURI"/>
                    <xsl:if test="not($base = ldt:base())">
                        <xsl:message>Application change. Base URI: <xsl:value-of select="$base"/></xsl:message>
                        <xsl:call-template name="ldt:AppChanged">
                            <xsl:with-param name="base" select="$base"/>
                        </xsl:call-template>
                    </xsl:if>
                    <ixsl:set-property name="base" select="$base" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:if>

                <xsl:apply-templates select="?body" mode="ldh:HTMLDocumentLoaded">
                    <xsl:with-param name="href" select="$href"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="container" select="id($body-id, ixsl:page())"/>
                    <xsl:with-param name="push-state" select="$push-state"/>
                    <xsl:with-param name="refresh-content" select="$refresh-content"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                
                <!-- error response - could not load document -->
                <xsl:result-document href="#content-body" method="ixsl:replace-content">
                    <div class="alert alert-block">
                        <strong>Error loading XHTML document</strong>
                        <xsl:if test="$response?message">
                            <pre>
                                <xsl:value-of select="$response?message"/>
                            </pre>
                        </xsl:if>
                    </div>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- cannot be a named template because overriding templates need to be able to call xsl:next-match (cannot use xsl:origin with Saxon-JS because of XSLT 3.0 packages) -->
    <xsl:template match="/" mode="ldh:HTMLDocumentLoaded">
        <xsl:param name="href" as="xs:anyURI"/> <!-- possibly proxied URL -->
        <xsl:param name="container" as="element()"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="replace-content" select="true()" as="xs:boolean"/>
        <xsl:param name="refresh-content" as="xs:boolean?"/>
        <!-- decode raw document URL (without fragment) from the ?uri query param, if it's present -->
        <xsl:variable name="uri" select="if (contains($href, '?')) then let $query-params := ldh:parse-query-params(substring-after(ac:document-uri($href), '?')) return if (exists($query-params?uri)) then ldh:decode-uri($query-params?uri[1]) else ldh:absolute-path($href) else ldh:absolute-path($href)" as="xs:anyURI"/>
        <xsl:variable name="doc-uri" select="ac:document-uri($uri)" as="xs:anyURI"/>
        <xsl:variable name="fragment" select="if (contains($href, '#')) then substring-after($href, '#') else ()" as="xs:string?"/>
        <!--<xsl:message>ldh:HTMLDocumentLoaded $href: <xsl:value-of select="$href"/> $uri: <xsl:value-of select="$uri"/> $doc-uri: <xsl:value-of select="$doc-uri"/> $fragment: <xsl:value-of select="$fragment"/> </xsl:message>-->
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:message>HTML base-uri(.): <xsl:value-of select="base-uri()"/></xsl:message>
        <xsl:message>HTML ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
        <xsl:message>HTML ldh:base-uri(ixsl:page()): <xsl:value-of select="ldh:base-uri(ixsl:page())"/></xsl:message>
            
        <ixsl:set-property name="uri" select="$uri" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <xsl:if test="$endpoint">
            <ixsl:set-property name="endpoint" select="$endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        </xsl:if>
        
        <xsl:if test="$replace-content">
            <!-- set document.title which history.pushState() does not do -->
            <ixsl:set-property name="title" select="string(/html/head/title)" object="ixsl:page()"/>

            <xsl:variable name="results" select="." as="document-node()"/>
            
            <!-- replace HTML body with the loaded XHTML body -->
            <xsl:for-each select="$container">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:copy-of select="id($container/@id, $results)/node()"/>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:choose>
                <!-- scroll fragment-identified element into view if fragment is provided-->
                <xsl:when test="$fragment">
                    <xsl:for-each select="id($fragment, ixsl:page())">
                        <xsl:sequence select="ixsl:call(., 'scrollIntoView', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each >
                </xsl:when>
                <!-- otherwise, scroll to the top of the window -->
                <xsl:otherwise>
                    <xsl:sequence select="ixsl:call(ixsl:window(), 'scrollTo', [ 0, 0 ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <xsl:if test="$push-state">
            <xsl:variable name="href" as="xs:anyURI">
                <xsl:choose>
                    <!-- if ldh:ContentMode is active, change the page's URL to reflect that -->
                    <xsl:when test="id('content-body', ixsl:page())/div[contains-token(@class, 'row-fluid')][1]/ul[contains-token(@class, 'nav-tabs')]/li[contains-token(@class, 'content-mode')][contains-token(@class, 'active')]">
                        <xsl:variable name="fragment" select="substring-after($href, '#')" as="xs:string"/>
                        <xsl:sequence select="xs:anyURI(ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, ac:build-uri(ac:uri(), map{ 'mode': '&ldh;ContentMode' } ), $fragment))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$href"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
        
            <xsl:call-template name="ldh:PushState">
                <xsl:with-param name="href" select="$href"/>
                <xsl:with-param name="title" select="/html/head/title"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="ldh:PostHTMLDocumentLoad">
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="doc-uri" select="$doc-uri"/>
        </xsl:call-template>
        
        <xsl:call-template name="ldh:RDFDocumentLoad">
            <xsl:with-param name="uri" select="$uri"/>
            <xsl:with-param name="refresh-content" select="$refresh-content"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- post-HTML load hook, mainly for navigation updates -->
    
    <xsl:template name="ldh:PostHTMLDocumentLoad">
        <xsl:param name="href" as="xs:anyURI"/> <!-- possibly proxied URL -->
        <xsl:param name="doc-uri" as="xs:anyURI"/>

        <!-- update the document-level @about -->
        <xsl:for-each select="id('content-body', ixsl:page())">
            <ixsl:set-attribute name="about" select="$doc-uri" object="."/>
        </xsl:for-each>
        
        <!-- update RDF download links to match the current URI -->
        <xsl:for-each select="id('export-rdf', ixsl:page())/following-sibling::ul/li/a">
            <!-- use @title attribute for the media type TO-DO: find a better way, a hidden input or smth -->
            <xsl:variable name="href" select="ac:build-uri(ldh:absolute-path($href), let $params := map{ 'accept': string(@title) } return if (not(starts-with($doc-uri, $ldt:base))) then map:merge(($params, map{ 'uri': $doc-uri })) else $params)" as="xs:anyURI"/>

            <ixsl:set-attribute name="href" select="$href" object="."/>
        </xsl:for-each>
            
        <!-- activate the current URL in the document tree -->
        <xsl:for-each select="id('doc-tree', ixsl:page())">
            <xsl:call-template name="ldh:DocTreeActivateHref">
                <xsl:with-param name="href" select="$href"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ldt:AppChanged">
        <xsl:param name="base" as="xs:anyURI"/>

        <xsl:for-each select="id('doc-tree', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="ldh:DocTree">
                    <xsl:with-param name="base" select="$base"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="onBacklinksLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="backlinks-container" as="element()"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="results" select="?body" as="document-node()"/>
                
                <xsl:for-each select="$backlinks-container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <ul class="well well-small nav nav-list">
                            <xsl:apply-templates select="$results/rdf:RDF/rdf:Description[not(@rdf:about = ac:uri())]" mode="bs2:List">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:with-param name="mode" select="ac:mode()[1]" tunnel="yes"/> <!-- TO-DO: support multiple modes -->
                                <xsl:with-param name="render-id" select="false()" tunnel="yes"/>
                            </xsl:apply-templates>
                        </ul>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>

    <!-- EVENT LISTENERS -->

    <!-- popstate -->
    
    <xsl:template match="." mode="ixsl:onpopstate">
        <xsl:variable name="state" select="ixsl:get(ixsl:event(), 'state')"/>
        <xsl:if test="not(empty($state))">
            <xsl:variable name="href" select="map:get($state, 'href')" as="xs:anyURI?"/>
            <xsl:variable name="container-id" select="if (map:contains($state, 'container-id')) then map:get($state, 'container-id') else ()" as="xs:anyURI?"/>
            <xsl:variable name="query-string" select="map:get($state, 'query-string')" as="xs:string?"/>
            <xsl:variable name="sparql" select="false()" as="xs:boolean"/>
            <xsl:variable name="endpoint" select="map:get($state, 'endpoint')" as="xs:anyURI?"/>

            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <!-- decode URI from the ?uri query param if the URI was proxied -->
            <xsl:variable name="uri" select="if (contains($href, '?uri=')) then xs:anyURI(ixsl:call(ixsl:window(), 'decodeURIComponent', [ substring-after($href, '?uri=') ])) else $href" as="xs:anyURI"/>

            <!-- TO-DO: do we need to proxy the $uri here? -->
            <xsl:choose>
                <xsl:when test="$sparql">
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }">
                            <xsl:call-template name="onSPARQLResultsLoad">
                                <xsl:with-param name="results-uri" select="$uri"/>
                                <xsl:with-param name="container" select="id($container-id, ixsl:page())"/>
                                <!-- we don't want to push a state that was just popped -->
                                <xsl:with-param name="push-state" select="false()"/>
                                <xsl:with-param name="query" select="$query-string"/>
                                <xsl:with-param name="endpoint" select="$endpoint"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- abort the previous request, if any -->
                    <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
                        <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
                    </xsl:if>

                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                            <xsl:call-template name="ldh:DocumentLoaded">
                                <xsl:with-param name="href" select="$href"/>
                                <!-- we don't want to push the same state we just popped back to -->
                                <xsl:with-param name="push-state" select="false()"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>

                    <!-- store the new request object -->
                    <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- do not intercept RDF download links -->
    <xsl:template match="button[@id = 'export-rdf']/following-sibling::ul//a" mode="ixsl:onclick" priority="1"/>
    
    <!-- intercept all HTML and SVG link clicks except to /uploads/ and those in the navbar (except breadcrumb bar, .brand and app list) and the footer -->
    <!-- resolve URLs against the current document URL because they can be relative -->
    <xsl:template match="a[not(@target)][starts-with(resolve-uri(@href, ac:document-uri(ac:uri())), 'http://') or starts-with(resolve-uri(@href, ac:document-uri(ac:uri())), 'https://')][not(starts-with(resolve-uri(@href, ac:document-uri(ac:uri())), resolve-uri('uploads/', $ldt:base)))][ancestor::div[@id = 'breadcrumb-nav'] or not(ancestor::div[tokenize(@class, ' ') = ('navbar', 'footer')])] | a[contains-token(@class, 'brand')] | div[button[contains-token(@class, 'btn-apps')]]/ul//a | svg:a[not(@target)][starts-with(resolve-uri(@href, ac:document-uri(ac:uri())), 'http://') or starts-with(resolve-uri(@href, ac:document-uri(ac:uri())), 'https://')][not(starts-with(resolve-uri(@href, ac:document-uri(ac:uri())), resolve-uri('uploads/', $ldt:base)))]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="href" select="resolve-uri(@href, ac:document-uri(ac:uri()))" as="xs:anyURI"/> <!-- resolve relative URIs -->
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- abort the previous request, if any -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
        </xsl:if>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="ldh:DocumentLoaded">
                    <xsl:with-param name="href" select="$href"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        
        <!-- store the new request object -->
        <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>
    
    <xsl:template match="form[contains-token(@class, 'navbar-form')]" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="uri-string" select=".//input[@name = 'uri']/ixsl:get(., 'value')" as="xs:string?"/>
        
        <!-- ignore form submission if the input value is not a valid http(s):// URI -->
        <xsl:if test="$uri-string castable as xs:anyURI and (starts-with($uri-string, 'http://') or starts-with($uri-string, 'https://'))">
            <xsl:variable name="uri" select="xs:anyURI($uri-string)" as="xs:anyURI"/>
            <!-- dereferenced external resources through a proxy -->
            <xsl:variable name="href" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $uri)" as="xs:anyURI"/>
            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <!-- abort the previous request, if any -->
            <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
                <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
            </xsl:if>

            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                    <xsl:call-template name="ldh:DocumentLoaded">
                        <xsl:with-param name="href" select="$href"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>

            <!-- store the new request object -->
            <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="onDelete">
        <xsl:context-item as="map(*)" use="required"/>
        
        <xsl:choose>
            <xsl:when test="?status = 204"> <!-- No Content -->
                <xsl:variable name="href" select="resolve-uri('..', ac:uri())" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $href)" as="xs:anyURI"/>

                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="ldh:DocumentLoaded">
                            <xsl:with-param name="href" select="$href"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- open drop-down by toggling its CSS class -->

    <xsl:template match="*[contains-token(@class, 'btn-group')][*[contains-token(@class, 'dropdown-toggle')]]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'open' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- trigger typeahead in the search bar -->
    
    <xsl:template match="input[@id = 'uri']" mode="ixsl:onkeyup" priority="1">
        <xsl:param name="text" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:param name="menu" select="following-sibling::ul" as="element()"/>
        <xsl:param name="delay" select="400" as="xs:integer"/>
        <xsl:param name="resource-types" as="xs:anyURI?"/>
        <xsl:param name="select-string" select="$select-labelled-string" as="xs:string"/>
        <xsl:param name="limit" select="100" as="xs:integer"/>
        <xsl:param name="label-var-name" select="'label'" as="xs:string"/>
        <xsl:variable name="key-code" select="ixsl:get(ixsl:event(), 'code')" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$key-code = 'Escape'">
                <xsl:call-template name="typeahead:hide">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$key-code = 'Enter'">
                <xsl:if test="$menu/li[contains-token(@class, 'active')]">
                    <!-- resource URI selected in the typeahead -->
                    <xsl:variable name="uri" select="$menu/li[contains-token(@class, 'active')]/input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                    <!-- dereference external resources through a proxy -->
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $uri)" as="xs:anyURI"/>
                    
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <!-- abort the previous request, if any -->
                    <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
                        <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
                    </xsl:if>

                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                            <xsl:call-template name="ldh:DocumentLoaded">
                                <xsl:with-param name="href" select="$uri"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    
                    <!-- store the new request object -->
                    <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$key-code = 'ArrowUp'">
                <xsl:call-template name="typeahead:selection-up">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$key-code = 'ArrowDown'">
                <xsl:call-template name="typeahead:selection-down">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:when>
            <!-- if the input is not a URI, execute a keyword search with SPARQL regex() -->
            <xsl:when test="not(starts-with(ixsl:get(., 'value'), 'http://')) and not(starts-with(ixsl:get(., 'value'), 'https://'))">
                <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($select-builder, 'build', []) ])" as="xs:string"/>
                <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
                <!-- append FILTER(regex()) -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:add-regex-filter">
                            <xsl:with-param name="var-name" select="$label-var-name" tunnel="yes"/>
                            <xsl:with-param name="pattern" select="$text" tunnel="yes"/>
                            <xsl:with-param name="flags" select="'iq'" tunnel="yes"/> <!-- case insensitive, ignore meta-characters: https://www.w3.org/TR/xpath-functions-31/#flags -->
                        </xsl:apply-templates>
                    </xsl:document>
                </xsl:variable>
                <!-- set LIMIT -->
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit"/>
                    </xsl:document>
                </xsl:variable>
                <!-- wrap SELECT into a DESCRIBE -->
                <xsl:variable name="query-xml" as="element()">
                    <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
                </xsl:variable>
                <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
                <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
                <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
                <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('search-service'), 'value'))" as="xs:anyURI?"/>
                <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
                <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), resolve-uri('sparql', $ldt:base))[1]" as="xs:anyURI"/>
                <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $results-uri)" as="xs:anyURI"/>
                
                <ixsl:schedule-action wait="$delay">
                    <xsl:call-template name="typeahead:load-xml">
                        <xsl:with-param name="element" select="."/>
                        <xsl:with-param name="query" select="$text"/>
                        <xsl:with-param name="uri" select="$request-uri"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="typeahead:hide">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- navbar search typeahead item selected -->
    
    <xsl:template match="form[contains-token(@class, 'navbar-form')]//ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'typeahead')]/li" mode="ixsl:onmousedown" priority="1">
        <!-- redirect to the resource URI selected in the typeahead -->
        <xsl:variable name="uri" select="input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
        <!-- dereference external resources through a proxy -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $uri)" as="xs:anyURI"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- abort the previous request, if any -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
        </xsl:if>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="ldh:DocumentLoaded">
                    <xsl:with-param name="href" select="$uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        
        <!-- store the new request object -->
        <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>
    
    <!-- open SPARQL editor -->
    
    <xsl:template match="a[contains-token(@class, 'query-editor')]" mode="ixsl:onclick">
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="textarea-id" select="'query-string'" as="xs:string"/>

        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="bs2:QueryEditor"/>
            </xsl:result-document>
        </xsl:for-each>

        <!-- initialize SPARQL query service dropdown -->
        <xsl:variable name="service" select="if (id('search-service', ixsl:page())) then xs:anyURI(ixsl:get(id('search-service', ixsl:page()), 'value')) else ()" as="xs:anyURI?"/>
        <xsl:call-template name="ldh:RenderServices">
            <xsl:with-param name="select" select="id('query-service', ixsl:page())"/>
            <xsl:with-param name="apps" select="ixsl:get(ixsl:window(), 'LinkedDataHub.apps')"/>
            <xsl:with-param name="selected-service" select="$service"/>
        </xsl:call-template>

        <!-- initialize YASQE on the textarea -->
        <xsl:variable name="js-statement" as="element()">
            <root statement="YASQE.fromTextArea(document.getElementById('{$textarea-id}'), {{ persistent: null }})"/>
        </xsl:variable>
        <ixsl:set-property name="{$textarea-id}" select="ixsl:eval(string($js-statement/@statement))" object="ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe')"/>
    </xsl:template>
    
    <!-- open editing form (do nothing if the button is disabled) -->
    <xsl:template match="a[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="href" select="@href" as="xs:anyURI"/>

        <!-- toggle .active class -->
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <!-- abort the previous request, if any -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
        </xsl:if>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddForm">
                    <xsl:with-param name="container" select="id('content-body', ixsl:page())"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <!-- store the new request object -->
        <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:if test="$href">
            <xsl:call-template name="ldh:PushState">
                <xsl:with-param name="href" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $href)"/>
                <xsl:with-param name="container" select="id('content-body', ixsl:page())"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-delete')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="uri" select="ac:uri()" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:query-params(xs:anyURI('&ac;EditMode')), $uri)" as="xs:anyURI"/>

        <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))) ])">
            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'DELETE', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                    <xsl:call-template name="onDelete"/>
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
        <xsl:variable name="uri-or-bnode" select="../../h2/a/@title | ../following-sibling::input[@name = ('su', 'sb')]/@value" as="xs:string"/>
        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'navigator.clipboard'), 'writeText', [ $uri-or-bnode ])"/>
    </xsl:template>

    <!-- open a form to save RDF document (do nothing if the button is disabled) -->
    
    <xsl:template match="button[contains-token(@class, 'btn-save-as')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="textarea-id" select="'query-string'" as="xs:string"/>
        <xsl:variable name="query" select="if (id($textarea-id, ixsl:page())) then ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id), 'getValue', []) else ()" as="xs:string?"/>
        <xsl:variable name="service-uri" select="if (id('query-service', ixsl:page())) then xs:anyURI(ixsl:get(id('query-service'), 'value')) else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), resolve-uri('sparql', $ldt:base))[1]" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="if ($query) then ac:build-uri($endpoint, map{ 'query': $query }) else ()" as="xs:anyURI?"/>
        
        <!-- if SPARQL editor is shown, use the SPARQL protocol URI; otherwise use the Linked Data resource URI -->
        <xsl:variable name="uri" select="if ($results-uri) then $results-uri else ac:uri()" as="xs:anyURI"/>

        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="form" as="element()">
                <xsl:call-template name="ldh:AddDataForm">
                    <xsl:with-param name="source" select="$uri"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="graph" select="ldh:absolute-path(ldh:href())"/>
        </xsl:call-template>
    </xsl:template>

    <!-- document mode tabs -->
    
    <xsl:template match="div[@id = 'content-body']/div/ul[contains-token(@class, 'nav-tabs')]/li[not(contains-token(@class, 'active'))]/a" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="active-class" select="tokenize(../@class, ' ')[not(. = 'active')]" as="xs:string"/>
        <xsl:variable name="href" select="@href" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        <!-- make other tabs inactive -->
        <xsl:sequence select="../../li[not(contains-token(@class, $active-class))]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        <!-- make this tab active -->
        <xsl:sequence select="../ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- abort the previous request, if any -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
        </xsl:if>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="ldh:DocumentLoaded">
                    <xsl:with-param name="href" select="$href"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>

        <!-- store the new request object -->
        <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>

    <!-- backlinks -->
    
    <xsl:template match="div[contains-token(@class, 'backlinks-nav')]//*[contains-token(@class, 'nav-header')]" mode="ixsl:onclick">
        <xsl:variable name="backlinks-container" select="ancestor::div[contains-token(@class, 'backlinks-nav')]" as="element()"/>
        <xsl:variable name="container" select="ancestor::div[@about][1]" as="element()"/>
        <xsl:variable name="content-uri" select="$container/@about" as="xs:anyURI"/>
        <xsl:variable name="content-value" select="if (ixsl:contains($container, 'dataset.contentValue')) then ixsl:get($container, 'dataset.contentValue') else $content-uri" as="xs:anyURI"/>
        <xsl:variable name="query-string" select="replace($backlinks-string, '$this', '&lt;' || $content-value || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`')) then (if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'service-uri') else ()) else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $results-uri)" as="xs:anyURI"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:choose>
            <!-- backlink nav list is not rendered yet - load it -->
            <xsl:when test="not(following-sibling::*[contains-token(@class, 'nav')])">
                <!-- toggle the caret direction -->
                <xsl:for-each select="span[contains-token(@class, 'caret')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                        <xsl:call-template name="onBacklinksLoad">
                            <xsl:with-param name="backlinks-container" select="$backlinks-container"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- show the nav list -->
            <xsl:when test="ixsl:style(following-sibling::*[contains-token(@class, 'nav')])?display = 'none'">
                <ixsl:set-style name="display" select="'block'" object="following-sibling::*[contains-token(@class, 'nav')]"/>
            </xsl:when>
            <!-- hide the nav list -->
            <xsl:otherwise>
                <ixsl:set-style name="display" select="'none'" object="following-sibling::*[contains-token(@class, 'nav')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- left-side document tree -->
    
    <xsl:template match="body[id('doc-tree', ixsl:page())]" mode="ixsl:onmousemove">
        <xsl:variable name="x" select="ixsl:get(ixsl:event(), 'clientX')"/>
        
        <!-- check that the mouse is on the left edge -->
        <xsl:if test="$x = 0">
            <!-- show #doc-tree -->
            <ixsl:set-style name="display" select="'block'" object="id('doc-tree', ixsl:page())"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>