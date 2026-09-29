<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY dh     "https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY java   "http://xml.apache.org/xalan/java/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:lds="&lds;"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:xsd="&xsd;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:sd="&sd;"
xmlns:sh="&sh;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:url="&java;java.net.URLDecoder"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:svg="http://www.w3.org/2000/svg"
exclude-result-prefixes="#all"
>

    <!--
        THE OPEN VALUE TIER: how a property and its values render when nothing more specific claims them.

        Imported by hooks.xsl, so this module sits BELOW the package stylesheets (see the contract in
        hooks.xsl): a package rule for its own property or datatype - a form control for skos:prefLabel,
        a value cell for a unit - outranks every generic rule here whatever the priorities, while the
        platform's typed vocabulary modules (imports/rdf.xsl, imports/dct.xsl...) above the packages
        still outrank the package. The rules are the value leaves and nothing else: one property row,
        one value cell, one form control, one annotation. The functions, keys and global params they
        call live in imports/default.xsl, which stays sealed above the packages on purpose - a module
        down here is overridable in everything it declares, and lds:origin() or $acl:agent must not be.

        Every rule here is the generic fallback of an open mode: ac:FormControl, ac:PropertyListValue,
        ac:ValueAnnotations, ldh:TypeControl, ac:property-label, ac:object-label, ac:lang-tag,
        ac:ResultsTableHeaderCell, the xhtml:Anchor/svg:Anchor overrides, xhtml:Input for real numbers,
        ldh:DateTimePair, and the unnamed mode's property row and value link.
    -->

    <xsl:template match="@rdf:resource | @rdf:nodeID | srx:uri" mode="ac:object-label" priority="1">
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:variable name="this" select="." as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="key('resources', .)">
                <xsl:apply-templates select="key('resources', .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="$object-metadata!key('resources', $this, .)">
                <!-- <xsl:message>ac:object-label(<xsl:value-of select="."/>) $object-metadata: <xsl:value-of select="serialize($object-metadata)"/></xsl:message> -->
                <xsl:apply-templates select="$object-metadata!key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="ldh:label-document(ac:document-uri(.))!key('resources', $this, .)">
                <xsl:apply-templates select="ldh:label-document(ac:document-uri(.))!key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="contains(., '#') and not(ends-with(., '#'))">
                <xsl:sequence select="substring-after(., '#')"/>
            </xsl:when>
            <xsl:when test="string-length(tokenize(., '/')[last()]) &gt; 0">
                <xsl:sequence select="translate(tokenize(., '/')[last()], '_', ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- override makes $property-metadata lookup take precedence over Linked Data -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:property-label">
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:variable name="this" select="concat(namespace-uri(), local-name())"/>
        
        <xsl:choose>
            <xsl:when test="key('resources', $this)">
                <xsl:apply-templates select="key('resources', $this)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="$property-metadata/key('resources', $this, .)">
                <xsl:apply-templates select="$property-metadata/key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="ldh:label-document(ac:document-uri(namespace-uri()))!key('resources', $this, .)">
                <xsl:apply-templates select="ldh:label-document(ac:document-uri(namespace-uri()))!key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local-name()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- RDFa overrides -->

    <!-- Every value cell takes its RDFa attributes from ac:RDFaAttributes rather than spelling them out, so the term ->
         attribute mapping lives in one place and the anatomy here is the only thing these templates decide. It is also what
         makes the cells faithful: a dd's literal used to be whatever text ended up inside it, which meant the language pill
         concatenated onto the value ("Square" + "en" = "Squareen") and a formatted date replaced its own lexical form. The
         attribute set carries @content now, so what the cell shows and what it asserts are free to differ. -->

    <xsl:template match="@rdf:resource" mode="ac:PropertyListValue">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd>
            <xsl:apply-templates select="." mode="ac:RDFaAttributes"/>
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>

    <xsl:template match="@rdf:nodeID" mode="ac:PropertyListValue">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd>
            <xsl:apply-templates select="." mode="ac:RDFaAttributes"/>
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>

    <xsl:template match="text()[../@xml:lang]" mode="ac:PropertyListValue">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <!-- the value declares its own language rather than inheriting the document's. A property renders every language it
             carries, so the two sit side by side and the document default is wrong for at least one of them: without @lang a
             screen reader reads "Square" with Lithuanian phonetics on an lt page, and "Aikštė" with an English voice on an en
             one. This is WCAG 3.1.2, and the attribute set says the same thing to an RDFa processor -->
        <dd>
            <xsl:apply-templates select="." mode="ac:RDFaAttributes"/>
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>

            <xsl:apply-templates select="../@xml:lang" mode="ac:lang-tag"/>
        </dd>
    </xsl:template>

    <!-- a property whose only value is the empty string: RDF/XML writes it as a childless element, so there is no text node
         to dispatch and the row used to lose its value cell entirely - taking the group's RDFa @property with it, which left
         the dt's title blank and the dl with a term and no description -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*[empty(node() | @rdf:resource | @rdf:nodeID)]" mode="ac:PropertyListValue">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd>
            <xsl:apply-templates select="." mode="ac:RDFaAttributes"/>
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>
        </dd>
    </xsl:template>

    <!-- the property list and the table cell both put a value's languages side by side, so the pill that tells them apart
         is written once here and applied from wherever the values are laid out. The core Tag at the inline xs size,
         in the system's structural-annotation violet (§17c) -->
    <xsl:template match="@xml:lang" mode="ac:lang-tag">
        <span class="ac-tag em-quiet co-accent sz-xs">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <xsl:template match="node()" mode="ac:PropertyListValue">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd>
            <xsl:apply-templates select="." mode="ac:RDFaAttributes"/>
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>

    <!-- DEFAULT -->

    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="concat(namespace-uri(), local-name())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>

        <span>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$title">
                <xsl:attribute name="title" select="$title"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <!-- the predicate label declares the language it was negotiated into, the same as a value does. Without it the
                 label inherits the document language, which is the language the page is composed in and not necessarily the
                 one the ontology had: a Lithuanian reader gets Lithuanian predicates inside a document whose chrome, and so
                 whose lang, is English. Resolved through the mode rather than ac:property-label() because the function is
                 declared as xs:string? and drops the winning literal's tag at its own boundary -->
            <xsl:variable name="label" as="item()*">
                <xsl:apply-templates select="." mode="ac:property-label">
                    <xsl:with-param name="property-metadata" select="$property-metadata"/>
                </xsl:apply-templates>
            </xsl:variable>
            <!-- item()*, not node()*: the fallback branches of ac:property-label return computed strings rather than the
                 label node - substring-after($this, '#') for a predicate the ontology does not describe - and binding an
                 atomic value to node()* is XTTE0570 at run time, which compiles clean and fails on a real page -->
            <xsl:variable name="label-node" select="$label[1][. instance of node()]" as="node()?"/>
            <xsl:if test="$label-node/../@xml:lang">
                <xsl:attribute name="lang" select="$label-node/../@xml:lang"/>
            </xsl:if>

            <xsl:choose>
                <xsl:when test="$property-metadata">
                    <xsl:sequence select="ac:property-label(., $property-metadata)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ac:property-label(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>

    <!-- ANCHOR -->
    
    <!-- subject resource -->
    <xsl:template match="@rdf:about" mode="xhtml:Anchor">
<!--        <xsl:param name="graph" as="xs:anyURI?" tunnel="yes"/>-->
        <xsl:param name="fragment" select="ac:fragment-id(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri(xs:anyURI(.)), map{}, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="role" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class || (if (not(starts-with(., lds:base()))) then ' external' else())"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="@rdf:about | @rdf:resource" mode="svg:Anchor">
        <xsl:param name="fragment" select="ac:fragment-id(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri(xs:anyURI(.)), map{}, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" select="$fragment" as="xs:string?"/>
        <xsl:param name="label" select="if (parent::rdf:Description) then ac:svg-label(..) else ac:svg-object-label(.)" as="xs:string"/>
        <xsl:param name="title" select="$label" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="label" select="$label"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class || (if (not(starts-with(., lds:base()))) then ' external' else())"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>

    <!-- DEFAULT -->

    <!-- proxy link URIs if they are external -->
    <xsl:template match="@rdf:resource | srx:uri" priority="2">
        <xsl:param name="fragment" select="ac:fragment-id(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri(xs:anyURI(.)), map{}, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>
        
        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class || (if (not(starts-with(., lds:base()))) then ' external' else())"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>

    <!-- TABLE CELLS -->

    <!-- the semantic-markup contract's th scope, on top of Web-Client's emitter -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:ResultsTableHeaderCell">
        <th scope="col">
            <xsl:apply-templates select="."/>
        </th>
    </xsl:template>

    <!-- TYPE -->

    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ldh:TypeControl"/>

    <!-- object -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@*" mode="ldh:TypeControl"/>

    <!-- resource -->
    <xsl:template match="*[*]/@rdf:about | *[*]/@rdf:nodeID" mode="ac:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="document-uri" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="about" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#id' || ac:uuid())" as="xs:anyURI?"/>
        <xsl:param name="tools" as="element()*"/>

        <div class="ldh-subject">
            <xsl:if test="$type = 'hidden'">
                <xsl:attribute name="style" select="'display: none'"/>
            </xsl:if>

            <input type="hidden" class="old subject-type" value="{if (local-name() = 'about') then 'su' else if (local-name() = 'nodeID') then 'sb' else ()}"/>
            <select class="term-select subject-type">
                <option value="su">
                    <xsl:if test="local-name() = 'about'">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    <xsl:apply-templates select="key('resources', 'term-uri', ldh:translations())" mode="ac:label"/>
                </option>
                <option value="sb">
                    <xsl:if test="local-name() = 'nodeID'">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    <xsl:apply-templates select="key('resources', 'term-blank-node', ldh:translations())" mode="ac:label"/>
                </option>
            </select>

            <label class="uri-field">
                <span class="msi outline sm" aria-hidden="true">link</span>
                <!-- hidden inputs in which we store the old values of the visible input -->
                <input type="hidden" class="old su">
                    <xsl:attribute name="value" select="if (local-name() = 'about') then . else $about"/>
                </input>
                <input type="hidden" class="old sb">
                    <xsl:attribute name="value" select="if (local-name() = 'nodeID') then . else generate-id()"/>
                </input>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'text'"/>
                    <!-- <xsl:with-param name="id" select="$id"/> -->
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </label>

            <div class="ldh-subject-tools">
                <xsl:sequence select="$tools"/>
            </div>
        </div>
    </xsl:template>

    <!-- turn off default form controls for rdf:type as we are handling it specially with ldh:TypeControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="ac:FormControl" priority="1"/>

    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:FormControl">
        <xsl:param name="this" select="xs:anyURI(concat(namespace-uri(), local-name()))" as="xs:anyURI"/>
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="error" select="@rdf:resource = $violations/ldh:violationValue or $violations/spin:violationPath/@rdf:resource = $this or $violations/sh:resultPath/@rdf:resource = $this" as="xs:boolean"/>
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="label" as="xs:string?">
            <xsl:sequence select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)"/> <!-- function upper-cases first letter, unlike mode="ac:label" -->
        </xsl:param>
        <xsl:param name="description" as="xs:string?">
            <xsl:for-each select="$property-metadata/key('resources', $this)">
                <xsl:sequence select="ac:description(.)"/> <!-- use function instead of mode="ac:description" as there might be multiple descriptions -->
            </xsl:for-each>
        </xsl:param>
        <xsl:param name="show-label" select="true()" as="xs:boolean"/>
        <xsl:param name="constructor" as="document-node()?"/>
        <!-- the class the constructor declares for this property's objects is a fact about the PROPERTY, so the row
             derives it once and hands it to every value control (to scope its combobox) and value annotation (to
             name its chip); nothing below the row sees the constructor -->
        <xsl:param name="forClass" select="ldh:constructor-range(., $constructor)" as="xs:anyURI*"/>
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="cloneable" select="false()" as="xs:boolean"/>
        <xsl:param name="type-constraints" as="element()*"/>
        <xsl:param name="type-shapes" as="element()*"/>
        <!-- only the first property that has a mandatory constraint is required, the following ones are not -->
        <xsl:param name="required" select="($type-shapes[sh:path/@rdf:resource = $this][sh:minCount &gt;= count(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this])]) or ($type-constraints//srx:binding[@name = 'property'][srx:uri = $this] and not(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this]))" as="xs:boolean"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <!-- inline messages for this row's violations, except the missing-mandatory-property kind, where the .is-violation decoration already says everything. The kind is read off the violation's spin:violationSource description (included in the response by the exception mapper) resp. the SHACL constraint component -->
        <xsl:param name="row-violations" select="$violations[spin:violationPath/@rdf:resource = $this or sh:resultPath/@rdf:resource = $this or ldh:violationValue = current()/@rdf:resource][not(key('resources', (spin:violationSource/@rdf:resource, spin:violationSource/@rdf:nodeID))/rdf:type/@rdf:resource = '&ldh;MissingPropertyValue')][not(sh:sourceConstraintComponent/@rdf:resource = '&sh;MinCountConstraintComponent')]" as="element()*"/>
        <xsl:param name="class" select="concat('ldh-prop-group', if ($error or exists($row-violations)) then ' is-violation' else (), if ($required) then ' required' else ())" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Input">
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:apply-templates>
            <xsl:if test="$show-label">
                <xsl:apply-templates select="." mode="ldh:PropertyLabel">
                    <xsl:with-param name="this" select="$this"/>
                    <xsl:with-param name="label" select="$label"/>
                    <xsl:with-param name="required" select="$required"/>
                    <xsl:with-param name="description" select="$description"/>
                </xsl:apply-templates>
            </xsl:if>

            <div class="ldh-prop-row{if (position() = last()) then ' is-last' else ()}{if ($error or exists($row-violations)) then ' is-violation' else ()}">
                <div class="value val-stack">
                    <div class="val-main">
                        <!-- the control, then ONE annotation strip, which the row renders. The control emits no
                             chips of its own (type-label false); everything that annotates the value - term-kind or
                             datatype chip AND the language field of a tagged literal - is what ac:ValueAnnotations
                             says about it, and it all lands in this one div.ldh-annot. Measured before: every chip
                             carried a strip of its own and the language field rode a second strip for an existing
                             value but none for a constructor's, so with each strip at flex 1 1 0 the field sat
                             halfway along one row and flush right on the next, and was hover-revealed on one and
                             always visible on the other -->
                        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"> <!-- not @rdf:* because that would apply to @rdf:parseType -->
                            <xsl:with-param name="id" select="$for"/>
                            <xsl:with-param name="required" select="$required"/>
                            <xsl:with-param name="forClass" select="$forClass"/>
                            <xsl:with-param name="type-label" select="false()"/>
                        </xsl:apply-templates>
                        <!-- the datatype rides the form encoding as a hidden input; its visible face is the chip in the strip -->
                        <xsl:apply-templates select="@rdf:datatype" mode="#current"/>

                        <xsl:variable name="annotations" as="item()*">
                            <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="ac:ValueAnnotations">
                                <xsl:with-param name="forClass" select="$forClass"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:if test="exists($annotations)">
                            <div class="ldh-annot">
                                <xsl:sequence select="$annotations"/>
                            </div>
                        </xsl:if>
                    </div>

                    <!-- authored labels/messages render verbatim; unlabeled violations fall back to a localized generic keyed by ldh:violation-key() -->
                    <xsl:if test="exists($row-violations)">
                        <div class="ldh-vmsgs">
                            <xsl:for-each select="$row-violations">
                                <span class="ac-help va-negative sz-sm" role="alert">
                                    <span class="msi outline sm" aria-hidden="true">error</span>
                                    <span>
                                        <xsl:choose>
                                            <xsl:when test="sh:resultMessage">
                                                <xsl:value-of select="sh:resultMessage[1]"/>
                                            </xsl:when>
                                            <xsl:when test="rdfs:label">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="." mode="ac:label"/>
                                                </xsl:value-of>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', ldh:violation-key(.), ldh:translations())" mode="ac:label"/>
                                                </xsl:value-of>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </span>
                                </span>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                </div>

                <div class="row-actions">
                    <xsl:if test="$cloneable">
                        <button type="button" class="ac-iconbtn sz-xs in-accent ap-ghost btn-add">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'add-stmt', ldh:translations())" mode="ac:label"/>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">add</span>
                        </button>
                    </xsl:if>

                    <xsl:if test="not($required)">
                        <button type="button" tabindex="-1" class="ac-iconbtn sz-xs in-destructive ap-ghost btn-remove-property">
                            <xsl:attribute name="title">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'remove-stmt', ldh:translations())" mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">remove</span>
                        </button>
                    </xsl:if>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- object resource -->
    <!-- object resource: committed values render as combobox chips, open values as the combobox lookup -->
    <xsl:template match="@rdf:resource" mode="ac:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- object resource exists in the current document -->
            <xsl:when test="key('resources', .)">
                <xsl:apply-templates select="key('resources', .)" mode="ldh:ComboboxChip">
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:apply-templates>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
            <xsl:when test="exists($object-metadata)">
                <xsl:choose>
                    <xsl:when test="key('resources', ., $object-metadata)">
                        <xsl:apply-templates select="key('resources', ., $object-metadata)" mode="ldh:ComboboxChip">
                            <xsl:with-param name="forClass" select="$forClass"/>
                        </xsl:apply-templates>

                        <xsl:if test="$type-label">
                            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="forClass" select="$forClass"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="ldh:Combobox">
                            <xsl:with-param name="value" select="."/>
                            <xsl:with-param name="forClass" select="$forClass"/>
                        </xsl:call-template>

                        <xsl:if test="$type-label">
                            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                                <xsl:with-param name="type" select="$type"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ldh:Combobox">
                    <xsl:with-param name="value" select="."/>
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:call-template>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                        <xsl:with-param name="type" select="$type"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@rdf:resource" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet an-term is-resource'"/>
                <xsl:with-param name="label" as="item()*">
                    <xsl:choose>
                        <xsl:when test="exists($forClass)">
                            <xsl:value-of select="$forClass ! ldh:class-label(xs:anyURI(.))" separator=""/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="key('resources', 'resource', ldh:translations())" mode="ac:label"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- object blank node -->
    <xsl:template match="*[@rdf:about]/*/@rdf:nodeID | *[@rdf:nodeID]/*/@rdf:nodeID" mode="ac:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>
        <xsl:variable name="resource" select="key('resources', .)"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$inline and $resource and not(. = $traversed-ids)">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>

                <xsl:apply-templates select="$resource" mode="#current">
                    <xsl:with-param name="traversed-ids" select="(., $traversed-ids)" tunnel="yes"/>
                </xsl:apply-templates>

                <!-- restore subject context -->
                <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$resource">
                <xsl:apply-templates select="$resource" mode="ldh:ComboboxChip">
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:apply-templates>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                        <xsl:with-param name="type" select="$type"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- blank nodes that only have rdf:type xsd:* and no other properties become literal inputs.
         Duplicates Web-Client's generic on purpose: this layer's object-bnode template above would
         otherwise swallow the match by import precedence, so the priority ladder must resolve here -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[starts-with(@rdf:resource, '&xsd;')])]]" mode="ac:FormControl" priority="2">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <!-- the field shell keeps this input on the shared control width; a bare input here sat at its
             UA-intrinsic width beside the capped fields (the §5d diagnostic) -->
        <xsl:apply-templates select="." mode="ac:FieldShell">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="control" as="item()*">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:apply-templates>

        <!-- datatype -->
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="key('resources', .)/rdf:type/@rdf:resource"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- what an xsd:* marker says about its value is the datatype it stands for, so its annotation is the
         @rdf:datatype chip of the literal it will become, reached by synthesising that literal. Shadows the
         Client's marker annotation (a bare "literal" chip) by import precedence; the boolean marker is an
         xsd:* marker too, so it is covered here rather than by a copy -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[starts-with(@rdf:resource, '&xsd;')])]]" mode="ac:ValueAnnotations" priority="2">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:variable name="datatype" as="document-node()">
            <xsl:document>
                <rdf:Description>
                    <xsl:element name="{../name()}" namespace="{../namespace-uri()}">
                        <xsl:attribute name="rdf:datatype" select="key('resources', .)/rdf:type/@rdf:resource"/>
                    </xsl:element>
                </rdf:Description>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$datatype//@rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="$type"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- A blank node typed rdf:langString is a LANGUAGE-TAGGED literal: a value input plus a language
         field, never a datatype and never a resource. Web-Client carries the same rule, and this is a
         deliberate shadow of it rather than a duplicate by accident: LDH imports Web-Client, so ANY
         LDH template matching this node wins on import precedence whatever priority the Client's
         carries. Measured while fixing it - excluding rdf:langString from LDH's non-XSD resource
         lookup did not reach the Client's rule, it merely handed the node to LDH's generic bnode
         control, which rendered an ob (object blank node) field for a property that takes text. The
         xsd:* template above shadows the Client's the same way and for the same reason.

         Why not a datatype: RDF 1.1 requires an rdf:langString literal to carry a language tag and
         forbids it carrying a datatype attribute, so emitting lt=rdf:langString would encode an
         ill-formed literal. The language field, its ll input and the annotation are all reached by
         synthesising the value node this control produces, so the constructor-driven field and the
         one rendered from existing data are the same emitters rather than two that can drift. It is
         prefilled from ac:langs(), the reader's own accepted list.

         What this cost before it was fixed: with the marker treated as a resource, an empty combobox
         still submitted its generated id URI as the object, so saving the form wrote
         skos:altLabel <...#id03f1366d-...> into the data instead of a literal. -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&rdf;langString'])]]" mode="ac:FormControl" priority="3">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
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
                </xsl:call-template>
            </xsl:with-param>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="disabled" select="$disabled"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- the marker's annotations are the ones a tagged literal carries (below): the rdf:langString chip and the
         language field, reached by synthesising the value the control will produce so the two paths share one
         emitter. The field is an ANNOTATION, so it rides the row's strip beside the chip - it is not part of the
         control, and rendering it there is what put it in a different place for a constructor's value than for
         an existing one -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&rdf;langString'])]]" mode="ac:ValueAnnotations" priority="3">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:variable name="value" as="element()">
            <xsl:element name="{../name()}" namespace="{../namespace-uri()}">
                <xsl:attribute name="xml:lang" select="ac:langs()[1]"/>
            </xsl:element>
        </xsl:variable>

        <xsl:apply-templates select="$value/@xml:lang" mode="#current">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- special case for owl:NamedIndividual bnode instances which become comboboxes -->
    <xsl:template match="*[@rdf:nodeID]/*/@rdf:nodeID[key('resources', .)/rdf:type/@rdf:resource = '&owl;NamedIndividual']" mode="ac:FormControl" priority="2">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-combobox combobox'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI"/>

        <xsl:apply-templates select="key('resources', .)" mode="ldh:ComboboxChip">
            <xsl:with-param name="forClass" select="$forClass"/>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="forClass" select="$forClass"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- blank nodes that only have non-XSD rdf:type and no other properties become resource lookups.
         rdf:langString is excluded because it is a LITERAL datatype that merely happens to live outside
         the xsd: namespace: a marker typed with it means "text with a language tag", and treating it as
         a class handed the author a URI picker for a property that takes text - which is exactly what a
         constructor declaring [ a rdf:langString ] got. Excluded here rather than shadowed by a second
         copy of the literal control: with no LDH template claiming it, Web-Client's own langString rule
         applies, so the control has one implementation in the layer that owns generic form behaviour. -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[not(starts-with(@rdf:resource, '&xsd;'))][not(@rdf:resource = '&rdf;langString')])]]" mode="ac:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-combobox combobox'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI*"/>

        <xsl:call-template name="ldh:Combobox">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="forClass" select="$forClass"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="forClass" select="$forClass"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- RDFa editor for XMLLiteral objects -->

    <xsl:template match="*[@rdf:parseType = 'Literal']/xhtml:*" mode="ac:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="type" select="'textarea'" as="xs:string?"/> <!-- 'textarea' is not a valid <input> type -->
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <div class="rdfa-editor-content">
            <xsl:copy-of select="node()" copy-namespaces="no"/>
        </div>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="'&rdf;XMLLiteral'"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet an-term is-blank'"/>
                <xsl:with-param name="label" as="item()*">
                    <xsl:choose>
                        <xsl:when test="exists($forClass)">
                            <xsl:value-of select="$forClass ! ldh:class-label(xs:anyURI(.))" separator=""/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="key('resources', 'resource', ldh:translations())" mode="ac:label"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- literal term-kind / datatype / language annotations (shadow the Web-Client help-inline emitters) -->

    <xsl:template match="text()" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:choose>
                <xsl:when test="../@rdf:datatype">
                    <xsl:apply-templates select="../@rdf:datatype" mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="ac:AnnotationTag">
                        <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet an-term is-literal'"/>
                        <xsl:with-param name="label" as="item()*">
                            <xsl:apply-templates select="key('resources', 'literal', ldh:translations())" mode="ac:label"/>
                        </xsl:with-param>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- A literal carrying a language tag IS an rdf:langString, and is named as one. RDF 1.1 gives
         every tagged literal that datatype, so "Literal" said less than the data does - and said
         something different from the field the same property gets before a value exists, which
         announces rdf:langString from the constructor. Same tag treatment as any other datatype,
         because that is what it is; the untagged case keeps the plain term tag below. -->
    <xsl:template match="text()[../@xml:lang]" mode="ac:ValueAnnotations" priority="1">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <xsl:apply-templates select="../@xml:lang" mode="#current">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- the language tag is what makes the literal an rdf:langString, so it is the tag that carries both
         annotations: the chip naming the datatype and the field editing the tag, the strip's last item -->
    <xsl:template match="@xml:lang" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet co-neutral'"/>
                <xsl:with-param name="title" select="'&rdf;langString'"/>
                <xsl:with-param name="label" select="'rdf:langString'"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="ac:FormControl">
                <xsl:with-param name="disabled" select="$disabled"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- an XMLLiteral is one value however many nodes it serialises to, and the chip names its datatype -->
    <xsl:template match="*[@rdf:parseType = 'Literal']/xhtml:*" mode="ac:ValueAnnotations" priority="1">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet co-neutral'"/>
                <xsl:with-param name="title" select="'&rdf;XMLLiteral'"/>
                <xsl:with-param name="label" select="'rdf:XMLLiteral'"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- the remaining nodes of the XMLLiteral are inside the editor above, not values of their own -->
    <xsl:template match="*[@rdf:parseType = 'Literal']/node()" mode="ac:ValueAnnotations"/>

    <xsl:template match="@rdf:datatype" mode="ac:ValueAnnotations">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:AnnotationTag">
                <xsl:with-param name="class" select="'ac-tag sz-sm em-quiet co-neutral'"/>
                <xsl:with-param name="title" select="."/>
                <xsl:with-param name="label" select="if (starts-with(., '&xsd;')) then 'xsd:' || substring-after(., '&xsd;') else string(.)"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- the field-shell emitters live in Web-Client now; the language field only takes the design's app-kit wrapper class -->
    <xsl:template match="@xml:lang" mode="ac:FormControl">
        <xsl:next-match>
            <xsl:with-param name="class" select="'ldh-lang'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- real numbers -->
    
    <xsl:template match="text()[../@rdf:datatype = '&xsd;float'] | text()[../@rdf:datatype = '&xsd;double']" mode="xhtml:Input" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="value" select="format-number(., '#####.00000')"/>
        </xsl:call-template>
        
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="../@rdf:datatype"/>
        </xsl:call-template>
    </xsl:template>

    <!-- datetimes -->

    <!-- the pair emits its own field shells, so it must not ride the generic text() field-shell wrapper;
         the hidden variant is a plain element, so it stays on the xhtml:Input primitive -->
    <xsl:template match="text()[../@rdf:datatype = '&xsd;dateTime'][. castable as xs:dateTime]" mode="ac:FormControl" priority="1">
        <xsl:param name="type" select="'datetime-local'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$type = 'datetime-local'">
                <xsl:apply-templates select="." mode="ldh:DateTimePair">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- value and timezone offset as two TextFields sitting together, as in the design: a composite
         component (the app kit's .ldh-dt-pair), so it carries a component mode rather than living
         inside xhtml:Input, whose modes stay childless element primitives -->
    <xsl:template match="text()[../@rdf:datatype = '&xsd;dateTime'][. castable as xs:dateTime]" mode="ldh:DateTimePair">
        <xsl:param name="type" select="'datetime-local'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <span class="ldh-dt-pair">
            <xsl:apply-templates select="." mode="ac:FieldShell">
                <xsl:with-param name="control" as="item()*">
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="class" select="$class"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="value" select="format-dateTime(xs:dateTime(.), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')"/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="type" select="'hidden'"/>
                <xsl:with-param name="name" select="'lt'"/>
                <xsl:with-param name="value" select="../@rdf:datatype"/>
            </xsl:call-template>

            <xsl:apply-templates select="." mode="ac:FieldShell">
                <xsl:with-param name="control" as="item()*">
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="class" select="'input-timezone'"/>
                        <xsl:with-param name="type" select="'text'"/>
                        <xsl:with-param name="value" select="format-dateTime(xs:dateTime(.), '[Z]')"/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:apply-templates>
        </span>
    </xsl:template>

    <!-- booleans -->

    <xsl:template match="text()[../@rdf:datatype = '&xsd;boolean']" mode="ac:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="value" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="ac:SelectShell">
                    <xsl:with-param name="select" as="item()*">
                <select name="ol">
                    <xsl:if test="$id"><xsl:attribute name="id" select="$id"/></xsl:if>
                    <xsl:if test="$class"><xsl:attribute name="class" select="$class"/></xsl:if>
                    <xsl:if test="$disabled"><xsl:attribute name="disabled" select="'disabled'"/></xsl:if>
                    <option value="true">
                        <xsl:if test=". = 'true'"><xsl:attribute name="selected" select="'selected'"/></xsl:if>
                        <xsl:text>true</xsl:text>
                    </option>
                    <option value="false">
                        <xsl:if test=". = 'false'"><xsl:attribute name="selected" select="'selected'"/></xsl:if>
                        <xsl:text>false</xsl:text>
                    </option>
                </select>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="../@rdf:datatype"/>
        </xsl:call-template>

        <xsl:if test="$type-label and not($type = 'hidden')">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- boolean placeholder via constructor's blank-node form: property → bnode whose only child is rdf:type xsd:boolean -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;boolean'])]]" mode="ac:FormControl" priority="3">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="id" select="$id"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="ac:SelectShell">
                    <xsl:with-param name="select" as="item()*">
                <select name="ol">
                    <xsl:if test="$id"><xsl:attribute name="id" select="$id"/></xsl:if>
                    <xsl:if test="$class"><xsl:attribute name="class" select="$class"/></xsl:if>
                    <xsl:if test="$disabled"><xsl:attribute name="disabled" select="'disabled'"/></xsl:if>
                    <option value="true">true</option>
                    <option value="false">false</option>
                </select>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="key('resources', .)/rdf:type/@rdf:resource"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="ac:ValueAnnotations">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
