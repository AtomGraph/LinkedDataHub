<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY cert   "http://www.w3.org/ns/auth/cert#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY c      "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:lacl="&lacl;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:cert="&cert;"
xmlns:ldt="&ldt;"
xmlns:core="&c;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:template match="rdf:RDF[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="xhtml:Body" priority="2">
        <body>
            <xsl:apply-templates select="." mode="bs2:NavBar"/>

            <div id="content-body" class="container-fluid">
                <xsl:apply-templates select="key('resources', ac:uri())" mode="ldh:ContentList"/>

                <xsl:apply-templates select="." mode="bs2:Row"/>
            </div>

            <xsl:apply-templates select="." mode="bs2:Footer"/>
        </body>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:ModeTabs" priority="2"/>

    <xsl:template match="*[rdf:type/@rdf:resource = '&adm;SignUp'][$ac:method = 'GET']" mode="bs2:Row" priority="2">
        <xsl:apply-templates select="ldh:construct(map{ xs:anyURI('&foaf;Person'): spin:constructors(xs:anyURI('&foaf;Person'), resolve-uri('ns', $ldt:base), $constructor-query)//srx:binding[@name = 'construct']/srx:literal/string() })" mode="bs2:RowForm">
            <xsl:with-param name="action" select="ac:uri()"/>
            <xsl:with-param name="enctype" select="()"/> <!-- don't use 'multipart/form-data' which is the default -->
            <xsl:with-param name="create-resource" select="false()"/>
            <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
            <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="rdf:RDF[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'][$ac:method = 'POST'][key('resources-by-type', '&spin;ConstraintViolation')]" mode="bs2:Row" priority="3">
        <xsl:apply-templates select="." mode="bs2:RowForm">
            <xsl:with-param name="action" select="ac:uri()"/>
            <xsl:with-param name="enctype" select="()"/>
            <xsl:with-param name="create-resource" select="false()"/>
            <xsl:with-param name="constructor-query" select="$constructor-query" tunnel="yes"/>
            <xsl:with-param name="constraint-query" select="$constraint-query" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- match the first resource, whatever it is -->
    <xsl:template match="*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'][$ac:method = 'POST'][not(key('resources-by-type', '&http;Response'))][1]" mode="bs2:Row" priority="3">
        <div class="row-fluid">
            <div class="main offset2 span7">
                <div class="alert alert-success row-fluid">
                    <div class="span1">
                        <img src="{resolve-uri('static/com/atomgraph/linkeddatahub/icons/baseline_done_white_48dp.png', $ac:contextUri)}" alt="Signup complete"/>
                    </div>
                    <div class="span11">
                        <p>Congratulations! Your WebID profile has been created. You can see its data below.</p>
                        <p>
                            <strong>Authentication details have been sent to your email address.</strong>
                        </p>
                    </div>
                </div>
            </div>
        </div>
        
        <xsl:apply-templates select="key('resources-by-type', '&foaf;Person')[@rdf:about]" mode="#current"/>
        <xsl:apply-templates select="key('resources-by-type', '&cert;PublicKey')[@rdf:about]" mode="#current"/>
    </xsl:template>
    
    <!-- suppress resources other than foaf:Person and cert:PublicKey -->
    <xsl:template match="*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'][$ac:method = 'POST'][not(key('resources-by-type', '&http;Response'))][not(rdf:type/@rdf:resource = ('&foaf;Person', '&cert;PublicKey'))]" mode="bs2:Row" priority="2"/>

    <!-- disable the right nav (backlinks etc.) -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:Right"/>

    <!-- hide object blank nodes (that only have a single rdf:type property) from constructed models -->
    <xsl:template match="rdf:Description[$ac:method = 'GET'][@rdf:nodeID][not(rdf:type/@rdf:resource = ('&foaf;Person', '&adm;SignUp'))][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:RowForm" priority="3"/>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="show-subject" select="false()" tunnel="yes"/>
            <xsl:with-param name="legend" select="false()"/>
            <xsl:with-param name="required" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[@rdf:about or @rdf:nodeID][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']/sioc:has_parent | *[@rdf:about or @rdf:nodeID][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']/sioc:has_container" mode="bs2:FormControl">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="resolve-uri('acl/agents/', $ldt:base)"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="foaf:based_near/@rdf:*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <select name="ou">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$disabled">
                <xsl:attribute name="disabled" select="'disabled'"/>
            </xsl:if>
            
            <xsl:variable name="selected" select="." as="xs:anyURI"/>
            <xsl:for-each select="document('countries.rdf')/rdf:RDF/*[@rdf:about]">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about = $selected"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>
        
        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
        
    <!-- change foaf:mbox object type from resource to literal -->
    <!-- TO-DO: apply this from Client's foaf.xsl instead - likely needs import restructuring -->
    <xsl:template match="foaf:mbox/@rdf:*" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="'text'"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="value" select="substring-after(., 'mailto:')"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="foaf:mbox/@rdf:*" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <span class="help-inline">Literal</span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="foaf:member/@rdf:*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <input type="hidden" name="ob" value="org"/>
        
        <!-- replace URI resource lookup with blank node -->
        <fieldset>
            <input type="hidden" name="sb" value="org"/>
            
            <div class="control-group">
                <input type="hidden" name="pu" value="&foaf;name"/>

                <label class="control-label" for="{$id}">
                    <xsl:value-of>
                        <xsl:apply-templates select="key('resources', '&foaf;name', document(ac:document-uri('&foaf;')))" mode="ac:label"/>
                    </xsl:value-of>
                </label>
                <div class="controls">
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="class" select="$class"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>

                    <xsl:if test="$type-label">
                        <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                            <xsl:with-param name="type" select="$type"/>
                        </xsl:apply-templates>
                    </xsl:if>
                </div>
            </div>
        </fieldset>
        
        <!-- restore subject context -->
        <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="foaf:member/@rdf:*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <span class="help-inline">Literal</span>
        </xsl:if>
    </xsl:template>
    
    <!-- make properties required -->
    <xsl:template match="foaf:givenName[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | foaf:familyName[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | foaf:mbox[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | cert:key[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1">
        <xsl:param name="violations" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="required" select="true()"/>
            <xsl:with-param name="violations" select="$violations"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="cert:key/@rdf:*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'password'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <input type="hidden" name="ob" value="key"/>
        
        <!-- replace URI resource lookup with blank node -->
        <fieldset>
            <input type="hidden" name="sb" value="key"/>

            <xsl:variable name="violations" select="key('violations-by-value', .) | key('violations-by-root', .)" as="element()*"/>
            <xsl:apply-templates select="$violations" mode="bs2:Violation"/>
        
            <xsl:call-template name="lacl:password">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="class" select="$class"/>
                <xsl:with-param name="disabled" select="$disabled"/>
                <xsl:with-param name="for" select="concat($id, '-pwd1')"/>
                <xsl:with-param name="violations" select="$violations"/>
            </xsl:call-template>
            <!-- double the password input -->
            <xsl:call-template name="lacl:password">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="class" select="$class"/>
                <xsl:with-param name="disabled" select="$disabled"/>
                <xsl:with-param name="for" select="concat($id, '-pwd2')"/>
                <xsl:with-param name="violations" select="$violations"/>
            </xsl:call-template>
        </fieldset>

        <!-- restore subject context -->
        <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- do not show secretary URI input -->
    <xsl:template match="acl:delegates[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1"/>

    <!-- do not show the email hash value -->
    <xsl:template match="foaf:mbox_sha1sum[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="1"/>

    <xsl:template name="lacl:password">
        <xsl:param name="this" select="xs:anyURI('&lacl;password')" as="xs:anyURI"/>
        <xsl:param name="type" select="'password'" as="xs:string"/>
        <!-- <xsl:param name="id" as="xs:string?"/> -->
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="for" select="generate-id()" as="xs:string"/>
        <xsl:param name="required" select="true()" as="xs:boolean"/>
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="error" select="@rdf:resource = $violations/ldh:violationValue or $violations/spin:violationPath/@rdf:resource = $this" as="xs:boolean"/>
        <xsl:param name="class" select="concat('control-group', if ($error) then ' error' else (), if ($required) then ' required' else ())" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <input type="hidden" name="pu" value="&lacl;password"/>

            <label class="control-label" for="{$for}">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&lacl;password', document(ac:document-uri('&lacl;')))" mode="ac:label"/>
                </xsl:value-of>
            </label>
            <div class="controls">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$for"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:call-template>

                <xsl:if test="$type-label">
                    <span class="help-inline">Literal</span>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
    <!-- hide type control -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:TypeControl" priority="2">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!--  hide properties -->
    <xsl:template match="dh:slug[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | foaf:primaryTopic[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | foaf:isPrimaryTopicOf[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | cert:modulus[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp'] | cert:exponent[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:FormControl" priority="3">
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

    <xsl:template match="*[@rdf:about = '&foaf;mbox'][doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="ac:label" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="key('resources', 'email', document('translations.rdf'))" mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>

    <!-- turn off additional properties -->
    <xsl:template match="*[doc-available(ac:uri())][key('resources', ac:uri(), document(ac:uri()))/rdf:type/@rdf:resource = '&adm;SignUp']" mode="bs2:PropertyControl" priority="1"/>

</xsl:stylesheet>