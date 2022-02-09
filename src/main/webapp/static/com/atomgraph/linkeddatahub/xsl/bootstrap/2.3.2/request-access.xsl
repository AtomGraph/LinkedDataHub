<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:lacl="&lacl;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:param name="ldh:access-to" as="xs:anyURI?"/>

    <xsl:template match="rdf:RDF[ac:uri() = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST'][key('resources-by-type', '&spin;ConstraintViolation')]" mode="xhtml:Body" priority="3">
        <xsl:apply-templates select="." mode="bs2:RowForm">
            <xsl:with-param name="action" select="ac:uri()"/>
            <xsl:with-param name="enctype" select="()"/> <!-- don't use 'multipart/form-data' which is the default -->
            <xsl:with-param name="create-resource" select="false()"/>
            <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
            <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[ac:uri() = resolve-uri('request%20access', $ldt:base)][$ac:method = 'GET']" mode="xhtml:Body" priority="2">
        <body>
            <xsl:apply-templates select="." mode="bs2:NavBar"/>

            <div id="content-body" class="container-fluid">
                <xsl:for-each select="key('resources', ac:uri())">
                    <xsl:apply-templates select="key('resources', ldh:content/@rdf:*)" mode="ldh:ContentList"/>
                </xsl:for-each>

                <xsl:apply-templates select="." mode="bs2:RowBlock"/>
            </div>

            <xsl:apply-templates select="." mode="bs2:Footer"/>
        </body>
    </xsl:template>

    <!-- currently doesn't work because the client-side does not refresh the bs2:NavBarActions -->
    <!--<xsl:template match="rdf:RDF[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:NavBarActions" priority="2"/>-->

    <xsl:template match="rdf:RDF[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:ModeTabs" priority="2"/>

    <xsl:template match="*[@rdf:about = resolve-uri('request%20access', $ldt:base)][$ac:method = 'GET']" mode="bs2:RowBlock" priority="2">
        <xsl:variable name="constructor" as="document-node()">
            <xsl:document>
                <!-- construct a combined graph of dh:Item and lacl:AuthorizationRequest instances -->
                <xsl:for-each select="ldh:construct(map{ xs:anyURI('&dh;Item'): spin:constructors(xs:anyURI('&dh;Item'), resolve-uri('ns', $ldt:base), $constructor-query)//srx:binding[@name = 'construct']/srx:literal/string(.),
                        xs:anyURI('&lacl;AuthorizationRequest'): spin:constructors(xs:anyURI('&lacl;AuthorizationRequest'), resolve-uri('ns', $ldt:base), $constructor-query)//srx:binding[@name = 'construct']/srx:literal/string(.) })">
                    <xsl:apply-templates select="." mode="ldh:SetPrimaryTopic">
                        <xsl:with-param name="topic-id" select="key('resources-by-type', '&lacl;AuthorizationRequest')/@rdf:nodeID" tunnel="yes"/>
                        <xsl:with-param name="doc-id" select="key('resources-by-type', '&dh;Item')/@rdf:nodeID" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:document>
        </xsl:variable>
        
        <xsl:apply-templates select="$constructor" mode="bs2:RowForm">
            <xsl:with-param name="action" select="ac:uri()"/>
            <xsl:with-param name="enctype" select="()"/> <!-- don't use 'multipart/form-data' which is the default -->
            <xsl:with-param name="create-resource" select="false()"/>
            <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
            <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- display stored AuthorizationRequest data after successful POST (without ConstraintViolations) -->
    <!-- match the first resource, whatever it is -->
    <xsl:template match="*[ac:uri() = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST'][not(key('resources-by-type', '&http;Response'))][1]" mode="bs2:RowBlock" priority="3">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'offset2 span7'" as="xs:string?"/>

        <div class="row-fluid">
            <div class="offset2 span7">
                <div class="alert alert-success row-fluid ">
                    <div class="span1">
                        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/baseline_done_white_48dp.png', $ac:contextUri)}" alt="Request created"/>
                    </div>
                    <div class="span11">
                        <p>Your access request has been created.</p>
                        <p>You will be notified when the administrator approves or rejects it.</p>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- suppress other resources -->
    <xsl:template match="*[ac:uri() = resolve-uri('request%20access', $ldt:base)][$ac:method = 'POST'][not(key('resources-by-type', '&http;Response'))]" mode="bs2:RowBlock" priority="2"/>

    <!-- hide object blank nodes (that only have a single rdf:type property) from constructed models -->
    <xsl:template match="rdf:Description[$ac:method = 'GET'][@rdf:nodeID][not(rdf:type/@rdf:resource = ('&lacl;AuthorizationRequest', '&dh;Item'))][ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:RowForm" priority="3"/>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="show-subject" select="false()" tunnel="yes"/>
            <xsl:with-param name="legend" select="false()"/>
            <xsl:with-param name="required" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- make properties required -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:uri() = resolve-uri('request%20access', $ldt:base)]/*" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="required" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID][ac:uri() = resolve-uri('request%20access', $ldt:base)]/sioc:has_parent | *[@rdf:about or @rdf:nodeID][ac:uri() = resolve-uri('request%20access', $ldt:base)]/sioc:has_container" mode="bs2:FormControl" priority="4">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="resolve-uri('acl/authorization-requests/', $ldt:base)"/>
        </xsl:call-template>
        <!-- generate Item title -->
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'pu'"/>
            <xsl:with-param name="value" select="'&dct;title'"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="value" select="'Access request by ' || ac:label(key('resources-by-type', '&foaf;Agent', $foaf:Agent))"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="lacl:requestMode/@rdf:*[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="2">
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
        
        <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
            <xsl:with-param name="type-label" select="$type-label"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="lacl:requestAgent[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="2">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="value" select="key('resources-by-type', '&foaf;Agent', $foaf:Agent)/@rdf:about"/>
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
            <xsl:with-param name="value" select="'Access request by ' || ac:label(key('resources-by-type', '&foaf;Agent', $foaf:Agent))"/>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="lacl:requestAccessTo/@rdf:*[ac:uri() = resolve-uri('request%20access', $ldt:base)][$ldh:access-to]" mode="bs2:FormControl" priority="2">
        <select name="ou" id="{generate-id()}" multiple="multiple" size="3">
            <option value="{resolve-uri('../add', $ldt:base)}" selected="selected">Add RDF endpoint</option>
            <option value="{resolve-uri('../service', $ldt:base)}" selected="selected">Graph Store endpoint</option>
            <option value="{resolve-uri('../sparql', $ldt:base)}" selected="selected">SPARQL endpoint</option>
        </select>
    </xsl:template>

    <!-- show first property as a select -->
    <xsl:template match="lacl:requestAccessToClass[1]/@rdf:*[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="2">
        <xsl:variable name="this" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="classes" select="key('resources', ('&def;Root', '&dh;Container','&dh;Item', '&nfo;FileDataObject'), document(ac:document-uri('&def;')))" as="element()*"/>
        <select name="ou" id="{generate-id()}" multiple="multiple" size="{count($classes)}">
            <xsl:for-each select="$classes">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="true()"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>
    </xsl:template>

    <!-- hide following properties -->
    <xsl:template match="lacl:requestAccessToClass/@rdf:*[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="1"/>
    
    <!-- hide type control -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:TypeControl" priority="2">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- suppress properties -->
    <xsl:template match="dct:title[ac:uri() = resolve-uri('request%20access', $ldt:base)] | dct:description[ac:uri() = resolve-uri('request%20access', $ldt:base)] | ldh:content[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:FormControl" priority="4"/>

    <!-- hide properties (including all of document resource properties) -->
    <xsl:template match="rdfs:label[ac:uri() = resolve-uri('request%20access', $ldt:base)] | foaf:isPrimaryTopicOf[ac:uri() = resolve-uri('request%20access', $ldt:base)] | *[foaf:primaryTopic][ac:uri() = resolve-uri('request%20access', $ldt:base)]/*" mode="bs2:FormControl" priority="3">
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

    <!-- turn off additional properties - it applies on the constructor document and not the $main-doc -->
    <xsl:template match="*[ac:uri() = resolve-uri('request%20access', $ldt:base)]" mode="bs2:PropertyControl" priority="1"/>

</xsl:stylesheet>