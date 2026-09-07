<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY cert   "http://www.w3.org/ns/auth/cert#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY c      "https://www.w3.org/ns/ldt/core/domain#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:lacl="&lacl;"
xmlns:ldh="&ldh;"
xmlns:lapp="&lapp;"
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
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all">

    <!-- intercept signup form submit to route the success callback through ldh:signup-form-response -->
    <xsl:template match="form[@id = 'form-signup']" mode="ixsl:onsubmit" priority="3" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:next-match>
            <xsl:with-param name="callback" select="ldh:signup-form-response#1"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:function name="ldh:signup-form-response" ixsl:updating="yes" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>

        <xsl:choose>
            <xsl:when test="$status = 201 and map:contains($response?headers, 'location')">
                <xsl:for-each select="$response">
                    <xsl:call-template name="ldh:SignUpComplete"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:row-form-response($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ldh:ContentBody" priority="2">
        <div class="content-body">
            <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="ldh:ContentList"/>

            <xsl:apply-templates select="." mode="ldh:BlockRow"/>
        </div>
    </xsl:template>

    <!-- hide "Create" button which otherwise would be shown because acl:Append is allowed for signup -->
    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:Create" priority="2"/>

    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:ModeList" priority="2"/>

    <!-- disable the block links popover (backlinks) -->
    <xsl:template match="*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ldh:BlockLinksPopover"/>

    <!-- Renders the signup form synchronously on both products: ldh:parse-query behind ldh:construct-instance is dual-declared (SPARQL.js in the browser, the ParseQuery Jena extension server-side), so the same template serves the server-rendered page and client-side re-renders -->
    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ldh:BlockRow" priority="2">
        <xsl:variable name="forClass" select="xs:anyURI('&foaf;Person')" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('ns', ldt:base()), map{ 'query': ldh:constructor-query($forClass), 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
        <xsl:variable name="results" select="document(ldh:href($results-uri, map{}))" as="document-node()"/>
        <xsl:variable name="constructed-doc" select="ldh:construct-instance(distinct-values($results//srx:binding[@name = 'text']/srx:literal), $forClass)" as="document-node()"/>

        <!-- select element children of rdf:RDF only — the constructed document is not strip-space'd, so unguarded apply-templates would copy whitespace text nodes -->
        <xsl:apply-templates select="$constructed-doc/rdf:RDF/*" mode="ldh:RowForm">
            <xsl:with-param name="form-id" select="'form-signup'"/>
            <xsl:with-param name="method" select="'post'"/> <!-- don't use PATCH which is the default -->
            <xsl:with-param name="action" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/>
            <xsl:with-param name="enctype" select="()"/> <!-- don't use 'multipart/form-data' which is the default -->
            <xsl:with-param name="create-resource" select="false()"/>
            <xsl:with-param name="base-uri" select="ac:absolute-path(ldh:base-uri(.))" tunnel="yes"/> <!-- base-uri() is empty on constructed documents -->
        </xsl:apply-templates>
    </xsl:template>

    <!-- hide resources from constructed models -->
    <xsl:template match="rdf:Description[not(rdf:type/@rdf:resource = ('&foaf;Person', '&adm;SignUp'))][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ldh:RowForm" priority="3"/>

    <!-- hide type control -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ldh:TypeControl" priority="2">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="show-subject" select="false()" tunnel="yes"/>
            <xsl:with-param name="legend" select="false()"/>
            <xsl:with-param name="required" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="foaf:based_near/@rdf:*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="1">
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
            
            <!-- empty placeholder, so an untouched form does not submit the first country; ldh:parse-rdf-post drops the empty-valued statement -->
            <option value=""></option>

            <xsl:variable name="selected" select="." as="xs:anyURI"/>
            <xsl:for-each select="document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/admin/countries.rdf', $lapp:origin))/rdf:RDF/*[@rdf:about]">
                <xsl:sort select="ac:label(.)" lang="{ac:langs()[1]}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about = $selected"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>
        
        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations"/>
        </xsl:if>
    </xsl:template>
        
    <!-- change foaf:mbox object type from resource to literal -->
    <!-- TO-DO: apply this from Client's foaf.xsl instead - likely needs import restructuring -->
    <xsl:template match="foaf:mbox/@rdf:*" mode="ac:FormControl">
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
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="foaf:mbox/@rdf:*" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <div class="ldh-annot">
                <span class="ldhc-tag sz-sm em-quiet an-term is-literal">
                    <xsl:apply-templates select="key('resources', 'literal', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </span>
            </div>
        </xsl:if>
    </xsl:template>
    
    <!-- make properties required -->
    <xsl:template match="foaf:givenName[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | foaf:familyName[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | foaf:mbox[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | cert:key[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="1">
        <xsl:param name="violations" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="required" select="true()"/>
            <xsl:with-param name="violations" select="$violations"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="cert:key/@rdf:*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="1">
        <xsl:param name="type" select="'password'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <input type="hidden" name="ob" value="key"/>
        
        <!-- replace URI resource lookup with blank node -->
        <fieldset>
            <input type="hidden" name="sb" value="key"/>
            <input type="hidden" name="pu" value="&rdf;type"/>
            <input type="hidden" name="ou" value="&cert;X509Certificate"/>
            
            <xsl:variable name="violations" select="key('violations-by-value', .) | key('violations-by-root', .)" as="element()*"/>

            <div class="ldh-prop-form is-form-mode">
                <xsl:call-template name="lacl:password">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="for" select="concat($id, '-pwd1')"/>
                    <xsl:with-param name="violations" select="$violations"/>
                </xsl:call-template>
                <!-- double the password input -->
                <xsl:call-template name="lacl:password">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="for" select="concat($id, '-pwd2')"/>
                    <xsl:with-param name="violations" select="$violations"/>
                </xsl:call-template>
            </div>
        </fieldset>

        <!-- restore subject context -->
        <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- do not show secretary URI input -->
    <xsl:template match="acl:delegates[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="1"/>

    <!-- do not show the email hash value -->
    <xsl:template match="foaf:mbox_sha1sum[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="1"/>

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
        <xsl:param name="row-violations" select="$violations[spin:violationPath/@rdf:resource = $this][rdfs:label]" as="element()*"/>
        <xsl:param name="class" select="concat('ldh-prop-group', if ($error) then ' is-violation' else (), if ($required) then ' required' else ())" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <input type="hidden" name="pu" value="&lacl;password"/>

            <div class="label">
                <span class="lbl-row">
                    <span class="pred" title="{$this}">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', '&lacl;password', document(ac:document-uri('&lacl;')))" mode="ac:label"/>
                        </xsl:value-of>
                    </span>

                    <xsl:if test="$required">
                        <span class="ldhc-label-aux req">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'required', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:attribute>
                            <xsl:text>*</xsl:text>
                            <span class="ldhc-vh">
                                <xsl:apply-templates select="key('resources', 'required', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </span>
                        </span>
                    </xsl:if>
                </span>
            </div>

            <div class="ldh-prop-row is-interactive is-last{if ($error) then ' is-violation' else ()}">
                <div class="value val-stack">
                    <div class="val-main">
                        <xsl:call-template name="xhtml:Input">
                            <xsl:with-param name="name" select="'ol'"/>
                            <xsl:with-param name="type" select="$type"/>
                            <xsl:with-param name="id" select="$for"/>
                            <xsl:with-param name="disabled" select="$disabled"/>
                        </xsl:call-template>

                        <xsl:if test="$type-label">
                            <div class="ldh-annot">
                                <span class="ldhc-tag sz-sm em-quiet an-term is-literal">
                                    <xsl:apply-templates select="key('resources', 'literal', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </span>
                            </div>
                        </xsl:if>
                    </div>

                    <!-- the password violations are authored server-side (mismatch, length, character set) - inline their messages like the shared property template does -->
                    <xsl:if test="exists($row-violations)">
                        <div class="ldh-vmsgs">
                            <xsl:for-each select="$row-violations">
                                <span class="ldhc-help va-negative sz-sm" role="alert">
                                    <span class="msi outline sm" aria-hidden="true">error</span>
                                    <span>
                                        <xsl:value-of>
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </xsl:value-of>
                                    </span>
                                </span>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                </div>

                <div class="row-actions"></div>
            </div>
        </div>
    </xsl:template>
    
    <!--  hide properties -->
    <xsl:template match="dh:slug[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | foaf:primaryTopic[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | foaf:isPrimaryTopicOf[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | cert:modulus[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())] | cert:exponent[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:FormControl" priority="3">
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

    <xsl:template match="*[@rdf:about = '&foaf;mbox'][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ac:label" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="key('resources', 'email', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/translations.rdf', $lapp:origin)))" mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>

    <!-- turn off additional properties -->
    <xsl:template match="*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), ldt:base())]" mode="ldh:PropertyControl" priority="1"/>

</xsl:stylesheet>