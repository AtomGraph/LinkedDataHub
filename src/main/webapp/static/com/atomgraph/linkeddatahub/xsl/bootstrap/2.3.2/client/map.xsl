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
        
        <xsl:variable name="js-function" select="ixsl:get(ixsl:window(), 'ixslTemplateListener')"/>
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), 'MapMarkerClick', $map ])"/> <!-- will invoke template onMapMarkerClick -->
        <xsl:message>$js-function: <xsl:value-of select="$js-function"/></xsl:message>
        <xsl:sequence select="ixsl:call($map, 'on', [ 'click', $js-function ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function (map, evt) {
                    if (!evt.dragging) {
                        map.getTargetElement().style.cursor = map.hasFeatureAtPixel(map.getEventPixel(evt.originalEvent)) ? 'pointer' : '';
                    }
                }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), $map ])"/>
        <xsl:sequence select="ixsl:call($map, 'on', [ 'pointermove', $js-function ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:sequence select="$map"/>
    </xsl:function>

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
                <ixsl:set-property name="name" select="ac:label(.)" object="$feature-options"/>
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

        <xsl:variable name="icon-style-options" select="ldh:new-object()"/>
        <ixsl:set-property name="image" select="$icon" object="$icon-style-options"/>
        <xsl:variable name="icon-style" select="ldh:new('ol.style.Style', [ $icon-style-options ])"/>

        <xsl:variable name="text-options" select="ldh:new-object()"/>
        <ixsl:set-property name="font" select="'12px sans-serif'" object="$text-options"/>
        <ixsl:set-property name="offsetY" select="10" object="$text-options"/>
        <ixsl:set-property name="overflow" select="true()" object="$text-options"/>
        <xsl:variable name="text" select="ldh:new('ol.style.Text', [ $text-options ])"/>

        <xsl:variable name="label-style-options" select="ldh:new-object()"/>
        <ixsl:set-property name="text" select="$text" object="$label-style-options"/>
        <xsl:variable name="label-style" select="ldh:new('ol.style.Style', [ $label-style-options ])"/>

        <xsl:variable name="style" select="[ $icon-style, $label-style ]"/>
        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function(style, labelStyle, feature) {
                    labelStyle.getText().setText(feature.get('name'));
                    return style;
                  }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), $style, $label-style ])"/>

        <xsl:variable name="source-options" select="ldh:new-object()"/>
        <!--<ixsl:set-property name="features" select="$features" object="$source-options"/>-->
        <xsl:variable name="source" select="ldh:new('ol.source.Vector', [ $source-options ])"/>
        <xsl:sequence select="ixsl:call($source, 'addFeatures', [ $features ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="layer-options" select="ldh:new-object()"/>
        <ixsl:set-property name="source" select="$source" object="$layer-options"/>
        <ixsl:set-property name="style" select="$js-function" object="$layer-options"/>
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

<!--    <xsl:template name="onMapPointerMove">
        <xsl:param name="event" as="item()"/>
        <xsl:param name="map" as="item()"/>

        <xsl:choose>
            <xsl:when test="ixsl:call($map, 'hasFeatureAtPixel', [ ixsl:get($event, 'pixel') ])">
                <ixsl:set-style name="cursor" select="'pointer'" object="ixsl:call($map, 'getViewport', [])"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="''" object="ixsl:call($map, 'getViewport', [])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    
    <xsl:template match="." mode="ixsl:onMapMarkerClick">
        <xsl:param name="event" select="ixsl:event()"/>
        <xsl:param name="map" select="ixsl:get(ixsl:get($event, 'detail'), 'map')"/>
        <xsl:message>$event: <xsl:value-of select="$event"/></xsl:message>

        <xsl:variable name="event" select="ixsl:get(ixsl:get($event, 'detail'), 'ol-event')"/> <!-- override the helper CustomEvent with the original OpenLayers event -->

        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function (feat, layer) {
                    return feat;
                }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <xsl:variable name="feature" select="ixsl:call($map, 'forEachFeatureAtPixel', [ ixsl:get($event, 'pixel'), $js-function])" as="item()?"/>
        
        <xsl:if test="exists($feature)"> <!-- TO-DO: && feature.getGeometry() instanceof ol.geom.Point -->
            <xsl:variable name="uri" select="xs:anyURI(ixsl:call($feature, 'getId', []))" as="xs:anyURI"/>
            <!-- InfoWindowMode is handled as a special case in layout.xsl -->
            <xsl:variable name="mode" select="'https://w3id.org/atomgraph/linkeddatahub/templates#InfoWindowMode'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ldh:query-params(xs:anyURI($mode)), $uri)" as="xs:anyURI"/>

            <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

            <xsl:variable name="request" as="item()*">
                <!-- request HTML instead of XHTML because Google Maps' InfoWindow doesn't support XHTML -->
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'text/html' } }">
                    <xsl:call-template name="onInfoWindowLoad">
                        <xsl:with-param name="event" select="$event"/>
                        <xsl:with-param name="map" select="$map"/>
                        <xsl:with-param name="feature" select="$feature"/>
                        <xsl:with-param name="uri" select="$uri"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="onInfoWindowLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="event"/>
        <xsl:param name="map"/>
        <xsl:param name="feature"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'text/html')">
                <xsl:for-each select="?body">
                    <xsl:variable name="info-window-options" select="ldh:new-object()"/>
                    <!-- render first child of <body> as InfoWindow content -->
                    <xsl:variable name="info-window-html" select="/html/body/*[1]" as="element()"/>
                    <xsl:variable name="coord" select="ixsl:get($event, 'coordinate')"/>
                    <xsl:variable name="container" select="ixsl:call(ixsl:page(), 'createElement', [ 'div' ])" as="element()"/>
                    <xsl:sequence select="ixsl:call(ixsl:call($map, 'getOverlayContainerStopEvent', []), 'appendChild', [ $container ])[current-date() lt xs:date('2000-01-01')]"/>
                    <ixsl:set-attribute name="id" select="'whateverest'" object="$container"/>

                    <xsl:variable name="overlay-options" select="ldh:new-object()"/>
                    <ixsl:set-property name="element" select="$container" object="$overlay-options"/>
                    <ixsl:set-property name="autoPan" select="true()" object="$overlay-options"/>
                    <ixsl:set-property name="positioning" select="'bottom-center'" object="$overlay-options"/>
                    <!--<ixsl:set-property name="className" select="'ol-overlay-container ol-selectable'" object="$overlay-options"/>-->
                    <!--<ixsl:set-property name="autoPanAnimation" select="" object="$overlay-options"/>-->
                    <xsl:variable name="overlay" select="ldh:new('ol.Overlay', [ $overlay-options ])"/>
                    <xsl:sequence select="ixsl:call($overlay, 'setPosition', [ $coord ])[current-date() lt xs:date('2000-01-01')]"/>

                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="modal-header">
                                <button type="button" class="close">&#215;</button>
                            </div>
                            
                            <div class="modal-body">
                                <xsl:copy-of select="$info-window-html"/>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                
                    <xsl:sequence select="ixsl:call($map, 'addOverlay', [ $overlay ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
<!--                <xsl:variable name="info-window-options" select="ldh:new-object()"/>
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
                <xsl:sequence select="ixsl:call($info-window, 'open', [ $open-options ])[current-date() lt xs:date('2000-01-01')]"/>-->
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- close popup overlay (info window) -->
    <!-- there seems to be some glitch where this template propagates into an out-of-DOM copy of $container: https://github.com/openlayers/openlayers/issues/6948#issuecomment-1235416369 -->
    
    <xsl:template match="/html//div[contains-token(@class, 'ol-overlay-container')]//div[contains-token(@class, 'modal-header')]/button[contains-token(@class, 'close')]" mode="ixsl:onclick" >
        <xsl:variable name="content-uri" select="ancestor::div[@about][1]/@about" as="xs:anyURI"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'ol-overlay-container')]/div" as="element()"/>
        <xsl:variable name="escaped-content-uri" select="xs:anyURI(translate($content-uri, '.', '-'))" as="xs:anyURI"/>
        <xsl:variable name="map" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri), 'map')"/> <!-- TO-DO: LinkedDataHub.map -->
        <xsl:variable name="overlay" select="ixsl:call(ixsl:call($map, 'getOverlays', []), 'getArray', [])[ ixsl:call(., 'getElement', []) is $container ]"/>
        <xsl:sequence select="ixsl:call($map, 'removeOverlay', [ $overlay ])[current-date() lt xs:date('2000-01-01')]"/> <!-- remove overlay from map -->
    </xsl:template>
    
</xsl:stylesheet>
