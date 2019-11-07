<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:sp="&sp;"
xmlns:geo="&geo;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all">
   
    <xsl:template match="*[@rdf:about = '&ac;ListMode']" mode="apl:logo">
        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_view_list_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;TableMode']" mode="apl:logo">
        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_border_all_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;GridMode']" mode="apl:logo">
        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_grid_on_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ChartMode']" mode="apl:logo">
        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_show_chart_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
    </xsl:template>

    <!-- FILTERS -->
    
    <xsl:template name="bs2:FilterIn">
        <div class="sidebar-nav faceted-nav">
            <h2 class="nav-header btn">Types</h2>

            <ul class="well well-small nav nav-list">
                <li>
                    <label class="checkbox">
                        <input type="checkbox" name="Type" value="{resolve-uri('ns/default#Container', $ldt:base)}"> <!-- {@rdf:about | @rdf:nodeID} -->
<!--                                    <xsl:if test="$filter/*/@rdf:resource = @rdf:about">
                                <xsl:attribute name="checked" select="'checked'"/>
                            </xsl:if>-->
                        </input>
                        <span title="Container">Container</span>
                    </label>
                </li>
                <li>
                    <label class="checkbox">
                        <input type="checkbox" name="Type" value="{resolve-uri('ns/default#Item', $ldt:base)}"> <!-- {@rdf:about | @rdf:nodeID} -->
<!--                                    <xsl:if test="$filter/*/@rdf:resource = @rdf:about">
                                <xsl:attribute name="checked" select="'checked'"/>
                            </xsl:if>-->
                        </input>
                        <span title="Item">Item</span>
                    </label>
                </li>
            </ul>
        </div>
    </xsl:template>

    <!-- PAGER -->

    <xsl:template name="bs2:PagerList">
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean?"/>
        <xsl:param name="result-count" as="xs:integer?"/>
        <xsl:param name="show" select="($offset - $limit) &gt;= 0 or $result-count &gt;= $limit" as="xs:boolean"/>

        <!-- do not show pagination if the children document count is less than the page limit -->
        <xsl:if test="$show">
            <ul class="pager">
                <li class="previous">
                    <xsl:choose>
                        <xsl:when test="($offset - $limit) &gt;= 0">
                            <a class="active">
                                <!-- only set hyperlink on server-side - client-side will use event listener to avoid page refresh -->
                                <xsl:variable name="href" select="xs:anyURI(concat($ac:uri, '?limit=', $limit, '&amp;offset=', $offset - $limit, if ($order-by) then concat('&amp;order-by=', $order-by) else (), if ($desc) then concat('&amp;desc=', $desc) else ()))" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:attribute name="href" select="$href" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                
                                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_navigate_before_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class">previous disabled</xsl:attribute>
                            <a>
                                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_navigate_before_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
                            </a>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li class="next">
                    <xsl:choose>
                        <xsl:when test="$result-count &gt;= $limit">
                            <a class="active">
                                <!-- only set hyperlink on server-side - client-side will use event listener to avoid page refresh -->
                                <xsl:variable name="href" select="xs:anyURI(concat($ac:uri, '?limit=', $limit, '&amp;offset=', $offset + $limit, if ($order-by) then concat('&amp;order-by=', $order-by) else (), if ($desc) then concat('&amp;desc=', $desc) else ()))" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:attribute name="href" select="$href" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                
                                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_navigate_next_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class">next disabled</xsl:attribute>
                            <a>
                                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_navigate_next_black_24px.svg', $ac:contextUri)}" alt="{ac:label(.)}"/>
                            </a>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
            </ul>
        </xsl:if>
    </xsl:template>
    
    <!-- BLOCK LIST MODE -->
    
    <xsl:template match="rdf:RDF" mode="bs2:BlockList" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>
        
        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
            
        <xsl:next-match/>
        
        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="*[key('resources', foaf:primaryTopic/@rdf:resource)]" mode="bs2:BlockList" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Actions"/>
            
            <xsl:apply-templates select="." mode="bs2:TypeList"/>
            
            <xsl:apply-templates select="." mode="apl:logo"/>
                        
            <xsl:apply-templates select="." mode="bs2:Timestamp"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="xhtml:Anchor"/>
            
            <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="bs2:Header">
                <xsl:with-param name="class" select="'well well-small'"/>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <xsl:template match="*[key('resources', foaf:isPrimaryTopicOf/@rdf:resource)]" mode="bs2:BlockList" priority="1"/>

    <xsl:template match="*[*][@rdf:local-name = ('about', 'nodeID')]" mode="bs2:BlockList" priority="0.8">
        <xsl:apply-templates select="." mode="bs2:Header"/>
    </xsl:template>
    
    <!-- GRID MODE -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Grid" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>
        
        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
        
        <xsl:next-match/>
        
        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- TABLE MODE -->
    
    <xsl:template match="rdf:RDF" mode="xhtml:Table" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:variable name="result-count" select="count(rdf:Description)" as="xs:integer"/>
        
        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
        
        <xsl:next-match/>
        
        <xsl:call-template name="bs2:PagerList">
            <xsl:with-param name="limit" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit'))"/>
            <xsl:with-param name="offset" select="xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset'))"/>
            <xsl:with-param name="order-by" select="ixsl:get(ixsl:window(), 'LinkedDataHub.order-by')"/>
            <xsl:with-param name="desc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.desc')"/>
            <xsl:with-param name="result-count" select="$result-count"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- GRAPH MODE -->

    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <div id="graph-canvas" style="width: 100%; height: 100%;"/>

        <script type="text/javascript" src="https://d3js.org/d3.v3.min.js"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/http-client/Client.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/http-client/ClientRequest.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/http-client/ClientResponse.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/http-client/WebResource.js', $ac:contextUri)}"></script>
        <script type="text/javascript" src="{resolve-uri('static/com/atomgraph/linkeddatahub/js/GraphMode.js', $ac:contextUri)}"></script>
        
        <script type="text/javascript"><![CDATA[
            new GraphMode("#graph-canvas", 640, 480).load("]]><xsl:value-of select="$ac:uri"/><![CDATA[");
        ]]>
        </script>
    </xsl:template>
    
    <!-- MAP MODE -->

    <!-- TO-DO: improve match pattern -->
    <xsl:template match="rdf:RDF[resolve-uri('geo/', $ldt:base) = $ac:uri]" mode="bs2:Map" priority="1">
        <xsl:next-match>
            <xsl:with-param name="container-uri" select="()"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:Map">
        <div id="map-canvas"></div>
        
        <ixsl:schedule-action wait="0">
            <xsl:call-template name="create-google-map">
                <xsl:with-param name="map" select="ac:create-map('map-canvas', 56, 10, 4)"/>
            </xsl:call-template>
        </ixsl:schedule-action>

        <ixsl:schedule-action wait="0">
            <xsl:call-template name="create-geo-object">
                <!-- use container's SELECT query to build a geo query -->
                <xsl:with-param name="geo" select="ac:create-geo-object($ac:uri, resolve-uri('sparql', $ldt:base), ixsl:get(ixsl:window(), 'LinkedDataHub.select-query'), 'thing')"/>
            </xsl:call-template>
        </ixsl:schedule-action>

        <ixsl:schedule-action wait="0">
            <xsl:call-template name="add-geo-listener"/>
        </ixsl:schedule-action>
    </xsl:template>

    <xsl:function name="ac:create-map">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="lat" as="xs:float"/>
        <xsl:param name="lng" as="xs:float"/>
        <xsl:param name="zoom" as="xs:integer"/>

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.maps.Map(document.getElementById('{$id}'), {{ center: new google.maps.LatLng({$lat}, {$lng}), zoom: {$zoom} }})"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:template name="create-google-map">
        <xsl:param name="map"/>
        
        <ixsl:set-property name="map" select="$map" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>

    <xsl:function name="ac:create-geo-object">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="select-string" as="xs:string"/>
        <xsl:param name="item-var-name" as="xs:string"/>

        <!-- set ?this value -->
        <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <xsl:variable name="js-statement" as="element()">
            <!-- TO-DO: move Geo under AtomGraph namespace -->
            <!-- use template literals because the query is multi-line https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals -->
            <root statement="new SPARQLMap.Geo(window.LinkedDataHub.map, new URL('{$endpoint}'), `{$select-string}`, '{$item-var-name}')"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>

    <xsl:template name="create-geo-object">
        <xsl:param name="geo"/>
        
        <ixsl:set-property name="geo" select="$geo" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
    </xsl:template>
    
    <xsl:template name="add-geo-listener">
        <xsl:variable name="js-statement" as="element()">
            <root statement="window.LinkedDataHub.map.addListener('idle', function() {{ window.LinkedDataHub.geo.loadMarkers(window.LinkedDataHub.geo.addMarkers); }})"/> <!-- use template literal because the query string is multi-line -->
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:template>
    
    <!--
    <xsl:template match="*[geo:lat castable as xs:double][geo:long castable as xs:double]" mode="bs2:Map" priority="1">
        <xsl:param name="nested" as="xs:boolean?"/>

        <script type="text/javascript">
            <![CDATA[
                function initialize]]><xsl:value-of select="generate-id()"/><![CDATA[()
                {
                    var latLng = new google.maps.LatLng(]]><xsl:value-of select="geo:lat[1]"/>, <xsl:value-of select="geo:long[1]"/><![CDATA[);
                    var contentString = ']]><xsl:variable name="info-xhtml"><xsl:call-template name="ac:escape-json">
                                    <xsl:with-param name="string"><xsl:call-template name="xml-to-string">
                                        <xsl:with-param name="node-set">
                                            <xsl:apply-templates select="." mode="bs2:Block"/>
                                        </xsl:with-param>
                                    </xsl:call-template>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:variable>
                    <xsl:value-of disable-output-escaping="yes" select="$info-xhtml"/><![CDATA[';
                    var infowindow = new google.maps.InfoWindow({
                        content: contentString
                    });
                    var marker = new google.maps.Marker({
                        position: latLng,
                        map: map,
                        title: "]]><xsl:apply-templates select="." mode="ac:label"/><![CDATA["]]>
                        <xsl:variable name="color-property" select="key('resources-by-type', '&apl;Map')/apl:colorProperty/@rdf:resource" as="xs:string?"/>
                        <xsl:variable name="color-value" select="*[concat(namespace-uri(), local-name()) = $color-property][1]" as="xs:float?"/>
                        <xsl:variable name="color" select="key('resources-by-type', '&apl;Range')[apl:from &lt;= $color-value][apl:to &gt;= $color-value][1]/apl:color" as="xs:string?"/>
                        <xsl:if test="$color">
                            <![CDATA[,
                                icon: {
                                    path: google.maps.SymbolPath.CIRCLE,
                                    strokeColor: '#]]><xsl:value-of select="$color"/><![CDATA[',
                                    strokeWeight: 10,
                                    scale: 4
                                }
                            ]]>
                        </xsl:if>
                    <![CDATA[
                    });
                    marker.addListener('click', function() {
                      infowindow.open(map, marker);
                    });
                }

                google.maps.event.addDomListener(window, 'load', initialize]]><xsl:value-of select="generate-id()"/><![CDATA[);
            ]]>
        </script>
    </xsl:template>
    -->
    
    <!-- MAP CONTROLS MODE -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="apl:MapControlsMode">
        <xsl:param name="resources" as="element()*" tunnel="yes"/>
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <!-- <xsl:param name="mode" select="$ac:mode" as="xs:anyURI?"/> -->
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>

        <xsl:variable name="range-doc" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="map">
                        <rdf:type rdf:resource="&apl;Map"/>
                        <apl:latProperty rdf:nodeID="latProperty"/>
                        <apl:longProperty rdf:nodeID="longProperty"/>
                        <apl:colorProperty rdf:nodeID="colorProperty"/>
                    </rdf:Description>
                    <xsl:for-each select="1 to 5">
                        <rdf:Description rdf:nodeID="range{position()}">
                            <rdf:type rdf:resource="&apl;Range"/>
                            <apl:from xml:space="preserve"> </apl:from>
                            <apl:to xml:space="preserve"> </apl:to>
                            <apl:color xml:space="preserve"> </apl:color>
                        </rdf:Description>
                    </xsl:for-each>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        
        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
            </xsl:if>
            <!--
            <xsl:if test="$dh:offset">
                <input type="hidden" name="offset" value="{$dh:offset}"/>
            </xsl:if>
            <xsl:if test="$dh:limit">
                <input type="hidden" name="limit" value="{$dh:limit}"/>
            </xsl:if>
            <xsl:if test="$dh:orderBy">
                <input type="hidden" name="orderBy" value="{$dh:orderBy}"/>
            </xsl:if>
            <xsl:if test="$dh:desc">
                <input type="hidden" name="desc" value="{$dh:desc}"/>
            </xsl:if>
            <xsl:if test="$ac:mode">
                <input type="hidden" name="mode" value="{$ac:mode}"/>
            </xsl:if>
            -->

            <input type="hidden" name="rdf"/>
            
            <fieldset class="table">
                <button type="submit" class="pull-right btn btn-primary">Set</button>
                
                <xsl:choose>
                    <xsl:when test="key('resources-by-type', '&apl;Map')">
                        <xsl:apply-templates select="key('resources-by-type', '&apl;Map')" mode="#current"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="key('resources-by-type', '&apl;Map', $range-doc)" mode="#current"/>
                    </xsl:otherwise>
                </xsl:choose>
            </fieldset>
                        
            <fieldset class="table">
                <xsl:variable name="missing-range-count" select="count(key('resources-by-type', '&apl;Range', $range-doc)) - count(key('resources-by-type', '&apl;Range')[apl:from or apl:to or apl:color])" as="xs:integer"/>
                <xsl:apply-templates select="key('resources-by-type', '&apl;Range')" mode="#current">
                    <xsl:sort select="if (apl:from castable as xs:float) then xs:float(apl:from) else ()"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="key('resources-by-type', '&apl;Range', $range-doc)[position() &lt;= $missing-range-count]" mode="#current"/>
            </fieldset>
        </form>
    </xsl:template>
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Map']" mode="apl:MapControlsMode">
        <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current"/>
        <xsl:apply-templates select="rdf:type" mode="#current"/>
            
        <dl class="row">
            <xsl:apply-templates select="apl:latProperty" mode="#current"/>
            <xsl:apply-templates select="apl:longProperty" mode="#current"/>
            <xsl:apply-templates select="apl:colorProperty" mode="#current"/>
        </dl>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Range']" mode="apl:MapControlsMode">
        <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current"/>
        <xsl:apply-templates select="rdf:type" mode="#current"/>

        <dl class="row">
            <xsl:apply-templates select="apl:from" mode="#current"/>
            <xsl:apply-templates select="apl:to" mode="#current"/>
            <xsl:apply-templates select="apl:color" mode="#current"/>
        </dl>
    </xsl:template>

    <xsl:template match="rdf:type" mode="apl:MapControlsMode">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="apl:colorProperty" mode="ac:property-label">Color</xsl:template>
    <xsl:template match="apl:latProperty" mode="ac:property-label">Latitude</xsl:template>
    <xsl:template match="apl:longProperty" mode="ac:property-label">Longitude</xsl:template>

    <xsl:template match="apl:colorProperty | apl:latProperty | apl:longProperty" mode="apl:MapControlsMode">
        <xsl:param name="this" select="concat(namespace-uri(), local-name())"/>
        <xsl:param name="resources" as="element()*" tunnel="yes"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <xsl:variable name="current" select="."/>

        <input type="hidden" name="pu" value="{$this}"/>
        <dt class="cell">
            <label for="{$for}">
                <xsl:apply-templates select="." mode="ac:property-label"/>
            </label>
        </dt>
        <dd class="cell">
            <select id="{$for}" name="ou" class="input-small">
                <xsl:for-each-group select="key('resources', $resources/foaf:primaryTopic/(@rdf:resource,@rdf:nodeID), root($resources[1]))/*[. castable as xs:float]" group-by="concat(namespace-uri(), local-name())">
                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}"/>
                    <option value="{current-grouping-key()}">
                        <xsl:if test="$current/@rdf:resource = current-grouping-key()">
                            <xsl:attribute name="selected">selected</xsl:attribute>
                        </xsl:if>

                        <xsl:apply-templates select="current-group()[1]" mode="ac:property-label">
                            <xsl:sort select="ac:object-label(@rdf:resource)" order="ascending"/>
                        </xsl:apply-templates>
                    </option>
                </xsl:for-each-group>
            </select>
        </dd>
    </xsl:template>

    <xsl:template match="apl:from" mode="ac:property-label">From</xsl:template>
    <xsl:template match="apl:to" mode="ac:property-label">To</xsl:template>
    <xsl:template match="apl:color" mode="ac:property-label">Color</xsl:template>

    <xsl:template match="apl:from | apl:to | apl:color" mode="apl:MapControlsMode">
        <xsl:param name="this" select="concat(namespace-uri(), local-name())"/>
        <xsl:param name="resources" as="element()*" tunnel="yes"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <xsl:variable name="current" select="."/>

        <input type="hidden" name="pu" value="{$this}"/>
        <dt class="cell">
            <label for="{$for}">
                <xsl:apply-templates select="." mode="ac:property-label"/>
            </label>
        </dt>
        <dd class="cell">
            <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"/>
        </dd>
    </xsl:template>

    <xsl:template match="@rdf:resource | @rdf:nodeID" mode="apl:MapControlsMode">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="type-label" select="false()"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="text()" mode="apl:MapControlsMode">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="class" select="'input-small'" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="type-label" select="false()"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="apl:color/text()" mode="apl:MapControlsMode" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="class" select="'input-small'" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="type-label" select="false()"/>
        </xsl:apply-templates>

        <xsl:text> </xsl:text>
        <span style="background-color: #{.};">&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</span>
    </xsl:template>

    <!-- CHART MODE -->

    <xsl:template match="rdf:RDF" mode="bs2:Chart" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:variable name="results" select="ixsl:get(ixsl:window(), 'LinkedDataHub.results')" as="document-node()"/>
        
        <xsl:apply-templates select="$results" mode="bs2:ChartForm"/>

        <div id="chart-canvas"/>
    </xsl:template>
    
    <!-- graph chart (for RDF/XML results) -->
    
    <xsl:template match="rdf:RDF" mode="bs2:ChartForm" use-when="system-property('xsl:product-name') = 'Saxon-CE'" priority="-1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="resolve-uri('ns#ChartItem', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="type" select="resolve-uri('ns/default#GraphChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="action" select="resolve-uri(concat('charts/?forClass=', encode-for-uri(resolve-uri($type, $ldt:base))), $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="chart-type" select="xs:anyURI(ac:query-param('chart-type'))" as="xs:anyURI?"/>
        <xsl:param name="category" select="ac:query-param('category')" as="xs:string?"/>
        <xsl:param name="series" select="ac:query-param('series')" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <!-- <xsl:param name="mode" as="xs:anyURI*"/> -->
        <xsl:param name="endpoint" select="xs:anyURI(ac:query-param('endpoint'))" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>

        <xsl:if test="$show-controls">
            <form method="{$method}" action="{$action}">
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$accept-charset">
                    <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$enctype">
                    <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
                </xsl:if>

                <fieldset>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'sb'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'chart'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&rdf;type'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="$type"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&spin;query'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-uri')"/> <!-- SELECT URI -->
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ob'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'this'"/>
                    </xsl:call-template>

                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&apl;endpoint'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="resolve-uri('sparql', $ldt:base)"/>
                    </xsl:call-template>

<!--                    <div class="row-fluid">
                        <div class="span12">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;endpoint'"/>
                            </xsl:call-template>
                    
                            <label for="endpoint-uri">Endpoint</label>
                            <xsl:text> </xsl:text>
                                <select id="endpoint-uri" name="ou" class="input-xxlarge">
                                    <option value="{resolve-uri('sparql', $ldt:base)}">[SPARQL endpoint]</option>
                                    
                                    <xsl:for-each select="document(resolve-uri('services/', $ldt:base))//*[sd:endpoint/@rdf:resource]" use-when="system-property('xsl:product-name') = 'SAXON'">
                                        <xsl:sort select="ac:label(.)"/>
                                        
                                        <xsl:apply-templates select="." mode="xhtml:Option">
                                            <xsl:with-param name="value" select="sd:endpoint/@rdf:resource"/>
                                            <xsl:with-param name="selected" select="sd:endpoint/@rdf:resource = $endpoint"/>
                                        </xsl:apply-templates>
                                    </xsl:for-each>
                                    <xsl:if test="true()"  use-when="system-property('xsl:product-name') = 'Saxon-CE'">
                                        <xsl:variable name="query" select="'DESCRIBE ?service { GRAPH ?g { ?service &lt;&sd;endpoint&gt; ?endpoint } }'"/>
                                        <xsl:message>
                                            <xsl:sequence select="ac:fetch(resolve-uri(concat('sparql?query=', encode-for-uri($query)), $ldt:base), 'application/rdf+xml', 'onchartModeServiceLoad')"/>
                                        </xsl:message> 
                                    </xsl:if>
                            </select>
                        </div>
                    </div>-->
                    <div class="row-fluid">
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;chartType'"/>
                            </xsl:call-template>
                
                            <label for="{$chart-type-id}">
                                <xsl:apply-templates select="key('resources', '&apl;chartType', document('&apl;'))" mode="ac:label" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:value-of use-when="system-property('xsl:product-name') = 'Saxon-CE'">Chart type</xsl:value-of>
                            </label>
                            <br/>
                            <select id="{$chart-type-id}" name="ou" class="input-medium">
                                <option value="&ac;Table">
                                    <xsl:if test="$chart-type = '&ac;Table'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Table</xsl:text>
                                </option>
                                <option value="&ac;ScatterChart">
                                    <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Scatter chart</xsl:text>
                                </option>
                                <option value="&ac;LineChart">
                                    <xsl:if test="$chart-type = '&ac;LineChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Line chart</xsl:text>
                                </option>
                                <option value="&ac;BarChart">
                                    <xsl:if test="$chart-type = '&ac;BarChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Bar chart</xsl:text>
                                </option>
                                <option value="&ac;Timeline">
                                    <xsl:if test="$chart-type = '&ac;Timeline'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Timeline</xsl:text>
                                </option>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;categoryProperty'"/>
                            </xsl:call-template>
                            
                            <label for="{$category-id}">Category</label>
                            <br/>
                            <select id="{$category-id}" name="ou" class="input-large">
                                <option value="">
                                    <xsl:text>[URI/ID]</xsl:text> <!-- URI is the default category -->
                                </option>

                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') = 'Saxon-CE'"/>

                                    <option value="{current-grouping-key()}">
                                        <xsl:if test="$category = current-grouping-key()">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>
                                        
                                        <xsl:apply-templates select="current-group()[1]" mode="ac:property-label">
                                            <xsl:sort select="ac:object-label(@rdf:resource)" order="ascending"/>
                                        </xsl:apply-templates>
                                    </option>
                                </xsl:for-each-group>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;seriesProperty'"/>
                            </xsl:call-template>
                            
                            <label for="{$series-id}">Series</label>
                            <br/>
                            <select id="{$series-id}" name="ou" multiple="multiple" class="input-large">
                                <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                                    <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                    <xsl:sort select="ac:property-label(.)" order="ascending" use-when="system-property('xsl:product-name') = 'Saxon-CE'"/>

                                    <option value="{current-grouping-key()}">
                                        <xsl:if test="$series = current-grouping-key()">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>
                                        
                                        <xsl:apply-templates select="current-group()[1]" mode="ac:property-label">
                                            <xsl:sort select="ac:object-label(@rdf:resource)" order="ascending"/>
                                        </xsl:apply-templates>
                                    </option>
                                </xsl:for-each-group>
                            </select>
                        </div>
                    </div>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&dct;title'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="id" select="'chart-title'"/>
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ob'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'this'"/>
                    </xsl:call-template>

                    <!-- ChartItem -->

                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'sb'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'this'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&dct;title'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="id" select="'chart-doc-title'"/>
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&rdf;type'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="$doc-type"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ob'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'chart'"/>
                    </xsl:call-template>
                </fieldset>
                <div class="form-actions">
                    <button class="btn btn-primary btn-save-chart" type="submit">
                        <!-- <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                            <xsl:with-param name="filename" select="'ic_note_add_white_24px.svg'"/>
                        </xsl:apply-templates> -->

                        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_save_white_24px.svg', $ac:contextUri)}" alt="Save"/>
                        <xsl:text> Save</xsl:text> <!-- to do: use query class in apl:logo mode -->
                    </button>
                </div>
            </form>
        </xsl:if>
    </xsl:template>

    <!-- table chart (for SPARQL XML results) -->
    
    <xsl:template match="srx:sparql" mode="bs2:ChartForm" use-when="system-property('xsl:product-name') = 'Saxon-CE'">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="doc-type" select="resolve-uri('ns#ChartItem', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="type" select="resolve-uri('ns/default#ResultSetChart', $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="action" select="resolve-uri(concat('charts/?forClass=', encode-for-uri(resolve-uri($type, $ldt:base))), $ldt:base)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'form-inline'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="chart-type" select="xs:anyURI(ac:query-param('chart-type'))" as="xs:anyURI?"/>
        <xsl:param name="category" select="ac:query-param('category')" as="xs:string?"/>
        <xsl:param name="series" select="ac:query-param('series')" as="xs:string*"/>
        <xsl:param name="chart-type-id" select="'chart-type'" as="xs:string"/>
        <xsl:param name="category-id" select="'category'" as="xs:string"/>
        <xsl:param name="series-id" select="'series'" as="xs:string"/>
        <xsl:param name="width" as="xs:string?"/>
        <xsl:param name="height" select="'480'" as="xs:string?"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="endpoint" select="xs:anyURI(ac:query-param('endpoint'))" as="xs:anyURI?"/>
        <xsl:param name="query" as="xs:string?"/>
        <xsl:param name="show-controls" select="true()" as="xs:boolean"/>

        <xsl:if test="$show-controls">
            <form method="{$method}" action="{$action}">
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$accept-charset">
                    <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$enctype">
                    <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
                </xsl:if>

                <fieldset>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'sb'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'chart'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&rdf;type'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="$type"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&spin;query'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-uri')"/> <!-- SELECT URI -->
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ob'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'this'"/>
                    </xsl:call-template>

                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&apl;endpoint'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="resolve-uri('sparql', $ldt:base)"/>
                    </xsl:call-template>
                    
<!--                    <div class="row-fluid">
                        <div class="span12">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;endpoint'"/>
                            </xsl:call-template>
                    
                            <label for="endpoint-uri">Endpoint</label>
                            <xsl:text> </xsl:text>
                                <select id="endpoint-uri" name="ou" class="input-xxlarge">
                                    <option value="{resolve-uri('sparql', $ldt:base)}">[SPARQL endpoint]</option>
                                    
                                    <xsl:for-each select="document(resolve-uri('services/', $ldt:base))//*[sd:endpoint/@rdf:resource]" use-when="system-property('xsl:product-name') = 'SAXON'">
                                        <xsl:sort select="ac:label(.)"/>
                                        
                                        <xsl:apply-templates select="." mode="xhtml:Option">
                                            <xsl:with-param name="value" select="sd:endpoint/@rdf:resource"/>
                                            <xsl:with-param name="selected" select="sd:endpoint/@rdf:resource = $endpoint"/>
                                        </xsl:apply-templates>
                                    </xsl:for-each>
                                    <xsl:if test="true()"  use-when="system-property('xsl:product-name') = 'Saxon-CE'">
                                        <xsl:variable name="query" select="'DESCRIBE ?service { GRAPH ?g { ?service &lt;&sd;endpoint&gt; ?endpoint } }'"/>
                                        <xsl:message>
                                            <xsl:sequence select="ac:fetch(resolve-uri(concat('sparql?query=', encode-for-uri($query)), $ldt:base), 'application/rdf+xml', 'onchartModeServiceLoad')"/>
                                        </xsl:message> 
                                    </xsl:if>
                            </select>
                        </div>
                    </div>-->
                    <div class="row-fluid">
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;chartType'"/>
                            </xsl:call-template>
                
                            <label for="{$chart-type-id}">
                                <xsl:apply-templates select="key('resources', '&apl;chartType', document('&apl;'))" mode="ac:label" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:value-of use-when="system-property('xsl:product-name') = 'Saxon-CE'">Chart type</xsl:value-of>
                            </label>
                            <br/>
                            <select id="{$chart-type-id}" name="ou" class="input-medium">
                                <option value="&ac;Table">
                                    <xsl:if test="$chart-type = '&ac;Table'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Table</xsl:text>
                                </option>
                                <option value="&ac;ScatterChart">
                                    <xsl:if test="$chart-type = '&ac;ScatterChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Scatter chart</xsl:text>
                                </option>
                                <option value="&ac;LineChart">
                                    <xsl:if test="$chart-type = '&ac;LineChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Line chart</xsl:text>
                                </option>
                                <option value="&ac;BarChart">
                                    <xsl:if test="$chart-type = '&ac;BarChart'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Bar chart</xsl:text>
                                </option>
                                <option value="&ac;Timeline">
                                    <xsl:if test="$chart-type = '&ac;Timeline'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    
                                    <xsl:text>Timeline</xsl:text>
                                </option>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;categoryVarName'"/>
                            </xsl:call-template>
                            
                            <label for="{$category-id}">Category</label>
                            <br/>
                            <select id="{$category-id}" name="ol" class="input-large">
                                <xsl:for-each select="srx:head/srx:variable">
                                    <!-- leave the original variable order so it can be controlled from query -->

                                    <option value="{@name}">
                                        <xsl:if test="$category = @name">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:value-of select="@name"/>
                                    </option>
                                </xsl:for-each>
                            </select>
                        </div>
                        <div class="span4">
                            <xsl:call-template name="xhtml:Input">
                                <xsl:with-param name="name" select="'pu'"/>
                                <xsl:with-param name="type" select="'hidden'"/>
                                <xsl:with-param name="value" select="'&apl;seriesVarName'"/>
                            </xsl:call-template>
                                
                            <label for="{$series-id}">Series</label>
                            <br/>
                            <select id="{$series-id}" name="ol" multiple="multiple" class="input-large">
                                <xsl:for-each select="srx:head/srx:variable">
                                    <!-- leave the original variable order so it can be controlled from query -->

                                    <option value="{@name}">
                                        <xsl:if test="$series = @name">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                        </xsl:if>

                                        <xsl:value-of select="@name"/>
                                    </option>
                                </xsl:for-each>
                            </select>
                        </div>
                    </div>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&dct;title'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="id" select="'chart-title'"/>
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&foaf;isPrimaryTopicOf'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ob'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'this'"/>
                    </xsl:call-template>

                    <!-- ChartItem -->

                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'sb'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'this'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&dct;title'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="id" select="'chart-doc-title'"/>
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&rdf;type'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ou'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="$doc-type"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'pu'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
                    </xsl:call-template>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ob'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="value" select="'chart'"/>
                    </xsl:call-template>
                </fieldset>
                <div class="form-actions">
                    <button class="btn btn-primary btn-save-chart" type="submit">
                        <!-- <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                            <xsl:with-param name="filename" select="'ic_note_add_white_24px.svg'"/>
                        </xsl:apply-templates> -->

                        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/ic_save_white_24px.svg', $ac:contextUri)}" alt="Save"/>
                        <xsl:text> Save</xsl:text> <!-- to do: use query class in apl:logo mode -->
                    </button>
                </div>
            </form>
        </xsl:if>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->
    
    <!-- filter onchange -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'faceted-nav']//input[@type = 'checkbox']" mode="ixsl:onchange">
        <xsl:variable name="values" select="ancestor::ul//input[@name = 'Type'][@prop:checked = true()]/@prop:value" as="xs:string*"/>
        <xsl:choose>
            <!-- apply FILTER if any values were selected -->
            <xsl:when test="count($values) &gt; 0">
                <!-- build an array of SPARQL.js URIs from string values -->
                <xsl:variable name="value-uris" select="ixsl:call(ixsl:get(ixsl:window(), 'Array'), 'of')"/>
                <xsl:for-each select="$values">
                    <xsl:message>
                        <xsl:value-of select="ixsl:call($value-uris, 'push', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'uri', current()))"/>
                    </xsl:message>
                </xsl:for-each>
                <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
                <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', $select-string)"/>
                <!-- pseudo JS code: SPARQLBuilder.SelectBuilder.fromString($select-builder).where(SPARQLBuilder.QueryBuilder.filter(SPARQLBuilder.QueryBuilder.in(QueryBuilder.var("Type"), [ $value ]))) -->
                <xsl:variable name="select-builder" select="ixsl:call($select-builder, 'where', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'filter', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'in', ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'var', 'Type'), $value-uris)))"/>
                <xsl:variable name="select-string" select="ixsl:call($select-builder, 'toString')" as="xs:string"/>
                 <!-- set ?this variable value -->
                <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $ac:uri, '&gt;'))" as="xs:string"/>
                <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
                <xsl:variable name="describe-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset')), ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
                <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/>
                <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>

                <ixsl:set-property name="describe-query" select="$describe-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                
                <xsl:message>
                    <xsl:sequence select="ac:fetch($results-uri, 'application/rdf+xml', 'onContainerResultsLoad')"/>
                </xsl:message>
            </xsl:when>
            <!-- if not, execute original query -->
            <xsl:otherwise>
                <xsl:variable name="select-string" select="ixsl:get(ixsl:window(), 'LinkedDataHub.select-query')" as="xs:string"/>
                 <!-- set ?this variable value -->
                <xsl:variable name="select-string" select="replace($select-string, '\?this', concat('&lt;', $ac:uri, '&gt;'))" as="xs:string"/>
                <!-- wrap SELECT into DESCRIBE and set pagination modifiers -->
                <xsl:variable name="describe-string" select="ac:build-describe($select-string, xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.limit')), xs:integer(ixsl:get(ixsl:window(), 'LinkedDataHub.offset')), ixsl:get(ixsl:window(), 'LinkedDataHub.order-by'), ixsl:get(ixsl:window(), 'LinkedDataHub.desc'))" as="xs:string"/>
                <xsl:variable name="endpoint" select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))" as="xs:anyURI"/>
                <xsl:variable name="results-uri" select="xs:anyURI(concat($endpoint, '?query=', encode-for-uri($describe-string)))" as="xs:anyURI"/>

                <ixsl:set-property name="describe-query" select="$describe-string" object="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                
                <xsl:message>
                    <xsl:sequence select="ac:fetch($results-uri, 'application/rdf+xml', 'onContainerResultsLoad')"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>