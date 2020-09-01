<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY typeahead  "http://graphity.org/typeahead#">
    <!ENTITY lapp       "https://w3id.org/atomgraph/linkeddatahub/apps/domain#">
    <!ENTITY apl        "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY a          "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs       "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd        "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl        "http://www.w3.org/2002/07/owl#">
    <!ENTITY skos       "http://www.w3.org/2004/02/skos/core#">
    <!ENTITY srx        "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http       "http://www.w3.org/2011/http#">
    <!ENTITY ldt        "https://www.w3.org/ns/ldt#">
    <!ENTITY c          "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY dh         "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sd         "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp         "http://spinrdf.org/sp#">
    <!ENTITY spin       "http://spinrdf.org/spin#">
    <!ENTITY dct        "http://purl.org/dc/terms/">
    <!ENTITY foaf       "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc       "http://rdfs.org/sioc/ns#">
]>
<xsl:stylesheet version="2.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:style="http://saxonica.com/ns/html-style-property"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:typeahead="&typeahead;"
xmlns:a="&a;"
xmlns:ac="&ac;"
xmlns:lapp="&lapp;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:ldt="&ldt;"
xmlns:core="&c;"
xmlns:dh="&dh;"
xmlns:srx="&srx;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:skos="&skos;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>

    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/RDFXML2DataTable.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/SPARQLXMLResults2DataTable.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/converters/RDFXML2SVG.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/functions.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/imports/default.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="../../../../com/atomgraph/client/xsl/bootstrap/2.3.2/container.xsl"/>
    <xsl:import href="../../../../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/resource.xsl"/>
    <xsl:import href="../../../../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/container.xsl"/>
    <xsl:import href="../../../../com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/sparql.xsl"/>
    <xsl:import href="typeahead.xsl"/>

    <xsl:param name="ac:contextUri" as="xs:anyURI"/>
    <xsl:param name="ldt:base" as="xs:anyURI"/>
    <xsl:param name="ldt:ontology" as="xs:anyURI"/>
    <xsl:param name="ac:lang" select="ixsl:get(ixsl:get(ixsl:page(), 'documentElement'), 'lang')" as="xs:string"/>
    <!-- this is the document URI as absolute path - hash and query string are removed -->
    <xsl:param name="ac:uri" as="xs:anyURI">
        <xsl:choose>
            <!-- override with ?uri= query param value, if any -->
            <xsl:when test="ixsl:query-params()?uri">
                <xsl:sequence select="xs:anyURI(ixsl:query-params()?uri)"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- remove #hash part, if any -->
                <xsl:variable name="before-hash" select="if (contains(ixsl:get(ixsl:window(), 'location.href'), '#')) then substring-before(ixsl:get(ixsl:window(), 'location.href'), '#') else ixsl:get(ixsl:window(), 'location.href')" as="xs:string"/>
                <!-- remove ?query part, if any -->
                <xsl:sequence select="xs:anyURI(if (contains($before-hash, '?')) then substring-before($before-hash, '?') else $before-hash)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="search-container-uri" select="resolve-uri('search/', $ldt:base)" as="xs:anyURI"/>
    <xsl:param name="page-size" select="20" as="xs:integer"/>
<!--    <xsl:param name="ac:sitemap" as="document-node()?"/>-->
    <xsl:param name="ac:endpoint" select="if (ixsl:query-params()?endpoint) then xs:anyURI(ixsl:query-params()?endpoint) else ()" as="xs:anyURI?"/>
    <xsl:param name="ac:limit" select="if (ixsl:query-params()?limit) then xs:integer(ixsl:query-params()?limit) else $page-size" as="xs:integer"/>
    <xsl:param name="ac:offset" select="if (ixsl:query-params()?offset) then xs:integer(ixsl:query-params()?offset) else 0" as="xs:integer"/>
    <xsl:param name="ac:order-by" select="ixsl:query-params()?order-by" as="xs:string?"/>
    <xsl:param name="ac:desc" select="map:contains(ixsl:query-params(), 'desc')" as="xs:boolean?"/>
    <xsl:param name="ac:mode" select="if (ixsl:query-params()?mode) then xs:anyURI(ixsl:query-params()?mode) else xs:anyURI('&ac;ReadMode')" as="xs:anyURI?"/>
    <xsl:param name="ac:container-mode" select="if (ixsl:query-params()?container-mode) then xs:anyURI(ixsl:query-params()?container-mode) else xs:anyURI('&ac;ListMode')" as="xs:anyURI?"/>
    <xsl:param name="ac:googleMapsKey" select="'AIzaSyCQ4rt3EnNCmGTpBN0qoZM1Z_jXhUnrTpQ'" as="xs:string"/>
    <xsl:param name="default-order-by" select="'title'" as="xs:string?"/>

    <xsl:param name="constructor-form" as="element()?"/>
    <xsl:param name="created-uri" as="xs:string?"/>
    <xsl:param name="constructor-doc" as="document-node()?"/>
                
    <xsl:key name="elements-by-class" match="*" use="tokenize(@class, ' ')"/>
    <xsl:key name="violations-by-value" match="*" use="apl:violationValue/text()"/>
    
    <xsl:strip-space elements="*"/>
    
    <!-- embedding mode descriptions here because currently the AC vocabulary is not resolvable from the client-side -->
    
    <rdf:Description rdf:about="&ac;ReadMode">
        <rdfs:label>Properties</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:about="&ac;ListMode">
        <rdfs:label>List</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:about="&ac;TableMode">
        <rdfs:label>Table</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:about="&ac;GridMode">
        <rdfs:label>Grid</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:about="&ac;ChartMode">
        <rdfs:label>Chart</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:about="&ac;MapMode">
        <rdfs:label>Map</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:about="&ac;GraphMode">
        <rdfs:label>Graph</rdfs:label>
    </rdf:Description>

    <!-- INITIAL TEMPLATE -->
    
    <xsl:template name="main">
        <xsl:message>$ac:contextUri: <xsl:value-of select="$ac:contextUri"/></xsl:message>
        <xsl:message>$ldt:base: <xsl:value-of select="$ldt:base"/></xsl:message>
        <xsl:message>$ldt:ontology: <xsl:value-of select="$ldt:ontology"/></xsl:message>
        <xsl:message>$ac:lang: <xsl:value-of select="$ac:lang"/></xsl:message>
        <xsl:message>$ac:uri: <xsl:value-of select="$ac:uri"/></xsl:message>
        <xsl:message>Search container URI: <xsl:value-of select="$search-container-uri"/></xsl:message>
        <xsl:message>$ac:limit: <xsl:value-of select="$ac:limit"/></xsl:message>
        <xsl:message>$ac:offset: <xsl:value-of select="$ac:offset"/></xsl:message>
        <xsl:message>$ac:order-by: <xsl:value-of select="$ac:order-by"/></xsl:message>
        <xsl:message>$ac:desc: <xsl:value-of select="$ac:desc"/></xsl:message>
        <xsl:message>$ac:mode: <xsl:value-of select="$ac:mode"/></xsl:message>
        <xsl:message>$ac:container-mode: <xsl:value-of select="$ac:container-mode"/></xsl:message>

        <!-- create a LinkedDataHub namespace -->
        <ixsl:set-property name="LinkedDataHub" select="ac:new-object()"/>
        <!-- global properties that hold current container pagination state -->
        <ixsl:set-property name="limit" select="$ac:limit" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="offset" select="$ac:offset" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="order-by" select="if ($ac:order-by) then $ac:order-by else $default-order-by" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="desc" select="$ac:desc" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="active-class" select="'list-mode'" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="endpoint" select="resolve-uri('sparql', $ldt:base)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <!-- load application's ontology RDF document -->
<!--        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $ldt:ontology, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad"/>
        </ixsl:schedule-action>-->
        <!-- disable SPARQL editor's server-side submission -->
        <xsl:for-each select="ixsl:page()//button[contains(@class, 'btn-run-query')]">
            <ixsl:set-attribute name="type" select="'button'"/> <!-- instead of "submit" -->
        </xsl:for-each>
        <!-- only show first time message for authenticated agents -->
        <xsl:if test="not(ixsl:page()//div[tokenize(@class, ' ') = 'navbar']//a[tokenize(@class, ' ') = 'btn-primary'][text() = 'Sign up']) and not(contains(ixsl:get(ixsl:page(), 'cookie'), 'LinkedDataHub.first-time-message'))">
            <xsl:for-each select="id('main-content', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:call-template name="first-time-message"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
        <!-- initialize wymeditor textareas -->
        <xsl:apply-templates select="key('elements-by-class', 'wymeditor', ixsl:page())" mode="apl:PostConstructMode"/>
        <xsl:if test="not($ac:mode = '&ac;QueryEditorMode') and starts-with($ac:uri, $ldt:base)">
            <!-- show progress bar -->
            <xsl:for-each select="id('main-content', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div id="progress-bar">
                        <div class="progress progress-striped active">
                            <div class="bar" style="width: 20%;"></div>
                        </div>
                    </div>
                </xsl:result-document>
            </xsl:for-each>
            <!-- load this RDF document and then use the dh:select query to load and render container results -->
            <xsl:message>
                <!-- add a bogus query parameter to give the RDF/XML document a different URL in the browser cache, otherwise it will clash with the HTML representation -->
                <!-- this is due to broken browser behavior re. Vary and conditional requests: https://stackoverflow.com/questions/60799116/firefox-if-none-match-headers-ignore-content-type-and-vary/60802443 -->
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': concat($ac:uri, '?param=dummy'), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="onrdfBodyLoad"/>
                </ixsl:schedule-action>
            </xsl:message>
        </xsl:if>
        <!-- initialize SPARQL endpoint dropdown -->
        <xsl:for-each select="id('endpoint-uri', ixsl:page())">
            <xsl:variable name="query" select="'DESCRIBE ?service { GRAPH ?g { ?service &lt;&sd;endpoint&gt; ?endpoint } }'"/>
            <xsl:message>
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': resolve-uri(concat('sparql?query=', encode-for-uri($query)), $ldt:base), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="onServiceLoad"/>
                </ixsl:schedule-action>
            </xsl:message> 
        </xsl:for-each>
        <!--  append Save form to Query form -->
        <xsl:for-each select="id('query-form', ixsl:page())/..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:call-template name="bs2:SaveQueryForm">
                    <xsl:with-param name="query" select="ixsl:call(ixsl:get(ixsl:window(), 'yasqe'), 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>
        <!-- append typeahead list after search/URI input -->
        <xsl:for-each select="id('uri', ixsl:page())/..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <ul id="{generate-id()}" class="search-typeahead typeahead dropdown-menu"></ul>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- FUNCTIONS -->

    <xsl:function name="ac:new-url">
        <xsl:param name="href" as="xs:anyURI"/>
        
        <xsl:variable name="js-statement" as="element()">
            <root statement="new URL('{$href}')"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:function name="ac:new-object">
        <xsl:variable name="js-statement" as="element()">
            <root statement="{{ }}"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:function name="ac:build-describe" as="xs:string">
        <xsl:param name="select-string" as="xs:string"/> <!-- already with ?this value set -->
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean"/>

        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <!-- ignore ORDER BY variable name if it's not present in the query -->
        <xsl:variable name="order-by" select="if (ixsl:call($select-builder, 'isProjected', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', [ $order-by ]) ])) then $order-by else ()" as="xs:string?"/>
        <xsl:variable name="select-builder" select="ac:paginate($select-builder, $limit, $offset, $order-by, $desc)"/>
        <xsl:variable name="describe-builder" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'DescribeBuilder'), 'new', []), 'where', [ ixsl:call($select-builder, 'build', []) ])"/>
        <xsl:sequence select="ixsl:call($describe-builder, 'toString', [ ])"/>
    </xsl:function>
    
    <!-- TEMPLATES -->
    
    <!-- we don't want to include per-vocabulary stylesheets -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:label">
        <xsl:choose>
            <xsl:when test="skos:prefLabel[lang($ac:lang)]">
                <xsl:value-of select="skos:prefLabel[lang($ac:lang)]"/>
            </xsl:when>
            <xsl:when test="rdfs:label[lang($ac:lang)]">
                <xsl:value-of select="rdfs:label[lang($ac:lang)]"/>
            </xsl:when>
            <xsl:when test="dct:title[lang($ac:lang)]">
                <xsl:value-of select="dct:title[lang($ac:lang)]"/>
            </xsl:when>
            <xsl:when test="skos:prefLabel">
                <xsl:value-of select="skos:prefLabel"/>
            </xsl:when>
            <xsl:when test="rdfs:label">
                <xsl:value-of select="rdfs:label"/>
            </xsl:when>
            <xsl:when test="dct:title">
                <xsl:value-of select="dct:title"/>
            </xsl:when>
            <xsl:when test="foaf:name">
                <xsl:value-of select="foaf:name"/>
            </xsl:when>
            <xsl:when test="foaf:givenName and foaf:familyName">
                <xsl:value-of select="concat(foaf:givenName, ' ', foaf:familyName)"/>
            </xsl:when>
            <xsl:when test="foaf:familyName">
                <xsl:value-of select="foaf:familyName"/>
            </xsl:when>
            <xsl:when test="foaf:nick">
                <xsl:value-of select="foaf:nick"/>
            </xsl:when>
            <xsl:when test="sioc:name">
                <xsl:value-of select="sioc:name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@rdf:about | @rdf:nodeID"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:description">
        <xsl:choose>
            <xsl:when test="rdfs:comment[lang($ac:lang)]">
                <xsl:value-of select="rdfs:comment[lang($ac:lang)]"/>
            </xsl:when>
            <xsl:when test="dct:description[lang($ac:lang)]">
                <xsl:value-of select="dct:description[lang($ac:lang)]"/>
            </xsl:when>
            <xsl:when test="rdfs:comment">
                <xsl:value-of select="rdfs:comment"/>
            </xsl:when>
            <xsl:when test="dct:description">
                <xsl:value-of select="dct:description"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ReadMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'read-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;ListMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'list-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;TableMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'table-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;GridMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'grid-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ChartMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'chart-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;MapMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'map-mode')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;GraphMode']" mode="apl:logo">
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
    
    <!-- copied from layout.xsl which is not imported -->
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

    <!-- if document has a topic, show it as the typeahead value instead -->
    <xsl:template match="*[*][key('resources', foaf:primaryTopic/@rdf:resource)]" mode="apl:Typeahead" priority="1">
        <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="#current"/>
    </xsl:template>

    <xsl:template match="/" mode="ConstructMode">
        <xsl:message>ConstructMode</xsl:message>
        
        <xsl:variable name="target-id" select="$constructor-form/input[@class = 'target-id']/@value" as="xs:string?"/>
        <xsl:variable name="doc-id" select="concat('id', ixsl:call(ixsl:window(), 'generateUUID', []))" as="xs:string"/>
        <xsl:variable name="modal-form" as="element()">
            <xsl:apply-templates select="$constructor-doc//form[@class = 'form-horizontal']" mode="modal">
                <xsl:with-param name="target-id" select="$target-id" tunnel="yes"/>
                <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="form-id" select="$modal-form/@id" as="xs:string"/>
        
        <xsl:for-each select="$constructor-form/..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <!-- append modal div to body -->
                <xsl:copy-of select="$modal-form"/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="add-form-listeners">
            <xsl:with-param name="id" select="$form-id"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="/" mode="CreatedMode">
        <xsl:variable name="resource" select="key('resources', $created-uri)"/>
        <xsl:variable name="target-id" select="$constructor-form//input[@class = 'target-id']/@value" as="xs:string?"/>
        
        <!-- remove modal constructor form -->
        <xsl:message>
            <xsl:value-of select="ixsl:call($constructor-form/.., 'remove', [])"/>
        </xsl:message>
        
        <!-- $target-id is of "Create" button, need to replace the preceding typeahead input instead -->
        <xsl:for-each select="id($target-id, ixsl:page())/ancestor::div[@class = 'controls']/span[input]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:apply-templates select="$resource" mode="apl:Typeahead"/>
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
                <a href="https://linkeddatahub.com/demo/" class="float-left btn btn-primary btn-large" target="_blank">Check out demo apps</a>
                <a href="https://linkeddatahub.com/linkeddatahub/docs/" class="float-left btn btn-primary btn-large" target="_blank">Learn more</a>
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
        
    <!-- when RDF/XML of current document loads, fetch its dh:select (container SELECT) query -->
    <xsl:template name="onrdfBodyLoad">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:for-each select="?body">
            <!-- container SELECT query -->
            <xsl:for-each select="key('resources', $ac:uri)">
                <xsl:variable name="select-uri" select="xs:anyURI(dh:select/@rdf:resource)" as="xs:anyURI?"/>
                <xsl:choose>
                    <xsl:when test="$select-uri">
                        <xsl:message>
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $select-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="onContainerQueryLoad">
                                    <xsl:with-param name="select-uri" select="$select-uri"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:message>

                        <!-- container progress bar -->
                        <xsl:for-each select="id('progress-bar', ixsl:page())">
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <div class="progress progress-striped active">
                                    <div class="bar" style="width: 40%;"></div>
                                </div>
                            </xsl:result-document>
                        </xsl:for-each>

                        <!-- append filters to left-nav. TO-DO: filters may be visible before the container query is loaded -->
                        <xsl:for-each select="id('left-nav', ixsl:page())">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <xsl:call-template name="bs2:FilterIn"/>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- container progress bar -->
                        <xsl:for-each select="id('progress-bar', ixsl:page())">
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <!-- do not show progress bar for Items - only for Containers -->
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- chart query -->
                <xsl:for-each select="key('resources', foaf:primaryTopic/@rdf:resource)[spin:query][apl:chartType]">
                    <xsl:variable name="query-uri" select="xs:anyURI(spin:query/@rdf:resource)" as="xs:anyURI?"/>

                    <xsl:if test="$query-uri">
                        <xsl:variable name="chart-type" select="xs:anyURI(apl:chartType/@rdf:resource)" as="xs:anyURI?"/>
                        <xsl:variable name="category" select="apl:categoryProperty/@rdf:resource | apl:categoryVarName" as="xs:string?"/>
                        <xsl:variable name="series" select="apl:seriesProperty/@rdf:resource | apl:seriesVarName" as="xs:string*"/>
                        <xsl:variable name="endpoint" select="apl:endpoint/@rdf:resource" as="xs:anyURI"/>

                        <!-- cannot skip variables and select values directly - Firefox throws "(InternalError) : too much recursion" error -->
                        <ixsl:set-property name="chart-type" select="$chart-type" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                        <ixsl:set-property name="category" select="$category" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                        <ixsl:set-property name="series" select="$series" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                        <ixsl:set-property name="endpoint" select="$endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                        <!-- query progress bar -->
                        <xsl:for-each select="id('progress-bar', ixsl:page())">
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <div class="progress progress-striped active">
                                    <div class="bar" style="width: 40%;"></div>
                                </div>
                            </xsl:result-document>
                        </xsl:for-each>

                        <xsl:message>
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $query-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="onChartQueryLoad">
                                    <xsl:with-param name="query-uri" select="$query-uri"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:message>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- when container SELECT query loads, wrap it into DESCRIBE and fetch RDF/XML results -->
    <xsl:template name="onContainerQueryLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="select-uri" as="xs:anyURI"/>
            
        <xsl:for-each select="?body">
            <xsl:message>$select-uri: <xsl:value-of select="$select-uri"/></xsl:message>
            <xsl:variable name="select-resource" select="key('resources', $select-uri)" as="element()"/>
            <xsl:variable name="select-string" select="$select-resource/sp:text" as="xs:string"/>
            <xsl:variable name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')" as="xs:boolean"/>
            <!-- set ?this variable value -->
            <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $ac:uri, '&gt;'))" as="xs:string"/>
            <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
            <xsl:variable name="describe-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset')), ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
            <xsl:variable name="endpoint" select="if ($select-resource/apl:endpoint/@rdf:resource) then $select-resource/apl:endpoint/@rdf:resource else xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/>
            <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>

            <ixsl:set-property name="endpoint" select="$endpoint" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <!-- set global SELECT URI-->
            <ixsl:set-property name="select-uri" select="$select-uri" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <!-- set global SELECT query (without modifiers) -->
            <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <!-- set global DESCRIBE query (without modifiers) -->
            <ixsl:set-property name="describe-query" select="$describe-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

            <!-- container progress bar -->
            <xsl:for-each select="id('progress-bar', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <div class="progress progress-striped active">
                        <div class="bar" style="width: 60%;"></div>
                    </div>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:message>
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="onContainerResultsLoad"/>
                </ixsl:schedule-action>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>

    <!-- when container RDF/XML results load, render them -->
    <xsl:template name="onContainerResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>

        <!-- container progress bar -->
        <xsl:for-each select="id('progress-bar', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="progress progress-striped active">
                    <div class="bar" style="width: 80%;"></div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <!--<xsl:variable name="results" select="ixsl:get($detail, 'body')" as="document-node()"/>-->
                <xsl:for-each select="?body">
                    <ixsl:set-property name="results" select="." object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                    <xsl:call-template name="render-container">
                        <xsl:with-param name="results" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
                <xsl:call-template name="render-container-error">
                    <xsl:with-param name="message" select="?message"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="render-container">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="active-class" select="ixsl:get(ixsl:window(), 'LinkedDataHub.active-class')" as="xs:string?"/>

        <!-- remove container progress bar -->
        <xsl:for-each select="id('progress-bar', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content"></xsl:result-document>
        </xsl:for-each>
        
        <xsl:choose>
            <!-- container results are already rendered -->
            <xsl:when test="id('container-pane', ixsl:page())">
                <xsl:for-each select="id('container-pane', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:call-template name="container-mode">
                            <xsl:with-param name="results" select="$results"/>
                            <!-- <xsl:with-param name="order-by" select="$order-by"/> -->
                            <!-- <xsl:with-param name="active-class" select="$active-class"/> -->
                        </xsl:call-template>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <!-- first time rendering the container results -->
            <xsl:otherwise>
                <xsl:for-each select="id('main-content', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div id="container-pane">
                            <xsl:call-template name="container-mode">
                                <xsl:with-param name="results" select="$results"/>
                                <!-- <xsl:with-param name="order-by" select="$order-by"/> -->
                                <!-- <xsl:with-param name="active-class" select="$active-class"/> -->
                            </xsl:call-template>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

        <!-- after we've created the map or chart container element, create the JS objects using it -->
        <xsl:if test="$active-class = 'map-mode' or (not($active-class) and $ac:container-mode = '&ac;MapMode')">
            <!-- TO-DO: check if window.LinkedDataHub.map already exists? -->
            <xsl:call-template name="create-google-map">
                <xsl:with-param name="map" select="ac:create-map('map-canvas', 56, 10, 4)"/>
            </xsl:call-template>

            <xsl:call-template name="create-geo-object">
                <!-- use container's SELECT query to build a geo query -->
                <xsl:with-param name="geo" select="ac:create-geo-object($ac:uri, resolve-uri('sparql', $ldt:base), ixsl:get(ixsl:window(), 'LinkedDataHub.select-query'), 'thing')"/>
            </xsl:call-template>

            <xsl:call-template name="add-geo-listener"/>
        </xsl:if>
        <xsl:if test="$active-class = 'chart-mode' or (not($active-class) and $ac:container-mode = '&ac;ChartMode')">
            <xsl:variable name="canvas-id" select="'chart-canvas'" as="xs:string"/>
            <xsl:variable name="chart-type" select="xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
            <xsl:variable name="category" as="xs:string?"/>
            <xsl:variable name="series" select="distinct-values($results/*/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>

            <!-- window.LinkedDataHub.data-table object is used by ac:draw-chart() -->
            <ixsl:set-property name="data-table" select="ac:rdf-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <ixsl:set-property name="chart-type" select="$chart-type" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <ixsl:set-property name="category" select="$category" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <ixsl:set-property name="series" select="$series" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

            <xsl:call-template name="render-chart">
                <xsl:with-param name="canvas-id" select="$canvas-id"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="render-container-error">
        <xsl:param name="message" as="xs:string"/>

        <!-- remove container progress bar -->
        <xsl:for-each select="id('progress-bar', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content"></xsl:result-document>
        </xsl:for-each>
        
        <xsl:choose>
            <!-- container results are already rendered -->
            <xsl:when test="id('container-pane', ixsl:page())">
                <xsl:for-each select="id('container-pane', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error during query execution:</strong>
                            <pre>
                                <xsl:value-of select="$message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <!-- first time rendering the container results -->
            <xsl:otherwise>
                <xsl:for-each select="id('main-content', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div id="container-pane">
                            <div class="alert alert-block">
                                <strong>Error during query execution:</strong>
                                <pre>
                                    <xsl:value-of select="$message"/>
                                </pre>
                            </div>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- container results layout -->
    
    <xsl:template name="container-mode">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')" as="xs:string?"/>
        <xsl:param name="active-class" select="ixsl:get(ixsl:window(), 'LinkedDataHub.active-class')" as="xs:string?"/>
        
        <div>
            <ul class="nav nav-tabs">
                <li class="read-mode">
                    <xsl:if test="$active-class = 'read-mode' or (not($active-class) and $ac:container-mode = '&ac;ReadMode')">
                        <xsl:attribute name="class" select="'read-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;ReadMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        Read
                    </a>
                </li>
                <li class="list-mode">
                    <xsl:if test="$active-class = 'list-mode' or (not($active-class) and $ac:container-mode = '&ac;ListMode')">
                        <xsl:attribute name="class" select="'list-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;ListMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        List
                    </a>
                </li>
                <li class="table-mode">
                    <xsl:if test="$active-class = 'table-mode' or (not($active-class) and $ac:container-mode = '&ac;TableMode')">
                        <xsl:attribute name="class" select="'table-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;TableMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        Table
                    </a>
                </li>
                <li class="grid-mode">
                    <xsl:if test="$active-class = 'grid-mode' or (not($active-class) and $ac:container-mode = '&ac;GridMode')">
                        <xsl:attribute name="class" select="'grid-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;GridMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        Grid
                    </a>
                </li>
                <li class="chart-mode">
                    <xsl:if test="$active-class = 'chart-mode' or (not($active-class) and $ac:container-mode = '&ac;ChartMode')">
                        <xsl:attribute name="class" select="'chart-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;ChartMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        Chart
                    </a>
                </li>
                <li class="map-mode">
                    <xsl:if test="$active-class = 'map-mode' or (not($active-class) and $ac:container-mode = '&ac;MapMode')">
                        <xsl:attribute name="class" select="'map-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;MapMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        Map
                    </a>
                </li>
                <li class="graph-mode">
                    <xsl:if test="$active-class = 'graph-mode' or (not($active-class) and $ac:container-mode = '&ac;GraphMode')">
                        <xsl:attribute name="class" select="'graph-mode active'"/>
                    </xsl:if>

                    <a>
                        <!--<xsl:apply-templates select="key('resources', '&ac;GraphMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo"/>-->
                        Graph
                    </a>
                </li>
            </ul>
        
            <div id="container-results">
                <xsl:variable name="sorted-results" as="document-node()">
                    <xsl:document>
                        <xsl:for-each select="$results/rdf:RDF">
                            <xsl:copy>
                                <xsl:perform-sort select="*">
                                    <!-- sort by $order-by if it is set, by URI/bnode ID otherwise -->
                                    <xsl:sort select="if ($order-by) then *[local-name() = $order-by] else if (@rdf:about) then @rdf:about else @rdf:nodeID"/>
                                </xsl:perform-sort>
                            </xsl:copy>
                        </xsl:for-each>
                    </xsl:document>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$active-class = 'list-mode' or (not($active-class) and $ac:container-mode = '&ac;ListMode')">
                        <xsl:apply-templates select="$sorted-results" mode="bs2:BlockList"/>
                    </xsl:when>
                    <xsl:when test="$active-class = 'table-mode' or (not($active-class) and $ac:container-mode = '&ac;TableMode')">
                        <xsl:apply-templates select="$sorted-results" mode="xhtml:Table"/>
                    </xsl:when>
                    <xsl:when test="$active-class = 'grid-mode' or (not($active-class) and $ac:container-mode = '&ac;GridMode')">
                        <xsl:apply-templates select="$sorted-results" mode="bs2:Grid"/>
                    </xsl:when>
                    <xsl:when test="$active-class = 'chart-mode' or (not($active-class) and $ac:container-mode = '&ac;ChartMode')">
                        <xsl:apply-templates select="$sorted-results" mode="bs2:Chart"/>
                    </xsl:when>
                    <xsl:when test="$active-class = 'map-mode' or (not($active-class) and $ac:container-mode = '&ac;MapMode')">
                        <xsl:apply-templates select="$sorted-results" mode="bs2:Map"/>
                    </xsl:when>
                    <xsl:when test="$active-class = 'graph-mode' or (not($active-class) and $ac:container-mode = '&ac;GraphMode')">
                        <xsl:apply-templates select="$sorted-results" mode="bs2:Graph"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$sorted-results" mode="bs2:Block"/>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="onChartQueryLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="query-uri" as="xs:anyURI"/>

        <xsl:for-each select="?body">
            <xsl:variable name="query-type" select="xs:anyURI(key('resources', $query-uri)/rdf:type/@rdf:resource)" as="xs:anyURI"/>
            <xsl:variable name="query-string" select="key('resources', $query-uri)/sp:text" as="xs:string"/>
            <!-- TO-DO: use SPARQLBuilder to set LIMIT -->
            <xsl:variable name="query-string" select="concat($query-string, ' LIMIT 100')" as="xs:string"/>
            <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/>
            <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($query-string)))" as="xs:anyURI"/>

            <!-- query progress bar -->
            <xsl:for-each select="id('progress-bar', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <div class="progress progress-striped active">
                        <div class="bar" style="width: 60%;"></div>
                    </div>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:for-each select="id('main-content', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div id="sparql-results"/>
                </xsl:result-document>
            </xsl:for-each>

            <xsl:message>
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }">
                    <xsl:call-template name="onSPARQLResultsLoad"/>
                </ixsl:schedule-action>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="onSPARQLResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="?body">
                    <ixsl:set-property name="results" select="." object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                    <!-- query progress bar -->
                    <xsl:for-each select="id('progress-bar', ixsl:page())">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="progress progress-striped active">
                                <div class="bar" style="width: 80%;"></div>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>

                    <!-- window.LinkedDataHub.data-table object is used by ac:draw-chart() -->
                    <xsl:choose>
                        <xsl:when test="rdf:RDF">
                            <ixsl:set-property name="data-table" select="ac:rdf-data-table(., (), ())" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                        </xsl:when>
                        <xsl:when test="srx:sparql">
                            <ixsl:set-property name="data-table" select="ac:sparql-results-data-table(., (), ())" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                        </xsl:when>
                    </xsl:choose>

                    <xsl:variable name="results" select="." as="document-node()"/>
                    <!-- values may already be initialized from chart properties in onrdfBodyLoad -->
                    <xsl:variable name="chart-type" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.chart-type')) then xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.chart-type')) else xs:anyURI('&ac;Table')" as="xs:anyURI?"/>
                    <xsl:variable name="category" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.category')) then ixsl:get(ixsl:window(), 'LinkedDataHub.category') else (if (srx:sparql) then srx:sparql/srx:head/srx:variable[1]/@name else ())" as="xs:string?"/>
                    <xsl:variable name="series" select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.series')) then ixsl:get(ixsl:window(), 'LinkedDataHub.series') else (if (rdf:RDF) then distinct-values(rdf:RDF/*/*/concat(namespace-uri(), local-name())) else srx:sparql/srx:head/srx:variable/@name)" as="xs:string*"/>

                    <ixsl:set-property name="chart-type" select="$chart-type" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                    <ixsl:set-property name="category" select="$category" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                    <ixsl:set-property name="series" select="$series" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

                    <xsl:for-each select="id('sparql-results', ixsl:page())">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:apply-templates select="$results" mode="bs2:Chart">
                                <xsl:with-param name="chart-type" select="$chart-type"/>
                                <xsl:with-param name="category" select="$category"/>
                                <xsl:with-param name="series" select="$series"/>
                            </xsl:apply-templates>
                        </xsl:result-document>
                    </xsl:for-each>

                    <xsl:call-template name="render-chart">
                        <xsl:with-param name="canvas-id" select="'chart-canvas'"/>
                        <xsl:with-param name="chart-type" select="$chart-type"/>
                        <xsl:with-param name="category" select="$category"/>
                        <xsl:with-param name="series" select="$series"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- remove query progress bar -->
                <xsl:for-each select="id('progress-bar', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content"></xsl:result-document>
                </xsl:for-each>
        
                <!-- error response - could not load query results -->
                <xsl:for-each select="id('sparql-results', ixsl:page())">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error during query execution:</strong>
                            <pre>
                                <xsl:value-of select="?message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="render-chart">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="chart-type" as="xs:anyURI"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <!-- remove query progress bar -->
        <xsl:for-each select="id('progress-bar', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content"></xsl:result-document>
        </xsl:for-each>
        
        <xsl:call-template name="ac:draw-chart">
             <xsl:with-param name="canvas-id" select="$canvas-id"/>
             <xsl:with-param name="chart-type" select="$chart-type"/>
             <xsl:with-param name="category" select="$category"/>
             <xsl:with-param name="series" select="$series"/>
        </xsl:call-template>
    </xsl:template>

    <!-- EVENT LISTENERS -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'hero-unit']/button[tokenize(@class, ' ') = 'close']" mode="ixsl:onclick" priority="1">
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
        <xsl:param name="container-uri" select="$search-container-uri" as="xs:anyURI"/>
        <xsl:param name="resource-types" as="xs:anyURI?"/>
        <xsl:param name="container-doc" select="document(concat($container-uri, '?accept=', encode-for-uri('application/rdf+xml')))" as="document-node()"/>
        <xsl:param name="select-uri" select="key('resources', $container-uri, $container-doc)/dh:select/@rdf:resource" as="xs:anyURI"/>
        <xsl:param name="select-doc" select="document(concat(ac:document-uri($select-uri), '?accept=', encode-for-uri('application/rdf+xml')))" as="document-node()"/>
        <xsl:param name="select-string" select="key('resources', $select-uri, $select-doc)/sp:text" as="xs:string"/>
        <xsl:param name="limit" select="100" as="xs:integer"/>
        <xsl:variable name="key-code" select="ixsl:get(ixsl:event(), 'code')" as="xs:string"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <!-- pseudo JS code: SPARQLBuilder.SelectBuilder.fromString($select-builder).where(SPARQLBuilder.QueryBuilder.filter(SPARQLBuilder.QueryBuilder.regex(QueryBuilder.var("label"), QueryBuilder.term(QueryBuilder.str($text))))) -->
        <xsl:variable name="select-builder" select="ixsl:call($select-builder, 'where', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'filter', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'regex', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'str', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ 'label' ]) ]), ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'term', [ ac:escape-regex($text) ]), true() ] ) ] ) ])"/>
        <xsl:variable name="select-string" select="ixsl:call($select-builder, 'toString', [])" as="xs:string"/>
        <xsl:variable name="describe-string" select="ac:build-describe($select-string, $limit, (), (), true())" as="xs:string"/>
        <xsl:variable name="endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>
        <xsl:variable name="results" select="document($results-uri)" as="document-node()"/>

        <xsl:choose>
            <xsl:when test="$key-code = 'Escape'">
                <xsl:call-template name="typeahead:hide">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$key-code = 'Enter'">
                <xsl:if test="$menu/li[tokenize(@class, ' ') = 'active']">
                    <!-- redirect to the resource URI selected in the typeahead -->
                    <xsl:variable name="resource-uri" select="$menu/li[tokenize(@class, ' ') = 'active']/input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                    <xsl:call-template name="redirect">
                        <xsl:with-param name="uri" select="$resource-uri"/>
                    </xsl:call-template>
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
                        <!--<xsl:with-param name="js-function" select="$js-function"/>-->
                        <!--<xsl:with-param name="callback" select="apl:resource-typeahead-callback#3"/>-->
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
    
    <xsl:template match="form[tokenize(@class, ' ') = 'navbar-form']//ul[tokenize(@class, ' ') = 'dropdown-menu'][tokenize(@class, ' ') = 'typeahead']/li" mode="ixsl:onmousedown" priority="1">
        <xsl:variable name="resource-uri" select="input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
        <!-- redirect to the resource URI selected in the typeahead -->
        <xsl:call-template name="redirect">
            <xsl:with-param name="uri" select="$resource-uri"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="redirect">
        <xsl:param name="uri" as="xs:anyURI"/>
        
        <ixsl:set-property name="location.href" select="$uri"/>
    </xsl:template>
    
    <!-- prompt for query title (also reused for its document) -->
    
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-save-query']" mode="ixsl:onclick">
        <!-- get query string from YASQE -->
        <xsl:variable name="query" select="ixsl:call(ixsl:get(ixsl:window(), 'yasqe'), 'getValue', [])" as="xs:string"/>
        <xsl:for-each select="id('save-query-string')"> <!-- using a different ID from 'query-string' which is the visible YasQE textarea -->
            <ixsl:set-attribute name="value" select="$query"/>
        </xsl:for-each>
        <!-- get SPARQL endpoint URI from dropdown -->
        <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(id('endpoint-uri'), 'value'))" as="xs:anyURI"/>
        <xsl:for-each select="id('query-endpoint')">
            <ixsl:set-attribute name="value" select="$endpoint"/>
        </xsl:for-each>
        
        <!-- prompt for title before form proceeds to submit -->
        <xsl:variable name="title" select="ixsl:call(ixsl:window(), 'prompt', [ 'Title' ])" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$title">
                <xsl:for-each select="id('query-title')">
                    <ixsl:set-attribute name="value" select="$title"/>
                </xsl:for-each>
                <xsl:for-each select="id('query-doc-title')">
                    <ixsl:set-attribute name="value" select="$title"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/> <!-- does not work :/ -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- prompt for chart title (also reused for its document) -->
    
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-save-chart']" mode="ixsl:onclick">
        <!-- prompt for title before form proceeds to submit -->
        <xsl:variable name="title" select="ixsl:call(ixsl:window(), 'prompt', [ 'Title' ])" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$title">
                <xsl:for-each select="id('chart-title')">
                    <ixsl:set-attribute name="value" select="$title"/>
                </xsl:for-each>
                <xsl:for-each select="id('chart-doc-title')">
                    <ixsl:set-attribute name="value" select="$title"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
        
    <!-- run SPARQL query in editor -->
    
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-run-query']" mode="ixsl:onclick">
        <xsl:variable name="query" select="ixsl:call(ixsl:get(ixsl:window(), 'yasqe'), 'getValue', [])" as="xs:string"/> <!-- get query string from YASQE -->
        <!-- <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/> -->
        <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(id('endpoint-uri'), 'value'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($query)))" as="xs:anyURI"/>

        <!-- is SPARQL results element does not already exist, create one -->
        <xsl:if test="not(id('sparql-results', ixsl:page()))">
            <xsl:for-each select="id('main-content', ixsl:page())">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <div id="sparql-results"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
        
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml,application/rdf+xml;q=0.9' } }">
            <xsl:call-template name="onSPARQLResultsLoad"/>
        </ixsl:schedule-action>
    </xsl:template>
    
    <!-- chart-type onchange -->
    
    <xsl:template match="select[@id = 'chart-type']" mode="ixsl:onchange">
        <xsl:param name="chart-type" select="xs:anyURI(ixsl:get(., 'value'))" as="xs:anyURI?"/>
        <xsl:param name="category" select="ixsl:get(ixsl:window(), 'LinkedDataHub.category')" as="xs:string?"/>
        <xsl:param name="series" select="ixsl:get(ixsl:window(), 'LinkedDataHub.series')" as="xs:string*"/>

        <ixsl:set-property name="chart-type" select="$chart-type" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="results" select="ixsl:get(ixsl:window(), 'LinkedDataHub.results')" as="document-node()"/>
        <xsl:if test="$chart-type and ($category or $results/rdf:RDF) and not(empty($series))">
            <!-- window.LinkedDataHub.data-table object is used by ac:draw-chart() -->
            <xsl:choose>
                <xsl:when test="$results/rdf:RDF">
                    <ixsl:set-property name="data-table" select="ac:rdf-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:when>
                <xsl:when test="$results/srx:sparql">
                    <ixsl:set-property name="data-table" select="ac:sparql-results-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:when>
            </xsl:choose>
            
            <xsl:call-template name="render-chart">
                <xsl:with-param name="canvas-id" select="'chart-canvas'"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- category onchange -->

    <xsl:template match="select[@id = 'category']" mode="ixsl:onchange">
        <xsl:param name="chart-type" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.chart-type'))" as="xs:anyURI?"/>
        <xsl:param name="category" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:param name="series" select="ixsl:get(ixsl:window(), 'LinkedDataHub.series')" as="xs:string*"/>

        <ixsl:set-property name="category" select="$category" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="results" select="ixsl:get(ixsl:window(), 'LinkedDataHub.results')" as="document-node()"/>
        <xsl:if test="$chart-type and ($category or $results/rdf:RDF) and not(empty($series))">
            <!-- window.LinkedDataHub.data-table object is used by ac:draw-chart() -->
            <xsl:choose>
                <xsl:when test="$results/rdf:RDF">
                    <ixsl:set-property name="data-table" select="ac:rdf-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:when>
                <xsl:when test="$results/srx:sparql">
                    <ixsl:set-property name="data-table" select="ac:sparql-results-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:when>
            </xsl:choose>
            
            <xsl:call-template name="render-chart">
                <xsl:with-param name="canvas-id" select="'chart-canvas'"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- series onchange -->

    <xsl:template match="select[@id = 'series']" mode="ixsl:onchange">
        <xsl:param name="chart-type" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.chart-type'))" as="xs:anyURI?"/>
        <xsl:param name="category" select="ixsl:get(ixsl:window(), 'LinkedDataHub.category')" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*">
            <xsl:for-each select="0 to xs:integer(ixsl:get(., 'selectedOptions.length')) - 1">
                <xsl:variable name="js-statement" as="element()">
                    <root statement="document.getElementById('series').selectedOptions.item({.}).value"/>
                </xsl:variable>
                <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
            </xsl:for-each>
        </xsl:param>

        <ixsl:set-property name="series" select="$series" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="results" select="ixsl:get(ixsl:window(), 'LinkedDataHub.results')" as="document-node()"/>
        <xsl:if test="$chart-type and ($category or $results/rdf:RDF) and not(empty($series))">
            <!-- window.LinkedDataHub.data-table object is used by ac:draw-chart() -->
            <xsl:choose>
                <xsl:when test="$results/rdf:RDF">
                    <ixsl:set-property name="data-table" select="ac:rdf-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:when>
                <xsl:when test="$results/srx:sparql">
                    <ixsl:set-property name="data-table" select="ac:sparql-results-data-table($results, $category, $series)" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                </xsl:when>
            </xsl:choose>
            
            <xsl:call-template name="render-chart">
                <xsl:with-param name="canvas-id" select="'chart-canvas'"/>
                <xsl:with-param name="chart-type" select="$chart-type"/>
                <xsl:with-param name="category" select="$category"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- container mode tabs -->
    
    <xsl:template match="*[@id = 'container-pane']/div/ul[@class = 'nav nav-tabs']/li/a" mode="ixsl:onclick">
        <xsl:variable name="active-class" select="../@class" as="xs:string"/>

        <ixsl:set-property name="active-class" select="$active-class" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        
        <xsl:call-template name="render-container">
            <xsl:with-param name="results" select="ixsl:get(ixsl:window(), 'LinkedDataHub.results')"/>
        </xsl:call-template>
    </xsl:template>

    <!-- pager prev links -->

    <xsl:template match="*[@id = 'container-pane']//ul[@class = 'pager']/li[@class = 'previous']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>

        <!-- descrease OFFSET to get the previous page -->
        <xsl:variable name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))" as="xs:integer"/>
        <xsl:variable name="offset" select="$offset - $page-size" as="xs:integer"/>
        <ixsl:set-property name="offset" select="$offset" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
        <!-- <xsl:variable name="order-by" select="if ($ac:order-by) then $ac:order-by else if (ixsl:call($select-builder, 'isProjected', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', $default-order-by))) then $default-order-by else ()" as="xs:string?"/> -->
        <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
        <xsl:variable name="describe-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), $offset, ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
        <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad"/>
        </ixsl:schedule-action>
    </xsl:template>

    <!-- pager next links -->
    
    <xsl:template match="*[@id = 'container-pane']//ul[@class = 'pager']/li[@class = 'next']/a[@class = 'active']" mode="ixsl:onclick">
        <xsl:variable name="event" select="ixsl:event()"/>

        <!-- increase OFFSET to get the next page -->
        <xsl:variable name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))" as="xs:integer"/>
        <xsl:variable name="offset" select="$offset + $page-size" as="xs:integer"/>
        <ixsl:set-property name="offset" select="$offset" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>

        <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
        <!-- <xsl:variable name="order-by" select="if ($ac:order-by) then $ac:order-by else if (ixsl:call($select-builder, 'isProjected', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', $default-order-by))) then $default-order-by else ()" as="xs:string?"/> -->
        <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
        <xsl:variable name="describe-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), $offset, ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
        <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onContainerResultsLoad"/>
        </ixsl:schedule-action>
    </xsl:template>
    
    <!-- types (Classes) are looked up on the NamespaceOntology rather on the SearchContainer -->
    <xsl:template match="input[tokenize(@class, ' ') = 'type-typeahead']" mode="ixsl:onkeyup" priority="1">
        <xsl:next-match>
            <xsl:with-param name="container-uri" select="resolve-uri('ns/domain', $ldt:base)"/>
            <xsl:with-param name="callback" select="'ontypeTypeaheadCallback'"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- lookup by ?label and optional ?Type using search SELECT -->
    <xsl:template match="input[tokenize(@class, ' ') = 'typeahead']" mode="ixsl:onkeyup">
        <xsl:param name="menu" select="following-sibling::ul" as="element()"/>
        <xsl:param name="delay" select="400" as="xs:integer"/>
        <xsl:param name="container-uri" select="$search-container-uri" as="xs:anyURI"/>
        <xsl:param name="resource-types" select="ancestor::div[@class = 'controls']/input[@class = 'forClass']/@value" as="xs:anyURI*"/>
        <xsl:param name="container-doc" select="document(concat($container-uri, '?accept=', encode-for-uri('application/rdf+xml')))" as="document-node()"/>
        <xsl:param name="select-uri" select="key('resources', $container-uri, $container-doc)/dh:select/@rdf:resource" as="xs:anyURI"/>
        <xsl:param name="select-doc" select="document(concat(ac:document-uri($select-uri), '?accept=', encode-for-uri('application/rdf+xml')))" as="document-node()"/>
        <xsl:param name="select-string" select="key('resources', $select-uri, $select-doc)/sp:text" as="xs:string"/>
        <xsl:param name="limit" select="100" as="xs:integer"/>
        <xsl:variable name="key-code" select="ixsl:get(ixsl:event(), 'code')" as="xs:string"/>
        <xsl:variable name="value-uris" select="array { $resource-types[not(. = '&rdfs;Resource')] }" as="array(xs:anyURI)"/>
        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <!-- pseudo JS code: SPARQLBuilder.SelectBuilder.fromString($select-builder).where(SPARQLBuilder.QueryBuilder.filter(SPARQLBuilder.QueryBuilder.regex(QueryBuilder.var("label"), QueryBuilder.term($value)))) -->
        <xsl:variable name="select-builder" select="ixsl:call($select-builder, 'where', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'filter', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'regex', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'str', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ 'label' ]) ]), ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'term', [ ac:escape-regex(ixsl:get(., 'value')) ]), true() ]) ]) ])"/>
        <!-- pseudo JS code: SPARQLBuilder.SelectBuilder.fromString($select-builder).where(SPARQLBuilder.QueryBuilder.filter(SPARQLBuilder.QueryBuilder.in(QueryBuilder.var("Type"), [ $value ]))) -->
        <xsl:variable name="select-builder" select="if (empty($resource-types[not(. = 'http://www.w3.org/2000/01/rdf-schema#Resource')])) then $select-builder else ixsl:call($select-builder, 'where', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'filter', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'in', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', [ 'Type' ]), $value-uris ]) ]) ])"/>
        <xsl:variable name="select-string" select="ixsl:call($select-builder, 'toString', [])" as="xs:string"/>
        <xsl:variable name="describe-string" select="ac:build-describe($select-string, $limit, (), (), true())" as="xs:string"/>
        <xsl:variable name="endpoint" select="resolve-uri('sparql', $ldt:base)" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>
        <xsl:variable name="results" select="document($results-uri)" as="document-node()"/>
        
        <xsl:choose>
            <xsl:when test="$key-code = 'Escape'">
                <xsl:call-template name="typeahead:hide">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$key-code = 'Enter'">
                <xsl:for-each select="$menu/li[tokenize(@class, ' ') = 'active']">
                    <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/> <!-- prevent form submit -->
                
                    <xsl:variable name="resource-uri" select="input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                    <xsl:variable name="typeahead-class" select="'btn add-typeahead'" as="xs:string"/>
                    <xsl:variable name="typeahead-doc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.typeahead.rdfXml')" as="document-node()"/> <!-- set by typeahead:xml-loaded -->
                    <xsl:variable name="resource" select="key('resources', $resource-uri, $typeahead-doc)"/>

                    <xsl:for-each select="../..">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:apply-templates select="$resource" mode="apl:Typeahead">
                                <xsl:with-param name="class" select="$typeahead-class"/>
                            </xsl:apply-templates>
                        </xsl:result-document>
                    </xsl:for-each>

                    <xsl:call-template name="resource-typeahead">
                        <xsl:with-param name="id" select="generate-id($resource)"/>
                    </xsl:call-template>
                </xsl:for-each>
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
                        <xsl:with-param name="query" select="ixsl:get(., 'value')"/>
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
    
    <xsl:template match="input[tokenize(@class, ' ') = 'typeahead']" mode="ixsl:onblur">
        <xsl:param name="menu" select="following-sibling::ul" as="element()"/>
        
        <xsl:call-template name="typeahead:hide">
            <xsl:with-param name="menu" select="$menu"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="ul[tokenize(@class, ' ') = 'dropdown-menu'][tokenize(@class, ' ') = 'type-typeahead']/li" mode="ixsl:onmousedown" priority="1">
        <xsl:next-match>
            <xsl:with-param name="typeahead-class" select="'btn add-typeahead add-typetypeahead'"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- select typeahead item -->
    
    <xsl:template match="ul[tokenize(@class, ' ') = 'dropdown-menu'][tokenize(@class, ' ') = 'typeahead']/li" mode="ixsl:onmousedown">
        <xsl:param name="resource-uri" select="input[@name = 'ou']/ixsl:get(., 'value')"/>
        <xsl:param name="typeahead-class" select="'btn add-typeahead'" as="xs:string"/>
        <xsl:variable name="typeahead-doc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.typeahead.rdfXml')"/>
        <xsl:variable name="resource" select="key('resources', $resource-uri, $typeahead-doc)"/>

        <xsl:for-each select="../..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:apply-templates select="$resource" mode="apl:Typeahead">
                    <xsl:with-param name="class" select="$typeahead-class"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="resource-typeahead">
            <xsl:with-param name="id" select="generate-id($resource)"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="resource-typeahead">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:for-each select="id($id, ixsl:page())/preceding-sibling::div[1]/button[tokenize(@class, ' ') = 'btn-remove']">
            <!-- TO-DO: refactor into apl:PostConstructMode -->
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'click', ixsl:get(ixsl:window(), 'onRemoveButtonClick') ])"/>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[tokenize(@class, ' ') = 'add-type']" mode="ixsl:onclick" priority="1">
        <xsl:param name="lookup-class" select="'type-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="id" select="concat('input-', $uuid)"/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="../..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select=".."/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="add-typeahead">
            <xsl:with-param name="id" select="concat('input-', $uuid)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- special case for rdf:type lookups -->
    <xsl:template match="button[tokenize(@class, ' ') = 'add-typetypeahead']" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'type-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="button[tokenize(@class, ' ') = 'add-typeahead']" mode="ixsl:onclick">
        <xsl:param name="lookup-class" select="'resource-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'resource-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="id" select="concat('input-', $uuid)"/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="add-typeahead">
            <xsl:with-param name="id" select="concat('input-', $uuid)"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="add-typeahead">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:for-each select="id($id, ixsl:page())">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'blur', ixsl:get(ixsl:window(), 'onTypeaheadInputBlur') ])"/>
                <xsl:value-of select="ixsl:call(., 'focus', [])"/>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="button[tokenize(@class, ' ') = 'add-value']" mode="ixsl:onclick">
        <xsl:message>Adding property for class: <xsl:value-of select="@value"/></xsl:message>
        <xsl:variable name="constructor-uri" select="resolve-uri(concat('?forClass=', encode-for-uri(@value), '&amp;', 'mode=', encode-for-uri('&ac;ConstructMode')), $ac:uri)" as="xs:anyURI"/>
        <xsl:message>Constructor URI: <xsl:value-of select="$constructor-uri"/></xsl:message>

        <xsl:message>
            <xsl:value-of select="ixsl:call(ixsl:window(), 'loadRDFXML', [ ixsl:event(), string($constructor-uri), ixsl:get(ixsl:window(), 'onaddValueCallback') ])"/>
        </xsl:message>
        <!-- replace button content with loading indicator -->
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="disabled" select="'disabled'"/>
                    <xsl:text>Loading...</xsl:text>
                </xsl:copy>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="button[tokenize(@class, ' ') = 'add-constructor']" mode="ixsl:onclick">
        <xsl:variable name="action" select="input[@class = 'action']/@value" as="xs:anyURI"/>
        <xsl:message>Action URI: <xsl:value-of select="$action"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $action, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
            <xsl:call-template name="onaddModalFormCallback"/>
        </ixsl:schedule-action>
    </xsl:template>

    <xsl:template match="button[tokenize(@class, ' ') = 'btn-edit']" mode="ixsl:onclick">
        <xsl:variable name="graph-uri" select="input/@value" as="xs:anyURI"/>
        <xsl:message>GRAPH URI: <xsl:value-of select="$graph-uri"/></xsl:message>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
<!--        <xsl:value-of select="ixsl:call(ixsl:window(), 'loadXHTML', [ ixsl:event(), string($graph-uri), ixsl:get(ixsl:window(), 'onaddModalFormCallback') ])"/>-->
        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $graph-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
            <xsl:call-template name="onaddModalFormCallback"/>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template match="div[tokenize(@class, ' ') = 'modal']//button[tokenize(@class, ' ') = ('close', 'btn-close')]" mode="ixsl:onclick">
        <!-- remove modal constructor form -->
        <xsl:for-each select="ancestor::div[tokenize(@class, ' ') = 'modal']">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'remove', [])"/>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>
    
    <!-- content tabs (markup from Bootstrap) -->
    <xsl:template match="div[tokenize(@class, ' ') = 'tabbable']/ul[tokenize(@class, ' ') = 'nav-tabs']/li/a" mode="ixsl:onclick">
        <!-- deactivate other tabs -->
        <ixsl:set-attribute name="class" select="string-join(tokenize(@class, ' ')[not(. = 'active')], ' ')" object="../../li"/>
        <!-- activate this tab -->
        <ixsl:set-attribute name="class" select="'active'" object=".."/>
        <!-- deactivate other tab panes -->
        <ixsl:set-attribute name="class" select="string-join(tokenize(@class, ' ')[not(. = 'active')], ' ')" object="../../following-sibling::*[tokenize(@class, ' ') = 'tab-content']/*[tokenize(@class, ' ') = 'tab-pane']"/>
        <!-- activate this tab -->
        <ixsl:set-attribute name="class" select="concat(@class, ' ', 'active')" object="../../following-sibling::*[tokenize(@class, ' ') = 'tab-content']/*[tokenize(@class, ' ') = 'tab-pane'][count(preceding-sibling::*[tokenize(@class, ' ') = 'tab-pane']) = count(current()/../preceding-sibling::li)]"/>
    </xsl:template>
    
    <!-- MODAL IDENTITY TRANSFORM -->
    
    <xsl:template match="@for | @id" mode="modal" priority="1">
        <xsl:param name="doc-id" as="xs:string" tunnel="yes"/>
        
        <xsl:attribute name="{name()}" select="concat($doc-id, .)"/>
    </xsl:template>
    
    <xsl:template match="input[@class = 'target-id']" mode="modal" priority="1">
        <xsl:param name="target-id" as="xs:string?" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="$target-id">
                <xsl:attribute name="value" select="$target-id"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- regenerates slug literal UUID because form (X)HTML can be cached -->
    <xsl:template match="input[@name = 'ol'][ancestor::div[@class = 'controls']/preceding-sibling::input[@name = 'pu']/@value = '&dh;slug']" mode="modal" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="value" select="ixsl:call(ixsl:window(), 'generateUUID', [])"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@* | node()" mode="modal">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- CALLBACKS -->
    
    <xsl:template name="ixsl:ontypeTypeaheadCallback">
        <xsl:next-match>
            <xsl:with-param name="container-uri" select="resolve-uri('ns/domain', $ldt:base)"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template name="onaddModalFormCallback">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="?body">
                    <xsl:variable name="event" select="ixsl:event()"/>
                    <xsl:variable name="target" select="ixsl:get($event, 'target')"/>
                    <xsl:variable name="target-id" select="$target/@id" as="xs:string?"/>
                    <xsl:variable name="doc-id" select="concat('id', ixsl:call(ixsl:window(), 'generateUUID', []))" as="xs:string"/>
                    <xsl:variable name="modal-div" as="element()">
                        <xsl:apply-templates select="//div[tokenize(@class, ' ') = 'modal-constructor']" mode="modal">
                            <xsl:with-param name="target-id" select="$target-id" tunnel="yes"/>
                            <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="form-id" select="$modal-div/form/@id" as="xs:string"/>

                    <xsl:for-each select="ixsl:page()//body">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <!-- append modal div to body -->
                            <xsl:copy-of select="$modal-div"/>
                        </xsl:result-document>

                        <ixsl:set-style name="cursor" select="'default'"/>
                    </xsl:for-each>

                    <!-- add event listeners to the descendants of modal form -->
                    <xsl:call-template name="add-form-listeners">
                        <xsl:with-param name="id" select="$form-id"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="." mode="ixsl:onaddValueCallback">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="target" select="ixsl:get($event, 'target')"/>
        <!-- ancestor-or-self axis needed because either <button> or its child <img> can be event target -->
        <xsl:variable name="forClass" select="$target/ancestor-or-self::button/@value" as="xs:anyURI"/>
        <xsl:variable name="button" select="id($target/ancestor-or-self::button/@id, ixsl:page())" as="element()"/>
        <xsl:variable name="template-doc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.typeahead.rdfXml')" as="document-node()"/>
        <xsl:variable name="selected-property" select="$button/../preceding-sibling::*/select/option[ixsl:get(., 'selected') = true()]/ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="for" select="generate-id($template-doc//*[@rdf:nodeID][rdf:type/@rdf:resource = $forClass]/*[concat(namespace-uri(), local-name()) = $selected-property][1]/(@rdf:*[local-name() = ('resource', 'nodeID')], node())[1])" as="xs:string"/>

        <xsl:for-each select="$button">
            <xsl:for-each select="../..">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:for-each select="$template-doc//*[@rdf:nodeID][rdf:type/@rdf:resource = $forClass]/*[concat(namespace-uri(), local-name()) = $selected-property][1]">
                        <xsl:apply-templates select="." mode="xhtml:Input">
                            <xsl:with-param name="type" select="'hidden'"/>
                        </xsl:apply-templates>

                        <label class="control-label" for="{$for}" title="{$selected-property}">
                            <xsl:apply-templates select="." mode="ac:property-label"/>
                        </label>

                        <div class="controls">
                            <div class="btn-group pull-right">
                                <button type="button" class="btn btn-small pull-right btn-remove" title="Remove this statement"></button>
                            </div>

                            <xsl:apply-templates select="(@rdf:*[local-name() = ('resource', 'nodeID')], node())" mode="bs2:FormControl"/>
                        </div>
                    </xsl:for-each>
                </xsl:result-document>
            </xsl:for-each>
            
            <!-- move property creation control group down, by appending it to the parent fieldset -->
            <xsl:for-each select="../../..">
                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:apply-templates select="$template-doc//*[@rdf:nodeID][rdf:type/@rdf:resource = $forClass]/*[not(self::rdf:type)][not(self::foaf:isPrimaryTopicOf)][1]" mode="bs2:PropertyControl">
                        <xsl:with-param name="template" select="$template-doc//*[@rdf:nodeID][rdf:type/@rdf:resource = $forClass]"/>
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:result-document>
            </xsl:for-each>

            <!-- apply WYMEditor on textarea if object is XMLLiteral -->
            <xsl:call-template name="add-value-listeners">
                <xsl:with-param name="id" select="$for"/>
                <!-- <xsl:with-param name="wymeditor" select="$template-doc//*[@rdf:nodeID][rdf:type/@rdf:resource = $forClass]/*[concat(namespace-uri(), local-name()) = $selected-property]/@rdf:*[local-name() = 'parseType'] = 'Literal'"/> -->
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="add-value-listeners">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:for-each select="id($id, ixsl:page())">
            <xsl:apply-templates select="." mode="apl:PostConstructMode"/>
            
            <xsl:value-of select="ixsl:call(., 'focus', [])"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="add-form-listeners">
        <xsl:param name="id" as="xs:string"/>
        <xsl:message>FORM ID: <xsl:value-of select="$id"/></xsl:message>

        <xsl:apply-templates select="id($id, ixsl:page())" mode="apl:PostConstructMode"/>
    </xsl:template>

    <xsl:template match="*" mode="apl:PostConstructMode">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!-- LISTENER IDENTITY TRANSFORM - binding events to inputs -->
    
    <xsl:template match="text()" mode="apl:PostConstructMode"/>

    <xsl:template match="div[tokenize(@class, ' ') = 'modal']/form" mode="apl:PostConstructMode" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'submit', ixsl:get(ixsl:window(), 'onModalFormSubmit') ])"/>
        </xsl:message>
        
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <!-- remove property button -->
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-remove']" mode="apl:PostConstructMode" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'click', ixsl:get(ixsl:window(), 'onRemoveButtonClick') ])"/>
        </xsl:message>
    </xsl:template>

    <!-- subject type change -->
    <xsl:template match="select[tokenize(@class, ' ') = 'subject-type']" mode="apl:PostConstructMode" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onSubjectTypeChange') ])"/>
        </xsl:message>
    </xsl:template>
        
    <!-- constructor dropdown -->
    <xsl:template match="*[tokenize(@class, ' ') = 'btn-group'][*[tokenize(@class, ' ') = 'dropdown-toggle']]" mode="apl:PostConstructMode" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(., 'addEventListener',  ['click', ixsl:get(ixsl:window(), 'onDropdownClick') ])"/>
        </xsl:message>
    </xsl:template>
    
    <xsl:template match="textarea[tokenize(@class, ' ') = 'wymeditor']" mode="apl:PostConstructMode" priority="1">
        <!-- without wrapping into comment, we get: SEVERE: In delayed event: DOM error appending text node with value: '[object Object]' to node with name: #document -->
        <xsl:message>
            <!-- call .wymeditor() on textarea to show WYMEditor -->
            <xsl:value-of select="ixsl:call(ixsl:call(ixsl:window(), 'jQuery', [ . ]), 'wymeditor', [])"/>
        </xsl:message>
    </xsl:template>

    <xsl:template match="fieldset//input" mode="apl:PostConstructMode" priority="1">
        <!-- subject value change -->
        <xsl:if test="tokenize(@class, ' ') = 'subject'">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onSubjectValueChange') ])"/>
            </xsl:message>
        </xsl:if>
        <!-- object onmouseover (tooltip) -->
        <xsl:if test="@name = ('ou', 'ob', 'ol')">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'mouseover', ixsl:get(ixsl:window(), 'onInputMouseOver') ])"/>
            </xsl:message>
        </xsl:if>
        <!-- typeahead blur -->
        <xsl:if test="tokenize(@class, ' ') = 'resource-typeahead'">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'blur', ixsl:get(ixsl:window(), 'onTypeaheadInputBlur') ])"/>
            </xsl:message>
        </xsl:if>
        <!-- prepended/appended input -->
        <xsl:if test="@type = 'text' and ../tokenize(@class, ' ') = ('input-prepend', 'input-append')">
            <xsl:variable name="value" select="concat(preceding-sibling::*[@class = 'add-on']/text(), @value, following-sibling::*[@class = 'add-on']/text())" as="xs:string?"/>
            <xsl:message>Concatenated @value: <xsl:value-of select="$value"/></xsl:message>
            <!-- set the initial value the same way as the event handler does -->
            <ixsl:set-property object="../input[@type = 'hidden']" name="value" select="$value"/>

            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onPrependedAppendedInputChange') ])"/>
            </xsl:message>
        </xsl:if>
        
        <!-- TO-DO: move to a better place. Does not take effect if typeahead is reset -->
        <ixsl:set-property object="." name="autocomplete" select="'off'"/>
    </xsl:template>
    
</xsl:stylesheet>