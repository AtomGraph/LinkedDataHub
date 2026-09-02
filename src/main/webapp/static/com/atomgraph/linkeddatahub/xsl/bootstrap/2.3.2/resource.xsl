<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
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
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
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
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:lacl="&lacl;"
xmlns:lapp="&lapp;"
xmlns:ldh="&ldh;"
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
    
    <xsl:key name="shapes-by-target-class" match="*[@rdf:about] | *[@rdf:nodeID]" use="sh:targetClass/@rdf:resource | sh:targetClass/@rdf:resource"/>

    <!-- Material Symbols glyph per layout mode (shared by the action-bar mode switcher and the mode list) -->
    <xsl:variable name="ldh:mode-icons" as="map(xs:string, xs:string)" select="map{
        '&ldh;ContentMode': 'view_module',
        '&ac;ReadMode': 'visibility',
        '&ac;ListMode': 'view_list',
        '&ac;TableMode': 'table',
        '&ac;GridMode': 'grid_view',
        '&ac;MapMode': 'map',
        '&ac;ChartMode': 'bar_chart',
        '&ac;GraphMode': 'hub'
    }"/>
    <!-- document-class glyphs shared by the breadcrumb and constructor items; sites supply their own fallback -->
    <xsl:variable name="ldh:class-icons" as="map(xs:string, xs:string)" select="map{
        '&def;Root': 'folder',
        '&dh;Container': 'folder',
        '&dh;Item': 'description'
    }"/>

    <!-- LABEL -->

    <xsl:template match="*[@rdf:about = '&owl;NamedIndividual']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'instance', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
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

    <xsl:template match="*[@rdf:about = '&ldh;View']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-logo btn-view')"/>
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

    <xsl:template match="*[@rdf:about = ('&ldh;ContentMode', '&ac;ReadMode', '&ac;ListMode', '&ac;TableMode', '&ac;GridMode', '&ac;MapMode', '&ac;ChartMode', '&ac;GraphMode')]" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="mode-logo-classes" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'&ldh;ContentMode'" select="'btn-content'"/>
                <xsl:map-entry key="'&ac;ReadMode'" select="'btn-read'"/>
                <xsl:map-entry key="'&ac;ListMode'" select="'btn-list'"/>
                <xsl:map-entry key="'&ac;TableMode'" select="'btn-table'"/>
                <xsl:map-entry key="'&ac;GridMode'" select="'btn-grid'"/>
                <xsl:map-entry key="'&ac;MapMode'" select="'btn-map'"/>
                <xsl:map-entry key="'&ac;ChartMode'" select="'btn-chart'"/>
                <xsl:map-entry key="'&ac;GraphMode'" select="'btn-graph'"/>
            </xsl:map>
        </xsl:param>

        <xsl:attribute name="class" select="concat($class, ' ', map:get($mode-logo-classes, @rdf:about))"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;QueryEditorMode']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-query')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&acl;Access']" mode="ldh:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-acl btn-access-form')"/>
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
        <!-- crumb icon by document type, as in the design system's breadcrumb -->
        <xsl:param name="icon" select="((rdf:type/@rdf:resource ! map:get($ldh:class-icons, string(.))), 'link')[1]" as="xs:string"/>

        <!-- same href recipe as the xhtml:Anchor override in imports/default.xsl; the crumb builds its
             own <a> because the design puts a glyph inside it, which the anchor mode cannot emit -->
        <xsl:variable name="fragment" select="ac:fragment-id(@rdf:about)" as="xs:string?"/>

        <a href="{ldh:href(ac:document-uri(xs:anyURI(@rdf:about)), map{}, $fragment)}" title="{@rdf:about}" class="bc-pill{if ($leaf) then ' is-current' else ()}">
            <span class="msi sm" aria-hidden="true">
                <xsl:value-of select="$icon"/>
            </span>
            <span>
                <xsl:apply-templates select="." mode="ac:label"/>
            </span>
        </a>

        <xsl:if test="not($leaf)">
            <span class="msi sm bc-sep" aria-hidden="true">chevron_right</span>
        </xsl:if>
    </xsl:template>
    
    <!-- BLOCK LINKS POPOVER -->

    <!-- backlinks: jump-off navigation in a popover anchored to the links button in the block header
         (or the view toolbar). Ships closed and empty; the tb-links onclick lazy-loads the row list
         on first open, resolving the block URI from the ancestor block's @about at click time, so the
         markup needs no resource context of its own. -->
    <xsl:template match="*" mode="ldh:BlockLinksPopover">
        <div class="links-nav">
            <button type="button" class="tb tb-links">
                <xsl:attribute name="title">
                    <xsl:apply-templates select="key('resources', 'backlinks', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </xsl:attribute>

                <span class="msi sm" aria-hidden="true">link</span>
            </button>

            <div class="links-pop">
                <h2 class="dh2">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'backlinks', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                    </xsl:value-of>
                </h2>

                <div class="backlinks-nav dgroup">
                    <!-- ldh:backlinks-response appends the row list here on first open -->
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- COPY URI BUTTON -->

    <!-- copies the resource's URI to the clipboard. Context-free markup like ldh:BlockLinksPopover:
         the onclick handler in client.xsl resolves the URI from the header's title anchor or the
         ancestor block's @about at click time. -->
    <xsl:template match="*" mode="ldh:CopyUriButton">
        <button type="button" class="btn-copy-uri tb">
            <xsl:attribute name="title">
                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
            </xsl:attribute>

            <span class="msi sm" aria-hidden="true">content_copy</span>
        </button>
    </xsl:template>

    <!-- LINK ROW -->

    <xsl:template match="*[@rdf:about]" mode="ldh:LinkRow">
        <xsl:param name="icon" select="'link'" as="xs:string"/>

        <a href="{ldh:href(ac:document-uri(xs:anyURI(@rdf:about)), map{}, ac:fragment-id(@rdf:about))}" title="{@rdf:about}" class="drow{if (not(starts-with(@rdf:about, ldt:base()))) then ' external' else ''}">
            <span class="msi sm" aria-hidden="true">
                <xsl:value-of select="$icon"/>
            </span>
            <span class="lbl">
                <xsl:apply-templates select="." mode="ac:label"/>
            </span>
        </a>
    </xsl:template>

    <!-- MODE LIST -->

    <xsl:template match="*[@rdf:about]" mode="bs2:ModeListItem">
        <xsl:param name="absolute-path" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="base-uri" as="xs:anyURI?"/>
        <xsl:param name="active" as="xs:boolean"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri($base-uri), ldh:build-query(xs:anyURI(@rdf:about)))" as="xs:anyURI?"/>
        <xsl:param name="mode-classes" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'&ldh;ContentMode'" select="'content-mode'"/>
                <xsl:map-entry key="'&ac;ReadMode'" select="'read-mode'"/>
                <xsl:map-entry key="'&ac;ListMode'" select="'list-mode'"/>
                <xsl:map-entry key="'&ac;TableMode'" select="'table-mode'"/>
                <xsl:map-entry key="'&ac;GridMode'" select="'grid-mode'"/>
                <xsl:map-entry key="'&ac;MapMode'" select="'map-mode'"/>
                <xsl:map-entry key="'&ac;ChartMode'" select="'chart-mode'"/>
                <xsl:map-entry key="'&ac;GraphMode'" select="'graph-mode'"/>
            </xsl:map>
        </xsl:param>
        <xsl:param name="class" select="map:get($mode-classes, @rdf:about) || (if ($active) then ' is-active' else ())" as="xs:string?"/>

        <a class="mi{if ($class) then ' ' || $class else ()}">
            <xsl:if test="$href">
                <xsl:attribute name="href" select="$href"/>
            </xsl:if>
            <span class="msi sm" aria-hidden="true">
                <xsl:value-of select="map:get($ldh:mode-icons, string(@rdf:about))"/>
            </span>
            <span class="label-col">
                <xsl:apply-templates select="." mode="ac:label"/>
            </span>
        </a>
    </xsl:template>

    <!-- DEFAULT -->

    <!-- embed file content -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&nfo;FileDataObject'][dct:format]" priority="2">
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
    
    <!-- BLOCK -->
        
    <!-- resource block overrides -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select')]" mode="bs2:Row" priority="1">
        <!-- TO-DO: use ldh:request-uri() to resolve URIs server-side -->
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean?"/>
        <xsl:param name="show-row-block-controls" select="true()" as="xs:boolean"/>
        <xsl:param name="show-drag-handle" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <xsl:apply-templates select="key('resources', .)" mode="bs2:RowContentHeader"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class or $diff-class">
                <xsl:attribute name="class" select="string-join(($class, $diff-class), ' ')"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
<!--            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>-->
            <xsl:if test="$draggable = true()">
                <xsl:attribute name="draggable" select="'true'"/>
            </xsl:if>

            <div class="row-main">
                <xsl:if test="$show-row-block-controls">
                    <xsl:attribute name="class" select="'row-main progress active'"/>

                    <xsl:if test="$show-drag-handle">
                        <div class="drag-handle">
                            <xsl:if test="acl:mode() = '&acl;Write'">
                                <xsl:attribute name="draggable" select="'true'"/>
                            </xsl:if>
                        </div>
                    </xsl:if>
                    <div class="block-row row-block-controls" style="position: relative; top: 30px; margin-top: -30px; z-index: 1;">
                        <div class="row-main">
                            <xsl:if test="acl:mode() = '&acl;Write'">
                                <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm btn-edit" style="display: none;">
                                    <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                                </button>
                            </xsl:if>
                            <div class="block-row">
                                <div style="width: 0%;" class="row-main bar"></div>
                            </div>
                        </div>
                    </div>
                </xsl:if>

                <!-- client-side $container -->
                <xsl:next-match>
                    <xsl:with-param name="id" select="()"/> <!-- only block wrappers have @id-->
                    <xsl:with-param name="about" select="()"/> <!-- only block wrappers have @about -->
                    <xsl:with-param name="class" select="'block-row'"/>
                </xsl:next-match>
            </div>
        </div>
    </xsl:template>
    
    <!-- XHTML content overrides -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;XHTML'][rdf:value[@rdf:parseType = 'Literal']/xhtml:div]" mode="bs2:Row" priority="1">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <!-- XHTML content is prose: quiet block, no card surface, reads as part of the page flow -->
        <xsl:param name="class" select="'block ldh-block is-quiet'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean?"/>
        <xsl:param name="show-drag-handle" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <xsl:apply-templates select="." mode="bs2:RowContentHeader"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class or $diff-class">
                <xsl:attribute name="class" select="string-join(($class, $diff-class), ' ')"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
<!--            <xsl:if test="exists($typeof)">
                <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
            </xsl:if>-->
            <xsl:if test="$draggable = true()">
                <xsl:attribute name="draggable" select="'true'"/>
            </xsl:if>
            
            <div class="row-main">
                <xsl:if test="$show-drag-handle">
                    <div class="drag-handle">
                        <xsl:if test="acl:mode() = '&acl;Write'">
                            <xsl:attribute name="draggable" select="'true'"/>
                        </xsl:if>
                    </div>
                </xsl:if>
                <div class="block-row row-block-controls" style="position: relative; top: 30px; margin-top: -30px; z-index: 1;">
                    <div class="row-main">
                        <xsl:if test="acl:mode() = '&acl;Write'">
                            <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm btn-edit" style="display: none;">
                                <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                            </button>
                        </xsl:if>
                    </div>
                </div>

                <div id="row-{generate-id()}" class="block-row">
                    <xsl:if test="$about">
                        <xsl:attribute name="about" select="$about"/>
                    </xsl:if>
                    <xsl:if test="exists($typeof)">
                        <xsl:attribute name="typeof" select="string-join($typeof, ' ')"/>
                    </xsl:if>
            
                    <div>
                        <xsl:if test="$main-class">
                            <xsl:attribute name="class" select="$main-class"/>
                        </xsl:if>

                        <!-- the diff union can carry two values (removed and added); mark each and show the removed one first -->
                        <xsl:for-each select="rdf:value[@rdf:parseType = 'Literal']">
                            <xsl:sort select="if (ldh:value-diff-class(., $diff-added-keys, $diff-removed-keys) = 'diff-removed') then 0 else 1"/>

                            <xsl:variable name="value-diff-class" select="ldh:value-diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>
                            <xsl:choose>
                                <xsl:when test="$value-diff-class">
                                    <div class="{$value-diff-class}">
                                        <xsl:apply-templates select="xhtml:div" mode="ldh:XHTMLContent"/>
                                    </div>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="xhtml:div" mode="ldh:XHTMLContent"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </div>

                    <!-- content blocks have no header - the popover and the copy-URI button anchor to the card's top right corner instead, surfaced on card hover by CSS -->
                    <xsl:if test="$about">
                        <xsl:apply-templates select="." mode="ldh:BlockLinksPopover"/>
                        <xsl:apply-templates select="." mode="ldh:CopyUriButton"/>
                    </xsl:if>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- hide inlined blank node resources from the main block flow -->
    <xsl:template match="*[*][key('resources', @rdf:nodeID)][count(key('predicates-by-object', @rdf:nodeID)[not(self::foaf:primaryTopic)]) = 1]" mode="bs2:Row" priority="1">
        <xsl:param name="display" select="false()" as="xs:boolean" tunnel="yes"/>
        
        <xsl:if test="$display">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <!-- hide instances of system classes -->
    <xsl:template match="*[not($ldh:renderSystemResources)][@rdf:about = ac:absolute-path(ldh:base-uri(.)) and rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')]" mode="bs2:Row" priority="1"/>

    <!-- bs2:Row wrapper: outer div + inner div.row-main around next-match output. Emitted by both products so that server- and client-rendered markup have the same shape: the ontology-driven view injection in client/block.xsl keys off this exact nesting (outer div.block[@about] / div.row-main / inner div.block[@typeof]), and it now runs over server-rendered markup too, which is kept in place on the initial load. The SAXON-only predecessor at resource.xsl:605 also injected view blocks synchronously; only the shape is reproduced here, the injection stays client-side. Excludes the typed block types handled by the typed-block template since those have their own wrapper structure (progress bar etc.) and the unconditional wrapping here would inject two spurious div levels into their next-match chain. -->
    <!-- TO-DO: replace with fully client-side wrapper in ldh:RenderRow in block.xsl -->
    <xsl:template match="*[*][@rdf:about][not(rdf:type/@rdf:resource = ('&http;Response', '&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select'))] | *[*][@rdf:nodeID][not(rdf:type/@rdf:resource = ('&http;Response', '&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select'))]" mode="bs2:Row" priority="0.7">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <!-- the wrapper keeps the 'block' anchor token but not the ldh-block card skin:
                 the inner next-match block is the card, and skinning both stacked two cards -->
            <xsl:attribute name="class" select="string-join(('block', $diff-class), ' ')"/>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>

            <div class="row-main">
                <xsl:next-match>
                    <xsl:with-param name="id" select="()"/> <!-- only the wrapper carries @id -->
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="about" select="$about"/>
                    <xsl:with-param name="typeof" select="$typeof"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="style" select="$style"/>
                </xsl:next-match>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Row">
        <!-- TO-DO: use ldh:request-uri() to resolve URIs server-side -->
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <!-- 'block' is the token every CSR handler anchors on; 'ldh-block' is what app.css styles -->
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class or $diff-class">
                <xsl:attribute name="class" select="string-join(($class, $diff-class), ' ')"/>
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

            <div>
                <xsl:if test="$main-class">
                    <xsl:attribute name="class" select="$main-class"/>
                </xsl:if>
                
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
                    <xsl:when test="$mode = '&ac;ChartMode'">
                        <xsl:apply-templates select="$doc" mode="bs2:Chart">
                            <xsl:with-param name="canvas-id" select="generate-id() || '-chart-canvas'"/>
                            <xsl:with-param name="show-save" select="false()"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;GraphMode'">
                        <!-- whole loaded document, deliberately not $doc: the graph shows the link structure between all resources in the response -->
                        <xsl:apply-templates select=".." mode="bs2:Graph">
                            <xsl:with-param name="canvas-id" select="generate-id() || '-graph-canvas'"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;EditMode'">
                        <xsl:apply-templates select="." mode="bs2:Form">
                            <xsl:with-param name="required" select="rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </div>
    </xsl:template>

    <!-- HEADER -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Header">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ldh-block-head'" as="xs:string?"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="bs2:Image"/>

            <!-- titles group: the type list reads as the block's badge, the description as its subtitle -->
            <div style="min-width: 0">
                <xsl:apply-templates select="." mode="bs2:TypeList"/>

                <h2 class="ttl">
                    <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="xhtml:Anchor"/>

                    <!-- the block state marker travels with every header and app.css reveals it only where this
                         block's body holds the empty state, so it cannot outlive the state it names -->
                    <span class="ldh-block-state is-empty">
                        <span class="msi outline" aria-hidden="true">inbox</span>
                        <span>
                            <xsl:apply-templates select="key('resources', 'block-state-empty', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </span>
                </h2>

                <xsl:where-populated>
                    <span class="sub">
                        <xsl:apply-templates select="." mode="ac:description"/>
                    </span>
                </xsl:where-populated>
            </div>

            <div class="actions">
                <xsl:apply-templates select="." mode="bs2:Timestamp"/>

                <xsl:if test="@rdf:about">
                    <xsl:apply-templates select="." mode="ldh:BlockLinksPopover"/>
                </xsl:if>

                <xsl:apply-templates select="." mode="bs2:Actions"/>
            </div>
        </div>
    </xsl:template>

    <!-- PROPERTY LIST -->

    <!-- suppress types in property list - we show them in the bs2:Header instead -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:PropertyList"/>

    <!-- override outer bs2:PropertyList so sort keys consume tunneled $property-metadata and $object-metadata
         (tunnel params don't cross xsl:function boundaries, so 1-arg ac:property-label/ac:object-label can't see them) -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:PropertyList">
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>

        <xsl:variable name="definitions" as="document-node()">
            <xsl:document>
                <dl>
                    <xsl:apply-templates select="*" mode="#current">
                        <xsl:sort select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)" order="ascending" lang="{$ac:lang}"/>
                        <xsl:sort select="ac:lang-rank(.)" order="ascending"/>
                        <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{$ac:lang}"/>
                    </xsl:apply-templates>
                </dl>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
    </xsl:template>

    <!-- wrap each predicate's dt/dd run in a <div> name-value group (HTML's dl grouping element), keyed
         on the dds' RDFa @property URI - the group is the styling unit (border, full-height hover band).
         Only the first dt of a group survives, replacing the outer label-based dt dedup: labels can
         collide across predicates, property URIs cannot -->
    <xsl:template match="xhtml:dl" mode="bs2:PropertyListIdentity">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>

            <xsl:for-each-group select="*" group-adjacent="string((self::xhtml:dd/@property, following-sibling::xhtml:dd[preceding-sibling::xhtml:dt[1] is current()][1]/@property)[1])">
                <div>
                    <xsl:apply-templates select="(current-group()/self::xhtml:dt)[1], current-group()/self::xhtml:dd" mode="#current"/>
                </div>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

    <!-- neutralize the outer label-based dt dedup (adjacent predicates sharing a label would lose the
         second group's dt) - the grouping above already drops repeated dts -->
    <xsl:template match="xhtml:dt" mode="bs2:PropertyListIdentity">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

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
        <!-- the edit form submits a PATCH, which AuthorizationFilter requires acl:Write for - so without that mode the button opens a form that cannot be saved -->
        <xsl:param name="show-edit-button" select="acl:mode() = '&acl;Write'" as="xs:boolean" tunnel="yes"/>

        <div>
            <!--
            <xsl:if test="doc-available($app-request-uri)">
                <xsl:variable name="apps" select="document($app-request-uri)" as="document-node()"/>
                <xsl:if test="$apps//*[sd:endpoint/@rdf:resource]">
                    <xsl:variable name="resource" select="." as="element()"/>
                    
                    <div class="btn-group">
                        <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm dropdown-toggle">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'reconcile-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:attribute>

                            <xsl:apply-templates select="key('resources', 'reconcile', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            <xsl:text> </xsl:text>
                            <span class="msi caret" aria-hidden="true">expand_more</span>
                        </button>
                        <ul class="dropdown-menu">
                            <xsl:for-each select="$apps//*[@rdf:about][sd:endpoint/@rdf:resource]">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ac:lang}"/>
                                
                                <li>
                                    <button class="btn-reconcile">
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
            
            <xsl:apply-templates select="." mode="ldh:CopyUriButton"/>

            <xsl:if test="$show-edit-button">
                <button type="button" class="btn-edit tb">
                    <xsl:attribute name="title">
                        <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                    </xsl:attribute>

                    <span class="msi sm" aria-hidden="true">edit</span>
                </button>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:Actions"/>
    
    <!-- TIMESTAMP -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Timestamp">
        <xsl:variable name="sorted-date-time-properties" as="element()*">
            <xsl:perform-sort select="(dct:created, dct:modified)[exists(ldh:date-time(string(.)))]">
                <xsl:sort select="ldh:date-time(string(.))" order="ascending"/>
            </xsl:perform-sort>
        </xsl:variable>
        <xsl:apply-templates select="$sorted-date-time-properties[last()]/text()"/>
    </xsl:template>
    
    <!-- TYPE LIST -->

    <xsl:template match="*[sioc:has_parent] | *[sioc:has_container]" mode="bs2:TypeList" priority="0.8"/>

    <xsl:template match="*[@rdf:about or @rdf:nodeID][rdf:type/@rdf:resource]" mode="bs2:TypeList">
        <ul class="ldh-typelist">
            <xsl:for-each select="rdf:type/@rdf:resource">
                <xsl:sort select="ac:object-label(.)" order="ascending" lang="{$ac:lang}"/>

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

        <xsl:for-each select="$predicates[@rdf:resource]"> <!-- do not iterate $predicates/@rdf:resource sequence as it will be sorted differently -->
            <xsl:apply-templates select="key('resources', @rdf:resource)" mode="bs2:Row"/>
        </xsl:for-each>
    </xsl:template>

    <!-- ROW CONTENT HEADER -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;Object']" mode="bs2:RowContentHeader" priority="1">
        <xsl:variable name="anchor" as="node()*">
            <xsl:for-each select="@rdf:about">
                <xsl:variable name="request-uri" select="ldh:href(ac:document-uri(.), map{ 'accept': 'application/rdf+xml' }, ())" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SaxonJS'"/>
                <xsl:variable name="request-uri" select="ac:document-uri(.)" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                <xsl:apply-templates select="key('resources', ., document($request-uri))" mode="xhtml:Anchor">
                    <xsl:with-param name="class" as="xs:string?">
                        <xsl:apply-templates select="." mode="ldh:logo"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:if test="exists($anchor)">
            <div class="block-row">
                <div class="main">
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
        
        <button title="{@rdf:about}" data-for-shape="{@rdf:about}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <xsl:choose>
                <xsl:when test="$with-label">
                    <xsl:apply-templates select="." mode="ldh:logo">
                        <xsl:with-param name="class" select="'it add-constructor'"/>
                    </xsl:apply-templates>

                    <xsl:value-of>
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ldh:logo">
                        <xsl:with-param name="class" select="'it add-constructor'"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </button>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="bs2:ConstructorListItem">
        <xsl:param name="create-graph" select="false()" as="xs:boolean"/>
        <!-- on SaxonJS proxy via ldh:href (no browser catalog, cross-origin term URIs would otherwise hit mixed-content); on SAXON keep the raw URI so Jena's location-mapping resolves it locally -->
        <xsl:param name="request-uri" select="ldh:href(ac:document-uri(@rdf:about), map{ 'accept': 'application/rdf+xml' }, ())" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SaxonJS'"/>
        <xsl:param name="request-uri" select="ac:document-uri(@rdf:about)" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>
        <xsl:param name="icon" select="(map:get($ldh:class-icons, string(@rdf:about)), 'category')[1]" as="xs:string"/>

        <xsl:if test="doc-available($request-uri)">
            <button type="button" class="it add-constructor" title="{@rdf:about}" data-for-class="{@rdf:about}">
                <xsl:if test="$create-graph">
                    <xsl:attribute name="data-create-graph" select="'true'"/>
                </xsl:if>

                <span class="ico">
                    <span class="msi sm" aria-hidden="true">
                        <xsl:value-of select="$icon"/>
                    </span>
                </span>
                <span class="body">
                    <span class="lbl">
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </span>
                </span>
            </button>
        </xsl:if>
    </xsl:template>
    
    <!-- ROW FORM -->

    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="bs2:RowForm" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:RowForm">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="form-id" select="'form-' || generate-id()" as="xs:string?"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="action" select="ldh:href(ac:absolute-path($base-uri))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="enctype" select="if ($typeof = '&nfo;FileDataObject') then 'multipart/form-data' else ()" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldh-btn'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="show-cancel-button" select="true()" as="xs:boolean"/>
        <xsl:param name="show-form-actions" select="true()" as="xs:boolean"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>

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
            
            <div>
                <xsl:if test="$main-class">
                    <xsl:attribute name="class" select="$main-class"/>
                </xsl:if>
                
                <form method="{$method}" action="{$action}" class="ldh-prop-form">
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
                        <xsl:with-param name="action" select="$action" tunnel="yes"/>
                        <xsl:with-param name="required" select="rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')" tunnel="yes"/>
                    </xsl:apply-templates>

                    <xsl:if test="$show-form-actions">
                        <div class="ldh-block-foot">
                            <xsl:if test="$show-cancel-button">
                                <button type="button" class="ldh-btn is-ghost btn-cancel">
                                    <xsl:value-of>
                                        <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:value-of>
                                </button>
                            </xsl:if>

                            <button type="reset" class="ldh-btn is-ghost btn-reset">
                                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </button>

                            <button type="submit" class="{$button-class} btn-save">
                                <span class="msi sm" aria-hidden="true">save</span>
                                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </button>
                        </div>
                    </xsl:if>
                </form>
            </div>
        </div>
    </xsl:template>
    
    <!-- FORM -->
    
    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="bs2:Form" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Form">
        <xsl:param name="required" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:apply-templates select="." mode="bs2:FormControl">
            <xsl:with-param name="inline" select="false()" tunnel="yes"/>
            <xsl:with-param name="required" select="$required"/>
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
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:FormControl" name="bs2:FormControl">
        <xsl:param name="id" select="concat('fieldset-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="violations" select="key('violations-by-value', */@rdf:resource) | key('violations-by-root', (@rdf:about, @rdf:nodeID)) | key('violations-by-focus-node', (@rdf:about, @rdf:nodeID))" as="element()*"/>
        <xsl:param name="forClass" select="distinct-values(rdf:type/@rdf:resource)" as="xs:anyURI*"/>
        <xsl:param name="type-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="constructors" as="document-node()?" tunnel="yes"/> <!-- not used to build $constructor -->
        <xsl:param name="constraints" as="document-node()?" tunnel="yes"/>
        <xsl:param name="shapes" as="document-node()?" tunnel="yes"/>
        <!-- include both sh:NodeShape and its connected sh:PropertyShapes in $type-shapes -->
        <xsl:param name="type-shapes" select="if ($shapes) then (key('shapes-by-target-class', $forClass, $shapes), key('resources', key('shapes-by-target-class', $forClass, $shapes)/sh:property/@rdf:resource, $shapes)) else ()" as="element()*"/>
        <xsl:param name="constructor" as="document-node()?" tunnel="yes">
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
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-hidden" select="false()" as="xs:boolean"/>
        <xsl:param name="show-property-control" select="true()" as="xs:boolean"/>
        <!-- inner fieldset content; default is the merged-properties iteration (resource description merged with deduped constructor template properties). Override via xsl:with-param name="body" to substitute a different iteration (e.g. mode="#current" so the caller's mode templates fire per property) while reusing the fieldset shell. -->
        <xsl:param name="body" as="node()*">
            <xsl:variable name="resource-predicates" select="*/concat(namespace-uri(), local-name())" as="xs:string*"/>
            <xsl:variable name="merged-properties" as="element()*">
                <xsl:sequence select="*"/>
                <xsl:for-each-group select="$template/*[not(self::rdf:type)]" group-by="concat(namespace-uri(), local-name())">
                    <xsl:if test="not(current-grouping-key() = $resource-predicates)">
                        <xsl:sequence select="."/>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:variable>
            <xsl:apply-templates select="$merged-properties" mode="#current">
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
        </xsl:param>

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
                        <xsl:value-of select="ac:label(.)"/>

                        <div class="actions">
                            <xsl:if test="exists($type-metadata) and exists($constructors)">
                                <div class="btn-group">
                                    <!-- show list of types that have constructors (excluding built-in system classes) -->
                                    <xsl:variable name="constructor-classes" select="distinct-values($constructors//srx:binding[@name = 'Type']/srx:uri)[not(starts-with(., '&dh;') or starts-with(., '&ldh;') or starts-with(., '&def;') or starts-with(., '&lapp;') or starts-with(., '&sp;') or starts-with(., '&nfo;'))]" as="xs:anyURI*"/>

                                    <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm dropdown-toggle btn-edit-actions">
                                        <!-- only admins should see the button as only they have access to the ontologies with constructors in them -->
                                        <xsl:if test="not(acl:mode() = '&acl;Control' and exists($constructor-classes))">
                                            <xsl:attribute name="style" select="'display: none'"/>
                                        </xsl:if>

                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'actions', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                        </xsl:value-of>
                                        <span class="msi caret" aria-hidden="true">expand_more</span>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <xsl:for-each select="$constructor-classes">
                                            <li>
                                                <button type="button" class="btn-edit-constructors" data-resource-type="{.}">
                                                    <xsl:value-of>
                                                        <xsl:apply-templates select="key('resources', 'edit', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                    </xsl:value-of>
                                                    <xsl:text> </xsl:text>
                                                    <!-- query class description from the namespace ontology (because it might not be available as Linked Data) -->
                                                    <xsl:apply-templates select="key('resources', ., $type-metadata)" mode="ac:label"/>
                                                    <xsl:text> </xsl:text>
                                                    <xsl:value-of>
                                                        <xsl:apply-templates select="key('resources', 'constructors', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                    </xsl:value-of>
                                                </button>
                                            </li>
                                        </xsl:for-each>
                                    </ul>
                                </div>
                            </xsl:if>
                            
                            <!-- button that toggles the .control-group for subject URI/bnode ID editing -->
                            <button type="button" class="ldhc-btn in-neutral ap-ghost sz-sm is-iconly btn-edit-subj {if ($show-subject) then 'open' else ()}"><span class="msi sm" aria-hidden="true">edit</span></button>
                        </div>
                        
                        <!-- "Copy URI" button -->
                        <button type="button">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:attribute>

                            <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'ldhc-btn in-neutral ap-ghost sz-sm'"/>
                            </xsl:apply-templates>

                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'copy-uri', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>

                        <xsl:if test="not($required)">
                            <div class="btn-group">
                                <button type="button" class="tb btn-remove-resource">
                                    <xsl:attribute name="title">
                                        <xsl:apply-templates select="key('resources', 'remove-resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                    </xsl:attribute>

                                    <span class="msi sm" aria-hidden="true">close</span>
                                </button>
                            </div>
                        </xsl:if>
                    </legend>
                </xsl:when>
                <xsl:when test="not($required)">
                    <div class="btn-group">
                        <button type="button" class="tb btn-remove-resource">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'remove-resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">close</span>
                        </button>
                    </div>
                </xsl:when>
            </xsl:choose>

            <!-- @rdf:about / @rdf:nodeID rendering is shell behavior, not per-flow customizable; dispatch in bs2:FormControl mode explicitly so it works regardless of whether the shell was entered via the match template (mode=bs2:FormControl) or the named template (e.g. from ldh:DocumentForm / ldh:AppSettingsForm wrapper modes) -->
            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="bs2:FormControl">
                <xsl:with-param name="type" select="if ($show-subject) then 'text' else 'hidden'"/>
            </xsl:apply-templates>
    
            <xsl:apply-templates select="." mode="bs2:TypeControl">
                <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                <xsl:with-param name="hidden" select="$type-hidden"/>
            </xsl:apply-templates>

            <xsl:if test="exists($violations)">
                <div class="violations">
                    <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
                </div>
            </xsl:if>

            <xsl:sequence select="$body"/>

            <xsl:if test="$show-property-control">
                <xsl:apply-templates select="." mode="bs2:PropertyControl">
                    <xsl:with-param name="template" select="$template"/>
                    <xsl:with-param name="forClass" select="$forClass"/>
                    <xsl:with-param name="required" select="true()"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata"/>
                </xsl:apply-templates>
            </xsl:if>
        </fieldset>
    </xsl:template>

    <!-- Admin app override: allow subject editing for non-hierarchy resources by flipping the $show-subject default. -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][starts-with(replace(lapp:origin(), '^https?://', ''), 'admin.')]" mode="bs2:FormControl" priority="1">
        <xsl:param name="legend" select="true()" as="xs:boolean"/>
        <xsl:param name="show-subject" select="not(rdf:type/@rdf:resource = ('&dh;Item', '&dh;Container'))" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>

        <xsl:next-match>
            <xsl:with-param name="legend" select="$legend"/>
            <xsl:with-param name="show-subject" select="$show-subject" tunnel="yes"/>
            <xsl:with-param name="required" select="$required"/>
        </xsl:next-match>
    </xsl:template>

    <!-- TYPE CONTROL -->

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
    
    <!-- hide property dropdown for block instances -->
    
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object')]" mode="bs2:PropertyControl" priority="1"/>
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]" mode="bs2:PropertyControl">
        <xsl:param name="class" as="xs:string?"/>
        <!--<xsl:param name="label" select="true()" as="xs:boolean"/>-->
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:variable name="seq-properties" select="for $property in ../rdf:Description/*/concat(namespace-uri(), local-name())[starts-with(., '&rdf;' || '_')] return xs:anyURI($property)" as="xs:anyURI*"/>
        <xsl:variable name="max-seq-index" select="if (empty($seq-properties)) then 0 else max(for $seq-property in $seq-properties return xs:integer(substring-after($seq-property, '&rdf;' || '_')))" as="xs:integer"/>

        <div class="control-group">
            <span class="control-label">
                <select>
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
                <button type="button" id="button-{generate-id()}" class="tb add-value">
                    <span class="msi sm" aria-hidden="true">add</span>
                </button>
            </div>
        </div>
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
        <xsl:param name="request-uri" select="ldh:href(ac:document-uri(rdf:type/@rdf:resource), map{ 'accept': 'application/rdf+xml' }, ())" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SaxonJS'"/>
        <xsl:param name="request-uri" select="ac:document-uri(rdf:type/@rdf:resource)" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', rdf:type/@rdf:resource, document($request-uri))" mode="ldh:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="." mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>
    
    <xsl:template match="*[rdf:type/@rdf:resource = '&sh;ValidationResult']" mode="bs2:Violation">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>
        <xsl:param name="request-uri" select="ldh:href(ac:document-uri(rdf:type/@rdf:resource), map{ 'accept': 'application/rdf+xml' }, ())" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SaxonJS'"/>
        <xsl:param name="request-uri" select="ac:document-uri(rdf:type/@rdf:resource)" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="key('resources', rdf:type/@rdf:resource, document($request-uri))" mode="ldh:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of select="sh:resultMessage"/>
        </div>
    </xsl:template>
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="bs2:Exception"/>

    <!-- OBJECT -->
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Object"/>

    <!-- ### SHARED BETWEEN SERVER AND CLIENT -->
    
    <!-- TYPEAHEAD -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:Typeahead">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'ldhc-btn in-neutral ap-solid sz-sm add-typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="title" select="(@rdf:about, @rdf:nodeID)[1]" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <span>
            <xsl:if test="exists($forClass)">
                <xsl:attribute name="data-for-class" select="string-join($forClass, ' ')"/>
            </xsl:if>
            
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

                <span>
                    <xsl:value-of>
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </xsl:value-of>
                </span>
                <span class="msi caret" aria-hidden="true">expand_more</span>

                <xsl:if test="@rdf:about">
                    <input type="hidden" name="ou" value="{@rdf:about}"/>
                </xsl:if>
                <xsl:if test="@rdf:nodeID">
                    <input type="hidden" name="ob" value="{@rdf:nodeID}"/>
                </xsl:if>
            </button>
        </span>
    </xsl:template>
    
</xsl:stylesheet>
