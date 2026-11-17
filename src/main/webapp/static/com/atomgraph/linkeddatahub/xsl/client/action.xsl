<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY wa     "https://w3id.org/atomgraph/web-algebra">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:lds="&lds;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:wa="&wa;"
xmlns:acl="&acl;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!--
        ACTIONS: what a package wants DONE, declared as data and carried out by the platform.

        A package stylesheet renders and nothing else (hooks.xsl, PackageContract). A change to data - several
        writes across documents, a delete that drops the links other documents hold to it - is declared in the package's
        ontology instead:

            skos:Concept ldh:action :DeleteConcept .
            :DeleteConcept a ldh:Action ; dct:title "Delete concept" ; ldh:plan """<Sequence .../>"""^^rdf:XMLLiteral .

        The plan is a Web-Algebra operation (client/webalgebra.xsl). It takes its parameters as $wa:bindings, one
        row: ?this (the resource the action was clicked on), ?document (the document it was clicked in), ?base
        (the dataspace) and ?admin (its admin dataspace). An action that needs more - the concept a Move puts it
        under - declares arguments as a SPIN template does (spin:constraint [ a spl:Argument ; spl:predicate
        :target ; spl:valueType skos:Concept ]): the dialog asks for them first, and each value is one more column
        of the row, named by the predicate's local name (?target), as SPIN binds an argument. The platform finds the actions of a resource's classes
        the way it finds their constructors - a SPARQL query on /ns, through rdfs:subClassOf - and renders them
        as a menu in the block's header, for a reader who may write and where the dataspace has an executor
        (lds:assistant).

        A click never writes at once. The plan is first evaluated with dry-run="true", which returns its write
        set without applying it - every PUT, PATCH, POST and DELETE with its URI, derived from a snapshot and
        with its preconditions - and that set is checked and shown:

            - a write outside this dataspace and its admin is refused outright; the dialog says which;
            - a write into the admin dataspace or to the settings is flagged: access control and configuration;
            - the reader confirms, and only then is the same plan submitted again to be applied.

        What the reader sees is what will happen, read off the evaluated plan rather than off the package's
        description of itself. A write set applied in part (a refusal mid-way, per document) is reported as such.
    -->

    <!-- the actions a resource's classes declare, through rdfs:subClassOf as constructors are found; VALUES ?type
         is appended per block, as the ontology-view query's is -->
    <xsl:variable name="ldh:action-query" as="xs:string">
        <![CDATA[
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
            PREFIX  dct:  <http://purl.org/dc/terms/>

            SELECT DISTINCT ?action ?title
            WHERE {
                ?type rdfs:subClassOf* ?class .
                ?class ldh:action ?action .
                ?action dct:title ?title .
            }
        ]]>
        <!-- VALUES ?type goes here -->
    </xsl:variable>

    <!-- one action's plan and its arguments, read when it is clicked rather than kept on the page: the plan is the
         ontology's, and a click is the only time it is needed. One row per argument, or one row without any -->
    <xsl:function name="ldh:action-plan-query" as="xs:string">
        <xsl:param name="action" as="xs:anyURI"/>

        <xsl:sequence select="'PREFIX ldh: &lt;&ldh;&gt; PREFIX spin: &lt;http://spinrdf.org/spin#&gt; PREFIX spl: &lt;http://spinrdf.org/spl#&gt; PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt; SELECT ?plan ?predicate ?valueType ?optional ?label ?comment WHERE { &lt;' || $action || '&gt; ldh:plan ?plan OPTIONAL { &lt;' || $action || '&gt; spin:constraint ?arg . ?arg a spl:Argument ; spl:predicate ?predicate OPTIONAL { ?arg spl:valueType ?valueType } OPTIONAL { ?arg spl:optional ?optional } OPTIONAL { ?predicate rdfs:label ?label } OPTIONAL { ?arg rdfs:comment ?comment } } }'"/>
    </xsl:function>

    <!-- the variable an argument binds: its predicate's local name, the SPIN rule (arg:target binds ?target) -->
    <xsl:function name="ldh:argument-name" as="xs:string">
        <xsl:param name="predicate" as="xs:string"/>

        <xsl:sequence select="tokenize($predicate, '[#/]')[last()]"/>
    </xsl:function>

    <!-- DISCOVERY -->

    <!-- the actions menu for a typed resource block, contributed to the ldh:Hydrate walk (client/block.xsl)
         beside the ontology views: the same row wrapper, the same /ns query shape. Only for a reader who may
         write the document - the actions change data - and only where the dataspace has an executor.
         Priority 1 over the ontology-view rule's default, which matches the same row: this one runs first and
         passes the row on, so neither depends on include order. -->
    <xsl:template match="child::div[contains-token(@class, 'ldh-block-row')][@about][child::div[contains-token(@class, 'row-main')]/div[contains-token(@class, 'block')][@typeof]]" mode="ldh:HydrationHook" priority="1" as="(function(item()?) as map(*))*">
        <xsl:if test="acl:mode() = '&acl;Write' and lds:dataspace-description()/lds:assistant = 'true'">
            <xsl:variable name="block" select="child::div[contains-token(@class, 'row-main')]/div[contains-token(@class, 'block')][@typeof]" as="element()"/>
            <xsl:variable name="typeof-uris" select="tokenize($block/@typeof, ' ') ! xs:anyURI(.)" as="xs:anyURI*"/>
            <xsl:variable name="values-clause" select="' VALUES ?type { ' || string-join(for $t in $typeof-uris return '&lt;' || $t || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': $ldh:action-query || $values-clause }), map{})" as="xs:anyURI"/>
            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
            <xsl:variable name="context" select="map{ 'request': $request, 'block': $block }" as="map(*)"/>

            <xsl:sequence select="ldh:actions-load#2($context, ?)"/>
        </xsl:if>

        <xsl:next-match/>
    </xsl:template>

    <xsl:function name="ldh:actions-load" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?"/>

        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:actions-loaded#1)
        "/>
    </xsl:function>

    <!-- the menu goes into the block header's action cluster, after copy and edit: the app kit's overflow menu
         (.ldh-of-wrap), opened by the platform's drop-toggle handler, one entry per action -->
    <xsl:function name="ldh:actions-loaded" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="block" select="$context('block')" as="element()"/>

        <xsl:if test="$response?status = 200 and $response?media-type = 'application/sparql-results+xml'">
            <xsl:variable name="results" select="$response?body//srx:result" as="element()*"/>

            <xsl:if test="exists($results)">
                <xsl:for-each select="$block/div[contains-token(@class, 'ldh-block-head')]/div[contains-token(@class, 'actions')]">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div class="ldh-of-wrap ac-menu-anchor ldh-action-menu">
                            <button type="button" class="ac-iconbtn sz-sm in-neutral ap-ghost drop-toggle" aria-haspopup="menu" aria-expanded="false" title="{ac:label(key('resources', 'actions', ldh:translations()))}" aria-label="{ac:label(key('resources', 'actions', ldh:translations()))}">
                                <span class="msi sm" aria-hidden="true">bolt</span>
                            </button>

                            <div class="ldh-of-menu">
                                <xsl:for-each select="$results">
                                    <xsl:sort select="srx:binding[@name = 'title']/srx:literal"/>

                                    <button type="button" class="it btn-action" data-action="{srx:binding[@name = 'action']/srx:uri}">
                                        <span class="msi sm" aria-hidden="true">play_arrow</span>
                                        <span class="it-txt">
                                            <xsl:value-of select="srx:binding[@name = 'title']/srx:literal"/>
                                        </span>
                                    </button>
                                </xsl:for-each>
                            </div>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- THE CLICK: read the plan, evaluate it, show what it would do -->

    <xsl:template match="button[contains-token(@class, 'btn-action')][@data-action]" mode="ixsl:onclick">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][@about][1]" as="element()"/>
        <xsl:variable name="pane" select="ancestor::div[contains-token(@class, 'ldh-pane')]" as="element()"/>
        <xsl:variable name="context" select="ldh:action-context(xs:anyURI(@data-action), string(span[contains-token(@class, 'it-txt')]), xs:anyURI($block/@about), ldh:base-uri($block), $pane)" as="map(*)"/>

        <xsl:sequence select="ldh:busy-cursor()"/>
        <ixsl:promise select="ldh:action-plan($context, true())" on-failure="ldh:action-failure($context, ?)"/>
    </xsl:template>

    <!-- what a plan runs with, read once from where the action was clicked: the resource, the document it is shown
         in, the dataspace and its admin - the one row of $wa:bindings -->
    <xsl:function name="ldh:action-context" as="map(*)">
        <xsl:param name="action" as="xs:anyURI"/>
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="document" as="xs:anyURI"/>
        <xsl:param name="pane" as="element()"/>

        <xsl:sequence select="
            map{
                'action': $action,
                'title': $title,
                'this': $this,
                'document': $document,
                'base': lds:base(),
                'admin': lds:dataspace-description()/lds:admin/@rdf:resource/xs:anyURI(.),
                'pane': $pane,
                'content-body': $pane/div[contains-token(@class, 'document-body')]/div[contains-token(@class, 'content-body')]
            }"/>
    </xsl:function>

    <!-- reads the plan from the ontology, then submits it: evaluated only (dry run) or applied -->
    <xsl:function name="ldh:action-plan" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="dry-run" as="xs:boolean"/>
        <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', lds:base()), map{ 'query': ldh:action-plan-query($context('action')) }), map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>

        <xsl:sequence select="
            ixsl:http-request($request) =>
                ixsl:then(ldh:rethread-response(map:put($context, 'dry-run', $dry-run), ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:action-plan-response#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:action-plan-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="literal" select="($response?body//srx:binding[@name = 'plan']/srx:literal)[1]" as="element()?"/>
        <xsl:variable name="arguments" select="$response?body//srx:result[srx:binding[@name = 'predicate']]" as="element()*"/>

        <xsl:choose>
            <!-- arguments not asked for yet: the dialog asks first, and Preview comes back here with them -->
            <xsl:when test="$response?status = 200 and exists($literal) and exists($arguments) and not(map:contains($context, 'arguments'))">
                <xsl:sequence select="ldh:action-arguments-dialog($context, $arguments)"/>
            </xsl:when>
            <xsl:when test="$response?status = 200 and exists($literal)">
                <!-- the plan is an rdf:XMLLiteral: its XML, parsed, is the operation -->
                <xsl:variable name="plan" select="parse-xml(string($literal))/*" as="element()"/>
                <xsl:variable name="values" select="if (map:contains($context, 'arguments')) then $context('arguments') else ()" as="element()*"/>
                <xsl:variable name="body" as="document-node()">
                    <xsl:document>
                        <wa:request dry-run="{if ($context('dry-run')) then 'true' else 'false'}">
                            <wa:bindings>
                                <sparql xmlns="http://www.w3.org/2005/sparql-results#">
                                    <head>
                                        <variable name="this"/>
                                        <variable name="document"/>
                                        <variable name="base"/>
                                        <variable name="admin"/>
                                        <xsl:for-each select="$values">
                                            <variable name="{@name}"/>
                                        </xsl:for-each>
                                    </head>
                                    <results>
                                        <result>
                                            <binding name="this"><uri><xsl:value-of select="$context('this')"/></uri></binding>
                                            <binding name="document"><uri><xsl:value-of select="$context('document')"/></uri></binding>
                                            <binding name="base"><uri><xsl:value-of select="$context('base')"/></uri></binding>
                                            <xsl:if test="exists($context('admin'))">
                                                <binding name="admin"><uri><xsl:value-of select="$context('admin')"/></uri></binding>
                                            </xsl:if>
                                            <xsl:for-each select="$values">
                                                <binding name="{@name}">
                                                    <xsl:choose>
                                                        <xsl:when test="@datatype">
                                                            <literal datatype="{@datatype}"><xsl:value-of select="@value"/></literal>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <uri><xsl:value-of select="@value"/></uri>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </binding>
                                            </xsl:for-each>
                                        </result>
                                    </results>
                                </sparql>
                            </wa:bindings>
                            <wa:plan>
                                <xsl:copy-of select="$plan"/>
                            </wa:plan>
                        </wa:request>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="submission" select="map:merge(($context, map{ 'plan': $plan, 'request': ldh:webalgebra-request($body), 'on-ended': if ($context('dry-run')) then ldh:action-planned#2 else ldh:action-applied#2 }), map{ 'duplicates': 'use-last' })" as="map(*)"/>

                <xsl:sequence select="
                    ixsl:http-request($submission('request')) =>
                        ixsl:then(ldh:rethread-response($submission, ?)) =>
                        ixsl:then(ldh:handle-response#1) =>
                        ixsl:then(ldh:execution-response#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- THE ARGUMENTS: what the action needs besides the resource, asked for before anything is evaluated. A
         resource argument is looked up among the instances of its spl:valueType, as an object property's value
         is; any other is typed in -->

    <xsl:function name="ldh:action-arguments-dialog" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="arguments" as="element()*"/>

        <xsl:sequence select="ldh:reset-cursor()"/>

        <xsl:variable name="modal" as="element()">
            <div class="ac-backdrop pos-center modal modal-action" id="{'action-modal-' || $context('pane')/@id}">
                <xsl:apply-templates select="$context('pane')" mode="ldh:Modal">
                    <xsl:with-param name="size" select="'sz-md'"/>
                    <xsl:with-param name="title" select="$context('title')"/>
                    <xsl:with-param name="sub" select="$context('this')"/>
                    <xsl:with-param name="body" as="item()*">
                        <form class="ldh-action-args-form" data-action="{$context('action')}" data-this="{$context('this')}" data-document="{$context('document')}" data-title="{$context('title')}">
                            <fieldset>
                                <div class="ldh-prop-form is-form-mode">
                                    <xsl:for-each select="$arguments">
                                        <xsl:variable name="predicate" select="xs:anyURI(srx:binding[@name = 'predicate']/srx:uri)" as="xs:anyURI"/>
                                        <xsl:variable name="value-type" select="srx:binding[@name = 'valueType']/srx:uri/xs:anyURI(.)" as="xs:anyURI?"/>
                                        <xsl:variable name="required" select="not(srx:binding[@name = 'optional']/srx:literal = 'true')" as="xs:boolean"/>
                                        <xsl:variable name="literal" select="exists($value-type) and starts-with($value-type, '&xsd;')" as="xs:boolean"/>
                                        <xsl:variable name="id" select="'action-arg-' || ldh:argument-name($predicate)" as="xs:string"/>

                                        <div class="ldh-prop-group ldh-action-arg{if ($required) then ' required' else ()}" data-name="{ldh:argument-name($predicate)}">
                                            <xsl:if test="$required">
                                                <xsl:attribute name="data-required" select="'true'"/>
                                            </xsl:if>
                                            <xsl:if test="$literal">
                                                <xsl:attribute name="data-datatype" select="$value-type"/>
                                            </xsl:if>

                                            <xsl:apply-templates select="." mode="ldh:PropertyLabel">
                                                <xsl:with-param name="this" select="$predicate"/>
                                                <xsl:with-param name="label" select="(srx:binding[@name = 'label']/srx:literal, ldh:argument-name($predicate))[1] ! string(.)"/>
                                                <xsl:with-param name="required" select="$required"/>
                                                <xsl:with-param name="description" select="srx:binding[@name = 'comment']/srx:literal ! string(.)"/>
                                            </xsl:apply-templates>
                                            <div class="ldh-prop-row is-last">
                                                <div class="value val-stack">
                                                    <div class="val-main">
                                                        <xsl:choose>
                                                            <xsl:when test="$literal">
                                                                <xsl:apply-templates select="." mode="ac:FieldShell">
                                                                    <xsl:with-param name="control" as="item()*">
                                                                        <input type="text" name="ol" id="{$id}"/>
                                                                    </xsl:with-param>
                                                                </xsl:apply-templates>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:call-template name="ldh:Combobox">
                                                                    <xsl:with-param name="id" select="$id"/>
                                                                    <xsl:with-param name="forClass" select="$value-type"/>
                                                                </xsl:call-template>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </div>
                                                </div>
                                                <div class="row-actions"></div>
                                            </div>
                                        </div>
                                    </xsl:for-each>
                                </div>
                            </fieldset>

                            <div class="ldh-form-bar">
                                <span class="fb-end">
                                    <button type="button" class="ac-btn in-neutral ap-outline sz-sm btn-close">
                                        <span>
                                            <xsl:apply-templates select="key('resources', 'cancel', ldh:translations())" mode="ac:label"/>
                                        </span>
                                    </button>
                                    <button type="submit" class="ac-btn in-brand ap-solid sz-sm btn-action-preview">
                                        <span class="msi sm" aria-hidden="true">visibility</span>
                                        <span>
                                            <xsl:apply-templates select="key('resources', 'action-preview', ldh:translations())" mode="ac:label"/>
                                        </span>
                                    </button>
                                </span>
                            </div>
                        </form>
                    </xsl:with-param>
                </xsl:apply-templates>
            </div>
        </xsl:variable>

        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" select="$modal"/>
            <xsl:with-param name="target" select="$context('content-body')"/>
        </xsl:call-template>
    </xsl:function>

    <!-- one argument's value as the form holds it: a picked resource is the committed chip's input, a typed value the
         text input's. A lookup left half-typed has no value -->
    <xsl:function name="ldh:action-argument-value" as="xs:string?">
        <xsl:param name="group" as="element()"/>

        <xsl:sequence select="(if ($group/@data-datatype) then $group//input[@name = 'ol'] else $group//span[contains-token(@class, 'ac-cb-committed')]//input[@name = 'ou'])[1] ! normalize-space(ixsl:get(., 'value'))[. ne '']"/>
    </xsl:function>

    <!-- Preview: every required argument has a value, or the empty ones are marked and nothing is sent; then the
         arguments dialog gives way to the write set, evaluated with them -->
    <xsl:template match="form[contains-token(@class, 'ldh-action-args-form')]" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="pane" select="ancestor::div[contains-token(@class, 'ldh-pane')]" as="element()"/>
        <xsl:variable name="groups" select=".//div[contains-token(@class, 'ldh-action-arg')]" as="element()*"/>
        <xsl:variable name="missing" select="$groups[@data-required = 'true'][empty(ldh:action-argument-value(.))]" as="element()*"/>

        <!-- the control is marked, as the design system marks an invalid one -->
        <xsl:for-each select="$groups//div[contains-token(@class, 'ac-combobox') or contains-token(@class, 'ac-field')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'st-invalid', exists(ancestor::div[contains-token(@class, 'ldh-action-arg')] intersect $missing) ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:if test="empty($missing)">
            <xsl:variable name="arguments" as="element()*">
                <xsl:for-each select="$groups[exists(ldh:action-argument-value(.))]">
                    <arg name="{@data-name}" value="{ldh:action-argument-value(.)}">
                        <xsl:if test="@data-datatype">
                            <xsl:attribute name="datatype" select="@data-datatype"/>
                        </xsl:if>
                    </arg>
                </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="context" select="map:put(ldh:action-context(xs:anyURI(@data-action), string(@data-title), xs:anyURI(@data-this), xs:anyURI(@data-document), $pane), 'arguments', $arguments)" as="map(*)"/>

            <xsl:for-each select="ancestor::div[contains-token(@class, 'modal')]">
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
            <xsl:sequence select="ldh:busy-cursor()"/>
            <ixsl:promise select="ldh:action-plan($context, true())" on-failure="ldh:action-failure($context, ?)"/>
        </xsl:if>
    </xsl:template>

    <!-- THE DRY RUN: the write set, checked and shown -->

    <!-- the write set names documents by URI; the reader knows them by title. One query asks the dataspace for the
         titles of the documents it holds, and the dialog opens with whatever came back: a document with no title
         here (one in the admin dataspace, one not made yet) keeps its URI -->
    <xsl:function name="ldh:action-planned" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:variable name="uris" select="distinct-values($execution/wa:writes/wa:write[@outcome = 'planned']/@uri)" as="xs:string*"/>

        <xsl:choose>
            <xsl:when test="$execution/wa:status = 'complete' and exists($uris)">
                <xsl:variable name="query" select="'PREFIX dct: &lt;http://purl.org/dc/terms/&gt; PREFIX sioc: &lt;http://rdfs.org/sioc/ns#&gt; SELECT ?doc ?title ?container WHERE { VALUES ?doc { ' || string-join($uris ! ('&lt;' || . || '&gt;'), ' ') || ' } GRAPH ?doc { ?doc dct:title ?title OPTIONAL { ?doc sioc:has_container|sioc:has_parent ?container } } }'" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('sparql', $context('base')), map{ 'query': $query }), map{})" as="xs:anyURI"/>
                <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
                <xsl:sequence select="
                    ixsl:http-request($request) =>
                        ixsl:then(ldh:rethread-response(map:put($context, 'execution', $execution), ?, 'titles-response')) =>
                        ixsl:then(ldh:action-titles-response#1)
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:action-dialog($context, $execution, map{})"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- no titles is not a failure: the dialog opens with the URIs. The document's container comes back with them,
         read from the data while the document still exists: where a reader goes once it is deleted -->
    <xsl:function name="ldh:action-titles-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('titles-response')" as="map(*)"/>
        <xsl:variable name="results" select="if ($response?status = 200) then $response?body//srx:result else ()" as="element()*"/>
        <xsl:variable name="titles" select="map:merge(for $result in $results return map{ string($result/srx:binding[@name = 'doc']/srx:uri): string($result/srx:binding[@name = 'title']/srx:literal) }, map{ 'duplicates': 'use-first' })" as="map(*)"/>
        <xsl:variable name="container" select="($results[srx:binding[@name = 'doc']/srx:uri = $context('document')]/srx:binding[@name = 'container']/srx:uri)[1] ! xs:anyURI(.)" as="xs:anyURI?"/>

        <xsl:sequence select="ldh:action-dialog(map:put($context, 'container', $container), $context('execution'), $titles)"/>
    </xsl:function>

    <!-- what a write does, in the reader's words: PATCH updates, DELETE deletes, POST adds to, and PUT creates a
         document the dataspace does not have yet and replaces one it has -->
    <xsl:function name="ldh:action-verb" as="xs:string">
        <xsl:param name="write" as="element()"/>
        <xsl:param name="titles" as="map(*)"/>
        <xsl:param name="base" as="xs:anyURI"/>

        <xsl:sequence select="
            if ($write/@method = 'PATCH') then 'action-update'
            else if ($write/@method = 'DELETE') then 'action-delete'
            else if ($write/@method = 'POST') then 'action-add-to'
            else if (map:contains($titles, string($write/@uri))) then 'action-replace'
            else if (starts-with($write/@uri, $base)) then 'action-create'
            else 'action-write'"/>
    </xsl:function>

    <xsl:function name="ldh:action-dialog" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:param name="titles" as="map(*)"/>
        <xsl:variable name="writes" select="$execution/wa:writes/wa:write[@outcome = 'planned']" as="element()*"/>
        <xsl:variable name="base" select="$context('base')" as="xs:anyURI"/>
        <xsl:variable name="admin" select="$context('admin')" as="xs:anyURI?"/>
        <!-- the policy: inside this dataspace or its admin, or nowhere -->
        <xsl:variable name="outside" select="$writes[not(starts-with(@uri, $base) or (exists($admin) and starts-with(@uri, $admin)))]" as="element()*"/>
        <xsl:variable name="allowed" select="$execution/wa:status = 'complete' and exists($writes) and empty($outside)" as="xs:boolean"/>

        <xsl:sequence select="ldh:reset-cursor()"/>

        <xsl:variable name="modal" as="element()">
            <div class="ac-backdrop pos-center modal modal-action" id="{'action-modal-' || $context('pane')/@id}">
                <xsl:apply-templates select="$context('pane')" mode="ldh:Modal">
                    <xsl:with-param name="size" select="'sz-md'"/>
                    <xsl:with-param name="title" select="$context('title')"/>
                    <xsl:with-param name="sub" select="$context('this')"/>
                    <xsl:with-param name="body" as="item()*">
                        <form class="ldh-action-form" data-action="{$context('action')}" data-this="{$context('this')}" data-document="{$context('document')}" data-title="{$context('title')}">
                            <xsl:if test="exists($context('container'))">
                                <xsl:attribute name="data-container" select="$context('container')"/>
                            </xsl:if>
                            <!-- the arguments it was evaluated with, so Confirm applies the same -->
                            <xsl:if test="map:contains($context, 'arguments')">
                                <xsl:for-each select="$context('arguments')">
                                    <input type="hidden" name="arg" data-name="{@name}" value="{@value}">
                                        <xsl:if test="@datatype">
                                            <xsl:attribute name="data-datatype" select="@datatype"/>
                                        </xsl:if>
                                    </input>
                                </xsl:for-each>
                            </xsl:if>
                            <fieldset>
                                <!-- the plan, as the assistant shows one: the operations, folded under their count -->
                                <xsl:apply-templates select="$context('plan')" mode="ldh:PlanTrace"/>
                                <xsl:choose>
                                    <xsl:when test="$execution/wa:status = 'error'">
                                        <p>
                                            <xsl:apply-templates select="key('resources', 'action-not-started-explanation', ldh:translations())" mode="ac:label"/>
                                        </p>
                                        <xsl:if test="$execution/wa:message">
                                            <pre><xsl:value-of select="$execution/wa:message"/></pre>
                                        </xsl:if>
                                    </xsl:when>
                                    <xsl:when test="empty($writes)">
                                        <p>
                                            <xsl:apply-templates select="key('resources', 'action-no-writes', ldh:translations())" mode="ac:label"/>
                                        </p>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <p>
                                            <xsl:apply-templates select="key('resources', 'action-planned-writes', ldh:translations())" mode="ac:label"/>
                                        </p>
                                        <ul class="ldh-action-writes">
                                            <xsl:for-each select="$writes">
                                                <xsl:variable name="flagged" select="(exists($admin) and starts-with(@uri, $admin)) or @uri = ($base || 'settings', $base || 'settings/')" as="xs:boolean"/>
                                                <!-- the method and the URI stay on the row, as data and as the link's target -->
                                                <li class="{if (. intersect $outside) then 'is-danger' else if ($flagged) then 'is-flagged' else ()}" data-method="{@method}">
                                                    <span class="ldh-action-verb">
                                                        <xsl:apply-templates select="key('resources', ldh:action-verb(., $titles, $base), ldh:translations())" mode="ac:label"/>
                                                    </span>
                                                    <xsl:text> </xsl:text>
                                                    <a href="{@uri}" title="{@uri}" target="_blank">
                                                        <xsl:value-of select="if (map:contains($titles, string(@uri))) then $titles(string(@uri)) else @uri"/>
                                                    </a>
                                                    <xsl:choose>
                                                        <xsl:when test=". intersect $outside">
                                                            <xsl:text> </xsl:text>
                                                            <span class="msi sm" aria-hidden="true">block</span>
                                                            <xsl:text> </xsl:text>
                                                            <xsl:apply-templates select="key('resources', 'action-outside-dataspace', ldh:translations())" mode="ac:label"/>
                                                        </xsl:when>
                                                        <xsl:when test="$flagged">
                                                            <xsl:text> </xsl:text>
                                                            <span class="msi sm" aria-hidden="true">lock</span>
                                                            <xsl:text> </xsl:text>
                                                            <xsl:apply-templates select="key('resources', 'action-flagged', ldh:translations())" mode="ac:label"/>
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </fieldset>

                            <div class="ldh-form-bar">
                                <span class="fb-end">
                                    <button type="button" class="ac-btn in-neutral ap-outline sz-sm btn-close">
                                        <span>
                                            <xsl:apply-templates select="key('resources', 'cancel', ldh:translations())" mode="ac:label"/>
                                        </span>
                                    </button>
                                    <xsl:if test="$allowed">
                                        <button type="submit" class="ac-btn in-brand ap-solid sz-sm btn-action-confirm">
                                            <span class="msi sm" aria-hidden="true">play_arrow</span>
                                            <span>
                                                <xsl:apply-templates select="key('resources', 'confirm', ldh:translations())" mode="ac:label"/>
                                            </span>
                                        </button>
                                    </xsl:if>
                                </span>
                            </div>
                        </form>
                    </xsl:with-param>
                </xsl:apply-templates>
            </div>
        </xsl:variable>

        <xsl:call-template name="ldh:ShowModalForm">
            <xsl:with-param name="form" select="$modal"/>
            <xsl:with-param name="target" select="$context('content-body')"/>
        </xsl:call-template>
    </xsl:function>

    <!-- THE CONFIRMATION: the same plan, read and submitted again, applied this time -->

    <xsl:template match="form[contains-token(@class, 'ldh-action-form')]" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="pane" select="ancestor::div[contains-token(@class, 'ldh-pane')]" as="element()"/>
        <xsl:variable name="arguments" as="element()*">
            <xsl:for-each select="input[@name = 'arg']">
                <arg name="{@data-name}" value="{@value}">
                    <xsl:if test="@data-datatype">
                        <xsl:attribute name="datatype" select="@data-datatype"/>
                    </xsl:if>
                </arg>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="context" select="ldh:action-context(xs:anyURI(@data-action), string(@data-title), xs:anyURI(@data-this), xs:anyURI(@data-document), $pane)" as="map(*)"/>
        <xsl:variable name="context" select="map:merge(($context, map{ 'form': ., 'container': @data-container ! xs:anyURI(.) }, if (exists($arguments)) then map{ 'arguments': $arguments } else ()))" as="map(*)"/>

        <xsl:for-each select="button[contains-token(@class, 'btn-action-confirm')] | .//button[contains-token(@class, 'btn-action-confirm')]">
            <ixsl:set-attribute name="disabled" select="''"/>
        </xsl:for-each>
        <xsl:sequence select="ldh:busy-cursor()"/>
        <ixsl:promise select="ldh:action-plan($context, false())" on-failure="ldh:action-failure($context, ?)"/>
    </xsl:template>

    <!-- what applying did. Complete: the dialog has served its purpose and the document is read again, since a
         plan changes what the page shows (a concept re-parented, a document gone); a document the plan deleted
         sends the reader to its container. Error: a write was refused and what was applied before it stands -
         told in the dialog, which stays open, with the executor's message. -->
    <xsl:function name="ldh:action-applied" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:variable name="form" select="$context('form')" as="element()"/>
        <xsl:variable name="document" select="$context('document')" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="$execution/wa:status = 'complete'">
                <xsl:for-each select="$form/ancestor::div[contains-token(@class, 'modal')]">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>

                <xsl:variable name="deleted" select="exists($execution/wa:writes/wa:write[@method = 'DELETE'][@outcome = 'applied'][@uri = $document])" as="xs:boolean"/>
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="if ($deleted) then ($context('container'), $context('base'))[1] else $document"/>
                    <xsl:with-param name="fragment" select="()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:reset-cursor()"/>
                <xsl:sequence select="ldh:render-failure($form, 'action-refused', 'action-refused-explanation', string($execution/wa:message))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- a request that did not get as far as an execution: told where the action was clicked -->
    <xsl:function name="ldh:action-failure" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="error" as="map(*)"/>
        <xsl:variable name="host" select="if (map:contains($context, 'form')) then $context('form') else $context('content-body')" as="element()"/>

        <xsl:sequence select="ldh:promise-failure($host, 'action-not-started', $error)"/>
    </xsl:function>

</xsl:stylesheet>
