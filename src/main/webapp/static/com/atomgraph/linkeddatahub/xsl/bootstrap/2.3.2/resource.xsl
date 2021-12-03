<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY aplt   "https://w3id.org/atomgraph/linkeddatahub/templates#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
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
xmlns:aplt="&aplt;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
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
    
    <xsl:param name="acl:Agent" as="document-node()?"/>

    <!-- LOGO -->

    <xsl:template match="*[rdf:type/@rdf:resource = ('&def;Root', '&def;Container')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-container')"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&def;Item']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-item')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;ConstructMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-action')"/>
        <!-- <xsl:sequence select="ac:label(.)"/> -->
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&def;Container']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-container')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&def;Item']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-item')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&def;DydraService', '&def;GenericService')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-service')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&def;Describe', '&def;Construct', '&def;Select', '&def;Ask')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-query')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&def;File']" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-file')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&def;CSVImport', '&def;RDFImport')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-import')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = ('&def;ResultSetChart', '&def;GraphChart')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-chart')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&apl;URISyntaxViolation', '&spin;ConstraintViolation', '&apl;ResourceExistsException')]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'violation')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = ('latest', 'files', 'imports', 'geo', 'queries', 'charts', 'services')]" mode="apl:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', @rdf:nodeID)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'toggle-content']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-toggle-content')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&aplt;Ban']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-ban')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
        
    <xsl:template match="*[@rdf:about = '&ac;Delete']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-delete')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'skolemize']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-skolemize')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;Export']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-export')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'settings']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-settings')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'save']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-save')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'close']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-close')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'reset']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-reset')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'search']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-search')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'notifications']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-notifications')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&foaf;Agent']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-agent')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ReadMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-read')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;MapMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-map')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;GraphMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-graph')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;QueryEditorMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-query')"/>
        <text>Query editor</text>
<!--        <xsl:sequence select="ac:label(.)"/>-->
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&acl;Access']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-acl')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][lacl:requestAccess/@rdf:resource]" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'access-required')"/>
        <xsl:sequence select="ac:label(.)"/>
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
        </div>
    </xsl:template>

    <!-- BLOCK ROW -->
    
    <!-- mark query instances as .resource-content which is then rendered by client.xsl -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&def;Select', '&adm;Select', '&sp;Select')][sp:text]" mode="bs2:RowBlock" priority="1">
        <xsl:param name="content-uri" select="@rdf:about" as="xs:anyURI"/>

        <xsl:next-match>
            <xsl:with-param name="content-uri" select="$content-uri"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- mark chart instances as .resource-content which is then rendered by client.xsl -->
    <xsl:template match="*[@rdf:about][spin:query/@rdf:resource][apl:chartType/@rdf:resource]" mode="bs2:RowBlock" priority="1">
        <xsl:param name="content-uri" select="@rdf:about" as="xs:anyURI"/>

        <xsl:next-match>
            <xsl:with-param name="content-uri" select="$content-uri"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- embed file content -->
    <xsl:template match="*[@rdf:about][dct:format]" mode="bs2:RowBlock" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="content-uri" as="xs:anyURI?"/>
        <xsl:param name="class" select="if ($content-uri) then 'row-fluid content resource-content' else 'row-fluid'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:sequence select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:sequence select="$class"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$content-uri">
                <xsl:attribute name="data-content-uri" select="$content-uri"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Left"/>

            <div class="span7">
                <xsl:apply-templates select="." mode="bs2:Header"/>

                <xsl:apply-templates select="." mode="bs2:PropertyList"/>
            
                <xsl:variable name="media-type" select="substring-after(dct:format[1]/@rdf:resource, 'http://www.sparontologies.net/mediatype/')" as="xs:string"/>
                <object data="{@rdf:about}" type="{$media-type}"></object>
            </div>

            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
    </xsl:template>
    
    <!-- hide the current document resource -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&def;Root', '&def;Container', '&def;Item')]" mode="bs2:RowBlock" priority="1"/>

    <!-- hide Content resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']" mode="bs2:RowBlock" priority="2"/>

    <!-- hide inlined blank node resources from the main block flow -->
    <xsl:template match="*[*][key('resources', @rdf:nodeID)][count(key('predicates-by-object', @rdf:nodeID)[not(self::foaf:primaryTopic)]) = 1]" mode="bs2:RowBlock" priority="1">
        <xsl:param name="display" select="false()" as="xs:boolean" tunnel="yes"/>
        
        <xsl:if test="$display">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:RowBlock">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="content-uri" as="xs:anyURI?"/>
        <xsl:param name="class" select="'row-fluid'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:sequence select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:sequence select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Left"/>

            <div class="span7">
                <xsl:apply-templates select="." mode="bs2:Block"/>
                
                <xsl:if test="$content-uri">
                    <div id="{$id || '-content'}" data-content-uri="{$content-uri}"/>
                </xsl:if>
            </div>

            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
        
        <xsl:apply-templates select="rdf:type/@rdf:resource/key('resources', ., document(ac:document-uri(.)))/apl:template/@rdf:resource/key('resources', ., document(ac:document-uri(.)))" mode="apl:ContentList"/>
    </xsl:template>
    
    <!-- TO-DO: override other modes -->
    
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
                <xsl:apply-templates select="." mode="xhtml:Anchor">
                    <xsl:with-param name="class" as="xs:string?">
                        <xsl:apply-templates select="." mode="apl:logo"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </h2>

            <p>
                <xsl:apply-templates select="." mode="ac:description"/>
            </p>

            <xsl:apply-templates select="." mode="bs2:TypeList"/>
        </div>
    </xsl:template>

    <!-- PROPERTY LIST -->
    
    <!-- suppress types in property list - we show them in the bs2:Header instead -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:PropertyList"/>

    <!-- IMAGE -->
    
    <!-- TO-DO: move down to Web-Client -->
    <xsl:template match="*[*][@rdf:about]" mode="bs2:Image">
        <xsl:param name="class" as="xs:string?"/>
        
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

    <!-- TO-DO: move down to Web-Client -->
    <xsl:template match="*[*][@rdf:nodeID]" mode="bs2:Image">
        <xsl:param name="class" as="xs:string?"/>

        <xsl:variable name="image-uris" as="xs:anyURI*">
            <xsl:apply-templates select="." mode="ac:image"/>
        </xsl:variable>
        <xsl:variable name="this" select="." as="element()"/>
        
        <xsl:for-each select="$image-uris[1]">
            <img src="{.}" alt="{ac:label($this)}">
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
                </xsl:if>
            </img>
        </xsl:for-each>
    </xsl:template>

    <!-- ACTIONS -->

    <xsl:template match="*[@rdf:about]" mode="bs2:Actions" priority="1">
        <div class="pull-right">
            <button title="{key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))}" type="button">
                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
                
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:value-of>
            </button>
        </div>
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
    
    <!-- CONTENT LIST -->
    
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
        <xsl:param name="class" select="'row-fluid content resource-content'" as="xs:string?"/>
        
        <!-- @data-content-uri is used to retrieve $content-uri in client.xsl -->
        <div data-content-uri="{rdf:first/@rdf:resource}">
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
                    
            <div class="left-nav span2"></div>
            
            <div class="span7">
                <xsl:if test="doc-available(ac:document-uri(rdf:first/@rdf:resource))">
                    <xsl:apply-templates select="key('resources', rdf:first/@rdf:resource, document(ac:document-uri(rdf:first/@rdf:resource)))" mode="apl:ContentHeader"/>
                </xsl:if>
            </div>
            
            <div class="right-nav span3"></div>
        </div>
        
        <!-- process the next apl:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*" mode="apl:ContentList"/>

    <xsl:template match="*[*][@rdf:about]" mode="apl:ContentHeader" priority="2">
        <h2>
            <xsl:apply-templates select="." mode="xhtml:Anchor">
                <xsl:with-param name="class" as="xs:string?">
                    <xsl:apply-templates select="." mode="apl:logo"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </h2>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="bs2:ConstructorListItem">
        <xsl:param name="with-label" select="true()" as="xs:boolean"/>

        <!-- the class document has to be available -->
        <xsl:if test="doc-available(ac:document-uri(@rdf:about))">
            <li>
                <xsl:apply-templates select="." mode="bs2:Constructor">
                    <xsl:with-param name="id" select="()"/>
                    <xsl:with-param name="with-label" select="$with-label"/>
                </xsl:apply-templates>
            </li>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about]" mode="bs2:Constructor">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="subclasses" as="attribute()*"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:param name="modal-form" select="false()" as="xs:boolean"/>
        <xsl:variable name="forClass" select="@rdf:about" as="xs:anyURI"/>

        <xsl:if test="doc-available(ac:document-uri($forClass))">
            <!-- this is used for typeahead's FILTER ?Type -->
            <input type="hidden" class="forClass" value="{$forClass}"/>

            <!-- if $forClass subclasses are provided, render a dropdown with multiple constructor choices. Otherwise, only render a single constructor button for $forClass -->
            <xsl:choose>
                <xsl:when test="exists($subclasses)">
                    <div class="btn-group">
                        <button type="button">
                            <xsl:choose>
                                <xsl:when test="$with-label">
                                    <xsl:apply-templates select="." mode="apl:logo">
                                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                    </xsl:apply-templates>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of>
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </xsl:value-of>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="apl:logo">
                                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                    </xsl:apply-templates>
                                </xsl:otherwise>
                            </xsl:choose>
                        </button>
                        <ul class="dropdown-menu">
                            <xsl:variable name="self-and-subclasses" select="key('resources', $forClass, document(ac:document-uri($forClass))), $subclasses/.." as="element()*"/>

                            <!-- apply on the "deepest" subclass of $forClass and its subclasses -->
                            <!-- eliminate matches where a class is a subclass of itself (happens in inferenced ontology models) -->
                            <xsl:for-each-group select="$self-and-subclasses[let $about := @rdf:about return not($about = $self-and-subclasses[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)]" group-by="@rdf:about">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>

                                <!-- won't traverse blank nodes, only URI resources -->
                                <li>
                                    <button type="button" class="btn add-constructor" title="{current-grouping-key()}">
                                        <xsl:if test="$id">
                                            <xsl:attribute name="id" select="$id"/>
                                        </xsl:if>
                                        <!-- we don't want to give a name to this input as it would be included in the RDF/POST payload -->
                                        <input type="hidden" class="forClass" value="{@rdf:about}"/>
                                        
                                        <xsl:value-of>
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                </li>
                            </xsl:for-each-group>
                        </ul>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <button type="button" title="{@rdf:about}">
                        <xsl:if test="$id">
                            <xsl:attribute name="id" select="$id"/>
                        </xsl:if>

                        <xsl:choose>
                            <xsl:when test="$with-label">
                                <xsl:apply-templates select="." mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn add-constructor'"/>
                                </xsl:apply-templates>

                                <xsl:value-of>
                                    <xsl:apply-templates select="." mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn add-constructor'"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- we don't want to give a name to this input as it would be included in the RDF/POST payload -->
                        <input type="hidden" class="forClass" value="{@rdf:about}"/>
                    </button>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- FORM -->

    <!-- hide constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation'] | *[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Form" priority="2"/>

    <!-- hide object blank nodes (that only have a single rdf:type property) from constructed models -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][not(* except rdf:type)]" mode="bs2:Form" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- FORM CONTROL -->

    <!-- turn off blank node resources from constructor graph -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][rdf:type/starts-with(@rdf:resource, '&xsd;')] | *[@rdf:nodeID][$ac:forClass][rdf:type/@rdf:resource = '&rdfs;Resource']" mode="bs2:FormControl" priority="2"/>

    <!-- turn off default form controls for rdf:type as we are handling it specially with bs2:TypeControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:FormControl" priority="1"/>
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:FormControl">
        <xsl:param name="id" select="concat('form-control-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="violations" select="key('violations-by-value', */@rdf:resource) | key('violations-by-root', (@rdf:about, @rdf:nodeID))" as="element()*"/>
        <xsl:param name="forClass" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>
        <xsl:param name="template-doc" select="ac:construct($ldt:ontology, $forClass, $ldt:base)" as="document-node()?"/>
        <xsl:param name="template" select="$template-doc/rdf:RDF/*[@rdf:nodeID][every $type in rdf:type/@rdf:resource satisfies current()/rdf:type/@rdf:resource = $type]" as="element()*"/>
        <xsl:param name="template-properties" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="traversed-ids" select="@rdf:*" as="xs:string*" tunnel="yes"/>
        <xsl:param name="show-subject" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>

        <fieldset>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:choose>
                <xsl:when test="$legend">
                    <legend>
                        <xsl:if test="not($required)">
                            <!-- the button has to be inside <legend> for it to float to the top/right corner properly -->
                            <div class="btn-group pull-right">
                                <button type="button" class="btn btn-large pull-right btn-remove-resource" title="Remove this resource"></button>
                            </div>
                        </xsl:if>

                        <!-- "Copy URI" button -->
                        <button title="{key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))}" type="button">
                            <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn'"/>
                            </xsl:apply-templates>

                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        
                        <xsl:value-of select="ac:label(.)"/>
                    </legend>
                </xsl:when>
                <xsl:when test="not($required)">
                    <div class="btn-group pull-right">
                        <button type="button" class="btn btn-large pull-right btn-remove-resource" title="Remove this resource"></button>
                    </div>
                </xsl:when>
            </xsl:choose>

            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current">
                <xsl:with-param name="type" select="if ($show-subject) then 'text' else 'hidden'"/>
            </xsl:apply-templates>
    
            <xsl:apply-templates select="." mode="bs2:TypeControl"/>

            <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
            
            <xsl:variable name="types" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>
            <!-- create inputs for both resource description and constructor template properties -->
            <xsl:apply-templates select="* | $template/*[not(concat(namespace-uri(), local-name()) = current()/*/concat(namespace-uri(), local-name()))][not(self::rdf:type)][not(self::foaf:isPrimaryTopicOf)]" mode="#current">
                <!-- move required properties up -->
                <xsl:sort select="exists(document(ac:document-uri($types))/key('resources', key('resources', $types)/spin:constraint/(@rdf:resource|@rdf:nodeID))[rdf:type/@rdf:resource = '&apl;MissingPropertyValue'][sp:arg1/@rdf:resource = current()/concat(namespace-uri(), local-name())])" order="descending"/>
                <xsl:sort select="ac:property-label(.)"/>
                <xsl:with-param name="violations" select="$violations"/>
                <xsl:with-param name="template-doc" select="$template-doc"/>
                <xsl:with-param name="traversed-ids" select="$traversed-ids" tunnel="yes"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="$template/*[1]" mode="bs2:PropertyControl">
                <xsl:with-param name="template" select="$template"/>
                <xsl:with-param name="forClass" select="$forClass"/>
                <xsl:with-param name="required" select="true()"/>
            </xsl:apply-templates>
        </fieldset>
    </xsl:template>
    
    <!-- TYPE CONTROL -->

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:TypeControl">
        <xsl:param name="forClass" select="xs:anyURI('&adm;Class')" as="xs:anyURI?"/> <!-- allow subclasses of lsm:Class? -->
        <xsl:param name="hidden" select="false()" as="xs:boolean"/>

        <xsl:apply-templates mode="#current">
            <xsl:sort select="ac:label(..)"/>
            <xsl:with-param name="forClass" select="$forClass"/>
            <xsl:with-param name="hidden" select="$hidden"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- PROPERTY CONTROL -->
    
    <!-- hide property dropdown -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/*" mode="bs2:PropertyControl" priority="1"/>

    <!-- TYPE CONTROL -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:ContentControl">
        <div class="control-group">
            <span class="control-label">
                <select class="input-medium">
                    <option>Resource content</option>
                    <option>HTML content</option>
                </select>
            </span>

            <div class="controls">
                <button type="button">[+]</button>
            </div>
        </div>
    </xsl:template>
    
    <!-- TYPEAHEAD -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="apl:Typeahead">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'btn add-typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="title" select="(@rdf:about, @rdf:nodeID)[1]" as="xs:string?"/>

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
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </span>
            <span class="caret pull-right"></span>
            
            <xsl:if test="@rdf:about">
                <input type="hidden" name="ou" value="{@rdf:about}"/>
            </xsl:if>
            <xsl:if test="@rdf:nodeID">
                <input type="hidden" name="ob" value="{@rdf:nodeID}"/>
            </xsl:if>
        </button>
    </xsl:template>
    
    <!-- VIOLATION -->

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;URISyntaxViolation']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;URISyntaxViolation', document(ac:document-uri('&apl;')))" mode="apl:logo">
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

            <xsl:apply-templates select="key('resources', '&spin;ConstraintViolation', document(ac:document-uri('&spin;')))" mode="apl:logo">
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