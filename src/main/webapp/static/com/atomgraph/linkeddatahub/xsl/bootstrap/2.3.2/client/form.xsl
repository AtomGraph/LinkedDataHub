<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def        "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh        "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY typeahead  "http://graphity.org/typeahead#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs       "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd        "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl        "http://www.w3.org/2002/07/owl#">
    <!ENTITY ldt        "https://www.w3.org/ns/ldt#">
    <!ENTITY dh         "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY cert       "http://www.w3.org/ns/auth/cert#">
    <!ENTITY sd         "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sh         "http://www.w3.org/ns/shacl#">
    <!ENTITY sioc       "http://rdfs.org/sioc/ns#">
    <!ENTITY sp         "http://spinrdf.org/sp#">
    <!ENTITY spin       "http://spinrdf.org/spin#">
    <!ENTITY dct        "http://purl.org/dc/terms/">
    <!ENTITY foaf       "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:dct="&dct;"
xmlns:typeahead="&typeahead;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sh="&sh;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:param name="select-labelled-class-or-shape-string" as="xs:string">
<![CDATA[
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  sh:   <http://www.w3.org/ns/shacl#>
PREFIX  spin: <http://spinrdf.org/spin#>

SELECT  ?classOrShape
WHERE
  {   { ?classOrShape (rdfs:subClassOf)*/spin:constructor ?constructor
        FILTER ( ! strstarts(str(?classOrShape), "http://spinrdf.org/spin#") )
      }
    UNION
      { ?classOrShape
                  a  sh:NodeShape
      }
    ?classOrShape
              rdfs:label  ?label
    FILTER isURI(?classOrShape)
  }
]]>
    </xsl:param>

    <xsl:key name="violations-by-value" match="*" use="ldh:violationValue/text()"/>
    <xsl:key name="violations-by-focus-node" match="*" use="sh:focusNode/@rdf:resource | sh:focusNode/@rdf:nodeID"/>

    <!-- TEMPLATES -->

    <!-- provide a property label which otherwise would default to local-name() client-side -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content']/rdfs:label | *[rdf:type/@rdf:resource = '&ldh;Content']/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>

    <!-- make sure content value input is shown as required -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content']/rdf:value" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
            <xsl:with-param name="required" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- hide content type input (template borrowed from rdf.xsl which is not included client-side) -->
    <xsl:template match="rdf:type[@rdf:resource = '&ldh;Content']" mode="bs2:TypeControl">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*" mode="ldh:PostConstruct">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="ldh:PostConstruct"/>

    <!-- subject type change -->
    <xsl:template match="select[contains-token(@class, 'subject-type')]" mode="ldh:PostConstruct" priority="1">
        <xsl:sequence select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onSubjectTypeChange') ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <xsl:template match="textarea[contains-token(@class, 'wymeditor')]" mode="ldh:PostConstruct" priority="1">
        <!-- call .wymeditor() on textarea to show WYMEditor -->
        <xsl:sequence select="ixsl:call(ixsl:call(ixsl:window(), 'jQuery', [ . ]), 'wymeditor', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="wymeditor" select="ixsl:call(ixsl:get(ixsl:window(), 'jQuery'), 'getWymeditorByTextarea', [ . ])" as="item()"/>
        <xsl:variable name="char-count" select="sum(.//text()/string-length())" as="xs:integer"/>
        <xsl:variable name="iframe" select="ixsl:get($wymeditor, '_iframe')" as="element()"/>
        
        <!-- attempt to infer WYMEditor height from the length of textarea's content (though min 30em and max 100em) -->
        <xsl:for-each select="$iframe">
            <xsl:variable name="height-in-em" select="$char-count idiv 16" as="xs:integer"/>
            <xsl:variable name="height-in-em" select="if ($height-in-em &lt; 30) then 30 else if ($height-in-em &gt; 100) then 100 else $height-in-em" as="xs:integer"/>
            <ixsl:set-style name="height" select="string($height-in-em) || 'em'" object="."/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="textarea[@id][contains-token(@class, 'sparql-query-string')]" mode="ldh:PostConstruct" priority="1">
        <xsl:variable name="textarea-id" select="ixsl:get(., 'id')" as="xs:string"/>
        <!-- initialize YASQE SPARQL editor on the textarea -->
        <xsl:variable name="js-statement" as="element()">
            <root statement="YASQE.fromTextArea(document.getElementById('{$textarea-id}'), {{ persistent: null }})"/>
        </xsl:variable>
        <ixsl:set-property name="{$textarea-id}" select="ixsl:eval(string($js-statement/@statement))" object="ixsl:get(ixsl:window(), 'LinkedDataHub.yasqe')"/>
    </xsl:template>
    
    <!-- TO-DO: phase out as regular ixsl: event templates -->
    <xsl:template match="fieldset//input" mode="ldh:PostConstruct" priority="1">
        <!-- subject value change -->
        <xsl:if test="contains-token(@class, 'subject')">
            <xsl:sequence select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onSubjectValueChange') ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        
        <!-- TO-DO: move to a better place. Does not take effect if typeahead is reset -->
        <ixsl:set-property object="." name="autocomplete" select="'off'"/>
    </xsl:template>
    
    <!-- inject datetime-local inputs (only if the input is visible) TO-DO: align structure of constructor and editing form controls -->
    <xsl:template match="input[not(@type = 'hidden')][@name = 'ol'][following-sibling::input[@name = 'lt'][@value = '&xsd;dateTime']] | input[@name = 'ol'][@value][../following-sibling::div/input[@name = 'lt'][@value = '&xsd;dateTime']]" mode="ldh:PostConstruct" priority="2">
        <ixsl:set-attribute name="type" select="'datetime-local'"/>
        <ixsl:set-attribute name="step" select="'1'"/>

        <xsl:if test="@value">
            <!-- adjust the datetime value to the implicit (user's) timezone and format it to make it a legal datetime-local value: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/datetime-local#value -->
            <xsl:variable name="datetime-local" select="format-dateTime(adjust-dateTime-to-timezone(xs:dateTime(@value)), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')" as="xs:string"/>        
            <ixsl:set-attribute name="value" select="$datetime-local"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="ldh:FormPreSubmit">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="ldh:FormPreSubmit"/>
    
    <!-- trim whitespace in bnode/URI values -->
    <xsl:template match="input[@name = ('ob', 'ou')][ixsl:get(., 'value')]" mode="ldh:FormPreSubmit" priority="1">
        <ixsl:set-attribute name="value" select="normalize-space(ixsl:get(., 'value'))"/>
    </xsl:template>
    
    <!-- remove names of RDF/POST inputs with empty values -->
    <xsl:template match="input[@name = ('ob', 'ou', 'ol')][not(ixsl:get(., 'value'))]" mode="ldh:FormPreSubmit" priority="2">
        <ixsl:remove-attribute name="name"/>
    </xsl:template>
    
    <!-- adjust datetime-local values to the implicit timezone -->
    <xsl:template match="input[@type = 'datetime-local'][ixsl:get(., 'value')]" mode="ldh:FormPreSubmit" priority="1">
        <!-- set the input type back to 'text' because 'datetime-local' does not accept the timezoned value -->
        <ixsl:set-attribute name="type" select="'text'"/>
        <ixsl:set-property name="value" select="string(adjust-dateTime-to-timezone(ixsl:get(., 'value')))" object="."/>
    </xsl:template>
    
    <xsl:template name="bs2:SignUpComplete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="created-uri" select="?headers?location" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:for-each select="id('content-body', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="row-fluid">
                    <div class="main offset2 span7">
                        <div class="alert alert-success row-fluid">
                            <div class="span1">
                                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/baseline_done_white_48dp.png', $ac:contextUri)}" alt="Signup complete"/>
                            </div>
                            <div class="span11">
                                <p>Congratulations! Your WebID profile has been created. You can see its data below.</p>
                                <p>
                                    <strong>Authentication details have been sent to your email address.</strong>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- proxy $created-uri to make sure we get RDF/XML. TO-DO: load asynchronously? -->
                <xsl:variable name="request-uri" select="ac:build-uri($created-uri, map{ 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:for-each select="document($request-uri)">
                    <xsl:apply-templates select="key('resources-by-type', '&foaf;Person')[@rdf:about]" mode="bs2:Row"/>
                </xsl:for-each>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="bs2:AccessRequestComplete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="created-uri" select="?headers?location" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:for-each select="id('content-body', ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="row-fluid">
                    <div class="offset2 span7">
                        <div class="alert alert-success row-fluid ">
                            <div class="span1">
                                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/baseline_done_white_48dp.png', $ac:contextUri)}" alt="Request created"/>
                            </div>
                            <div class="span11">
                                <p>Your access request has been created.</p>
                                <p>You will be notified when the administrator approves or rejects it.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
    <!-- enable inline editing form (do nothing if the button is disabled) -->
    
    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="about" select="$container/@about" as="xs:anyURI"/>
        <xsl:variable name="graph" as="xs:anyURI?"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:message>ixsl:get(., 'baseURI'): <xsl:value-of select="ixsl:get(., 'baseURI')"/></xsl:message>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
        <xsl:message>ixsl:location(): <xsl:value-of select="ixsl:location()"/></xsl:message>
        
        <xsl:if test="ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`')">
            <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>
            <xsl:message>ldh:LoadEditedDocument $etag: <xsl:value-of select="$etag"/></xsl:message>
        </xsl:if>
        
        <!-- if the URI is external, dereference it through the proxy -->
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:absolute-path(ldh:base-uri(.)), $graph, ())" as="xs:anyURI"/>
        
        <xsl:variable name="request" as="item()*">
            <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile --> 
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="ldh:LoadEditedDocument">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="about" select="$about"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template name="ldh:LoadEditedDocument">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="about" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="etag" select="?headers?etag" as="xs:string?"/>
                <xsl:message>ETag: <xsl:value-of select="$etag"/></xsl:message>
                
                <xsl:for-each select="?body">
                    <ixsl:set-property name="{'`' || ac:absolute-path(ldh:base-uri(.)) || '`'}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                    <!-- store document under window.LinkedDataHub.contents[$content-uri].results -->
                    <ixsl:set-property name="results" select="." object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`')"/>
                    <!-- store ETag header value under window.LinkedDataHub.contents[$content-uri].etag -->
                    <ixsl:set-property name="etag" select="$etag" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`')"/>

                    <xsl:variable name="resource" select="key('resources', $about)" as="element()"/> <!-- TO-DO: handle error -->
                    <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
                    <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                    <xsl:variable name="request" as="item()*">
                        <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile --> 
                        <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                            <xsl:call-template name="ldh:LoadTypeMetadata">
                                <xsl:with-param name="container" select="$container"/>
                                <xsl:with-param name="resource" select="$resource"/>
                                <xsl:with-param name="types" select="$types"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <!-- error response -->
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ldh:LoadTypeMetadata">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="types" as="xs:anyURI*"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="type-metadata" select="?body" as="document-node()?"/>

                <!-- TO-DO: refactor to use asynchronous HTTP requests -->
                <xsl:variable name="property-uris" select="distinct-values($resource/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:variable name="property-metadata" select="document($request-uri)" as="document-node()"/>

                <xsl:variable name="query-string" select="$constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
                <xsl:variable name="constraints" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>
                
                <xsl:for-each select="$container">
                    <xsl:variable name="row" as="node()*">
                        <xsl:apply-templates select="$resource" mode="bs2:RowForm">
                            <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                            <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:copy-of select="$row/*"/> <!-- inject the content of div.row-fluid -->
                    </xsl:result-document>
                </xsl:for-each>

                <!-- initialize event listeners -->
                <xsl:apply-templates select="$container/*" mode="ldh:PostConstruct"/>

                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <!-- error response -->
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- disable inline editing form (do nothing if the button is disabled) -->
    
    <xsl:template match="div[@about][@typeof = ('&ldh;ResultSetChart', '&ldh;GraphChart')]//button[contains-token(@class, 'btn-cancel')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick" priority="1">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="content-uri" select="xs:anyURI($container/@about)" as="xs:anyURI"/>
        <xsl:variable name="content-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:variable name="about" select="$container/@about" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:message>ixsl:get(., 'baseURI'): <xsl:value-of select="ixsl:get(., 'baseURI')"/></xsl:message>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
        <xsl:message>ixsl:location(): <xsl:value-of select="ixsl:location()"/></xsl:message>

        <!-- not using ldh:base-uri(.) because it goes stale when DOM is replaced -->
        <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(xs:anyURI(ixsl:location())) || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="chart" select="key('resources', $about, $doc)" as="element()"/>

        <xsl:apply-templates select="$chart" mode="ldh:RenderContent">
            <xsl:with-param name="this" select="ancestor::div[@about][1]/@about"/>
            <xsl:with-param name="container" select="$container"/>
        </xsl:apply-templates>
        
        <!-- initialize event listeners -->
        <xsl:apply-templates select="$container/*" mode="ldh:PostConstruct"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- TO-DO: unify -->
    <xsl:template match="div[@about][@typeof]//button[contains-token(@class, 'btn-cancel')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="about" select="$container/@about" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:message>ixsl:get(., 'baseURI'): <xsl:value-of select="ixsl:get(., 'baseURI')"/></xsl:message>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
        <xsl:message>ixsl:location(): <xsl:value-of select="ixsl:location()"/></xsl:message>

        <!-- not using ldh:base-uri(.) because it goes stale when DOM is replaced -->
        <xsl:variable name="doc" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(xs:anyURI(ixsl:location())) || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="resource" select="key('resources', $about, $doc)" as="element()"/>

        <xsl:variable name="row" as="node()*">
            <xsl:apply-templates select="$resource" mode="bs2:Row"/>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$row/*"/> <!-- inject the content of div.row-fluid -->
            </xsl:result-document>
        </xsl:for-each>
        <!-- initialize event listeners -->
        <xsl:apply-templates select="$container/*" mode="ldh:PostConstruct"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- submit document creation form using PUT -->
    
    <xsl:template match="div[contains-token(@class, 'modal-constructor')]//form[contains-token(@class, 'form-horizontal')]" mode="ixsl:onsubmit" priority="1">
        <xsl:next-match>
            <xsl:with-param name="method" select="'put'"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- submit instance creation form using POST -->
    
    <xsl:template match="form[contains-token(@class, 'form-horizontal')]" mode="ixsl:onsubmit">
        <xsl:param name="method" select="ixsl:get(., 'method')" as="xs:string"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()?"/> <!-- no container means the form was modal -->
        <xsl:variable name="form" select="." as="element()"/>
        <xsl:variable name="id" select="ixsl:get($form, 'id')" as="xs:string"/>
        <xsl:variable name="action" select="ixsl:get($form, 'action')" as="xs:anyURI"/>
        <xsl:variable name="enctype" select="ixsl:get($form, 'enctype')" as="xs:string"/>
        <xsl:variable name="accept" select="'application/rdf+xml'" as="xs:string"/>
        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>
        <xsl:message>$etag: <xsl:value-of select="$etag"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:message>
            <xsl:for-each select="$elements">
                @name: <xsl:value-of select="@name"/> ixsl:get(., 'value'): <xsl:value-of select="if (ixsl:contains(., 'value')) then ixsl:get(., 'value') else 'None'"/> ixsl:get(., 'value') = '': <xsl:value-of select="ixsl:get(., 'value') = ''"/>
            </xsl:for-each>
        </xsl:message>
        <xsl:variable name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <xsl:variable name="resources" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:sequence select="ldh:triples-to-descriptions($triples)"/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $action)" as="xs:anyURI"/>

        <xsl:message>form.form-horizontal ixsl:onsubmit</xsl:message>
        <xsl:message>$triples: <xsl:value-of select="serialize($triples)"/></xsl:message>
        <xsl:message>RDF/XML: <xsl:value-of select="serialize($resources)"/></xsl:message>
        
        <!-- pre-process form before submitting it -->
        <!-- <xsl:apply-templates select="." mode="ldh:FormPreSubmit"/> -->
            
        <xsl:choose>
            <!-- we need to handle multipart requests specially because of Saxon-JS 2 limitations: https://saxonica.plan.io/issues/4732 -->
            <xsl:when test="$enctype = 'multipart/form-data'">
                <xsl:variable name="form-data" select="ldh:new('FormData', [ $form ])"/>
                <xsl:variable name="headers" select="ldh:new-object()"/>
                <ixsl:set-property name="Accept" select="$accept" object="$headers"/>
                <ixsl:set-property name="If-Match" select="$etag" object="$headers"/>
                
                <!-- TO-DO: refactor fetchDispatchXML using IXSL -->
                <xsl:sequence select="js:fetchDispatchXML($request-uri, $method, $headers, $form-data, ., $doc-uri, $resources, $container, 'MultipartResourceUpdated')[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="request" as="item()*">
                    <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile --> 
                    <ixsl:schedule-action http-request="map{ 'method': $method, 'href': $request-uri, 'media-type': 'application/rdf+xml', 'body': $resources, 'headers': map{ 'If-Match': $etag, 'Accept': $accept } }">
                        <xsl:call-template name="ldh:ResourceUpdated">
                            <xsl:with-param name="doc-uri" select="$doc-uri"/>
                            <xsl:with-param name="container" select="$container"/>
                            <xsl:with-param name="form" select="$form"/>
                            <xsl:with-param name="resources" select="$resources"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- submit instance update form using PATCH -->
    
    <xsl:template match="div[@about][contains-token(@class, 'row-fluid')][@typeof]//form[contains-token(@class, 'form-horizontal')][upper-case(@method) = 'PATCH']" mode="ixsl:onsubmit" priority="1">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()?"/>
        <xsl:variable name="form" select="." as="element()"/>
        <xsl:variable name="id" select="ixsl:get($form, 'id')" as="xs:string"/>
        <xsl:variable name="action" select="ixsl:get($form, 'action')" as="xs:anyURI"/>
        <xsl:variable name="enctype" select="ixsl:get($form, 'enctype')" as="xs:string"/>
        <xsl:variable name="accept" select="'application/xhtml+xml'" as="xs:string"/>
        <xsl:variable name="about" select="ancestor::div[@typeof][1]/@about" as="xs:anyURI"/>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path(ldh:base-uri(.)) || '`'), 'etag')" as="xs:string"/>
        <xsl:message>$etag: <xsl:value-of select="$etag"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:variable name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <xsl:variable name="where-pattern" as="element()">
            <json:map>
                <json:string key="type">bgp</json:string>
                <json:array key="triples">
                    <json:map>
                        <json:string key="subject"><xsl:sequence select="$about"/></json:string>
                        <json:string key="predicate">?p</json:string>
                        <json:string key="object">?o</json:string>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:variable>
        <xsl:variable name="update-xml" as="element()">
            <json:map>
                <json:string key="type">update</json:string>
                <json:array key="updates">
                    <json:map>
                        <json:string key="updateType">insertdelete</json:string>
                        <json:array key="delete">
                            <xsl:sequence select="$where-pattern"/>
                        </json:array>
                        <json:array key="insert">
                            <json:map>
                                <json:string key="type">bgp</json:string>
                                <json:array key="triples">
                                    <xsl:sequence select="$triples"/>
                                </json:array>
                            </json:map>
                        </json:array>
                        <json:array key="where">
                            <xsl:sequence select="$where-pattern"/>
                        </json:array>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:variable>
        <xsl:variable name="update-json-string" select="xml-to-json($update-xml)" as="xs:string"/>
<xsl:message>
    <xsl:value-of select="$update-json-string"/>
</xsl:message>
        <xsl:variable name="update-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $update-json-string ])"/>
        <xsl:variable name="update-string" select="ixsl:call($sparql-generator, 'stringify', [ $update-json ])" as="xs:string"/>
        <xsl:variable name="resources" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:sequence select="ldh:triples-to-descriptions($triples)"/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $action)" as="xs:anyURI"/>
        
        <xsl:variable name="request" as="item()*">
            <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile --> 
            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string, 'headers': map{ 'If-Match': $etag, 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }">
                <xsl:call-template name="ldh:ResourceUpdated">
                    <xsl:with-param name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="form" select="$form"/>
                    <xsl:with-param name="resources" select="$resources"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- add new property to form -->
    
    <xsl:template match="div[@typeof][contains-token(@class, 'row-fluid')]//form//button[contains-token(@class, 'add-value')]" mode="ixsl:onclick">
        <xsl:variable name="form" select="ancestor::form" as="element()?"/>
        <xsl:variable name="property-control-group" select="../.." as="element()"/>
        <xsl:variable name="fieldset" select="$property-control-group/.." as="element()"/>
        <xsl:variable name="property-uri" select="../preceding-sibling::*/select/option[ixsl:get(., 'selected') = true()]/ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="seq-property" select="starts-with($property-uri, '&rdf;_')" as="xs:boolean"/>
        <xsl:variable name="forClass" select="ancestor::div[@typeof][contains-token(@class, 'row-fluid')]/@typeof" as="xs:anyURI*"/>
        <xsl:message>$forClass: <xsl:value-of select="$forClass"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:variable name="constructed-doc" select="ldh:construct-forClass($forClass)" as="document-node()"/> <!-- TO-DO: asynchronous request -->
        <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
        <xsl:variable name="property" select="$resource/*[concat(namespace-uri(), local-name()) = $property-uri]" as="element()"/>

        <!-- remove the current property control group from the current position -->
        <xsl:sequence select="ixsl:call($property-control-group, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:for-each select="$fieldset">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:apply-templates select="$property" mode="bs2:FormControl">
                    <!-- generate fresh $for value because otherwise we can generate existing IDs from the same constructor -->
                    <xsl:with-param name="for" select="'id' || ac:uuid()"/>
                </xsl:apply-templates>
                
                <!-- append the property control group at the end of the fieldset -->
                <xsl:copy-of select="$property-control-group"/>
            </xsl:result-document>
            
            <!-- initialize the last property control group after it's appended -->
            <xsl:apply-templates select="(./div[contains-token(@class, 'control-group')][input/@name = 'pu'])[last()]" mode="ldh:PostConstruct"/>
        </xsl:for-each>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- after inline resource creation/editing form is submitted  -->
    <xsl:template name="ldh:ResourceUpdated">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()?"/>
        <xsl:param name="form" as="element()"/>
        <xsl:param name="resources" as="document-node()"/>

        <xsl:choose>
            <!-- POST data appended successfully -->
            <xsl:when test="?status = (200, 204)">
                <xsl:variable name="etag" select="?headers?etag" as="xs:string?"/>
                <xsl:if test="$etag">
                    <xsl:message>$etag: <xsl:value-of select="$etag"/></xsl:message>
                    <!-- store ETag header value under window.LinkedDataHub.contents[$doc-uri].etag -->
                    <ixsl:set-property name="etag" select="$etag" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $doc-uri || '`')"/>
                </xsl:if>

                <xsl:variable name="classes" select="()" as="element()*"/>
                <xsl:variable name="row" as="element()">
                    <xsl:apply-templates select="$resources/rdf:RDF/*" mode="bs2:Row">
                        <xsl:with-param name="classes" select="$classes"/>
                        <xsl:with-param name="style" select="()"/> <!-- TO-DO: remove? -->
                        <xsl:with-param name="type-content" select="false()"/>
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:variable>
                
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:copy-of select="$row/*"/>
                    </xsl:result-document>
                </xsl:for-each>
                
                <xsl:apply-templates select="id($row//form/@id, ixsl:page())" mode="ldh:PostConstruct"/>

                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <!-- POST created new document successfully, redirect to it -->
            <xsl:when test="?status = 201 and ?headers?location">
                <xsl:variable name="created-uri" select="?headers?location" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $created-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="ldh:DocumentLoaded">
                            <xsl:with-param name="href" select="$created-uri"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>

                <!-- store the new request object -->
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- POST or PUT constraint violation response is 422 Unprocessable Entity, bad RDF syntax is 400 Bad Request -->
            <xsl:when test="?status = (400, 422) and starts-with(?media-type, 'application/rdf+xml')"> <!-- allow 'application/rdf+xml;charset=UTF-8' as well -->
                
                <xsl:variable name="body" select="?body" as="document-node()"/>
                <!-- iterate each form fieldset as resource -->
                <xsl:for-each select="$form/fieldset">
                    <xsl:variable name="resource-uri" select=".//input[@name = 'su']/ixsl:get(., 'value')" as="xs:anyURI?"/>
                    <xsl:variable name="resource-bnode" select=".//input[@name = 'sb']/ixsl:get(., 'value')" as="xs:string?"/>
                    <xsl:message>
                        $resource-uri: <xsl:value-of select="$resource-uri"/>
                        $resource-bnode: <xsl:value-of select="$resource-bnode"/>
                    </xsl:message>
                    <!-- select violations specific to this resource -->
                    <!-- TO-DO: key('violations-by-value', $resources//*/@rdf:resource, ?body) -->
                    <xsl:variable name="violations" select="key('violations-by-root', ($resource-uri, $resource-bnode), $body) | key('violations-by-focus-node', ($resource-uri, $resource-bnode), $body)" as="element()*"/>
                    <xsl:message>$violations: <xsl:value-of select="serialize($violations)"/></xsl:message>

                    <!-- iterate control groups as properties -->
                    <xsl:for-each select="./div[contains-token(@class, 'control-group')][input[@name = 'pu']]">
                        <xsl:variable name="predicate" select="input[@name = 'pu']/ixsl:get(., 'value')" as="xs:anyURI"/>
                        
                        <xsl:choose>
                            <!-- if there are violations specific to the predicate of this control group, set error class on the group -->
                            <xsl:when test="$violations[spin:violationPath/@rdf:resource = $predicate]">
                                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:when>
                            <!-- otherwise, remove the error class -->
                            <xsl:otherwise>
                                <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    
                    <xsl:for-each select="./div[contains-token(@class, 'violations')]">
                        <xsl:choose>
                            <!-- render violations if they exist for this resource -->
                            <xsl:when test="exists($violations)">
                                <xsl:result-document href="?." method="ixsl:replace-content">
                                    <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
                                </xsl:result-document>
                                <ixsl:set-style name="display" select="'block'"/>
                            </xsl:when>
                            <!-- hide any previous violations if this resource now has none -->
                            <xsl:otherwise>
                                <ixsl:set-style name="display" select="'none'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
                
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <!-- error response -->
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- toggles the .control-group for subject URI/bnode ID editing -->
    <xsl:template match="button[contains-token(@class, 'btn-edit-subj')]" mode="ixsl:onclick">
        <!-- subject .control group is the first one after <legend> -->
        <xsl:variable name="subj-control-group" select="ancestor::legend/following-sibling::div[1][contains-token(@class, 'control-group')]" as="element()"/>
        
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'open' ])[current-date() lt xs:date('2000-01-01')]"/>
        
        <xsl:for-each select="$subj-control-group">
            <xsl:choose>
                <xsl:when test="ixsl:style(.)?display = 'none'">
                    <ixsl:set-style name="display" select="'block'"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-style name="display" select="'none'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <!-- shows new SPIN-constructed document as a modal form -->
    <xsl:template match="div[contains-token(@class, 'action-bar')]//button[contains-token(@class, 'add-constructor')][ixsl:contains(., 'dataset.forClass')]" mode="ixsl:onclick" priority="2">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="forClass" select="ixsl:get(., 'dataset.forClass')" as="xs:anyURI"/>
        <xsl:message>forClass: <xsl:value-of select="$forClass"/></xsl:message>
        <xsl:variable name="constructed-doc" select="ldh:construct-forClass($forClass)" as="document-node()"/>
        <xsl:variable name="doc-uri" select="resolve-uri(ac:uuid() || '/', ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/> <!-- build a relative URI for the child document -->
        <xsl:variable name="this" select="$doc-uri" as="xs:anyURI"/>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/> $doc-uri: <xsl:value-of select="$doc-uri"/> $this: <xsl:value-of select="$doc-uri"/></xsl:message>
        <!-- set document URI instead of blank node -->
        <xsl:variable name="constructed-doc" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$constructed-doc" mode="ldh:SetResourceURI">
                    <xsl:with-param name="forClass" select="$forClass" tunnel="yes"/>
                    <xsl:with-param name="this" select="$this" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="classes" select="()" as="element()*"/>

        <xsl:for-each select="$container">
            <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
            <xsl:variable name="form" as="element()*">
                <!-- TO-DO: refactor to use asynchronous HTTP requests -->
                <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
                <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:variable name="type-metadata" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                <xsl:variable name="property-uris" select="distinct-values($resource/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:variable name="property-metadata" select="document($request-uri)" as="document-node()"/>

                <xsl:variable name="query-string" select="$constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
                <xsl:variable name="constraints" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                <xsl:apply-templates select="$constructed-doc" mode="bs2:Form"> <!-- document level template -->
                    <xsl:with-param name="method" select="'post'"/> <!-- browsers do not allow PUT form method -->
                    <xsl:with-param name="action" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $doc-uri)" as="xs:anyURI"/>
                    <xsl:with-param name="form-actions-class" select="'form-actions modal-footer'" as="xs:string?"/>
                    <xsl:with-param name="classes" select="$classes"/>
                    <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                    <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                    <!-- <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/> -->
                    <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/> <!-- ac:absolute-path(ldh:base-uri(.)) is empty on constructed documents -->
                    <!-- <xsl:sort select="ac:label(.)"/> -->
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:result-document href="?." method="ixsl:append-content">
                <div class="modal modal-constructor fade in">
                    <!--
                    <xsl:if test="$id">
                        <xsl:attribute name="id" select="$id"/>
                    </xsl:if>
                    -->

                    <div class="modal-header">
                        <button type="button" class="close">&#215;</button>

                        <legend>
                            <!-- <xsl:value-of select="$legend-label"/> -->
                        </legend>
                    </div>

                    <div class="modal-body">
                        <xsl:copy-of select="$form"/>
                    </div>
                </div>
            </xsl:result-document>

            <xsl:if test="id($form/@id, ixsl:page())">
                <xsl:apply-templates select="id($form/@id, ixsl:page())" mode="ldh:PostConstruct"/>
            </xsl:if>
        </xsl:for-each>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- appends new SPIN-constructed instance to the form -->
    <xsl:template match="button[contains-token(@class, 'add-constructor')][ixsl:contains(., 'dataset.forClass')]" mode="ixsl:onclick" priority="1">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="forClass" select="ixsl:get(., 'dataset.forClass')" as="xs:anyURI"/>
        <xsl:message>forClass: <xsl:value-of select="$forClass"/></xsl:message>
        <xsl:variable name="constructed-doc" select="ldh:construct-forClass($forClass)" as="document-node()"/>
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="this" select="xs:anyURI($doc-uri || '#id' || ac:uuid())" as="xs:anyURI"/>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/> $doc-uri: <xsl:value-of select="$doc-uri"/> $this: <xsl:value-of select="$doc-uri"/></xsl:message>
        <!-- set document URI instead of blank node -->
        <xsl:variable name="constructed-doc" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$constructed-doc" mode="ldh:SetResourceURI">
                    <xsl:with-param name="forClass" select="$forClass" tunnel="yes"/>
                    <xsl:with-param name="this" select="$this" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="classes" select="()" as="element()*"/>

        <xsl:for-each select="$container">
            <xsl:variable name="create-resource" select="$container/div[contains-token(@class, 'create-resource')]" as="element()"/>
            <!-- remove preceding Create button block -->
            <xsl:for-each select="$create-resource">
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>

            <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
            <xsl:variable name="row-form" as="element()*">
                <!-- TO-DO: refactor to use asynchronous HTTP requests -->
                <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
                <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:variable name="type-metadata" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                <xsl:variable name="property-uris" select="distinct-values($resource/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:variable name="property-metadata" select="document($request-uri)" as="document-node()"/>

                <xsl:variable name="query-string" select="$constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
                <xsl:variable name="constraints" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                <xsl:apply-templates select="$constructed-doc" mode="bs2:RowForm">
                    <xsl:with-param name="method" select="'post'"/>
                    <xsl:with-param name="action" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $doc-uri)" as="xs:anyURI"/>
                    <xsl:with-param name="classes" select="$classes"/>
                    <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                    <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                    <!-- <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/> -->
                    <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/> <!-- ac:absolute-path(ldh:base-uri(.)) is empty on constructed documents -->
                    <xsl:with-param name="show-cancel-button" select="false()"/>
                </xsl:apply-templates>
            </xsl:variable>
            
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select="$row-form"/>
                
                <!-- append following Create button block -->
                <xsl:sequence select="$create-resource"/>
            </xsl:result-document>

            <!-- add event listeners to the descendants of the form. TO-DO: replace with XSLT -->
            <xsl:if test="id($row-form//form/@id, ixsl:page())">
                <xsl:apply-templates select="id($row-form//form/@id, ixsl:page())" mode="ldh:PostConstruct"/>
            </xsl:if>
        </xsl:for-each>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- types (classes with constructors) are looked up in the <ns> endpoint -->
    <xsl:template match="input[contains-token(@class, 'type-typeahead')]" mode="ixsl:onkeyup" priority="1">
        <xsl:next-match>
            <xsl:with-param name="endpoint" select="resolve-uri('ns', $ldt:base)"/>
            <xsl:with-param name="select-string" select="$select-labelled-class-or-shape-string"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- lookup by $label and optional $Type using search SELECT -->
    <xsl:template match="input[contains-token(@class, 'typeahead')]" mode="ixsl:onkeyup">
        <xsl:param name="text" select="ixsl:get(., 'value')" as="xs:string?"/>
        <xsl:param name="menu" select="following-sibling::ul" as="element()"/>
        <xsl:param name="delay" select="400" as="xs:integer"/>
        <xsl:param name="endpoint" select="sd:endpoint()" as="xs:anyURI"/>
        <xsl:param name="forClass" select="../span/ixsl:get(., 'dataset.forClass')" as="xs:anyURI*"/>
        <xsl:param name="select-string" select="$select-labelled-string" as="xs:string?"/>
        <xsl:param name="limit" select="100" as="xs:integer?"/>
        <xsl:param name="label-var-name" select="'label'" as="xs:string"/>
        <xsl:param name="type-var-name" select="'Type'" as="xs:string"/>
        <xsl:variable name="key-code" select="ixsl:get(ixsl:event(), 'code')" as="xs:string"/>
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
        <!-- append FILTER($var IN ()) -->
        <xsl:variable name="select-xml" as="document-node()">
            <xsl:document>
                <xsl:choose>
                    <!-- do not FILTER by $forClass if the only type is rdfs:Resource -->
                    <xsl:when test="empty($forClass[not(. = '&rdfs;Resource')])">
                        <xsl:sequence select="$select-xml"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$select-xml" mode="ldh:add-filter-in">
                            <xsl:with-param name="var-name" select="$type-var-name" tunnel="yes"/>
                            <xsl:with-param name="values" select="$forClass" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
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
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': string($query-string) })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/> <!-- proxy the results -->
        <!-- TO-DO: use <ixsl:schedule-action> instead of document() -->
        <xsl:variable name="results" select="document($request-uri)" as="document-node()"/>
        
        <xsl:choose>
            <xsl:when test="$key-code = 'Escape'">
                <xsl:call-template name="typeahead:hide">
                    <xsl:with-param name="menu" select="$menu"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$key-code = 'Enter'">
                <xsl:for-each select="$menu/li[contains-token(@class, 'active')]">
                    <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/> <!-- prevent form submit -->
                
                    <xsl:variable name="resource-id" select="input[@name = ('ou', 'ob')]/ixsl:get(., 'value')" as="xs:anyURI"/>
                    <xsl:variable name="typeahead-class" select="'btn add-typeahead'" as="xs:string"/>
                    <xsl:variable name="typeahead-doc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.typeahead.rdfXml')" as="document-node()"/> <!-- set by typeahead:xml-loaded -->
                    <xsl:variable name="resource" select="key('resources', $resource-id, $typeahead-doc)"/>

                    <xsl:for-each select="../..">
                        <xsl:variable name="typeahead" as="element()">
                            <xsl:apply-templates select="$resource" mode="ldh:Typeahead">
                                <xsl:with-param name="class" select="$typeahead-class"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:sequence select="$typeahead/*"/>
                        </xsl:result-document>
                    </xsl:for-each>
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
                        <!-- we don't want to use rdfs:Resource as a type because a filter in typeahead:process would not select any resources with this type -->
                        <xsl:with-param name="resource-types" select="$forClass[not(. = '&rdfs;Resource')]"/>
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

    <xsl:template match="input[contains-token(@class, 'typeahead')]" mode="ixsl:onfocusout">
        <xsl:param name="menu" select="following-sibling::ul" as="element()"/>
        
        <xsl:call-template name="typeahead:hide">
            <xsl:with-param name="menu" select="$menu"/>
        </xsl:call-template>
    </xsl:template>

    <!-- select .type-typeahead item (priority over plain .typeahead) -->
    
    <xsl:template match="ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'type-typeahead')]/li" mode="ixsl:onmousedown" priority="1">
        <xsl:param name="typeahead-class" select="'btn add-typeahead add-type-typeahead'" as="xs:string"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'row-fluid')]" as="element()"/>
        <xsl:variable name="fieldset" select="ancestor::fieldset" as="element()"/>
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI"/>
        <xsl:variable name="resource-id" select="input[@name = ('ou', 'ob')]/ixsl:get(., 'value')" as="xs:string"/> <!-- can be URI resource or blank node ID -->
        <xsl:variable name="typeahead-doc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.typeahead.rdfXml')" as="document-node()"/>
        <xsl:variable name="resource" select="key('resources', $resource-id, $typeahead-doc)" as="element()"/>
        <xsl:variable name="control-group" select="ancestor::div[contains-token(@class, 'control-group')]" as="element()"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

        <xsl:for-each select="../..">
            <xsl:variable name="typeahead" as="element()">
                <xsl:apply-templates select="$resource" mode="ldh:Typeahead">
                    <xsl:with-param name="class" select="$typeahead-class"/>
                </xsl:apply-templates>
            </xsl:variable>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="$typeahead/*"/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:choose>
            <!-- a node shape was selected -->
            <xsl:when test="$resource/rdf:type/@rdf:resource = '&sh;NodeShape'">
                <xsl:variable name="forShape" select="$resource/@rdf:about" as="xs:anyURI"/>
                <xsl:message>forShape: <xsl:value-of select="$forShape"/></xsl:message>
                <xsl:variable name="shape-doc" select="document(ac:document-uri($forShape))" as="document-node()?"/>
                <xsl:variable name="shape" select="key('resources', $forShape, $shape-doc)" as="element()"/>
                <xsl:variable name="constructed-doc" as="document-node()">
                    <xsl:document>
                        <rdf:RDF>
                            <xsl:apply-templates select="$shape" mode="ldh:Shape"/>
                        </rdf:RDF>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="forClass" select="$shape/sh:targetClass/@rdf:resource" as="xs:anyURI"/>

                <ixsl:set-attribute name="typeof" select="$forClass" object="$container"/>
                
                <xsl:for-each select="$fieldset">
                    <!-- TO-DO: unify with .btn-edit onclick -->
                    <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
                    <xsl:variable name="new-fieldset" as="element()*">
                        <!-- TO-DO: refactor to use asynchronous HTTP requests -->
                        <!--
                        <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
                        <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                        <xsl:variable name="type-metadata" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                        <xsl:variable name="property-uris" select="distinct-values($resource/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                        <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                        <xsl:variable name="property-metadata" select="document($request-uri)" as="document-node()"/>

                        <xsl:variable name="query-string" select="$constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
                        <xsl:variable name="constraints" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>
                        -->
                        
                        <xsl:apply-templates select="$resource" mode="bs2:Form">
                            <xsl:with-param name="method" select="'post'"/>
                            <xsl:with-param name="action" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $doc-uri)" as="xs:anyURI"/>
                            <xsl:with-param name="classes" select="$classes"/>
                            <!--
                            <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                            <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                            -->
                            <xsl:with-param name="shapes" select="$shape-doc" tunnel="yes"/>
                            <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/> <!-- ac:absolute-path(ldh:base-uri(.)) is empty on constructed documents -->
                            <xsl:with-param name="show-cancel-button" select="false()"/>
                        </xsl:apply-templates>
                    </xsl:variable>

                    <!-- remove the "old" property controls -->
                    <xsl:for-each select=".//div[contains-token(@class, 'control-group')][.//button[contains-token(@class, 'add-value')]]">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <!-- add property form controls, except for rdf:type -->
                        <xsl:copy-of select="$new-fieldset/div[contains-token(@class, 'control-group')][not(input[@name = 'pu']/@value = '&rdf;type')]"/>
                    </xsl:result-document>

                    <!-- add event listeners to the descendants of the fieldset TO-DO: replace with XSLT -->
                    <xsl:if test="id(@id, ixsl:page())">
                        <xsl:apply-templates select="id(@id, ixsl:page())" mode="ldh:PostConstruct"/>
                    </xsl:if>
                </xsl:for-each>

                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <!-- a class with constructor was selected -->
            <xsl:otherwise>
                <xsl:variable name="forClass" select="$resource/@rdf:about" as="xs:anyURI"/>
                <xsl:message>forClass: <xsl:value-of select="$forClass"/></xsl:message>
                <xsl:variable name="constructed-doc" select="ldh:construct-forClass($forClass)" as="document-node()"/>
                <xsl:variable name="classes" select="()" as="element()*"/>

                <!-- update @typeof value -->
                <ixsl:set-attribute name="typeof" select="$forClass" object="$container"/>
                
                <xsl:for-each select="$fieldset">
                    <!-- TO-DO: unify with .btn-edit onclick -->
                    <xsl:variable name="resource" select="key('resources-by-type', $forClass, $constructed-doc)[not(key('predicates-by-object', @rdf:nodeID))]" as="element()"/>
                    <xsl:variable name="new-fieldset" as="element()*">
                        <!-- TO-DO: refactor to use asynchronous HTTP requests -->
                        <xsl:variable name="types" select="distinct-values($resource/rdf:type/@rdf:resource)" as="xs:anyURI*"/>
                        <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                        <xsl:variable name="type-metadata" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                        <xsl:variable name="property-uris" select="distinct-values($resource/*/concat(namespace-uri(), local-name()))" as="xs:string*"/>
                        <xsl:variable name="query-string" select="'DESCRIBE $Type VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                        <xsl:variable name="property-metadata" select="document($request-uri)" as="document-node()"/>

                        <xsl:variable name="query-string" select="$constraint-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }'" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string, 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
                        <xsl:variable name="constraints" select="if (exists($types)) then document($request-uri) else ()" as="document-node()?"/>

                        <xsl:apply-templates select="$resource" mode="bs2:Form">
                            <xsl:with-param name="method" select="'post'"/>
                            <xsl:with-param name="action" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $doc-uri)" as="xs:anyURI"/>
                            <xsl:with-param name="classes" select="$classes"/>
                            <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                            <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
                            <xsl:with-param name="constraints" select="$constraints" tunnel="yes"/>
                            <!-- <xsl:with-param name="shapes" select="$shapes" tunnel="yes"/> -->
                            <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/> <!-- ac:absolute-path(ldh:base-uri(.)) is empty on constructed documents -->
                            <xsl:with-param name="show-cancel-button" select="false()"/>
                        </xsl:apply-templates>
                    </xsl:variable>

                    <!-- remove the "old" property controls -->
                    <xsl:for-each select=".//div[contains-token(@class, 'control-group')][.//button[contains-token(@class, 'add-value')]]">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <!-- add property form controls, except for rdf:type -->
                        <xsl:copy-of select="$new-fieldset/div[contains-token(@class, 'control-group')][not(input[@name = 'pu']/@value = '&rdf;type')]"/>
                    </xsl:result-document>

                    <!-- add event listeners to the descendants of the fieldset TO-DO: replace with XSLT -->
                    <xsl:if test="id(@id, ixsl:page())">
                        <xsl:apply-templates select="id(@id, ixsl:page())" mode="ldh:PostConstruct"/>
                    </xsl:if>
                </xsl:for-each>

                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- select typeahead item -->
    
    <xsl:template match="ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'typeahead')]/li" mode="ixsl:onmousedown">
        <xsl:param name="typeahead-class" select="'btn add-typeahead'" as="xs:string"/>
        <xsl:variable name="resource-id" select="input[@name = ('ou', 'ob')]/ixsl:get(., 'value')" as="xs:string"/> <!-- can be URI resource or blank node ID -->
        <xsl:variable name="typeahead-doc" select="ixsl:get(ixsl:window(), 'LinkedDataHub.typeahead.rdfXml')" as="document-node()"/>
        <xsl:variable name="resource" select="key('resources', $resource-id, $typeahead-doc)" as="element()"/>

        <xsl:for-each select="../..">
            <xsl:variable name="typeahead" as="element()">
                <xsl:apply-templates select="$resource" mode="ldh:Typeahead">
                    <xsl:with-param name="class" select="$typeahead-class"/>
                </xsl:apply-templates>
            </xsl:variable>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="$typeahead/*"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- toggle between Content as HTML (rdf:XMLLiteral) and URI resource -->
    <xsl:template match="select[contains-token(@class, 'content-type')][ixsl:get(., 'value') = '&rdfs;Resource']" mode="ixsl:onchange">
        <xsl:variable name="fieldset" select="../../.." as="element()"/>
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="A1">
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:nodeID="A2"/>
                        <ac:mode rdf:nodeID="A3"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A2">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                    <rdf:Description rdf:nodeID="A3">
                        <rdf:type rdf:resource="&rdfs;Resource"/>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="new-fieldset" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:Description[@rdf:nodeID = 'A1']" mode="bs2:FormControl"/>
        </xsl:variable>

        <xsl:for-each select="$fieldset">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <!-- reinsert all children except control groups -->
                <xsl:copy-of select="$fieldset/*[not(contains-token(@class, 'control-group'))]"/>
                <!-- insert new control groups -->
                <xsl:copy-of select="$new-fieldset/*[contains-token(@class, 'control-group')]"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- toggle between Content as URI resource and HTML (rdf:XMLLiteral) -->
    <xsl:template match="select[contains-token(@class, 'content-type')][ixsl:get(., 'value') = '&rdf;XMLLiteral']" mode="ixsl:onchange">
        <xsl:variable name="fieldset" select="../../.." as="element()"/>
       <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:nodeID="A1">
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:parseType="Literal">
                            <xhtml:div/>
                        </rdf:value>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="new-fieldset" as="node()*">
            <xsl:apply-templates select="$constructor//rdf:Description[@rdf:nodeID = 'A1']" mode="bs2:FormControl"/>
        </xsl:variable>

        <xsl:for-each select="$fieldset">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <!-- reinsert all children except control groups -->
                <xsl:copy-of select="$fieldset/*[not(contains-token(@class, 'control-group'))]"/>
                <!-- insert new control groups -->
                <xsl:copy-of select="$new-fieldset/*[contains-token(@class, 'control-group')]"/>
            </xsl:result-document>

            <!-- initialize wymeditor textarea -->
            <xsl:apply-templates select="key('elements-by-class', 'wymeditor', ancestor::div[1])" mode="ldh:PostConstruct"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- remove the whole div.row-fluid containing the form -->
    <xsl:template match="div[contains-token(@class, 'row-fluid')]//button[contains-token(@class, 'btn-remove-resource')]" mode="ixsl:onclick" priority="2">
        <xsl:variable name="about" select="ancestor::div[@typeof][1]/@about" as="xs:anyURI"/>
        <xsl:variable name="form" select="ancestor::form" as="element()"/>
        <xsl:variable name="action" select="ixsl:get($form, 'action')" as="xs:anyURI"/>
        <xsl:message>ldh:base-uri(.): <xsl:value-of select="ldh:base-uri(.)"/></xsl:message>
        <xsl:variable name="etag" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || ac:absolute-path($action) || '`'), 'etag')" as="xs:string"/>
        <xsl:message>$etag: <xsl:value-of select="$etag"/></xsl:message>

        <xsl:sequence select="ixsl:call(ancestor::div[contains-token(@class, 'row-fluid')][1], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="where-pattern" as="element()">
            <json:map>
                <json:string key="type">bgp</json:string>
                <json:array key="triples">
                    <json:map>
                        <json:string key="subject"><xsl:sequence select="$about"/></json:string>
                        <json:string key="predicate">?p</json:string>
                        <json:string key="object">?o</json:string>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:variable>
        <xsl:variable name="update-xml" as="element()">
            <json:map>
                <json:string key="type">update</json:string>
                <json:array key="updates">
                    <json:map>
                        <json:string key="updateType">insertdelete</json:string>
                        <json:array key="delete">
                            <xsl:sequence select="$where-pattern"/>
                        </json:array>
                        <json:array key="insert"/>
                        <json:array key="where">
                            <xsl:sequence select="$where-pattern"/>
                        </json:array>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:variable>
        <xsl:variable name="update-json-string" select="xml-to-json($update-xml)" as="xs:string"/>
<xsl:message>
    <xsl:value-of select="$update-json-string"/>
</xsl:message>
        <xsl:variable name="update-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $update-json-string ])"/>
        <xsl:variable name="update-string" select="ixsl:call($sparql-generator, 'stringify', [ $update-json ])" as="xs:string"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $action)" as="xs:anyURI"/>
        
        <xsl:variable name="request" as="item()*">
            <!-- If-Match header checks preconditions, i.e. that the graph has not been modified in the meanwhile --> 
            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string, 'headers': map{ 'If-Match': $etag, 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }">
                <xsl:call-template name="ldh:ResourceDeleted"/>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template name="ldh:ResourceDeleted">
        <xsl:context-item as="map(*)" use="required"/>

        <xsl:choose>
            <xsl:when test="?status = 204">
                <xsl:message>Resource deleted</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- remove <fieldset> -->
    <xsl:template match="fieldset//button[contains-token(@class, 'btn-remove-resource')]" mode="ixsl:onclick" priority="1">
        <xsl:sequence select="ixsl:call(ancestor::fieldset, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- remove <div class="control-group"> -->
    <xsl:template match="button[contains-token(@class, 'btn-remove-property')]" mode="ixsl:onclick" priority="1">
        <xsl:sequence select="ixsl:call(../../.., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="button[contains-token(@class, 'add-type')]" mode="ixsl:onclick" priority="1">
        <xsl:param name="lookup-class" select="'type-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        
        <xsl:for-each select="..">
            <xsl:variable name="lookup" as="element()">
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="id" select="'input-' || $uuid"/>
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="$lookup/*"/>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="../..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select=".."/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:for-each select="id('input-' || $uuid, ixsl:page())">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- special case for class (with constructor) lookups -->
    <xsl:template match="button[contains-token(@class, 'add-type-typeahead')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'type-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="button[contains-token(@class, 'add-typeahead')]" mode="ixsl:onclick">
        <xsl:param name="lookup-class" select="'resource-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'resource-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        
        <xsl:for-each select="..">
            <xsl:variable name="lookup" as="element()">
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="id" select="'input-' || $uuid"/>
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="$lookup/*"/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:for-each select="id('input-' || $uuid, ixsl:page())">
            <xsl:sequence select="ixsl:call(., 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- show a typeahead dropdown with instances in the form -->
    
    <xsl:template match="form//input[contains-token(@class, 'resource-typeahead')]" mode="ixsl:onfocusin">
        <xsl:variable name="menu" select="following-sibling::ul" as="element()"/>
        <xsl:variable name="forClass" select="../span/ixsl:get(., 'dataset.forClass')" as="xs:anyURI*"/>
        <xsl:variable name="item-doc" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <!-- convert instances in the RDF/POST form to RDF/XML -->
                    <xsl:for-each select="ancestor::form//input[@name = ('sb', 'su')][@value]">
                        <!-- filter resources by type if $forClass is provided -->
                        <xsl:if test="empty($forClass) or $forClass = '&rdfs;Resource' or following-sibling::div[input[@name = 'pu'][@value = '&rdf;type']]//input[@name = 'ou']/@value = $forClass">
                            <rdf:Description>
                                <xsl:if test="@name = 'sb'">
                                     <xsl:attribute name="rdf:nodeID" select="@value"/>
                                </xsl:if>
                                <xsl:if test="@name = 'su'">
                                     <xsl:attribute name="rdf:about" select="@value"/>
                                </xsl:if>
                                
                                <dct:title>
                                    <xsl:value-of select="@value"/>
                                </dct:title>
                            </rdf:Description>
                        </xsl:if>
                    </xsl:for-each>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>

        <ixsl:set-property name="LinkedDataHub.typeahead.rdfXml" select="$item-doc"/>

        <xsl:call-template name="typeahead:process">
            <xsl:with-param name="menu" select="$menu"/>
            <xsl:with-param name="items" select="$item-doc/rdf:RDF/rdf:Description"/>
            <xsl:with-param name="element" select="."/>
        </xsl:call-template>
    </xsl:template>

    <!-- simplified version of Bootstrap's tooltip() -->
    
    <xsl:template match="fieldset//input" mode="ixsl:onmouseover">
        <xsl:choose>
            <!-- show existing tooltip -->
            <xsl:when test="../div[contains-token(@class, 'tooltip')]">
                <ixsl:set-style name="display" select="'block'" object="../div[contains-token(@class, 'tooltip')]"/>
            </xsl:when>
            <!-- append new tooltip -->
            <xsl:otherwise>
                <xsl:variable name="description-span" select="ancestor::*[contains-token(@class, 'control-group')]//*[contains-token(@class, 'description')]" as="element()?"/>
                <xsl:if test="$description-span">
                    <xsl:variable name="input-offset-width" select="ixsl:get(., 'offsetWidth')" as="xs:integer"/>
                    <xsl:variable name="input-offset-height" select="ixsl:get(., 'offsetHeight')" as="xs:integer"/>
                    <xsl:for-each select="..">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <div class="tooltip fade top in">
                                <div class="tooltip-arrow"></div>
                                <div class="tooltip-inner">
                                    <xsl:sequence select="$description-span/text()"/>
                                </div>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <!-- adjust the position of the tooltip relative to the input -->
        <xsl:variable name="input-top" select="ixsl:get(., 'offsetTop')" as="xs:double"/>
        <xsl:variable name="input-left" select="ixsl:get(., 'offsetLeft')" as="xs:double"/>
        <xsl:variable name="input-width" select="ixsl:get(., 'offsetWidth')" as="xs:double"/>
        <xsl:for-each select="../div[contains-token(@class, 'tooltip')]">
            <xsl:variable name="tooltip-height" select="ixsl:get(., 'offsetHeight')" as="xs:double"/>
            <xsl:variable name="tooltip-width" select="ixsl:get(., 'offsetWidth')" as="xs:double"/>
            
            <ixsl:set-style name="top" select="($input-top - $tooltip-height) || 'px'"/>
            <ixsl:set-style name="left" select="($input-left + ($input-width - $tooltip-width) div 2) || 'px'"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="fieldset//input" mode="ixsl:onmouseout">
        <xsl:for-each select="../div[contains-token(@class, 'tooltip')]">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- the same logic as onFormLoad but handles only responses to multipart requests invoked via JS function fetchDispatchXML() -->
    <xsl:template match="." mode="ixsl:onMultipartResourceUpdated">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="doc-uri" select="ixsl:get(ixsl:get($event, 'detail'), 'docUri')" as="xs:anyURI"/>
        <xsl:variable name="container" select="ixsl:get(ixsl:get($event, 'detail'), 'container')" as="element()"/>
        <xsl:variable name="resources" select="ixsl:get(ixsl:get($event, 'detail'), 'resources')" as="document-node()"/>
        <xsl:variable name="form" select="ixsl:get(ixsl:get($event, 'detail'), 'target')" as="element()"/> <!-- not ixsl:get(ixsl:event(), 'target') because that's the whole document -->
        <xsl:variable name="response" select="ixsl:get(ixsl:get($event, 'detail'), 'response')"/>
        <xsl:variable name="xml" select="if (ixsl:contains($event, 'detail.xml')) then ixsl:get($event, 'detail.xml') else ()" as="document-node()?"/>
        <!-- imitate an <ixsl:schedule-action> response map -->
        <xsl:variable name="response" as="map(*)">
            <xsl:map>
                <xsl:map-entry key="'body'" select="$xml"/>
                <xsl:map-entry key="'status'" select="ixsl:get($response, 'status')"/>
                <xsl:map-entry key="'message'" select="ixsl:get($response, 'statusText')"/>
                <xsl:map-entry key="'media-type'" select="ixsl:call(ixsl:get($response, 'headers'), 'get', [ 'Content-Type' ])"/>
                <xsl:map-entry key="'headers'">
                    <xsl:map>
                        <xsl:map-entry key="'location'" select="ixsl:call(ixsl:get($response, 'headers'), 'get', [ 'Location' ])"/>
                        <!-- TO-DO: create a map of all headers from response.headers -->
                    </xsl:map>
                </xsl:map-entry>
            </xsl:map>
        </xsl:variable>
        
        <xsl:for-each select="$response">
            <xsl:call-template name="ldh:ResourceUpdated">
                <xsl:with-param name="doc-uri" select="$doc-uri"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="resources" select="$resources"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <!-- after "Create" or "Edit" buttons are clicked" -->
    <xsl:template name="onAddForm">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="add-class" as="xs:string?"/>
        <xsl:param name="new-form-id" as="xs:string?"/>
        <xsl:param name="max-bnode-id" as="xs:integer?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="event" select="ixsl:event()"/>
                    <xsl:variable name="target" select="ixsl:get($event, 'target')"/>
                    <xsl:variable name="modal" select="exists(id($container/@id)//div[contains-token(@class, 'modal-constructor')])" as="xs:boolean"/>
                    <xsl:variable name="doc-id" select="concat('id', ixsl:call(ixsl:window(), 'generateUUID', []))" as="xs:string"/>
                    
                    <xsl:variable name="form" as="element()">
                        <xsl:apply-templates select="id($container/@id)//form" mode="form">
                            <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                            <!-- only rewrite bnode labels if "Create" button was called within <form> -->
                            <xsl:with-param name="max-bnode-id" select="if ($target/ancestor::form[contains-token(@class, 'form-horizontal')]) then $max-bnode-id else ()" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="form-id" select="$form/@id" as="xs:string"/>

                    <xsl:if test="$add-class">
                        <xsl:sequence select="$form/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ $add-class, true() ])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>

                    <xsl:choose>
                        <!-- if "Create" button is within a <form>, append elements to <form> -->
<!--                        <xsl:when test="$target/ancestor::form[contains-token(@class, 'form-horizontal')]">
                            <xsl:for-each select="$target/ancestor::form[contains-token(@class, 'form-horizontal')]">
                                 remove the old form-actions <div> because we'll be appending a new one below 
                                <xsl:for-each select="./div[./div[contains-token(@class, 'form-actions')]]">
                                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                                </xsl:for-each>
                                 remove the current "Create" buttons from the form 
                                <xsl:for-each select="$target/ancestor::div[contains-token(@class, 'create-resource')]">
                                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                                </xsl:for-each>

                                <xsl:result-document href="?." method="ixsl:append-content">
                                     only append the <fieldset> from the $form, not the whole <form> 
                                    <xsl:copy-of select="$form//div[contains-token(@class, 'row-fluid')]"/>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:when>-->
                        <!-- if "Create" button is ReadMode, append form as row -->
                        <xsl:when test="$target/ancestor::div[@id = 'content-body']">
                            <xsl:for-each select="$target/ancestor::div[@id = 'content-body']">
                                <!-- remove the current "Create" buttons from the row -->
                                <xsl:for-each select="$target/ancestor::div[contains-token(@class, 'create-resource')]">
                                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                                </xsl:for-each>

                                <xsl:result-document href="?." method="ixsl:append-content">
                                    <div id="id{ac:uuid()}" class="row-fluid"> <!-- typeof -->
                                        <xsl:copy-of select="$form"/>
                                    </div>
                                </xsl:result-document>
                            </xsl:for-each>
                            
                            <!-- a hack to change the request method to POST as we want to append partial data and not replace the whole graph as with PUT in EditMode -->
                            <ixsl:set-attribute name="action" select="replace($form/@action, '_method=PUT', '_method=POST')" object="id($form-id, ixsl:page())"/>
                        </xsl:when>
                        <!-- there's no <form> so we're not in EditMode - replace the whole content -->
                        <xsl:otherwise>
                            <xsl:for-each select="$container">
                                <xsl:result-document href="?." method="ixsl:replace-content">
                                    <xsl:copy-of select="$form"/>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>

                    <!-- add event listeners to the descendants of the form. TO-DO: replace with XSLT -->
                    <xsl:if test="id($form-id, ixsl:page())">
                        <xsl:apply-templates select="id($form-id, ixsl:page())" mode="ldh:PostConstruct"/>
                    </xsl:if>

                    <xsl:if test="$new-form-id">
                        <!-- overwrite form's @id with the provided value -->
                        <ixsl:set-property name="id" select="$new-form-id" object="id($form-id, ixsl:page())"/>
                    </xsl:if>
                    
                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onAddValue">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="property-control-group" as="element()"/>
        <xsl:param name="property" as="xs:anyURI"/>
        <xsl:param name="seq-property" select="starts-with($property, '&rdf;_')" as="xs:boolean"/>
        <xsl:param name="fieldset" select="$property-control-group/.." as="element()"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="doc-id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
                    <xsl:variable name="form" as="element()">
                        <xsl:apply-templates select="//form[@class = 'form-horizontal']" mode="form">
                            <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <!-- if this is a rdf:Seq membership property, always revert to rdf:_1 (because that's the only one we have in the constructor) and fix the form inputs afterwards -->
                    <xsl:variable name="constructed-property" select="if ($seq-property) then xs:anyURI('&rdf;_1') else $property" as="xs:anyURI"/>
                    <!-- the constructor might have duplicate properties, possibly with different object types -->
                    <xsl:variable name="new-control-group" select="$form//div[contains-token(@class, 'control-group')][input[@name = 'pu']/@value = $constructed-property]" as="element()*"/>
                    
                    <!-- append the new constructed control groups as well as the current property control group to the parent fieldset -->
                    <xsl:for-each select="$fieldset">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <xsl:copy-of select="$new-control-group"/>
                            <xsl:copy-of select="$property-control-group"/>
                        </xsl:result-document>

                        <xsl:apply-templates select="." mode="ldh:PostConstruct"/>
                    </xsl:for-each>

                    <!-- remove the current "old" property control group -->
                    <xsl:sequence select="ixsl:call($property-control-group, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>

                    <xsl:if test="$seq-property">
                        <!-- switch context to the newly inserted control group -->
                        <xsl:for-each select="$fieldset/div[contains-token(@class, 'control-group')][input[@name = 'pu']/@value = $constructed-property][last()]">
                            <xsl:variable name="seq-index" select="xs:integer(substring-after($property, '&rdf;_'))" as="xs:integer"/>
                            <xsl:if test="$seq-index &gt; 1">
                                <!-- fix up the rdf:_X sequence property URI and label -->
                                <ixsl:set-attribute name="value" object="input[@name = 'pu']" select="$property"/>

                                <xsl:for-each select="label">
                                    <xsl:result-document href="?." method="ixsl:replace-content">
                                        <xsl:value-of select="'_' || $seq-index"/>
                                    </xsl:result-document>
                                </xsl:for-each>
                            </xsl:if>
                        </xsl:for-each>

                        <!-- switch context to the last div.control-group which now contains the property select -->
                        <xsl:for-each select="$fieldset/div[contains-token(@class, 'control-group')][./span[contains-token(@class, 'control-label')]/select]">
                            <xsl:variable name="seq-properties" select="for $property in ancestor::fieldset//input[@name = 'pu']/@value[starts-with(., '&rdf;' || '_')] return xs:anyURI($property)" as="xs:anyURI*"/>
                            <xsl:variable name="max-seq-index" select="if (empty($seq-properties)) then 0 else max(for $seq-property in $seq-properties return xs:integer(substring-after($seq-property, '&rdf;' || '_')))" as="xs:integer"/>
                            <xsl:variable name="next-property" select="xs:anyURI('&rdf;_' || ($max-seq-index + 1))" as="xs:anyURI"/>

                            <xsl:for-each select=".//select">
                                <!-- append new property to the dropdown with an incremented index (if it doesn't already exist) -->
                                <xsl:if test="not(option/@value = $next-property)">
                                    <xsl:result-document href="?." method="ixsl:append-content">
                                        <option value="{$next-property}">
                                            <xsl:text>_</xsl:text>
                                            <xsl:value-of select="$max-seq-index + 1"/>
                                        </option>
                                    </xsl:result-document>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:if>
                    
                    <xsl:if test="$property = '&rdf;type'">
                        <xsl:for-each select="$fieldset/div[contains-token(@class, 'control-group')][input[@name = 'pu']/@value = $property][last()]">
                            <xsl:variable name="id" select="'input-' || ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>

                            <!-- reset label's @for value with the new $id -->
                            <xsl:for-each select="./label[contains-token(@class, 'control-label')]">
                                <ixsl:set-attribute name="for" object="." select="$id"/>
                            </xsl:for-each>

                            <!-- replace existing typeahead with an empty typeahead input (bs2:Lookup) -->
                            <xsl:for-each select="./div[contains-token(@class, 'controls')]/span[1]"> <!-- make sure not to select span.help-inline -->
                                <xsl:result-document href="?." method="ixsl:replace-content">
                                    <xsl:call-template name="bs2:Lookup">
                                        <xsl:with-param name="class" select="'type-typeahead typeahead'"/>
                                        <xsl:with-param name="id" select="$id"/>
                                        <xsl:with-param name="list-class" select="'type-typeahead typeahead dropdown-menu'"/>
                                    </xsl:call-template>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
                
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onTypeaheadResourceLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="resource-uri" as="xs:anyURI"/>
        <xsl:param name="typeahead-span" as="element()"/>
        <!-- <xsl:param name="modal-form" as="element()?"/> -->

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <xsl:variable name="resource" select="key('resources', $resource-uri)" as="element()?"/>

                    <xsl:choose>
                        <xsl:when test="$resource">
                            <xsl:for-each select="$typeahead-span">
                                <xsl:variable name="typeahead" as="element()">
                                    <xsl:apply-templates select="$resource" mode="ldh:Typeahead"/>
                                </xsl:variable>
                                
                                <xsl:result-document href="?." method="ixsl:replace-content">
                                    <xsl:sequence select="$typeahead"/>
                                </xsl:result-document>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- resource description not found, render lookup input -->
                            <xsl:call-template name="bs2:Lookup">
                                <xsl:with-param name="class" select="'resource-typeahead typeahead'"/>
<!--                                <xsl:with-param name="id" select="'input-' || $uuid"/>-->
                                <xsl:with-param name="list-class" select="'resource-typeahead typeahead dropdown-menu'"/>
                                <xsl:with-param name="value" select="$resource-uri"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template name="onAddConstructor">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="control-group" as="element()"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="doc-id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
                    <xsl:variable name="form" as="element()">
                        <xsl:apply-templates select="//form[@class = 'form-horizontal']" mode="form">
                            <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="new-fieldset" select="$form//fieldset" as="element()"/>
                    
                    <xsl:for-each select="$control-group/ancestor::fieldset">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <!-- hydrate with properties, filter out property controls -->
                            <xsl:copy-of select="$new-fieldset/div[contains-token(@class, 'control-group')]"/>
                        </xsl:result-document>

                        <!-- show the "Actions" button -->
                        <xsl:for-each select=".//button[contains-token(@class, 'btn-edit-actions')]">
                            <ixsl:set-style name="display" select="'block'" object="."/>
                        </xsl:for-each>
                        
                        <!-- update the constructor/shape list -->
                        <xsl:for-each select=".//button[contains-token(@class, 'btn-edit-actions')]/following-sibling::ul">
                            <!-- remove the list item for owl:NamedIndividual -->
                            <xsl:for-each select="li[button[contains-token(@class, 'btn-edit-constructors')][ixsl:get(., 'dataset.resourceType') = '&owl;NamedIndividual']]">
                                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:for-each>
                    
                            <!-- append new "Edit constructor(s)" buttons -->
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <xsl:copy-of select="$new-fieldset//ul/li[button[contains-token(@class, 'btn-edit-constructors')]]"/>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:for-each>
                    
                    <!-- remove the following property controls -->
                    <xsl:for-each select="$control-group/following-sibling::div[contains-token(@class, 'control-group')][1][.//button[contains-token(@class, 'add-value')]]">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    <xsl:for-each select="$control-group">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:for-each>
                
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not construct class instance' ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>