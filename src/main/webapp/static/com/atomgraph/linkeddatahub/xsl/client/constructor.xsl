<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
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
xmlns:lds="&lds;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:spin="&spin;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- Which graph holds each constructor. A resource's URI does not tell you which document describes it -
         the add path already asks this question about the class, and the save path has to ask it about the
         constructor rather than stripping the fragment off its URI. Runs against the admin endpoint, since
         that is where the named graphs are; /ns serves the merged closure and has none. -->
    <xsl:variable name="constructor-graph-query" as="xs:string">
        <![CDATA[
            PREFIX sp: <http://spinrdf.org/sp#>

            PREFIX dct: <http://purl.org/dc/terms/>

            PREFIX spin: <http://spinrdf.org/spin#>

            SELECT DISTINCT  $constructor ?graph ?title ?owner
            WHERE
              { GRAPH ?graph
                  { $constructor  sp:text  ?text }
                OPTIONAL
                  { GRAPH ?graph
                      { ?graph  dct:title  ?title }
                  }
                OPTIONAL
                  { GRAPH ?ownerGraph
                      { ?owner  spin:constructor  $constructor }
                  }
              }
        ]]>
    </xsl:variable>
    <!-- Which documents hold a class's constructors. The gate needs the documents rather than the
         constructors, because a document is what a PATCH is authorized against. Runs against the admin
         endpoint for the same reason $constructor-graph-query does: /ns serves the merged closure and has
         no named graphs. An agent without admin access cannot run it at all, which is what makes the gate
         built on it fail closed. -->
    <xsl:variable name="type-constructor-graph-query" as="xs:string">
        <![CDATA[
            PREFIX spin: <http://spinrdf.org/spin#>
            PREFIX sp: <http://spinrdf.org/sp#>

            PREFIX foaf: <http://xmlns.com/foaf/0.1/>

            SELECT DISTINCT  ?graph
            WHERE
              {   { GRAPH ?typeGraph
                      { $Type  spin:constructor  ?constructor }
                    GRAPH ?graph
                      { ?constructor  sp:text  ?text }
                  }
                UNION
                  { GRAPH ?graph
                      { ?graph  foaf:primaryTopic  $Ontology }
                  }
              }
        ]]>
    </xsl:variable>
    <!-- The document describing the application's own ontology, which is where a constructor goes when the
         class has none the agent can write. Resolved rather than derived: lds:ontology advertises the
         ontology's URI (.../ns#), and the document about it is a dh:Item elsewhere entirely. Dataspace-safe,
         since each dataspace's ontology resolves to its own document. -->
    <xsl:variable name="ontology-document-query" as="xs:string">
        <![CDATA[
            PREFIX foaf: <http://xmlns.com/foaf/0.1/>
            PREFIX dct: <http://purl.org/dc/terms/>

            SELECT DISTINCT  ?graph ?title
            WHERE
              { GRAPH ?graph
                  { ?graph  foaf:primaryTopic  $Ontology }
                OPTIONAL
                  { GRAPH ?graph
                      { ?graph  dct:title  ?title }
                  }
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
    <!-- Creating a constructor and writing its template are one update: the editor has nothing to create
         until a property exists, so there is no empty constructor to leave behind if the author closes the
         dialog. rdf:type and rdfs:isDefinedBy make it a resource other tools can find, which the bare
         spin:constructor link it used to write was not - that is why a new one's heading was a raw id. -->
    <xsl:variable name="constructor-create-string" as="xs:string">
        <![CDATA[
            PREFIX sp: <http://spinrdf.org/sp#>
            PREFIX spin: <http://spinrdf.org/spin#>
            PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX ldh: <https://w3id.org/atomgraph/linkeddatahub#>

            INSERT
            {
                $Type spin:constructor $this .
                $this a ldh:Constructor .
                $this rdfs:isDefinedBy $Ontology .
                $this sp:text $text .
            }
            WHERE
            {
            }
        ]]>
    </xsl:variable>
    <!-- A constructor whose last property was removed is deleted, not written as an empty CONSTRUCT. An
         empty template contributes no fields, so leaving one behind is a resource that means nothing. -->
    <xsl:variable name="constructor-delete-string" as="xs:string">
        <![CDATA[
            PREFIX spin: <http://spinrdf.org/spin#>

            DELETE
            {
                $Type spin:constructor $this .
                $this ?p ?o .
            }
            WHERE
            {
                OPTIONAL
                {
                    $this ?p ?o .
                }
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
            ixsl:then(ldh:load-ontology-document#1) =>
            ixsl:then(ldh:http-request-threaded(?, 'ontology-document-request', 'ontology-document-response')) =>
            ixsl:then(ldh:handle-response(?, 'ontology-document-response')) =>
            ixsl:then(ldh:set-ontology-document#1) =>
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
        <xsl:variable name="admin-base-uri" select="xs:anyURI(replace(lds:base(), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('sparql', $admin-base-uri), map{ 'query': $query-string })" as="xs:anyURI"/>
        <!-- not read from cache, for the reason ldh:graph-query-request records: which document holds a
             constructor decides where Save writes -->
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($results-uri, map{}), 'headers': map{ 'Accept': 'application/sparql-results+xml', 'Cache-Control': 'no-cache, no-store, must-revalidate' } }" as="map(*)"/>
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

    <!-- Where a class's first constructor goes. Same shape as the constructor-graph pair above, and just as
         non-fatal: without it the dialog still renders every existing constructor, it simply cannot offer a
         destination for a class that has none. -->
    <xsl:function name="ldh:load-ontology-document" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="map:merge(($context, map{ 'ontology-document-request': ldh:graph-query-request($ontology-document-query, $context('type')) }))"/>
    </xsl:function>

    <xsl:function name="ldh:set-ontology-document" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('ontology-document-response')" as="map(*)?"/>

        <xsl:choose>
            <xsl:when test="exists($response) and $response?status = 200 and $response?media-type = 'application/sparql-results+xml'">
                <xsl:sequence select="map:merge(($context, map{ 'ontology-document': $response?body }))"/>
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
                <!-- the application's own ontology document: where this class's first constructor goes -->
                <xsl:variable name="ontology-document" select="if (map:contains($context, 'ontology-document')) then $context('ontology-document') else ()" as="document-node()?"/>
                <xsl:variable name="ontology-doc-uri" select="($ontology-document//srx:result/srx:binding[@name = 'graph']/srx:uri/xs:anyURI(.))[1]" as="xs:anyURI?"/>
                <xsl:variable name="ontology-doc-title" select="($ontology-document//srx:result/srx:binding[@name = 'title']/srx:literal)[1]" as="xs:string?"/>
                <xsl:variable name="constructor-graph-uris" select="distinct-values($constructor-graphs//srx:result/srx:binding[@name = 'graph']/srx:uri/xs:anyURI(.))" as="xs:anyURI*"/>
                <!-- constructors another class also uses: rendered, never written -->
                <xsl:variable name="shared-constructors" select="if (map:contains($context, 'shared-constructors')) then $context('shared-constructors') else ()" as="xs:anyURI*"/>

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
                                                <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': 'DESCRIBE &lt;' || $type || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>

                                                <xsl:apply-templates select="key('resources', $type, document(ac:document-uri($request-uri)))" mode="ac:label"/>
                                            </h2>
                                        </div>
                                        <span class="ac-modal-x">
                                            <button type="button" class="ac-iconbtn sz-sm in-neutral ap-ghost" aria-label="{ac:label(key('resources', 'close', ldh:translations()))}"><span class="msi sm">close</span></button>
                                        </span>
                                    </div>
                                    <div class="ac-modal-body is-flush">
                                        <div class="ldh-ctor-body">
                                            <!-- One fieldset per CONSTRUCTOR. Grouping by document was tried and
                                                 reverted: the document decides whether you MAY write, which the ACL gate
                                                 answers on its own, while the constructor's attachment decides whether
                                                 writing is SAFE - and that is the question the author cannot otherwise
                                                 see. A constructor reached through rdfs:subClassOf*, or attached to
                                                 several classes as ldh:TitleConstructor is to eight, renders the same
                                                 rows here as one of this class's own. -->
                                            <xsl:for-each select="$constructors//srx:result">
                                                <xsl:variable name="constructor-uri" select="srx:binding[@name = 'constructor']/srx:uri" as="xs:anyURI"/>
                                                <xsl:variable name="construct-string" select="srx:binding[@name = 'construct']/srx:literal" as="xs:string"/>
                                                <xsl:variable name="construct-json" as="item()">
                                                    <xsl:variable name="construct-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromString', [ $construct-string ])"/>
                                                    <xsl:sequence select="ixsl:call($construct-builder, 'build', [])"/>
                                                </xsl:variable>
                                                <xsl:variable name="construct-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $construct-json ])" as="xs:string"/>
                                                <xsl:variable name="construct-xml" select="json-to-xml($construct-json-string)" as="document-node()"/>
                                                <xsl:variable name="graph-results" select="$constructor-graphs//srx:result[srx:binding[@name = 'constructor']/srx:uri = $constructor-uri]" as="element()*"/>

                                                <xsl:call-template name="ldh:ConstructorFieldset">
                                                    <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                                                    <xsl:with-param name="construct-xml" select="$construct-xml"/>
                                                    <xsl:with-param name="graph" select="($graph-results/srx:binding[@name = 'graph']/srx:uri/xs:anyURI(.))[1]"/>
                                                    <xsl:with-param name="title" select="($graph-results/srx:binding[@name = 'title']/srx:literal)[1]"/>
                                                    <xsl:with-param name="owners" select="distinct-values($graph-results/srx:binding[@name = 'owner']/srx:uri/xs:anyURI(.))"/>
                                                    <xsl:with-param name="type" select="$type"/>
                                                </xsl:call-template>
                                            </xsl:for-each>

                                            <!-- A class whose constructors all belong to someone else still needs somewhere to
                                                 put its own. One empty fieldset on the application's ontology provides it, with
                                                 nothing written until its first property is saved - so closing the dialog leaves
                                                 no trace, which is what the old "+ Constructor" could not manage. -->
                                            <xsl:if test="exists($ontology-doc-uri) and not($ontology-doc-uri = $constructor-graph-uris)">
                                                <xsl:call-template name="ldh:ConstructorFieldset">
                                                    <xsl:with-param name="constructor-uri" select="xs:anyURI($ontology-doc-uri || '#id' || ac:uuid())"/>
                                                    <xsl:with-param name="construct-xml" select="()"/>
                                                    <xsl:with-param name="graph" select="$ontology-doc-uri"/>
                                                    <xsl:with-param name="title" select="$ontology-doc-title"/>
                                                    <xsl:with-param name="owners" select="$type"/>
                                                    <xsl:with-param name="type" select="$type"/>
                                                    <xsl:with-param name="new" select="true()"/>
                                                </xsl:call-template>
                                            </xsl:if>
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

        <!-- the result-document above has already applied - Saxon-JS 3 updates the page immediately - so
             the dialog is in the DOM and its fieldsets are there to gate -->
        <xsl:call-template name="ldh:GateConstructorDialog"/>

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
                    <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': 'DESCRIBE &lt;' || $predicate || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>
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
             range slot empty (nothing DESCRIBEs rdf:langString, and the resource branch had no fallback for
             a type it cannot resolve) and, because the save path keeps only rows whose slot carries a
             control, silently dropped the row: opening the SKOS Concept constructor and pressing Save
             deleted prefLabel, altLabel and definition from its template. The slot no longer empties -
             ldh:ConstructorResourceObject synthesizes a chip for a type /ns cannot resolve - so such a row
             would now be saved with a resource range instead of vanishing, which is why the test stays. -->
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
    
    <!-- Which document holds a constructor, and its title: both answered by the lookup the chain already ran. -->
    <xsl:function name="ldh:constructor-graph" as="xs:anyURI?">
        <xsl:param name="graphs" as="document-node()?"/>
        <xsl:param name="constructor" as="xs:anyURI"/>

        <xsl:sequence select="($graphs//srx:result[srx:binding[@name = 'constructor']/srx:uri = $constructor]/srx:binding[@name = 'graph']/srx:uri/xs:anyURI(.))[1]"/>
    </xsl:function>

    <xsl:function name="ldh:constructor-graph-title" as="xs:string?">
        <xsl:param name="graphs" as="document-node()?"/>
        <xsl:param name="constructor" as="xs:anyURI"/>

        <xsl:sequence select="($graphs//srx:result[srx:binding[@name = 'constructor']/srx:uri = $constructor]/srx:binding[@name = 'title']/srx:literal)[1]"/>
    </xsl:function>

    <!-- the rows a constructor would be rebuilt from: a predicate, and either an object URI or a datatype -->
    <xsl:function name="ldh:constructor-valid-rows" as="element()*">
        <xsl:param name="container" as="element()"/>

        <xsl:sequence select="$container/div[contains-token(@class, 'ldh-ctor-rows')]/div[contains-token(@class, 'ldh-ctor-row')][./div[contains-token(@class, 'ctor-pred')]//input[@name = 'ou']/@value][span[contains-token(@class, 'ctor-range-slot')]//input[@name = 'ou']/@value or span[contains-token(@class, 'ctor-range-slot')]//select[@name = 'ou']]"/>
    </xsl:function>

    <xsl:template name="ldh:ConstructorFieldset">
        <xsl:param name="constructor-uri" as="xs:anyURI"/>
        <xsl:param name="construct-xml" as="document-node()?"/>
        <!-- the document to PATCH on save. Stamped because the constructor URI does not identify it: the
             taxonomy package's constructors are fragments of a raw.githubusercontent.com file and live in
             the application's copy of that ontology, so deriving the document would PATCH GitHub. -->
        <xsl:param name="graph" as="xs:anyURI?"/>
        <!-- that document's title, fetched with the graph so the heading needs no second lookup -->
        <xsl:param name="title" as="xs:string?"/>
        <!-- every class this constructor is attached to -->
        <xsl:param name="owners" select="()" as="xs:anyURI*"/>
        <xsl:param name="type" as="xs:anyURI"/>
        <!-- nothing is stored for this constructor yet: the save path creates it rather than rewriting it -->
        <xsl:param name="new" select="false()" as="xs:boolean"/>

        <!-- Editable only when this class is the only one that has it. A constructor inherited through
             rdfs:subClassOf*, or attached to several classes directly, renders the same rows - and rewriting
             it from here would silently change every other class's form. skos:OrderedCollection inherits
             five from skos:Collection; ldh:TitleConstructor is attached to eight classes at once. -->
        <xsl:variable name="exclusive" select="empty($owners[not(. = $type)])" as="xs:boolean"/>

        <fieldset class="ldh-ctor-card" about="{$constructor-uri}">
            <xsl:if test="$graph">
                <xsl:attribute name="data-graph" select="$graph"/>
            </xsl:if>
            <xsl:if test="$new">
                <xsl:attribute name="data-new" select="'true'"/>
            </xsl:if>
            <xsl:if test="not($exclusive)">
                <xsl:attribute name="disabled" select="'disabled'"/>
                <xsl:attribute name="class" select="'ldh-ctor-card is-readonly'"/>
            </xsl:if>

            <div class="ldh-ctor-card-head">
                <span class="ttl">
                    <a href="{($graph, $constructor-uri)[1]}" title="{$constructor-uri}" target="_blank">
                        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': 'DESCRIBE &lt;' || $constructor-uri || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>
                        <xsl:variable name="labelled" select="key('resources', $constructor-uri, document($request-uri))" as="element()*"/>

                        <xsl:choose>
                            <xsl:when test="exists($labelled)">
                                <xsl:apply-templates select="$labelled" mode="ac:label"/>
                            </xsl:when>
                            <!-- nothing describes it - one this editor made, which carries no label - so the
                                 document it lives in is the most useful thing to name -->
                            <xsl:otherwise>
                                <xsl:value-of select="($title, $graph, $constructor-uri)[1]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                </span>

                <!-- says WHY it is inert, rather than leaving the agent to guess -->
                <xsl:if test="not($exclusive)">
                    <span class="ctor-owners">
                        <xsl:apply-templates select="key('resources', 'constructor-shared', ldh:translations())" mode="ac:label"/>
                        <xsl:text> </xsl:text>
                        <xsl:for-each select="$owners[not(. = $type)]">
                            <xsl:if test="position() gt 1">, </xsl:if>
                            <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': 'DESCRIBE &lt;' || . || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>
                            <a href="{.}" title="{.}" target="_blank">
                                <xsl:apply-templates select="key('resources', ., document($request-uri))" mode="ac:label"/>
                            </a>
                        </xsl:for-each>
                    </span>
                </xsl:if>
            </div>

            <div class="ldh-ctor-rows">
                <xsl:apply-templates select="$construct-xml/json:map/json:array[@key = 'template']/json:map" mode="ldh:ConstructorTripleForm">
                    <xsl:sort select="json:string[@key = 'predicate']"/>
                </xsl:apply-templates>
            </div>

            <xsl:if test="$exclusive">
                <button type="button" class="ldh-ctor-addprop create-action add-triple-template">
                    <span class="msi sm" aria-hidden="true">add</span>
                    <span>
                        <xsl:apply-templates select="key('resources', '&rdf;Property', document(ac:document-uri('&rdf;')))" mode="ac:label"/>
                    </span>
                </button>
            </xsl:if>
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
    
    <!-- The range slot is the class combobox in its committed state: a chip holding the class, its edit
         button reopening the lookup. A row whose range is undeclared gets rdfs:Resource rather than an empty
         slot - the idiom the platform's own constructors write for an object that is any resource
         (owl:imports on owl:Ontology, sd:endpoint, ac:mode, foaf:primaryTopic), and the one client/form.xsl
         reads as "no type filter" when it is the only forClass. Defaulting here rather than in the save path
         keeps a value in the slot, so nothing downstream needs a notion of a range left open:
         ldh:constructor-valid-rows still asks for a control and still finds one. -->
    <xsl:template name="ldh:ConstructorResourceObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>
        <!-- a variable rather than a param default: both callers pass a value that can be empty - the row
             renderer passes the parsed object type, the object-kind toggle passes nothing at all - and a
             param default only covers the second -->
        <xsl:variable name="range" select="($object-type, xs:anyURI('&rdfs;Resource'))[1]" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': 'DESCRIBE &lt;' || $range || '&gt;', 'accept': 'application/rdf+xml' }), map{})" as="xs:anyURI"/>
        <!-- ontologies are served without inference, so owl:Class subjects do not carry the rdfs:Class type.
             The chip carries the scope its lookup was made with, which is what the edit button reopens with -
             ldh:ComboboxChip puts it on @data-for-class. -->
        <xsl:variable name="forClass" select="(xs:anyURI('&rdfs;Class'), xs:anyURI('&owl;Class'))" as="xs:anyURI*"/>
        <xsl:variable name="resource" select="key('resources', $range, document($request-uri))[*][@rdf:about or @rdf:nodeID]" as="element()?"/>

        <xsl:choose>
            <xsl:when test="exists($resource)">
                <xsl:apply-templates select="$resource" mode="ldh:ComboboxChip">
                    <xsl:with-param name="class" select="'cb-chip-btn add-combobox add-class-combobox'"/>
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!-- nothing in /ns describes $range - rdfs:Resource never does, nor does a class from a
                     vocabulary the app does not import - so synthesize the node the chip renders from, the
                     way the predicate slot does. ldh:class-label() names it: the localized word for
                     rdfs:Resource, so the chip reads like the Resource toggle beside it, the URI tail
                     otherwise. Without it the slot rendered empty and the save path dropped the row. -->
                <xsl:variable name="synthetic" as="document-node()">
                    <xsl:document>
                        <rdf:RDF>
                            <rdf:Description rdf:about="{$range}">
                                <rdf:type rdf:resource="&rdfs;Class"/>
                                <rdfs:label>
                                    <xsl:value-of select="ldh:class-label($range)"/>
                                </rdfs:label>
                            </rdf:Description>
                        </rdf:RDF>
                    </xsl:document>
                </xsl:variable>

                <xsl:apply-templates select="$synthetic/rdf:RDF/rdf:Description" mode="ldh:ComboboxChip">
                    <xsl:with-param name="class" select="'cb-chip-btn add-combobox add-class-combobox'"/>
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- GATES -->

    <!-- Every constructor affordance is gated by the authorization of the request IT issues, at the
         granularity requests are issued: the save loop sends one PATCH per fieldset to that fieldset's own
         @data-graph, so a dialog can write several documents and the fieldset is the unit. The three
         affordances therefore ask about three different documents - the button about any of the class's
         constructor graphs, a fieldset about its own, and the create button about the graph holding the
         CLASS, which is where a new constructor is inserted.

         None of it is enforcement. The PATCH is authorized again server-side, so a gate stale by the time
         Save is pressed degrades to an error to report rather than a hole. -->

    <!-- A gate that cannot answer leaves its affordance closed, which is the safe reading of an unknown
         authorization. For an agent without admin access the graph lookup 403s - the expected path, not a
         failure worth reporting: the affordance simply never appears. -->
    <xsl:function name="ldh:gate-failure" ixsl:updating="yes">
        <xsl:param name="error" as="map(*)"/>
    </xsl:function>

    <!-- The affordance is emitted hidden by ldh:ConstructorActions, which cannot evaluate the condition
         itself (see there). Overriding rather than inlining keeps resource.xsl free of ixsl, which the
         server-side transform shares. -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ldh:ConstructorActions">
        <xsl:param name="constructors" as="document-node()?"/>
        <xsl:param name="type-metadata" as="document-node()?"/>

        <xsl:next-match>
            <xsl:with-param name="constructors" select="$constructors"/>
            <xsl:with-param name="type-metadata" select="$type-metadata"/>
        </xsl:next-match>

        <!-- Not inline, and not for the reason the dialog's gate is: updates apply immediately, but this
             template runs INSIDE the enclosing xsl:result-document that is still building the form, so the
             buttons next-match just emitted are not in the page yet. A resolved promise is the smallest
             correct wait - its continuation runs once the stack unwinds, after that result-document has
             applied - where a timer would be an arbitrary guess at the same thing. -->
        <ixsl:promise select="ixsl:resolve(()) => ixsl:then(ldh:gate-constructor-actions#1)"
            on-failure="ldh:gate-failure#1"/>
    </xsl:template>

    <!-- One promise per affordance, so a class whose lookup fails gates only itself, and reveals need no
         coordination: the first writable document reveals and a second is a no-op. -->
    <xsl:function name="ldh:gate-constructor-actions" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="item()?"/>

        <xsl:for-each select="ixsl:page()//button[contains-token(@class, 'btn-edit-constructors')][not(@data-gated)]">
            <xsl:variable name="button" select="." as="element()"/>
            <xsl:variable name="type" select="xs:anyURI(@data-resource-type)" as="xs:anyURI"/>

            <ixsl:set-attribute name="data-gated" select="'true'"/>

            <ixsl:promise select="ixsl:resolve(map{ 'button': $button, 'type': $type }) =>
                ixsl:then(ldh:load-type-constructor-graphs#1) =>
                ixsl:then(ldh:http-request-threaded(?, 'type-constructor-graphs-request', 'type-constructor-graphs-response')) =>
                ixsl:then(ldh:handle-response(?, 'type-constructor-graphs-response')) =>
                ixsl:then(ldh:gate-constructor-action#1)"
                on-failure="ldh:gate-failure#1"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="ldh:load-type-constructor-graphs" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="map:merge(($context, map{ 'type-constructor-graphs-request': ldh:graph-query-request($type-constructor-graph-query, $context('type')) }))"/>
    </xsl:function>

    <!-- Shared by the admin-side lookups: same endpoint, same $Type and $Ontology substitution, same result
         media type - and the same refusal to read a cached answer. These decide whether an affordance is
         offered and whether a constructor may be rewritten, and a SELECT over /sparql has no invalidation
         path: only the ontology CONSTRUCTs OntologyRepository stamps carry a Surrogate-Key, so a PATCH
         invalidates the document it wrote and nothing that queried it. Measured while testing the
         shared-constructor guard: a dialog opened before a second class was attached went on answering
         "not shared" afterwards, and the guard never fired. Same header ldh:ViewResults uses to re-query a
         view with fresh data, for the same reason. -->
    <xsl:function name="ldh:graph-query-request" as="map(*)">
        <xsl:param name="query" as="xs:string"/>
        <xsl:param name="type" as="xs:anyURI"/>

        <xsl:variable name="query-string" select="replace($query, '$Type', '&lt;' || $type || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="query-string" select="replace($query-string, '$Ontology', '&lt;' || resolve-uri('ns#', lds:base()) || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="admin-base-uri" select="xs:anyURI(replace(lds:base(), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('sparql', $admin-base-uri), map{ 'query': $query-string })" as="xs:anyURI"/>

        <xsl:sequence select="map{ 'method': 'GET', 'href': ldh:href($results-uri, map{}), 'headers': map{ 'Accept': 'application/sparql-results+xml', 'Cache-Control': 'no-cache, no-store, must-revalidate' } }"/>
    </xsl:function>

    <!-- One HEAD per document the class's constructors live in. -->
    <xsl:function name="ldh:gate-constructor-action" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="button" select="$context('button')" as="element()"/>

        <xsl:for-each select="ldh:response-graphs($context('type-constructor-graphs-response'))">
            <ixsl:promise select="ixsl:http-request(ldh:head-request(.)) =>
                ixsl:then(ldh:reveal-constructor-action($button, ?))"
                on-failure="ldh:gate-failure#1"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="ldh:response-graphs" as="xs:anyURI*">
        <xsl:param name="response" as="map(*)?"/>

        <xsl:sequence select="
            if (exists($response) and $response?status = 200 and $response?media-type = 'application/sparql-results+xml')
            then distinct-values($response?body//srx:binding[@name = 'graph']/srx:uri/xs:anyURI(.))
            else ()"/>
    </xsl:function>

    <xsl:function name="ldh:reveal-constructor-action" ixsl:updating="yes">
        <xsl:param name="button" as="element()"/>
        <xsl:param name="response" as="map(*)"/>

        <xsl:if test="ldh:writable-response($response)">
            <xsl:for-each select="$button">
                <ixsl:set-style name="display" select="''"/>

                <!-- a menu item also reveals the menu it sits in; the single-class button has no wrap -->
                <xsl:for-each select="ancestor::div[contains-token(@class, 'ldh-form-actions-wrap')][1]">
                    <ixsl:set-style name="display" select="''"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

    <!-- An unwritable constructor is DISABLED rather than hidden: it is still information about the class,
         and hiding it would say the class has fewer constructors than it does. disabled on the fieldset is
         both the rendering and the mechanism - HTML makes every control inside it inert, and the save loop
         skips it by the same attribute. -->
    <xsl:template name="ldh:GateConstructorDialog">
        <xsl:for-each select="ixsl:page()//form[contains-token(@class, 'constructor-template')]//fieldset[@data-graph][not(@data-gated)]">
            <xsl:variable name="fieldset" select="." as="element()"/>

            <ixsl:set-attribute name="data-gated" select="'true'"/>

            <ixsl:promise select="ixsl:http-request(ldh:head-request(xs:anyURI(@data-graph))) =>
                ixsl:then(ldh:gate-constructor-fieldset($fieldset, ?))"
                on-failure="ldh:disable-constructor-fieldset($fieldset, ?)"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:function name="ldh:gate-constructor-fieldset" ixsl:updating="yes">
        <xsl:param name="fieldset" as="element()"/>
        <xsl:param name="response" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="ldh:writable-response($response)">
                <!-- The HEAD that decided writability also carries the validator, so the save can write
                     conditionally without a request of its own. Every other PATCH in the client sends
                     If-Match from LinkedDataHub.contents, which holds only documents the browser navigated
                     to - and the documents edited here are ontologies it never loaded. -->
                <xsl:for-each select="$fieldset[exists($response?headers?etag)]">
                    <ixsl:set-attribute name="data-etag" select="$response?headers?etag"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:disable-constructor-fieldset($fieldset, map{})"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- also the lookup's failure handler, which is why it takes the error map it ignores -->
    <xsl:function name="ldh:disable-constructor-fieldset" ixsl:updating="yes">
        <xsl:param name="fieldset" as="element()"/>
        <xsl:param name="error" as="map(*)"/>

        <xsl:for-each select="$fieldset">
            <ixsl:set-attribute name="disabled" select="'disabled'"/>
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-readonly', true())"/>
        </xsl:for-each>
    </xsl:function>

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
            <xsl:with-param name="endpoint" select="resolve-uri('ns', lds:base())"/>
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

    <!-- save constructor form onclick. Validate it before update updating constructors -->
    <xsl:template match="form[contains-token(@class, 'constructor-template')]//div[contains-token(@class, 'mhint')]/button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="form" select="ancestor::form" as="element()"/>
        <!-- a fieldset the gate disabled is skipped by both: its rows cannot have been edited, and its
             document is one this agent may not PATCH -->
        <xsl:variable name="rows" select="$form/descendant::fieldset[not(@disabled)]/descendant::div[contains-token(@class, 'ldh-ctor-row')]" as="element()*"/>

        <xsl:choose>
            <!-- input values missing, throw an error -->
            <xsl:when test="exists($rows/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:for-each select="$rows[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]">
                    <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'error', true())"/>
                </xsl:for-each>
            </xsl:when>
            <!-- all required values present, proceed to update the constructors -->
            <xsl:otherwise>
                <!-- A fieldset is one constructor again, and one whose attachment is not exclusive to this
                     class is disabled at render, so this skips it: rewriting it would change the form of
                     every other class that has it. -->
                <xsl:variable name="updates" as="map(*)*">
                    <xsl:for-each select="$form//fieldset[not(@disabled)]">
                        <xsl:variable name="container" select="." as="element()"/>
                        <xsl:variable name="constructor-uri" select="@about/xs:anyURI(.)" as="xs:anyURI"/>
                        <xsl:variable name="valid-rows" select="ldh:constructor-valid-rows(.)" as="element()*"/>
                        <xsl:variable name="construct-xml" as="document-node()">
                            <xsl:iterate select="$valid-rows">
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

                        <!-- A constructor exists exactly when it templates at least one property: the first one
                             creates it, the last one removed deletes it, and one that never existed and still has
                             no properties is left alone. -->
                        <xsl:variable name="update-string" as="xs:string?">
                            <xsl:choose>
                                <xsl:when test="exists($valid-rows) and $container/@data-new">
                                    <xsl:variable name="create" select="replace($constructor-create-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                                    <xsl:variable name="create" select="replace($create, '$Type', '&lt;' || $form/@about || '&gt;', 'q')" as="xs:string"/>
                                    <xsl:variable name="create" select="replace($create, '$Ontology', '&lt;' || resolve-uri('ns#', lds:base()) || '&gt;', 'q')" as="xs:string"/>
                                    <xsl:sequence select="replace($create, '$text', '&quot;&quot;&quot;' || $construct-string || '&quot;&quot;&quot;', 'q')"/>
                                </xsl:when>
                                <xsl:when test="exists($valid-rows)">
                                    <xsl:variable name="update" select="replace($constructor-update-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                                    <xsl:sequence select="replace($update, '$text', '&quot;&quot;&quot;' || $construct-string || '&quot;&quot;&quot;', 'q')"/>
                                </xsl:when>
                                <xsl:when test="not($container/@data-new)">
                                    <xsl:variable name="delete" select="replace($constructor-delete-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                                    <xsl:sequence select="replace($delete, '$Type', '&lt;' || $form/@about || '&gt;', 'q')"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:if test="exists($update-string)">
                            <xsl:variable name="document-uri" select="($container/@data-graph/xs:anyURI(.), ac:document-uri($constructor-uri))[1]" as="xs:anyURI"/>

                            <!-- the request is assembled when it is sent, not here: its If-Match is whatever
                                 validator the document carries by then, which the write before it may have changed -->
                            <xsl:sequence select="map{ 'document': $document-uri, 'href': ldh:href($document-uri, map{}), 'body': $update-string }"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:choose>
                    <!-- nothing to write: Save is a no-op and closes, which nothing else would do - the
                         only other place the dialog closes is the end of the chain below -->
                    <xsl:when test="empty($updates)">
                        <xsl:for-each select="$form">
                            <xsl:call-template name="ldh:CloseModal"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="ldh:busy-cursor()"/>

                        <!-- one validator per document, seeded from the gate's HEAD and replaced by each
                             write's own response, so a second constructor in the same document is conditional
                             on what the first one left rather than on what the dialog opened with -->
                        <xsl:variable name="etags" select="map:merge($form//fieldset[@data-graph][@data-etag] ! map{ string(@data-graph): string(@data-etag) }, map{ 'duplicates': 'use-first' })" as="map(*)"/>

                        <xsl:sequence select="ldh:patch-constructors(map{ 'form': $form, 'updates': $updates, 'etags': $etags })"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- One PATCH at a time, each starting when the last has answered. LDH's PATCH is a whole-graph
         read-modify-write - it GETs the graph, applies the update to it in memory and PUTs the result back -
         so two constructors saved into the same document in parallel race, and whichever PUT lands second
         reinstates what the other had just removed. Measured: emptying one constructor while a second in the
         same document was rewritten sent a correct DELETE that answered 200, and left the constructor
         attached, because the rewrite had read the graph before that DELETE was persisted. Chaining also
         gives the clear one place to run, after every write has landed, rather than once per response. -->
    <xsl:function name="ldh:patch-constructors" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="updates" select="$context?updates" as="map(*)*"/>

        <xsl:choose>
            <xsl:when test="empty($updates)">
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

                <xsl:for-each select="$context?form">
                    <xsl:call-template name="ldh:CloseModal"/>
                </xsl:for-each>

                <!-- One clear, of the namespace ontology. It used to be preceded by a clear naming the document the
                     PATCH went to, which /clear takes as an ontology to reassemble - and a package's copy of its
                     ontology is a dh:Item ABOUT the ontology, not an owl:Ontology, so that reload answered 500 and
                     this one never ran. Nothing is lost with it: a clear discards every cached graph and closure
                     whatever URI it is given, so the namespace reload below re-reads the edited document as well. -->
                <xsl:call-template name="ldh:ClearNamespace"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="update" select="head($updates)" as="map(*)"/>
                <xsl:variable name="etag" select="$context?etags($update?document)" as="xs:string?"/>
                <xsl:variable name="headers" select="map:merge((map{ 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' }, $etag ! map{ 'If-Match': . }))" as="map(*)"/>
                <xsl:variable name="request" select="map{ 'method': 'PATCH', 'href': $update?href, 'media-type': 'application/sparql-update', 'body': $update?body, 'headers': $headers }" as="map(*)"/>

                <ixsl:promise select="ixsl:http-request($request) =>
                    ixsl:then(ldh:constructor-patched(map:put($context, 'updates', tail($updates)), $update?document, ?))"
                    on-failure="ldh:constructor-patch-failed($context, ?)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- A failed write stops the chain: the updates behind it are not sent, because the author is looking at
         a dialog whose state no longer matches the store and the rest would write on top of that. -->
    <xsl:function name="ldh:constructor-patched" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="document" as="xs:anyURI"/>
        <xsl:param name="response" as="map(*)"/>

        <xsl:variable name="etag" select="$response?headers?etag" as="xs:string?"/>
        <!-- a response that carries no validator leaves the document with none rather than with the one this
             write has just invalidated, so the next update to it is unconditional instead of certainly 412 -->
        <xsl:variable name="context" select="map:put($context, 'etags', if (exists($etag)) then map:put($context?etags, $document, $etag) else map:remove($context?etags, $document))" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 204)">
                <xsl:sequence select="ldh:patch-constructors($context)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:constructor-patch-failed($context, $response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:constructor-patch-failed" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response" as="map(*)"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:sequence select="ldh:render-failure(($context?form//div[contains-token(@class, 'ac-modal-body')])[1], 'constructor-not-updated', ac:http-error-key($response?status), ldh:response-detail($response))"/>
    </xsl:function>

    <xsl:template name="ldh:ClearNamespace">
        <xsl:param name="ontology-uri" select="resolve-uri('ns#', lds:base())" as="xs:anyURI"/>
        <xsl:variable name="form-data" select="ixsl:new('URLSearchParams', [ ixsl:new('FormData', []) ])"/>
        <xsl:sequence select="ixsl:call($form-data, 'append', [ 'uri', $ontology-uri ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="admin-base-uri" select="xs:anyURI(replace(lds:base(), '^(https?://)', '$1admin.'))" as="xs:anyURI"/>
        <xsl:variable name="clear-uri" select="resolve-uri('clear', $admin-base-uri)" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($clear-uri)" as="xs:anyURI"/>
        <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': $request-uri, 'media-type': 'application/x-www-form-urlencoded', 'body': $form-data, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <!-- the namespace ontology is fresh again - reconcile the open editing forms with the updated constructors -->
            <xsl:call-template name="ldh:SyncFormsWithConstructor"/>
        </ixsl:schedule-action>
    </xsl:template>

</xsl:stylesheet>