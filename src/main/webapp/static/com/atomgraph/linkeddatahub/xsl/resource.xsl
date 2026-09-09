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

    <!-- the single icon-from-type derivation: first mapped glyph of the resource's types, else the caller's fallback -->
    <xsl:function name="ldh:class-icon" as="xs:string?">
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="fallback" as="xs:string?"/>

        <xsl:sequence select="($resource/rdf:type/@rdf:resource ! map:get($ldh:class-icons, string(.)), $fallback)[1]"/>
    </xsl:function>

    <!-- LABEL -->

    <xsl:template match="*[@rdf:about = '&owl;NamedIndividual']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'instance', ldh:translations())" mode="ac:label"/>
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
    
    <xsl:template match="*[@rdf:about]" mode="schema:ListItem" as="element()">
        <rdf:Description rdf:nodeID="item{position()}">
            <rdf:type rdf:resource="&schema;ListItem"/>
            <schema:position><xsl:value-of select="position()"/></schema:position>
            <schema:name><xsl:value-of select="ac:label(.)"/></schema:name>
            <schema:item><xsl:value-of select="@rdf:about"/></schema:item>
        </rdf:Description>
    </xsl:template>
    
    <!-- BREADCRUMBS -->

    <xsl:template match="*[@rdf:about]" mode="ac:BreadcrumbItem">
        <xsl:param name="leaf" select="true()" as="xs:boolean"/>
        <!-- crumb icon by document type, as in the design system's breadcrumb -->
        <xsl:param name="icon" select="ldh:class-icon(., 'link')" as="xs:string"/>

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
            <button type="button" class="ldhc-iconbtn sz-sm in-accent ap-ghost tb-links" aria-pressed="false">
                <xsl:attribute name="title">
                    <xsl:apply-templates select="key('resources', 'backlinks', ldh:translations())" mode="ac:label"/>
                </xsl:attribute>

                <span class="msi sm" aria-hidden="true">link</span>
            </button>

            <div class="links-pop">
                <h2 class="dh2">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', 'backlinks', ldh:translations())" mode="ac:label"/>
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
        <xsl:param name="class" select="'ldhc-iconbtn sz-sm in-neutral ap-ghost btn-copy-uri'" as="xs:string"/>

        <button type="button" class="{$class}">
            <xsl:attribute name="title">
                <xsl:apply-templates select="key('resources', 'copy-uri', ldh:translations())" mode="ac:label"/>
            </xsl:attribute>

            <span class="msi sm" aria-hidden="true">content_copy</span>
        </button>
    </xsl:template>

    <!-- EDIT BUTTON -->

    <!-- opens the whole-resource edit form for the nearest addressable block. Context-free markup like
         ldh:CopyUriButton: the onclick handler in client/form.xsl resolves the target from the ancestor
         block's @about at click time. -->
    <xsl:template match="*" mode="ldh:EditButton">
        <xsl:param name="class" select="'ldhc-iconbtn sz-sm in-neutral ap-ghost btn-edit'" as="xs:string"/>

        <button type="button" class="{$class}">
            <xsl:attribute name="title">
                <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
            </xsl:attribute>

            <span class="msi sm" aria-hidden="true">edit</span>
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

    <xsl:template match="*[@rdf:about]" mode="ac:ModeSwitcherItem">
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
        <xsl:param name="desc-keys" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:map-entry key="'&ldh;ContentMode'" select="'content-mode-desc'"/>
                <xsl:map-entry key="'&ac;ReadMode'" select="'read-mode-desc'"/>
                <xsl:map-entry key="'&ac;ListMode'" select="'list-mode-desc'"/>
                <xsl:map-entry key="'&ac;TableMode'" select="'table-mode-desc'"/>
                <xsl:map-entry key="'&ac;GridMode'" select="'grid-mode-desc'"/>
                <xsl:map-entry key="'&ac;MapMode'" select="'map-mode-desc'"/>
                <xsl:map-entry key="'&ac;ChartMode'" select="'chart-mode-desc'"/>
                <xsl:map-entry key="'&ac;GraphMode'" select="'graph-mode-desc'"/>
            </xsl:map>
        </xsl:param>

        <!-- a menu item radio (the design's ModeSwitcher): a link when the mode is URL-addressable,
             a button when the switch is client state only (the view modes) -->
        <xsl:element name="{if ($href) then 'a' else 'button'}" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'mi' || (if ($class) then ' ' || $class else ())"/>
            <xsl:attribute name="role" select="'menuitemradio'"/>
            <xsl:attribute name="aria-checked" select="if ($active) then 'true' else 'false'"/>
            <xsl:choose>
                <xsl:when test="$href">
                    <xsl:attribute name="href" select="$href"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="type" select="'button'"/>
                </xsl:otherwise>
            </xsl:choose>
            <span class="msi sm" aria-hidden="true">
                <xsl:value-of select="map:get($ldh:mode-icons, string(@rdf:about))"/>
            </span>
            <span class="label-col">
                <span class="label">
                    <xsl:apply-templates select="." mode="ac:label"/>
                </span>
                <xsl:for-each select="map:get($desc-keys, string(@rdf:about))">
                    <span class="desc">
                        <xsl:apply-templates select="key('resources', ., ldh:translations())" mode="ac:label"/>
                    </span>
                </xsl:for-each>
            </span>
            <xsl:if test="$active">
                <span class="msi sm tick" aria-hidden="true">check</span>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <!-- DEFAULT -->

    <!-- the unnamed resource dispatch emits block BODY content only: ldh:BlockRow owns the card and its
         header/body slots (the design keeps head and body as siblings), so Web-Client's full-block
         default (div.block > header + property list) is overridden here -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]">
        <xsl:apply-templates select="." mode="ac:PropertyEditor"/>
    </xsl:template>

    <!-- embed file content -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&nfo;FileDataObject'][dct:format]" priority="2">
        <xsl:apply-templates select="." mode="ac:PropertyEditor"/>

        <xsl:variable name="media-type" select="substring-after(dct:format[1]/@rdf:resource, 'http://www.sparontologies.net/mediatype/')" as="xs:string"/>
        <object data="{@rdf:about}" type="{$media-type}"></object>
    </xsl:template>

    <!-- BLOCK -->

    <!-- hide inlined blank node resources from the main block flow -->
    <xsl:template match="*[*][key('resources', @rdf:nodeID)][count(key('predicates-by-object', @rdf:nodeID)[not(self::foaf:primaryTopic)]) = 1]" mode="ldh:BlockRow" priority="1">
        <xsl:param name="display" select="false()" as="xs:boolean" tunnel="yes"/>
        
        <xsl:if test="$display">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <!-- hide instances of system classes -->
    <xsl:template match="*[not($ldh:renderSystemResources)][@rdf:about = ac:absolute-path(ldh:base-uri(.)) and rdf:type/@rdf:resource = ('&def;Root', '&dh;Container', '&dh;Item')]" mode="ldh:BlockRow" priority="1"/>

    <!-- ldh:BlockRow: the design system's row layer (div.ldh-block-row > div.row-main) around the block card,
         mirroring the BlockRow/Block component split in the design's Blocks.jsx. One template owns the
         scaffolding - the row carries @id/@about/diff/@draggable, .row-main carries the drag handle - and the
         per-type variance lives in the ldh:Block card mode below. Emitted by both products so that server- and
         client-rendered markup have the same shape: the ontology-driven view injection in client/block.xsl keys
         off this exact nesting (outer div.ldh-block-row[@about] / div.row-main / inner div.block[@typeof]).
         An ontology-injected (derived) block renders as the nested-block well instead: no row layer, and the
         stored-block chrome is omitted - drag reorder needs rdf:_N membership, the row edit form needs a subject
         that exists in the graph, and the host block's bar already spans this block's load - so only the head
         and the RDFa body remain -->
    <!-- TO-DO: replace with fully client-side wrapper in ldh:RenderRow in block.xsl -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:BlockRow">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean?"/>
        <xsl:param name="show-block-bar" select="true()" as="xs:boolean"/>
        <xsl:param name="show-drag-handle" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="nested" select="false()" as="xs:boolean"/>
        <xsl:param name="depth" select="1" as="xs:integer"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="$nested">
                <xsl:variable name="block-type" select="(rdf:type/@rdf:resource[. = ('&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select')])[1]" as="xs:anyURI?"/>
                <xsl:variable name="glyph" select="map{ '&ldh;View': 'table_rows', '&ldh;GraphChart': 'show_chart', '&ldh;ResultSetChart': 'show_chart', '&sp;Describe': 'code', '&sp;Construct': 'code', '&sp;Ask': 'code', '&sp;Select': 'code' }(string($block-type))" as="xs:string?"/>

                <div>
                    <xsl:if test="$id">
                        <xsl:attribute name="id" select="$id"/>
                    </xsl:if>
                    <xsl:attribute name="class" select="string-join(('block ldh-nblock', $diff-class), ' ')"/>
                    <xsl:if test="$about">
                        <xsl:attribute name="about" select="$about"/>
                    </xsl:if>
                    <xsl:attribute name="data-depth" select="min((3, $depth))"/>

                    <!-- THE header - the same component as a top-level block's, at compact density: depth
                         changes the density, never the structure. Links stay off inside the well, and the
                         derived block is not reorderable (no rdf:_N membership), so no drag slot either -->
                    <xsl:apply-templates select="." mode="ac:BlockHeader">
                        <xsl:with-param name="density" select="'compact'"/>
                        <xsl:with-param name="icon" select="($glyph, 'widgets')[1]"/>
                        <xsl:with-param name="show-links" select="false()"/>
                    </xsl:apply-templates>
                    <div class="ldh-nblock-body">
                        <div class="block-row" typeof="{string-join($typeof, ' ')}">
                            <div class="main">
                                <xsl:apply-templates select="." mode="ac:PropertyEditor"/>
                            </div>
                        </div>
                    </div>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div>
                    <xsl:attribute name="class" select="string-join(('ldh-block-row', $diff-class), ' ')"/>
                    <xsl:if test="$id">
                        <xsl:attribute name="id" select="$id"/>
                    </xsl:if>
                    <xsl:if test="$about">
                        <xsl:attribute name="about" select="$about"/>
                    </xsl:if>
                    <xsl:if test="$draggable = true()">
                        <xsl:attribute name="draggable" select="'true'"/>
                    </xsl:if>

                    <div class="row-main">
                        <xsl:apply-templates select="." mode="ldh:Block">
                            <xsl:with-param name="about" select="$about"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="style" select="$style"/>
                            <xsl:with-param name="show-block-bar" select="$show-block-bar"/>
                        </xsl:apply-templates>
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ldh:Block: the block card, the row layer's counterpart of the design's Block component. Templates here
         emit the card and its children only (head, bar, body, actions); a new block type adds one card template
         and the row scaffolding above needs no change. ldh:RowForm is this layer's edit-mode peer: it returns a
         card with the same contract, which is what lets the edit flows replace cards in place -->

    <!-- typed resource card: the carrier's header + loading bar + the CSR container the hydration chain fills -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&ldh;Object', '&ldh;View', '&ldh;GraphChart', '&ldh;ResultSetChart', '&sp;Describe', '&sp;Construct', '&sp;Ask', '&sp;Select')]" mode="ldh:Block" priority="1">
        <!-- TO-DO: use ldh:request-uri() to resolve URIs server-side -->
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="show-block-bar" select="true()" as="xs:boolean"/>
        <xsl:param name="show-drag-handle" select="true()" as="xs:boolean" tunnel="yes"/>

        <div>
            <xsl:attribute name="class" select="string-join(($class, 'is-loading'[$show-block-bar]), ' ')"/>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>
            <xsl:if test="$show-block-bar">
                <xsl:attribute name="aria-busy" select="'true'"/>
            </xsl:if>

            <!-- the carrier resource's own header: title, type chips, actions. Head, bar and
                 body are siblings of the card (the bar shows under the head while loading) -->
            <xsl:apply-templates select="." mode="ac:BlockHeader">
                <xsl:with-param name="draggable" select="$show-drag-handle"/>
            </xsl:apply-templates>

            <xsl:if test="$show-block-bar">
                <xsl:apply-templates select="." mode="ldh:BlockBar"/>
            </xsl:if>

            <!-- client-side $container -->
            <xsl:next-match>
                <xsl:with-param name="about" select="()"/> <!-- the card carries @about -->
                <xsl:with-param name="class" select="'block-row'"/>
                <xsl:with-param name="show-header" select="false()"/>
            </xsl:next-match>
        </div>
    </xsl:template>

    <!-- XHTML content card -->
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&ldh;XHTML'][rdf:value[@rdf:parseType = 'Literal']/xhtml:div]" mode="ldh:Block" priority="1">
        <!-- XHTML content is prose: quiet block, no card surface, reads as part of the page flow -->
        <xsl:param name="class" select="'block ldh-block is-quiet'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>
        <xsl:param name="show-drag-handle" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$about">
                <xsl:attribute name="about" select="$about"/>
            </xsl:if>

            <!-- one header for every block type (the design's TextBlock is a quiet Block with the same
                 header); the drag slot rides it, replacing the gutter handle -->
            <xsl:if test="$about">
                <xsl:apply-templates select="." mode="ac:BlockHeader">
                    <xsl:with-param name="draggable" select="$show-drag-handle"/>
                </xsl:apply-templates>
            </xsl:if>

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

            </div>
        </div>
    </xsl:template>

    <!-- default card: the resource's header + property-list body (or the per-mode body for Map/Chart/Graph/Edit) -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:Block">
        <!-- 'block' is the token every CSR handler anchors on; 'ldh-block' is what app.css styles -->
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="main-class" select="'main ldh-block-body'" as="xs:string?"/>
        <xsl:param name="show-header" select="true()" as="xs:boolean"/>
        <xsl:param name="show-drag-handle" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <div>
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

            <!-- head and body are siblings (the design's Block anatomy); the edit form titles itself
                 with its fieldset legend, so EditMode skips the header rather than doubling the title -->
            <xsl:if test="$show-header and not($mode = '&ac;EditMode')">
                <xsl:apply-templates select="." mode="ac:BlockHeader">
                    <xsl:with-param name="draggable" select="$show-drag-handle"/>
                </xsl:apply-templates>
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
                        <xsl:apply-templates select="$doc" mode="ac:Map">
                            <xsl:with-param name="id" select="generate-id() || '-map-canvas'"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;ChartMode'">
                        <xsl:apply-templates select="$doc" mode="ldh:Chart">
                            <xsl:with-param name="canvas-id" select="generate-id() || '-chart-canvas'"/>
                            <xsl:with-param name="show-save" select="false()"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;GraphMode'">
                        <!-- whole loaded document, deliberately not $doc: the graph shows the link structure between all resources in the response -->
                        <xsl:apply-templates select=".." mode="ac:Graph">
                            <xsl:with-param name="canvas-id" select="generate-id() || '-graph-canvas'"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;EditMode'">
                        <xsl:apply-templates select="." mode="ac:ResourceForm">
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

    <!-- the design's composite resource header (.ldh-res-head): thumbnail or class icon, title with its type
         chips inline, description lede, actions. One header serves every resource - chart and query blocks
         included, whose kind now reads off the type chip instead of a .sub fallback -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:BlockHeader">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'ldh-block-head ldh-res-head'" as="xs:string?"/>
        <xsl:param name="density" select="'default'" as="xs:string"/> <!-- default | compact: nesting depth, not type -->
        <xsl:param name="icon" as="xs:string?"/>
        <xsl:param name="draggable" select="false()" as="xs:boolean"/>
        <xsl:param name="show-links" select="true()" as="xs:boolean"/>

        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="not($density = 'default')">
                <xsl:attribute name="data-density" select="$density"/>
            </xsl:if>

            <!-- the design's drag slot: present when the block is reorderable, which is also the
                 authorization gate - only acl:Write can PATCH the new content order -->
            <xsl:if test="$draggable and acl:mode() = '&acl;Write'">
                <span class="ldh-bh-drag" role="button" tabindex="0" draggable="true" aria-label="{ac:label(key('resources', 'drag-to-reorder', ldh:translations()))}" title="{ac:label(key('resources', 'drag-to-reorder', ldh:translations()))}">
                    <span class="msi sm" aria-hidden="true">drag_indicator</span>
                </span>
            </xsl:if>

            <xsl:apply-templates select="." mode="ac:Depiction">
                <xsl:with-param name="icon" select="($icon, ldh:class-icon(., ()))[1]"/>
            </xsl:apply-templates>

            <div class="ldh-res-text">
                <div class="ldh-res-titleline">
                    <h2 class="ttl">
                        <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="xhtml:Anchor"/>
                    </h2>

                    <xsl:apply-templates select="." mode="ac:ResourceTypes"/>
                </div>

                <xsl:where-populated>
                    <p class="ldh-res-desc">
                        <xsl:apply-templates select="." mode="ac:description"/>
                    </p>
                </xsl:where-populated>
            </div>

            <div class="actions">
                <xsl:apply-templates select="." mode="ldh:Timestamp"/>

                <xsl:if test="$show-links and @rdf:about">
                    <xsl:apply-templates select="." mode="ldh:BlockLinksPopover"/>
                </xsl:if>

                <xsl:apply-templates select="." mode="ac:BlockActions"/>
            </div>
        </div>
    </xsl:template>

    <!-- PROPERTY LIST -->

    <!-- suppress types in property list - we show them in the ac:BlockHeader instead -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="ac:PropertyEditor"/>

    <!-- override outer ac:PropertyEditor so sort keys consume tunneled $property-metadata and $object-metadata
         (tunnel params don't cross xsl:function boundaries, so 1-arg ac:property-label/ac:object-label can't see them) -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:PropertyEditor">
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>

        <xsl:variable name="definitions" as="document-node()">
            <xsl:document>
                <dl>
                    <xsl:apply-templates select="*" mode="#current">
                        <xsl:sort select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)" order="ascending" lang="{ac:langs()[1]}"/>
                        <xsl:sort select="ac:lang-rank(.)" order="ascending"/>
                        <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then (if ($object-metadata) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1], $object-metadata) else ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1])) else ()" order="ascending" lang="{ac:langs()[1]}"/>
                    </xsl:apply-templates>
                </dl>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$definitions" mode="ac:PropertyGroups"/>
    </xsl:template>

    <!-- project the intermediate dt/dd list onto the design's property grid, keeping the dl/dt/dd
         carriers: a resource description is an association list, which is exactly what dl is specified
         for, so the semantic elements and the RDFa attributes ride the same markup the grid styles.
         One .ldh-prop-group per predicate (keyed on the dds' RDFa @property URI - labels can collide
         across predicates, property URIs cannot; the div group wrapper is the HTML spec's own dl
         grouping element), the dt's label in the spanning .label cell, each dd as a .ldh-prop-row.
         The RDFa attributes ride the .value cell, not the dd: an RDFa literal is its element's text
         content, and on the dd the layout whitespace around the cells would pollute it (and crash
         the client-side text() extractions in chart.xsl/view.xsl). The trailing empty .row-actions
         cell completes the grid row so the statement delimiter reaches the card's right inset -->
    <xsl:template match="xhtml:dl" mode="ac:PropertyGroups">
        <dl class="ldh-prop-form">
            <xsl:for-each-group select="*" group-adjacent="string((self::xhtml:dd/@property, following-sibling::xhtml:dd[preceding-sibling::xhtml:dt[1] is current()][1]/@property)[1])">
                <xsl:variable name="property-uri" select="current-grouping-key()" as="xs:string"/>
                <xsl:variable name="dt" select="(current-group()/self::xhtml:dt)[1]" as="element()?"/>
                <xsl:variable name="dds" select="current-group()/self::xhtml:dd" as="element()*"/>

                <div class="ldh-prop-group">
                    <xsl:if test="count($dds) gt 1">
                        <xsl:attribute name="style" select="'--rows: ' || count($dds)"/>
                    </xsl:if>

                    <dt class="label">
                        <xsl:if test="count($dds) gt 1">
                            <xsl:attribute name="style" select="'grid-row: span ' || count($dds)"/>
                        </xsl:if>

                        <span class="pred" title="{$property-uri}">
                            <xsl:sequence select="$dt/node()"/>
                        </span>
                    </dt>

                    <xsl:for-each select="$dds">
                        <dd class="ldh-prop-row{if (position() = last()) then ' is-last' else ()}">
                            <div class="value{@class ! (' ' || .)}">
                                <xsl:copy-of select="@* except @class"/>
                                <xsl:sequence select="node()"/>
                            </div>
                            <div class="row-actions"></div>
                        </dd>
                    </xsl:for-each>
                </div>
            </xsl:for-each-group>
        </dl>
    </xsl:template>

    <!-- IMAGE -->
    
    <!-- the depiction thumbnail and the class icon share one 72px footprint (.ldh-res-thumb/.ldh-res-icon),
         so the title starts at the same x whether or not the resource carries an image; resources whose
         class has no icon mapping render neither, as in the design's BlockHeader -->
    <!-- URI-named thumbs link to the resource; blank-node thumbs render the same anatomy inert -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="ac:Depiction">
        <xsl:param name="icon" select="ldh:class-icon(., ())" as="xs:string?"/>

        <xsl:variable name="image-uris" as="xs:anyURI*">
            <xsl:apply-templates select="." mode="ac:image"/>
        </xsl:variable>
        <xsl:variable name="this" select="." as="element()"/>

        <xsl:choose>
            <xsl:when test="exists($image-uris)">
                <xsl:for-each select="$image-uris[1]">
                    <xsl:element name="{if ($this/@rdf:about) then 'a' else 'span'}" namespace="http://www.w3.org/1999/xhtml">
                        <xsl:attribute name="class" select="'ldh-res-thumb'"/>
                        <xsl:if test="$this/@rdf:about">
                            <xsl:attribute name="href" select="$this/@rdf:about"/>
                            <xsl:attribute name="title" select="ac:label($this)"/>
                        </xsl:if>

                        <img src="{.}" alt="{ac:label($this)}"/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="exists($icon)">
                <span class="ldh-res-icon">
                    <span class="msi outline" aria-hidden="true">
                        <xsl:value-of select="$icon"/>
                    </span>
                </span>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

    <!-- ACTIONS -->

    <xsl:template match="*[@rdf:about]" mode="ac:BlockActions" priority="1">
        <!-- the edit form submits a PATCH, which AuthorizationFilter requires acl:Write for - so without that mode the button opens a form that cannot be saved -->
        <xsl:param name="show-edit-button" select="acl:mode() = '&acl;Write'" as="xs:boolean" tunnel="yes"/>

        <div>
            <!--
            <xsl:if test="doc-available($app-request-uri)">
                <xsl:variable name="apps" select="document($app-request-uri)" as="document-node()"/>
                <xsl:if test="$apps//*[sd:endpoint/@rdf:resource]">
                    <xsl:variable name="resource" select="." as="element()"/>
                    
                    <div class="ldhc-menu-anchor">
                        <button type="button" class="ldhc-btn in-neutral ap-solid sz-sm drop-toggle">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'reconcile-title', ldh:translations())" mode="ac:label"/>
                            </xsl:attribute>

                            <xsl:apply-templates select="key('resources', 'reconcile', ldh:translations())" mode="ac:label"/>
                            <xsl:text> </xsl:text>
                            <span class="msi caret" aria-hidden="true">expand_more</span>
                        </button>
                        <ul class="ldhc-menu">
                            <xsl:for-each select="$apps//*[@rdf:about][sd:endpoint/@rdf:resource]">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{ac:langs()[1]}"/>
                                
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
                <xsl:apply-templates select="." mode="ldh:EditButton"/>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="ac:BlockActions"/>
    
    <!-- TIMESTAMP -->

    <!-- the single "latest of created/modified" selection, shared by ldh:Timestamp and the list row's .ts cell -->
    <xsl:function name="ldh:latest-date-time" as="element()?">
        <xsl:param name="resource" as="element()"/>

        <xsl:variable name="sorted-date-time-properties" as="element()*">
            <xsl:perform-sort select="($resource/dct:created, $resource/dct:modified)[exists(ldh:date-time(string(.)))]">
                <xsl:sort select="ldh:date-time(string(.))" order="ascending"/>
            </xsl:perform-sort>
        </xsl:variable>

        <xsl:sequence select="$sorted-date-time-properties[last()]"/>
    </xsl:function>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:Timestamp">
        <xsl:apply-templates select="ldh:latest-date-time(.)/text()"/>
    </xsl:template>
    
    <!-- TYPE LIST -->

    <xsl:template match="*[sioc:has_parent] | *[sioc:has_container]" mode="ac:ResourceTypes" priority="0.8"/>

    <!-- the design's type chips (.ldh-types): a type is the resource's identity, so it rides the titleline
         rather than the statement list, and each chip links to the class definition. Same href recipe as the
         breadcrumb crumb -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID][rdf:type/@rdf:resource]" mode="ac:ResourceTypes">
        <span class="ldh-types">
            <xsl:apply-templates select="rdf:type/@rdf:resource" mode="#current">
                <xsl:sort select="ac:object-label(.)" order="ascending" lang="{ac:langs()[1]}"/>
            </xsl:apply-templates>
        </span>
    </xsl:template>

    <!-- the design's type chip: the single emitter every chip surface applies templates into
         (the titleline wrapper above, the nested-block head) -->
    <xsl:template match="rdf:type/@rdf:resource" mode="ac:ResourceTypes">
        <a class="ldh-type-chip" href="{ldh:href(ac:document-uri(xs:anyURI(.)), map{}, ac:fragment-id(xs:anyURI(.)))}" title="{.}">
            <span>
                <xsl:value-of select="ac:object-label(.)"/>
            </span>
            <span class="msi sm" aria-hidden="true">north_east</span>
        </a>
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
            <xsl:apply-templates select="key('resources', @rdf:resource)" mode="ldh:BlockRow"/>
        </xsl:for-each>
    </xsl:template>

    <!-- SHAPE CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="ldh:ShapeConstructor" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" as="xs:anyURI" tunnel="yes"/>
        
        <!-- add-constructor/create-action are the behavior hooks the constructor onclick handlers match on -->
        <button title="{@rdf:about}" data-for-shape="{@rdf:about}" class="it add-constructor create-action">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <xsl:if test="$with-label">
                <xsl:value-of>
                    <xsl:apply-templates select="." mode="ac:label"/>
                </xsl:value-of>
            </xsl:if>
        </button>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->

    <xsl:template match="*[*][@rdf:about]" mode="ldh:ConstructorListItem">
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
    <xsl:template match="*[@rdf:nodeID][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="ldh:RowForm" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:RowForm">
        <xsl:param name="id" select="if (contains(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#')) then substring-after(@rdf:about, ac:absolute-path(ldh:base-uri(.)) || '#') else generate-id()" as="xs:string?"/>
        <xsl:param name="class" select="'block ldh-block'" as="xs:string?"/>
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="typeof" select="rdf:type/@rdf:resource/xs:anyURI(.)" as="xs:anyURI*"/>
        <xsl:param name="form-id" select="'form-' || generate-id()" as="xs:string?"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="base-uri" select="ldh:base-uri(.)" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="action" select="ldh:href(ac:absolute-path($base-uri))" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="enctype" select="if ($typeof = '&nfo;FileDataObject') then 'multipart/form-data' else ()" as="xs:string?"/>
        <xsl:param name="button-class" select="'ldhc-btn in-primary ap-solid sz-sm'" as="xs:string?"/>
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
                
                <form method="{$method}" action="{$action}" class="ldh-edit-form">
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

                    <xsl:apply-templates select="/rdf:RDF/*[http:sc/@rdf:resource = '&sc;Conflict']" mode="ldh:Exception"/>

                    <xsl:apply-templates select="." mode="ac:ResourceForm">
                        <xsl:with-param name="method" select="$method"/>
                        <xsl:with-param name="action" select="$action" tunnel="yes"/>
                        <xsl:with-param name="required" select="rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')" tunnel="yes"/>
                    </xsl:apply-templates>

                    <xsl:if test="$show-form-actions">
                        <xsl:apply-templates select="." mode="ldh:FormFooter">
                            <xsl:with-param name="button-class" select="$button-class"/>
                            <xsl:with-param name="dismiss" select="if ($show-cancel-button) then 'cancel' else ()"/>
                        </xsl:apply-templates>
                    </xsl:if>
                </form>
            </div>
        </div>
    </xsl:template>
    
    <!-- FORM -->
    
    <!-- hide object blank nodes that only have a single rdf:type property from constructed models, unless the type is owl:NamedIndividual -->
    <xsl:template match="*[@rdf:nodeID][key('predicates-by-object', @rdf:nodeID)][not(* except rdf:type or rdf:type/@rdf:resource = '&owl;NamedIndividual')]" mode="ac:ResourceForm" priority="2"/>

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:ResourceForm">
        <xsl:param name="required" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:apply-templates select="." mode="ac:FormControl">
            <xsl:with-param name="inline" select="false()" tunnel="yes"/>
            <xsl:with-param name="required" select="$required"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="ldh:Exception" priority="1">
        <div class="ldh-form-alert">
            <xsl:apply-templates select="." mode="ac:InlineAlert">
                <xsl:with-param name="text" as="item()*">
                    <xsl:apply-templates select="key('resources', '&ldh;ResourceExistsException', document(ac:document-uri('&ldh;')))" mode="ac:label"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </div>
    </xsl:template>
    
    <!-- FORM CONTROL -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:FormControl" name="ac:FormControl">
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
                    <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('ns', ldt:base()), map{ 'query': ldh:constructor-query($forClass), 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
                    <xsl:variable name="results" select="document(ldh:href($results-uri, map{}))" as="document-node()"/>
                    <xsl:sequence select="ldh:construct-instance(distinct-values($results//srx:binding[@name = 'text']/srx:literal), $forClass)"/>
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
            <xsl:attribute name="class" select="string-join(('ldh-fieldset', $class), ' ')"/>

            <!-- list of types that have constructors (excluding built-in system classes) -->
            <xsl:variable name="constructor-classes" select="if (exists($type-metadata) and exists($constructors)) then distinct-values($constructors//srx:binding[@name = 'Type']/srx:uri)[not(starts-with(., '&dh;') or starts-with(., '&ldh;') or starts-with(., '&def;') or starts-with(., '&lapp;') or starts-with(., '&sp;') or starts-with(., '&nfo;'))] else ()" as="xs:anyURI*"/>
            <!-- subject-row tools, revealed together with the subject row: copy-URI (keeps the btn-copy-uri class the clipboard handler matches on) and the constructor actions. One action renders as a direct labelled button, two or more collapse into the overflow menu -->
            <xsl:variable name="subject-tools" as="element()*">
                <xsl:apply-templates select="." mode="ldh:CopyUriButton">
                    <xsl:with-param name="class" select="'ldh-subject-copy btn-copy-uri'"/>
                </xsl:apply-templates>

                <xsl:choose>
                    <xsl:when test="count($constructor-classes) = 1">
                        <button type="button" class="ldh-form-action btn-edit-constructors" data-resource-type="{$constructor-classes}">
                            <!-- only admins should see the button as only they have access to the ontologies with constructors in them -->
                            <xsl:if test="not(acl:mode() = '&acl;Control')">
                                <xsl:attribute name="style" select="'display: none'"/>
                            </xsl:if>

                            <span class="msi outline sm" aria-hidden="true">tune</span>
                            <span>
                                <xsl:apply-templates select="key('resources', 'edit-constructors', ldh:translations())" mode="ac:label"/>
                            </span>
                        </button>
                    </xsl:when>
                    <xsl:when test="count($constructor-classes) gt 1">
                        <div class="ldh-form-actions-wrap">
                            <!-- only admins should see the menu as only they have access to the ontologies with constructors in them -->
                            <xsl:if test="not(acl:mode() = '&acl;Control')">
                                <xsl:attribute name="style" select="'display: none'"/>
                            </xsl:if>

                            <button type="button" class="ldh-form-action" aria-haspopup="menu" aria-expanded="false">
                                <span class="msi outline sm" aria-hidden="true">bolt</span>
                                <span>
                                    <xsl:apply-templates select="key('resources', 'actions', ldh:translations())" mode="ac:label"/>
                                </span>
                                <span class="msi sm caret" aria-hidden="true">expand_more</span>
                            </button>
                            <div class="ldh-form-actions-menu" role="menu">
                                <xsl:for-each select="$constructor-classes">
                                    <button type="button" role="menuitem" class="it btn-edit-constructors" data-resource-type="{.}">
                                        <span class="ico"><span class="msi outline sm" aria-hidden="true">tune</span></span>
                                        <span class="body">
                                            <span class="lbl">
                                                <!-- query class description from the namespace ontology (because it might not be available as Linked Data) -->
                                                <xsl:apply-templates select="key('resources', ., $type-metadata)" mode="ac:label"/>
                                            </span>
                                            <span class="sub">
                                                <xsl:apply-templates select="key('resources', 'edit-constructors', ldh:translations())" mode="ac:label"/>
                                            </span>
                                        </span>
                                    </button>
                                </xsl:for-each>
                            </div>
                        </div>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>

            <xsl:if test="$legend">
                <legend class="lg-eyebrow">
                    <xsl:value-of select="ac:label(.)"/>
                </legend>
            </xsl:if>

            <xsl:if test="$legend or not($required)">
                <div class="ldh-form-subjbar">
                    <xsl:if test="$legend">
                        <!-- button that toggles the .ldh-subject row for subject URI/bnode ID editing -->
                        <button type="button" class="ldhc-iconbtn sz-sm in-neutral ap-ghost btn-edit-subj" aria-pressed="{if ($show-subject) then 'true' else 'false'}">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'subject-uri-actions', ldh:translations())" mode="ac:label"/>
                            </xsl:attribute>

                            <span class="msi outline sm" aria-hidden="true">link</span>
                        </button>
                    </xsl:if>

                    <xsl:if test="not($required)">
                        <button type="button" class="ldhc-iconbtn sz-sm in-destructive ap-ghost btn-remove-resource">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'remove-resource', ldh:translations())" mode="ac:label"/>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">close</span>
                        </button>
                    </xsl:if>
                </div>
            </xsl:if>

            <!-- @rdf:about / @rdf:nodeID rendering is shell behavior, not per-flow customizable; dispatch in ac:FormControl mode explicitly so it works regardless of whether the shell was entered via the match template (mode=ac:FormControl) or the named template (e.g. from ldh:DocumentForm / ldh:AppSettingsForm wrapper modes) -->
            <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="ac:FormControl">
                <xsl:with-param name="type" select="if ($show-subject) then 'text' else 'hidden'"/>
                <xsl:with-param name="tools" select="$subject-tools"/>
            </xsl:apply-templates>

            <div class="ldh-prop-form is-form-mode">
                <xsl:apply-templates select="." mode="ldh:TypeControl">
                    <xsl:with-param name="type-metadata" select="$type-metadata" tunnel="yes"/>
                    <xsl:with-param name="hidden" select="$type-hidden"/>
                </xsl:apply-templates>

                <!-- no fieldset-level alert stack: violations surface at the affected rows - .error decoration for missing mandatory properties, inline .ldhc-help messages for every other kind (see the property template in imports/default.xsl) -->
                <xsl:sequence select="$body"/>
            </div>

            <xsl:if test="$show-property-control">
                <xsl:apply-templates select="." mode="ldh:PropertyControl">
                    <xsl:with-param name="template" select="$template"/>
                    <xsl:with-param name="forClass" select="$forClass"/>
                    <xsl:with-param name="required" select="true()"/>
                    <xsl:with-param name="property-metadata" select="$property-metadata"/>
                </xsl:apply-templates>
            </xsl:if>
        </fieldset>
    </xsl:template>

    <!-- Admin app override: allow subject editing for non-hierarchy resources by flipping the $show-subject default. -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][starts-with(replace(lapp:origin(), '^https?://', ''), 'admin.')]" mode="ac:FormControl" priority="1">
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

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:TypeControl">
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
    
    <xsl:template match="*[rdf:type/@rdf:resource = ('&ldh;XHTML', '&ldh;Object')]" mode="ldh:PropertyControl" priority="1"/>
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]" mode="ldh:PropertyControl">
        <xsl:param name="class" as="xs:string?"/>
        <!--<xsl:param name="label" select="true()" as="xs:boolean"/>-->
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:variable name="seq-properties" select="for $property in ../rdf:Description/*/concat(namespace-uri(), local-name())[starts-with(., '&rdf;' || '_')] return xs:anyURI($property)" as="xs:anyURI*"/>
        <xsl:variable name="max-seq-index" select="if (empty($seq-properties)) then 0 else max(for $seq-property in $seq-properties return xs:integer(substring-after($seq-property, '&rdf;' || '_')))" as="xs:integer"/>

        <div class="ldh-prop-addrow">
            <xsl:apply-templates select="." mode="ac:SelectShell">
                <xsl:with-param name="select" as="item()*">
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
                </xsl:with-param>
            </xsl:apply-templates>

            <button type="button" id="button-{generate-id()}" class="ldhc-btn in-primary ap-solid sz-sm add-value">
                <span class="msi outline sm" aria-hidden="true">add</span>
                <span>
                    <xsl:apply-templates select="key('resources', 'add', ldh:translations())" mode="ac:label"/>
                </span>
            </button>
        </div>
    </xsl:template>
    
    <!-- VIOLATION -->

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;URISyntaxViolation']" mode="ac:Violation">
        <xsl:param name="class" select="'ldhc-alert va-negative'" as="xs:string?"/>

        <xsl:apply-templates select="." mode="ac:InlineAlert">
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="text" select="string(rdfs:label)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&sh;ValidationResult']" mode="ac:Violation">
        <xsl:param name="class" select="'ldhc-alert va-negative'" as="xs:string?"/>

        <xsl:apply-templates select="." mode="ac:InlineAlert">
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="text" select="string(sh:resultMessage)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:Exception"/>

    <!-- OBJECT -->

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="ldh:Object"/>

    <!-- COMBOBOX CHIP -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:ComboboxChip">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'cb-chip-btn add-combobox'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="title" select="(@rdf:about, @rdf:nodeID)[1]" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <span class="ldhc-cb-committed">
            <xsl:if test="exists($forClass)">
                <xsl:attribute name="data-for-class" select="string-join($forClass, ' ')"/>
            </xsl:if>

            <span class="ldhc-cb-chip">
                <span class="msi outline sm" aria-hidden="true">link</span>
                <span class="cb-chip-lbl">
                    <xsl:if test="$title">
                        <xsl:attribute name="title" select="$title"/>
                    </xsl:if>

                    <xsl:value-of>
                        <xsl:apply-templates select="." mode="ac:label"/>
                    </xsl:value-of>
                </span>
                <!-- the edit button carries the committed term's RDF/POST input, so re-picking replaces both together -->
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

                    <span class="msi" aria-hidden="true">edit</span>

                    <xsl:if test="@rdf:about">
                        <input type="hidden" name="ou" value="{@rdf:about}"/>
                    </xsl:if>
                    <xsl:if test="@rdf:nodeID">
                        <input type="hidden" name="ob" value="{@rdf:nodeID}"/>
                    </xsl:if>
                </button>
            </span>
        </span>
    </xsl:template>

</xsl:stylesheet>
