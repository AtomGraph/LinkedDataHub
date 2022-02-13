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
    <!ENTITY acl        "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt        "https://www.w3.org/ns/ldt#">
    <!ENTITY dh         "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd         "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp         "http://spinrdf.org/sp#">
    <!ENTITY dct        "http://purl.org/dc/terms/">
    <!ENTITY foaf       "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc       "http://rdfs.org/sioc/ns#">
    <!ENTITY nfo        "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY schema1    "http://schema.org/">
    <!ENTITY schema2    "https://schema.org/">
    <!ENTITY dbpo       "http://dbpedia.org/ontology/">
    <!ENTITY gm         "https://developers.google.com/maps#">
]>
<xsl:stylesheet version="3.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
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
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:skos="&skos;"
xmlns:gm="&gm;"
xmlns:schema1="&schema1;"
xmlns:schema2="&schema2;"
xmlns:dbpo="&dbpo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>

    <xsl:import href="../../../../com/atomgraph/client/xsl/group-sort-triples.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/RDFXML2DataTable.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/SPARQLXMLResults2DataTable.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/RDFXML2SVG.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/functions.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/container.xsl"/>
    <xsl:import href="bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="bootstrap/2.3.2/document.xsl"/>
    <xsl:import href="query-transforms.xsl"/>
    <xsl:import href="typeahead.xsl"/>

    <xsl:include href="bootstrap/2.3.2/client/breadcrumb.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/chart.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/container.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/form.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/map.xsl"/>
    <xsl:include href="bootstrap/2.3.2/client/sparql.xsl"/>

    <xsl:param name="ac:contextUri" as="xs:anyURI"/>
    <xsl:param name="ldt:base" as="xs:anyURI"/>
    <xsl:param name="ldt:ontology" as="xs:anyURI"/> <!-- used in default.xsl -->
    <xsl:param name="sd:endpoint" as="xs:anyURI?"/>
    <xsl:param name="ldh:absolutePath" as="xs:anyURI"/>
    <xsl:param name="app-request-uri" as="xs:anyURI"/>
    <xsl:param name="ldh:apps" as="document-node()?">
        <xsl:document>
            <rdf:RDF></rdf:RDF>
        </xsl:document>
    </xsl:param>
    <xsl:param name="ac:lang" select="ixsl:get(ixsl:get(ixsl:page(), 'documentElement'), 'lang')" as="xs:string"/>
    <xsl:param name="ac:mode" select="if (ixsl:query-params()?mode) then xs:anyURI(ixsl:query-params()?mode) else xs:anyURI('&ac;ReadMode')" as="xs:anyURI?"/>
    <xsl:param name="ac:query" select="ixsl:query-params()?query" as="xs:string?"/>
    <xsl:param name="ac:googleMapsKey" select="'AIzaSyCQ4rt3EnNCmGTpBN0qoZM1Z_jXhUnrTpQ'" as="xs:string"/>
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
  { GRAPH ?graph
      { ?resource  a  ?Type .
        ?resource (((((((((rdfs:label|dc:title)|dct:title)|foaf:name)|foaf:givenName)|foaf:familyName)|sioc:name)|skos:prefLabel)|sioc:content)|schema1:name)|schema2:name ?label
        FILTER isURI(?resource)
      }
  }
]]>
    </xsl:param>
    <xsl:param name="select-labelled-class-string" as="xs:string">
<![CDATA[
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  spin: <http://spinrdf.org/spin#>

SELECT  ?class
WHERE
  { ?class (rdfs:subClassOf)*/spin:constructor  ?constructor .
    ?class    rdfs:label        ?label
    FILTER isURI(?class)
    FILTER (!strstarts(str(?class), 'http://spinrdf.org/spin#'))
  }
]]>
    </xsl:param>
    <xsl:param name="backlinks-string" as="xs:string">
<![CDATA[
DESCRIBE ?subject
WHERE
  { SELECT DISTINCT  ?subject
    WHERE
      {   { ?subject  ?p  ?this }
        UNION
          { GRAPH ?g
              { ?subject  ?p  ?this }
          }
        FILTER isURI(?subject)
      }
    LIMIT   10
  }
]]></xsl:param>

    <xsl:key name="resources" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>
    <xsl:key name="elements-by-class" match="*" use="tokenize(@class, ' ')"/>
    <xsl:key name="violations-by-value" match="*" use="ldh:violationValue/text()"/>
    <xsl:key name="resources-by-container" match="*[@rdf:about] | *[@rdf:nodeID]" use="sioc:has_parent/@rdf:resource | sioc:has_container/@rdf:resource"/>

    <xsl:strip-space elements="*"/>

    <!-- INITIAL TEMPLATE -->
    
    <xsl:template name="main">
        <xsl:message>xsl:product-name: <xsl:value-of select="system-property('xsl:product-name')"/></xsl:message>
        <xsl:message>saxon:platform: <xsl:value-of select="system-property('saxon:platform')"/></xsl:message>
        <xsl:message>$ac:contextUri: <xsl:value-of select="$ac:contextUri"/></xsl:message>
        <xsl:message>$ldt:base: <xsl:value-of select="$ldt:base"/></xsl:message>
        <xsl:message>$ldh:absolutePath: <xsl:value-of select="$ldh:absolutePath"/></xsl:message>
        <xsl:message>count($ldh:apps//*[rdf:type/@rdf:resource = '&sd;Service']): <xsl:value-of select="count($ldh:apps//*[rdf:type/@rdf:resource = '&sd;Service'])"/></xsl:message>
        <xsl:message>$ac:lang: <xsl:value-of select="$ac:lang"/></xsl:message>
        <xsl:message>$sd:endpoint: <xsl:value-of select="$sd:endpoint"/></xsl:message>
        <xsl:message>ixsl:query-params()?uri: <xsl:value-of select="ixsl:query-params()?uri"/></xsl:message>

        <!-- create a LinkedDataHub namespace -->
        <ixsl:set-property name="LinkedDataHub" select="ldh:new-object()"/>
        <ixsl:set-property name="contents" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="typeahead" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/> <!-- used by typeahead.xsl -->
        <ixsl:set-property name="endpoint" select="$sd:endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="yasqe" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <xsl:apply-templates select="ixsl:page()" mode="ldh:LoadedHTMLDocument">
            <xsl:with-param name="href" select="ldh:href()"/>
            <!--<xsl:with-param name="fragment" select="encode-for-uri(ldh:href())"/>-->
            <!--<xsl:with-param name="uri" select="if (ixsl:query-params()?uri) then xs:anyURI(ixsl:query-params()?uri) else ldh:absolute-path(ldh:href())"/>-->
            <xsl:with-param name="endpoint" select="$sd:endpoint"/>
            <xsl:with-param name="container" select="id('content-body', ixsl:page())"/>
            <xsl:with-param name="replace-content" select="false()"/>
        </xsl:apply-templates>
        <!-- disable SPARQL editor's server-side submission -->
        <xsl:for-each select="ixsl:page()//button[contains(@class, 'btn-run-query')]"> <!-- TO-DO: use the 'elements-by-class' key -->
            <ixsl:set-attribute name="type" select="'button'"/> <!-- instead of "submit" -->
        </xsl:for-each>
        <!-- only show first time message for authenticated agents -->
<!--        <xsl:if test="id('content-body', ixsl:page()) and not(contains(ixsl:get(ixsl:page(), 'cookie'), 'LinkedDataHub.first-time-message'))">
            <xsl:result-document href="#content-body" method="ixsl:append-content">
                <xsl:call-template name="first-time-message"/>
            </xsl:result-document>
        </xsl:if>-->
        <!-- initialize wymeditor textareas -->
        <xsl:apply-templates select="key('elements-by-class', 'wymeditor', ixsl:page())" mode="ldh:PostConstruct"/>
        <!-- append typeahead list after the search/URI input -->
        <xsl:for-each select="id('uri', ixsl:page())/..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <ul id="{generate-id()}" class="search-typeahead typeahead dropdown-menu"></ul>
            </xsl:result-document>
        </xsl:for-each>
        <!-- initialize LinkedDataHub.apps (and the search dropdown, if it's shown) -->
        <ixsl:set-property name="apps" select="$ldh:apps" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <!-- #search-service may be missing (e.g. suppressed by extending stylesheet) -->
        <xsl:for-each select="id('search-service', ixsl:page())">
            <xsl:call-template name="ldh:RenderServices">
                <xsl:with-param name="select" select="."/>
                <xsl:with-param name="apps" select="$ldh:apps"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- FUNCTIONS -->
    
    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'location.href'))"/>
    </xsl:function>

    <xsl:function name="ldh:absolute-path" as="xs:anyURI">
        <xsl:param name="href" as="xs:anyURI"/>
        
        <xsl:sequence select="xs:anyURI(if (contains($href, '?')) then substring-before($href, '?') else if (contains($href, '#')) then substring-before($href, '#') else $href)"/>
    </xsl:function>

    <xsl:function name="ac:uri" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.uri'))"/>
        <!--<xsl:sequence select="xs:anyURI(if (contains($href, '?')) then let $query-params := ldh:parse-query-params(substring-after($href, '?')) return if (exists($query-params?uri)) then ldh:decode-uri($query-params?uri[1]) else $href else $href)"/>-->
    </xsl:function>

    <xsl:function name="sd:endpoint" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))"/>
    </xsl:function>
    
    <xsl:function name="ldh:parse-query-params" as="map(xs:string, xs:string*)">
        <xsl:param name="query-string" as="xs:string"/>

        <xsl:sequence select="map:merge(
            for $query in tokenize($query-string, '&amp;')
            return
                let $param := tokenize($query, '=')
                return map:entry(head($param), tail($param))
            ,
            map { 'duplicates': 'combine' }
        )"/>
    </xsl:function>

    <xsl:function name="ldh:decode-uri" as="map(xs:string, xs:string*)">
        <xsl:param name="encoded-uri" as="xs:string"/>

        <xsl:sequence select="ixsl:call(ixsl:window(), 'decodeURIComponent', [ $encoded-uri ])"/>
    </xsl:function>

    <!-- finds the app with the longest matching base URI -->
    <xsl:function name="ldh:match-app" as="element()?">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="apps" as="document-node()"/>
        
        <xsl:sequence select="let $max-length := max($apps//rdf:Description[ldt:base/@rdf:resource[starts-with($uri, .)]]/string-length(ldt:base/@rdf:resource)) return ($apps//rdf:Description[ldt:base/@rdf:resource[starts-with($uri, .)]][string-length(ldt:base/@rdf:resource) eq $max-length])[1]"/>
    </xsl:function>
    
    <xsl:function name="ldh:query-type" as="xs:string">
        <xsl:param name="query-string" as="xs:string"/>
        
        <xsl:sequence select="analyze-string($query-string, '[^a-zA-Z]?(SELECT|ASK|DESCRIBE|CONSTRUCT)[^a-zA-Z]', 'i')/fn:match[1]/fn:group[@nr = '1']/string()"/>
    </xsl:function>

    <xsl:function name="ldh:new-object">
        <xsl:variable name="js-statement" as="element()">
            <root statement="{{ }}"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:function name="ldh:new" as="item()">
        <xsl:param name="target" as="xs:string"/>
        <xsl:param name="arguments" as="array(*)"/>

        <xsl:sequence select="ixsl:call(ixsl:window(), 'Reflect.construct', [ ixsl:get(ixsl:window(), $target), $arguments ] )"/>
    </xsl:function>
    
    <xsl:function name="ac:build-describe" as="xs:string">
        <xsl:param name="select-string" as="xs:string"/> <!-- already with ?this value set -->
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean"/>

        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <!-- ignore ORDER BY variable name if it's not present in the query -->
        <xsl:variable name="order-by" select="if (ixsl:call($select-builder, 'isVariable', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', [ $order-by ]) ])) then $order-by else ()" as="xs:string?"/>
        <xsl:variable name="select-builder" select="ac:paginate($select-builder, $limit, $offset, $order-by, $desc)"/>
        <xsl:variable name="describe-builder" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'DescribeBuilder'), 'new', []), 'wherePattern', [ ixsl:call($select-builder, 'build', []) ])"/>
        <xsl:sequence select="ixsl:call($describe-builder, 'toString', [ ])"/>
    </xsl:function>
    
    <!-- accepts and returns SelectBuilder. Use ixsl:call(ac:paginate(...), 'toString', []) to get SPARQL string -->
    <xsl:function name="ac:paginate">
        <xsl:param name="select-builder"/> <!-- as SelectBuilder -->
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="$order-by and exists($desc)">
                <xsl:sequence select="ixsl:call(ixsl:call(ixsl:call($select-builder, 'limit', [ $limit ]), 'offset', [ $offset ]), 'orderBy', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'ordering',  [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', [ $order-by ]), $desc ]) ])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:call($select-builder, 'limit', [ $limit ]), 'offset', [ $offset ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- format URLs in DataTable as HTML links -->
    <xsl:template match="@rdf:about[starts-with(., 'http://')] | @rdf:about[starts-with(., 'https://')] | @rdf:resource[starts-with(., 'http://')] | @rdf:resource[starts-with(., 'https://')] | srx:uri[starts-with(., 'http://')] | srx:uri[starts-with(., 'https://')]" mode="ac:DataTable">
        "&lt;a href=\"<xsl:value-of select="."/>\"&gt;<xsl:value-of select="."/>&lt;/a&gt;"
    </xsl:template>

    <!-- in addition to JSON escaping, escape < > in literals so they don't get interpreted as HTML tags -->
    <xsl:template match="srx:literal[@datatype = '&xsd;string' or not(@datatype)]" mode="ac:DataTable">
        "<xsl:value-of select="replace(replace(replace(replace(replace(replace(replace(replace(., '\\', '\\\\'), '&quot;', '\\&quot;'), '/', '\\/'), '&#xA;', '\\n'), '&#xD;', '\\r'), '&#x9;', '\\t'), '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>"
    </xsl:template>

    <!-- in addition to JSON escaping, escape < > in literals so they don't get interpreted as HTML tags -->
    <xsl:template match="rdf:Description/*/text()[../@rdf:datatype = '&xsd;string' or not(../@rdf:datatype)]" mode="ac:DataTable">
        "<xsl:value-of select="replace(replace(replace(replace(replace(replace(replace(replace(., '\\', '\\\\'), '&quot;', '\\&quot;'), '/', '\\/'), '&#xA;', '\\n'), '&#xD;', '\\r'), '&#x9;', '\\t'), '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>"
    </xsl:template>
    
    <xsl:function name="ac:rdf-data-table">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="json" as="xs:string">
            <xsl:value-of>
                <xsl:choose>
                    <xsl:when test="$category">
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="property-uris" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- if no $category specified, show resource URI/ID as category -->
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="resource-ids" select="true()" tunnel="yes"/>
                            <xsl:with-param name="property-uris" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:value-of>
        </xsl:variable>
        
        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.visualization.DataTable(JSON.parse(String.raw`{$json}`))"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:function name="ac:sparql-results-data-table">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="json" as="xs:string">
            <xsl:value-of>
                <xsl:apply-templates select="$results" mode="ac:DataTable">
                    <xsl:with-param name="var-names" select="$category, $series" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:value-of>
        </xsl:variable>

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.visualization.DataTable(JSON.parse(String.raw`{$json}`))"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
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
    
    <xsl:template match="*[@rdf:about = '&ac;ReadMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'read-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;ListMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'list-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;TableMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'table-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;GridMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'grid-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ChartMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'chart-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;MapMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'map-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;GraphMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'graph-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
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
    
    <!-- assuming SELECT query here. what do we do about DESCRIBE/CONSTRUCT? -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&sp;Select'][sp:text]" mode="ldh:Content" priority="1">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:param name="content-uri" select="xs:anyURI(translate(@rdf:about, '.', '-'))" as="xs:anyURI"/>
        <!-- set ?this variable value unless getting the query string from state -->
        <xsl:variable name="select-string" select="replace(sp:text, '\?this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <!-- service can be explicitly specified on content using ldh:service -->
        <xsl:variable name="service-uri" select="xs:anyURI(ldh:service/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        
        <xsl:message>
            ldh:Content $service-uri: <xsl:value-of select="$service-uri"/> exists($service): <xsl:value-of select="exists($service)"/>
        </xsl:message>
        
        <xsl:choose>
            <!-- service URI is not specified or specified and can be loaded -->
            <xsl:when test="not($service-uri) or ($service-uri and exists($service))">
                <!-- window.LinkedDataHub.contents[{$content-uri}] object is already created -->
                <!-- store the initial SELECT query (without modifiers) -->
                <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                <!-- store the first var name of the initial SELECT query -->
                <ixsl:set-property name="focus-var-name" select="$focus-var-name" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                <xsl:if test="$service-uri">
                    <!-- store (the URI of) the service -->
                    <ixsl:set-property name="service-uri" select="$service-uri" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                    <ixsl:set-property name="service" select="$service" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                </xsl:if>

                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit">
                            <xsl:with-param name="limit" select="$page-size" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                            <xsl:with-param name="offset" select="0" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:document>
                </xsl:variable>

                <!-- store the transformed query XML -->
                <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                <!-- update progress bar -->
                <xsl:for-each select="$container//div[@class = 'bar']">
                    <ixsl:set-style name="width" select="'75%'" object="."/>
                </xsl:for-each>

                <xsl:call-template name="ldh:RenderContainer">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="content-uri" select="$content-uri"/>
                    <xsl:with-param name="content" select="."/>
                    <xsl:with-param name="select-string" select="$select-string"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about]" mode="ldh:Content">
        <xsl:param name="container" as="element()"/>

        <!-- hide progress bar -->
        <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>
        
        <xsl:variable name="row-block" as="element()?">
            <xsl:apply-templates select="." mode="bs2:RowBlock"/>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$row-block/*"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="first-time-message">
        <div class="hero-unit">
            <button type="button" class="close">×</button>
            <h1>Your app is ready</h1>
            <h2>Deploy structured data, <em>without coding</em></h2>
            <p>Manage and publish RDF graph data, import CSV, create custom views and visualizations within minutes. Change app structure and API logic without writing code.</p>
            <p class="">
                <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/" class="float-left btn btn-primary btn-large" target="_blank">Learn more</a>
            </p>
        </div>
    </xsl:template>
    
    <!-- CALLBACKS -->

    <!-- ontology loaded -->
<!--    <xsl:template name="ixsl:onOntologyLoad">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:for-each select="?status">
            <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ . ])"/>
        </xsl:for-each>
    </xsl:template>-->
        
    <xsl:template name="ldh:LoadedRDFDocument">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:message>ldh:LoadedRDFDocument $uri: <xsl:value-of select="$uri"/></xsl:message>

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
                    <!-- list items will be injected by ldh:BreadCrumbResourceLoad -->
                </ul>
            </xsl:result-document>

            <xsl:call-template name="ldh:BreadCrumbResourceLoad">
                <xsl:with-param name="id" select="'breadcrumb-nav'"/>
                <!-- strip the query string if it's present -->
                <xsl:with-param name="uri" select="xs:anyURI(if (contains($uri, '?')) then substring-before($uri, '?') else $uri)"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:for-each select="?body">
            <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
            <xsl:variable name="content-uri" select="xs:anyURI(translate($uri, '.', '-'))" as="xs:anyURI"/>
            <ixsl:set-property name="{$content-uri}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
            <!-- store document under window.LinkedDataHub[$content-uri].results -->
            <ixsl:set-property name="results" select="." object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                
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

            <!-- TO-DO: replace hardcoded element ID -->
            <xsl:if test="id('map-canvas', ixsl:page())">
                <xsl:variable name="canvas-id" select="'map-canvas'" as="xs:string"/>
                <xsl:variable name="initial-load" select="true()" as="xs:boolean"/>
                <!-- reuse center and zoom if map object already exists, otherwise set defaults -->
                <xsl:variable name="center-lat" select="56" as="xs:float"/>
                <xsl:variable name="center-lng" select="10" as="xs:float"/>
                <xsl:variable name="zoom" select="4" as="xs:integer"/>
                <xsl:variable name="map" select="ac:create-map($canvas-id, $center-lat, $center-lng, $zoom)"/>
                
                <ixsl:set-property name="map" select="$map" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                
                <xsl:for-each select="//rdf:Description[geo:lat/text() castable as xs:float][geo:long/text() castable as xs:float]">
                    <xsl:call-template name="gm:AddMarker">
                        <xsl:with-param name="map" select="$map"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>

            <!-- TO-DO: replace hardcoded element ID -->
            <xsl:if test="id('chart-canvas', ixsl:page())">
                <xsl:variable name="canvas-id" select="'chart-canvas'" as="xs:string"/>
                <xsl:variable name="results" select="." as="document-node()"/>
                <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
                <xsl:variable name="category" as="xs:string?"/>
                <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                <xsl:variable name="data-table" select="ac:rdf-data-table($results, $category, $series)"/>
                
                <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                <xsl:call-template name="render-chart">
                    <xsl:with-param name="data-table" select="$data-table"/>
                    <xsl:with-param name="canvas-id" select="$canvas-id"/>
                    <xsl:with-param name="chart-type" select="$chart-type"/>
                    <xsl:with-param name="category" select="$category"/>
                    <xsl:with-param name="series" select="$series"/>
                </xsl:call-template>
            </xsl:if>
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
    
    <!-- push states -->
    
<!--    <xsl:template name="ldh:PushContentState">
        <xsl:param name="href" as="xs:anyURI"/>
        <xsl:param name="title" as="xs:string?"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="sparql" select="false()" as="xs:boolean"/>
        <xsl:param name="service-uri" as="xs:anyURI?"/>

        <xsl:variable name="state" as="map(xs:string, item())">
            <xsl:map>
                <xsl:map-entry key="'href'" select="$href"/>
                <xsl:map-entry key="'content-uri'" select="$content-uri"/>
                <xsl:map-entry key="'query-string'" select="$select-string"/>
                <xsl:map-entry key="'sparql'" select="$sparql"/>
                <xsl:if test="$service-uri">
                    <xsl:map-entry key="'service-uri'" select="$service-uri"/>
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="state-obj" select="ixsl:call(ixsl:window(), 'JSON.parse', [ $state => serialize(map{ 'method': 'json' }) ])"/>
        <ixsl:set-property name="query" select="ixsl:call(ixsl:window(), 'JSON.parse', [ xml-to-json($select-xml) ])" object="$state-obj"/>
        
        <xsl:sequence select="ixsl:call(ixsl:window(), 'history.pushState', [ $state-obj, $title ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>-->

    <xsl:template name="ldh:PushState">
         <!-- has to be a proxied URI with the actual URI encoded as ?uri, otherwise we get a "DOMException: The operation is insecure" -->
        <xsl:param name="href" as="xs:anyURI"/>
        <xsl:param name="title" as="xs:string?"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="sparql" select="false()" as="xs:boolean"/>
        <xsl:param name="service-uri" as="xs:anyURI?"/>
        
<!--        <xsl:message>
            ldh:PushState $href: <xsl:value-of select="$href"/> $sparql: <xsl:value-of select="$sparql"/>
        </xsl:message>-->
        
        <xsl:variable name="state" as="map(xs:string, item())">
            <xsl:map>
                <xsl:map-entry key="'href'" select="$href"/>
                <xsl:map-entry key="'container-id'" select="ixsl:get($container, 'id')"/>
                <!--<xsl:map-entry key="'content-uri'" select="$content-uri"/>-->
                <xsl:map-entry key="'query-string'" select="$query"/>
                <xsl:map-entry key="'sparql'" select="$sparql"/>
<!--                <xsl:if test="$service-uri">
                    <xsl:map-entry key="'service'" select="$service-uri"/>
                </xsl:if>-->
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="state-obj" select="ixsl:call(ixsl:window(), 'JSON.parse', [ $state => serialize(map{ 'method': 'json' }) ])"/>

        <!-- push the latest state into history -->
        <xsl:sequence select="ixsl:call(ixsl:window(), 'history.pushState', [ $state-obj, $title, $href ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- load contents -->
    
    <xsl:template name="ldh:LoadContents">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="content-ids" as="xs:string*"/> <!-- workaround for Saxon-JS bug: https://saxonica.plan.io/issues/5036 -->
        <!--<xsl:param name="state" as="item()?"/>-->

<!--        <xsl:for-each select="key('elements-by-class', 'resource-content', ixsl:page())">-->
        <xsl:if test="exists($content-ids)">
            <xsl:for-each select="id($content-ids, ixsl:page())">
                <xsl:variable name="content-uri" select="ixsl:get(., 'dataset.contentUri')" as="xs:anyURI"/> <!-- get the value of the @data-content-uri attribute -->
                <xsl:variable name="container" select="." as="element()"/>
                <xsl:variable name="progress-container" select="if (contains-token(@class, 'row-fluid')) then ./div[contains-token(@class, 'span7')] else ." as="element()"/>

                <!-- show progress bar in the middle column -->
                <xsl:for-each select="$progress-container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div class="progress-bar">
                            <div class="progress progress-striped active">
                                <div class="bar" style="width: 25%;"></div>
                            </div>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:variable name="request-uri" select="ldh:href($ldt:base, $content-uri)" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': ac:document-uri($request-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                        <xsl:call-template name="onContentLoad">
                            <xsl:with-param name="uri" select="$uri"/>
                            <xsl:with-param name="content-uri" select="$content-uri"/>
                            <xsl:with-param name="container" select="$container"/>
                            <!--<xsl:with-param name="state" select="$state"/>-->
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <!-- load RDF document -->
    
    <xsl:template name="ldh:LoadRDFDocument">
        <xsl:param name="uri" as="xs:anyURI"/>
        <!-- if the URI is external, dereference it through the proxy -->
        <!-- add a bogus query parameter to give the RDF/XML document a different URL in the browser cache, otherwise it will clash with the HTML representation -->
        <!-- this is due to broken browser behavior re. Vary and conditional requests: https://stackoverflow.com/questions/60799116/firefox-if-none-match-headers-ignore-content-type-and-vary/60802443 -->
        <xsl:variable name="request-uri" select="ac:build-uri(ldh:absolute-path(ldh:href()), let $params := map{ 'param': 'dummy' } return if (not(starts-with($uri, $ldt:base))) then map:merge(($params, map{ 'uri': $uri })) else $params)" as="xs:anyURI"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:LoadedRDFDocument">
                    <xsl:with-param name="uri" select="$uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- show "Add data"/"Save as" form -->
    
    <xsl:template name="ldh:ShowAddDataForm">
        <xsl:param name="id" select="'add-data'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary btn-save'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="source" as="xs:anyURI?"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="container" as="xs:anyURI?"/>
        
        <!-- don't append the div if it's already there -->
        <xsl:if test="not(id($id, ixsl:page()))">
            <xsl:for-each select="ixsl:page()//body">
                <!-- append modal div to body -->
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div class="modal modal-constructor fade in">
                        <xsl:if test="$id">
                            <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                        </xsl:if>

                        <div class="modal-header">
                            <button type="button" class="close">&#215;</button>

                            <legend title="Add RDF data">Add RDF data</legend>
                        </div>

                        <div class="modal-body">
                            <div class="tabbable">
                                <ul class="nav nav-tabs">
                                    <li>
                                        <xsl:if test="not($source)">
                                            <xsl:attribute name="class">active</xsl:attribute>
                                        </xsl:if>

                                        <a>Upload file</a>
                                    </li>
                                    <li>
                                        <xsl:if test="$source">
                                            <xsl:attribute name="class">active</xsl:attribute>
                                        </xsl:if>

                                        <a>From URI</a>
                                    </li>
                                </ul>
                                <div class="tab-content">
                                    <div>
                                        <xsl:attribute name="class">tab-pane <xsl:if test="not($source)">active</xsl:if></xsl:attribute>

                                        <form id="form-add-data" method="POST" action="{ac:build-uri(resolve-uri('add', $ldt:base), map{ 'forClass': '&nfo;FileDataObject' })}" enctype="multipart/form-data">
                                            <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
                                            <xsl:call-template name="xhtml:Input">
                                                <xsl:with-param name="name" select="'rdf'"/>
                                                <xsl:with-param name="type" select="'hidden'"/>
                                            </xsl:call-template>

                                            <fieldset>
                                                <input type="hidden" name="sb" value="file"/>
                                                <input type="hidden" name="pu" value="&rdf;type"/>
                                                <input type="hidden" name="ou" value="&nfo;FileDataObject"/>

                                                <!-- file title is unused, just needed to pass the ldh:File constraints -->
                                                <input type="hidden" name="pu" value="&dct;title"/>
                                                <input id="upload-rdf-title" type="hidden" name="ol" value="RDF upload"/>

                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&dct;format"/>
                                                    <label class="control-label" for="upload-rdf-format">Format</label>
                                                    <div class="controls">
                                                        <select id="upload-rdf-format" name="ol">
                                                            <!--<option value="">[browser-defined]</option>-->
                                                            <optgroup label="RDF triples">
                                                                <option value="text/turtle">Turtle (.ttl)</option>
                                                                <option value="application/n-triples">N-Triples (.nt)</option>
                                                                <option value="application/rdf+xml">RDF/XML (.rdf)</option>
                                                            </optgroup>
                                                            <optgroup label="RDF quads">
                                                                <option value="text/trig">TriG (.trig)</option>
                                                                <option value="application/n-quads">N-Quads (.nq)</option>
                                                            </optgroup>
                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&nfo;fileName"/>
                                                    <label class="control-label" for="upload-rdf-filename">FileName</label>
                                                    <div class="controls">
                                                        <input id="upload-rdf-filename" type="file" name="ol"/>
                                                    </div>
                                                </div>
                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&sd;name"/>
                                                    <label class="control-label" for="upload-rdf-doc">Graph</label>
                                                    <div class="controls">
                                                        <span>
                                                            <input type="text" name="ou" id="upload-rdf-doc" class="resource-typeahead typeahead"/>
                                                            <ul class="resource-typeahead typeahead dropdown-menu" id="ul-upload-rdf-doc" style="display: none;"></ul>
                                                        </span>

                                                        <input type="hidden" class="forClass" value="&dh;Container" autocomplete="off"/>
                                                        <input type="hidden" class="forClass" value="&dh;Item" autocomplete="off"/>
                                                        <div class="btn-group">
                                                            <button type="button" class="btn dropdown-toggle create-action"></button>
                                                            <ul class="dropdown-menu">
                                                                <li>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Container'))}" class="btn add-constructor" title="&dh;Container" id="{generate-id()}-upload-rdf-container">
                                                                        <xsl:text>Container</xsl:text>
                                                                        <input type="hidden" class="forClass" value="&dh;Container"/>
                                                                    </a>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Item'))}" class="btn add-constructor" title="&dh;Item" id="{generate-id()}-upload-rdf-item">
                                                                        <xsl:text>Item</xsl:text>
                                                                        <input type="hidden" class="forClass" value="&dh;Item"/>
                                                                    </a>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                        <span class="help-inline">Document</span>
                                                    </div>
                                                </div>
                                            </fieldset>

                                            <div class="form-actions modal-footer">
                                                <button type="submit" class="{$button-class}">Save</button>
                                                <button type="button" class="btn btn-close">Close</button>
                                                <button type="reset" class="btn btn-reset">Reset</button>
                                            </div>
                                        </form>
                                    </div>
                                    <div>
                                        <xsl:attribute name="class">tab-pane <xsl:if test="$source">active</xsl:if></xsl:attribute>

                                        <form id="form-clone-data" method="POST" action="{resolve-uri('clone', $ldt:base)}">
                                            <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
                                            <xsl:call-template name="xhtml:Input">
                                                <xsl:with-param name="name" select="'rdf'"/>
                                                <xsl:with-param name="type" select="'hidden'"/>
                                            </xsl:call-template>

                                            <fieldset>
                                                <input type="hidden" name="sb" value="clone"/>

                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&dct;source"/>
                                                    <label class="control-label" for="remote-rdf-source">Source</label>
                                                    <div class="controls">
                                                        <input type="text" id="remote-rdf-source" name="ou" class="input-xxlarge">
                                                            <xsl:if test="$source">
                                                                <xsl:attribute name="value">
                                                                    <xsl:value-of select="$source"/>
                                                                </xsl:attribute>
                                                            </xsl:if>
                                                        </input>
                                                        <span class="help-inline">Resource</span>
                                                    </div>
                                                </div>
                                                <div class="control-group required">
                                                    <input type="hidden" name="pu" value="&sd;name"/>
                                                    <label class="control-label" for="remote-rdf-doc">Graph</label>
                                                    <div class="controls">
                                                        <span>
                                                            <input type="text" name="ou" id="remote-rdf-doc" class="resource-typeahead typeahead"/>
                                                            <ul class="resource-typeahead typeahead dropdown-menu" id="ul-upload-rdf-doc" style="display: none;"></ul>
                                                        </span>

                                                        <input type="hidden" class="forClass" value="&dh;Container" autocomplete="off"/>
                                                        <input type="hidden" class="forClass" value="&dh;Item" autocomplete="off"/>
                                                        <div class="btn-group">
                                                            <button type="button" class="btn dropdown-toggle create-action"></button>
                                                            <ul class="dropdown-menu">
                                                                <li>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Container'))}" class="btn add-constructor" title="&dh;Container" id="{generate-id()}-remote-rdf-container">
                                                                        <xsl:text>Container</xsl:text>
                                                                        <input type="hidden" class="forClass" value="&dh;Container"/>
                                                                    </a>
                                                                </li>
                                                                <li>
                                                                    <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), xs:anyURI('&ac;ModalMode'), xs:anyURI('&dh;Item'))}" type="button" class="btn add-constructor" title="&dh;Item" id="{generate-id()}-remote-rdf-item">
                                                                        <xsl:text>Item</xsl:text>
                                                                        <input type="hidden" class="forClass" value="&dh;Item"/>
                                                                    </a>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                        <span class="help-inline">Document</span>
                                                    </div>
                                                </div>
                                            </fieldset>

                                            <div class="form-actions modal-footer">
                                                <button type="submit" class="{$button-class}">Save</button>
                                                <button type="button" class="btn btn-close">Close</button>
                                                <button type="reset" class="btn btn-reset">Reset</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>

                            <div class="alert alert-info">
                                <p>Adding data this way will cause a blocking request, so use it for small amounts of data only (e.g. a few thousands of RDF triples). For larger data, use asynchronous <a href="https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/imports/rdf/" target="_blank">RDF imports</a>.</p>
                            </div>
                        </div>
                    </div>
                </xsl:result-document>
                
                <xsl:if test="$container">
                    <!-- fill the container typeahead value, if it's provided -->
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $container, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                            <xsl:call-template name="onTypeaheadResourceLoad">
                                <xsl:with-param name="resource-uri" select="$container"/>
                                <xsl:with-param name="typeahead-span" select="id('remote-rdf-doc', ixsl:page())/.."/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>

                <ixsl:set-style name="cursor" select="'default'"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <!-- root children list (unused) -->
    
    <xsl:template name="ldh:RootLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="id" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="select-uri" select="key('resources', $ldt:base)/dh:select/@rdf:resource" as="xs:anyURI?"/>
                    <xsl:if test="$select-uri">
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $select-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="ldh:RootChildrenSelectLoad">
                                    <xsl:with-param name="id" select="$id"/>
                                    <xsl:with-param name="this-uri" select="$ldt:base"/>
                                    <xsl:with-param name="select-uri" select="$select-uri"/>
                                    <xsl:with-param name="endpoint" select="resolve-uri('sparql', $ldt:base)"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ldh:RootChildrenSelectLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="this-uri" as="xs:anyURI"/>
        <xsl:param name="select-uri" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="select" select="key('resources', $select-uri)" as="element()?"/>
                    <xsl:variable name="select-string" select="$select/sp:text" as="xs:string?"/>
                    <xsl:if test="$select-string">
                        <!--turn SELECT into DESCRIBE - no point in using ac:build-describe() as we don't want pagination here--> 
                        <!--TO-DO: use CONSTRUCT to only pull dct:titles?--> 
                        <xsl:variable name="query-string" select="replace($select-string, 'DISTINCT', '')" as="xs:string"/>
                        <xsl:variable name="query-string" select="replace($query-string, 'SELECT', 'DESCRIBE')" as="xs:string"/>
                         <!--set ?this variable value--> 
                        <xsl:variable name="query-string" select="replace($query-string, '\?this', concat('&lt;', $this-uri, '&gt;'))" as="xs:string"/>
                        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>

                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="ldh:RootChildrenResultsLoad">
                                    <xsl:with-param name="id" select="$id"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ldh:RootChildrenResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="id" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="results" select="." as="document-node()"/>
                        <xsl:variable name="container-list" as="element()*">
                            <xsl:for-each select="key('resources-by-container', $ldt:base, $results)">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                <xsl:apply-templates select="." mode="bs2:List">
                                    <xsl:with-param name="active" select="starts-with(ldh:absolute-path(ldh:href()), @rdf:about)"/>
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </xsl:variable>

                        <xsl:result-document href="#{$id}" method="ixsl:replace-content">
                            <xsl:if test="$container-list">
                                <div class="well well-small">
                                    <h2 class="nav-header">
                                        <a href="{$ldt:base}" title="{$ldt:base}">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'root', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </a>
                                    </h2>
                                    <ul class="nav nav-list">
                                        <xsl:copy-of select="$container-list"/>
                                    </ul>
                                </div>
                            </xsl:if>
                        </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="#{$id}" method="ixsl:replace-content">
                    <div class="alert alert-block">Error loading root children</div>
                </xsl:result-document>
                <!--<xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- render dropdown for root containers -->
    <xsl:template match="*[@rdf:about = ($ldt:base, resolve-uri('charts/', $ldt:base), resolve-uri('files/', $ldt:base), resolve-uri('geo/', $ldt:base), resolve-uri('imports/', $ldt:base), resolve-uri('latest/', $ldt:base), resolve-uri('apps/', $ldt:base), resolve-uri('services/', $ldt:base), resolve-uri('queries/', $ldt:base))]" mode="bs2:BreadCrumbListItem" priority="1">
        <xsl:param name="leaf" select="true()" as="xs:boolean"/>

        <li>
            <div class="btn-group">
                <button class="btn dropdown-toggle" type="button">
                    <xsl:apply-templates select="." mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                    </xsl:apply-templates>
                    
                    <span class="caret"></span>
                </button>

                <ul class="dropdown-menu">
                    <!-- TO-DO: replace with an RDF/XML document and ldh:logo/xhtml:Anchor calls -->
                    <li>
                        <a href="{$ldt:base}" class="btn-logo btn-container">Root</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}apps/" class="btn-logo btn-app">Applications</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}charts/" class="btn-logo btn-chart">Charts</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}files/" class="btn-logo btn-file">Files</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}geo/" class="btn-logo btn-geo">Geo</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}imports/" class="btn-logo btn-import">Imports</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}latest/" class="btn-logo btn-latest">Latest</a>
                    </li>
                    <li>
                        <a href="{$ldt:base}queries/" class="btn-logo btn-query">Queries</a>
                    </li>
                </ul>
            </div>

            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="xhtml:Anchor">
                <xsl:with-param name="id" select="()"/>
            </xsl:apply-templates>

            <xsl:if test="not($leaf)">
                <span class="divider">/</span>
            </xsl:if>
        </li>
    </xsl:template>

    <!-- service select -->
    
    <xsl:template name="ldh:RenderServices">
        <xsl:param name="select" as="element()"/>
        <xsl:param name="apps" as="document-node()"/>
        <xsl:param name="selected-service" as="xs:anyURI?"/>
        
        <xsl:for-each select="$select">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <option value="">[SPARQL service]</option>
                
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
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="results-container-id" select="$container-id || '-sparql-results'" as="xs:string"/>
        <xsl:param name="chart-canvas-id" select="$container-id || '-chart-canvas'" as="xs:string"/>
        <xsl:param name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="textarea-id" select="'query-string'" as="xs:string"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="content-method" select="xs:QName('ixsl:replace-content')" as="xs:QName"/>
        <xsl:param name="show-editor" select="true()" as="xs:boolean"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="not(id($results-container-id, ixsl:page()))">
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div id="{$results-container-id}" class="sparql-results" data-content-uri="{$content-uri}"/> <!-- used as $content-uri in chart form's onchange events -->
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- update @data-content-uri value -->
                <xsl:for-each select="id($results-container-id, ixsl:page())">
                    <ixsl:set-property name="dataset.contentUri" select="$content-uri" object="."/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

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
                    
                    <xsl:result-document href="#{$results-container-id}" method="ixsl:replace-content">
                        <xsl:apply-templates select="$results" mode="bs2:Chart">
                            <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                            <xsl:with-param name="chart-type" select="$chart-type"/>
                            <xsl:with-param name="category" select="$category"/>
                            <xsl:with-param name="series" select="$series"/>
                        </xsl:apply-templates>
                    </xsl:result-document>

                    <!-- create new cache entry using content URI as key -->
                    <ixsl:set-property name="{$content-uri}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                    <ixsl:set-property name="results" select="$results" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                    <xsl:variable name="data-table" select="if ($results/rdf:RDF) then ac:rdf-data-table($results, $category, $series) else ac:sparql-results-data-table($results, $category, $series)"/>
                    <ixsl:set-property name="data-table" select="$data-table" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)"/>
                    
                    <xsl:call-template name="render-chart">
                        <xsl:with-param name="data-table" select="$data-table"/>
                        <xsl:with-param name="canvas-id" select="$chart-canvas-id"/>
                        <xsl:with-param name="chart-type" select="$chart-type"/>
                        <xsl:with-param name="category" select="$category"/>
                        <xsl:with-param name="series" select="$series"/>
                    </xsl:call-template>

<!--                    <xsl:if test="$push-state">
                        <xsl:call-template name="ldh:PushState">
                            <xsl:with-param name="href" select="ldh:href($ldt:base, $content-uri)"/>
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="query" select="$query"/>
                            <xsl:with-param name="sparql" select="true()"/>
                        </xsl:call-template>
                    </xsl:if>-->
                    
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
                <xsl:result-document href="#{$results-container-id}" method="ixsl:replace-content">
                    <div class="alert alert-block">
                        <strong>Error during query execution:</strong>
                        <pre>
                            <xsl:value-of select="$response?message"/>
                        </pre>
                    </div>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- embed content -->
    
    <xsl:template name="onContentLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="content-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <!--<xsl:param name="state" as="item()?"/>-->

        <xsl:message>
            onContentLoad
            $uri: <xsl:value-of select="$uri"/> $content-uri: <xsl:value-of select="$content-uri"/> $container-id: <xsl:value-of select="$container-id"/>
            ?status: <xsl:value-of select="?status"/> exists(key('resources', $content-uri, ?body)): <xsl:value-of select="exists(key('resources', $content-uri, ?body))"/>
        </xsl:message>
        
        <xsl:variable name="content" select="key('resources', $content-uri, ?body)" as="element()?"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml' and $content">
                <!-- replace dots which have a special meaning in Saxon-JS -->
                <xsl:variable name="escaped-content-uri" select="xs:anyURI(translate($content-uri, '.', '-'))" as="xs:anyURI"/>
                <!-- create new cache entry using content URI as key -->
                <ixsl:set-property name="{$escaped-content-uri}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                <!-- store this content element -->
                <ixsl:set-property name="content" select="$content" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri)"/>

                <xsl:for-each select="$container//div[@class = 'bar']">
                    <!-- update progress bar -->
                    <ixsl:set-style name="width" select="'50%'" object="."/>
                </xsl:for-each>

                <xsl:apply-templates select="$content" mode="ldh:Content">
                    <xsl:with-param name="uri" select="$uri"/>
                    <xsl:with-param name="container" select="$container"/>
                    <!--<xsl:with-param name="state" select="$state"/>-->
                </xsl:apply-templates>
            </xsl:when>
            <!-- content could not be loaded as RDF -->
            <xsl:when test="?status = 406">
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <object data="{$content-uri}"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content resource: <a href="{$content-uri}"><xsl:value-of select="$content-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Linked Data browser -->
    
    <xsl:template name="onDocumentLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="href" as="xs:anyURI?"/>
        <!--<xsl:param name="fragment" as="xs:string?"/>-->
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:param name="fallback" select="false()" as="xs:boolean"/>
        <xsl:param name="service-uri" select="if (id('search-service', ixsl:page())) then xs:anyURI(ixsl:get(id('search-service', ixsl:page()), 'value')) else ()" as="xs:anyURI?"/>
        <xsl:param name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        
        <xsl:message>
            onDocumentLoad
            $href: <xsl:value-of select="$href"/>
            $container/@id: <xsl:value-of select="$container/@id"/>
            $push-state: <xsl:value-of select="$push-state"/>
            ?status: <xsl:value-of select="?status"/>
            <!--ixsl:get(ixsl:window(), 'history.state.href'): <xsl:value-of select="ixsl:get(ixsl:window(), 'history.state.href')"/>-->
        </xsl:message>

        <xsl:variable name="response" select="." as="map(*)"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:variable name="endpoint-link" select="tokenize(?headers?link, ',')[contains(., '&sd;endpoint')]" as="xs:string?"/>
                <xsl:variable name="endpoint" select="if ($endpoint-link) then xs:anyURI(substring-before(substring-after(substring-before($endpoint-link, ';'), '&lt;'), '&gt;')) else ()" as="xs:anyURI?"/>

                <xsl:apply-templates select="?body" mode="ldh:LoadedHTMLDocument">
                    <xsl:with-param name="href" select="$href"/>
                    <!--<xsl:with-param name="fragment" select="$fragment"/>-->
                    <!--<xsl:with-param name="uri" select="ac:uri()"/>-->
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="push-state" select="$push-state"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="?status = 0">
                <!-- HTTP request was terminated - do nothing -->
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                
                <!-- error response - could not load query results -->
                <xsl:result-document href="#content-body" method="ixsl:replace-content">
                    <xsl:choose>
                        <xsl:when test="id('content-body', ?body)">
                            <xsl:copy-of select="id('content-body', ?body)/*"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <div class="alert alert-block">
                                <strong>Error loading RDF document</strong>
                                <xsl:if test="$response?message">
                                    <pre>
                                        <xsl:value-of select="$response?message"/>
                                    </pre>
                                </xsl:if>
                            </div>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- cannot be a named template because overriding templates need to be able to call xsl:next-match (cannot use xsl:origin with Saxon-JS because of XSLT 3.0 packages) -->
    <xsl:template match="/" mode="ldh:LoadedHTMLDocument">
        <xsl:param name="href" as="xs:anyURI"/> <!-- possibly proxied URL -->
        <!-- decode raw URL from the ?uri query param, if it's present -->
        <xsl:param name="uri" select="if (contains($href, '?')) then let $query-params := ldh:parse-query-params(substring-after($href, '?')) return if (exists($query-params?uri)) then ldh:decode-uri($query-params?uri[1]) else () else ()" as="xs:anyURI"/> <!-- raw URL -->
        <xsl:param name="fragment" select="encode-for-uri($uri)" as="xs:string?"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="push-state" select="true()" as="xs:boolean"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="replace-content" select="true()" as="xs:boolean"/>
        
        <xsl:message>From <xsl:value-of select="$href"/> loaded document with URI: <xsl:value-of select="$uri"/> fragment: <xsl:value-of select="$fragment"/></xsl:message>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        <!-- enable .btn-edit if it's present -->
        <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//a[contains-token(@class, 'btn-edit')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'disabled', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- enable .btn-save-as if it's present -->
        <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'btn-save-as')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'disabled', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <ixsl:set-property name="uri" select="$uri" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <xsl:if test="$endpoint">
            <ixsl:set-property name="endpoint" select="$endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        </xsl:if>
        
        <!-- update the a.btn-edit link if it is visible -->
        <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//a[contains-token(@class, 'btn-edit')]">
            <xsl:variable name="edit-uri" select="ldh:href($ldt:base, $uri, xs:anyURI('&ac;EditMode'))" as="xs:anyURI"/>
            <ixsl:set-attribute name="href" select="$edit-uri" object="."/>
        </xsl:for-each>

        <xsl:choose>
            <!-- local URI -->
            <xsl:when test="starts-with($uri, $ldt:base)">
                <!-- enable .btn-skolemize -->
                <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'btn-skolemize')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'disabled', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <!-- unset #uri value -->
                <xsl:for-each select="id('uri', ixsl:page())">
                    <ixsl:set-property name="value" select="()" object="."/>
                </xsl:for-each>
            </xsl:when>
            <!-- external URI -->
            <xsl:otherwise>
                <!-- disable .btn-skolemize -->
                <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'btn-skolemize')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'disabled', true() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <!-- set #uri value -->
                <xsl:for-each select="id('uri', ixsl:page())">
                    <ixsl:set-property name="value" select="$uri" object="."/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="$push-state">
            <xsl:call-template name="ldh:PushState">
                <xsl:with-param name="href" select="$href"/>
                <xsl:with-param name="title" select="/html/head/title"/>
                <xsl:with-param name="container" select="$container"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test="$replace-content">
            <!-- set document.title which history.pushState() does not do -->
            <ixsl:set-property name="title" select="string(/html/head/title)" object="ixsl:page()"/>

            <xsl:variable name="results" select="." as="document-node()"/>

            <!-- replace content body with the loaded XHTML -->
            <xsl:for-each select="$container">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:copy-of select="id($container/@id, $results)/*"/>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:choose>
                <!-- scroll fragment-identified element into view if fragment is provided-->
                <xsl:when test="$fragment">
                    <xsl:message>
                        exists(id($fragment, ixsl:page())): <xsl:value-of select="exists(id($fragment, ixsl:page()))"/>
                    </xsl:message>
                    
                    <xsl:for-each select="id($fragment, ixsl:page())">
                        <xsl:sequence select="ixsl:call(., 'scrollIntoView', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each >
                </xsl:when>
                <!-- otherwise, scroll to the top of the window -->
                <xsl:otherwise>
                    <xsl:sequence select="ixsl:call(ixsl:window(), 'scrollTo', [ 0, 0 ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:otherwise>
            </xsl:choose>

            <!-- update RDF download links to match the current URI -->
            <xsl:for-each select="id('export-rdf', ixsl:page())/following-sibling::ul/li/a">
                <!-- use @title attribute for the media type TO-DO: find a better way, a hidden input or smth -->
                <xsl:variable name="href" select="ac:build-uri(ldh:absolute-path(ldh:href()), let $params := map{ 'accept': string(@title) } return if (not(starts-with(ldh:absolute-path(ldh:href()), $ldt:base))) then map:merge(($params, map{ 'uri': ldh:absolute-path(ldh:href()) })) else $params)" as="xs:anyURI"/>
                <ixsl:set-attribute name="href" select="$href" object="."/>
            </xsl:for-each>
        </xsl:if>

        <!-- this has to go after <xsl:result-document href="#{$container-id}"> because otherwise new elements will be injected and the $content-ids lookup will not work anymore -->
        <xsl:variable name="content-ids" select="key('elements-by-class', 'resource-content')/@id" as="xs:string*"/>
        <xsl:call-template name="ldh:LoadContents">
            <xsl:with-param name="uri" select="$uri"/>
            <xsl:with-param name="content-ids" select="$content-ids"/>
            <!--<xsl:with-param name="state" select="$state"/>-->
        </xsl:call-template>
        
        <xsl:call-template name="ldh:LoadRDFDocument">
            <xsl:with-param name="uri" select="$uri"/>
        </xsl:call-template>
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

            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <!-- decode URI from the ?uri query param if the URI was proxied -->
            <xsl:variable name="uri" select="if (contains($href, '?uri=')) then xs:anyURI(ixsl:call(ixsl:window(), 'decodeURIComponent', [ substring-after($href, '?uri=') ])) else $href" as="xs:anyURI"/>
<!--            <xsl:message>
                onpopstate
                $href: <xsl:value-of select="$href"/>
                $uri: <xsl:value-of select="$uri"/>
                $query-string: <xsl:value-of select="$query-string"/>
                $sparql: <xsl:value-of select="$sparql"/>
            </xsl:message>-->

            <!-- TO-DO: do we need to proxy the $uri here? -->
            <xsl:choose>
                <xsl:when test="$sparql">
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }">
                            <xsl:call-template name="onSPARQLResultsLoad">
                                <xsl:with-param name="content-uri" select="$uri"/>
                                <xsl:with-param name="container" select="id($container-id, ixsl:page())"/>
                                <!-- we don't want to push a state that was just popped -->
                                <xsl:with-param name="push-state" select="false()"/>
                                <xsl:with-param name="query" select="$query-string"/>
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
                            <xsl:call-template name="onDocumentLoad">
                                <xsl:with-param name="href" select="$href"/>
                                <!--<xsl:with-param name="fragment" select="encode-for-uri($href)"/>-->
                                <!--<xsl:with-param name="state" select="$state"/>-->
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
    
    <!-- intercept all link HTTP(S) clicks except to /uploads/ and those in the navbar (except breadcrumb bar, .brand and app list) and the footer -->
    <xsl:template match="a[not(@target)][starts-with(@href, 'http://') or starts-with(@href, 'https://')][not(starts-with(@href, resolve-uri('uploads/', $ldt:base)))][ancestor::div[@id = 'breadcrumb-nav'] or not(ancestor::div[tokenize(@class, ' ') = ('navbar', 'footer')])] | a[contains-token(@class, 'brand')] | div[button[contains-token(@class, 'btn-apps')]]/ul//a" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="href" select="@href" as="xs:anyURI"/>
        <!-- $href is already proxied server-side -->
        <!--<xsl:variable name="request-uri" select="ldh:href($ldt:base, $href)" as="xs:anyURI"/>-->
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- abort the previous request, if any -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
        </xsl:if>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onDocumentLoad">
                    <xsl:with-param name="href" select="$href"/>
                    <!--<xsl:with-param name="fragment" select="encode-for-uri($href)"/>-->
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
            <xsl:variable name="href" select="ldh:href($ldt:base, $uri)" as="xs:anyURI"/>
            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <!-- abort the previous request, if any -->
            <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
                <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
            </xsl:if>

            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                    <xsl:call-template name="onDocumentLoad">
                        <xsl:with-param name="href" select="ac:document-uri($href)"/>
                        <!--<xsl:with-param name="fragment" select="encode-for-uri($uri)"/>-->
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
                <xsl:message>Resource deleted. Redirect to parent URI: <xsl:value-of select="$href"/></xsl:message>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, $href)" as="xs:anyURI"/>

                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="onDocumentLoad">
                            <xsl:with-param name="href" select="$href"/>
                            <!--<xsl:with-param name="fragment" select="encode-for-uri($href)"/>-->
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onSkolemize">
        <xsl:context-item as="map(*)" use="required"/>
        
        <xsl:choose>
            <xsl:when test="?status = (200, 201)"> <!-- OK / Created -->
                <xsl:variable name="href" select="ac:uri()" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, $href)" as="xs:anyURI"/>

                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="onDocumentLoad">
                            <xsl:with-param name="href" select="$href"/>
                            <!--<xsl:with-param name="fragment" select="encode-for-uri($href)"/>-->
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- validate form before submitting it and show errors on control-groups where input values are missing -->
    <xsl:template match="form[@id = 'form-add-data'] | form[@id = 'form-clone-data']" mode="ixsl:onsubmit" priority="1">
        <xsl:variable name="control-groups" select="descendant::div[contains-token(@class, 'control-group')][input[@name = 'pu'][@value = ('&nfo;fileName', '&dct;source', '&sd;name')]]" as="element()*"/>
        <xsl:choose>
            <!-- values missing, throw an error -->
            <xsl:when test="some $input in $control-groups/descendant::input[@name = ('ol', 'ou')] satisfies not(ixsl:get($input, 'value'))">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
                <xsl:sequence select="$control-groups/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present, apply the default form onsubmit -->
            <xsl:otherwise>
                <xsl:sequence select="$control-groups/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- open drop-down by toggling its CSS class -->

    <xsl:template match="*[contains-token(@class, 'btn-group')][*[contains-token(@class, 'dropdown-toggle')]]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'open' ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="div[contains-token(@class, 'hero-unit')]/button[contains-token(@class, 'close')]" mode="ixsl:onclick" priority="1">
        <!-- remove the hero-unit -->
        <xsl:for-each select="..">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'remove', [])"/>
            </xsl:message>
        </xsl:for-each>
        <!-- set a cookie to never show it again -->
        <ixsl:set-property name="cookie" select="concat('LinkedDataHub.first-time-message=true; path=/', substring-after($ldt:base, $ac:contextUri), '; expires=Fri, 31 Dec 9999 23:59:59 GMT')" object="ixsl:page()"/>
    </xsl:template>
    
    <!-- trigger typeahead in the search bar -->
    
    <xsl:template match="input[@id = 'uri']" mode="ixsl:onkeyup" priority="1">
        <xsl:param name="text" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:param name="menu" select="following-sibling::ul" as="element()"/>
        <xsl:param name="delay" select="400" as="xs:integer"/>
        <xsl:param name="resource-types" as="xs:anyURI?"/>
        <xsl:param name="select-string" select="$select-labelled-string" as="xs:string"/>
        <xsl:param name="limit" select="100" as="xs:integer"/>
        <xsl:variable name="key-code" select="ixsl:get(ixsl:event(), 'code')" as="xs:string"/>
        <!-- TO-DO: refactor query building using XSLT -->
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <!-- pseudo JS code: SPARQLBuilder.SelectBuilder.fromString(select-builder).wherePattern(SPARQLBuilder.QueryBuilder.filter(SPARQLBuilder.QueryBuilder.regex(QueryBuilder.var("label"), QueryBuilder.term(QueryBuilder.str($text))))) -->
        <xsl:variable name="select-builder" select="ixsl:call($select-builder, 'wherePattern', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'filter', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'regex', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'str', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ 'label' ]) ]), ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'term', [ ac:escape-regex($text) ]), true() ] ) ] ) ])"/>
        <xsl:variable name="select-string" select="ixsl:call($select-builder, 'toString', [])" as="xs:string"/>
        <xsl:variable name="query-string" select="ac:build-describe($select-string, $limit, (), (), true())" as="xs:string"/>
        <xsl:variable name="service-uri" select="xs:anyURI(ixsl:get(id('search-service'), 'value'))" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), resolve-uri('sparql', $ldt:base))[1]" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $results-uri)" as="xs:anyURI"/>
        <!-- TO-DO: use <ixsl:schedule-action> instead -->
        <xsl:variable name="results" select="document($request-uri)" as="document-node()"/>

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
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, $uri)" as="xs:anyURI"/>
                    
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <!-- abort the previous request, if any -->
                    <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
                        <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
                        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
                    </xsl:if>

                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                            <xsl:call-template name="onDocumentLoad">
                                <xsl:with-param name="href" select="ac:document-uri($uri)"/>
                                <!--<xsl:with-param name="fragment" select="encode-for-uri($uri)"/>-->
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
            <!-- ignore URIs in the input -->
            <xsl:when test="not(starts-with(ixsl:get(., 'value'), 'http://')) and not(starts-with(ixsl:get(., 'value'), 'https://'))">
                <ixsl:schedule-action wait="$delay">
                    <xsl:call-template name="typeahead:load-xml">
                        <xsl:with-param name="element" select="."/>
                        <xsl:with-param name="query" select="$text"/>
                        <xsl:with-param name="uri" select="$results-uri"/>
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
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $uri)" as="xs:anyURI"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- abort the previous request, if any -->
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub'), 'request')">
            <xsl:message>Aborting HTTP request that has already been sent</xsl:message>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'LinkedDataHub.request'), 'abort', [])"/>
        </xsl:if>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onDocumentLoad">
                    <xsl:with-param name="href" select="ac:document-uri($uri)"/>
                    <!--<xsl:with-param name="fragment" select="encode-for-uri($uri)"/>-->
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

        <!-- disable action buttons -->
        <xsl:for-each select="ixsl:page()//div[contains-token(@class, 'action-bar')]//button[tokenize(@class, ' ') = ('btn-edit', 'btn-save-as', 'btn-skolemize')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'disabled', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

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

    <xsl:template match="button[contains-token(@class, 'btn-add-data')]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="container" select="ldh:absolute-path(ldh:href())"/>
        </xsl:call-template>
    </xsl:template>

    <!-- open editing form (do nothing if the button is disabled) -->
    <xsl:template match="a[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="href" select="@href" as="xs:anyURI"/>
        <xsl:message>GRAPH URI: <xsl:value-of select="$href"/></xsl:message>

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
                <xsl:with-param name="href" select="ldh:href($ldt:base, $href)"/>
                <!--<xsl:with-param name="title" select="/html/head/title"/>-->
                <xsl:with-param name="container" select="id('content-body', ixsl:page())"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'btn-delete')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="uri" select="ac:uri()" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $uri, xs:anyURI('&ac;EditMode'))" as="xs:anyURI"/>

        <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ 'Are you sure?' ])">
            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'DELETE', 'href': $request-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                    <xsl:call-template name="onDelete"/>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'btn-skolemize')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="uri" select="ac:build-uri(resolve-uri('skolemize', $ldt:base), map{ 'graph': string(ac:uri()) })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="$uri" as="xs:anyURI"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': $request-uri, 'headers': map{ 'Content-Type': 'application/rdf+x-www-form-urlencoded' } }">
                <xsl:call-template name="onSkolemize"/>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- content tabs (markup from Bootstrap) -->
    <xsl:template match="div[contains-token(@class, 'tabbable')]/ul[contains-token(@class, 'nav-tabs')]/li/a" mode="ixsl:onclick">
        <!-- deactivate other tabs -->
        <xsl:for-each select="../../li">
            <ixsl:set-attribute name="class" select="string-join(tokenize(@class, ' ')[not(. = 'active')], ' ')"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="..">
            <ixsl:set-attribute name="class" select="'active'"/>
        </xsl:for-each>
        <!-- deactivate other tab panes -->
        <xsl:for-each select="../../following-sibling::*[contains-token(@class, 'tab-content')]/*[contains-token(@class, 'tab-pane')]">
            <ixsl:set-attribute name="class" select="string-join(tokenize(@class, ' ')[not(. = 'active')], ' ')"/>
        </xsl:for-each>
        <!-- activate this tab -->
        <xsl:for-each select="../../following-sibling::*[contains-token(@class, 'tab-content')]/*[contains-token(@class, 'tab-pane')][count(preceding-sibling::*[contains-token(@class, 'tab-pane')]) = count(current()/../preceding-sibling::li)]">
            <ixsl:set-attribute name="class" select="concat(@class, ' ', 'active')"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- copy resource's URI into clipboard -->
    
    <xsl:template match="button[contains-token(@class, 'btn-copy-uri')]" mode="ixsl:onclick">
        <!-- get resource URI from its heading title attribute, both in bs2:Actions and bs2:FormControl mode -->
        <xsl:variable name="uri-or-bnode" select="../../h2/a/@title | ../following-sibling::input[@name = ('su', 'sb')]/@value" as="xs:string"/>
        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'navigator.clipboard'), 'writeText', [ $uri-or-bnode ])"/>
    </xsl:template>

    <!-- open a form to save RDF document (do nothing is the button is disabled) -->
    
    <xsl:template match="button[contains-token(@class, 'btn-save-as')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:variable name="textarea-id" select="'query-string'" as="xs:string"/>
        <xsl:variable name="query" select="if (id($textarea-id, ixsl:page())) then ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe'), $textarea-id), 'getValue', []) else ()" as="xs:string?"/>
        <xsl:variable name="service-uri" select="if (id('query-service', ixsl:page())) then xs:anyURI(ixsl:get(id('query-service'), 'value')) else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), resolve-uri('sparql', $ldt:base))[1]"/>
        <xsl:variable name="results-uri" select="if ($query) then ac:build-uri($endpoint, map{ 'query': $query }) else ()" as="xs:anyURI?"/>
        
        <!-- if SPARQL editor is shown, use the SPARQL protocol URI; otherwise use the Linked Data resource URI -->
        <xsl:variable name="uri" select="if ($results-uri) then $results-uri else ac:uri()" as="xs:anyURI"/>

        <xsl:call-template name="ldh:ShowAddDataForm">
            <xsl:with-param name="source" select="$uri"/>
            <xsl:with-param name="graph" select="resolve-uri(encode-for-uri($uri) || '/', ldh:absolute-path(ldh:href()))"/>
            <xsl:with-param name="container" select="ldh:absolute-path(ldh:href())"/>
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
                <xsl:call-template name="onDocumentLoad">
                    <xsl:with-param name="href" select="$href"/>
                    <!--<xsl:with-param name="fragment" select="encode-for-uri($href)"/>-->
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>

        <!-- store the new request object -->
        <ixsl:set-property name="request" select="$request" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>

    <!-- backlinks -->
    
    <xsl:template match="div[contains-token(@class, 'backlinks-nav')]//*[contains-token(@class, 'nav-header')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'backlinks-nav')]" as="element()"/>
        <xsl:variable name="content-uri" select="input[@name = 'uri']/@value" as="xs:anyURI"/>
        <xsl:variable name="query-string" select="replace($backlinks-string, '\?this', concat('&lt;', $content-uri, '&gt;'))" as="xs:string"/>
        <!-- replace dots with dashes from this point (not before using in the query string!) -->
        <xsl:variable name="content-uri" select="xs:anyURI(translate($content-uri, '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri)) then (if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-uri), 'service-uri') else ()) else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $results-uri)" as="xs:anyURI"/>
        
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
                            <xsl:with-param name="container" select="$container"/>
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
    
    <!-- CALLBACKS -->

    <xsl:template name="onBacklinksLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="results" select="?body" as="document-node()"/>
                
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <ul class="well well-small nav nav-list">
                            <xsl:apply-templates select="$results/rdf:RDF/rdf:Description[not(@rdf:about = ac:uri())]" mode="bs2:List">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                            </xsl:apply-templates>
                        </ul>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
</xsl:stylesheet>