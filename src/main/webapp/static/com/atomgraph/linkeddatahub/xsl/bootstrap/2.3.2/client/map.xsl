<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:geo="&geo;"
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>
    
    <!-- FUNCTIONS -->

    <!-- TO-DO: port SPARQLMap JS-based logic to native XSLT code -->
    
    <!-- creates Google Maps object -->
    
    <xsl:function name="ldh:create-map">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="lat" as="xs:float"/>
        <xsl:param name="lng" as="xs:float"/>
        <xsl:param name="zoom" as="xs:integer"/>

        <xsl:variable name="tile-options" select="ldh:new-object()"/>
        <ixsl:set-property name="source" select="ldh:new('ol.source.OSM', [])" object="$tile-options"/>
        <xsl:variable name="tile" select="ldh:new('ol.layer.Tile', [ $tile-options ])"/>
        <xsl:variable name="layers" select="[ $tile ]" as="array(*)"/>

        <xsl:variable name="view-options" select="ldh:new-object()"/>
        <xsl:variable name="lon-lat" select="[ $lng, $lat ]" as="array(*)"/>
        <xsl:variable name="center" select="ixsl:call(ixsl:get(ixsl:window(), 'ol.proj'), 'fromLonLat', [ $lon-lat ])"/>
        <!--
        Saxon-JS issue: https://saxonica.plan.io/issues/5656#note-4 - call view.setCenter() instead
        <ixsl:set-property name="center" select="$center" object="$view-options"/>
        -->
        <ixsl:set-property name="zoom" select="$zoom" object="$view-options"/>
        <xsl:variable name="view" select="ldh:new('ol.View', [ $view-options ])"/>
        
        <xsl:variable name="map-options" select="ldh:new-object()"/>
        <ixsl:set-property name="target" select="$canvas-id" object="$map-options"/>
        <ixsl:set-property name="layers" select="$layers" object="$map-options"/>
        <ixsl:set-property name="view" select="$view" object="$map-options"/>

        <xsl:variable name="map" select="ldh:new('ol.Map', [ $map-options ])"/>
        <xsl:sequence select="ixsl:call($view, 'setCenter', [ $center ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="$map"/>
    </xsl:function>

    <xsl:function name="ldh:map-marker-onclick">
        <xsl:param name="map" as="item()"/>
       
        <xsl:variable name="container" select="ixsl:call(ixsl:page(), 'createElement', [ 'div' ])" as="element()"/>
        <ixsl:set-property name="id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])" object="$container"/>
        <xsl:sequence select="ixsl:call(ixsl:page()/html/body, 'appendChild', [ $container ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="overlay-options" select="ldh:new-object()"/>
        <ixsl:set-property name="element" select="$container" object="$overlay-options"/>
        <ixsl:set-property name="autoPan" select="true()" object="$overlay-options"/>
        <!--<ixsl:set-property name="autoPanAnimation" select="" object="$overlay-options"/>-->
        <xsl:variable name="overlay" select="ldh:new('ol.Overlay', [ $overlay-options ])"/>
        <xsl:sequence select="ixsl:call($map, 'addOverlay', [ $overlay ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:message>map.getOverlays().getArray().length: <xsl:value-of select="ixsl:get(ixsl:call(ixsl:call($map, 'getOverlays', []), 'getArray', []), 'length')"/></xsl:message>
        
        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function mapOnClick(map, overlay, evt) {
                    var feature = map.forEachFeatureAtPixel(evt.pixel, function (feat, layer) {
                            return feat;
                        }
                    );

                    if (feature && feature.getGeometry() instanceof ol.geom.Point) {
                        var coord = evt.coordinate;
                        console.log(JSON.stringify(coord));

                        overlay.getElement().innerHTML = "<h1>Whateverest</h1>";
                        overlay.setPosition(coord);
                    }
                    else {
                        overlay.setPosition(undefined);
                    }
                }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <!-- bind map and overlay variables and return new bound function: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_objects/Function/bind#partially_applied_functions -->
        <xsl:sequence select="ixsl:call($js-function, 'bind', [ (), $map, $overlay ])"/>
    </xsl:function>
    
    <!-- creates SPARQLMap.Geo object (for containers) -->
    
    <xsl:function name="ac:create-geo-object">
        <xsl:param name="map" as="item()"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="graph-var-name" as="xs:string?"/>

        <!-- set $this value -->
        <xsl:variable name="select-string" select="replace($select-string, '\$this', '&lt;' || $uri || '&gt;')" as="xs:string"/>
        <!-- TO-DO: move Geo under AtomGraph namespace -->
        <xsl:choose>
            <xsl:when test="$graph-var-name">
                <xsl:sequence select="ldh:new('SPARQLMap.Geo', [ $map, ldh:new('URL', [ $base ]), ldh:new('URL', [ $endpoint ]), $select-string, $focus-var-name, $graph-var-name ])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:new('SPARQLMap.Geo', [ $map, ldh:new('URL', [ $base ]), ldh:new('URL', [ $endpoint ]), $select-string, $focus-var-name ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="ac:add-geo-listener">
        <xsl:param name="escaped-content-uri" as="xs:anyURI"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="window.LinkedDataHub.contents['{$escaped-content-uri}'].map.addListener('idle', function() {{ window.LinkedDataHub.contents['{$escaped-content-uri}'].geo.loadMarkers(window.LinkedDataHub.contents['{$escaped-content-uri}'].geo.addMarkers); }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:template>

    <!-- load geo resources with a given boundary -->
    
    <xsl:template name="ldh:LoadGeoResources">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-id" as="xs:string"/>
        <xsl:param name="escaped-content-uri" as="xs:anyURI"/>
        <xsl:param name="content" as="element()?"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, $results-uri)" as="xs:anyURI"/>

        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <xsl:call-template name="onGeoResultsLoad">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="content-id" select="$content-id"/>
                <xsl:with-param name="escaped-content-uri" select="$escaped-content-uri"/>
                <xsl:with-param name="content" select="$content"/>
                <xsl:with-param name="active-mode" select="$active-mode"/>
                <xsl:with-param name="select-string" select="$select-string"/>
                <xsl:with-param name="select-xml" select="$select-xml"/>
                <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                <xsl:with-param name="endpoint" select="$endpoint"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <!-- add marker logic ported from SPARQLMap -->
    
    <xsl:template name="ldh:AddMapMarkers">
        <xsl:param name="resources" as="element()*"/> <!-- rdf:Descriptions -->
        <xsl:param name="map" as="item()"/>

        <xsl:variable name="feature-seq" as="item()*">
            <xsl:for-each select="$resources">
                <xsl:variable name="lon-lat" select="[ xs:float(geo:long/text()), xs:float(geo:lat/text()) ]" as="array(*)"/>
                <xsl:variable name="coord" select="ixsl:call(ixsl:get(ixsl:window(), 'ol.proj'), 'fromLonLat', [ $lon-lat ])"/>
                <xsl:variable name="geometry" select="ldh:new('ol.geom.Point', [ $coord ])"/>

                <xsl:variable name="feature-options" select="ldh:new-object()"/>
                <ixsl:set-property name="geometry" select="$geometry" object="$feature-options"/>
                <xsl:variable name="feature" select="ldh:new('ol.Feature', [ $feature-options ])"/>
                
                <xsl:if test="@rdf:about">
                    <xsl:sequence select="ixsl:call($feature, 'setId', [ string(@rdf:about) ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
                
                <xsl:sequence select="$feature"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="features" select="array{ $feature-seq }" as="array(*)"/>

        <xsl:variable name="icon-options" select="ldh:new-object()"/>
        <!-- <ixsl:set-property name="anchor" select="" object="$icon-options"/> -->
        <ixsl:set-property name="anchorXUnits" select="'fraction'" object="$icon-options"/>
        <ixsl:set-property name="anchorYUnits" select="'pixels'" object="$icon-options"/>
        <!--<ixsl:set-property name="scale" select="0.2" object="$icon-options"/>-->
        <ixsl:set-property name="src" select="'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Map_marker_font_awesome.svg/30px-Map_marker_font_awesome.svg.png'" object="$icon-options"/>
        <xsl:variable name="icon" select="ldh:new('ol.style.Icon', [ $icon-options ])"/>
        <xsl:sequence select="ixsl:call($icon, 'setAnchor', [ [0.5, 30] ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="style-options" select="ldh:new-object()"/>
        <ixsl:set-property name="image" select="$icon" object="$style-options"/>
        <xsl:variable name="style" select="ldh:new('ol.style.Style', [ $style-options ])"/>
        
        <xsl:variable name="source-options" select="ldh:new-object()"/>
        <!--<ixsl:set-property name="features" select="$features" object="$source-options"/>-->
        <xsl:variable name="source" select="ldh:new('ol.source.Vector', [ $source-options ])"/>
        <xsl:sequence select="ixsl:call($source, 'addFeatures', [ $features ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="layer-options" select="ldh:new-object()"/>
        <ixsl:set-property name="source" select="$source" object="$layer-options"/>
        <ixsl:set-property name="style" select="$style" object="$layer-options"/>
        <xsl:variable name="layer" select="ldh:new('ol.layer.Vector', [ $layer-options ])"/>
        
        <xsl:sequence select="ixsl:call($map, 'addLayer', [ $layer ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- when container RDF/XML results load, render them -->
    <xsl:template name="onGeoResultsLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <!--<xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>-->
        <xsl:param name="content-id" as="xs:string"/>
        <xsl:param name="escaped-content-uri" select="xs:anyURI(translate($container/@about, '.', '-'))" as="xs:anyURI"/>
        <xsl:param name="content" as="element()?"/>
        <xsl:param name="active-mode" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        
        <!-- update progress bar -->
        <xsl:for-each select="$container//div[@class = 'bar']">
            <ixsl:set-style name="width" select="'75%'" object="."/>
        </xsl:for-each>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="canvas-id" select="$content-id || '-map-canvas'" as="xs:string"/>
                    <xsl:variable name="initial-load" select="not(ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri), 'map'))" as="xs:boolean"/>
                    <xsl:variable name="avg-lat" select="avg(distinct-values(rdf:RDF/rdf:Description/geo:lat/xs:float(.)))" as="xs:float?"/>
                    <xsl:variable name="avg-lng" select="avg(distinct-values(rdf:RDF/rdf:Description/geo:long/xs:float(.)))" as="xs:float?"/>
                    <!-- reuse center and zoom if map object already exists, otherwise set defaults -->
                    <xsl:variable name="center-lat" select="if (not($initial-load)) then xs:float(ixsl:call(ixsl:get(ixsl:window(), 'ol.proj'), 'toLonLat', [ ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri), 'map'), 'getView', []), 'getCenter', []) ])[2]) else (if (exists($avg-lat)) then $avg-lat else 0)" as="xs:float"/>
                    <xsl:variable name="center-lng" select="if (not($initial-load)) then xs:float(ixsl:call(ixsl:get(ixsl:window(), 'ol.proj'), 'toLonLat', [ ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri), 'map'), 'getView', []), 'getCenter', []) ])[1]) else (if (exists($avg-lng)) then $avg-lng else 0)" as="xs:float"/>
                    <xsl:variable name="zoom" select="if (not($initial-load)) then xs:integer(ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri), 'map'), 'getView', []), 'getZoom', [])) else 4" as="xs:integer"/>
                    <xsl:variable name="map" select="ldh:create-map($canvas-id, $center-lat, $center-lng, $zoom)" as="item()"/>
                    <xsl:sequence select="ixsl:call($map, 'on', [ 'click', ldh:map-marker-onclick($map) ])[current-date() lt xs:date('2000-01-01')]"/>
                    
                    <ixsl:set-property name="map" select="$map" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri)"/>

                    <xsl:call-template name="ldh:AddMapMarkers">
                        <xsl:with-param name="resources" select="rdf:RDF/rdf:Description[geo:lat/text() castable as xs:float][geo:long/text() castable as xs:float]"/>
                        <xsl:with-param name="map" select="$map"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- error response - could not load query results -->
                <xsl:call-template name="render-container-error">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="message" select="?message"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- loading is done - restore the default mouse cursor -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template name="onMarkerClick">
        <xsl:param name="map"/>
        <xsl:param name="marker"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        
        <!-- InfoWindowMode is handled as a special case in layout.xsl -->
        <xsl:variable name="mode" select="'https://w3id.org/atomgraph/linkeddatahub/templates#InfoWindowMode'" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:query-params(xs:anyURI($mode)), $uri)" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="request" as="item()*">
            <!-- request HTML instead of XHTML because Google Maps' InfoWindow doesn't support XHTML -->
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'text/html' } }">
                <xsl:call-template name="onInfoWindowLoad">
                    <xsl:with-param name="map" select="$map"/>
                    <xsl:with-param name="marker" select="$marker"/>
                    <xsl:with-param name="uri" select="$uri"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template name="onInfoWindowLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="map"/>
        <xsl:param name="marker"/>
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'text/html')">
                <xsl:for-each select="?body">
                    <xsl:variable name="info-window-options" select="ldh:new-object()"/>
                    <!-- render first child of <body> as InfoWindow content -->
                    <xsl:variable name="info-window-html" select="/html/body/*[1]" as="element()"/>
                    <ixsl:set-property name="content" select="$info-window-html" object="$info-window-options"/>
                    <xsl:variable name="info-window" select="ldh:new('google.maps.InfoWindow', [ $info-window-options ])"/>
                    <xsl:variable name="open-options" select="ldh:new-object()"/>
                    <ixsl:set-property name="anchor" select="$marker" object="$open-options"/>
                    <ixsl:set-property name="map" select="$map" object="$open-options"/>
                    <ixsl:set-property name="shouldFocus" select="false()" object="$open-options"/>
                    <xsl:sequence select="ixsl:call($info-window, 'open', [ $open-options ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="info-window-options" select="ldh:new-object()"/>
                <xsl:variable name="info-window-html" as="element()">
                    <div class="alert alert-block">
                        <strong>Could not map resource: <a href="{$uri}"><xsl:value-of select="$uri"/></a></strong>
                    </div>
                </xsl:variable>
                <ixsl:set-property name="content" select="$info-window-html" object="$info-window-options"/>
                <xsl:variable name="info-window" select="ldh:new('google.maps.InfoWindow', [ $info-window-options ])"/>
                <xsl:variable name="open-options" select="ldh:new-object()"/>
                <ixsl:set-property name="anchor" select="$marker" object="$open-options"/>
                <ixsl:set-property name="map" select="$map" object="$open-options"/>
                <ixsl:set-property name="shouldFocus" select="false()" object="$open-options"/>
                <xsl:sequence select="ixsl:call($info-window, 'open', [ $open-options ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
</xsl:stylesheet>
