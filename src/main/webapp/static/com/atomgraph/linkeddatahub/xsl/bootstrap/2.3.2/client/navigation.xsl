<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- KEYS -->

    <xsl:key name="type-count" match="srx:result" use="srx:binding[@name = 'type']/srx:uri"/>

    <!-- PARAMS -->

    <xsl:param name="class-types-string" as="xs:string">
<![CDATA[
SELECT DISTINCT  ?type (COUNT(?s) AS ?count)
WHERE
  {   { ?s  a  ?type }
    UNION
      { GRAPH ?g
          { ?s  a  ?type }
      }
  }
GROUP BY ?type
ORDER BY DESC(COUNT(?s))
LIMIT   10
]]>
    </xsl:param>

    <xsl:param name="geo-resources-string" as="xs:string">
<![CDATA[
PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
PREFIX dct: <http://purl.org/dc/terms/>

SELECT DISTINCT ?resource
WHERE
  { GRAPH ?graph
      { ?resource  geo:lat   ?lat ;
                   geo:long  ?long
        OPTIONAL
          { ?resource  a  ?type }
        OPTIONAL
          { ?resource  dct:title  ?title }
      }
  }
ORDER BY ?title
]]>
    </xsl:param>

    <xsl:param name="latest-resources-string" as="xs:string">
<![CDATA[
PREFIX dct: <http://purl.org/dc/terms/>

SELECT DISTINCT ?dated
WHERE
  { GRAPH ?graph
      { ?dated  dct:created  ?created }
  }
ORDER BY DESC(?created)
]]>
    </xsl:param>

    <!-- TEMPLATES -->
    
    <xsl:template name="ldh:LeftSidebar">
        <xsl:param name="base" select="ldt:base()" as="xs:anyURI"/>

        <!-- Document tree container -->
        <div id="document-tree">
            <h2 class="nav-header btn">
                <xsl:apply-templates select="key('resources', 'document-tree', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </h2>

            <ul class="well well-small nav nav-list">
                <!-- TO-DO: generalize -->
                <li>
                    <button class="btn btn-small btn-expand-tree"></button>
                    <a href="{$base}" class="btn-logo btn-container">
                        <xsl:apply-templates select="key('resources', 'root', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </a>
                </li>
            </ul>
        </div>

        <!-- Class list container -->
        <div>
            <h2 class="nav-header btn">
                <xsl:apply-templates select="key('resources', 'classes', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </h2>

            <ul class="well well-small nav nav-list" id="class-list">
                <!-- class list will be loaded dynamically -->
            </ul>
        </div>

        <!-- Other section -->
        <div id="other-views">
            <h2 class="nav-header btn">
                <xsl:apply-templates select="key('resources', 'other', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
            </h2>

            <ul class="well well-small nav nav-list">
                <li>
                    <button type="button" class="btn btn-logo btn-geo">
                        <xsl:apply-templates select="key('resources', 'geo', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </button>
                </li>
                <li>
                    <button type="button" class="btn btn-logo btn-latest">
                        <xsl:apply-templates select="key('resources', 'latest', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </button>
                </li>
            </ul>
        </div>
    </xsl:template>
    
    <xsl:template name="ldh:DocTreeActivateHref">
        <xsl:context-item as="element()" use="required"/> <!-- document tree container -->
        <xsl:param name="href" as="xs:anyURI"/>

        <!-- Strip query params from href to ensure consistent matching -->
        <xsl:variable name="target-uri" select="ac:document-uri($href)" as="xs:anyURI"/>

        <xsl:message>
            ldh:DocTreeActivateHref $href: <xsl:value-of select="$href"/>, stripped: <xsl:value-of select="$target-uri"/>
        </xsl:message>

        <!-- make the previously active list items inactive -->
        <xsl:for-each select=".//li[contains-token(@class, 'active')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <!-- Find li elements whose href (without query params) matches target href (without query params) -->
        <xsl:for-each select=".//li[a[ac:document-uri(xs:anyURI(@href)) = $target-uri]]">
            <!-- mark the new list item as active -->
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- Update both document-tree and class-list after navigation -->
    <xsl:template name="ldh:NavigationUpdate">
        <xsl:param name="href" as="xs:anyURI"/>

        <!-- activate the current URL in the document tree -->
        <xsl:for-each select="id('document-tree', ixsl:page())">
            <xsl:variable name="href-string" select="string($href)" as="xs:string"/>
            <xsl:variable name="target" select="xs:anyURI(if (contains($href-string, '?')) then substring-before($href-string, '?') else $href-string)" as="xs:anyURI"/>
            <xsl:call-template name="ldh:DocTreeExpandPathAndActivate">
                <xsl:with-param name="container" select="."/>
                <xsl:with-param name="target" select="$target"/>
            </xsl:call-template>
        </xsl:for-each>

        <!-- reload the class list -->
        <xsl:for-each select="id('class-list', ixsl:page())">
            <xsl:call-template name="ldh:ClassListLoad">
                <xsl:with-param name="container" select="."/>
                <xsl:with-param name="endpoint" select="sd:endpoint()"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="ldh:DocTreeExpandPathAndActivate">
        <xsl:param name="container" as="element()"/> <!-- document-tree element -->
        <xsl:param name="target" as="xs:anyURI"/> <!-- target document URI (already stripped of query params) -->

        <xsl:message>ldh:DocTreeExpandPathAndActivate - starting descent for target: <xsl:value-of select="$target"/></xsl:message>

        <!-- Find the root <li> element (first top-level li in the tree) -->
        <xsl:variable name="root-li" select="$container/ul/li[1]" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$root-li">
                <xsl:message>ldh:DocTreeExpandPathAndActivate - found root: <xsl:value-of select="$root-li/a/@href"/></xsl:message>
                <!-- Start recursive descent from root -->
                <xsl:sequence select="ldh:doctree-descend($root-li, $target, $container)[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>ldh:DocTreeExpandPathAndActivate - no root found in tree</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="ldh:DocTreeResourceLoad">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"> <!-- using the ldh:SelectChildren query -->
            <xsl:variable name="select-string" select="key('resources', '&ldh;SelectChildren', document(ac:document-uri('&ldh;')))/sp:text" as="xs:string"/>
            <xsl:variable name="select-string" select="replace($select-string, '$this', '&lt;' || $uri || '&gt;', 'q')" as="xs:string"/>
            <xsl:variable name="select-json" as="item()">
                <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
            </xsl:variable>
            <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
            <!-- replace ?child ?thing with ?child - we don't need the topics of documents here -->
            <xsl:variable name="select-xml" as="document-node()">
                <xsl:document>
                    <xsl:apply-templates select="json-to-xml($select-json-string)" mode="ldh:replace-variables">
                        <xsl:with-param name="var-names" select="('child')" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:document>
            </xsl:variable>
            <xsl:sequence select="$select-xml"/>
        </xsl:param>
        <xsl:param name="endpoint" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'container': $container,
            'uri': $uri
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:left-sidebar-resource-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about]" mode="bs2:DocTreeListItem">
        <xsl:param name="class" as="xs:string?"/>

        <li>
            <!-- only containers have can have children resources -->
            <xsl:if test="sioc:has_parent">
                <button class="btn btn-small btn-expand-tree"></button>
            </xsl:if>
            
            <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor">
                <xsl:with-param name="id" select="()"/>
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
        </li>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
    <!-- show left-side document tree -->
    
    <xsl:template match="body[id('left-sidebar', ixsl:page())]" mode="ixsl:onmousemove">
        <xsl:variable name="x" select="ixsl:get(ixsl:event(), 'clientX')"/>
        
        <!-- check that the mouse is on the left edge -->
        <xsl:if test="$x = 0">
            <!-- show #left-sidebar -->
            <ixsl:set-style name="display" select="'block'" object="id('left-sidebar', ixsl:page())"/>
        </xsl:if>
    </xsl:template>
    
    <!-- hide the document tree container if its position is fixed (i.e. the layout is not responsive) -->
    <xsl:template match="div[@id = 'left-sidebar'][ixsl:style(.)?position = 'fixed']" mode="ixsl:onmouseout">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element mouse entered -->
        
        <!-- only hide if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="div[@id = 'document-tree']//li/a[@href]" mode="ixsl:onclick" priority="1">
        <xsl:variable name="href" select="@href" as="xs:anyURI"/>

        <xsl:for-each select="ancestor::div[@id = 'document-tree']">
            <xsl:call-template name="ldh:DocTreeActivateHref">
                <xsl:with-param name="href" select="$href"/>
            </xsl:call-template>
        </xsl:for-each>

        <xsl:next-match/>
    </xsl:template>
    
    <!-- expands tree -->
    
    <xsl:template match="button[contains-token(@class, 'btn-expand-tree')]" mode="ixsl:onclick">
        <xsl:variable name="href" select="following-sibling::a/@href" as="xs:anyURI"/>
        <xsl:variable name="container" select=".." as="element()"/> <!-- the parent <li> -->

        <xsl:choose>
            <!-- if children list does not exist, create it -->
            <xsl:when test="not($container/ul)">
                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expand-tree', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expanded-tree', true() ])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <ul class="well well-small nav nav-list">
                            <!-- list items will be injected by ldh:DocTreeResourceLoad -->
                        </ul>
                    </xsl:result-document>
                </xsl:for-each>

                <xsl:call-template name="ldh:DocTreeResourceLoad">
                    <xsl:with-param name="container" select="$container/ul"/>
                    <xsl:with-param name="uri" select="$href"/>
                    <xsl:with-param name="endpoint" select="sd:endpoint()"/>
                </xsl:call-template>
            </xsl:when>
            <!-- if the children list is present but hidden, show it -->
            <xsl:when test="ixsl:style($container/ul)?display = 'none'">
                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expand-tree', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expanded-tree', true() ])[current-date() lt xs:date('2000-01-01')]"/>

                <ixsl:set-style name="display" select="'block'" object="$container/ul"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- collapses tree -->
    
    <xsl:template match="button[contains-token(@class, 'btn-expanded-tree')]" mode="ixsl:onclick">
        <xsl:variable name="container" select=".." as="element()"/> <!-- the parent <li> -->
        
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expand-tree', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expanded-tree', false() ])[current-date() lt xs:date('2000-01-01')]"/>

        <ixsl:set-style name="display" select="'none'" object="$container/ul"/>
    </xsl:template>

    <!-- backlinks -->
    
    <xsl:template match="div[contains-token(@class, 'backlinks-nav')]//*[contains-token(@class, 'nav-header')]" mode="ixsl:onclick">
        <xsl:variable name="backlinks-container" select="ancestor::div[contains-token(@class, 'backlinks-nav')]" as="element()"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="block-uri" select="$block/@about" as="xs:anyURI"/>
        <xsl:variable name="query-string" select="replace($backlinks-string, '$this', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="service-uri" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')) then (if (ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri')) then ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'service-uri') else ()) else ()" as="xs:anyURI?"/>
        <xsl:variable name="service" select="if ($service-uri) then key('resources', $service-uri, document(ac:build-uri(ac:document-uri($service-uri), map{ 'accept': 'application/rdf+xml' }))) else ()" as="element()?"/> <!-- TO-DO: refactor asynchronously -->
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:choose>
            <!-- backlink nav list is not rendered yet - load it -->
            <xsl:when test="not(following-sibling::*[contains-token(@class, 'nav')])">
                <!-- toggle the caret direction -->
                <xsl:for-each select="span[contains-token(@class, 'caret')]">
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'caret-reversed' ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="context" as="map(*)" select="
                  map{
                    'request': $request,
                    'backlinks-container': $backlinks-container
                  }"/>
                <ixsl:promise select="ixsl:http-request($context('request')) =>
                    ixsl:then(ldh:rethread-response($context, ?)) =>
                    ixsl:then(ldh:handle-response#1) =>
                    ixsl:then(ldh:backlinks-response#1)"
                    on-failure="ldh:promise-failure#1"/>
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
        
    <xsl:function name="ldh:breadcrumb-resource-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="uri" select="$context('uri')" as="xs:anyURI"/>
        <xsl:variable name="leaf" select="$context('leaf')" as="xs:boolean"/>

        <xsl:message>ldh:breadcrumb-resource-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="resource" select="key('resources', $uri)" as="element()?"/>
                        <xsl:variable name="parent-uri" select="$resource/sioc:has_container/@rdf:resource | $resource/sioc:has_parent/@rdf:resource" as="xs:anyURI?"/>
                        <xsl:if test="$parent-uri">
                            <xsl:variable name="request-uri" select="ldh:href($parent-uri)" as="xs:anyURI"/>
                            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                            <xsl:variable name="context" as="map(*)" select="
                              map{
                                'request': $request,
                                'container': $container,
                                'uri': $parent-uri,
                                'leaf': false()
                              }"/>
                            <ixsl:promise select="ixsl:http-request($context('request')) =>
                                ixsl:then(ldh:rethread-response($context, ?)) =>
                                ixsl:then(ldh:handle-response#1) =>
                                ixsl:then(ldh:breadcrumb-resource-response#1)"
                                on-failure="ldh:promise-failure#1"/>
                        </xsl:if>

                        <!-- append to the breadcrumb list -->
                        <xsl:for-each select="$container/ul">
                            <xsl:variable name="content" select="*" as="element()*"/>
                            <!-- we want to prepend the parent resource to the beginning of the breadcrumb list -->
                            <xsl:result-document href="?." method="ixsl:replace-content">
                                <xsl:apply-templates select="$resource" mode="bs2:BreadCrumbListItem">
                                    <xsl:with-param name="leaf" select="$leaf"/>
                                </xsl:apply-templates>

                                <xsl:copy-of select="$content"/>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        Error loading breadcrumbs for URI: <xsl:value-of select="$uri"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- Recursive descent function: expands path from current-li down to target-uri -->
    <xsl:function name="ldh:doctree-descend" as="map(*)" ixsl:updating="yes">
        <xsl:param name="current-li" as="element()"/> <!-- the <li> element we're currently at -->
        <xsl:param name="target-uri" as="xs:anyURI"/> <!-- the document URI we want to reach -->
        <xsl:param name="tree-container" as="element()"/> <!-- the document-tree element -->

        <xsl:variable name="current-href-full" select="xs:anyURI($current-li/a/@href)" as="xs:anyURI"/>
        <!-- Strip query parameters for comparison -->
        <xsl:variable name="current-href" select="ac:document-uri($current-href-full)" as="xs:anyURI"/>

        <xsl:message>ldh:doctree-descend - current: <xsl:value-of select="$current-href"/>, target: <xsl:value-of select="$target-uri"/></xsl:message>

        <xsl:choose>
            <!-- Case 1: We've reached the target - activate it -->
            <xsl:when test="$current-href = $target-uri">
                <xsl:message>ldh:doctree-descend - reached target, activating</xsl:message>
                <xsl:for-each select="$tree-container">
                    <xsl:call-template name="ldh:DocTreeActivateHref">
                        <xsl:with-param name="href" select="$target-uri"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:sequence select="map{}"/>
            </xsl:when>

            <!-- Case 2: Target URI starts with current href - need to descend further -->
            <xsl:when test="starts-with(string($target-uri), string($current-href))">
                <xsl:variable name="expand-button" select="$current-li/button[contains-token(@class, 'btn-expand-tree')]" as="element()?"/>

                <xsl:choose>
                    <!-- Case 2a: Has expand button and not expanded yet - expand and load children -->
                    <xsl:when test="$expand-button and not($current-li/ul)">
                        <xsl:message>ldh:doctree-descend - expanding: <xsl:value-of select="$current-href"/></xsl:message>

                        <!-- Create <ul> for children -->
                        <xsl:for-each select="$current-li">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <ul class="well well-small nav nav-list"></ul>
                            </xsl:result-document>
                        </xsl:for-each>

                        <!-- Toggle button class -->
                        <xsl:for-each select="$expand-button">
                            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expand-tree', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'btn-expanded-tree', true() ])[current-date() lt xs:date('2000-01-01')]"/>
                        </xsl:for-each>

                        <!-- Load children and continue descent after loading -->
                        <!-- Build query to load children (inline from ldh:DocTreeResourceLoad) -->
                        <xsl:variable name="select-string" select="key('resources', '&ldh;SelectChildren', document(ac:document-uri('&ldh;')))/sp:text" as="xs:string"/>
                        <xsl:variable name="select-string" select="replace($select-string, '$this', '&lt;' || $current-href || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="select-json" as="item()">
                            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
                            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
                        </xsl:variable>
                        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
                        <xsl:variable name="select-xml" as="document-node()">
                            <xsl:document>
                                <xsl:apply-templates select="json-to-xml($select-json-string)" mode="ldh:replace-variables">
                                    <xsl:with-param name="var-names" select="('child')" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:document>
                        </xsl:variable>

                        <!-- Wrap SELECT into a DESCRIBE -->
                        <xsl:variable name="query-xml" as="element()">
                            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
                        </xsl:variable>
                        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
                        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
                        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
                        <xsl:variable name="results-uri" select="ac:build-uri(sd:endpoint(), map{ 'query': $query-string })" as="xs:anyURI"/>
                        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
                        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>

                        <xsl:variable name="load-context" as="map(*)" select="
                          map{
                            'request': $request,
                            'container': $current-li/ul,
                            'uri': $current-href
                          }"/>

                        <ixsl:promise select="ixsl:http-request($load-context('request')) =>
                            ixsl:then(ldh:rethread-response($load-context, ?)) =>
                            ixsl:then(ldh:handle-response#1) =>
                            ixsl:then(ldh:left-sidebar-resource-response#1) =>
                            ixsl:then(ldh:doctree-descend-after-load(?, $current-li, $target-uri, $tree-container))"/>
                        <xsl:sequence select="map{}"/>
                    </xsl:when>

                    <!-- Case 2b: Already expanded - find next child to descend into -->
                    <xsl:when test="$current-li/ul/li">
                        <xsl:message>ldh:doctree-descend - already expanded, finding next child</xsl:message>

                        <!-- Find which child's href (without query params) is a prefix of target-uri -->
                        <xsl:variable name="next-li" select="$current-li/ul/li[starts-with(string($target-uri), string(ac:document-uri(xs:anyURI(a/@href))))][1]" as="element()?"/>

                        <xsl:choose>
                            <xsl:when test="$next-li">
                                <xsl:message>ldh:doctree-descend - descending to: <xsl:value-of select="$next-li/a/@href"/></xsl:message>
                                <xsl:sequence select="ldh:doctree-descend($next-li, $target-uri, $tree-container)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>ldh:doctree-descend - no matching child found, activating target</xsl:message>
                                <xsl:for-each select="$tree-container">
                                    <xsl:call-template name="ldh:DocTreeActivateHref">
                                        <xsl:with-param name="href" select="$target-uri"/>
                                    </xsl:call-template>
                                </xsl:for-each>
                                <xsl:sequence select="map{}"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- Case 2c: Has expand button but <ul> exists and is empty (loading in progress) -->
                    <xsl:otherwise>
                        <xsl:message>ldh:doctree-descend - waiting for children to load</xsl:message>
                        <xsl:sequence select="map{}"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Case 3: Target is not under this branch -->
            <xsl:otherwise>
                <xsl:message>ldh:doctree-descend - target not under this branch</xsl:message>
                <xsl:sequence select="map{}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Helper to continue descent after children are loaded -->
    <xsl:function name="ldh:doctree-descend-after-load" as="map(*)" ixsl:updating="yes">
        <xsl:param name="load-context" as="map(*)"/> <!-- context from loading -->
        <xsl:param name="current-li" as="element()"/>
        <xsl:param name="target-uri" as="xs:anyURI"/>
        <xsl:param name="tree-container" as="element()"/>

        <xsl:message>ldh:doctree-descend-after-load - children loaded for: <xsl:value-of select="$current-li/a/@href"/></xsl:message>

        <!-- Find which child's href (without query params) is a prefix of target-uri -->
        <xsl:variable name="next-li" select="$current-li/ul/li[starts-with(string($target-uri), string(ac:document-uri(xs:anyURI(a/@href))))][1]" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$next-li">
                <xsl:message>ldh:doctree-descend-after-load - descending to: <xsl:value-of select="$next-li/a/@href"/></xsl:message>
                <xsl:sequence select="ldh:doctree-descend($next-li, $target-uri, $tree-container)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>ldh:doctree-descend-after-load - no matching child, activating target</xsl:message>
                <xsl:for-each select="$tree-container">
                    <xsl:call-template name="ldh:DocTreeActivateHref">
                        <xsl:with-param name="href" select="$target-uri"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:sequence select="$load-context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:left-sidebar-resource-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/> <!-- <ul> element -->
        <xsl:variable name="uri" select="$context('uri')" as="xs:anyURI"/>

        <xsl:message>ldh:left-sidebar-resource-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="resources" select="rdf:RDF/*[@rdf:about]" as="element()*"/>
                        <!-- append to the doc tree list -->
                        <xsl:for-each select="$container">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <xsl:apply-templates select="$resources" mode="bs2:DocTreeListItem">
                                    <xsl:sort select="ac:label(.)"/>
                                    <!--<xsl:with-param name="active" select="@rdf:about = $uri"/>-->
                                </xsl:apply-templates>
                            </xsl:result-document>
                        </xsl:for-each>

                        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        Error loading document tree for URI :<xsl:value-of select="$uri"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <xsl:function name="ldh:backlinks-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="backlinks-container" select="$context('backlinks-container')" as="element()"/>

        <xsl:message>ldh:backlinks-response</xsl:message>
        
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="results" select="?body" as="document-node()"/>

                    <xsl:for-each select="$backlinks-container">
                        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <ul class="well well-small nav nav-list">
                                <xsl:apply-templates select="$results/rdf:RDF/rdf:Description[not(@rdf:about = $doc-uri)]" mode="xhtml:ListItem">
                                    <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                    <xsl:with-param name="mode" select="ixsl:query-params()?mode[1]" tunnel="yes"/> <!-- TO-DO: support multiple modes -->
                                    <xsl:with-param name="render-id" select="false()" tunnel="yes"/>
                                </xsl:apply-templates>
                            </ul>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- Load classes with instances from the SPARQL endpoint -->
    <xsl:template name="ldh:ClassListLoad">
        <xsl:param name="container" as="element()"/> <!-- the <ul id="class-list"> -->
        <xsl:param name="endpoint" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-string" select="$class-types-string" as="xs:string"/>
        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="query-json-string" select="xml-to-json($select-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'container': $container
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:class-list-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- Handle the response from loading classes - extract type URIs and query ns endpoint -->
    <xsl:function name="ldh:class-list-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>

        <xsl:message>ldh:class-list-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                    <xsl:for-each select="?body">
                        <xsl:variable name="results" select="." as="document-node()"/>
                        <!-- extract type URIs from SPARQL results -->
                        <xsl:variable name="type-uris" select="$results/srx:sparql/srx:results/srx:result/srx:binding[@name = 'type']/srx:uri" as="xs:string*"/>

                        <xsl:choose>
                            <xsl:when test="exists($type-uris)">
                                <!-- build DESCRIBE query with VALUES clause -->
                                <xsl:variable name="query-string" select="'DESCRIBE ?type WHERE { VALUES ?type { ' || string-join(for $uri in $type-uris return '&lt;' || $uri || '&gt;', ' ') || ' } }'" as="xs:string"/>
                                <xsl:variable name="ns-uri" select="resolve-uri('ns', ldt:base())" as="xs:anyURI"/>
                                <xsl:variable name="results-uri" select="ac:build-uri($ns-uri, map{ 'query': $query-string })" as="xs:anyURI"/>
                                <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
                                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                                <xsl:variable name="new-context" as="map(*)" select="
                                  map{
                                    'request': $request,
                                    'container': $container,
                                    'type-results': $results
                                  }"/>
                                <ixsl:promise select="ixsl:http-request($new-context('request')) =>
                                    ixsl:then(ldh:rethread-response($new-context, ?)) =>
                                    ixsl:then(ldh:handle-response#1) =>
                                    ixsl:then(ldh:class-list-describe-response#1)"
                                    on-failure="ldh:promise-failure#1"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>No class types found</xsl:message>
                                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        Error loading class types from sparql endpoint
                    </xsl:message>
                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- Handle the response from describing class types -->
    <xsl:function name="ldh:class-list-describe-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="type-results" select="$context('type-results')" as="document-node()"/>

        <xsl:message>ldh:class-list-describe-response</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="class-doc" select="?body" as="document-node()"/>

                    <!-- append to the class tree list -->
                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:for-each select="$type-results//srx:result">
                                <xsl:sort select="xs:integer(srx:binding[@name = 'count']/srx:literal)" order="descending"/>

                                <xsl:choose>
                                    <xsl:when test="key('resources', srx:binding[@name = 'type']/srx:uri, $class-doc)">
                                        <xsl:apply-templates select="key('resources', srx:binding[@name = 'type']/srx:uri, $class-doc)" mode="bs2:ClassListItem">
                                            <xsl:with-param name="count" select="xs:integer(srx:binding[@name = 'count']/srx:literal)"/>
                                        </xsl:apply-templates>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="temp-class" as="element()">
                                            <rdf:Description rdf:about="{srx:binding[@name = 'type']/srx:uri}"/>
                                        </xsl:variable>
                                        <xsl:apply-templates select="$temp-class" mode="bs2:ClassListItem">
                                            <xsl:with-param name="count" select="xs:integer(srx:binding[@name = 'count']/srx:literal)"/>
                                        </xsl:apply-templates>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>                                
                        </xsl:result-document>
                    </xsl:for-each>

                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        Error loading class descriptions from ns endpoint
                    </xsl:message>
                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- Render a class as a list item with button -->
    <xsl:template match="*[@rdf:about]" mode="bs2:ClassListItem">
        <xsl:param name="count" as="xs:integer"/>

        <li>
            <button class="btn btn-class" data-class-uri="{@rdf:about}">
                <span>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </span>
                
                <xsl:if test="exists($count)">
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="$count"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
            </button>
        </li>
    </xsl:template>

    <!-- Opens modal dialog to show instances of a class -->
    <xsl:template match="button[contains-token(@class, 'btn-class')]" mode="ixsl:onclick">
        <xsl:variable name="class-uri" select="xs:anyURI(ixsl:get(., 'dataset.classUri'))"/>
        <xsl:variable name="container-id" select="'class-instances-container'" as="xs:string"/>

        <!-- Create modal structure with a block element -->
        <xsl:variable name="modal" as="element()">
            <div class="modal modal-constructor fade in" id="class-instances-modal">
                <div class="modal-header">
                    <button type="button" class="close">×</button>
                    <legend>
                        <xsl:choose>
                            <xsl:when test="doc-available(ac:document-uri($class-uri))">
                                <xsl:apply-templates select="key('resources', $class-uri, document(ac:document-uri($class-uri)))" mode="ac:label"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$class-uri"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </legend>
                </div>
                <div class="modal-body">
                    <div class="row-fluid block">
                        <div class="span12 progress progress-striped active">
                            <div class="row-fluid row-block-controls" style="position: relative; top: 30px; margin-top: -30px; z-index: 1;">
                                <div class="span12">
                                    <div class="row-fluid">
                                        <div style="width: 0%;" class="span12 bar"></div>
                                    </div>
                                </div>
                            </div>

                            <div id="{$container-id}" class="row-fluid" typeof="&ldh;View">
                                <div class="main span12">
                                    <!-- View results will be rendered here -->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="form-actions modal-footer">
                    <button type="button" class="btn btn-primary btn-close">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
            </div>
        </xsl:variable>

        <!-- Show modal -->
        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" select="$modal"/>
        </xsl:call-template>

        <!-- Create cache entry for the block -->
        <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`'))">
            <ixsl:set-property name="{'`' || $container-id || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:if>

        <!-- Load instances into modal -->
        <xsl:call-template name="ldh:ClassInstancesLoad">
            <xsl:with-param name="container" select="id($container-id, ixsl:page())"/>
            <xsl:with-param name="class-uri" select="$class-uri"/>
            <xsl:with-param name="endpoint" select="sd:endpoint()"/>
            <xsl:with-param name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`')"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Load instances for a specific class -->
    <xsl:template name="ldh:ClassInstancesLoad">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="class-uri" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="cache" as="item()"/>
        <xsl:variable name="container-id" select="$container/@id" as="xs:string"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <!-- determine which query to use based on whether instances are in named graphs -->
        <!-- TODO: we need to check if instances are in named graphs - for now use SelectInstancesInGraphs -->
        <xsl:variable name="query-uri" select="xs:anyURI('&ldh;SelectInstancesInGraphs')" as="xs:anyURI"/>
        <xsl:variable name="select-string" select="key('resources', $query-uri, document(ac:document-uri('&ldh;')))/sp:text" as="xs:string"/>
        <!-- Add VALUES clause to bind $type to the class URI -->
        <xsl:variable name="select-string" select="$select-string || ' VALUES $type { &lt;' || $class-uri || '&gt; }'" as="xs:string"/>

        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="json-to-xml($select-json-string)" mode="ldh:replace-variables">
                    <xsl:with-param name="var-names" select="('s')" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <xsl:variable name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`')" as="item()"/>
        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>
        <ixsl:set-property name="select-string" select="$select-string" object="$cache"/>
        <ixsl:set-property name="initial-var-name" select="'s'" object="$cache"/> <!-- has to match ldh:SelectInstancesInGraphs -->
        <ixsl:set-property name="endpoint" select="sd:endpoint()" object="$cache"/>

        <!-- Initialize progress counters: 3 steps (metadata, render-view, result-count) -->
        <xsl:sequence select="ldh:update-progress-counter($cache, map{'container': $container}, 'init', 3)"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="xs:anyURI('&ac;ListMode')"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="'s'"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- close modals when a link inside them is clicked -->
    <xsl:template match="div[@id = ('class-instances-modal', 'geo-modal', 'latest-modal')]//a[@href]" mode="ixsl:onclick" priority="1">
        <xsl:variable name="modal" select="ancestor::div[contains-token(@class, 'modal')][@id][1]" as="element()"/>

        <!-- remove the modal -->
        <xsl:for-each select="$modal">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:next-match/>
    </xsl:template>

    <!-- Opens modal dialog to show geo resources -->
    <xsl:template match="button[contains-token(@class, 'btn-geo')]" mode="ixsl:onclick">
        <xsl:variable name="container-id" select="'geo-container'" as="xs:string"/>
        <xsl:variable name="select-string" select="$geo-resources-string" as="xs:string"/>

        <!-- Create modal structure with a block element -->
        <xsl:variable name="modal" as="element()">
            <div class="modal modal-constructor fade in" id="geo-modal">
                <div class="modal-header">
                    <button type="button" class="close">×</button>
                    <legend>
                        <xsl:apply-templates select="key('resources', 'geo', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </legend>
                </div>
                <div class="modal-body">
                    <div class="row-fluid block">
                        <div class="span12 progress progress-striped active">
                            <div class="row-fluid row-block-controls" style="position: relative; top: 30px; margin-top: -30px; z-index: 1;">
                                <div class="span12">
                                    <div class="row-fluid">
                                        <div style="width: 0%;" class="span12 bar"></div>
                                    </div>
                                </div>
                            </div>
                            
                            <div id="{$container-id}" class="row-fluid" typeof="&ldh;View">
                                <div class="main span12">
                                    <!-- View results will be rendered here -->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="form-actions modal-footer">
                    <button type="button" class="btn btn-primary btn-close">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
            </div>
        </xsl:variable>

        <!-- Show modal -->
        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" select="$modal"/>
        </xsl:call-template>

        <!-- Create cache entry for the block -->
        <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`'))">
            <ixsl:set-property name="{'`' || $container-id || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:if>
        <xsl:variable name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`')" as="item()"/>
        <ixsl:set-property name="select-string" select="$select-string" object="$cache"/>
        <ixsl:set-property name="initial-var-name" select="'resource'" object="$cache"/> <!-- has to match $geo-resources-string -->
        <ixsl:set-property name="endpoint" select="sd:endpoint()" object="$cache"/>

        <!-- Load geo resources into modal -->
        <xsl:call-template name="ldh:GeoResourcesLoad">
            <xsl:with-param name="container" select="id($container-id, ixsl:page())"/>
            <xsl:with-param name="endpoint" select="sd:endpoint()"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="cache" select="$cache"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Load geo resources -->
    <xsl:template name="ldh:GeoResourcesLoad">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="cache" as="item()"/>
        <xsl:param name="select-string" as="xs:string"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="json-to-xml($select-json-string)" mode="ldh:replace-variables">
                    <xsl:with-param name="var-names" select="('resource')" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <!-- Initialize progress counters: 3 steps (metadata, render-view, result-count) -->
        <xsl:sequence select="ldh:update-progress-counter($cache, map{'container': $container}, 'init', 3)"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="xs:anyURI('&ac;MapMode')"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="'resource'"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

    <!-- Opens modal dialog to show latest resources -->
    <xsl:template match="button[contains-token(@class, 'btn-latest')]" mode="ixsl:onclick">
        <xsl:variable name="container-id" select="'latest-container'" as="xs:string"/>
        <xsl:variable name="select-string" select="$latest-resources-string" as="xs:string"/>

        <!-- Create modal structure with a block element -->
        <xsl:variable name="modal" as="element()">
            <div class="modal modal-constructor fade in" id="latest-modal">
                <div class="modal-header">
                    <button type="button" class="close">×</button>
                    <legend>
                        <xsl:apply-templates select="key('resources', 'latest', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </legend>
                </div>
                <div class="modal-body">
                    <div class="row-fluid block">
                        <div class="span12 progress progress-striped active">
                            <div class="row-fluid row-block-controls" style="position: relative; top: 30px; margin-top: -30px; z-index: 1;">
                                <div class="span12">
                                    <div class="row-fluid">
                                        <div style="width: 0%;" class="span12 bar"></div>
                                    </div>
                                </div>
                            </div>

                            <div id="{$container-id}" class="row-fluid" typeof="&ldh;View">
                                <div class="main span12">
                                    <!-- View results will be rendered here -->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="form-actions modal-footer">
                    <button type="button" class="btn btn-primary btn-close">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
            </div>
        </xsl:variable>

        <!-- Show modal -->
        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" select="$modal"/>
        </xsl:call-template>

        <!-- Create cache entry for the block -->
        <xsl:if test="not(ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`'))">
            <ixsl:set-property name="{'`' || $container-id || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:if>
        <xsl:variable name="cache" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $container-id || '`')" as="item()"/>
        <ixsl:set-property name="select-string" select="$select-string" object="$cache"/>
        <ixsl:set-property name="initial-var-name" select="'dated'" object="$cache"/> <!-- has to match $latest-resources-string -->
        <ixsl:set-property name="endpoint" select="sd:endpoint()" object="$cache"/>

        <!-- Initialize progress counters: 3 steps (metadata, render-view, result-count) -->
        <xsl:sequence select="ldh:update-progress-counter($cache, map{'container': id($container-id, ixsl:page())}, 'init', 3)"/>

        <!-- Load latest resources into modal -->
        <xsl:call-template name="ldh:LatestResourcesLoad">
            <xsl:with-param name="container" select="id($container-id, ixsl:page())"/>
            <xsl:with-param name="endpoint" select="sd:endpoint()"/>
            <xsl:with-param name="select-string" select="$select-string"/>
            <xsl:with-param name="cache" select="$cache"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Load latest resources -->
    <xsl:template name="ldh:LatestResourcesLoad">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="cache" as="item()"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="json-to-xml($select-json-string)" mode="ldh:replace-variables">
                    <xsl:with-param name="var-names" select="('dated')" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <!-- store the transformed query XML -->
        <ixsl:set-property name="select-xml" select="$select-xml" object="$cache"/>

        <!-- Initialize progress counters: 3 steps (metadata, render-view, result-count) -->
        <xsl:sequence select="ldh:update-progress-counter($cache, map{'container': $container}, 'init', 3)"/>

        <xsl:variable name="view-context" as="map(*)">
            <xsl:call-template name="ldh:RenderView">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="active-mode" select="xs:anyURI('&ac;ListMode')"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="initial-var-name" select="'dated'"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
                <xsl:with-param name="cache" select="$cache"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="context" select="map:merge((map{ 'block': $container }, $view-context))" as="map(*)"/>

        <ixsl:promise select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:view-results-thunk#1)
            "
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>

</xsl:stylesheet>