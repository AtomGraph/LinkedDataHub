<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:lacl="&lacl;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:param name="apl:access-to" as="xs:anyURI?"/>

    <!-- display stored AuthorizationRequest data after successful POST (without ConstraintViolations) -->
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST'][not(key('resources-by-type', '&http;Response'))]" mode="ac:ModeChoice" priority="2">
        <xsl:apply-templates select="." mode="bs2:Block"/>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:NavBarActions" priority="2"/>
    
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:Left" priority="2"/>

    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:Right" priority="1"/>

    <!-- handle ConstraintViolations -->
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:Main" priority="2">
        <xsl:next-match>
            <xsl:with-param name="class" select="'offset2 span7'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- [not(key('resources-by-type', '&http;Response'))] -->
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST']" mode="bs2:Block" priority="2">
        <div class="alert alert-success row-fluid">
            <div class="span1">
                <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/baseline_done_white_48dp.png', $ac:contextUri)}" alt="Request created"/>
            </div>
            <div class="span11">
                <p>Your access request has been created.</p>
                <p>You will be notified when the administrator approves or rejects it.</p>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:TargetContainer" priority="2"/>
    
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="show-subject" select="false()" tunnel="yes"/>
            <xsl:with-param name="legend" select="false()"/>
        </xsl:next-match>
    </xsl:template>
                
    <xsl:template match="*[@rdf:about or @rdf:nodeID][$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:forClass]/sioc:has_parent | *[@rdf:about or @rdf:nodeID][$ldt:base][$ac:forClass][$ac:uri = resolve-uri('request%20access', $ldt:base)]/sioc:has_container" mode="bs2:FormControl" priority="4">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="resolve-uri('acl/authorization-requests/', $ldt:base)"/>
        </xsl:call-template>
        <!-- generate AuthorizationRequestItem title -->
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'pu'"/>
            <xsl:with-param name="value" select="'&dct;title'"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="value" select="'Access request by ' || ac:label($acl:Agent//*[foaf:isPrimaryTopicOf/@rdf:resource = document-uri($acl:Agent)])"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="lacl:requestMode/@rdf:*[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <xsl:variable name="this" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="properties" select="../../*[concat(namespace-uri(), local-name()) = $this]" as="element()*"/>
        <xsl:variable name="modes" select="key('resources-by-subclass', '&acl;Access', document(ac:document-uri('&acl;')))" as="element()*"/>
        <xsl:variable name="default" select="xs:anyURI('&acl;Read')" as="xs:anyURI*"/>
        <select name="ou" id="{generate-id()}" multiple="multiple" size="{count($modes)}">
            <xsl:for-each select="$modes">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="if ($ac:method = 'POST') then @rdf:about = $properties/@rdf:resource else @rdf:about = $default"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>
        
        <xsl:if test="$type-label">
            <span class="help-inline">Resource</span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="lacl:requestAgent[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="value" select="$acl:Agent//*[foaf:isPrimaryTopicOf/@rdf:resource = document-uri($acl:Agent)]/@rdf:about"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
        
        <!-- generate AuthorizationRequest label-->
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'pu'"/>
            <xsl:with-param name="value" select="'&rdfs;label'"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="value" select="'Access request by ' || ac:label($acl:Agent//*[foaf:isPrimaryTopicOf/@rdf:resource = document-uri($acl:Agent)])"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="lacl:requestAccessTo/@rdf:*[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)][$apl:access-to]" mode="bs2:FormControl" priority="2">
        <label>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="value" select="resolve-uri('../sparql', $ldt:base)"/> <!-- end-user endpoint -->
                <xsl:with-param name="type" select="'checkbox'"/>
                <xsl:with-param name="checked" select="true()"/>
            </xsl:call-template>
            
            SPARQL endpoint
        </label>
    </xsl:template>

    <xsl:template match="lacl:requestAccessToClass/@rdf:*[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="2">
        <xsl:variable name="this" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="classes" select="key('resources', (resolve-uri('../ns/domain/default#Root', $ldt:base), resolve-uri('../ns/domain/default#Container', $ldt:base), resolve-uri('../ns/domain/default#Item', $ldt:base), resolve-uri('../ns/domain/default#File', $ldt:base)), document(resolve-uri('../ns/domain/default', $ldt:base)))" as="element()*"/>
        <select name="ou" id="{generate-id()}" multiple="multiple" size="{count($classes)}">
            <xsl:for-each select="$classes">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="true()"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>
    </xsl:template>

    <!-- hide type control -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:TypeControl" priority="2">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- hide properties (including all of document resource properties) -->
    <xsl:template match="foaf:isPrimaryTopicOf[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)] | *[foaf:primaryTopic][$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]/*" mode="bs2:FormControl" priority="3">
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
    
    <xsl:template match="sioc:content[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1"/>
    
    <!-- turn off additional properties - it applies on the constructor document and not the $main-doc -->
    <xsl:template match="*[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:PropertyControl" priority="1"/>

</xsl:stylesheet>