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
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY schema "https://schema.org/">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
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
xmlns:sh="&sh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:geo="&geo;"
xmlns:void="&void;"
xmlns:schema="&schema;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>
    
    <xsl:param name="foaf:Agent" as="document-node()?"/>

    <xsl:key name="shapes-by-target-class" match="*[@rdf:about] | *[@rdf:nodeID]" use="sh:targetClass/@rdf:resource | sh:targetClass/@rdf:resource"/>

    <!-- LABEL -->

    <!-- TO-DO: move to owl.xsl -->
    <xsl:template match="*[@rdf:about = '&owl;NamedIndividual']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'instance', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
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

    <xsl:template match="*[@rdf:about = ('&ldh;URISyntaxViolation', '&spin;ConstraintViolation', '&sh;ValidationResult', '&sh;ValidationReport', '&ldh;ResourceExistsException')]" mode="ldh:logo">
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

    <!-- schema.org BREADCRUMBS -->
    
    <xsl:template match="*[@rdf:about]" mode="schema:BreadCrumbListItem" as="element()">
        <rdf:Description rdf:nodeID="item{position()}">
            <rdf:type rdf:resource="&schema;ListItem"/>
            <schema:position><xsl:value-of select="position()"/></schema:position>
            <schema:name><xsl:value-of select="ac:label(.)"/></schema:name>
            <schema:item><xsl:value-of select="@rdf:about"/></schema:item>
        </rdf:Description>
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
    
    <!-- disable .left-nav for XHTML content instances -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;XHTML'][rdf:value[@rdf:parseType = 'Literal']/xhtml:div]" mode="bs2:Left" priority="2"/>

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
    
    <!-- .resource-content instances -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Object'][rdf:value/@rdf:resource]" mode="bs2:Right" priority="1">
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
                    </h2>
                    <!-- will be hydrated by client.xsl -->
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- MODE TABS -->
    
    <xsl:template match="*[@rdf:about]" mode="bs2:ModeTabsItem">
        <xsl:param name="absolute-path" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="base-uri" as="xs:anyURI?"/>
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

            <a href="{ldh:href($ldt:base, $absolute-path, ldh:query-params(xs:anyURI(@rdf:about)), ac:absolute-path($base-uri))}">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </a>
        </li>
    </xsl:template>
    
    <!-- BLOCK -->

    <!-- embed file content -->
    <xsl:template match="*[@rdf:about][dct:format]" mode="bs2:Block" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Header"/>

            <xsl:apply-templates select="." mode="bs2:PropertyList"/>
            
            <xsl:variable name="media-type" select="substring-after(dct:format[1]/@rdf:resource, 'http://www.sparontologies.net/mediatype/')" as="xs:string"/>
            <object data="{@rdf:about}" type="{$media-type}"></object>
        </div>
    </xsl:template>
    
    <!-- ROW -->
    
    <!-- query and chart overrides TO-DO: move to a vocab-specific stylesheet -->
    <xsl:template match="*[@rdf:about][sp:text/text()] | *[@rdf:about][spin:query/@rdf:resource][ldh:chartType/@rdf:resource]" mode="bs2:Row" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid content override-content'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" select="'display: none;'" as="xs:string?"/> <!-- TO-DO: remove? -->

        <xsl:next-match>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="about" select="$about"/>
            <xsl:with-param name="typeof" select="$typeof"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="style" select="$style"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- hide inlined blank node resources from the main block flow -->
    <xsl:template match="*[*][key('resources', @rdf:nodeID)][count(key('predicates-by-object', @rdf:nodeID)[not(self::foaf:primaryTopic)]) = 1]" mode="bs2:Row" priority="1">
        <xsl:param name="display" select="false()" as="xs:boolean" tunnel="yes"/>
        
        <xsl:if test="$display">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <!-- hide instances of system classes -->
    <xsl:template match="*[not($ldh:renderSystemResources)][@rdf:about = ac:absolute-path(ldh:base-uri(.)) and rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')] | *[not($ldh:renderSystemResources)][rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]" mode="bs2:Row" priority="1" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Row">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="type-content" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>
            <xsl:if test="$style">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Left"/>

            <div class="main span7">
                <xsl:variable name="doc" as="document-node()">
                    <xsl:document>
                        <rdf:RDF>
                            <xsl:copy-of select="."/>
                        </rdf:RDF>
                    </xsl:document>
                </xsl:variable>
        
                <xsl:choose>
                    <xsl:when test="$mode = '&ac;MapMode'">
                        <xsl:apply-templates select="$doc" mode="bs2:Map">
                            <xsl:with-param name="id" select="generate-id() || '-map-canvas'"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;GraphMode'">
                        <xsl:apply-templates select=".." mode="bs2:Graph"/>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;EditMode'">
                        <xsl:apply-templates select="." mode="bs2:Form"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="bs2:Block"/>
                    </xsl:otherwise>
                </xsl:choose>
            </div>

            <xsl:apply-templates select="." mode="bs2:Right"/>
            
            <xsl:if test="$type-content">
                <!-- render contents attached to the types of this resource using ldh:template -->
                <xsl:variable name="types" select="rdf:type/@rdf:resource" as="xs:anyURI*" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:variable name="content-values" select="if (exists($types) and doc-available(resolve-uri('ns?query=ASK%20%7B%7D', $ldt:base))) then (ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $template-query || ' VALUES $Type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' }')//srx:binding[@name = 'content']/srx:uri/xs:anyURI(.)) else ()" as="xs:anyURI*" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:for-each select="$content-values" use-when="system-property('xsl:product-name') = 'SAXON'">
                    <xsl:if test="doc-available(ac:document-uri(.))">
                        <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="bs2:RowContent"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </div>
    </xsl:template>
    
    <!-- HEADER -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'well'" as="xs:string?"/>

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
        <xsl:param name="show-edit-button" select="true()" as="xs:boolean" tunnel="yes"/>
        
        <div class="pull-right">
            <!--
            <xsl:if test="doc-available($app-request-uri)">
                <xsl:variable name="apps" select="document($app-request-uri)" as="document-node()"/>
                <xsl:if test="$apps//*[sd:endpoint/@rdf:resource]">
                    <xsl:variable name="resource" select="." as="element()"/>
                    
                    <div class="btn-group pull-left">
                        <button type="button" class="btn dropdown-toggle">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'reconcile-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:attribute>

                            <xsl:apply-templates select="key('resources', 'reconcile', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            <xsl:text> </xsl:text>
                            <span class="caret"></span>
                        </button>
                        <ul class="dropdown-menu">
                            <xsl:for-each select="$apps//*[@rdf:about][sd:endpoint/@rdf:resource]">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>
                                
                                <li>
                                    <button class="btn btn-reconcile">
                                        <input type="hidden" name="resource" value="{$resource/@rdf:about}"/>
                                        <input type="hidden" name="label" value="{ac:label($resource)}"/>
                                        <input type="hidden" name="service" value="{sd:endpoint/@rdf:resource}"/>
                                        
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </button>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>
                </xsl:if>
            </xsl:if>
            -->
            
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
            
            <xsl:if test="$show-edit-button">
                <button type="button" class="btn btn-edit">
                    <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </button>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:Actions"/>
    
    <!-- TIMESTAMP -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Timestamp">
        <xsl:variable name="max-modified-datetime" select="max((dct:created/text()[. castable as xs:date]/xs:date(.), dct:created/text()[. castable as xs:dateTime]/xs:dateTime(.), dct:modified/text()[. castable as xs:date]/xs:date(.), dct:modified/text()[. castable as xs:dateTime]/xs:dateTime(.)))" as="item()?"/>
        <xsl:apply-templates select="(dct:created/text(), dct:modified/text())[. = $max-modified-datetime]"/>
    </xsl:template>
    
    <!-- TYPE LIST -->

    <xsl:template match="*[sioc:has_parent] | *[sioc:has_container]" mode="bs2:TypeList" priority="0.8"/>

    <xsl:template match="*[@rdf:about or @rdf:nodeID][rdf:type/@rdf:resource]" mode="bs2:TypeList">
        <ul class="inline">
            <xsl:for-each select="rdf:type/@rdf:resource">
                <xsl:sort select="ac:object-label(.)" order="ascending" lang="{$ldt:lang}" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:sort select="ac:object-label(.)" order="ascending" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

                <!-- TO-DO: find a way to use only cached documents, otherwise this will execute a synchronous HTTP request which slows down the UI -->
                <li>
                    <xsl:apply-templates select="."/>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    <!-- CONTENT LIST -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:ContentList">
        <!-- sort rdf:_1, rdf:_2, ... properties by index -->
        <xsl:variable name="predicates" as="element()*">
            <xsl:perform-sort select="*[namespace-uri() = '&rdf;'][starts-with(local-name(), '_')]">
                <xsl:sort select="xs:integer(substring-after(local-name(), '_'))"/>
            </xsl:perform-sort>
        </xsl:variable>

        <xsl:variable name="this" select="@rdf:about" as="xs:anyURI"/>
        <xsl:for-each select="$predicates"> <!-- do not0 iterate $predicates/@rdf:resource sequence as it will be sorted differently -->
            <xsl:apply-templates select="@rdf:resource" mode="bs2:RowContent"/>
            <!-- <xsl:for-each select="@rdf:resource"> -->
                <!--
                <xsl:if test="doc-available(ac:document-uri(.))">
                    <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="bs2:RowContent"/>
                </xsl:if>
                -->

                <!--
                <div class="row-fluid content" about="{.}" id="{if (contains($about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after($about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()}">
                    <div class="left-nav span2"></div>
                    <div class="main span7"></div>
                    <div class="right-nav span3"></div>
                </div>
                -->
                <!-- TO-DO: show error otherwise -->
            <!-- </xsl:for-each> -->
        </xsl:for-each>
    </xsl:template>

    <!-- ROW BLOCKS -->
    
    <!-- XHTML block (render server-side as the block data is available here) -->
    
    <xsl:template match="@rdf:resource[key('resources', .)[rdf:type/@rdf:resource = '&ldh;XHTML'][rdf:value[@rdf:parseType = 'Literal']/xhtml:div]]" mode="bs2:RowContent" priority="2">
        <xsl:param name="id" select="if (contains(., ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(., ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid content'" as="xs:string?"/>
<!--        <xsl:param name="typeof" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>-->
        <xsl:param name="left-class" as="xs:string?"/>
        <xsl:param name="main-class" select="'main offset2 span7'" as="xs:string?"/>
        <xsl:param name="right-class" select="'right-nav span3'" as="xs:string?"/>
        <xsl:param name="transclude" select="false()" as="xs:boolean"/>
        <xsl:param name="base" as="xs:anyURI?"/>
        <xsl:param name="draggable" select="$acl:mode = '&acl;Write'" as="xs:boolean?"/>

        <div about="{.}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
<!--            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>-->
            <xsl:if test="$draggable = true()">
                <xsl:attribute name="draggable" select="'true'"/>
            </xsl:if>
            <xsl:if test="$draggable = false()">
                <xsl:attribute name="draggable" select="'false'"/>
            </xsl:if>
            
            <!--
            <xsl:apply-templates select="." mode="bs2:Left">
                <xsl:with-param name="class" select="$left-class"/>
            </xsl:apply-templates>
            -->
            <div>
                <xsl:if test="$left-class">
                    <xsl:attribute name="class" select="$left-class"/>
                </xsl:if>
            </div>

            <div>
                <xsl:if test="$main-class">
                    <xsl:attribute name="class" select="$main-class"/>
                </xsl:if>

                <xsl:apply-templates select="key('resources', .)/rdf:value[@rdf:parseType = 'Literal']/xhtml:div" mode="ldh:XHTMLContent">
                    <xsl:with-param name="transclude" select="$transclude" tunnel="yes"/>
                    <xsl:with-param name="base" select="$base" tunnel="yes"/>
                </xsl:apply-templates>
            </div>
            
            <!--
            <xsl:apply-templates select="." mode="bs2:Right">
                <xsl:with-param name="class" select="$right-class"/>
            </xsl:apply-templates>
            -->
            
            <div>
                <xsl:if test="$right-class">
                    <xsl:attribute name="class" select="$right-class"/>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
    <!-- content block -->
    
    <xsl:template match="@rdf:resource" mode="bs2:RowContent" priority="1">
        <xsl:param name="id" select="if (contains(., ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(., ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid content'" as="xs:string?"/>
<!--        <xsl:param name="graph" select="ldh:graph/@rdf:resource" as="xs:anyURI?"/>
        <xsl:param name="mode" select="ac:mode/@rdf:resource" as="xs:anyURI?"/>-->
<!--        <xsl:param name="typeof" select="rdf:type/@rdf:resource" as="xs:anyURI*"/>-->
        <xsl:param name="left-class" select="'left-nav span2'" as="xs:string?"/>
        <xsl:param name="main-class" select="'main span7'" as="xs:string?"/>
        <xsl:param name="right-class" select="'right-nav span3'" as="xs:string?"/>
        <xsl:param name="draggable" select="$acl:mode = '&acl;Write'" as="xs:boolean?"/>

        <xsl:apply-templates select="." mode="bs2:RowContentHeader"/>
        
        <div about="{.}"> <!-- data-content-value="{@rdf:about}" -->
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
<!--            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>-->
            <xsl:if test="$draggable = true()">
                <xsl:attribute name="draggable" select="'true'"/>
            </xsl:if>
            <xsl:if test="$draggable = false()">
                <xsl:attribute name="draggable" select="'false'"/>
            </xsl:if>
            
            <!--
            <xsl:apply-templates select="." mode="bs2:Left">
                <xsl:with-param name="class" select="$left-class"/>
            </xsl:apply-templates>
            -->
            <div>
                <xsl:if test="$left-class">
                    <xsl:attribute name="class" select="$left-class"/>
                </xsl:if>
            </div>

            <div>
                <xsl:if test="$main-class">
                    <xsl:attribute name="class" select="$main-class"/>
                </xsl:if>
            </div>
            
            <!--
            <xsl:apply-templates select="." mode="bs2:Right">
                <xsl:with-param name="class" select="$right-class"/>
            </xsl:apply-templates>
            -->
            
            <div>
                <xsl:if test="$right-class">
                    <xsl:attribute name="class" select="$right-class"/>
                </xsl:if>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:RowContent"/>

    <!-- ROW CONTENT HEADER -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&ldh;View', '&ldh;Object')]" mode="bs2:RowContentHeader" priority="1">
        <xsl:variable name="anchor" as="node()*">
            <xsl:for-each select="@rdf:about">
                <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="xhtml:Anchor">
                    <xsl:with-param name="class" as="xs:string?">
                        <xsl:apply-templates select="." mode="ldh:logo"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:if test="exists($anchor)">
            <div class="row-fluid">
                <div class="main offset2 span7">
                    <h2>
                        <xsl:sequence select="$anchor"/>
                    </h2>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*[*][@rdf:about]" mode="bs2:RowContentHeader"/>
    
    <!-- SHAPE CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="bs2:ShapeConstructor" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>
<!--        <xsl:variable name="forShape" select="@rdf:about" as="xs:anyURI"/>-->
        
        <button title="{@rdf:about}" data-for-shape="{@rdf:about}">
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
        </button>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="bs2:ConstructorListItem" use-when="system-property('xsl:product-name') = 'SAXON'">
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
    
    <xsl:template match="*[*][@rdf:about]" mode="bs2:Constructor" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="subclasses" as="attribute()*"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>
<!--        <xsl:variable name="forClass" select="@rdf:about" as="xs:anyURI"/>-->

        <xsl:if test="doc-available(ac:document-uri(@rdf:about))">
            <!-- if subclasses exist, render a dropdown with multiple constructor choices. Otherwise, only render a single constructor button -->
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
                            <xsl:variable name="self-and-subclasses" select="key('resources', @rdf:about, document(ac:document-uri(@rdf:about))), $subclasses/.." as="element()*"/>

                            <!-- apply on the "deepest" subclass and its subclasses -->
                            <!-- eliminate matches where a class is a subclass of itself (happens in inferenced ontology models) -->
                            <xsl:for-each-group select="$self-and-subclasses[let $about := @rdf:about return not($about = $self-and-subclasses[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)]" group-by="@rdf:about">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>

                                <!-- won't traverse blank nodes, only URI resources -->
                                <li>
                                    <button class="btn add-constructor" title="{current-grouping-key()}" data-for-class="{current-grouping-key()}">
                                        <xsl:if test="$id">
                                            <xsl:attribute name="id" select="$id"/>
                                        </xsl:if>
                                        
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
                    <button title="{@rdf:about}" data-for-class="{@rdf:about}">
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
                    </button>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- ROW FORM -->

    <!-- hide constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&spin;ConstraintViolation', '&sh;ValidationResult', '&sh;ValidationReport', '&http;Response')]" mode="bs2:RowForm" priority="3" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <!-- hide instances of system classes -->
    <!-- <xsl:template match="*[not($ldh:renderSystemResources)][@rdf:about = ac:absolute-path(ldh:base-uri(.)) and rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')] | *[not($ldh:renderSystemResources)][rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]" mode="bs2:RowForm" priority="2.5" use-when="system-property('xsl:product-name') = 'SAXON'"/> -->

    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][$ac:method = 'GET'][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="bs2:RowForm" priority="2" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="bs2:RowForm" priority="2" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:RowForm">
        <xsl:param name="id" select="generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'row-fluid content'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="form-id" select="'form-' || generate-id()" as="xs:string?"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="action" select="ldh:href($ldt:base, ac:absolute-path($base-uri), map{}, ac:build-uri(ac:absolute-path($base-uri), map{ 'mode': for $mode in $ac:mode return string($mode) }))" as="xs:anyURI"/>
        <xsl:param name="enctype" select="if ($typeof = '&nfo;FileDataObject') then 'multipart/form-data' else ()" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="show-cancel-button" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>
            
            <xsl:apply-templates select="." mode="bs2:Left"/>

            <div class="main span7">
                <form method="{$method}" action="{$action}" class="form-horizontal">
                    <xsl:if test="$form-id">
                        <xsl:attribute name="id" select="$form-id"/>
                    </xsl:if>
                    <xsl:if test="$accept-charset">
                        <xsl:attribute name="accept-charset" select="$accept-charset"/>
                    </xsl:if>
                    <xsl:if test="$enctype">
                        <xsl:attribute name="enctype" select="$enctype"/>
                    </xsl:if>

                    <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'rdf'"/>
                        <xsl:with-param name="type" select="'hidden'"/>
                    </xsl:call-template>

                    <xsl:apply-templates select="/rdf:RDF/*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception"/>
                
                    <xsl:apply-templates select="." mode="bs2:Form">
                        <xsl:with-param name="method" select="$method"/>
                        <xsl:with-param name="action" select="$action"/>
                    </xsl:apply-templates>
                    
                    <div class="form-actions">
                        <button type="submit" class="btn-primary">
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="$button-class"/>
                            </xsl:apply-templates>

                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </button>

                        <button type="reset" class="btn">
                            <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn'"/>
                            </xsl:apply-templates>

                            <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </button>

                        <xsl:if test="$show-cancel-button">
                            <button type="button" class="btn btn-cancel">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </button>
                        </xsl:if>
                    </div>
                </form>
           </div>

            <xsl:apply-templates select="." mode="bs2:Right"/>
        </div>
    </xsl:template>
    
    <!-- FORM -->
    
    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="bs2:Form" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:param name="classes" as="element()*"/>

        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:with-param name="inline" select="false()" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&ldh;ResourceExistsException', document(ac:document-uri('&ldh;')))" mode="ldh:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="key('resources', '&ldh;ResourceExistsException', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>
    
    <!-- FORM CONTROL -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:FormControl">
        <xsl:param name="id" select="concat('fieldset-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="violations" select="key('violations-by-value', */@rdf:resource) | key('violations-by-root', (@rdf:about, @rdf:nodeID)) | key('violations-by-focus-node', (@rdf:about, @rdf:nodeID))" as="element()*"/>
        <xsl:param name="forClass" select="distinct-values(rdf:type/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:param name="type-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="constructors" as="document-node()?" tunnel="yes"/>
        <xsl:param name="constraints" as="document-node()?" tunnel="yes"/>
        <xsl:param name="shapes" as="document-node()?" tunnel="yes"/>
        <!-- include both sh:NodeShape and its connected sh:PropertyShapes in $type-shapes -->
        <xsl:param name="type-shapes" select="if ($shapes) then (key('shapes-by-target-class', $forClass, $shapes), key('resources', key('shapes-by-target-class', $forClass, $shapes)/sh:property/@rdf:resource, $shapes)) else ()" as="element()*"/>
        <xsl:param name="constructor" as="document-node()?">
            <!-- SHACL shapes take priority over SPIN constructors TO-DO: merge constructors -->
            <xsl:choose>
                <xsl:when test="exists($type-shapes)">
                    <xsl:variable name="constructor" as="document-node()">
                        <xsl:document>
                            <rdf:RDF>
                                <xsl:apply-templates select="$type-shapes" mode="ldh:Shape"/>
                            </rdf:RDF>
                        </xsl:document>
                    </xsl:variable>
                    <xsl:sequence select="ldh:reserialize($constructor)"/>
                </xsl:when>
                <xsl:when test="exists($forClass)">
                    <xsl:sequence select="ldh:construct-forClass($forClass)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="type-constraints" select="$constraints//srx:result[srx:binding[@name = 'Type'] = $forClass]" as="element()*"/>
        <xsl:param name="template" select="$constructor/rdf:RDF/*[@rdf:nodeID][every $type in rdf:type/@rdf:resource satisfies current()/rdf:type/@rdf:resource = $type][* except rdf:type]" as="element()*"/>
        <xsl:param name="template-properties" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="traversed-ids" select="@rdf:*" as="xs:string*" tunnel="yes"/>
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="show-subject" select="not(starts-with(@rdf:about, $base-uri) or @rdf:nodeID)" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="required" select="rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')" as="xs:boolean"/> <!-- Container/Item instances cannot be removed -->

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

                        <div class="pull-right">
                            <xsl:if test="exists($type-metadata)">
                                <div class="btn-group">
                                    <!-- show list of types that have constructors (excluding built-in system classes) -->
                                    <xsl:variable name="constructor-classes" select="distinct-values($constructors//srx:binding[@name = 'Type']/srx:uri)[not(starts-with(., '&dh;') or starts-with(., '&ldh;') or starts-with(., '&def;') or starts-with(., '&lapp;') or starts-with(., '&sp;') or starts-with(., '&nfo;'))]" as="xs:anyURI*"/>
                                    <button type="button" class="btn dropdown-toggle btn-edit-actions">
                                        <!-- only admins should see the button as only they have access to the ontologies with constructors in them -->
                                        <xsl:if test="not($acl:mode = '&acl;Control' and exists($constructor-classes))">
                                            <xsl:attribute name="style" select="'display: none'"/>
                                        </xsl:if>

                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'actions', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                        <span class="caret"></span>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <xsl:for-each select="$constructor-classes">
                                            <li>
                                                <button type="button" class="btn btn-edit-constructors" data-resource-type="{.}">
                                                    <xsl:value-of>
                                                        <xsl:apply-templates select="key('resources', 'edit', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                                    </xsl:value-of>
                                                    <xsl:text> </xsl:text>
                                                    <!-- query class description from the namespace ontology (because it might not be available as Linked Data) -->
                                                    <xsl:apply-templates select="key('resources', ., $type-metadata)" mode="ac:label"/>
                                                    <xsl:text> </xsl:text>
                                                    <xsl:value-of>
                                                        <xsl:apply-templates select="key('resources', 'constructors', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                                    </xsl:value-of>
                                                </button>
                                            </li>
                                        </xsl:for-each>
                                    </ul>
                                </div>
                            </xsl:if>
                            
                            <!-- button that toggles the .control-group for subject URI/bnode ID editing -->
                            <button type="button" class="btn btn-edit-subj {if ($show-subject) then 'open' else ()}"></button>
                        </div>
                        
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
    
            <xsl:apply-templates select="." mode="bs2:TypeControl">
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
            </xsl:apply-templates>

            <div class="violations" style="display: none">
                <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
            </div>
            
            <!-- create inputs for both resource description and constructor template properties -->
            <xsl:apply-templates select="* | $template/*[not(concat(namespace-uri(), local-name()) = current()/*/concat(namespace-uri(), local-name()))][not(self::rdf:type)]" mode="#current">
                <!-- move required properties up -->
                <xsl:sort select="exists($type-constraints//srx:binding[@name = 'property'][srx:uri = current()/concat(namespace-uri(), local-name())])" order="descending"/>
                <xsl:sort select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)"/>
                <xsl:with-param name="violations" select="$violations"/>
                <xsl:with-param name="constructor" select="$constructor"/>
                <xsl:with-param name="type-constraints" select="$type-constraints"/>
                <xsl:with-param name="type-shapes" select="$type-shapes"/>
                <xsl:with-param name="traversed-ids" select="$traversed-ids" tunnel="yes"/>
                <xsl:with-param name="property-metadata" select="$property-metadata" tunnel="yes"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="bs2:PropertyControl">
                <xsl:with-param name="template" select="$template"/>
                <xsl:with-param name="forClass" select="$forClass"/>
                <xsl:with-param name="required" select="true()"/>
                <xsl:with-param name="property-metadata" select="$property-metadata"/>
            </xsl:apply-templates>
        </fieldset>
    </xsl:template>
    
    <!-- TYPE CONTROL -->

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]" mode="bs2:TypeControl" priority="1">
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
    
    <!-- hide property dropdown for content instances -->
    
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object', '&ldh;View')]" mode="bs2:PropertyControl" priority="1"/>
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]" mode="bs2:PropertyControl">
        <xsl:param name="class" as="xs:string?"/>
        <!--<xsl:param name="label" select="true()" as="xs:boolean"/>-->
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <!-- <xsl:param name="forClass" as="xs:anyURI*"/> -->
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:variable name="seq-properties" select="for $property in ../rdf:Description/*/concat(namespace-uri(), local-name())[starts-with(., '&rdf;' || '_')] return xs:anyURI($property)" as="xs:anyURI*"/>
        <xsl:variable name="max-seq-index" select="if (empty($seq-properties)) then 0 else max(for $seq-property in $seq-properties return xs:integer(substring-after($seq-property, '&rdf;' || '_')))" as="xs:integer"/>

        <div class="control-group">
            <span class="control-label">
                <select class="input-medium">
                    <xsl:apply-templates select="key('resources', '&rdf;type', document(ac:document-uri('&rdf;type')))" mode="xhtml:Option"/>
                    
                    <!-- group properties by URI - there might be duplicates in the constructor; filter out rdf:type because it's included by default -->
                    <xsl:for-each-group select="$template/*[not(concat(namespace-uri(), local-name()) = '&rdf;type')]" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)"/>
                        <xsl:variable name="this" select="xs:anyURI(current-grouping-key())" as="xs:anyURI"/>
                        <xsl:variable name="available" select="doc-available(ac:document-uri($this))" as="xs:boolean"/>
                        <xsl:choose use-when="system-property('xsl:product-name') = 'SAXON'">
                            <xsl:when test="$available and key('resources', $this, document(ac:document-uri($this)))">
                                <xsl:apply-templates select="key('resources', $this, document(ac:document-uri($this)))" mode="xhtml:Option">
                                    <!-- <xsl:with-param name="selected" select="@rdf:about = $this"/> -->
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <option value="{current-grouping-key()}">
                                    <xsl:value-of select="local-name()"/>
                                </option>
                                
                                <!-- generate additional content sequence properties (that are not in the constructor but are used in the resource description -->
                                <xsl:if test="current-grouping-key() = '&rdf;_1'">
                                    <xsl:for-each select="2 to ($max-seq-index + 1)">
                                        <option value="&rdf;_{.}">
                                            <xsl:value-of select="'_' || ."/>
                                        </option>
                                    </xsl:for-each>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:for-each select="." use-when="system-property('xsl:product-name') eq 'SaxonJS'">
                            <option value="{current-grouping-key()}">
                                <xsl:value-of select="local-name()"/>
                            </option>
                            
                            <!-- generate additional content sequence properties (that are not in the constructor but are used in the resource description -->
                            <xsl:if test="current-grouping-key() = '&rdf;_1'">
                                <xsl:for-each select="2 to ($max-seq-index + 1)">
                                    <option value="&rdf;_{.}">
                                        <xsl:value-of select="'_' || ."/>
                                    </option>
                                </xsl:for-each>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </select>
            </span>

            <div class="controls">
                <!-- $forClass value is used in client.xsl -->
                <!-- 
                <xsl:for-each select="$forClass">
                    <input type="hidden" name="forClass" value="{.}"/>
                </xsl:for-each>
                -->
                
                <button type="button" id="button-{generate-id()}" class="btn add-value">
                    <xsl:apply-templates select="key('resources', 'add', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'btn add-value'"/>
                    </xsl:apply-templates>
                </button>
            </div>
        </div>
    </xsl:template>
    
    <!-- VIOLATION -->

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;URISyntaxViolation']" mode="bs2:Violation" use-when="system-property('xsl:product-name') = 'SAXON'">
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
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation']" mode="bs2:Violation" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', rdf:type/@rdf:resource, document(ac:document-uri(rdf:type/@rdf:resource)))" mode="ldh:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="." mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&sh;ValidationResult']" mode="bs2:Violation" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', rdf:type/@rdf:resource, document(ac:document-uri(rdf:type/@rdf:resource)))" mode="ldh:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of select="sh:resultMessage"/>
        </div>
    </xsl:template>
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Exception" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <!-- OBJECT -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Object" use-when="system-property('xsl:product-name') = 'SAXON'"/>

    <!-- ### SHARED BETWEEN SERVER AND CLIENT -->
    
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
    
</xsl:stylesheet>
