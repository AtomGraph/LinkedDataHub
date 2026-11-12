<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY wa     "https://w3id.org/atomgraph/web-algebra">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
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
        writes across documents, a delete that re-parents what it orphans - is declared in the package's
        ontology instead:

            skos:Concept ldh:action :DeleteConcept .
            :DeleteConcept a ldh:Action ; dct:title "Delete concept" ; ldh:plan """<Sequence .../>"""^^rdf:XMLLiteral .

        The plan is a Web-Algebra operation (client/webalgebra.xsl). It takes its parameters as $wa:bindings, one
        row: ?this (the resource the action was clicked on), ?document (the document it was clicked in), ?base
        (the dataspace) and ?admin (its admin dataspace). The platform finds the actions of a resource's classes
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

    <!-- one action's plan, read when it is clicked rather than kept on the page: the plan is the ontology's,
         and a click is the only time it is needed -->
    <xsl:function name="ldh:action-plan-query" as="xs:string">
        <xsl:param name="action" as="xs:anyURI"/>

        <xsl:sequence select="'PREFIX ldh: &lt;&ldh;&gt; SELECT ?plan WHERE { &lt;' || $action || '&gt; ldh:plan ?plan }'"/>
    </xsl:function>

    <!-- DISCOVERY -->

    <!-- the actions menu for a typed resource block, contributed to the ldh:RenderRow walk (client/block.xsl)
         beside the ontology views: the same row wrapper, the same /ns query shape. Only for a reader who may
         write the document - the actions change data - and only where the dataspace has an executor. -->
    <xsl:template match="child::div[contains-token(@class, 'ldh-block-row')][@about][child::div[contains-token(@class, 'row-main')]/div[contains-token(@class, 'block')][@typeof]]" mode="ldh:RowHook" as="(function(item()?) as map(*))*">
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
        <xsl:variable name="context" select="ldh:action-context(xs:anyURI(@data-action), string(span[contains-token(@class, 'it-txt')]), xs:anyURI($block/@about), $pane)" as="map(*)"/>

        <xsl:sequence select="ldh:busy-cursor()"/>
        <ixsl:promise select="ldh:action-plan($context, true())" on-failure="ldh:action-failure($context, ?)"/>
    </xsl:template>

    <!-- what a plan runs with, read once from where the action was clicked: the resource, its document, the
         dataspace and its admin - the one row of $wa:bindings -->
    <xsl:function name="ldh:action-context" as="map(*)">
        <xsl:param name="action" as="xs:anyURI"/>
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="this" as="xs:anyURI"/>
        <xsl:param name="pane" as="element()"/>

        <xsl:sequence select="
            map{
                'action': $action,
                'title': $title,
                'this': $this,
                'document': ac:document-uri($this),
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

        <xsl:choose>
            <xsl:when test="$response?status = 200 and exists($literal)">
                <!-- the plan is an rdf:XMLLiteral: its XML, parsed, is the operation -->
                <xsl:variable name="plan" select="parse-xml(string($literal))/*" as="element()"/>
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
                                    </head>
                                    <results>
                                        <result>
                                            <binding name="this"><uri><xsl:value-of select="$context('this')"/></uri></binding>
                                            <binding name="document"><uri><xsl:value-of select="$context('document')"/></uri></binding>
                                            <binding name="base"><uri><xsl:value-of select="$context('base')"/></uri></binding>
                                            <xsl:if test="exists($context('admin'))">
                                                <binding name="admin"><uri><xsl:value-of select="$context('admin')"/></uri></binding>
                                            </xsl:if>
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
                <xsl:variable name="submission" select="map:merge(($context, map{ 'request': ldh:webalgebra-request($body), 'on-ended': if ($context('dry-run')) then ldh:action-planned#2 else ldh:action-applied#2 }), map{ 'duplicates': 'use-last' })" as="map(*)"/>

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

    <!-- THE DRY RUN: the write set, checked and shown -->

    <xsl:function name="ldh:action-planned" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="execution" as="element()"/>
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
                        <form class="ldh-action-form" data-action="{$context('action')}" data-this="{$context('this')}" data-title="{$context('title')}">
                            <fieldset>
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
                                                <li class="{if (. intersect $outside) then 'is-danger' else if ($flagged) then 'is-flagged' else ()}">
                                                    <code><xsl:value-of select="@method"/></code>
                                                    <xsl:text> </xsl:text>
                                                    <a href="{@uri}" target="_blank"><xsl:value-of select="@uri"/></a>
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
        <xsl:variable name="context" select="map:put(ldh:action-context(xs:anyURI(@data-action), string(@data-title), xs:anyURI(@data-this), $pane), 'form', .)" as="map(*)"/>

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
                    <xsl:with-param name="doc-uri" select="if ($deleted) then resolve-uri('..', $document) else $document"/>
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
