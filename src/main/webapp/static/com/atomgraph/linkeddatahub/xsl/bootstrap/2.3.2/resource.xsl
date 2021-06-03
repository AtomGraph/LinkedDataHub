<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:lacl="&lacl;"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:geo="&geo;"
xmlns:void="&void;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>
    
    <xsl:param name="lacl:Agent" as="document-node()?"/>

    <!-- CSS -->
    
    <xsl:template use-when="system-property('xsl:product-name') = 'SAXON'" match="*[rdf:type/@rdf:resource][(rdf:type/@rdf:resource, rdf:type/@rdf:resource/apl:listSuperClasses(.)) = '&dh;Container']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'container-logo')"/>
    </xsl:template>

    <xsl:template use-when="system-property('xsl:product-name') = 'SAXON'" match="*[rdf:type/@rdf:resource][(rdf:type/@rdf:resource, rdf:type/@rdf:resource/apl:listSuperClasses(.)) = '&dh;Item']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'item-logo')"/>
    </xsl:template>

    <xsl:template use-when="system-property('xsl:product-name') eq 'Saxon-JS'" match="*[rdf:type/@rdf:resource = (resolve-uri('ns/domain/default#Root', $ldt:base), resolve-uri('ns/domain/default#Container', $ldt:base))]" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'container-logo')"/>
    </xsl:template>

    <xsl:template use-when="system-property('xsl:product-name') eq 'Saxon-JS'" match="*[rdf:type/@rdf:resource = (resolve-uri('ns/domain/default#Item', $ldt:base))]" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'item-logo')"/>
    </xsl:template>

    <!-- do not show text instead for logo icon for "things" -->
    <xsl:template match="*[foaf:isPrimaryTopicOf]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="$class"/>
    </xsl:template>
    
    <!-- BODY -->
    
    <!-- container/document blocks are hidden -->
    <xsl:template match="*[rdf:type/@rdf:resource][apl:listSuperClasses(rdf:type/@rdf:resource) = ('&dh;Container', '&dh;Item')]" mode="xhtml:Body" priority="1">
        <xsl:apply-templates select="key('resources', apl:content/@rdf:*)" mode="apl:ContentList"/>
        <xsl:apply-templates select="rdf:type/@rdf:resource/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource/key('resources', ., document(ac:document-uri(.)))" mode="apl:ContentList"/>
    </xsl:template>

    <!-- hide Content instances content body as they will be rendered in rdf:List order by the client-side apl:ContentList mode -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']" mode="xhtml:Body" priority="2"/>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="xhtml:Body">
        <div class="row-fluid">
            <xsl:apply-templates select="." mode="bs2:Left"/>

            <xsl:apply-templates select="." mode="bs2:Main"/>

            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
        
        <xsl:apply-templates select="key('resources', apl:content/@rdf:*)" mode="apl:ContentList"/>
        <xsl:apply-templates use-when="system-property('xsl:product-name') = 'SAXON'" select="rdf:type/@rdf:resource/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource/key('resources', ., document(ac:document-uri(.)))" mode="apl:ContentList"/>
    </xsl:template>
    
    <!-- MAIN -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Main">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span7'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Block"/>
        </div>
    </xsl:template>
    
    <!-- LEFT NAV -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Left" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'left-nav span2'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <!--<xsl:apply-templates mode="#current"/>-->

<!--            <xsl:if test="$ldt:base">  $lacl:Agent//@rdf:about 
                <div id="container-nav">
                    <div class="well well-small">
                        <ul class="nav nav-list">
                            <xsl:for-each select="$root-containers[not(. = $ldt:base)]">
                                <li>
                                    <xsl:if test="starts-with($ac:uri, .)">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>

                                     TO-DO: resolve as Linked Data resources? 
                                    <a href="{.}">
                                        <xsl:for-each select="key('resources', substring-before(substring-after(., $ldt:base), '/'), document('translations.rdf'))">
                                            <xsl:apply-templates select="." mode="apl:logo"/>
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of>
                                                <xsl:apply-templates select="." mode="ac:label"/>
                                            </xsl:value-of>
                                        </xsl:for-each>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>
                </div>
            </xsl:if>-->
        </div>
    </xsl:template>
    
    <!-- RIGHT NAV -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Right">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'right-nav span3'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:sequence select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:sequence select="$class"/></xsl:attribute>
            </xsl:if>

            <!--<xsl:apply-templates mode="#current"/>-->
        </div>
    </xsl:template>
    
    <!-- BLOCK -->
    
    <!-- match instances that have an apl:content property OR instances of types that have an an apl:template annotation property -->
    <xsl:template match="*[apl:content/@rdf:resource] | *[rdf:type/@rdf:resource[doc-available(ac:document-uri(.))]/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource[doc-available(ac:document-uri(.))]]" mode="bs2:Block">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
        
        <xsl:apply-templates select="key('resources', apl:content/@rdf:*)" mode="apl:ContentList"/>
        <xsl:apply-templates select="rdf:type/@rdf:resource/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource/key('resources', ., document(ac:document-uri(.)))" mode="apl:ContentList"/>
    </xsl:template>
    
    <!-- HEADER -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>

            <xsl:apply-templates select="." mode="bs2:Image"/>
            
            <xsl:apply-templates select="." mode="bs2:Actions"/>

            <h2>
                <xsl:apply-templates select="." mode="apl:logo"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="xhtml:Anchor"/>
            </h2>

            <p>
                <xsl:apply-templates select="." mode="ac:description"/>
            </p>

            <xsl:apply-templates select="." mode="bs2:TypeList"/>
        </div>
    </xsl:template>
    
    <!-- IMAGE -->
    
    <xsl:template match="*[*][@rdf:about]" mode="bs2:Image">
        <xsl:param name="class" select="'img-polaroid'" as="xs:string?"/>
        
        <xsl:variable name="image-uris" as="xs:anyURI*">
            <xsl:apply-templates select="." mode="ac:image"/>
        </xsl:variable>
        <xsl:variable name="this" select="." as="element()"/>
        
        <xsl:for-each select="$image-uris[1]">
            <a href="{$this/@rdf:about}" title="{ac:label($this)}">
                <img src="{.}" alt="{ac:label($this)}">
                    <xsl:if test="$class">
                        <xsl:attribute name="class" select="$class"/>
                    </xsl:if>
                </img>
            </a>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*[*][@rdf:nodeID]" mode="bs2:Image">
        <xsl:variable name="image-uris" as="xs:anyURI*">
            <xsl:apply-templates select="." mode="ac:image"/>
        </xsl:variable>
        <xsl:variable name="this" select="." as="element()"/>
        
        <xsl:for-each select="$image-uris[1]">
            <img src="{.}" alt="{ac:label($this)}" class="img-polaroid"/>
        </xsl:for-each>
    </xsl:template>

    <!-- ACTIONS -->

    <xsl:template match="*[@rdf:about]" mode="bs2:Actions" priority="1">
        <div class="pull-right">
            <button title="{key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))}">
                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
                
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:value-of>
            </button>
        </div>

        <xsl:variable name="logged-in" select="exists($lacl:Agent//@rdf:about)" as="xs:boolean" use-when="system-property('xsl:product-name') = 'SAXON'"/>
        <xsl:variable name="logged-in" select="not(ixsl:page()//div[tokenize(@class, ' ') = 'navbar']//a[tokenize(@class, ' ') = 'btn-primary'])" as="xs:boolean" use-when="system-property('xsl:product-name') eq 'Saxon-JS'"/>
        <xsl:if test="$logged-in">
            <!-- show delete button only for document resources -->
            <xsl:if test="ac:document-uri(@rdf:about) = @rdf:about">
                <div class="pull-right">
                    <form action="{ac:document-uri(@rdf:about)}?_method=DELETE" method="post">
                        <button class="btn btn-delete" type="submit">
                            <xsl:value-of use-when="system-property('xsl:product-name') = 'SAXON'">
                                <xsl:apply-templates select="key('resources', '&ac;Delete', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="ac:label"/>
                            </xsl:value-of>
                            <xsl:text use-when="system-property('xsl:product-name') eq 'Saxon-JS'">Delete</xsl:text> <!-- TO-DO: cache ontologies in localStorage -->
                        </button>
                    </form>
                </div>
            </xsl:if>

            <xsl:for-each select="key('resources', @rdf:about)/void:inDataset/@rdf:resource">
                <xsl:if test="not($ac:mode = '&ac;EditMode')">
                    <div class="pull-right">
                        <xsl:variable name="graph-uri" select="ac:build-uri(ac:document-uri(.), map{ 'mode': ('&ac;EditMode', '&ac;ModalMode') })" as="xs:anyURI"/>
                        <button title="{ac:label(key('resources', 'nav-bar-action-edit-graph-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                            <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri(xs:anyURI('&ac;'))))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn'"/>
                            </xsl:apply-templates>

                            <input type="hidden" value="{$graph-uri}"/>
                        </button>
                    </div>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:Actions"/>
    
    <!-- TIMESTAMP -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Timestamp">
        <!-- TO-DO: property labels? -->
        <xsl:variable name="min-created-datetime" select="min((../../dct:created/text()[. castable as xs:date]/xs:date(.), ../../dct:created/text()[. castable as xs:dateTime]/xs:dateTime(.)))" as="item()?"/>
        <xsl:apply-templates select="dct:created/text()[. = $min-created-datetime]"/>
        <xsl:text> </xsl:text>
        <xsl:variable name="max-modified-datetime" select="max((../../dct:modified/text()[. castable as xs:date]/xs:date(.), ../../dct:modified/text()[. castable as xs:dateTime]/xs:dateTime(.)))" as="item()?"/>
        <xsl:apply-templates select="dct:modified/text()[. = $max-modified-datetime]"/>
    </xsl:template>
    
    <!-- TYPE LIST -->

    <xsl:template match="*[sioc:has_parent] | *[sioc:has_container]" mode="bs2:TypeList" priority="0.8"/>

    <xsl:template match="*[@rdf:about or @rdf:nodeID][rdf:type/@rdf:resource]" mode="bs2:TypeList">
        <ul class="inline">
            <xsl:for-each select="rdf:type/@rdf:resource">
                <xsl:sort select="ac:object-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:sort select="ac:object-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'Saxon-JS'"/>

                <!-- TO-DO: find a way to use only cached documents, otherwise this will execute a synchronous HTTP request which slows down the UI -->
                <li>
                    <xsl:apply-templates select="."/>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    <!-- CONTENT -->
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content'][rdf:first[@rdf:parseType = 'Literal']/xhtml:div]" mode="apl:ContentList" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'content xhtml-content span7 offset2'" as="xs:string?"/>
        
        <div class="row-fluid">
            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>

                <!--  remove XHTML namespace -->
                <!-- <xsl:copy-of copy-namespaces="no" select="sioc:content/xhtml:div"/> -->
                <xsl:apply-templates select="rdf:first[@rdf:parseType = 'Literal']/xhtml:div" mode="apl:XHTMLContent"/>
            </div>
        </div>

        <!-- process the next apl:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content'][rdf:first/@rdf:resource]" mode="apl:ContentList" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'content resource-content span7'" as="xs:string?"/>
        
        <div class="row-fluid">
            <div class="left-nav span2"></div>
            
            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
                </xsl:if>

                <!--<object data="{ac:build-uri(xs:anyURI(rdf:first/@rdf:resource), map{ 'mode': '&aplt;ObjectMode' })}" type="text/html"></object>-->
                <input name="href" type="hidden" value="{rdf:first/@rdf:resource}"/>
            </div>
            
            <div class="right-nav span3"></div>
        </div>
        
        <!-- process the next apl:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*" mode="apl:ContentList"/>

    <!-- FORM -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- FORM CONTROL -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:FormControl">
        <xsl:param name="id" select="concat('form-control-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="violations" select="key('violations-by-value', */@rdf:resource) | key('violations-by-root', (@rdf:about, @rdf:nodeID))" as="element()*"/>
        <xsl:param name="forClass" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>
        <xsl:param name="template-doc" select="if ($ldt:ontology and $ldt:base) then ac:construct-doc($ldt:ontology, $forClass, $ldt:base) else ()" as="document-node()?"/>
        <xsl:param name="template" select="$template-doc/rdf:RDF/*[@rdf:nodeID][every $type in rdf:type/@rdf:resource satisfies current()/rdf:type/@rdf:resource = $type]" as="element()*"/>
        <xsl:param name="template-properties" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="traversed-ids" select="@rdf:*" as="xs:string*" tunnel="yes"/>
        <xsl:param name="show-subject" select="false()" as="xs:boolean" tunnel="yes"/>

        <fieldset>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <div class="btn-group pull-right">
                <button type="button" class="btn btn-large pull-right btn-remove-resource" title="Remove this resource">&#x2715;</button>
            </div>

            <xsl:if test="$legend">
                <legend>
                    <xsl:value-of select="ac:label(.)"/>
                </legend>
            </xsl:if>

            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current">
                <xsl:with-param name="type" select="if ($show-subject) then 'text' else 'hidden'"/>
            </xsl:apply-templates>
    
            <xsl:apply-templates select="." mode="bs2:TypeControl"/>

            <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
            
            <!-- create inputs for both resource description and constructor template properties -->
            <xsl:apply-templates select="* | $template/*[not(concat(namespace-uri(), local-name()) = current()/*/concat(namespace-uri(), local-name()))][not(self::rdf:type)][not(self::foaf:isPrimaryTopicOf)]" mode="#current">
                <!-- move required properties up -->
                <xsl:sort select="not(preceding-sibling::*[concat(namespace-uri(), local-name()) = current()/concat(namespace-uri(), local-name())]) and (if (../rdf:type/@rdf:resource and $ldt:ontology) then (key('resources', key('resources', (../rdf:type/@rdf:resource, ../rdf:type/@rdf:resource/apl:listSuperClasses(.)))/spin:constraint/(@rdf:resource|@rdf:nodeID))[rdf:type/@rdf:resource = '&apl;MissingPropertyValue'][sp:arg1/@rdf:resource = current()/concat(namespace-uri(), local-name())]) else true())" order="descending"/>
                <xsl:sort select="ac:property-label(.)"/>
                <xsl:with-param name="violations" select="$violations"/>
                <xsl:with-param name="template-doc" select="$template-doc"/>
                <xsl:with-param name="traversed-ids" select="$traversed-ids" tunnel="yes"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="$template/*[1]" mode="bs2:PropertyControl"> <!-- [not(self::rdf:type)][not(self::foaf:isPrimaryTopicOf)] -->
                <xsl:with-param name="template" select="$template"/>
                <xsl:with-param name="forClass" select="$forClass"/>
                <xsl:with-param name="required" select="true()"/>
            </xsl:apply-templates>
        </fieldset>
    </xsl:template>
    
    <!-- TYPE CONTROL -->
    
    <!-- container/document types are hidden -->
    <xsl:template match="*[rdf:type/@rdf:resource][$ldt:ontology][apl:listSuperClasses(rdf:type/@rdf:resource) = ('&dh;Container', '&dh;Item')]" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- turn off blank node resources from constructor graph -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][rdf:type/starts-with(@rdf:resource, '&xsd;')] | *[@rdf:nodeID][$ac:forClass][rdf:type/@rdf:resource = '&rdfs;Resource']" mode="bs2:FormControl" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:TypeControl">
        <xsl:param name="forClass" select="if ($ldt:base) then resolve-uri('admin/ns#Class', $ldt:base) else ()" as="xs:anyURI?"/> <!-- allow subclasses of lsm:Class? -->
        <xsl:param name="hidden" select="false()" as="xs:boolean"/>

        <xsl:apply-templates mode="#current">
            <xsl:sort select="ac:label(..)"/>
            <xsl:with-param name="forClass" select="$forClass"/>
            <xsl:with-param name="hidden" select="$hidden"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- TYPEAHEAD -->
    
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
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', foaf:primaryTopic/@rdf:resource)" mode="ac:label"/>
                        </xsl:value-of>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of>
                            <xsl:apply-templates select="." mode="ac:label"/>
                        </xsl:value-of>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
            <span class="caret pull-right"></span>
            <input type="hidden" name="ou" value="{@rdf:about}"/>
        </button>
    </xsl:template>
    
    <!-- VIOLATION -->

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;URISyntaxViolation']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;URISyntaxViolation', document('&apl;'))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of select="rdfs:label"/>
        </div>
    </xsl:template>
        
    <!-- take constraint labels from sitemap instead of response, if possible -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&spin;ConstraintViolation', document('&spin;'))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="." mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Exception"/>

    <!-- OBJECT -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Object"/>

</xsl:stylesheet>