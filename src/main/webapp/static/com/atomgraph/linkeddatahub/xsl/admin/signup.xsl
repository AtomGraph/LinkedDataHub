<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY cert   "http://www.w3.org/ns/auth/cert#">
    <!ENTITY dh     "https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY vivo   "http://vivoweb.org/ontology/core#">
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
xmlns:lds="&lds;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:cert="&cert;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:vivo="&vivo;"
xmlns:spin="&spin;"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
exclude-result-prefixes="#all">

    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ldh:ContentBody" priority="2">
        <div class="content-body">
            <xsl:apply-templates select="key('resources', ac:absolute-path(ldh:base-uri(.)))" mode="ldh:ContentList"/>

            <xsl:apply-templates select="." mode="ldh:BlockRow"/>
        </div>
    </xsl:template>

    <!-- hide "Create" button which otherwise would be shown because acl:Append is allowed for signup -->
    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:Create" priority="2"/>

    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:ModeSwitcher" priority="2"/>

    <!-- disable the block links popover (backlinks) -->
    <xsl:template match="*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ldh:BlockLinksPopover"/>

    <!-- Renders the signup form synchronously on both products: ldh:parse-query behind ldh:construct-instance is dual-declared (SPARQL.js in the browser, the ParseQuery Jena extension server-side), so the same template serves the server-rendered page and client-side re-renders -->
    <xsl:template match="rdf:RDF[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ldh:BlockRow" priority="2">
        <xsl:variable name="forClass" select="xs:anyURI('&foaf;Person')" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': ldh:constructor-query($forClass), 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
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
    <xsl:template match="rdf:Description[not(rdf:type/@rdf:resource = ('&foaf;Person', '&adm;SignUp'))][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ldh:RowForm" priority="3"/>

    <!-- hide type control -->
    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ldh:TypeControl" priority="2">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="show-subject" select="false()" tunnel="yes"/>
            <xsl:with-param name="legend" select="false()"/>
            <xsl:with-param name="required" select="true()"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="foaf:based_near/@rdf:*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="1">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <xsl:apply-templates select="." mode="ac:SelectShell">
            <xsl:with-param name="select" as="item()*">
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
                    <xsl:for-each select="document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/admin/countries.rdf', $lds:origin))/rdf:RDF/*[@rdf:about]">
                        <xsl:sort select="ac:label(.)" lang="{ac:langs()[1]}"/>
                        <xsl:apply-templates select="." mode="xhtml:Option">
                            <xsl:with-param name="selected" select="@rdf:about = $selected"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </select>
            </xsl:with-param>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations"/>
        </xsl:if>
    </xsl:template>
        
    <!-- The e-mail address is typed, not looked up. The constructor declares foaf:mbox [ a rdfs:Resource ],
         which the generic control renders as a resource combobox, and its lookup queries the SPARQL
         endpoint - which an agent who is signing up has no access to, so every keystroke answered with
         "The values could not be loaded". Posted as a literal, the way sioc:email is: ValidatingModelProvider
         turns a foaf:mbox literal into the mailto: URI the protocol wants. -->
    <xsl:template match="foaf:mbox/@rdf:*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="2">
        <xsl:param name="type" select="'email'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:apply-templates select="." mode="ac:FieldShell">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="control" as="item()*">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <!-- empty on the constructor's blank node; the address on a constraint-violation
                         re-render, where the submitted literal comes back as the converted mailto: URI -->
                    <xsl:with-param name="value" select="if (starts-with(., 'mailto:')) then substring-after(., 'mailto:') else ()"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- and the term the row posts is now a literal, not the blank node the constructor declared -->
    <xsl:template match="foaf:mbox/@rdf:*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:ValueAnnotations" priority="2">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet an-term is-literal'"/>
                <xsl:with-param name="label" as="item()*">
                    <xsl:apply-templates select="key('resources', 'literal', ldh:translations())" mode="ac:label"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- An ORCID iD is a URI the agent pastes, so this one stays a URI field (name="ou") and only loses
         the lookup - the same inaccessible SPARQL endpoint the e-mail's combobox queried. -->
    <xsl:template match="vivo:orcidId/@rdf:*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="2">
        <xsl:param name="type" select="'url'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:apply-templates select="." mode="ac:FieldShell">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="control" as="item()*">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <!-- empty on the constructor's blank node, the submitted URI on a violation re-render -->
                    <xsl:with-param name="value" select="if (local-name() = 'resource') then string(.) else ()"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- and the term it posts is a URI resource, not the blank node the constructor declared -->
    <xsl:template match="vivo:orcidId/@rdf:nodeID[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:ValueAnnotations" priority="2">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet an-term is-resource'"/>
                <xsl:with-param name="label" as="item()*">
                    <xsl:apply-templates select="key('resources', 'resource', ldh:translations())" mode="ac:label"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- make properties required -->
    <xsl:template match="foaf:givenName[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())] | foaf:familyName[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())] | foaf:mbox[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="1">
        <xsl:param name="violations" as="element()*"/>

        <xsl:next-match>
            <xsl:with-param name="required" select="true()"/>
            <xsl:with-param name="violations" select="$violations"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- The key is a blank-node certificate whose password is typed twice, and both inputs are rows of
         the form itself. Overriding the object (cert:key/@rdf:*) instead put them inside the Key row's
         value cell, which is a single flex line holding one capped control and one annotation strip:
         .ldh-prop-group is the grid the form lays out its predicates on, so a group nested there opened
         a second 200px label column inside the first one and pushed both inputs off the control column.
         RDF/POST is sequential, so the hidden statement inputs here and the pu/ol pairs inside the
         groups below have to stay in this document order. -->
    <xsl:template match="cert:key[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="2">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="type" select="'password'" as="xs:string"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="violations" as="element()*"/>
        <!-- the fieldset's violations are rooted at the person; the certificate's own are rooted at the key -->
        <xsl:variable name="key-violations" select="$violations | key('violations-by-value', (@rdf:resource, @rdf:nodeID)) | key('violations-by-root', (@rdf:resource, @rdf:nodeID))" as="element()*"/>

        <!-- <person> cert:key _:key -->
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <input type="hidden" name="ob" value="key"/>

        <!-- _:key a cert:X509Certificate -->
        <input type="hidden" name="sb" value="key"/>
        <input type="hidden" name="pu" value="&rdf;type"/>
        <input type="hidden" name="ou" value="&cert;X509Certificate"/>

        <xsl:call-template name="lacl:password">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="for" select="concat($id, '-pwd1')"/>
            <xsl:with-param name="violations" select="$key-violations"/>
        </xsl:call-template>
        <!-- double the password input. Its own label, because two rows both reading "Password" read as
             one row rendered twice -->
        <xsl:call-template name="lacl:password">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="for" select="concat($id, '-pwd2')"/>
            <xsl:with-param name="label" as="item()*">
                <xsl:apply-templates select="key('resources', 'repeat-password', ldh:translations())" mode="ac:label"/>
            </xsl:with-param>
            <xsl:with-param name="violations" select="$key-violations"/>
        </xsl:call-template>

        <!-- restore subject context -->
        <xsl:apply-templates select="../@rdf:about | ../@rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- do not show secretary URI input -->
    <xsl:template match="acl:delegates[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="1"/>

    <!-- do not show the email hash value -->
    <xsl:template match="foaf:mbox_sha1sum[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="1"/>

    <xsl:template name="lacl:password">
        <xsl:param name="this" select="xs:anyURI('&lacl;password')" as="xs:anyURI"/>
        <xsl:param name="type" select="'password'" as="xs:string"/>
        <!-- <xsl:param name="id" as="xs:string?"/> -->
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="for" select="generate-id()" as="xs:string"/>
        <xsl:param name="required" select="true()" as="xs:boolean"/>
        <xsl:param name="label" as="item()*">
            <xsl:apply-templates select="key('resources', '&lacl;password', document(ac:document-uri('&lacl;')))" mode="ac:label"/>
        </xsl:param>
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="error" select="@rdf:resource = $violations/ldh:violationValue or $violations/spin:violationPath/@rdf:resource = $this" as="xs:boolean"/>
        <xsl:param name="row-violations" select="$violations[spin:violationPath/@rdf:resource = $this][rdfs:label]" as="element()*"/>
        <xsl:param name="class" select="concat('ldh-prop-group', if ($error) then ' is-violation' else (), if ($required) then ' required' else ())" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <input type="hidden" name="pu" value="&lacl;password"/>

            <xsl:apply-templates select="." mode="ldh:PropertyLabel">
                <xsl:with-param name="this" select="$this"/>
                <xsl:with-param name="label" select="$label"/>
                <xsl:with-param name="required" select="$required"/>
            </xsl:apply-templates>

            <!-- the group holds a single value row, so that row is always its last one -->
            <div class="ldh-prop-row is-last{if ($error) then ' is-violation' else ()}">
                <div class="value val-stack">
                    <div class="val-main">
                        <xsl:apply-templates select="." mode="ac:FieldShell">
                            <xsl:with-param name="type" select="$type"/>
                            <xsl:with-param name="control" as="item()*">
                                <xsl:call-template name="xhtml:Input">
                                    <xsl:with-param name="name" select="'ol'"/>
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="id" select="$for"/>
                                    <xsl:with-param name="disabled" select="$disabled"/>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:apply-templates>

                        <!-- the row's one annotation strip, as in the shared property template: .ldh-annot
                             keeps the tag on the control's line and hidden until the row is hovered or focused -->
                        <xsl:if test="$type-label">
                            <div class="ldh-annot">
                                <xsl:apply-templates select="." mode="ac:AnnotationTag">
                                    <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet an-term is-literal'"/>
                                    <xsl:with-param name="label" as="item()*">
                                        <xsl:apply-templates select="key('resources', 'literal', ldh:translations())" mode="ac:label"/>
                                    </xsl:with-param>
                                </xsl:apply-templates>
                            </div>
                        </xsl:if>
                    </div>

                    <!-- the password violations are authored server-side (mismatch, length, character set) - inline their messages like the shared property template does -->
                    <xsl:if test="exists($row-violations)">
                        <div class="ldh-vmsgs">
                            <xsl:for-each select="$row-violations">
                                <span class="ac-help va-negative sz-sm" role="alert">
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
    <xsl:template match="dh:slug[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())] | foaf:primaryTopic[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())] | foaf:isPrimaryTopicOf[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())] | cert:modulus[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())] | cert:exponent[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:FormControl" priority="3">
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

    <xsl:template match="*[@rdf:about = '&foaf;mbox'][ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ac:label" priority="1">
        <xsl:value-of>
            <xsl:apply-templates select="key('resources', 'email', ldh:translations())" mode="ac:label"/>
        </xsl:value-of>
    </xsl:template>

    <!-- turn off additional properties -->
    <xsl:template match="*[ac:absolute-path(ldh:request-uri()) = resolve-uri(encode-for-uri('sign up'), lds:base())]" mode="ldh:PropertyControl" priority="1"/>

</xsl:stylesheet>