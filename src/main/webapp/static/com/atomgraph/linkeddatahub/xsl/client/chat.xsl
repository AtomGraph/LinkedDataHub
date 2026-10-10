<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY wa     "https://w3id.org/atomgraph/web-algebra">
    <!ENTITY waldh  "https://w3id.org/atomgraph/web-algebra/linkeddatahub">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
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
xmlns:sd="&sd;"
xmlns:wa="&wa;"
xmlns:waldh="&waldh;"
xmlns:acl="&acl;"
xmlns:dct="&dct;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- The assistant: a question becomes a Web-Algebra plan, the plan is shown, and only a press of Execute runs
         it. The plan service sits beside this instance (the web-algebra container, behind nginx at /webalgebra) and
         acts for the reader whose certificate nginx forwards, so what a plan may write is what the reader may write.

         A conversation is a block: an ldh:Chat resource, placed in a document by an ldh:Object block like a view or a
         chart, its turns ldh:ChatTurn resources that are its rdf:_N members. So a page holds as many conversations as
         it has chat blocks, a conversation is there when the reader comes back, and it can be embedded elsewhere. Each
         chat block ends in its own composer, and everything a question does happens inside the block it was asked in.

         The bar's Assistant button inserts a chat block that is not written yet (ldh:ChatEphemeral). Its first
         question writes the chat, the object block that places it and the document's rdf:_N for that block; a click
         that asks nothing leaves nothing behind. Every turn is written to the chat's own document when it ends (the
         answer has landed, or could not), with its plan, what the execution reported - the result capped - and how
         it went, so a block rendered again draws every turn from the store (the ldh:Chat RowHook below).

         Within a block, a conversation is a sequence of cards, one per question, each holding its plan under its own
         id in LinkedDataHub.chat so that a card's Execute runs that card's plan and no other. -->

    <!-- THE BLOCK -->

    <!-- the chat a node belongs to, its composer and its log -->
    <xsl:function name="ldh:chat-of" as="element()?">
        <xsl:param name="node" as="element()"/>

        <xsl:sequence select="$node/ancestor-or-self::div[contains-token(@class, 'ldh-chat')][1]"/>
    </xsl:function>

    <xsl:function name="ldh:chat-form" as="element()?">
        <xsl:param name="chat" as="element()?"/>

        <xsl:sequence select="$chat/form[contains-token(@class, 'ldh-chat-composer')]"/>
    </xsl:function>

    <xsl:function name="ldh:chat-log" as="element()?">
        <xsl:param name="chat" as="element()?"/>

        <xsl:sequence select="$chat/div[contains-token(@class, 'ldh-chat-log')]"/>
    </xsl:function>

    <!-- the conversation's body: the log of its turns and, for a reader who may append to the chat's document and can be
         acted for, the composer at its end. A reader without either sees the transcript and nothing to type into -->
    <xsl:template name="ldh:ChatBody">
        <xsl:param name="chat-uri" as="xs:anyURI"/>
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="ephemeral" select="false()" as="xs:boolean"/>
        <xsl:param name="block-uri" as="xs:anyURI?"/>
        <xsl:param name="writable" as="xs:boolean"/>
        <xsl:param name="turns" as="item()*"/>

        <div class="ldh-chat" data-chat="{$chat-uri}" data-doc="{$doc-uri}">
            <xsl:if test="$ephemeral">
                <xsl:attribute name="data-ephemeral" select="'true'"/>
                <xsl:attribute name="data-block" select="$block-uri"/>
            </xsl:if>
            <div class="ldh-chat-log">
                <xsl:sequence select="$turns"/>
            </div>
            <xsl:if test="$writable">
                <xsl:call-template name="ldh:ChatComposer">
                    <xsl:with-param name="translations" select="ldh:translations()"/>
                </xsl:call-template>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- the composer: the design's Checkbox twice - run a plan as soon as it arrives (reads only - a write always
         waits for Execute), and revise a plan that returned nothing (or failed) by itself, a few times - and the
         question -->
    <xsl:template name="ldh:ChatComposer">
        <xsl:param name="translations" as="document-node()"/>

        <form class="ldh-chat-composer" accept-charset="UTF-8">
            <div class="ldh-chat-options">
                <label class="ac-choice ldh-chat-run">
                    <input type="checkbox" name="run" checked="checked"/>
                    <span class="ac-box">
                        <span class="msi sm" aria-hidden="true">check</span>
                    </span>
                    <span class="ac-choice-body">
                        <span>
                            <xsl:apply-templates select="key('resources', 'execute-by-default', $translations)" mode="ac:label"/>
                        </span>
                    </span>
                </label>
                <label class="ac-choice ldh-chat-auto">
                    <input type="checkbox" name="auto"/>
                    <span class="ac-box">
                        <span class="msi sm" aria-hidden="true">check</span>
                    </span>
                    <span class="ac-choice-body">
                        <span>
                            <xsl:apply-templates select="key('resources', 'retry-on-empty', $translations)" mode="ac:label"/>
                        </span>
                    </span>
                </label>
            </div>
            <div class="ldh-chat-composer-row">
                <div class="ac-field">
                    <div class="ac-field-box sz-md">
                        <textarea rows="2" name="question" placeholder="{ac:label(key('resources', 'chat-placeholder', $translations))}" aria-label="{ac:label(key('resources', 'assistant', $translations))}"/>
                    </div>
                </div>
                <button type="submit" class="ac-btn in-primary ap-solid sz-md" aria-label="{ac:label(key('resources', 'send', $translations))}" title="{ac:label(key('resources', 'send', $translations))}">
                    <span class="msi sm" aria-hidden="true">send</span>
                </button>
            </div>
        </form>
    </xsl:template>

    <!-- A stored chat, as the object block placing it renders it: the typed card's body (resource.xsl) is replaced by
         the conversation, read from the chat's own document - its turns are resources there, not properties of the chat,
         so the row the object block drew does not hold them. The document's acl:mode links say whether the reader may
         continue it -->
    <xsl:template match="*[@typeof = '&ldh;Chat'][@about]" mode="ldh:RowHook" as="function(item()?) as map(*)">
        <xsl:param name="container" select="." as="element()"/>
        <xsl:variable name="chat-uri" select="xs:anyURI(@about)" as="xs:anyURI"/>
        <xsl:variable name="doc-uri" select="ac:document-uri($chat-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($doc-uri, map{}), 'headers': map{ 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }" as="map(*)"/>
        <xsl:variable name="context" select="map{ 'request': $request, 'container': $container, 'chat-uri': $chat-uri, 'doc-uri': $doc-uri }" as="map(*)"/>

        <xsl:sequence select="ldh:load-block#3($context, ldh:chat-self-thunk#1, ?)"/>
    </xsl:template>

    <xsl:function name="ldh:chat-self-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:chat-loaded#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:chat-loaded" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="chat-uri" select="$context('chat-uri')" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="$response?status = 200 and $response?media-type = 'application/rdf+xml'">
                <xsl:variable name="chat" select="key('resources', $chat-uri, $response?body)" as="element()?"/>
                <xsl:variable name="turns" select="ldh:chat-turns($chat)" as="element()*"/>
                <xsl:variable name="card-ids" select="for $turn in $turns return 'chat-' || ac:uuid()" as="xs:string*"/>
                <!-- the chat's document, not the page's: an embedded chat is continued where it is stored -->
                <xsl:variable name="acl-modes" select="ldh:link-targets($response?headers?link, '&acl;mode')" as="xs:anyURI*"/>
                <xsl:variable name="writable" select="exists($acl:agent) and $acl-modes = ('&acl;Append', '&acl;Write')" as="xs:boolean"/>

                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:call-template name="ldh:ChatBody">
                            <xsl:with-param name="chat-uri" select="$chat-uri"/>
                            <xsl:with-param name="doc-uri" select="$context('doc-uri')"/>
                            <xsl:with-param name="writable" select="$writable"/>
                            <xsl:with-param name="turns" as="element()*">
                                <xsl:for-each select="$turns">
                                    <xsl:variable name="position" select="position()" as="xs:integer"/>
                                    <xsl:apply-templates select="." mode="ldh:StoredTurn">
                                        <xsl:with-param name="card-id" select="$card-ids[$position]"/>
                                    </xsl:apply-templates>
                                </xsl:for-each>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:result-document>
                </xsl:for-each>

                <!-- what the cards hold, so Retry, Revise and the next question's history work on a stored turn as on a
                     live one; then the steps, the chart and the labels, which need the card in the page -->
                <xsl:for-each select="$turns">
                    <xsl:variable name="position" select="position()" as="xs:integer"/>
                    <xsl:sequence select="ldh:chat-restore-turn(id($card-ids[$position], ixsl:page()), .)"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:render-block-error($container, 'block-resource-not-loaded', ac:http-error-key($response?status), $chat-uri, $response)"/>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- the chat's turns in order: its rdf:_N members, by N -->
    <xsl:function name="ldh:chat-turns" as="element()*">
        <xsl:param name="chat" as="element()?"/>

        <xsl:for-each select="$chat/rdf:*[starts-with(local-name(), '_')][@rdf:resource]">
            <xsl:sort select="xs:integer(substring-after(local-name(), '_'))"/>
            <xsl:sequence select="key('resources', @rdf:resource, root($chat))"/>
        </xsl:for-each>
    </xsl:function>

    <!-- the next rdf:_N of a resource as a stored document describes it -->
    <xsl:function name="ldh:next-member" as="xs:integer">
        <xsl:param name="resource" as="element()*"/>

        <xsl:sequence select="max((0, for $member in $resource/rdf:*[starts-with(local-name(), '_')] return xs:integer(substring-after(local-name($member), '_')))) + 1"/>
    </xsl:function>

    <!-- an rdf:XMLLiteral as the element it holds: RDF/XML carries a literal as parsed markup, and as escaped text when
         the writer could not; either way it is the same element -->
    <xsl:function name="ldh:xml-literal" as="element()?">
        <xsl:param name="property" as="element()?"/>

        <xsl:sequence select="($property/*[1], for $text in $property[empty(*)][normalize-space()] return parse-xml(string($text))/*)[1]"/>
    </xsl:function>

    <!-- a stored turn, drawn as the live card ended: the question, the answer, the plan's summary, the trace folded under
         its count, and what it returned or wrote - the turn's outcome, not a fresh run of its plan -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;ChatTurn']" mode="ldh:StoredTurn">
        <xsl:param name="card-id" as="xs:string"/>
        <xsl:variable name="plan" select="ldh:xml-literal(ldh:plan)" as="element()?"/>
        <xsl:variable name="execution" select="ldh:xml-literal(ldh:execution)" as="element()?"/>
        <xsl:variable name="operation" select="$plan/*[not(self::wa:summary | self::wa:operations | self::wa:present | self::wa:message)][1]" as="element()?"/>

        <p class="ldh-chat-turn">
            <xsl:value-of select="ldh:question"/>
        </p>
        <div class="ldh-nblock ldh-chat-plan" data-depth="1" id="{$card-id}" data-question="{ldh:question}" data-attempt="0" data-outcome="{ldh:outcome}" data-turn="{@rdf:about}">
            <xsl:for-each select="ldh:answer[normalize-space()]">
                <p class="ldh-chat-answer">
                    <xsl:value-of select="."/>
                </p>
            </xsl:for-each>
            <xsl:if test="normalize-space($plan/wa:summary)">
                <p>
                    <xsl:value-of select="$plan/wa:summary"/>
                </p>
            </xsl:if>
            <xsl:if test="exists($operation)">
                <details class="ldh-chat-trace">
                    <summary>
                        <span class="msi sm chev" aria-hidden="true">chevron_right</span>
                    </summary>
                    <ul class="ldh-chat-steps">
                        <xsl:apply-templates select="$operation" mode="ldh:OperationTree"/>
                    </ul>
                </details>
            </xsl:if>
            <xsl:if test="exists($execution)">
                <xsl:call-template name="ldh:ChatOutcome">
                    <xsl:with-param name="execution" select="$execution"/>
                    <xsl:with-param name="present" select="$plan/wa:present"/>
                    <xsl:with-param name="card-id" select="$card-id"/>
                </xsl:call-template>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- a stored turn's card is given back what a live one holds, and drawn the rest of the way -->
    <xsl:function name="ldh:chat-restore-turn" as="item()*" ixsl:updating="yes">
        <xsl:param name="card" as="element()?"/>
        <xsl:param name="turn" as="element()"/>
        <xsl:variable name="plan" select="ldh:xml-literal($turn/ldh:plan)" as="element()?"/>
        <xsl:variable name="execution" select="ldh:xml-literal($turn/ldh:execution)" as="element()?"/>

        <xsl:for-each select="$card">
            <xsl:if test="exists($plan)">
                <ixsl:set-property name="{$card/@id}" select="$plan" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chat')"/>
            </xsl:if>
            <xsl:if test="exists($execution)">
                <ixsl:set-property name="{$card/@id}" select="$execution" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatExecutions')"/>
                <xsl:variable name="summary" select="ldh:execution-summary($execution)" as="map(*)"/>
                <xsl:if test="not($summary?failed) and exists($summary?result)">
                    <ixsl:set-property name="{$card/@id}" select="$execution/wa:result" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults')"/>
                </xsl:if>
                <xsl:sequence select="ldh:chat-steps($card, $execution)"/>
                <xsl:sequence select="ldh:chat-draw-chart($card, $execution, $plan/wa:present)"/>
                <xsl:sequence select="ldh:chat-label-rows($card, $execution, false())"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>

    <!-- THE EPHEMERAL BLOCK -->

    <!-- The bar's Assistant button starts a conversation: a chat block before the bar, headed as a block is, holding an
         empty log and its composer, which takes the focus. Nothing is written until the first question (ldh:ChatAsk), so
         its URIs are minted now and the block carries no @about - it is not a member of the document yet. Every press
         starts another; one left empty is closed with its x, or with Escape from its composer -->
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'ldh-chat-open')]]" mode="ixsl:onclick">
        <xsl:variable name="dock" select="ancestor::div[contains-token(@class, 'ldh-create-dock')][1]" as="element()"/>
        <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:base-uri($dock))" as="xs:anyURI"/>
        <xsl:variable name="uuid" select="ac:uuid()" as="xs:string"/>
        <xsl:variable name="chat-uri" select="xs:anyURI($doc-uri || '#chat-' || $uuid)" as="xs:anyURI"/>

        <xsl:for-each select="$dock">
            <xsl:result-document href="?." method="ixsl:insert-before">
                <xsl:call-template name="ldh:ChatEphemeral">
                    <xsl:with-param name="chat-uri" select="$chat-uri"/>
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="block-uri" select="xs:anyURI($doc-uri || '#block-' || $uuid)"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:for-each select="$dock/preceding-sibling::div[contains-token(@class, 'ldh-chat-ephemeral')][1]">
            <xsl:sequence select="ldh:chat-scroll(.)"/>
            <xsl:sequence select="ixsl:call((.//textarea)[1], 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="ldh:ChatEphemeral">
        <xsl:param name="chat-uri" as="xs:anyURI"/>
        <xsl:param name="doc-uri" as="xs:anyURI"/>
        <xsl:param name="block-uri" as="xs:anyURI"/>
        <xsl:variable name="translations" select="ldh:translations()" as="document-node()"/>

        <div class="ldh-block-row ldh-chat-ephemeral">
            <div class="row-main">
                <div class="block ldh-block">
                    <!-- the kit's one block header (BlockHeader, compact density): icon, title, and the actions cluster
                         holding the x that closes the block -->
                    <div class="ldh-block-head ldh-res-head" data-density="compact">
                        <span class="ldh-res-icon">
                            <span class="msi outline" aria-hidden="true">forum</span>
                        </span>
                        <div class="ldh-res-text">
                            <div class="ldh-res-titleline">
                                <h3 class="ttl">
                                    <xsl:apply-templates select="key('resources', 'assistant', $translations)" mode="ac:label"/>
                                </h3>
                            </div>
                        </div>
                        <div class="actions">
                            <button type="button" class="ac-iconbtn sz-sm in-neutral ap-ghost ldh-chat-close" aria-label="{ac:label(key('resources', 'close', $translations))}" title="{ac:label(key('resources', 'close', $translations))}">
                                <span class="msi sm" aria-hidden="true">close</span>
                            </button>
                        </div>
                    </div>
                    <div class="block-row" typeof="&ldh;Chat">
                        <div class="main ldh-block-body">
                            <xsl:call-template name="ldh:ChatBody">
                                <xsl:with-param name="chat-uri" select="$chat-uri"/>
                                <xsl:with-param name="doc-uri" select="$doc-uri"/>
                                <xsl:with-param name="ephemeral" select="true()"/>
                                <xsl:with-param name="block-uri" select="$block-uri"/>
                                <xsl:with-param name="writable" select="true()"/>
                            </xsl:call-template>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- the x closes a block nothing was asked in; once asked, the block is the document's and is removed as any block is -->
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'ldh-chat-close')]]" mode="ixsl:onclick">
        <xsl:for-each select="ancestor::div[contains-token(@class, 'ldh-chat-ephemeral')][1]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>

    <!-- The first question makes the chat the document's: one write adds the chat, the object block that places it, and
         the block as the document's next rdf:_N - read from the document as stored, which is also where the write's
         validator comes from. The block is then an ordinary member of the document, and the question goes on -->
    <xsl:function name="ldh:chat-create" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($doc-uri, map{}), 'headers': map{ 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }" as="map(*)"/>

        <xsl:sequence select="
            ixsl:http-request($request) =>
                ixsl:then(ldh:rethread-response($context, ?, 'doc-response')) =>
                ixsl:then(ldh:handle-response(?, 'doc-response')) =>
                ixsl:then(ldh:chat-create-request#1) =>
                ixsl:then(ldh:http-request-threaded(?, 'write-request', 'write-response')) =>
                ixsl:then(ldh:chat-created#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:chat-create-request" as="map(*)">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('doc-response')" as="map(*)"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="chat" select="$context('chat')" as="element()"/>
        <xsl:variable name="chat-uri" select="xs:anyURI($chat/@data-chat)" as="xs:anyURI"/>
        <xsl:variable name="block-uri" select="xs:anyURI($chat/@data-block)" as="xs:anyURI"/>

        <xsl:if test="not($response?status = 200 and $response?media-type = 'application/rdf+xml')">
            <xsl:sequence select="ldh:response-error($response)"/>
        </xsl:if>
        <xsl:variable name="member" select="ldh:next-member(key('resources', $doc-uri, $response?body))" as="xs:integer"/>
        <xsl:variable name="body" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:about="{$doc-uri}">
                        <xsl:element name="rdf:_{$member}" namespace="&rdf;">
                            <xsl:attribute name="rdf:resource" select="$block-uri"/>
                        </xsl:element>
                    </rdf:Description>
                    <rdf:Description rdf:about="{$block-uri}">
                        <rdf:type rdf:resource="&ldh;Object"/>
                        <rdf:value rdf:resource="{$chat-uri}"/>
                    </rdf:Description>
                    <rdf:Description rdf:about="{$chat-uri}">
                        <rdf:type rdf:resource="&ldh;Chat"/>
                        <!-- the conversation is named by what started it -->
                        <dct:title>
                            <xsl:value-of select="ldh:chat-title($context('question'))"/>
                        </dct:title>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>

        <xsl:sequence select="map:put($context, 'write-request', map{ 'method': 'POST', 'href': ldh:href($doc-uri, map{}), 'media-type': 'application/rdf+xml', 'body': $body, 'headers': ldh:conditional-headers(map{}, $response?headers?etag) })"/>
    </xsl:function>

    <!-- a question as a title: its first line, cut at a word near 80 characters -->
    <xsl:function name="ldh:chat-title" as="xs:string">
        <xsl:param name="question" as="xs:string"/>

        <xsl:sequence select="if (string-length($question) le 80) then $question else replace(substring($question, 1, 80), '\s+\S*$', '') || '…'"/>
    </xsl:function>

    <!-- written: the block is the document's, addressed as one, and the question goes on to the plan service -->
    <xsl:function name="ldh:chat-created" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('write-response')" as="map(*)"/>
        <xsl:variable name="chat" select="$context('chat')" as="element()"/>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 201, 204)">
                <xsl:sequence select="ldh:set-document-etag($context('doc-uri'), $response?headers?etag)"/>
                <xsl:for-each select="$chat/ancestor::div[contains-token(@class, 'ldh-chat-ephemeral')][1]">
                    <ixsl:set-attribute name="about" select="$chat/@data-block"/>
                    <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'ldh-chat-ephemeral', false())"/>
                    <xsl:for-each select=".//button[contains-token(@class, 'ldh-chat-close')]">
                        <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                    <xsl:for-each select=".//div[contains-token(@class, 'block-row')][@typeof = '&ldh;Chat']">
                        <ixsl:set-attribute name="about" select="$chat/@data-chat"/>
                    </xsl:for-each>
                </xsl:for-each>
                <xsl:for-each select="$chat">
                    <ixsl:remove-attribute name="data-ephemeral"/>
                    <ixsl:remove-attribute name="data-block"/>
                </xsl:for-each>

                <xsl:sequence select="ldh:chat-plan($context)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- STORING A TURN -->

    <!-- A turn is written when it has ended - its answer landed, or could not - as a resource of the chat's document and
         the chat's next rdf:_N: the question, the answer, the plan, what the execution reported with its result capped,
         and how it went. Then the page catches up with what the plan wrote, which renders the block again from the store,
         so the turn has to be there first. A turn that cannot be written says so in its card and stays where it is -->
    <xsl:function name="ldh:chat-store-turn" as="item()*" ixsl:updating="yes">
        <xsl:param name="card" as="element()"/>
        <xsl:variable name="chat" select="ldh:chat-of($card)" as="element()?"/>

        <xsl:if test="exists($chat) and not($chat/@data-ephemeral) and not($card/@data-turn)">
            <xsl:variable name="doc-uri" select="xs:anyURI($chat/@data-doc)" as="xs:anyURI"/>
            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': ldh:href($doc-uri, map{}), 'headers': map{ 'Accept': 'application/rdf+xml', 'Cache-Control': 'no-cache' } }" as="map(*)"/>
            <xsl:variable name="context" select="map{ 'doc-request': $request, 'doc-uri': $doc-uri, 'chat': $chat, 'card': $card, 'form': ldh:chat-form($chat) }" as="map(*)"/>

            <ixsl:promise select="
              ldh:http-request-threaded($context, 'doc-request', 'doc-response')
                => ixsl:then(ldh:handle-response(?, 'doc-response'))
                => ixsl:then(ldh:chat-turn-request#1)
                => ixsl:then(ldh:http-request-threaded(?, 'write-request', 'write-response'))
                => ixsl:then(ldh:chat-turn-stored#1)
            " on-failure="ldh:chat-failure($context, 'chat-not-saved', ?)"/>
        </xsl:if>
    </xsl:function>

    <xsl:function name="ldh:chat-turn-request" as="map(*)">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('doc-response')" as="map(*)"/>
        <xsl:variable name="doc-uri" select="$context('doc-uri')" as="xs:anyURI"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="chat-uri" select="xs:anyURI($context('chat')/@data-chat)" as="xs:anyURI"/>
        <xsl:variable name="turn-uri" select="xs:anyURI($doc-uri || '#turn-' || ac:uuid())" as="xs:anyURI"/>
        <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="execution" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chatExecutions'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chatExecutions'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="answer" select="normalize-space(string-join($card/p[contains-token(@class, 'ldh-chat-answer')]))" as="xs:string"/>

        <xsl:if test="not($response?status = 200 and $response?media-type = 'application/rdf+xml')">
            <xsl:sequence select="ldh:response-error($response)"/>
        </xsl:if>
        <xsl:variable name="member" select="ldh:next-member(key('resources', $chat-uri, $response?body))" as="xs:integer"/>
        <xsl:variable name="body" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description rdf:about="{$chat-uri}">
                        <xsl:element name="rdf:_{$member}" namespace="&rdf;">
                            <xsl:attribute name="rdf:resource" select="$turn-uri"/>
                        </xsl:element>
                    </rdf:Description>
                    <rdf:Description rdf:about="{$turn-uri}">
                        <rdf:type rdf:resource="&ldh;ChatTurn"/>
                        <ldh:question>
                            <xsl:value-of select="$card/@data-question"/>
                        </ldh:question>
                        <xsl:if test="$answer">
                            <ldh:answer>
                                <xsl:value-of select="$answer"/>
                            </ldh:answer>
                        </xsl:if>
                        <!-- the literals travel escaped, as text typed rdf:XMLLiteral, never as rdf:parseType="Literal" markup: a
                             result that is a graph is an rdf:RDF element, and Jena's RDF/XML parser refuses an rdf:RDF inside a
                             literal ("Inconsistent parserMode:TOP") - the whole write answered 400 for a turn whose plan had read
                             one. ldh:xml-literal reads either form back -->
                        <xsl:for-each select="$plan">
                            <ldh:plan rdf:datatype="&rdf;XMLLiteral">
                                <xsl:value-of select="serialize(., map{ 'method': 'xml' })"/>
                            </ldh:plan>
                        </xsl:for-each>
                        <xsl:for-each select="$execution">
                            <xsl:variable name="capped" as="element()">
                                <xsl:apply-templates select="." mode="ldh:CapExecution"/>
                            </xsl:variable>
                            <ldh:execution rdf:datatype="&rdf;XMLLiteral">
                                <xsl:value-of select="serialize($capped, map{ 'method': 'xml' })"/>
                            </ldh:execution>
                        </xsl:for-each>
                        <xsl:for-each select="$card/@data-outcome[normalize-space()]">
                            <ldh:outcome>
                                <xsl:value-of select="."/>
                            </ldh:outcome>
                        </xsl:for-each>
                        <dct:created rdf:datatype="&xsd;dateTime">
                            <xsl:value-of select="adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration('PT0H'))"/>
                        </dct:created>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>

        <xsl:sequence select="map:merge(($context, map{ 'turn-uri': $turn-uri, 'write-request': map{ 'method': 'POST', 'href': ldh:href($doc-uri, map{}), 'media-type': 'application/rdf+xml', 'body': $body, 'headers': ldh:conditional-headers(map{}, $response?headers?etag) } }), map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <!-- a stored result is a snapshot, capped: the first hundred rows of a result set, the first hundred resources of a
         graph. Enough to show the turn again, and to tell the next question what "them" were -->
    <xsl:template match="@* | node()" mode="ldh:CapExecution">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="srx:results/srx:result[position() gt 100]" mode="ldh:CapExecution"/>

    <xsl:template match="wa:result/rdf:RDF/*[position() gt 100]" mode="ldh:CapExecution"/>

    <xsl:function name="ldh:chat-turn-stored" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('write-response')" as="map(*)"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>

        <xsl:choose>
            <xsl:when test="$response?status = (200, 201, 204)">
                <xsl:sequence select="ldh:set-document-etag($context('doc-uri'), $response?headers?etag)"/>
                <xsl:for-each select="$card">
                    <ixsl:set-attribute name="data-turn" select="$context('turn-uri')"/>
                </xsl:for-each>
                <xsl:sequence select="ldh:chat-catch-up($card)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- The page catches up with what the plan wrote: every written document's cached copy goes, and the document being
         read is loaded again - a block on it may list what a new document changed, so the writes are not narrowed to its
         own URI. What the assistant writes is content - blocks - and only ContentMode shows a document's blocks, so a
         document it wrote to comes back in that mode, whatever mode it was being read in -->
    <xsl:function name="ldh:chat-catch-up" as="item()*" ixsl:updating="yes">
        <xsl:param name="card" as="element()"/>
        <xsl:variable name="execution" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chatExecutions'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chatExecutions'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="written" select="distinct-values($execution/wa:written/wa:document/@uri)" as="xs:anyURI*"/>

        <xsl:for-each select="$written">
            <ixsl:remove-property name="{'`' || . || '`'}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:for-each>
        <xsl:if test="exists($written) and exists($card/ancestor::body)">
            <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI"/>
            <ixsl:remove-property name="{'`' || $doc-uri || '`'}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>

            <!-- the navigation is written for a click, with a context node; the card stands in for one -->
            <xsl:for-each select="$card">
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="query-params" select="if ($written = $doc-uri) then map:put(map:remove(ldh:query-params(), 'uri'), 'mode', '&ldh;ContentMode') else map:remove(ldh:query-params(), 'uri')"/>
                    <xsl:with-param name="push-state" select="false()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

    <!-- THE COMPOSER -->

    <!-- Enter sends, Shift+Enter breaks the line; Escape from the composer of a block nothing was asked in closes the
         block. keydown, not keyup: the default that inserts the newline fires on keydown, and only the event carrying a
         default can prevent it -->
    <xsl:template match="textarea[ancestor::form[contains-token(@class, 'ldh-chat-composer')]]" mode="ixsl:onkeydown">
        <xsl:variable name="key" select="ixsl:get(ixsl:event(), 'key')" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$key = 'Enter' and not(ixsl:get(ixsl:event(), 'shiftKey'))">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:apply-templates select="ancestor::form[contains-token(@class, 'ldh-chat-composer')][1]" mode="ixsl:onsubmit"/>
            </xsl:when>
            <xsl:when test="$key = 'Escape'">
                <xsl:for-each select="ancestor::div[contains-token(@class, 'ldh-chat-ephemeral')][1][empty(.//div[contains-token(@class, 'ldh-chat-log')]/*)]">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="form[contains-token(@class, 'ldh-chat-composer')]" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="textarea" select="(.//textarea)[1]" as="element()"/>
        <xsl:variable name="question" select="normalize-space(ixsl:get($textarea, 'value'))" as="xs:string"/>

        <!-- nothing asked, nothing sent -->
        <xsl:if test="$question">
            <ixsl:set-property name="value" select="''" object="$textarea"/>
            <xsl:call-template name="ldh:ChatAsk">
                <xsl:with-param name="form" select="."/>
                <xsl:with-param name="question" select="$question"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- A question goes to the plan service with where the reader is and what this conversation has already tried:
         every card of this chat that ran, with its plan and how it went, so a plan that returned nothing is not proposed
         again (the last few only - the prompt is not the place for a whole afternoon). The reply becomes the new card.
         The first question of a chat block that is not written yet writes it first (ldh:chat-create) -->
    <xsl:template name="ldh:ChatAsk">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="question" as="xs:string"/>
        <!-- 0 when the reader asked; counts up when the assistant asks again by itself, so it stops asking -->
        <xsl:param name="attempt" select="0" as="xs:integer"/>
        <xsl:variable name="chat" select="ldh:chat-of($form)" as="element()"/>
        <xsl:variable name="log" select="ldh:chat-log($chat)" as="element()"/>
        <xsl:variable name="card-id" select="'chat-' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="history" as="array(*)" select="array { for $card in ($log/div[contains-token(@class, 'ldh-chat-plan')][@data-outcome])[position() gt last() - 3] return ldh:chat-turn($card) }"/>

        <xsl:for-each select="$log">
            <xsl:result-document href="?." method="ixsl:append-content">
                <p class="ldh-chat-turn">
                    <xsl:value-of select="$question"/>
                </p>
                <div class="ldh-nblock ldh-chat-plan" data-depth="1" id="{$card-id}" data-question="{$question}" data-attempt="{$attempt}">
                    <xsl:sequence select="ldh:chat-progress('thinking', ())"/>
                </div>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:sequence select="ldh:chat-scroll(id($card-id, ixsl:page()))"/>

        <xsl:apply-templates select="$form" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="false()"/>
        </xsl:apply-templates>
        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- where the reader is: the document in the address bar, its dataspace's endpoint and the dataspace's ontology, the
             context a plan against this instance needs. Read now rather than stamped at render, since navigation moves them -->
        <xsl:variable name="ontology" select="if (exists(lds:ontology())) then map{ 'ontology': string(lds:ontology()) } else map{}" as="map(xs:string, xs:string)"/>
        <xsl:variable name="body" select="serialize(map:merge((map{ 'question': $question, 'document': string(ac:absolute-path(ldh:request-uri())), 'endpoint': string(sd:endpoint()), 'history': $history }, $ontology)), map{ 'method': 'json' })" as="xs:string"/>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:chat-href('webalgebra/plans'), 'media-type': 'application/json', 'body': $body, 'headers': map{ 'Accept': 'application/xml' } }" as="map(*)"/>
        <xsl:variable name="context" select="map{ 'request': $request, 'card': id($card-id, ixsl:page()), 'form': $form, 'chat': $chat, 'doc-uri': xs:anyURI($chat/@data-doc), 'question': $question }" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="$chat/@data-ephemeral">
                <ixsl:promise select="ixsl:resolve($context) => ixsl:then(ldh:chat-create#1) => ixsl:finally(ldh:reset-cursor#0)" on-failure="ldh:chat-failure($context, 'chat-not-saved', ?)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:chat-plan($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- the question to the plan service; the reply becomes the card's plan -->
    <xsl:function name="ldh:chat-plan" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:plan-response#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:chat-failure($context, 'plan-not-generated', ?)"/>
    </xsl:function>

    <!-- one earlier turn as the plan service hears it: the question, the operation that ran, what came of it -->
    <xsl:function name="ldh:chat-turn" as="map(*)">
        <xsl:param name="card" as="element()"/>
        <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="operation" select="$plan/*[not(self::wa:summary | self::wa:operations | self::wa:present | self::wa:message)][1]" as="element()?"/>

        <xsl:variable name="result" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults'), string($card/@id)) else ()" as="element()?"/>

        <xsl:sequence select="map:merge((map{ 'question': string($card/@data-question), 'plan': (for $op in $operation return serialize($op, map{ 'method': 'xml' })), 'outcome': string($card/@data-outcome) }, for $values in ldh:result-values($result) return map{ 'result': $values }))"/>
    </xsl:function>

    <!-- what a plan returned, as a SPARQL VALUES block the next plan can carry verbatim: "them" in a follow-up is
         these rows, and a SELECT over an empty graph with this block yields them again, where a new query might not.
         A result set is one tuple per row in its variables' order; a graph is its described resources; a value is
         itself. Capped, with the cut announced, so a large result does not become the prompt -->
    <xsl:function name="ldh:result-values" as="xs:string?">
        <xsl:param name="result" as="element()?"/>
        <xsl:variable name="cap" select="100" as="xs:integer"/>
        <xsl:variable name="blocks" as="xs:string*">
            <xsl:for-each select="$result/srx:sparql[srx:results/srx:result][not(ldh:write-report(.))]">
                <xsl:variable name="vars" select="srx:head/srx:variable/@name" as="xs:string*"/>
                <xsl:variable name="rows" select="srx:results/srx:result" as="element()*"/>
                <xsl:sequence select="'VALUES (' || string-join(for $v in $vars return '?' || $v, ' ') || ') {' || codepoints-to-string(10) || string-join(for $row in $rows[position() le $cap] return '  (' || string-join(for $v in $vars return ldh:sparql-term($row/srx:binding[@name = $v]), ' ') || ')', codepoints-to-string(10)) || codepoints-to-string(10) || '}' || (if (count($rows) gt $cap) then codepoints-to-string(10) || '# and ' || (count($rows) - $cap) || ' more rows not shown' else '')"/>
            </xsl:for-each>
            <xsl:for-each select="$result/rdf:RDF[rdf:Description/@rdf:about]">
                <xsl:variable name="resources" select="rdf:Description/@rdf:about" as="xs:string*"/>
                <xsl:sequence select="'VALUES ?resource {' || codepoints-to-string(10) || string-join(for $r in $resources[position() le $cap] return '  &lt;' || $r || '&gt;', codepoints-to-string(10)) || codepoints-to-string(10) || '}' || (if (count($resources) gt $cap) then codepoints-to-string(10) || '# and ' || (count($resources) - $cap) || ' more not shown' else '')"/>
            </xsl:for-each>
            <xsl:if test="exists($result/wa:value)">
                <xsl:sequence select="'VALUES ?value {' || codepoints-to-string(10) || string-join(for $v in $result/wa:value[position() le $cap] return '  ' || ldh:sparql-literal(string($v)), codepoints-to-string(10)) || codepoints-to-string(10) || '}'"/>
            </xsl:if>
        </xsl:variable>

        <xsl:sequence select="if (exists($blocks)) then string-join($blocks, codepoints-to-string(10) || codepoints-to-string(10)) else ()"/>
    </xsl:function>

    <!-- one binding of a result row as a SPARQL term; an unbound variable or a blank node is UNDEF, since neither
         can be written into VALUES -->
    <xsl:function name="ldh:sparql-term" as="xs:string">
        <xsl:param name="binding" as="element()?"/>

        <xsl:sequence select="
          if (empty($binding) or $binding/srx:bnode) then 'UNDEF'
          else if ($binding/srx:uri) then '&lt;' || $binding/srx:uri || '&gt;'
          else if ($binding/srx:literal/@xml:lang) then ldh:sparql-literal(string($binding/srx:literal)) || '@' || $binding/srx:literal/@xml:lang
          else if ($binding/srx:literal/@datatype) then ldh:sparql-literal(string($binding/srx:literal)) || '^^&lt;' || $binding/srx:literal/@datatype || '&gt;'
          else ldh:sparql-literal(string($binding/srx:literal))"/>
    </xsl:function>

    <!-- a string as a quoted SPARQL literal, escaped per the grammar -->
    <xsl:function name="ldh:sparql-literal" as="xs:string">
        <xsl:param name="value" as="xs:string"/>

        <xsl:sequence select="'&quot;' || replace(replace(replace(replace($value, '\\', '\\\\'), '&quot;', '\\&quot;'), codepoints-to-string(10), '\\n'), codepoints-to-string(13), '\\r') || '&quot;'"/>
    </xsl:function>

    <!-- Revise: the same question again, now with this card in the history - a plan that returned nothing or failed
         is what the service is told not to repeat -->
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'ldh-chat-revise')]]" mode="ixsl:onclick">
        <xsl:variable name="card" select="ancestor::div[contains-token(@class, 'ldh-chat-plan')][1]" as="element()"/>

        <xsl:call-template name="ldh:ChatAsk">
            <xsl:with-param name="form" select="ldh:chat-form(ldh:chat-of($card))"/>
            <xsl:with-param name="question" select="string($card/@data-question)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- the composer is disabled while a request of its own is in flight, so a question is answered before the next
         one is asked; a plan waiting for Execute leaves it open -->
    <xsl:template match="form[contains-token(@class, 'ldh-chat-composer')]" mode="ldh:ComposerEnabled">
        <xsl:param name="enabled" as="xs:boolean"/>

        <xsl:for-each select=".//div[contains-token(@class, 'ac-field-box')] | .//button">
            <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-disabled', not($enabled))"/>
        </xsl:for-each>
        <xsl:for-each select=".//textarea | .//button">
            <xsl:choose>
                <xsl:when test="$enabled">
                    <ixsl:remove-attribute name="disabled"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-attribute name="disabled" select="'disabled'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:if test="$enabled">
            <xsl:sequence select="ixsl:call((.//textarea)[1], 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- THE PLAN -->

    <!-- The plan service answers with an envelope: a summary, the operations the plan invokes, and the operation
         element itself, already checked against the executor. An envelope holding a message instead is a reply when
         the status is 200 - the service declining, in words - and is shown as one. On any other status the message
         is the service's reason for failing (a plan refused by the validator, with the parser's line and column), and
         it reports as the failure it is, with the reason as the detail, where Revise can act on it. -->
    <xsl:function name="ldh:plan-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="plan" select="$response?body/wa:plan" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$response?status = 200 and exists($plan/*[not(self::wa:summary | self::wa:operations | self::wa:present | self::wa:message)])">
                <!-- the card keeps its plan under its own id: Execute on this card runs this plan, whatever was asked since -->
                <ixsl:set-property name="{$card/@id}" select="$plan" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chat')"/>

                <xsl:for-each select="$card">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:apply-templates select="$plan" mode="ldh:PlanCard"/>
                    </xsl:result-document>
                </xsl:for-each>

                <!-- a plan runs on arrival when the reader asked for that (Execute by default), and a revision the assistant
                     asked for by itself always does - in both cases only when every operation in it reads. One that writes
                     waits for Execute like any other, whatever the checkboxes say: a write cannot be taken back -->
                <xsl:variable name="run" select="ixsl:get(($context('form')//input[@name = 'run'])[1], 'checked')" as="xs:boolean"/>
                <xsl:if test="($run or xs:integer($card/@data-attempt) gt 0) and (every $name in $plan/wa:operations/wa:operation/@name satisfies ldh:operation-kind($name) = 'read')">
                    <xsl:call-template name="ldh:ChatExecute">
                        <xsl:with-param name="card" select="$card"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:when>
            <!-- the service declining, in words: that is the turn's answer, and the turn is stored with it -->
            <xsl:when test="$response?status = 200 and exists($plan/wa:message)">
                <xsl:for-each select="$card">
                    <ixsl:set-attribute name="data-outcome" select="'declined'"/>
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <p class="ldh-chat-answer">
                            <xsl:value-of select="$plan/wa:message"/>
                        </p>
                    </xsl:result-document>
                </xsl:for-each>
                <xsl:sequence select="ldh:chat-store-turn($card)"/>
            </xsl:when>
            <!-- the service's own words beat the status line as the detail; the chain's on-failure reports it in the card -->
            <xsl:when test="exists($plan/wa:message)">
                <xsl:sequence select="error(QName('&ldh;', 'ldh:ResponseError'), string($plan/wa:message), $response)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:apply-templates select="$context('form')" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="true()"/>
        </xsl:apply-templates>
        <xsl:sequence select="ldh:chat-scroll($card)"/>
    </xsl:function>

    <!-- the plan card: what the plan does in a sentence, its operations as the rows they will be executed as, the
         document itself for anyone who wants to read it, and the two things that can happen to it. The operation is
         the envelope's one child that is not envelope: every element of a plan is in the Web-Algebra namespace, so it
         is told apart by name and never by wa:* -->
    <xsl:template match="wa:plan" mode="ldh:PlanCard">
        <xsl:variable name="operation" select="*[not(self::wa:summary | self::wa:operations | self::wa:present | self::wa:message)][1]" as="element()"/>

        <xsl:if test="normalize-space(wa:summary)">
            <p>
                <xsl:value-of select="wa:summary"/>
            </p>
        </xsl:if>
        <!-- the trace: the same rows execution reports into - an operation is a step that has not run yet. The rows
             nest as the operations do, and each folds out its own operation's XML - the first, the outermost, the whole
             plan. Open while the plan is being read and run, since the rows are what there is to see; folded under its
             count once the answer has been written, which is then what there is to read -->
        <details class="ldh-chat-trace" open="">
            <summary>
                <span class="msi sm chev" aria-hidden="true">chevron_right</span>
                <xsl:value-of select="count(ldh:plan-operations($operation))"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="key('resources', 'chat-steps', ldh:translations())" mode="ac:label"/>
            </summary>
            <ul class="ldh-chat-steps">
                <xsl:apply-templates select="$operation" mode="ldh:OperationTree"/>
            </ul>
        </details>
        <div class="ldh-chat-plan-actions">
            <button type="button" class="ac-btn in-primary ap-solid sz-md ldh-chat-execute">
                <span class="msi sm" aria-hidden="true">play_arrow</span>
                <span>
                    <xsl:apply-templates select="key('resources', 'execute', ldh:translations())" mode="ac:label"/>
                </span>
            </button>
            <button type="button" class="ac-btn in-neutral ap-outline sz-md ldh-chat-cancel">
                <span>
                    <xsl:apply-templates select="key('resources', 'cancel', ldh:translations())" mode="ac:label"/>
                </span>
            </button>
        </div>
    </xsl:template>

    <!-- an operation before it runs: its glyph says what it does to data (reads, writes, can take away), its state
         says it is planned. Once the executor reports, the same row is a wa:step -->
    <!-- an operation before it runs, with the operations inside its arguments nested under it: its glyph says what it
         does to data (reads, writes, can take away), its state says it is planned. Once the executor reports, the same
         row is a wa:step -->
    <xsl:template match="*" mode="ldh:OperationTree">
        <xsl:variable name="kind" select="ldh:operation-kind(ldh:operation-name(.))" as="xs:string"/>
        <xsl:variable name="nested" select="ldh:nested-operations(.)" as="element()*"/>

        <li>
            <details class="ldh-chat-step is-planned kd-{$kind}">
                <summary>
                    <span class="st msi sm" aria-hidden="true">
                        <xsl:value-of select="map{ 'read': 'visibility', 'write': 'edit', 'destructive': 'warning' }($kind)"/>
                    </span>
                    <span class="op">
                        <xsl:value-of select="ldh:operation-name(.)"/>
                    </span>
                    <span class="mono muted"/>
                </summary>
                <xsl:sequence select="ldh:step-xml(.)"/>
            </details>
            <xsl:if test="exists($nested)">
                <ul>
                    <xsl:apply-templates select="$nested" mode="ldh:OperationTree"/>
                </ul>
            </xsl:if>
        </li>
    </xsl:template>

    <!-- the operations directly inside an operation. Arguments are the children and the operations are the
         arguments' children in the algebra's namespace, anything else there being inline data - except for the
         sequence form and a Variable, whose steps and value stand directly under them -->
    <xsl:function name="ldh:nested-operations" as="element()*">
        <xsl:param name="operation" as="element()"/>

        <xsl:sequence select="if ($operation/self::wa:Sequence or $operation/self::wa:Variable) then $operation/*[namespace-uri() = ('&wa;', '&waldh;')] else $operation/*/*[namespace-uri() = ('&wa;', '&waldh;')]"/>
    </xsl:function>

    <!-- how the service names an operation: the algebra's own bare, LinkedDataHub's with the family's prefix, as
         wa:operation/@name and wa:step/@operation carry it -->
    <xsl:function name="ldh:operation-name" as="xs:string">
        <xsl:param name="operation" as="element()"/>

        <xsl:sequence select="if (namespace-uri($operation) = '&waldh;') then 'waldh:' || local-name($operation) else local-name($operation)"/>
    </xsl:function>

    <!-- the operation elements of a plan in the order the service lists them: an operation, then the operations
         inside it, depth first -->
    <xsl:function name="ldh:plan-operations" as="element()*">
        <xsl:param name="operation" as="element()"/>

        <xsl:sequence select="$operation, for $child in ldh:nested-operations($operation) return ldh:plan-operations($child)"/>
    </xsl:function>

    <!-- the bytes that will be (or were) executed, not a rendering of them -->
    <xsl:function name="ldh:step-xml" as="element()?">
        <xsl:param name="operation" as="element()?"/>

        <xsl:for-each select="$operation">
            <div class="ac-codefield">
                <pre>
                    <xsl:value-of select="serialize(., map{ 'method': 'xml', 'indent': true() })"/>
                </pre>
            </div>
        </xsl:for-each>
    </xsl:function>

    <!-- what an operation does to data, by name: the algebra's writes and the waldh: family's creations and additions
         change documents, PATCH and the removals can take content away, everything else only reads -->
    <xsl:function name="ldh:operation-kind" as="xs:string">
        <xsl:param name="name" as="xs:string"/>

        <xsl:sequence select="
          if ($name = ('PATCH', 'DELETE', 'waldh:RemoveBlock')) then 'destructive'
          else if ($name = ('PUT', 'POST') or starts-with($name, 'waldh:Create') or starts-with($name, 'waldh:Add')) then 'write'
          else 'read'"/>
    </xsl:function>

    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'ldh-chat-cancel') or contains-token(@class, 'ldh-chat-dismiss')]]" mode="ixsl:onclick">
        <xsl:variable name="card" select="ancestor::div[contains-token(@class, 'ldh-chat-plan')][1]" as="element()"/>
        <xsl:variable name="form" select="ldh:chat-form(ldh:chat-of($card))" as="element()?"/>

        <ixsl:remove-property name="{$card/@id}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chat')"/>
        <ixsl:remove-property name="{$card/@id}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults')"/>
        <xsl:sequence select="ixsl:call($card, 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:apply-templates select="$form" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="true()"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- EXECUTION -->

    <!-- Execute (and Retry, which is the same button on a failed card) submits the card's plan and follows the
         execution until it ends. The description above the actions stays; what a previous attempt reported goes -->
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'ldh-chat-execute')]]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ChatExecute">
            <xsl:with-param name="card" select="ancestor::div[contains-token(@class, 'ldh-chat-plan')][1]"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="ldh:ChatExecute">
        <xsl:param name="card" as="element()"/>
        <xsl:variable name="form" select="ldh:chat-form(ldh:chat-of($card))" as="element()?"/>
        <xsl:variable name="plan" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))" as="element()"/>
        <xsl:variable name="operation" select="$plan/*[not(self::wa:summary | self::wa:operations | self::wa:present | self::wa:message)][1]" as="element()"/>

        <!-- the actions and what a previous attempt reported - everything after the rows - go; the rows go back to
             planned and report anew -->
        <xsl:for-each select="$card/*[preceding-sibling::details[contains-token(@class, 'ldh-chat-trace')]] | $card/div[contains-token(@class, 'ac-pbar')] | $card/p[contains-token(@class, 'ldh-chat-answer')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:for-each select="$card/details[contains-token(@class, 'ldh-chat-trace')]">
            <ixsl:set-attribute name="open" select="''"/>
            <xsl:for-each select="ul[contains-token(@class, 'ldh-chat-steps')]">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:apply-templates select="$operation" mode="ldh:OperationTree"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select="$card/p[1]">
            <xsl:result-document href="?." method="ixsl:insert-after">
                <xsl:sequence select="ldh:chat-progress('executing', '')"/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:apply-templates select="$form" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="false()"/>
        </xsl:apply-templates>
        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- an XML body travels as a document node, which ixsl:http-request serializes itself: the same bytes the card shows -->
        <xsl:variable name="body" as="document-node()">
            <xsl:document>
                <xsl:copy-of select="$operation"/>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:chat-href('webalgebra'), 'media-type': 'application/xml', 'body': $body, 'headers': map{ 'Accept': 'application/xml' } }" as="map(*)"/>
        <xsl:variable name="context" select="map{ 'request': $request, 'card': $card, 'form': $form }" as="map(*)"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:execution-response#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:chat-failure($context, 'execution-not-started', ?)"/>
    </xsl:template>

    <!-- 202: the execution has an id, and its result is polled from here on -->
    <xsl:function name="ldh:execution-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="id" select="$response?body/wa:execution/wa:id" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="$response?status = 202 and $id">
                <xsl:variable name="result-request" select="map{ 'method': 'GET', 'href': ldh:chat-href('webalgebra/' || $id || '/result'), 'headers': map{ 'Accept': 'application/xml' } }" as="map(*)"/>
                <xsl:sequence select="ldh:poll-execution(map:put($context, 'result-request', $result-request))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- a second between polls: the steps arrive as they happen, and a plan is seconds to minutes long -->
    <xsl:function name="ldh:poll-execution" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="
          ixsl:sleep(1000)
            => ixsl:then(ldh:result-request($context, ?))
        "/>
    </xsl:function>

    <!-- 'result-request'/'result-response' rather than 'request'/'response', so a 429 on a poll retries the poll and
         not the submission (ldh:retry-request pairs the keys by name) -->
    <xsl:function name="ldh:result-request" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="sleep-result" as="item()?"/>

        <xsl:sequence select="
          ixsl:http-request($context('result-request'))
            => ixsl:then(ldh:rethread-response($context, ?, 'result-response'))
            => ixsl:then(ldh:handle-response(?, 'result-response'))
            => ixsl:then(ldh:result-response#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:result-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('result-response')" as="map(*)"/>
        <xsl:variable name="execution" select="$response?body/wa:execution" as="element()?"/>

        <xsl:choose>
            <xsl:when test="$response?status = 202 and exists($execution)">
                <xsl:sequence select="ldh:chat-steps($context('card'), $execution)"/>
                <xsl:sequence select="ldh:poll-execution($context)"/>
            </xsl:when>
            <xsl:when test="$response?status = 200 and $execution/wa:status = 'complete'">
                <xsl:sequence select="ldh:execution-ended($context, $execution)"/>
            </xsl:when>
            <!-- a plan that failed answers 500 with the steps and writes that did happen; they are reported, not discarded -->
            <xsl:when test="$execution/wa:status = 'error'">
                <xsl:sequence select="ldh:execution-ended($context, $execution)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:response-error($response)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- the rows as the executor reports them: one per operation entered, in execution order, so a ForEach shows its
         iterations; they replace the planned rows, which for a plan without iteration are the same rows in a new
         state. The failure's message folds out under the step that failed - the innermost, since an outer operation
         fails only because one inside it did. The bar counts the rows that have an outcome against the rows there are -->
    <xsl:function name="ldh:chat-steps" ixsl:updating="yes">
        <xsl:param name="card" as="element()"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:variable name="steps" select="$execution/wa:steps/wa:step" as="element()*"/>
        <xsl:variable name="failed" select="$steps[@outcome = 'error'][last()]" as="element()?"/>
        <!-- a plan still held by its card (one that ran, or is running) lends its elements to the rows - but only when
             the steps are its operations one to one, in the order the executor enters them. A plan that stopped, or is
             still under way, has reported fewer steps than it has operations: those are its leading operations, and
             the rows get their XML all the same. A ForEach's iterations are more steps than operations, and get none -->
        <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="elements" select="if (exists($plan)) then ldh:plan-operations($plan/*[not(self::wa:summary | self::wa:operations | self::wa:present | self::wa:message)][1]) else ()" as="element()*"/>
        <xsl:variable name="entered" select="subsequence($elements, 1, count($steps))" as="element()*"/>
        <xsl:variable name="matched" select="count($entered) = count($steps) and deep-equal($entered/ldh:operation-name(.), $steps/string(@operation))" as="xs:boolean"/>

        <xsl:for-each select="$card/details[contains-token(@class, 'ldh-chat-trace')]/summary">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <span class="msi sm chev" aria-hidden="true">chevron_right</span>
                <!-- the outcome at a glance, so the folded trace still says whether the steps went green -->
                <xsl:choose>
                    <xsl:when test="exists($failed)">
                        <span class="msi sm st is-failed" aria-hidden="true">error</span>
                    </xsl:when>
                    <xsl:when test="exists($steps) and empty($steps[@outcome = 'start'])">
                        <span class="msi sm st is-done" aria-hidden="true">check_circle</span>
                    </xsl:when>
                </xsl:choose>
                <xsl:value-of select="count($steps)"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="key('resources', 'chat-steps', ldh:translations())" mode="ac:label"/>
                <xsl:for-each select="$steps[1]/@elapsed">
                    <xsl:text> · </xsl:text>
                    <xsl:value-of select="format-number(. div 1000, '0.0') || ' s'"/>
                </xsl:for-each>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="$card/details[contains-token(@class, 'ldh-chat-trace')]/ul[contains-token(@class, 'ldh-chat-steps')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="ldh:StepTree">
                    <xsl:with-param name="steps" select="$steps"/>
                    <xsl:with-param name="depth" select="0"/>
                    <xsl:with-param name="message" select="$execution/wa:message[exists($failed)]" tunnel="yes"/>
                    <xsl:with-param name="failed" select="$failed" tunnel="yes"/>
                    <xsl:with-param name="elements" select="$entered[$matched]" tunnel="yes"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="$card/div[contains-token(@class, 'ac-pbar')]/div[contains-token(@class, 'ac-pbar-head')]/span[contains-token(@class, 'ac-pbar-val')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:value-of select="count($steps[not(@outcome = 'start')]) || ' / ' || count($steps)"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:function>

    <!-- the steps as a tree: the executor reports them flat, in the order they were entered, each with its depth, so
         a step's children are the deeper steps that follow it up to the next step at its own depth. The items of
         one level, each with its subtree -->
    <xsl:template name="ldh:StepTree">
        <xsl:param name="steps" as="element()*"/>
        <xsl:param name="depth" as="xs:integer"/>

        <xsl:for-each-group select="$steps" group-starting-with="wa:step[xs:integer(@depth) = $depth]">
            <li>
                <xsl:apply-templates select="current-group()[1]" mode="ldh:StepRow"/>
                <xsl:if test="count(current-group()) gt 1">
                    <ul>
                        <xsl:call-template name="ldh:StepTree">
                            <xsl:with-param name="steps" select="current-group()[position() gt 1]"/>
                            <xsl:with-param name="depth" select="$depth + 1"/>
                        </xsl:call-template>
                    </ul>
                </xsl:if>
            </li>
        </xsl:for-each-group>
    </xsl:template>

    <!-- a step as the executor reported it: the row folds out its operation's XML, and the step that failed folds out
         open, with the message first - what went wrong above what was asked. The XML is the plan element at the same
         index in document order, which is the order the executor enters operations in -->
    <xsl:template match="wa:step" mode="ldh:StepRow">
        <xsl:param name="message" as="element()?" tunnel="yes"/>
        <xsl:param name="failed" as="element()?" tunnel="yes"/>
        <xsl:param name="elements" as="element()*" tunnel="yes"/>
        <xsl:variable name="state" select="if (@outcome = 'start') then 'is-running' else if (@outcome = 'complete') then 'is-done' else 'is-failed'" as="xs:string"/>
        <xsl:variable name="position" select="count(preceding-sibling::wa:step) + 1" as="xs:integer"/>

        <details class="ldh-chat-step {$state}">
            <xsl:if test=". is $failed and exists($message)">
                <xsl:attribute name="open" select="''"/>
            </xsl:if>
            <summary>
                <xsl:choose>
                    <!-- the design's ProgressCircle, as a field shows while it loads: a real spinner turns about its
                         own centre, where a rotated glyph does not -->
                    <xsl:when test="@outcome = 'start'">
                        <span class="st ac-pcircle sz-xs is-spin" aria-hidden="true">
                            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <circle class="pc-fill" cx="12" cy="12" r="9" fill="none" stroke-width="3" stroke-dasharray="42 15"/>
                            </svg>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="st msi sm" aria-hidden="true">
                            <xsl:value-of select="if (@outcome = 'complete') then 'check_circle' else 'error'"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
                <span class="op">
                    <xsl:value-of select="@operation"/>
                </span>
                <span class="mono muted">
                    <xsl:if test="@elapsed">
                        <xsl:value-of select="format-number(@elapsed div 1000, '0.0') || ' s'"/>
                    </xsl:if>
                </span>
            </summary>
            <xsl:if test=". is $failed and exists($message)">
                <p class="ldh-chat-step-message">
                    <xsl:value-of select="$message"/>
                </p>
            </xsl:if>
            <!-- the operation as it ran: a call nested in its arguments that decided a value at run time - the query a
                 SPARQLString wrote - stands as that value, so a SELECT shows the query it executed -->
            <xsl:variable name="resolved" as="element()?">
                <xsl:apply-templates select="$elements[$position]" mode="ldh:ResolvedOperation">
                    <xsl:with-param name="reported" select="../wa:step" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:sequence select="ldh:step-xml($resolved)"/>
            <!-- and what this step itself decided -->
            <xsl:for-each select="wa:value">
                <span class="ldh-chat-plan-meta">
                    <xsl:apply-templates select="key('resources', 'chat-step-value', ldh:translations())" mode="ac:label"/>
                </span>
                <div class="ac-codefield">
                    <pre>
                        <xsl:value-of select="."/>
                    </pre>
                </div>
            </xsl:for-each>
        </details>
    </xsl:template>

    <!-- An operation with the values its nested calls reported in place of the calls. The steps pair with the plan's
         elements by position (ldh:chat-steps does the pairing, and passes the elements only when it holds), so a nested
         element's step is the one at its index. The row's own operation stays itself: its value is shown beside it -->
    <!-- copy-namespaces="no": a stored plan is read out of the RDF/XML of its document, whose prefixes are in scope on
         every element of it and would otherwise be declared on the copy -->
    <xsl:template match="*" mode="ldh:ResolvedOperation">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()" mode="ldh:ResolvedArgument"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@* | text() | comment() | processing-instruction()" mode="ldh:ResolvedArgument">
        <xsl:copy/>
    </xsl:template>

    <xsl:template match="*" mode="ldh:ResolvedArgument">
        <xsl:param name="elements" as="element()*" tunnel="yes"/>
        <xsl:param name="reported" as="element()*" tunnel="yes"/>
        <xsl:variable name="index" select="(for $i in 1 to count($elements) return $i[$elements[$i] is current()])[1]" as="xs:integer?"/>
        <xsl:variable name="value" select="if (exists($index)) then $reported[$index]/wa:value else ()" as="element()?"/>

        <xsl:choose>
            <xsl:when test="exists($value)">
                <xsl:value-of select="$value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy copy-namespaces="no">
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Complete or failed, the card reports the same things: the final rows, green or red, with a failure's message
         folded under the step that failed; the documents the plan wrote; and for a plan that only read, what it read
         (ldh:ChatOutcome, which draws a stored turn the same way). The answer follows, and once it has landed the turn is
         stored and the page catches up with the writes (ldh:chat-store-turn) -->
    <xsl:function name="ldh:execution-ended" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="summary" select="ldh:execution-summary($execution)" as="map(*)"/>
        <!-- the plan the card holds, and how it said its result is best shown, when it said -->
        <xsl:variable name="plan-held" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>

        <xsl:for-each select="$card">
            <ixsl:set-attribute name="data-outcome" select="$summary?outcome"/>
        </xsl:for-each>
        <!-- what the execution reported is what the turn stores; what the plan returned is what a follow-up's "them"
             means, kept by the card and sent with the next question -->
        <ixsl:set-property name="{$card/@id}" select="$execution" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatExecutions')"/>
        <xsl:if test="not($summary?failed) and exists($summary?result)">
            <ixsl:set-property name="{$card/@id}" select="$execution/wa:result" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults')"/>
        </xsl:if>

        <xsl:sequence select="ldh:chat-steps($card, $execution)"/>
        <xsl:for-each select="$card/div[contains-token(@class, 'ac-pbar')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:for-each select="$card">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:call-template name="ldh:ChatOutcome">
                    <xsl:with-param name="execution" select="$execution"/>
                    <xsl:with-param name="present" select="$plan-held/wa:present"/>
                    <xsl:with-param name="card-id" select="string($card/@id)"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:sequence select="ldh:chat-draw-chart($card, $execution, $plan-held/wa:present)"/>

        <!-- the answer is read off the rows as the reader will see them: with their labels, so it waits for them when
             there are any to wait for, and goes straight away otherwise - a failure and a write included -->
        <xsl:sequence select="ldh:chat-label-rows($card, $execution, true())"/>

        <!-- the plan stays with its card: it is what Retry runs again and what the next question is told was tried -->

        <xsl:apply-templates select="$context('form')" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="true()"/>
        </xsl:apply-templates>
        <xsl:sequence select="ldh:chat-scroll($card)"/>

        <!-- with the checkbox on, nothing (or a failure) is asked again by the assistant itself, a few times at most;
             the reader sees every attempt as its own card and can stop it with the checkbox -->
        <xsl:variable name="form" select="$context('form')" as="element()?"/>
        <xsl:if test="exists($form) and ($summary?failed or $summary?empty) and ixsl:get(($form//input[@name = 'auto'])[1], 'checked') and xs:integer($card/@data-attempt) lt 3">
            <xsl:call-template name="ldh:ChatAsk">
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="question" select="string($card/@data-question)"/>
                <xsl:with-param name="attempt" select="xs:integer($card/@data-attempt) + 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:function>

    <!-- what an execution came to: whether it failed, the documents it wrote, what it returned (without what its writes
         reported: a write answers a one-row ?status ?url result set, which the documents written already say, and which
         is no answer to anything), whether that was nothing - a query that matched nothing is not an answer, it is the
         usual sign the plan guessed wrong - and all of it in a line -->
    <xsl:function name="ldh:execution-summary" as="map(*)">
        <xsl:param name="execution" as="element()"/>
        <xsl:variable name="failed" select="$execution/wa:status = 'error'" as="xs:boolean"/>
        <xsl:variable name="written" select="distinct-values($execution/wa:written/wa:document/@uri)" as="xs:anyURI*"/>
        <xsl:variable name="result" select="$execution/wa:result/*[not(ldh:write-report(.))]" as="element()*"/>
        <xsl:variable name="empty" select="not($failed) and empty($written) and empty($result[not(self::srx:sparql[empty(srx:results/srx:result)]) and not(self::rdf:RDF[empty(rdf:Description)])])" as="xs:boolean"/>
        <xsl:variable name="counts" as="xs:string*" select="
          if (exists($result/self::srx:sparql)) then count($result/self::srx:sparql/srx:results/srx:result) || ' rows' else (),
          if (exists($result/self::rdf:RDF)) then count($result/self::rdf:RDF/rdf:Description) || ' resources' else (),
          if (exists($result/self::wa:value)) then count($result/self::wa:value) || ' values' else (),
          if (exists($written)) then 'wrote ' || string-join($written, ' ') else ()"/>

        <xsl:sequence select="map{
          'failed': $failed,
          'written': $written,
          'result': $result,
          'empty': $empty,
          'outcome':
            if ($failed) then 'failed: ' || $execution/wa:message
            else if ($empty) then 'no results'
            else if (empty($counts)) then 'executed'
            else string-join($counts, ', ')
        }"/>
    </xsl:function>

    <!-- what a card shows once its plan has run, live or stored: the documents written, what was returned as blocks in
         the card (or that nothing was), and for nothing or a failure the two ways on - ask again differently, or run the
         same plan once more -->
    <xsl:template name="ldh:ChatOutcome">
        <xsl:param name="execution" as="element()"/>
        <xsl:param name="present" as="element()?"/>
        <xsl:param name="card-id" as="xs:string"/>
        <xsl:variable name="summary" select="ldh:execution-summary($execution)" as="map(*)"/>

        <xsl:if test="exists($summary?written)">
            <span class="ldh-chat-plan-meta">
                <xsl:apply-templates select="key('resources', 'changed-documents', ldh:translations())" mode="ac:label"/>
                <xsl:text> · </xsl:text>
                <xsl:value-of select="count($summary?written)"/>
            </span>
            <table class="ac-table ap-plain dn-tight is-hoverable ldh-chat-docs">
                <colgroup>
                    <col style="width: 28px"/>
                    <col/>
                </colgroup>
                <tbody>
                    <xsl:for-each select="$summary?written">
                        <tr>
                            <td>
                                <span class="msi sm" aria-hidden="true">description</span>
                            </td>
                            <td class="op">
                                <a class="iri" href="{.}">
                                    <xsl:value-of select="."/>
                                </a>
                            </td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="$summary?empty">
                <span class="ldh-chat-plan-meta">
                    <xsl:apply-templates select="key('resources', 'no-results', ldh:translations())" mode="ac:label"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$summary?result" mode="ldh:ExecutionResult">
                    <xsl:with-param name="present" select="$present" tunnel="yes"/>
                    <xsl:with-param name="card-id" select="$card-id" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="$summary?failed or $summary?empty">
            <div class="ldh-chat-plan-actions">
                <button type="button" class="ac-btn in-primary ap-solid sz-md ldh-chat-revise">
                    <span class="msi sm" aria-hidden="true">autorenew</span>
                    <span>
                        <xsl:apply-templates select="key('resources', 'revise', ldh:translations())" mode="ac:label"/>
                    </span>
                </button>
                <xsl:if test="$summary?failed">
                    <button type="button" class="ac-btn in-neutral ap-outline sz-md ldh-chat-execute">
                        <span class="msi sm" aria-hidden="true">refresh</span>
                        <span>
                            <xsl:apply-templates select="key('resources', 'retry', ldh:translations())" mode="ac:label"/>
                        </span>
                    </button>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- a chart is drawn into its canvas once the canvas is in the page - the card may have left it -->
    <xsl:function name="ldh:chat-draw-chart" as="item()*" ixsl:updating="yes">
        <xsl:param name="card" as="element()"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:param name="present" as="element()?"/>
        <xsl:variable name="summary" select="ldh:execution-summary($execution)" as="map(*)"/>

        <xsl:if test="not($summary?failed) and ldh:present-mode($present) = '&ac;ChartMode' and exists($summary?result/self::srx:sparql) and exists($card/ancestor::body)">
            <xsl:variable name="results" as="document-node()">
                <xsl:document>
                    <xsl:copy-of select="($summary?result/self::srx:sparql)[1]"/>
                </xsl:document>
            </xsl:variable>
            <!-- drawn as every chart is (ldh:InitCanvas), with the plan's type, category and series -->
            <xsl:apply-templates select="id($card/@id || '-chart', ixsl:page())" mode="ldh:InitCanvas">
                <xsl:with-param name="results" select="$results" tunnel="yes"/>
                <xsl:with-param name="chart-type" select="ldh:present-chart-type($present)" tunnel="yes"/>
                <xsl:with-param name="category" select="($present/@ldh:categoryVarName, $present/@category)[1]/string()" tunnel="yes"/>
                <xsl:with-param name="series" select="tokenize(($present/@ldh:seriesVarName, $present/@series)[1])" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:function>

    <!-- The URIs the rows name get their labels: the two lookups a view block runs, against the endpoint the plan
         queried (the dataspace's own when the plan named none, or several), and the rows are drawn again when the labels
         land. Until then, and if they never do, the rows stand as they are. A live turn's answer waits for them; a stored
         turn has its answer already -->
    <xsl:function name="ldh:chat-label-rows" as="item()*" ixsl:updating="yes">
        <xsl:param name="card" as="element()"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:param name="answer" as="xs:boolean"/>
        <xsl:variable name="summary" select="ldh:execution-summary($execution)" as="map(*)"/>
        <xsl:variable name="uris" select="distinct-values($summary?result/self::srx:sparql/srx:results/srx:result/srx:binding/srx:uri)" as="xs:string*"/>

        <xsl:choose>
            <xsl:when test="not($summary?failed) and exists($uris)">
                <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
                <xsl:variable name="endpoints" select="distinct-values($plan//wa:endpoint[not(*)]/normalize-space())" as="xs:string*"/>
                <xsl:variable name="endpoint" select="if (count($endpoints) = 1) then xs:anyURI($endpoints) else sd:endpoint()" as="xs:anyURI"/>
                <xsl:variable name="labels-context" select="map{ 'card': $card, 'result': $summary?result/self::srx:sparql, 'endpoint': $endpoint, 'object-uris': $uris[position() le 100], 'execution': $execution, 'answer': $answer }" as="map(*)"/>
                <ixsl:promise select="
                  ldh:http-request-threaded(ldh:load-object-metadata($labels-context), 'metadata-request', 'metadata-response')
                    => ixsl:then(ldh:handle-response(?, 'metadata-response'))
                    => ixsl:then(ldh:set-object-metadata#1)
                    => ixsl:then(ldh:http-request-threaded(?, 'ns-metadata-request', 'ns-metadata-response'))
                    => ixsl:then(ldh:handle-response(?, 'ns-metadata-response'))
                    => ixsl:then(ldh:set-object-metadata-ns#1)
                    => ixsl:then(ldh:merge-object-metadata#1)
                    => ixsl:then(ldh:chat-result-labelled#1)
                " on-failure="ldh:chat-labels-missed($labels-context, ?)"/>
            </xsl:when>
            <xsl:when test="$answer">
                <xsl:sequence select="ldh:chat-answer($card, $execution, ())"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- the rows again, now with the labels: the metadata is tunnelled through the table's rows to the link leaf, whose
         ac:object-label reads it before anything else, so the table needs no rule of its own. Results pair with
         tables by position, as a sequence's items were drawn side by side -->
    <xsl:function name="ldh:chat-result-labelled" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="results" select="$context('result')" as="element()*"/>
        <xsl:variable name="tables" select="$card//table[contains-token(@class, 'ldh-chat-result')]" as="element()*"/>

        <xsl:for-each select="$results">
            <xsl:variable name="position" select="position()" as="xs:integer"/>
            <xsl:for-each select="$tables[$position]/tbody">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <xsl:apply-templates select="$results[$position]/srx:results/srx:result" mode="ac:ResultsTable">
                        <xsl:with-param name="object-metadata" select="$context('object-metadata')" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:if test="$context('answer')">
            <xsl:sequence select="ldh:chat-answer($card, $context('execution'), $context('object-metadata'))"/>
        </xsl:if>
    </xsl:function>

    <!-- labels are a courtesy: a lookup that fails leaves the rows naming their URIs, and the answer is read off them as they are -->
    <xsl:function name="ldh:chat-labels-missed" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="error" as="item()*"/>

        <xsl:message>ldh:chat-labels-missed</xsl:message>
        <xsl:if test="$context('answer')">
            <xsl:sequence select="ldh:chat-answer($context('card'), $context('execution'), ())"/>
        </xsl:if>
    </xsl:function>

    <!-- a write's report: the one-row result set every write answers (formal-semantics §4.4), ?status and ?url -->
    <xsl:function name="ldh:write-report" as="xs:boolean">
        <xsl:param name="item" as="element()"/>

        <xsl:sequence select="exists($item/self::srx:sparql) and deep-equal(sort($item/srx:head/srx:variable/string(@name)), ('status', 'url'))"/>
    </xsl:function>

    <!-- THE ANSWER -->

    <!-- What the plan did, as a sentence or two: the question, the plan's summary, the steps and how they went, the
         documents written, and the rows - a label beside each resource that has one - go to the answer service beside
         the plan service, and its reading comes back as the card's first line. The rows stay the authority and stay
         on the card; the trace folds under its count once there is an answer to read instead. A service that cannot
         answer leaves the card as it was: the rows are the answer then, as they were before there was a service -->
    <xsl:function name="ldh:chat-answer" as="item()*" ixsl:updating="yes">
        <xsl:param name="card" as="element()"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:param name="object-metadata" as="document-node()?"/>
        <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="result" select="$execution/wa:result/*[not(ldh:write-report(.))]" as="element()*"/>
        <xsl:variable name="cap" select="60" as="xs:integer"/>
        <!-- the rows: a result set's, each binding its value and, for a resource with a known label, the label; a graph's
             described resources as one-column rows, labelled the same way -->
        <xsl:variable name="rows" as="array(*)" select="array {
          for $row in ($result/self::srx:sparql)[1]/srx:results/srx:result[position() le $cap] return map:merge(
            for $binding in $row/srx:binding return map{ string($binding/@name):
              if ($binding/srx:uri) then map:merge((map{ 'value': string($binding/srx:uri) }, for $label in (if (exists($object-metadata)) then ac:object-label($binding/srx:uri, $object-metadata) else ()) return map{ 'label': $label }))
              else string($binding/*) }),
          for $resource in ($result/self::rdf:RDF)[1]/rdf:Description[@rdf:about][position() le $cap] return map{ 'resource':
            map:merge((map{ 'value': string($resource/@rdf:about) }, for $label in (if (exists($object-metadata)) then ac:object-label($resource/@rdf:about, $object-metadata) else ()) return map{ 'label': $label })) }
        }"/>
        <xsl:variable name="body" as="map(*)" select="map:merge((
          map{ 'question': string($card/@data-question) },
          for $summary in $plan/wa:summary[normalize-space()] return map{ 'summary': normalize-space($summary) },
          map{ 'steps': array { for $step in $execution/wa:steps/wa:step return map{ 'operation': string($step/@operation), 'outcome': string($step/@outcome), 'elapsed': string($step/@elapsed) } } },
          map{ 'written': array { for $uri in $execution/wa:written/wa:document/@uri return string($uri) } },
          for $message in $execution/wa:message[$execution/wa:status = 'error'] return map{ 'failed': string($message) },
          if (exists($result/self::srx:sparql | $result/self::rdf:RDF)) then map{ 'rows': $rows } else map{},
          map{ 'values': array { for $value in $result/self::wa:value return string($value) } }
        ))"/>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:chat-href('webalgebra/answers'), 'media-type': 'application/json', 'body': serialize($body, map{ 'method': 'json' }), 'headers': map{ 'Accept': 'application/xml' } }" as="map(*)"/>
        <xsl:variable name="context" select="map{ 'request': $request, 'card': $card }" as="map(*)"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:chat-answered#1)
        " on-failure="ldh:chat-answer-missed($context, ?)"/>
    </xsl:function>

    <!-- the answer lands first on the card, and the trace folds under it; an envelope without one changes nothing -->
    <xsl:function name="ldh:chat-answered" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="answer" select="normalize-space($response?body/wa:answer)" as="xs:string"/>

        <xsl:if test="$response?status = 200 and $answer">
            <xsl:for-each select="$card/p[contains-token(@class, 'ldh-chat-answer')]">
                <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:for-each>
            <xsl:for-each select="$card/*[1]">
                <xsl:result-document href="?." method="ixsl:insert-before">
                    <p class="ldh-chat-answer">
                        <xsl:value-of select="$answer"/>
                    </p>
                </xsl:result-document>
            </xsl:for-each>
            <xsl:for-each select="$card/details[contains-token(@class, 'ldh-chat-trace')]">
                <ixsl:remove-attribute name="open"/>
            </xsl:for-each>
            <xsl:sequence select="ldh:chat-scroll($card)"/>
        </xsl:if>

        <!-- the turn has ended: it is stored, answer and all -->
        <xsl:sequence select="ldh:chat-store-turn($card)"/>
    </xsl:function>

    <!-- the answer is a courtesy too: without it the card says what it said before, and is stored as it is -->
    <xsl:function name="ldh:chat-answer-missed" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="error" as="item()*"/>

        <xsl:message>ldh:chat-answer-missed</xsl:message>
        <xsl:sequence select="ldh:chat-store-turn($context('card'))"/>
    </xsl:function>

    <!-- A result as a block inside the card: a result set as the table the document's query blocks use, or drawn as a
         chart when the plan said so; a graph through the view block's own list, grid or table rendering by the plan's
         word, the list when it gave none. Each sits in a nested well headed the way a block is - the mode's icon and
         name at compact density.
         The chart's canvas is drawn into once it is in the page (ldh:execution-ended) -->
    <xsl:template match="srx:sparql" mode="ldh:ExecutionResult">
        <xsl:param name="present" as="element()?" tunnel="yes"/>
        <xsl:param name="card-id" as="xs:string" tunnel="yes"/>

        <xsl:choose>
            <xsl:when test="ldh:present-mode($present) = '&ac;ChartMode'">
                <xsl:call-template name="ldh:ChatResultWell">
                    <xsl:with-param name="mode" select="xs:anyURI('&ac;ChartMode')"/>
                    <xsl:with-param name="icon" select="'show_chart'"/>
                    <xsl:with-param name="body" as="element()">
                        <div id="{$card-id}-chart" class="chart-canvas ldh-chat-chart"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ldh:ChatResultWell">
                    <xsl:with-param name="mode" select="xs:anyURI('&ac;TableMode')"/>
                    <xsl:with-param name="icon" select="'table'"/>
                    <xsl:with-param name="body" as="element()">
                        <xsl:apply-templates select="." mode="ac:ResultsTable">
                            <xsl:with-param name="class" select="'ac-table ap-plain dn-tight ldh-chat-result'"/>
                        </xsl:apply-templates>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="ldh:ExecutionResult">
        <xsl:param name="present" as="element()?" tunnel="yes"/>
        <!-- a graph is drawn as a list, a grid or a table; a list unless the plan said one of the others -->
        <xsl:variable name="mode" select="(ldh:present-mode($present)[. = ('&ac;GridMode', '&ac;TableMode')], xs:anyURI('&ac;ListMode'))[1]" as="xs:anyURI"/>

        <xsl:call-template name="ldh:ChatResultWell">
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="icon" select="map{ '&ac;ListMode': 'view_list', '&ac;GridMode': 'grid_view', '&ac;TableMode': 'table' }(string($mode))"/>
            <xsl:with-param name="body" as="element()*">
                <xsl:choose>
                    <xsl:when test="$mode = '&ac;GridMode'">
                        <xsl:apply-templates select="." mode="ldh:GridViewBlock">
                            <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                            <xsl:with-param name="endpoint" select="sd:endpoint()" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$mode = '&ac;TableMode'">
                        <xsl:apply-templates select="." mode="ldh:TableViewBlock">
                            <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                            <xsl:with-param name="endpoint" select="sd:endpoint()" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="ldh:ListViewBlock">
                            <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                            <xsl:with-param name="endpoint" select="sd:endpoint()" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="wa:value" mode="ldh:ExecutionResult">
        <span class="ldh-chat-plan-meta">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <xsl:template match="*" mode="ldh:ExecutionResult"/>

    <!-- THE PRESENTATION HINT -->

    <!-- How the plan said its result is best shown: wa:present carries the client's layout mode as ac:mode, the URI a
         view block's ac:mode takes, and a chart's details as the properties a chart block has - ldh:chartType,
         ldh:categoryVarName, ldh:seriesVarName. Turns stored before the hint took URIs said the same with the tokens
         table, list, grid and chart and with type, category and series; those are read too -->
    <xsl:function name="ldh:present-mode" as="xs:anyURI?">
        <xsl:param name="present" as="element()?"/>

        <xsl:sequence select="(for $mode in $present/@ac:mode return xs:anyURI($mode), for $token in $present/@mode return map{ 'table': xs:anyURI('&ac;TableMode'), 'list': xs:anyURI('&ac;ListMode'), 'grid': xs:anyURI('&ac;GridMode'), 'chart': xs:anyURI('&ac;ChartMode') }(string($token)))[1]"/>
    </xsl:function>

    <!-- a chart's type, a bar chart when the hint names none -->
    <xsl:function name="ldh:present-chart-type" as="xs:anyURI">
        <xsl:param name="present" as="element()?"/>

        <xsl:sequence select="(for $type in $present/@ldh:chartType return xs:anyURI($type), for $token in $present/@type return map{ 'bar': xs:anyURI('&ac;BarChart'), 'line': xs:anyURI('&ac;LineChart'), 'scatter': xs:anyURI('&ac;ScatterChart') }(string($token)), xs:anyURI('&ac;BarChart'))[1]"/>
    </xsl:function>

    <!-- the well a result sits in: the kit's nested block at depth 2 under the card, headed with the mode's icon and
         name, as a block in the document would be -->
    <xsl:template name="ldh:ChatResultWell">
        <xsl:param name="mode" as="xs:anyURI"/>
        <xsl:param name="icon" as="xs:string"/>
        <xsl:param name="body" as="item()*"/>

        <div class="ldh-nblock ldh-chat-result-block" data-depth="2" data-mode="{$mode}">
            <div class="ldh-block-head ldh-res-head" data-density="compact">
                <span class="ldh-res-icon">
                    <span class="msi outline" aria-hidden="true">
                        <xsl:value-of select="$icon"/>
                    </span>
                </span>
                <div class="ldh-res-text">
                    <div class="ldh-res-titleline">
                        <!-- the mode's own label, from the vocabulary that defines it, as the view mode switcher shows it -->
                        <h3 class="ttl">
                            <xsl:apply-templates select="key('resources', $mode, document(ac:document-uri('&ac;')))" mode="ac:label"/>
                        </h3>
                    </div>
                </div>
                <div class="actions"/>
            </div>
            <div class="ldh-nblock-body">
                <xsl:sequence select="$body"/>
            </div>
        </div>
    </xsl:template>


    <!-- FAILURE -->

    <!-- a chain that died (the service unreachable, a status nothing above accounts for) reports in its card, where
         ldh:RenderFailure puts the failure first; the progress it was reporting under is over, and so is the composer's wait -->
    <xsl:function name="ldh:chat-failure" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="title-key" as="xs:string"/>
        <xsl:param name="error" as="map(*)"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>

        <xsl:for-each select="$card/div[contains-token(@class, 'ac-pbar')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:apply-templates select="$context('form')" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="true()"/>
        </xsl:apply-templates>

        <xsl:sequence select="ldh:promise-failure($card, $title-key, $error)"/>
        <xsl:sequence select="ldh:chat-scroll($card)"/>
    </xsl:function>

    <!-- HELPERS -->

    <!-- the plan service is on this dataspace's origin, behind nginx at /webalgebra -->
    <xsl:function name="ldh:chat-href" as="xs:anyURI">
        <xsl:param name="path" as="xs:string"/>

        <xsl:sequence select="xs:anyURI(resolve-uri($path, lds:base()))"/>
    </xsl:function>

    <!-- the design's ProgressBar at its thinnest: a label, a value when there is one to count, and a bar that is
         indeterminate until then -->
    <xsl:function name="ldh:chat-progress" as="element()">
        <xsl:param name="label-key" as="xs:string"/>
        <xsl:param name="value" as="xs:string?"/>
        <xsl:variable name="label" as="item()*">
            <xsl:apply-templates select="key('resources', $label-key, ldh:translations())" mode="ac:label"/>
        </xsl:variable>

        <div class="ac-pbar ht-xs is-indeterminate">
            <div class="ac-pbar-head">
                <span class="ac-pbar-lbl">
                    <xsl:sequence select="$label"/>
                </span>
                <xsl:if test="exists($value)">
                    <span class="ac-pbar-val">
                        <xsl:value-of select="$value"/>
                    </span>
                </xsl:if>
            </div>
            <div class="ac-pbar-track" role="progressbar" aria-label="{string-join($label)}">
                <div class="ac-pbar-fill"/>
            </div>
        </div>
    </xsl:function>

    <!-- the newest card is the one being read: the page scrolls it into view, when the card is in the page at all -->
    <xsl:function name="ldh:chat-scroll" ixsl:updating="yes">
        <xsl:param name="card" as="element()?"/>

        <xsl:for-each select="$card[ancestor::body]">
            <xsl:sequence select="ixsl:call(., 'scrollIntoView', [ map{ 'block': 'nearest', 'behavior': 'smooth' } ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>
