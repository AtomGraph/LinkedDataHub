<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
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
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->
    
    <xsl:template name="ldh:DocTree">
        <xsl:param name="base" select="ldt:base()" as="xs:anyURI"/>

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
            <li>
                <button class="btn btn-small btn-expand-tree"></button>
                <a href="{$base}apps/" class="btn-logo btn-app">
                    <xsl:apply-templates select="key('resources', 'applications', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <li>
                <button class="btn btn-small btn-expand-tree"></button>
                <a href="{$base}charts/" class="btn-logo btn-chart">
                    <xsl:apply-templates select="key('resources', 'charts', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <li>
                <button class="btn btn-small btn-expand-tree"></button>
                <a href="{$base}files/" class="btn-logo btn-file">
                    <xsl:apply-templates select="key('resources', 'files', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <li>
                <button class="btn btn-small btn-expand-tree"></button>
                <a href="{$base}imports/" class="btn-logo btn-import">
                    <xsl:apply-templates select="key('resources', 'imports', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <li>
                <button class="btn btn-small btn-expand-tree"></button>
                <a href="{$base}queries/" class="btn-logo btn-query">
                    <xsl:apply-templates select="key('resources', 'queries', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <li>
                <button class="btn btn-small btn-expand-tree"></button>
                <a href="{$base}services/" class="btn-logo btn-service">
                    <xsl:apply-templates select="key('resources', 'services', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <!-- non-expandable containers (not based on ldh:SelectChildren) -->
            <li>
                <a href="{$base}geo/" class="btn-logo btn-geo">
                    <xsl:apply-templates select="key('resources', 'geo', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
            <li>
                <a href="{$base}latest/" class="btn-logo btn-latest">
                    <xsl:apply-templates select="key('resources', 'latest', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </a>
            </li>
        </ul>
    </xsl:template>
    
    <xsl:template name="ldh:DocTreeActivateHref">
        <xsl:context-item as="element()" use="required"/> <!-- document tree container -->
        <xsl:param name="href" as="xs:anyURI"/>

        <!-- make the previously active list items inactive -->
        <xsl:for-each select=".//li[contains-token(@class, 'active')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:for-each select=".//li[a/@href = $href]">
            <!-- mark the new list item as active -->
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', true() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
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
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:DocTreeResourceLoaded">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="uri" select="$uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
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
    
    <xsl:template match="body[id('doc-tree', ixsl:page())]" mode="ixsl:onmousemove">
        <xsl:variable name="x" select="ixsl:get(ixsl:event(), 'clientX')"/>
        
        <!-- check that the mouse is on the left edge -->
        <xsl:if test="$x = 0">
            <!-- show #doc-tree -->
            <ixsl:set-style name="display" select="'block'" object="id('doc-tree', ixsl:page())"/>
        </xsl:if>
    </xsl:template>
    
    <!-- hide the document tree container if its position is fixed (i.e. the layout is not responsive) -->
    <xsl:template match="div[@id = 'doc-tree'][ixsl:style(.)?position = 'fixed']" mode="ixsl:onmouseout">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element mouse entered -->
        
        <!-- only hide if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="div[@id = 'doc-tree']//li/a[@href]" mode="ixsl:onclick" priority="1">
        <xsl:variable name="href" select="@href" as="xs:anyURI"/>
        
        <xsl:for-each select="ancestor::div[@id = 'doc-tree']">
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
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/>
        
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
    
    <!-- CALLBACKS -->
    
    <xsl:template name="ldh:BreadCrumbResourceLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="leaf" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="resource" select="key('resources', $uri)" as="element()?"/>
                    <xsl:variable name="parent-uri" select="$resource/sioc:has_container/@rdf:resource | $resource/sioc:has_parent/@rdf:resource" as="xs:anyURI?"/>
                    <xsl:if test="$parent-uri">
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $parent-uri)" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="ldh:BreadCrumbResourceLoaded">
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="uri" select="$parent-uri"/>
                                    <xsl:with-param name="leaf" select="false()"/> <!-- parent resources cannot be leaves -->
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
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
    </xsl:template>
    
    <xsl:template name="ldh:DocTreeResourceLoaded">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/> <!-- <ul> element -->
        <xsl:param name="uri" as="xs:anyURI"/>

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
    </xsl:template>
    
</xsl:stylesheet>