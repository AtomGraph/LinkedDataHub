<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ldht   "https://w3id.org/atomgraph/linkeddatahub/templates#">
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
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:lacl="&lacl;"
xmlns:ldh="&ldh;"
xmlns:ldht="&ldht;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:sd="&sd;"
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
    
    <xsl:param name="foaf:Agent" as="document-node()?"/>

    <!-- LABEL -->

    <!-- TO-DO: move to owl.xsl -->
    <xsl:template match="*[@rdf:about = '&owl;NamedIndividual']" mode="ac:label">
        <xsl:text>Instance</xsl:text>
    </xsl:template>
    
    <!-- LOGO -->

    <xsl:template match="*[rdf:type/@rdf:resource = ('&def;Root', '&dh;Container')]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-container')"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&dh;Item']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-item')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&ac;ConstructMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'create-action')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&dh;Container']" mode="ldh:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-container')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&dh;Item']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-item')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&lapp;Application']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-app')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sd;Service']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-service')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&sp;Describe', '&sp;Construct', '&sp;Select', '&sp;Ask')]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-query')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&nfo;FileDataObject']" mode="ldh:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-file')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&ldh;CSVImport', '&ldh;RDFImport')]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-import')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = ('&ldh;ResultSetChart', '&ldh;GraphChart')]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-chart')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = ('&ldh;URISyntaxViolation', '&spin;ConstraintViolation', '&ldh;ResourceExistsException')]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'violation')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = ('latest', 'files', 'imports', 'geo', 'queries', 'charts', 'services')]" mode="ldh:logo" priority="1">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', @rdf:nodeID)"/>
    </xsl:template>

<!--    <xsl:template match="*[@rdf:nodeID = 'toggle-content']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-toggle-content')"/>
    </xsl:template>-->
    
    <xsl:template match="*[@rdf:about = '&ldht;Ban']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-ban')"/>
    </xsl:template>
        
    <xsl:template match="*[@rdf:about = '&ac;Delete']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-delete')"/>
    </xsl:template>

<!--    <xsl:template match="*[@rdf:nodeID = 'skolemize']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-skolemize')"/>
    </xsl:template>-->
    
    <xsl:template match="*[@rdf:about = '&ac;Export']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-export')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'settings']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-settings')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'save']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-save')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'close']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-close')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'reset']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-reset')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'search']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-search')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'applications']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-apps')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'notifications']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-notifications')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'add']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-add')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'remove']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-remove-property')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;EditMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-edit')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'copy-uri']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-copy-uri')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:nodeID = 'save-as']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-save-as')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about = '&foaf;Agent']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-agent')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;ReadMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-read')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;MapMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-map')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;GraphMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-graph')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;QueryEditorMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-query')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&acl;Access']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-acl')"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&http;Response'][lacl:requestAccess/@rdf:resource]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'access-required')"/>
    </xsl:template>

    <xsl:template match="*" mode="ldh:logo" priority="0">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:if test="$class">
            <xsl:attribute name="class" select="$class"/>
        </xsl:if>
    </xsl:template>

    <!-- BREADCRUMBS -->

    <xsl:template match="*[@rdf:about]" mode="bs2:BreadCrumbListItem">
        <xsl:param name="leaf" select="true()" as="xs:boolean"/>
        
        <li>
            <xsl:variable name="class" as="xs:string?">
                <xsl:apply-templates select="." mode="ldh:logo"/>
            </xsl:variable>
            <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor">
                <xsl:with-param name="id" select="()"/>
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>

            <xsl:if test="not($leaf)">
                <span class="divider">/</span>
            </xsl:if>
        </li>
    </xsl:template>
    
    <!-- LEFT NAV -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Left" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'left-nav span2'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
        </div>
    </xsl:template>
    
    <!-- RIGHT NAV -->
    
    <!-- empty right nav for content instances -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content'][rdf:first/@rdf:resource]" mode="bs2:Right" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'right-nav span3'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <!-- will be hydrated by client.xsl -->
        </div>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Right">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'right-nav span3'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <xsl:if test="@rdf:about">
                <div class="well well-small sidebar-nav backlinks-nav">
                    <h2 class="nav-header btn">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'backlinks', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>

                        <span class="caret caret-reversed pull-right"></span>
                        <input type="hidden" name="uri" value="{@rdf:about}"/>
                    </h2>
                    <!-- will be hydrated by client.xsl -->
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- MODE TABS -->
    
    <xsl:template match="*[@rdf:about]" mode="bs2:ModeTabsItem">
        <xsl:param name="active" as="xs:boolean"/>
        <xsl:param name="mode-classes" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'&ldh;ContentMode'" select="'content-mode'"/>
                <xsl:map-entry key="'&ac;ReadMode'" select="'read-mode'"/>
                <xsl:map-entry key="'&ac;MapMode'" select="'map-mode'"/>
                <xsl:map-entry key="'&ac;ChartMode'" select="'chart-mode'"/>
                <xsl:map-entry key="'&ac;GraphMode'" select="'graph-mode'"/>
            </xsl:map>
        </xsl:param>
        <xsl:param name="class" select="map:get($mode-classes, @rdf:about) || (if ($active) then ' active' else ())" as="xs:string?"/>

        <li>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <a href="{ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ac:uri(), xs:anyURI(@rdf:about))}">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </a>
        </li>
    </xsl:template>
    
    <!-- BLOCK ROW -->
    
    <!-- mark query instances as .resource-content which is then rendered by client.xsl -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&sp;Select'][sp:text]" mode="bs2:RowBlock" priority="1">
        <xsl:param name="content-uri" select="@rdf:about" as="xs:anyURI"/>

        <xsl:next-match>
            <xsl:with-param name="content-uri" select="$content-uri"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- mark chart instances as .resource-content which is then rendered by client.xsl -->
    <xsl:template match="*[@rdf:about][spin:query/@rdf:resource][ldh:chartType/@rdf:resource]" mode="bs2:RowBlock" priority="1">
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
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
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
    <xsl:template match="*[rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')]" mode="bs2:RowBlock" priority="1"/>

    <!-- hide Content resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content']" mode="bs2:RowBlock" priority="2"/>

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

        <xsl:apply-templates select="." mode="bs2:RowBlockContent">
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="content-uri" select="$content-uri"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:RowBlockContent">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="content-uri" as="xs:anyURI?"/>
        <xsl:param name="class" select="'row-fluid'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Left"/>

            <div class="span7">
                <xsl:apply-templates select="." mode="bs2:Block"/>
                
                <xsl:if test="$content-uri">
                    <div id="{$id || '-content'}" class="content resource-content" data-content-uri="{$content-uri}"/>
                </xsl:if>
            </div>

            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
        
        <!-- render contents attached to the types of this resource using ldh:template -->
        <xsl:variable name="content-uris" select="rdf:type/@rdf:resource[doc-available(resolve-uri('ns?query=ASK%20%7B%7D', $ldt:base))]/ldh:templates(., resolve-uri('ns', $ldt:base), $template-query)//srx:binding[@name = 'content']/srx:uri/xs:anyURI(.)" as="xs:anyURI*" use-when="system-property('xsl:product-name') = 'SAXON'"/>
        <xsl:for-each select="$content-uris" use-when="system-property('xsl:product-name') = 'SAXON'">
            <xsl:if test="doc-available(ac:document-uri(.))">
                <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="ldh:ContentList"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- TO-DO: override other modes -->
    
    <!-- HEADER -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Timestamp"/>

            <xsl:apply-templates select="." mode="bs2:Image"/>
            
            <xsl:apply-templates select="." mode="bs2:Actions"/>

            <h2>
                <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="xhtml:Anchor">
                    <xsl:with-param name="class" as="xs:string?">
                        <xsl:apply-templates select="." mode="ldh:logo"/>
                    </xsl:with-param>
                    <xsl:with-param name="mode" select="$mode"/>
                </xsl:apply-templates>
            </h2>

            <xsl:where-populated>
                <p>
                    <xsl:apply-templates select="." mode="ac:description"/>
                </p>
            </xsl:where-populated>

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
            <xsl:if test="doc-available($app-request-uri)">
                <div class="btn-group pull-left open">
                    <button type="button" class="btn dropdown-toggle btn-reconcile">
                        <xsl:attribute name="title">
                            <xsl:apply-templates select="key('resources', 'reconcile-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:attribute>

                        <xsl:apply-templates select="key('resources', 'reconcile', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>

                        <span class="caret"></span>
                    </button>
                    <ul class="dropdown-menu">
                        <xsl:variable name="apps" select="document($app-request-uri)" as="document-node()"/>
                        <xsl:apply-templates select="$apps//*[sd:endpoint/@rdf:resource]">
                            <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                        </xsl:apply-templates>
                    </ul>
                </div>
            </xsl:if>
            
            <button type="button">
                <xsl:attribute name="title">
                    <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:attribute>
                
                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
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
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content'][rdf:first[@rdf:parseType = 'Literal']/xhtml:div]" mode="ldh:ContentList" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'content xhtml-content span7 offset2'" as="xs:string?"/>
        
        <div class="row-fluid">
            <div>
                <xsl:if test="$id">
                    <xsl:attribute name="id" select="$id"/>
                </xsl:if>
                <xsl:if test="$class">
                    <xsl:attribute name="class" select="$class"/>
                </xsl:if>

                <!--  remove XHTML namespace -->
                <!-- <xsl:copy-of copy-namespaces="no" select="sioc:content/xhtml:div"/> -->
                <xsl:apply-templates select="rdf:first[@rdf:parseType = 'Literal']/xhtml:div" mode="ldh:XHTMLContent"/>
            </div>
        </div>

        <!-- process the next ldh:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content'][rdf:first/@rdf:resource]" mode="ldh:ContentList" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid content resource-content'" as="xs:string?"/>
        
        <!-- @data-content-uri is used to retrieve $content-uri in client.xsl -->
        <div data-content-uri="{rdf:first/@rdf:resource}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="ac:mode/@rdf:resource">
                <xsl:attribute name="data-content-mode" select="ac:mode/@rdf:resource"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Left"/>
            
            <div class="span7">
                <xsl:choose>
                    <xsl:when test="doc-available(ac:document-uri(rdf:first/@rdf:resource))">
                        <xsl:apply-templates select="key('resources', rdf:first/@rdf:resource, document(ac:document-uri(rdf:first/@rdf:resource)))" mode="ldh:ContentHeader"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2>
                            <a href="{ac:build-uri(ac:uri(), map{ 'uri': string(rdf:first/@rdf:resource) }) }">
                                <xsl:value-of select="rdf:first/@rdf:resource"/>
                            </a>
                        </h2>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            
            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
        
        <!-- process the next ldh:Content in the list -->
        <xsl:apply-templates select="key('resources', rdf:rest/@rdf:resource)" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*" mode="ldh:ContentList"/>

    <xsl:template match="*[*][@rdf:about]" mode="ldh:ContentHeader" priority="2">
        <xsl:param name="mode" as="xs:anyURI?"/>
        
        <h2>
            <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor">
                <xsl:with-param name="class" as="xs:string?">
                    <xsl:apply-templates select="." mode="ldh:logo"/>
                </xsl:with-param>
                <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
        </h2>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="bs2:ConstructorListItem">
        <xsl:param name="with-label" select="true()" as="xs:boolean"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>

        <!-- the class document has to be available -->
        <xsl:if test="doc-available(ac:document-uri(@rdf:about))">
            <li>
                <xsl:apply-templates select="." mode="bs2:Constructor">
                    <xsl:with-param name="id" select="()"/>
                    <xsl:with-param name="with-label" select="$with-label"/>
                    <xsl:with-param name="create-graph" select="$create-graph"/>
                </xsl:apply-templates>
            </li>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about]" mode="bs2:Constructor">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="subclasses" as="attribute()*"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:param name="modal-form" select="false()" as="xs:boolean"/>
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>
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
                                    <xsl:apply-templates select="." mode="ldh:logo">
                                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                    </xsl:apply-templates>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of>
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </xsl:value-of>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
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
                                    <xsl:variable name="query-params" select="map:merge((map{ 'forClass': string(current-grouping-key()) }, if ($modal-form) then map{ 'mode': '&ac;ModalMode' } else (), if ($create-graph) then map{ 'createGraph': string(true()) } else ()))" as="map(xs:string, xs:string*)"/>
                                    <xsl:variable name="href" select="ac:build-uri(ac:uri(), $query-params)" as="xs:anyURI"/>
                                    <a href="{$href}" class="btn add-constructor" title="{current-grouping-key()}">
                                        <xsl:if test="$id">
                                            <xsl:attribute name="id" select="$id"/>
                                        </xsl:if>
                                        <!-- we don't want to give a name to this input as it would be included in the RDF/POST payload -->
                                        <input type="hidden" class="forClass" value="{current-grouping-key()}"/>
                                        
                                        <xsl:value-of>
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </xsl:value-of>
                                    </a>
                                </li>
                            </xsl:for-each-group>
                        </ul>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="query-params" select="map:merge((map{ 'forClass': string($forClass) }, if ($modal-form) then map{ 'mode': '&ac;ModalMode' } else (), if ($create-graph) then map{ 'createGraph': string(true()) } else ()))" as="map(xs:string, xs:string*)"/>
                    <xsl:variable name="href" select="ac:build-uri(ac:uri(), $query-params)" as="xs:anyURI"/>
                    <a href="{$href}" title="{@rdf:about}">
                        <xsl:if test="$id">
                            <xsl:attribute name="id" select="$id"/>
                        </xsl:if>

                        <xsl:choose>
                            <xsl:when test="$with-label">
                                <xsl:apply-templates select="." mode="ldh:logo">
                                    <xsl:with-param name="class" select="'btn add-constructor'"/>
                                </xsl:apply-templates>

                                <xsl:value-of>
                                    <xsl:apply-templates select="." mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                                    <xsl:with-param name="class" select="'btn add-constructor'"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- we don't want to give a name to this input as it would be included in the RDF/POST payload -->
                        <input type="hidden" class="forClass" value="{@rdf:about}"/>
                    </a>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- MODAL FORM -->

    <!-- hide constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation'] | *[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:ModalForm" priority="3"/>

    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][$ac:method = 'GET'][not(rdf:type/@rdf:resource = '&owl;NamedIndividual')][not(* except rdf:type)]" mode="bs2:ModalForm" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:ModalForm">
        <xsl:apply-templates select="." mode="bs2:Form"/>
    </xsl:template>

    <!-- ROW FORM -->

    <!-- hide constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation'] | *[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:RowForm" priority="3"/>

    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][$ac:method = 'GET'][not(rdf:type/@rdf:resource = '&owl;NamedIndividual')][not(* except rdf:type)]" mode="bs2:RowForm" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'"/>
        
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:RowForm">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="content-uri" as="xs:anyURI?"/>
        <xsl:param name="class" select="'row-fluid'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <!--<xsl:apply-templates select="." mode="bs2:Left"/>-->

            <div class="span7 offset2">
                <xsl:apply-templates select="." mode="bs2:Form"/>
            </div>

            <!--<xsl:apply-templates select="." mode="bs2:Right"/>-->
        </div>
    </xsl:template>
    
    <!-- FORM -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:sort select="ac:label(.)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- FORM CONTROL -->

    <!-- turn off blank node resources from constructor graph (only those that are objects) -->
    <xsl:template match="*[@rdf:nodeID][$ac:forClass][rdf:type/starts-with(@rdf:resource, '&xsd;')] | *[@rdf:nodeID][$ac:forClass][count(key('predicates-by-object', @rdf:nodeID)) &gt; 0][rdf:type/@rdf:resource = '&rdfs;Resource']" mode="bs2:FormControl" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <!-- turn off default form controls for rdf:type as we are handling it specially with bs2:TypeControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:FormControl" priority="1"/>
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:FormControl">
        <xsl:param name="id" select="concat('form-control-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="violations" select="key('violations-by-value', */@rdf:resource) | key('violations-by-root', (@rdf:about, @rdf:nodeID))" as="element()*"/>
        <xsl:param name="forClass" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>
        <xsl:param name="constructor-query" as="xs:string?" tunnel="yes"/>
        <xsl:param name="constructor" select="ldh:construct(map:merge(for $class in $forClass return map{ $class: spin:constructors($class, resolve-uri('ns', $ldt:base), $constructor-query)//srx:binding[@name = 'construct']/srx:literal/string(.) }))" as="document-node()?"/>
        <xsl:param name="template" select="$constructor/rdf:RDF/*[@rdf:nodeID][every $type in rdf:type/@rdf:resource satisfies current()/rdf:type/@rdf:resource = $type][* except rdf:type]" as="element()*"/>
        <xsl:param name="template-properties" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="traversed-ids" select="@rdf:*" as="xs:string*" tunnel="yes"/>
        <xsl:param name="show-subject" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="constraint-query" as="xs:string?" tunnel="yes"/>

        <fieldset>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
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
                        <button type="button">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:attribute>

                            <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
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
            <xsl:apply-templates select="* | $template/*[not(concat(namespace-uri(), local-name()) = current()/*/concat(namespace-uri(), local-name()))][not(self::rdf:type)]" mode="#current">
                <!-- move required properties up -->
                <xsl:sort select="if ($constraint-query) then exists(for $type in $types return spin:constraints($type, resolve-uri('ns', $ldt:base), $constraint-query)//srx:binding[@name = 'property'][srx:uri = current()/concat(namespace-uri(), local-name())]) else false()" order="descending"/>
                <xsl:sort select="ac:property-label(.)"/>
                <xsl:with-param name="violations" select="$violations"/>
                <xsl:with-param name="constructor" select="$constructor"/>
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
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:TypeControl">
        <xsl:param name="forClass" as="xs:anyURI?"/> <!-- allow subclasses of owl:Class? -->
        <xsl:param name="hidden" select="false()" as="xs:boolean"/>

        <xsl:apply-templates mode="#current">
            <xsl:sort select="ac:label(..)"/>
            <xsl:with-param name="forClass" select="$forClass"/>
            <xsl:with-param name="hidden" select="$hidden"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- PROPERTY CONTROL -->
    
    <!-- hide property dropdown -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content']/*" mode="bs2:PropertyControl" priority="1"/>
    
    <!-- TYPEAHEAD -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:Typeahead">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'btn add-typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="title" select="(@rdf:about, @rdf:nodeID)[1]" as="xs:string?"/>

        <button type="button">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$disabled">
                <xsl:attribute name="disabled" select="'disabled'"/>
            </xsl:if>
            <xsl:if test="$title">
                <xsl:attribute name="title" select="$title"/>
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

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;URISyntaxViolation']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&ldh;URISyntaxViolation', document(ac:document-uri('&ldh;')))" mode="ldh:logo">
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
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&spin;ConstraintViolation', document(ac:document-uri('&spin;')))" mode="ldh:logo">
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
