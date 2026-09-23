<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:lapp="&lapp;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:spin="&spin;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:variable name="type-graph-query" as="xs:string">
        <![CDATA[
            SELECT DISTINCT  ?graph
            WHERE
              { GRAPH ?graph
                  { $Type  ?p  ?o }
              }
        ]]>
    </xsl:variable>
    <!-- Which graph holds each constructor. A resource's URI does not tell you which document describes it -
         the add path already asks this question about the class, and the save path has to ask it about the
         constructor rather than stripping the fragment off its URI. Runs against the admin endpoint, since
         that is where the named graphs are; /ns serves the merged closure and has none. -->
    <xsl:variable name="constructor-graph-query" as="xs:string">
        <![CDATA[
            PREFIX sp: <http://spinrdf.org/sp#>

            SELECT DISTINCT  $constructor ?graph
            WHERE
              { GRAPH ?graph
                  { $constructor  sp:text  ?text }
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="constructor-update-string" as="xs:string">
        <![CDATA[
            PREFIX sp: <http://spinrdf.org/sp#>

            DELETE
            {
                $this sp:text ?oldText .
            }
            INSERT
            {
                $this sp:text $text .
            }
            WHERE
            {
                OPTIONAL
                {
                    $this sp:text ?oldText .
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="constructor-insert-string" as="xs:string">
        <![CDATA[
            PREFIX spin: <http://spinrdf.org/spin#>

            INSERT
            {
                $Type spin:constructor $this .
            }
            WHERE
            {
                $Type ?p ?o .
            }
        ]]>
    </xsl:variable>
    
    <!-- TEMPLATES -->

    <xsl:template name="ldh:LoadConstructors">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="type" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:param name="form" as="element()?"/> <!-- the form the editor was opened from, where a failure to open it reports: the container is behind that form's dialog -->
        <xsl:variable name="container" select="." as="element()"/>

        <ixsl:set-style name="cursor" select="'progress'" object="."/>

        <xsl:variable name="context" as="map(*)" select="map{
            'container': $container,
            'type': $type,
            'types': ($type)
        }"/>

        <ixsl:promise select="ixsl:resolve($context) =>
            ixsl:then(ldh:load-constructors#1) =>
            ixsl:then(ldh:http-request-threaded(?, 'constructors-request', 'constructors-response')) =>
            ixsl:then(ldh:handle-response(?, 'constructors-response')) =>
            ixsl:then(ldh:set-constructors#1) =>
            ixsl:then(ldh:load-constructor-graphs#1) =>
            ixsl:then(ldh:http-request-threaded(?, 'constructor-graphs-request', 'constructor-graphs-response')) =>
            ixsl:then(ldh:handle-response(?, 'constructor-graphs-response')) =>
            ixsl:then(ldh:set-constructor-graphs#1) =>
            ixsl:then(ldh:render-constructor-mode#1)"
            on-failure="ldh:promise-failure($form, 'constructors-not-loaded', ?)"/>
    </xsl:template>

    <!-- Async constructor-to-graph pair. Reads context('constructors'), stores parsed sparql-results at
         context('constructor-graphs'). It has to be a real request rather than a document() call: SaxonJS
         resolves document() out of its document pool and returns empty for a URI nothing has fetched, with
         no error and no network request, which is exactly what it did here. -->
    <xsl:function name="ldh:load-constructor-graphs" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="constructors" select="$context('constructors')" as="document-node()?"/>
        <xsl:variable name="constructor-uris" select="distinct-values($constructors//srx:binding[@name = 'constructor']/srx:uri)" as="xs:string*"/>
        <xsl:variable name="query-string" select="$constructor-graph-query || ' VALUES $constructor { ' || string-join(for $uri in $constructor-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
        <xsl:variable name="admin-base-uri" select="xs:anyURI(replace(lapp:base(), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('sparql', $admin-base-uri), map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($results-uri, map{}), 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:sequence select="map:merge(($context, map{ 'constructor-graphs-request': $request }))"/>
    </xsl:function>

    <!-- A failed lookup is not fatal: the editor still renders and the save path falls back to deriving the
         document from the constructor URI, which is the behaviour before the lookup existed. -->
    <xsl:function name="ldh:set-constructor-graphs" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('constructor-graphs-response')" as="map(*)?"/>
        <xsl:choose>
            <xsl:when test="exists($response) and $response?status = 200 and $response?media-type = 'application/sparql-results+xml'">
                <xsl:sequence select="map:merge(($context, map{ 'constructor-graphs': $response?body }))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Terminal callback for the LoadConstructors promise chain. Renders the constructor-edit modal
         from context('constructors'); a fetch that failed never gets here, since ldh:set-constructors raises it
         for the chain's failure handler to report. -->
    <xsl:function name="ldh:render-constructor-mode" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="type" select="$context('type')" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="map:contains($context, 'constructors') and exists($context('constructors'))">
                <xsl:variable name="constructors" select="$context('constructors')" as="document-node()"/>
                <!-- resolved once by the chain rather than per save: one query maps each constructor to the
                     graph that holds it. Absent when the lookup failed, and the save path then falls back to
                     deriving the document from the constructor URI. -->
                <xsl:variable name="constructor-graphs" select="if (map:contains($context, 'constructor-graphs')) then $context('constructor-graphs') else ()" as="document-node()?"/>

                <xsl:for-each select="$container">

                    <!-- a modal takes over from the chrome that opened it: a drop-down the pick came from is dismissed here, once its own handler has run -->
                    <xsl:apply-templates select="ixsl:page()//*[contains-token(@class, 'ac-menu-anchor')][contains-token(@class, 'is-open')] | ixsl:page()//*[contains-token(@class, 'ldh-form-actions-wrap')][contains-token(@class, 'is-open')]" mode="ldh:CloseMenu"/>
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <!-- the constructor dialog stacks above the edit form's dialog -->
                        <div class="ac-backdrop pos-top modal modal-constructor" data-depth="2">
                            <div class="ac-modal sz-lg" role="dialog" aria-modal="true" aria-labelledby="modal-title-{generate-id()}">
                                <form class="ldh-edit-form constructor-template" about="{$type}">
                                    <div class="ac-modal-head">
                                        <span class="ac-modal-icon"><span class="msi outline" aria-hidden="true">tune</span></span>
                                        <div class="ac-modal-titles">
                                            <span class="ac-modal-eyebrow">
                                                <xsl:apply-templates select="key('resources', 'constructor', ldh:translations())" mode="ac:label"/>
                                            </span>
                                            <h2 class="ac-modal-title" id="modal-title-{generate-id()}">
                                                <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lapp:base()), map{ 'query': 'DESCRIBE &lt;' || $type || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>

                                                <xsl:apply-templates select="key('resources', $type, document(ac:document-uri($request-uri)))" mode="ac:label"/>
                                            </h2>
                                        </div>
                                        <span class="ac-modal-x">
                                            <button type="button" class="ac-iconbtn sz-sm in-neutral ap-ghost" aria-label="{ac:label(key('resources', 'close', ldh:translations()))}"><span class="msi sm">close</span></button>
                                        </span>
                                    </div>
                                    <div class="ac-modal-body is-flush">
                                        <div class="ldh-ctor-body">
                                            <xsl:for-each select="$constructors//srx:result">
                                                <xsl:variable name="constructor-uri" select="srx:binding[@name = 'constructor']/srx:uri" as="xs:anyURI"/>
                                                <xsl:variable name="construct-string" select="srx:binding[@name = 'construct']/srx:literal" as="xs:string"/>
                                                <xsl:variable name="construct-json" as="item()">
                                                    <xsl:variable name="construct-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromString', [ $construct-string ])"/>
                                                    <xsl:sequence select="ixsl:call($construct-builder, 'build', [])"/>
                                                </xsl:variable>
                                                <xsl:variable name="construct-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $construct-json ])" as="xs:string"/>
                                                <xsl:variable name="construct-xml" select="json-to-xml($construct-json-string)" as="document-node()"/>

                                                <xsl:call-template name="ldh:ConstructorFieldset">
                                                    <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                                                    <xsl:with-param name="construct-xml" select="$construct-xml"/>
                                                    <xsl:with-param name="graph" select="$constructor-graphs//srx:result[srx:binding[@name = 'constructor']/srx:uri = $constructor-uri]/srx:binding[@name = 'graph']/srx:uri/xs:anyURI(.)"/>
                                                </xsl:call-template>
                                            </xsl:for-each>

                                            <button type="button" class="ldh-ctor-addctor create-action add-constructor">
                                                <span class="msi sm" aria-hidden="true">add</span>
                                                <span>
                                                    <xsl:apply-templates select="key('resources', 'constructor', ldh:translations())" mode="ac:label"/>
                                                </span>
                                            </button>
                                        </div>

                                        <div class="mhint">
                                            <button type="button" class="ac-btn in-neutral ap-outline sz-md btn-close">
                                                <span>
                                                    <xsl:apply-templates select="key('resources', 'cancel', ldh:translations())" mode="ac:label"/>
                                                </span>
                                            </button>
                                            <button type="button" class="ac-btn in-primary ap-solid sz-md btn-save">
                                                <span class="msi outline sm" aria-hidden="true">check</span>
                                                <span>
                                                    <xsl:apply-templates select="key('resources', 'save', ldh:translations())" mode="ac:label"/>
                                                </span>
                                            </button>
                                        </div>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>

        <ixsl:set-style name="cursor" select="'default'" object="$container"/>
    </xsl:function>

    <xsl:template match="json:array[@key = 'template']/json:map[json:string[@key = 'subject'] = '?this']" mode="ldh:ConstructorTripleForm" priority="1">
        <xsl:param name="class" select="'ldh-ctor-row constructor-triple'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="json:string[@key = 'predicate']" mode="ldh:ConstructorTripleFormControl"/>

            <xsl:apply-templates select="json:string[@key = 'object']" mode="ldh:ConstructorTripleFormControl"/>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="ldh:ConstructorTripleForm"/>
    
    <xsl:template match="json:map/json:string[@key = 'predicate']" mode="ldh:ConstructorTripleFormControl" name="ldh:ConstructorPredicate">
        <xsl:param name="predicate" select="." as="xs:anyURI?"/>

        <div class="ctor-pred">
            <xsl:choose>
                <xsl:when test="$predicate">
                    <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lapp:base()), map{ 'query': 'DESCRIBE &lt;' || $predicate || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>
                    <xsl:variable name="ontology-doc-uri" select="ac:document-uri($predicate)" as="xs:anyURI"/>
                    <!-- /ns DESCRIBE resolves predicates from the app's ontology import closure (typically user-defined classes);
                         ixsl:doc-fetched picks up predicates whose ontology doc the page already pulled into the SaxonJS pool (typically system vocabularies) -->
                    <xsl:variable name="resource" select="(
                        key('resources', $predicate, document($request-uri))[*][@rdf:about or @rdf:nodeID],
                        if (ixsl:doc-fetched($ontology-doc-uri)) then key('resources', $predicate, document($ontology-doc-uri))[*][@rdf:about or @rdf:nodeID] else ()
                    )[1]" as="element()?"/>

                    <xsl:choose>
                        <xsl:when test="exists($resource)">
                            <xsl:apply-templates select="$resource" mode="ldh:ComboboxChip">
                                <xsl:with-param name="class" select="'cb-chip-btn add-combobox add-property-combobox'"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- no metadata available for $predicate: synthesize a minimal rdf:Description so ldh:ComboboxChip matches and ac:label falls back to the URI tail -->
                            <xsl:variable name="synthetic" as="document-node()">
                                <xsl:document>
                                    <rdf:RDF>
                                        <rdf:Description rdf:about="{$predicate}">
                                            <rdf:type rdf:resource="&rdf;Property"/>
                                        </rdf:Description>
                                    </rdf:RDF>
                                </xsl:document>
                            </xsl:variable>
                            <xsl:apply-templates select="$synthetic/rdf:RDF/rdf:Description" mode="ldh:ComboboxChip">
                                <xsl:with-param name="class" select="'cb-chip-btn add-combobox add-property-combobox'"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="uuid" select="ac:uuid()" as="xs:string"/>

                    <xsl:call-template name="ldh:Combobox">
                        <xsl:with-param name="forClass" select="xs:anyURI('&rdf;Property')"/>
                        <xsl:with-param name="class" select="'property-combobox combobox'"/>
                        <xsl:with-param name="id" select="'input-' || $uuid"/>
                        <xsl:with-param name="list-class" select="'property-combobox combobox ac-cb-panel'"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="json:map/json:string[@key = 'object']" mode="ldh:ConstructorTripleFormControl" name="ldh:ConstructorObject">
        <xsl:param name="object-bnode-id" select="." as="xs:string"/>
        <xsl:param name="object-type" select="../../json:map[json:string[@key = 'subject'] = $object-bnode-id]/json:string[@key = 'object']" as="xs:anyURI?"/>
        <!-- rdf:langString is a LITERAL datatype that merely lives outside the XSD namespace, so the object
             kind cannot be read off the namespace alone - imports/values.xsl excludes it from its non-XSD
             resource lookup for the same reason. Read as a resource it lit the Resource toggle, left the
             range slot empty (nothing DESCRIBEs rdf:langString, and the resource branch has no fallback for
             a type it cannot resolve) and, because the save path keeps only rows whose slot carries a
             control, silently dropped the row: opening the SKOS Concept constructor and pressing Save
             deleted prefLabel, altLabel and definition from its template. -->
        <xsl:variable name="literal" select="starts-with($object-type, '&xsd;') or $object-type = '&rdf;langString'" as="xs:boolean"/>

        <div class="ctor-term" role="radiogroup">
            <button type="button" role="radio" data-kind="&rdfs;Resource">
                <xsl:attribute name="class" select="concat('object-kind', if (not($literal)) then ' is-on' else ())"/>
                <xsl:attribute name="aria-checked" select="if (not($literal)) then 'true' else 'false'"/>

                <xsl:apply-templates select="key('resources', 'resource', ldh:translations())" mode="ac:label"/>
            </button>
            <button type="button" role="radio" data-kind="&rdfs;Literal">
                <xsl:attribute name="class" select="concat('object-kind', if ($literal) then ' is-on' else ())"/>
                <xsl:attribute name="aria-checked" select="if ($literal) then 'true' else 'false'"/>

                <xsl:apply-templates select="key('resources', 'literal', ldh:translations())" mode="ac:label"/>
            </button>
        </div>

        <span class="ctor-range-slot">
            <xsl:choose>
                <xsl:when test="$literal">
                    <xsl:call-template name="ldh:ConstructorLiteralObject">
                        <xsl:with-param name="object-type" select="$object-type"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="ldh:ConstructorResourceObject">
                        <xsl:with-param name="object-type" select="$object-type"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </span>

        <button type="button" class="ctor-rm btn-remove-property" tabindex="-1">
            <xsl:attribute name="title">
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'remove-stmt', ldh:translations())" mode="ac:label"/>
                </xsl:value-of>
            </xsl:attribute>

            <span class="msi sm" aria-hidden="true">remove</span>
        </button>
    </xsl:template>
    
    <xsl:template name="ldh:ConstructorFieldset">
        <xsl:param name="constructor-uri" as="xs:anyURI"/>
        <xsl:param name="construct-xml" as="document-node()?"/>
        <!-- the document to PATCH on save. Stamped because the constructor URI does not identify it: a
             document describes resources it does not own, as an imported vocabulary's annotations do. -->
        <xsl:param name="graph" as="xs:anyURI?"/>

        <fieldset class="ldh-ctor-card" about="{$constructor-uri}">
            <xsl:if test="$graph">
                <xsl:attribute name="data-graph" select="$graph"/>
            </xsl:if>
            <div class="ldh-ctor-card-head">
                <span class="ttl">
                    <a href="{$constructor-uri}" title="{$constructor-uri}" target="_blank">
                        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lapp:base()), map{ 'query': 'DESCRIBE &lt;' || $constructor-uri || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>
                        <xsl:apply-templates select="key('resources', $constructor-uri, document($request-uri))" mode="ac:label"/>
                    </a>
                </span>
            </div>

            <div class="ldh-ctor-rows">
                <xsl:apply-templates select="$construct-xml/json:map/json:array[@key = 'template']/json:map" mode="ldh:ConstructorTripleForm">
                    <xsl:sort select="json:string[@key = 'predicate']"/>
                </xsl:apply-templates>
            </div>

            <button type="button" class="ldh-ctor-addprop create-action add-triple-template">
                <span class="msi sm" aria-hidden="true">add</span>
                <span>
                    <xsl:apply-templates select="key('resources', '&rdf;Property', document(ac:document-uri('&rdf;')))" mode="ac:label"/>
                </span>
            </button>
        </fieldset>
    </xsl:template>

    <xsl:template name="ldh:ConstructorLiteralObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>

        <xsl:apply-templates select="." mode="ac:SelectShell">
            <xsl:with-param name="select" as="item()*">
                <select name="ou" class="ctor-range">
                    <option value="&xsd;string">
                        <xsl:if test="$object-type = '&xsd;string'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
                            
                        <xsl:apply-templates select="key('resources', 'datatype-string', ldh:translations())" mode="ac:label"/>
                    </option>
                    <!-- a language-tagged literal: the constructor declares [ a rdf:langString ] and the form
                         control it drives renders a value input plus a language field, never a datatype -->
                    <option value="&rdf;langString">
                        <xsl:if test="$object-type = '&rdf;langString'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>

                        <xsl:apply-templates select="key('resources', 'datatype-langstring', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;boolean">
                        <xsl:if test="$object-type = '&xsd;boolean'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-boolean', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;date">
                        <xsl:if test="$object-type = '&xsd;date'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-date', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;dateTime">
                        <xsl:if test="$object-type = '&xsd;dateTime'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-datetime', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;integer">
                        <xsl:if test="$object-type = '&xsd;integer'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-integer', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;float">
                        <xsl:if test="$object-type = '&xsd;float'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-float', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;double">
                        <xsl:if test="$object-type = '&xsd;double'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-double', ldh:translations())" mode="ac:label"/>
                    </option>
                    <option value="&xsd;decimal">
                        <xsl:if test="$object-type = '&xsd;decimal'">
                            <xsl:attribute name="selected" select="'selected'"/>
                        </xsl:if>
        
                        <xsl:apply-templates select="key('resources', 'datatype-decimal', ldh:translations())" mode="ac:label"/>
                    </option>
                </select>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template name="ldh:ConstructorResourceObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="$object-type">
                <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lapp:base()), map{ 'query': 'DESCRIBE &lt;' || $object-type || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>

                <xsl:apply-templates select="key('resources', $object-type, document($request-uri))" mode="ldh:ComboboxChip">
                    <xsl:with-param name="class" select="'cb-chip-btn add-combobox add-class-combobox'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="uuid" select="ac:uuid()" as="xs:string"/>

                <xsl:call-template name="ldh:Combobox">
                    <xsl:with-param name="forClass" select="(xs:anyURI('&rdfs;Class'), xs:anyURI('&owl;Class'))"/> <!-- ontologies are served without inference, so owl:Class subjects do not carry the rdfs:Class type -->
                    <xsl:with-param name="class" select="'class-combobox combobox'"/>
                    <xsl:with-param name="id" select="'input-' || $uuid"/>
                    <xsl:with-param name="list-class" select="'class-combobox combobox ac-cb-panel'"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
    <!-- open modal form with constructor editing mode -->
    <xsl:template match="button[contains-token(@class, 'btn-edit-constructors')]" mode="ixsl:onclick">"
        <xsl:variable name="type" select="ixsl:get(., 'dataset.resourceType')" as="xs:anyURI"/>

        <xsl:variable name="form" select="ancestor::form[1]" as="element()?"/>

        <xsl:for-each select="id('tab-content', ixsl:page())/div[contains-token(@class, 'ldh-pane')][contains-token(@class, 'is-active')]/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]">
            <xsl:call-template name="ldh:LoadConstructors">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="form" select="$form"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <!-- classes and properties are looked up in the <ns> endpoint -->
    <xsl:template match="input[contains-token(@class, 'class-combobox')] | input[contains-token(@class, 'property-combobox')]" mode="ixsl:onkeyup" priority="1">
        <xsl:next-match>
            <xsl:with-param name="endpoint" select="resolve-uri('ns', lapp:base())"/>
            <xsl:with-param name="select-string" select="$select-labelled-string"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[contains-token(@class, 'ac-cb-panel')][contains-token(@class, 'class-combobox')]/li" mode="ixsl:onmousedown" priority="2">
        <xsl:next-match>
            <xsl:with-param name="chip-class" select="'cb-chip-btn add-combobox add-class-combobox'"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[contains-token(@class, 'ac-cb-panel')][contains-token(@class, 'property-combobox')]/li" mode="ixsl:onmousedown" priority="2">
        <xsl:next-match>
            <xsl:with-param name="chip-class" select="'cb-chip-btn add-combobox add-property-combobox'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- special case for class lookups -->
    <xsl:template match="button[contains-token(@class, 'add-class-combobox')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="combobox-class" select="'class-combobox combobox'"/>
            <xsl:with-param name="combobox-list-class" select="'class-combobox combobox ac-cb-panel'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>

    <!-- special case for property lookups -->
    <xsl:template match="button[contains-token(@class, 'add-property-combobox')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="combobox-class" select="'property-combobox combobox'"/>
            <xsl:with-param name="combobox-list-class" select="'property-combobox combobox ac-cb-panel'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>

    <!-- toggles object type control depending on the object kind (segmented radio buttons) -->
    <xsl:template match="button[contains-token(@class, 'object-kind')]" mode="ixsl:onclick">
        <xsl:variable name="object-kind" select="xs:anyURI(@data-kind)" as="xs:anyURI"/>
        <xsl:variable name="button" select="." as="element()"/>

        <xsl:for-each select="../button[contains-token(@class, 'object-kind')]">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-on', . is $button)"/>
            <ixsl:set-attribute name="aria-checked" select="if (. is $button) then 'true' else 'false'" object="."/>
        </xsl:for-each>

        <xsl:for-each select="ancestor::div[contains-token(@class, 'ldh-ctor-row')][1]/span[contains-token(@class, 'ctor-range-slot')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:if test="$object-kind = '&rdfs;Resource'">
                    <xsl:call-template name="ldh:ConstructorResourceObject"/>
                </xsl:if>
                <xsl:if test="$object-kind = '&rdfs;Literal'">
                    <xsl:call-template name="ldh:ConstructorLiteralObject"/>
                </xsl:if>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- appends new triple template to the card's row list -->
    <xsl:template match="button[contains-token(@class, 'create-action')][contains-token(@class, 'add-triple-template')]" mode="ixsl:onclick">
        <xsl:variable name="row" as="node()*">
            <div class="ldh-ctor-row constructor-triple">
                <xsl:call-template name="ldh:ConstructorPredicate">
                    <xsl:with-param name="predicate" select="()"/>
                </xsl:call-template>

                <xsl:call-template name="ldh:ConstructorObject">
                    <xsl:with-param name="object-type" select="()"/>
                </xsl:call-template>
            </div>
        </xsl:variable>

        <xsl:for-each select="preceding-sibling::div[contains-token(@class, 'ldh-ctor-rows')][1]">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select="$row"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- appends new constructor -->
    <xsl:template match="div[contains-token(@class, 'ac-modal-body')]//button[contains-token(@class, 'create-action')][contains-token(@class, 'add-constructor')]" mode="ixsl:onclick">
        <xsl:variable name="button-div" select="." as="element()"/> <!-- the addctor strip button itself; new cards insert before it -->
        <xsl:variable name="type" select="ancestor::form/@about" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:variable name="query-string" select="replace($type-graph-query, '$Type', '&lt;' || $type || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="admin-base-uri" select="xs:anyURI(replace(lapp:base(), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('sparql', $admin-base-uri), map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                <xsl:call-template name="ldh:TypeGraphLoad">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="button-div" select="$button-div"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- save constructor form onclick. Validate it before update updating constructors -->
    <xsl:template match="form[contains-token(@class, 'constructor-template')]//div[contains-token(@class, 'mhint')]/button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="form" select="ancestor::form" as="element()"/>
        <xsl:variable name="rows" select="$form/descendant::div[contains-token(@class, 'ldh-ctor-row')]" as="element()*"/>

        <xsl:choose>
            <!-- input values missing, throw an error -->
            <xsl:when test="exists($rows/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:for-each select="$rows[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]">
                    <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'error', true())"/>
                </xsl:for-each>
            </xsl:when>
            <!-- all required values present, proceed to update the constructors -->
            <xsl:otherwise>
                <xsl:sequence select="ldh:busy-cursor()"/>

                <xsl:for-each select="$form//fieldset">
                    <xsl:variable name="container" select="." as="element()"/>
                    <xsl:variable name="constructor-uri" select="@about" as="xs:anyURI"/>
                    <xsl:variable name="construct-xml" as="document-node()">
                        <!-- not all controls might have value, filter to those that have -->
                        <xsl:iterate select="./div[contains-token(@class, 'ldh-ctor-rows')]/div[contains-token(@class, 'ldh-ctor-row')][./div[contains-token(@class, 'ctor-pred')]//input[@name = 'ou']/@value][span[contains-token(@class, 'ctor-range-slot')]//input[@name = 'ou']/@value or span[contains-token(@class, 'ctor-range-slot')]//select[@name = 'ou']]">
                            <xsl:param name="construct-xml" as="document-node()">
                                <xsl:document>
                                    <json:map>
                                        <json:string key="queryType">CONSTRUCT</json:string>
                                        <json:array key="template"/>
                                        <json:array key="where"/>
                                        <json:string key="type">query</json:string>
                                        <json:map key="prefixes"/>
                                    </json:map>
                                </xsl:document>
                            </xsl:param>

                            <xsl:on-completion>
                                <xsl:sequence select="$construct-xml"/>
                            </xsl:on-completion>

                            <xsl:next-iteration>
                                <xsl:with-param name="construct-xml">
                                    <xsl:apply-templates select="$construct-xml" mode="ldh:add-constructor-triple">
                                        <xsl:with-param name="predicate" select="./div[contains-token(@class, 'ctor-pred')]//input[@name = 'ou']/@value/xs:anyURI(.)" tunnel="yes"/>
                                        <xsl:with-param name="object-type" select="(span[contains-token(@class, 'ctor-range-slot')]//input[@name = 'ou']/@value/xs:anyURI(.), xs:anyURI(span[contains-token(@class, 'ctor-range-slot')]//select[@name = 'ou']/ixsl:get(., 'value')))[1]" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:with-param>
                            </xsl:next-iteration>
                        </xsl:iterate>
                    </xsl:variable>
                    <xsl:variable name="construct-json-string" select="xml-to-json($construct-xml)" as="xs:string"/>
                    <xsl:variable name="construct-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $construct-json-string ])"/>
                    <xsl:variable name="construct-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromQuery', [ $construct-json ]), 'toString', [])" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($constructor-update-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$text', '&quot;&quot;&quot;' || $construct-string || '&quot;&quot;&quot;', 'q')" as="xs:string"/>
                    <!-- the graph the constructor was found in, stamped when the editor was built. The URI is
                         only a fallback: stripping its fragment is right when the constructor is a fragment of
                         its own document, and wrong whenever a document describes a resource it does not own. -->
                    <xsl:variable name="document-uri" select="($container/@data-graph/xs:anyURI(.), ac:document-uri($constructor-uri))[1]" as="xs:anyURI"/>
                    <xsl:variable name="request-uri" select="ldh:href($document-uri, map{})" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="ldh:ConstructorUpdate">
                                <xsl:with-param name="container" select="$container"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <xsl:template name="ldh:ConstructorUpdate">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = (200, 204)">
                <xsl:for-each select="$container">
                    <xsl:call-template name="ldh:CloseModal"/>
                </xsl:for-each>

                <!-- One clear, of the namespace ontology. It used to be preceded by a clear naming the document the
                     PATCH went to, which /clear takes as an ontology to reassemble - and a package's copy of its
                     ontology is a dh:Item ABOUT the ontology, not an owl:Ontology, so that reload answered 500 and
                     this one never ran. Nothing is lost with it: a clear discards every cached graph and closure
                     whatever URI it is given, so the namespace reload below re-reads the edited document as well.
                     TO-DO: only clear after *all* constructors are saved: https://saxonica.plan.io/issues/5596 -->
                <xsl:call-template name="ldh:ClearNamespace"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:render-failure(($container//div[contains-token(@class, 'ac-modal-body')])[1], 'constructor-not-updated', ac:http-error-key(?status), ldh:response-detail(.))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ldh:TypeGraphLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="type" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:param name="button-div" as="element()"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml' and exists(?body//srx:result)">
                <xsl:for-each select="?body">
                    <xsl:for-each select="//srx:result">
                        <xsl:variable name="graph" select="srx:binding[@name = 'graph']/srx:uri" as="xs:anyURI"/>
                        <xsl:variable name="uuid" select="ac:uuid()" as="xs:string"/>
                        <!-- minted as a fragment of the graph, so this one document derivation is sound -->
                        <xsl:variable name="constructor-uri" select="xs:anyURI($graph || '#id' || $uuid)" as="xs:anyURI"/>
                        <xsl:variable name="update-string" select="replace($constructor-insert-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$Type', '&lt;' || $type || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ldh:href($graph, map{})" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                                <xsl:call-template name="ldh:ConstructorAppend">
                                    <xsl:with-param name="button-div" select="$button-div"/>
                                    <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                                    <xsl:with-param name="graph" select="$graph"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <!-- the request succeeded and no graph declares the class. It reaches the form through an imported
                 document this application cannot write to, so there is nowhere to put a constructor. Reported
                 rather than passed over, which is what made the button look dead. -->
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:sequence select="ldh:render-failure($button-div, 'ontology-graphs-not-loaded', 'ontology-graph-not-found', string($type))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:render-failure($button-div, 'ontology-graphs-not-loaded', ac:http-error-key(?status), ldh:response-detail(.))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ldh:ConstructorAppend">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="button-div" as="element()"/>
        <xsl:param name="constructor-uri" as="xs:anyURI"/>
        <!-- the graph the constructor was just written into, carried through so the new fieldset is stamped
             like the ones the editor rendered and its first save targets the same document -->
        <xsl:param name="graph" as="xs:anyURI?"/>

        <xsl:choose>
            <!-- a PATCH that writes returns 204, as ldh:ConstructorUpdate already allows for. Testing 200 alone
                 reported a successful write as a failure and skipped the fieldset, which is what made the
                 button look inert even once it had somewhere to write. -->
            <xsl:when test="?status = (200, 204)">
                <!-- insert the fieldset above the "Add constructor" button, which stays at the bottom of the form -->
                <xsl:for-each select="$button-div">
                    <xsl:result-document href="?." method="ixsl:insert-before">
                        <xsl:call-template name="ldh:ConstructorFieldset">
                            <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                            <xsl:with-param name="graph" select="$graph"/>
                        </xsl:call-template>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:render-failure($button-div, 'constructor-not-appended', ac:http-error-key(?status), ldh:response-detail(.))"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template name="ldh:ClearNamespace">
        <xsl:param name="ontology-uri" select="resolve-uri('ns#', lapp:base())" as="xs:anyURI"/>
        <xsl:variable name="form-data" select="ixsl:new('URLSearchParams', [ ixsl:new('FormData', []) ])"/>
        <xsl:sequence select="ixsl:call($form-data, 'append', [ 'uri', $ontology-uri ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="admin-base-uri" select="xs:anyURI(replace(lapp:base(), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:variable name="clear-uri" select="resolve-uri('clear', $admin-base-uri)" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($clear-uri)" as="xs:anyURI"/>
        <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/x-www-form-urlencoded', 'body': $form-data, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <!-- the namespace ontology is fresh again - reconcile the open editing forms with the updated constructors -->
            <xsl:call-template name="ldh:SyncFormsWithConstructor"/>
        </ixsl:schedule-action>
    </xsl:template>

</xsl:stylesheet>