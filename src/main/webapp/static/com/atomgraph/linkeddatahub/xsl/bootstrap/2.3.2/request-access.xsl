<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY java   "http://xml.apache.org/xalan/java/">
    <!ENTITY lacl   "http://linkeddatahub.com/ns/acl/domain#">
    <!ENTITY laclt   "http://linkeddatahub.com/ns/acl/templates#">
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY aplt   "http://atomgraph.com/ns/platform/templates#">
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY a      "http://atomgraph.com/ns/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xhv    "http://www.w3.org/1999/xhtml/vocab#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY sparql "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY cert   "http://www.w3.org/ns/auth/cert#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY c      "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY spl    "http://spinrdf.org/spl#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY list   "http://jena.hpl.hp.com/ARQ/list#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY google "http://atomgraph.com/ns/google#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:lacl="&lacl;"
xmlns:laclt="&laclt;"
xmlns:apl="&apl;"
xmlns:aplt="&aplt;"
xmlns:rdf="&rdf;"
xmlns:xhv="&xhv;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:sparql="&sparql;"
xmlns:http="&http;"
xmlns:cert="&cert;"
xmlns:sd="&sd;"
xmlns:ldt="&ldt;"
xmlns:core="&c;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:spin="&spin;"
xmlns:sp="&sp;"
xmlns:spl="&spl;"
xmlns:void="&void;"
xmlns:nfo="&nfo;"
xmlns:list="&list;"
xmlns:geo="&geo;"
xmlns:google="&google;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:param name="ac:access-to" as="xs:anyURI?"/>

    <!-- display stored AuthorizationRequest data after successful POST (without ConstraintViolations) -->
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST'][not(key('resources-by-type', '&http;Response'))]" mode="ac:ModeChoice" priority="2">
        <xsl:apply-templates select="." mode="bs2:Block"/>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:NavBarActions" priority="2"/>
    
    <!-- handle ConstraintViolations -->
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:Main" priority="2">
        <xsl:next-match>
            <xsl:with-param name="class" select="'offset2 span7'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- [not(key('resources-by-type', '&http;Response'))] -->
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST']" mode="bs2:Block" priority="2">
        <xsl:apply-templates select="." mode="apl:Content"/>

        <div class="alert alert-success">
            <p>Your access request has been created.</p>
            <p>You will be notified when the administrator approves or rejects it.</p>
        </div>
    </xsl:template>
       
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:Form" priority="3">
        <xsl:apply-templates select="." mode="apl:Content"/>
        
        <xsl:next-match>
            <!-- <xsl:with-param name="modal" select="false()"/> -->
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:TargetContainer" priority="2"/>
    
    <xsl:template match="rdf:RDF[$ldt:base][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:Right" priority="1"/>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="show-subject" select="false()" tunnel="yes"/>
            <xsl:with-param name="legend" select="false()"/>
        </xsl:next-match>
    </xsl:template>
                
    <xsl:template match="lacl:requestMode/@rdf:*[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <xsl:variable name="this" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="properties" select="../../*[concat(namespace-uri(), local-name()) = $this]" as="element()*"/>
        <xsl:variable name="modes" select="key('resources-by-subclass', '&acl;Access', $ac:sitemap)" as="element()*"/>
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
    
    <xsl:template match="lacl:requestAgent[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <input type="hidden" name="ou" value="{$lacl:Agent//*[foaf:isPrimaryTopicOf/@rdf:resource = document-uri($lacl:Agent)]/@rdf:about}"/>
    </xsl:template>
    
    <xsl:template match="lacl:requestAccessTo[$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:access-to]" mode="bs2:FormControl" priority="2">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <input type="hidden" name="ou" value="{$ac:access-to}"/>
    </xsl:template>
    
    <xsl:template match="lacl:requestAccessTo[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
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
    
    <!--
    <xsl:template match="lacl:requestAccessTo/@rdf:nodeID[$ac:uri = resolve-uri('request%20access', $ldt:base)][$ac:access-to]" mode="bs2:FormControl" priority="1">
        <input type="text" class="input-xxlarge" name="ou" value="{$ac:access-to}"/>
    </xsl:template>
    
    <xsl:template match="lacl:requestAccessTo/@rdf:*[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <input type="text" class="input-xxlarge" name="ou" value="{key('resources', key('resources', $ac:uri, $main-doc)/ldt:arg/@rdf:resource, $main-doc)[spl:predicate/@rdf:resource = '&lacl;requestAccessTo']/rdf:value/@rdf:resource}"/>
    </xsl:template>
    -->
    
    <xsl:template match="sioc:content[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1"/>

    <!-- hide slug - it will be created server side -->
    <xsl:template match="dh:slug[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1"/>
    
    <!-- turn off additional properties - it applies on the constructor document and not the $main-doc -->
    <xsl:template match="*[$ac:uri = resolve-uri('request%20access', $ldt:base)]" mode="bs2:PropertyControl" priority="1"/>

</xsl:stylesheet>