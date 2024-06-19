<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:sp="&sp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <xsl:template match="*[@rdf:about = '&sp;Ask']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'ask-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Select']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'select-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Describe']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'describe-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Construct']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'construct-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <!-- ROW: WRONG IMPORT PRECEDENCE! -->
    
<!--    <xsl:template match="*[sp:text/text()]" mode="bs2:Row" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid post-construct'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="content-value" as="xs:anyURI?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="about" select="$about"/>
            <xsl:with-param name="typeof" select="$typeof"/>
            <xsl:with-param name="content-value" select="$content-value"/>
            <xsl:with-param name="mode" select="$mode"/>
        </xsl:next-match>
    </xsl:template>-->
    
    <!-- BLOCK MODE -->

    <xsl:template match="*[sp:text/text()]" mode="bs2:Block">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" select="'id' || ac:uuid()" as="xs:string?"/>
        <xsl:param name="class" select="'sparql-query-form form-horizontal'" as="xs:string?"/> <!-- .sparql-query-form will trigger ldh:PostConstruct and initialize YASQE -->
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="textarea-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service-uri" select="ldh:service/@rdf:resource/xs:anyURI(.)" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="sp:text" as="xs:string"/>
        <xsl:param name="show-properties" select="false()" as="xs:boolean"/>
        <xsl:param name="forClass" select="xs:anyURI('&sd;Service')" as="xs:anyURI"/>
        <xsl:message>
            $service-uri: <xsl:value-of select="$service-uri"/>
        </xsl:message>
        
        <xsl:apply-templates select="." mode="bs2:Header"/>
        
        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset" select="$accept-charset"/>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype" select="$enctype"/>
            </xsl:if>

            <div class="control-group">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="value" select="'&ldh;service'"/>
                </xsl:call-template>
                
                <label class="control-label">
                    <xsl:apply-templates select="key('resources', '&ldh;service', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                </label>
                <div class="controls">
                    <xsl:choose>
                        <xsl:when test="$service-uri">
                            <!-- apply templates if server-side -->
                            <xsl:apply-templates select="key('resources', $service-uri, document(ac:document-uri($service-uri)))" mode="ldh:Typeahead" use-when="system-property('xsl:product-name') = 'SAXON'">
                                <xsl:with-param name="forClass" select="$forClass"/>
                            </xsl:apply-templates>
                            
                            <xsl:if test="true()" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
                                <!-- need to explicitly request RDF/XML, otherwise we get HTML -->
                                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:document-uri($service-uri))" as="xs:anyURI"/>
                                <xsl:message>
                                    $request-uri: <xsl:value-of select="$request-uri"/>
                                </xsl:message>
                                <!-- TO-DO: refactor asynchronously -->
                                <xsl:apply-templates select="key('resources', $service-uri, document($request-uri))" mode="ldh:Typeahead">
                                    <xsl:with-param name="forClass" select="$forClass"/>
                                </xsl:apply-templates>
                                
                                <!--
                                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $query-uri)" as="xs:anyURI"/>
                                <xsl:variable name="request" as="item()*">
                                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                        <xsl:call-template name="onQueryServiceLoad">
                                            <xsl:with-param name="container" select="$container"/>
                                            <xsl:with-param name="forClass" select="$forClass"/>
                                            <xsl:with-param name="service-uri" select="$service-uri"/>
                                        </xsl:call-template>
                                    </ixsl:schedule-action>
                                </xsl:variable>
                                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                                -->
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="bs2:Lookup">
                                <xsl:with-param name="forClass" select="$forClass"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </div>

            <textarea name="query" class="span12 sparql-query-string" rows="15">
                <xsl:if test="$textarea-id">
                    <xsl:attribute name="id" select="$textarea-id"/>
                </xsl:if>

                <xsl:value-of select="$query"/>
            </textarea>

            <div class="form-actions">
                <button type="submit">
                    <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn btn-primary btn-run-query'"/>
                    </xsl:apply-templates>

                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
                <button type="button" class="btn btn-primary btn-open-query">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'open', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
                <button type="button" class="btn btn-primary btn-save btn-save-query">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                    </xsl:value-of>
                </button>
            </div>
        </form>
        
        <xsl:if test="$show-properties">
            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="onQueryServiceLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="forClass" as="xs:anyURI"/>
        <xsl:param name="service-uri" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:variable name="results" select="?body" as="document-node()"/>

                <xsl:message>
                    $service: <xsl:value-of select="serialize(key('resources', $service-uri, $results))"/>
                </xsl:message>

                <xsl:result-document href="?." method="ixsl:append-content">
                    <xsl:apply-templates select="key('resources', $service-uri, $results)" mode="ldh:Typeahead">
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="response" select="." as="map(*)"/>
                <!-- error response - could not load service -->
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Error loading service:</strong>
                            <pre>
                                <xsl:value-of select="$response?message"/>
                            </pre>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- FORM CONTROL MODE -->

    <xsl:template match="sp:text/text() | sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'sparql-query-string'" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="name" select="'ol'" as="xs:string"/>
        <xsl:param name="rows" select="10" as="xs:integer"/>
        <xsl:param name="style" select="'font-family: monospace;'" as="xs:string"/>

        <textarea name="{$name}" id="{generate-id()}" rows="{$rows}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$style">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>
            
            <xsl:if test="self::text()">
                <xsl:value-of select="."/>
            </xsl:if>
        </textarea>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/text() | sp:text/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <span class="help-inline">Literal</span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/@rdf:datatype" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:next-match>
    </xsl:template>
    
</xsl:stylesheet>