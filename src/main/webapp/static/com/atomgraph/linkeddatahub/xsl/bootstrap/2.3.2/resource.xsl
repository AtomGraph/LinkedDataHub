<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
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
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
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
    
    <!-- BLOCK -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Block">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
        
        <xsl:apply-templates select="." mode="apl:ContentList"/>
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
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content xhtml-content'" as="xs:string?"/>
        
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

        <!-- process the next apl:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content'][rdf:first/@rdf:resource]" mode="apl:ContentList" priority="2">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'content resource-content'" as="xs:string?"/>
        
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
        
        <!-- process the next apl:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>
    
    <!-- match instances of types that have an apl:template annotation property -->
    <xsl:template match="*[rdf:type/@rdf:resource[doc-available(ac:document-uri(.))]/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource[doc-available(ac:document-uri(.))]]" mode="apl:ContentList" priority="2">
        <xsl:apply-templates select="rdf:type/@rdf:resource/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource/key('resources', ., document(ac:document-uri(.)))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*" mode="apl:ContentList"/>

</xsl:stylesheet>