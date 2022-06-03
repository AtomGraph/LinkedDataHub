<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY gm     "https://developers.google.com/maps#">
]>
<xsl:stylesheet version="3.0"
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
xmlns:geo="&geo;"
xmlns:ldt="&ldt;"
xmlns:gm="&gm;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>
    
    <!-- FUNCTIONS -->

    <!-- TO-DO: port SPARQLMap JS-based logic to native XSLT code -->
    
    <!-- creates Google Maps object (for containers) -->
    
    <xsl:function name="ac:create-map">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="lat" as="xs:float"/>
        <xsl:param name="lng" as="xs:float"/>
        <xsl:param name="zoom" as="xs:integer"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.maps.Map(document.getElementById('{$canvas-id}'), {{ center: new google.maps.LatLng({$lat}, {$lng}), zoom: {$zoom} }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <!-- creates SPARQLMap.Geo object (for containers) -->
    
    <xsl:function name="ac:create-geo-object">
        <xsl:param name="escaped-content-uri" as="xs:anyURI"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="focus-var-name" as="xs:string"/>
        <xsl:param name="graph-var-name" as="xs:string?"/>

        <!-- set $this value -->
        <xsl:variable name="select-string" select="replace($select-string, '\$this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <xsl:variable name="js-statement" as="element()">
            <!-- TO-DO: move Geo under AtomGraph namespace -->
            <!-- use template literals because the query is multi-line https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals -->
            <xsl:choose>
                <xsl:when test="$graph-var-name">
                    <root statement="new SPARQLMap.Geo(window.LinkedDataHub.contents['{$escaped-content-uri}'].map, new URL('{$base}'), new URL('{$endpoint}'), `{$select-string}`, '{$focus-var-name}', '{$graph-var-name}')"/>
                </xsl:when>
                <xsl:otherwise>
                    <root statement="new SPARQLMap.Geo(window.LinkedDataHub.contents['{$escaped-content-uri}'].map, new URL('{$base}'), new URL('{$endpoint}'), `{$select-string}`, '{$focus-var-name}')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:template name="ac:add-geo-listener">
        <xsl:param name="escaped-content-uri" as="xs:anyURI"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="window.LinkedDataHub.contents['{$escaped-content-uri}'].map.addListener('idle', function() {{ window.LinkedDataHub.contents['{$escaped-content-uri}'].geo.loadMarkers(window.LinkedDataHub.contents['{$escaped-content-uri}'].geo.addMarkers); }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:template>
    
    <!-- add marker logic ported from SPARQLMap -->
    
    <xsl:template name="gm:AddMarker">
        <xsl:context-item as="element()" use="required"/> <!-- rdf:Description -->
        <xsl:param name="map" as="item()"/>

        <xsl:variable name="lat-lng" select="ldh:new('google.maps.LatLng', [ xs:float(geo:lat/text()), xs:float(geo:long/text()) ])"/>
        <xsl:variable name="marker-options" select="ldh:new-object()"/>
        <ixsl:set-property name="position" select="$lat-lng" object="$marker-options"/>
        <ixsl:set-property name="map" select="$map" object="$marker-options"/>
        <ixsl:set-property name="label" select="ac:label(.)" object="$marker-options"/>
        <xsl:variable name="marker" select="ldh:new('google.maps.Marker', [ $marker-options ])"/>
        <!-- make sure $marker is evaluated -->
        <xsl:sequence select="$marker[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:if test="@rdf:about">
            <xsl:variable name="uri" select="string(@rdf:about)" as="xs:string"/>
            <!-- addGoogleMapsListener() is defined in jquery.js -->
            <xsl:sequence select="ixsl:call(ixsl:window(), 'addGoogleMapsListener', [ $marker, 'click', (), 'onMarkerClick', $map, $marker, $uri ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <xsl:template name="onMarkerClick">
        <xsl:param name="map"/>
        <xsl:param name="marker"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        
        <!-- InfoWindowMode is handled as a special case in layout.xsl -->
        <xsl:variable name="mode" select="'https://w3id.org/atomgraph/linkeddatahub/templates#InfoWindowMode'" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $uri, xs:anyURI($mode))" as="xs:anyURI"/>

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
