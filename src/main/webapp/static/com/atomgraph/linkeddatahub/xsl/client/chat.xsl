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
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- The assistant drawer: a question becomes a Web-Algebra plan, the plan is shown, and only a press of Execute
         runs it. The plan service sits beside this instance (the web-algebra container, behind nginx at /webalgebra)
         and acts for the reader whose certificate nginx forwards, so what a plan may write is what the reader may write.

         The drawer is chrome the server renders once (layout.xsl, ldh:AssistantDrawer); everything inside the log is
         built here. A conversation is a sequence of cards, one per question, each holding its plan under its own id
         in LinkedDataHub.chat so that a card's Execute runs that card's plan and no other. -->

    <!-- OPEN AND CLOSE -->

    <!-- the handle at the right edge opens the drawer; a persistent panel that insets the page is opened on purpose,
         not by a pointer straying to the edge, which is why hover only reveals the handle (app.css) -->
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'chat-open')]]" mode="ixsl:onclick">
        <xsl:apply-templates select="ixsl:page()//div[contains-token(@class, 'chat-drawer')]" mode="ldh:OpenDrawer"/>
    </xsl:template>

    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'chat-close')]]" mode="ixsl:onclick">
        <xsl:apply-templates select="ancestor::div[contains-token(@class, 'chat-drawer')][1]" mode="ldh:CloseDrawer"/>
    </xsl:template>

    <!-- Clear empties the log - every turn and every card - and drops the plans the cards held, so the next question
         starts a conversation with no history. The composer is enabled again, whatever a removed card left it as -->
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'chat-clear')]]" mode="ixsl:onclick">
        <xsl:variable name="drawer" select="ancestor::div[contains-token(@class, 'chat-drawer')][1]" as="element()"/>
        <xsl:variable name="log" select="$drawer/div[contains-token(@class, 'chat-log')]" as="element()"/>

        <xsl:for-each select="$log/div[contains-token(@class, 'chat-plan')]/@id">
            <ixsl:remove-property name="{.}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chat')"/>
            <ixsl:remove-property name="{.}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults')"/>
        </xsl:for-each>
        <xsl:sequence select="ixsl:call($log, 'replaceChildren', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:apply-templates select="$drawer/form[contains-token(@class, 'chat-composer')]" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="true()"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- inert while closed keeps the hidden subtree out of the tab order, as the dataspace drawer does -->
    <xsl:template match="div[contains-token(@class, 'chat-drawer')]" mode="ldh:OpenDrawer">
        <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-open', true())"/>
        <ixsl:remove-attribute name="inert"/>
        <xsl:sequence select="ixsl:call((.//textarea)[1], 'focus', [])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="div[contains-token(@class, 'chat-drawer')]" mode="ldh:CloseDrawer">
        <ixsl:set-attribute name="class" select="ldh:set-token(@class, 'is-open', false())"/>
        <ixsl:set-attribute name="inert" select="''"/>
    </xsl:template>

    <!-- THE COMPOSER -->

    <!-- Enter sends, Shift+Enter breaks the line; Escape closes the drawer from inside it as it does from the page
         (client/navigation.xsl handles the key when focus is on the body). keydown, not keyup: the default that
         inserts the newline fires on keydown, and only the event carrying a default can prevent it -->
    <xsl:template match="textarea[ancestor::form[contains-token(@class, 'chat-composer')]]" mode="ixsl:onkeydown">
        <xsl:variable name="key" select="ixsl:get(ixsl:event(), 'key')" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$key = 'Enter' and not(ixsl:get(ixsl:event(), 'shiftKey'))">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:apply-templates select="ancestor::form[contains-token(@class, 'chat-composer')][1]" mode="ixsl:onsubmit"/>
            </xsl:when>
            <xsl:when test="$key = 'Escape'">
                <xsl:apply-templates select="ancestor::div[contains-token(@class, 'chat-drawer')][1]" mode="ldh:CloseDrawer"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="form[contains-token(@class, 'chat-composer')]" mode="ixsl:onsubmit">
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
         every card that ran, with its plan and how it went, so a plan that returned nothing is not proposed again
         (the last few only - the prompt is not the place for a whole afternoon). The reply becomes the new card -->
    <xsl:template name="ldh:ChatAsk">
        <xsl:param name="form" as="element()"/>
        <xsl:param name="question" as="xs:string"/>
        <!-- 0 when the reader asked; counts up when the drawer asks again by itself, so it stops asking -->
        <xsl:param name="attempt" select="0" as="xs:integer"/>
        <xsl:variable name="log" select="$form/ancestor::div[contains-token(@class, 'chat-drawer')][1]/div[contains-token(@class, 'chat-log')]" as="element()"/>
        <xsl:variable name="card-id" select="'chat-' || ac:uuid()" as="xs:string"/>
        <xsl:variable name="history" as="array(*)" select="array { for $card in ($log/div[contains-token(@class, 'chat-plan')][@data-outcome])[position() gt last() - 3] return ldh:chat-turn($card) }"/>

        <xsl:for-each select="$log">
            <xsl:result-document href="?." method="ixsl:append-content">
                <p class="chat-turn">
                    <xsl:value-of select="$question"/>
                </p>
                <div class="ldh-nblock chat-plan" data-depth="1" id="{$card-id}" data-question="{$question}" data-attempt="{$attempt}">
                    <xsl:sequence select="ldh:chat-progress('thinking', ())"/>
                </div>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:sequence select="ldh:chat-scroll($log)"/>

        <xsl:apply-templates select="$form" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="false()"/>
        </xsl:apply-templates>
        <xsl:sequence select="ldh:busy-cursor()"/>

        <!-- where the reader is: the document in the address bar, its dataspace's endpoint and the dataspace's ontology, the
             context a plan against this instance needs. Read now rather than stamped at render, since navigation moves them -->
        <xsl:variable name="ontology" select="if (exists(lds:ontology())) then map{ 'ontology': string(lds:ontology()) } else map{}" as="map(xs:string, xs:string)"/>
        <xsl:variable name="body" select="serialize(map:merge((map{ 'question': $question, 'document': string(ac:absolute-path(ldh:request-uri())), 'endpoint': string(sd:endpoint()), 'history': $history }, $ontology)), map{ 'method': 'json' })" as="xs:string"/>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:chat-href('webalgebra/plans'), 'media-type': 'application/json', 'body': $body, 'headers': map{ 'Accept': 'application/xml' } }" as="map(*)"/>
        <xsl:variable name="context" select="map{ 'request': $request, 'card': id($card-id, ixsl:page()), 'form': $form }" as="map(*)"/>
        <ixsl:promise select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:plan-response#1) =>
            ixsl:finally(ldh:reset-cursor#0)
        " on-failure="ldh:chat-failure($context, 'plan-not-generated', ?)"/>
    </xsl:template>

    <!-- one earlier turn as the plan service hears it: the question, the operation that ran, what came of it -->
    <xsl:function name="ldh:chat-turn" as="map(*)">
        <xsl:param name="card" as="element()"/>
        <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
        <xsl:variable name="operation" select="$plan/*[not(self::wa:summary | self::wa:operations | self::wa:message)][1]" as="element()?"/>

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
            <xsl:for-each select="$result/srx:sparql[srx:results/srx:result]">
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
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'chat-revise')]]" mode="ixsl:onclick">
        <xsl:variable name="card" select="ancestor::div[contains-token(@class, 'chat-plan')][1]" as="element()"/>

        <xsl:call-template name="ldh:ChatAsk">
            <xsl:with-param name="form" select="ancestor::div[contains-token(@class, 'chat-drawer')][1]/form[contains-token(@class, 'chat-composer')]"/>
            <xsl:with-param name="question" select="string($card/@data-question)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- the composer is disabled while a request of its own is in flight, so a question is answered before the next
         one is asked; a plan waiting for Execute leaves it open -->
    <xsl:template match="form[contains-token(@class, 'chat-composer')]" mode="ldh:ComposerEnabled">
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
            <xsl:when test="$response?status = 200 and exists($plan/*[not(self::wa:summary | self::wa:operations | self::wa:message)])">
                <!-- the card keeps its plan under its own id: Execute on this card runs this plan, whatever was asked since -->
                <ixsl:set-property name="{$card/@id}" select="$plan" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chat')"/>

                <xsl:for-each select="$card">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <xsl:apply-templates select="$plan" mode="ldh:PlanCard"/>
                    </xsl:result-document>
                </xsl:for-each>

                <!-- a plan runs on arrival when the reader asked for that (Execute by default), and a revision the drawer
                     asked for by itself always does - in both cases only when every operation in it reads. One that writes
                     waits for Execute like any other, whatever the checkboxes say: a write cannot be taken back -->
                <xsl:variable name="run" select="ixsl:get(($context('form')//input[@name = 'run'])[1], 'checked')" as="xs:boolean"/>
                <xsl:if test="($run or xs:integer($card/@data-attempt) gt 0) and (every $name in $plan/wa:operations/wa:operation/@name satisfies ldh:operation-kind($name) = 'read')">
                    <xsl:call-template name="ldh:ChatExecute">
                        <xsl:with-param name="card" select="$card"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$response?status = 200 and exists($plan/wa:message)">
                <xsl:for-each select="$card">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <p>
                            <xsl:value-of select="$plan/wa:message"/>
                        </p>
                    </xsl:result-document>
                </xsl:for-each>
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
        <xsl:sequence select="ldh:chat-scroll($card/..)"/>
    </xsl:function>

    <!-- the plan card: what the plan does in a sentence, its operations as the rows they will be executed as, the
         document itself for anyone who wants to read it, and the two things that can happen to it. The operation is
         the envelope's one child that is not envelope: every element of a plan is in the Web-Algebra namespace, so it
         is told apart by name and never by wa:* -->
    <xsl:template match="wa:plan" mode="ldh:PlanCard">
        <xsl:variable name="operation" select="*[not(self::wa:summary | self::wa:operations | self::wa:message)][1]" as="element()"/>

        <xsl:if test="normalize-space(wa:summary)">
            <p>
                <xsl:value-of select="wa:summary"/>
            </p>
        </xsl:if>
        <!-- the same rows execution reports into: an operation is a step that has not run yet. The rows nest as
             the operations do, and each folds out its own operation's XML - the first, the outermost, the whole plan -->
        <ul class="chat-steps">
            <xsl:apply-templates select="$operation" mode="ldh:OperationTree"/>
        </ul>
        <div class="chat-plan-actions">
            <button type="button" class="ac-btn in-primary ap-solid sz-md chat-execute">
                <span class="msi sm" aria-hidden="true">play_arrow</span>
                <span>
                    <xsl:apply-templates select="key('resources', 'execute', ldh:translations())" mode="ac:label"/>
                </span>
            </button>
            <button type="button" class="ac-btn in-neutral ap-outline sz-md chat-cancel">
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
            <details class="chat-step is-planned kd-{$kind}">
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

    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'chat-cancel') or contains-token(@class, 'chat-dismiss')]]" mode="ixsl:onclick">
        <xsl:variable name="card" select="ancestor::div[contains-token(@class, 'chat-plan')][1]" as="element()"/>
        <xsl:variable name="form" select="ancestor::div[contains-token(@class, 'chat-drawer')][1]/form[contains-token(@class, 'chat-composer')]" as="element()"/>

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
    <xsl:template match="*[ancestor-or-self::button[contains-token(@class, 'chat-execute')]]" mode="ixsl:onclick">
        <xsl:call-template name="ldh:ChatExecute">
            <xsl:with-param name="card" select="ancestor::div[contains-token(@class, 'chat-plan')][1]"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="ldh:ChatExecute">
        <xsl:param name="card" as="element()"/>
        <xsl:variable name="form" select="$card/ancestor::div[contains-token(@class, 'chat-drawer')][1]/form[contains-token(@class, 'chat-composer')]" as="element()"/>
        <xsl:variable name="plan" select="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))" as="element()"/>
        <xsl:variable name="operation" select="$plan/*[not(self::wa:summary | self::wa:operations | self::wa:message)][1]" as="element()"/>

        <!-- the actions and what a previous attempt reported - everything after the rows - go; the rows go back to
             planned and report anew -->
        <xsl:for-each select="$card/*[preceding-sibling::ul[contains-token(@class, 'chat-steps')]] | $card/div[contains-token(@class, 'ac-pbar')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        <xsl:for-each select="$card/ul[contains-token(@class, 'chat-steps')]">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:apply-templates select="$operation" mode="ldh:OperationTree"/>
            </xsl:result-document>
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
        <xsl:variable name="elements" select="if (exists($plan)) then ldh:plan-operations($plan/*[not(self::wa:summary | self::wa:operations | self::wa:message)][1]) else ()" as="element()*"/>
        <xsl:variable name="entered" select="subsequence($elements, 1, count($steps))" as="element()*"/>
        <xsl:variable name="matched" select="count($entered) = count($steps) and deep-equal($entered/ldh:operation-name(.), $steps/string(@operation))" as="xs:boolean"/>

        <xsl:for-each select="$card/ul[contains-token(@class, 'chat-steps')]">
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

        <details class="chat-step {$state}">
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
                <p class="chat-step-message">
                    <xsl:value-of select="$message"/>
                </p>
            </xsl:if>
            <xsl:sequence select="ldh:step-xml($elements[$position])"/>
        </details>
    </xsl:template>

    <!-- Complete or failed, the card reports the same things: the final rows, green or red, with a failure's message
         folded under the step that failed; the documents the plan wrote; and for a plan that only read, what it read. Then the page catches up with the writes:
         every written document's cached copy goes, and the document being read is loaded again if anything was
         written - a block on it may list what a new document changed, so the writes are not narrowed to its own URI -->
    <xsl:function name="ldh:execution-ended" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="execution" as="element()"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="failed" select="$execution/wa:status = 'error'" as="xs:boolean"/>
        <xsl:variable name="written" select="$execution/wa:written/wa:document/@uri" as="xs:anyURI*"/>
        <!-- the plan's value: one item, or a sequence's items side by side (a graph, a result set, a value each) -->
        <xsl:variable name="result" select="$execution/wa:result/*" as="element()*"/>
        <!-- a query that matched nothing is not an answer: it is the usual sign the plan guessed wrong -->
        <xsl:variable name="empty" select="not($failed) and empty($written) and empty($result[not(self::srx:sparql[empty(srx:results/srx:result)]) and not(self::rdf:RDF[empty(rdf:Description)])])" as="xs:boolean"/>
        <xsl:variable name="counts" as="xs:string*" select="
          if (exists($result/self::srx:sparql)) then count($result/self::srx:sparql/srx:results/srx:result) || ' rows' else (),
          if (exists($result/self::rdf:RDF)) then count($result/self::rdf:RDF/rdf:Description) || ' resources' else (),
          if (exists($result/self::wa:value)) then count($result/self::wa:value) || ' values' else (),
          if (exists($written)) then 'wrote ' || string-join($written, ' ') else ()"/>
        <xsl:variable name="outcome" as="xs:string" select="
          if ($failed) then 'failed: ' || $execution/wa:message
          else if ($empty) then 'no results'
          else if (empty($counts)) then 'executed'
          else string-join($counts, ', ')"/>
        <xsl:for-each select="$card">
            <ixsl:set-attribute name="data-outcome" select="$outcome"/>
        </xsl:for-each>
        <!-- what the plan returned is what a follow-up's "them" means; kept by the card, sent with the next question -->
        <xsl:if test="not($failed) and exists($result)">
            <ixsl:set-property name="{$card/@id}" select="$execution/wa:result" object="ixsl:get(ixsl:window(), 'LinkedDataHub.chatResults')"/>
        </xsl:if>

        <xsl:sequence select="ldh:chat-steps($card, $execution)"/>
        <xsl:for-each select="$card/div[contains-token(@class, 'ac-pbar')]">
            <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>

        <xsl:for-each select="$card">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:if test="exists($written)">
                    <span class="chat-plan-meta">
                        <xsl:apply-templates select="key('resources', 'changed-documents', ldh:translations())" mode="ac:label"/>
                        <xsl:text> · </xsl:text>
                        <xsl:value-of select="count($written)"/>
                    </span>
                    <table class="ac-table ap-plain dn-tight is-hoverable chat-docs">
                        <colgroup>
                            <col style="width: 28px"/>
                            <col/>
                        </colgroup>
                        <tbody>
                            <xsl:for-each select="distinct-values($written)">
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
                    <xsl:when test="$empty">
                        <span class="chat-plan-meta">
                            <xsl:apply-templates select="key('resources', 'no-results', ldh:translations())" mode="ac:label"/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$result" mode="ldh:ExecutionResult"/>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- nothing, or a failure, is a reason to ask again differently; a failure may also be worth the same plan once more -->
                <xsl:if test="$failed or $empty">
                    <div class="chat-plan-actions">
                        <button type="button" class="ac-btn in-primary ap-solid sz-md chat-revise">
                            <span class="msi sm" aria-hidden="true">autorenew</span>
                            <span>
                                <xsl:apply-templates select="key('resources', 'revise', ldh:translations())" mode="ac:label"/>
                            </span>
                        </button>
                        <xsl:choose>
                            <xsl:when test="$failed">
                                <button type="button" class="ac-btn in-neutral ap-outline sz-md chat-execute">
                                    <span class="msi sm" aria-hidden="true">refresh</span>
                                    <span>
                                        <xsl:apply-templates select="key('resources', 'retry', ldh:translations())" mode="ac:label"/>
                                    </span>
                                </button>
                            </xsl:when>
                            <xsl:otherwise>
                                <button type="button" class="ac-btn in-neutral ap-outline sz-md chat-dismiss">
                                    <span>
                                        <xsl:apply-templates select="key('resources', 'dismiss', ldh:translations())" mode="ac:label"/>
                                    </span>
                                </button>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                </xsl:if>
            </xsl:result-document>
        </xsl:for-each>

        <!-- the URIs the rows name get their labels: the two lookups a view block runs, against the endpoint the plan
             queried (the dataspace's own when the plan named none, or several), and the rows are drawn again when the
             labels land. Until then, and if they never do, the rows stand as they are -->
        <xsl:variable name="uris" select="distinct-values($result/self::srx:sparql/srx:results/srx:result/srx:binding/srx:uri)" as="xs:string*"/>
        <xsl:if test="not($failed) and exists($uris)">
            <xsl:variable name="plan" select="if (ixsl:contains(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id))) then ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.chat'), string($card/@id)) else ()" as="element()?"/>
            <xsl:variable name="endpoints" select="distinct-values($plan//wa:endpoint[not(*)]/normalize-space())" as="xs:string*"/>
            <xsl:variable name="endpoint" select="if (count($endpoints) = 1) then xs:anyURI($endpoints) else sd:endpoint()" as="xs:anyURI"/>
            <xsl:variable name="labels-context" select="map{ 'card': $card, 'result': $result/self::srx:sparql, 'endpoint': $endpoint, 'object-uris': $uris[position() le 100] }" as="map(*)"/>
            <ixsl:promise select="
              ldh:http-request-threaded(ldh:load-object-metadata($labels-context), 'metadata-request', 'metadata-response')
                => ixsl:then(ldh:handle-response(?, 'metadata-response'))
                => ixsl:then(ldh:set-object-metadata#1)
                => ixsl:then(ldh:http-request-threaded(?, 'ns-metadata-request', 'ns-metadata-response'))
                => ixsl:then(ldh:handle-response(?, 'ns-metadata-response'))
                => ixsl:then(ldh:set-object-metadata-ns#1)
                => ixsl:then(ldh:merge-object-metadata#1)
                => ixsl:then(ldh:chat-result-labelled#1)
            " on-failure="ldh:chat-labels-missed#1"/>
        </xsl:if>

        <!-- the plan stays with its card: it is what Retry runs again and what the next question is told was tried -->

        <xsl:apply-templates select="$context('form')" mode="ldh:ComposerEnabled">
            <xsl:with-param name="enabled" select="true()"/>
        </xsl:apply-templates>
        <xsl:sequence select="ldh:chat-scroll($card/..)"/>

        <!-- with the checkbox on, nothing (or a failure) is asked again by the drawer itself, a few times at most;
             the reader sees every attempt as its own card and can stop it with the checkbox -->
        <xsl:variable name="form" select="$context('form')" as="element()"/>
        <xsl:if test="($failed or $empty) and ixsl:get(($form//input[@name = 'auto'])[1], 'checked') and xs:integer($card/@data-attempt) lt 3">
            <xsl:call-template name="ldh:ChatAsk">
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="question" select="string($card/@data-question)"/>
                <xsl:with-param name="attempt" select="xs:integer($card/@data-attempt) + 1"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:for-each select="distinct-values($written)">
            <ixsl:remove-property name="{'`' || . || '`'}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        </xsl:for-each>
        <xsl:if test="exists($written)">
            <xsl:variable name="doc-uri" select="ac:absolute-path(ldh:request-uri())" as="xs:anyURI"/>
            <ixsl:remove-property name="{'`' || $doc-uri || '`'}" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>

            <!-- the navigation is written for a click, with a context node; the card stands in for one -->
            <xsl:for-each select="$card">
                <xsl:call-template name="ldh:DocumentNavigate">
                    <xsl:with-param name="doc-uri" select="$doc-uri"/>
                    <xsl:with-param name="query-params" select="map:remove(ldh:query-params(), 'uri')"/>
                    <xsl:with-param name="push-state" select="false()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

    <!-- the rows again, now with the labels: the metadata is tunnelled through the table's rows to the link leaf, whose
         ac:object-label reads it before anything else, so the table needs no rule of its own. Results pair with
         tables by position, as a sequence's items were drawn side by side -->
    <xsl:function name="ldh:chat-result-labelled" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="card" select="$context('card')" as="element()"/>
        <xsl:variable name="results" select="$context('result')" as="element()*"/>
        <xsl:variable name="tables" select="$card/table[contains-token(@class, 'chat-result')]" as="element()*"/>

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
    </xsl:function>

    <!-- labels are a courtesy: a lookup that fails leaves the rows naming their URIs -->
    <xsl:function name="ldh:chat-labels-missed" as="item()*" ixsl:updating="yes">
        <xsl:param name="error" as="item()*"/>

        <xsl:message>ldh:chat-labels-missed</xsl:message>
    </xsl:function>

    <!-- a result set rides the same table the document's query blocks use; a graph is counted, since the page it
         was written to is what shows it -->
    <xsl:template match="srx:sparql" mode="ldh:ExecutionResult">
        <xsl:apply-templates select="." mode="ac:ResultsTable">
            <xsl:with-param name="class" select="'ac-table ap-plain dn-tight chat-result'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="ldh:ExecutionResult">
        <span class="chat-plan-meta">
            <xsl:value-of select="count(rdf:Description)"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="key('resources', 'resources', ldh:translations())" mode="ac:label"/>
        </span>
    </xsl:template>

    <!-- a term or string the plan returned, as the service spelled it -->
    <xsl:template match="wa:value" mode="ldh:ExecutionResult">
        <span class="chat-plan-meta">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <xsl:template match="*" mode="ldh:ExecutionResult"/>

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
        <xsl:sequence select="ldh:chat-scroll($card/..)"/>
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

    <!-- the newest card is the one being read -->
    <xsl:function name="ldh:chat-scroll" ixsl:updating="yes">
        <xsl:param name="log" as="element()"/>

        <ixsl:set-property name="scrollTop" select="ixsl:get($log, 'scrollHeight')" object="$log"/>
    </xsl:function>

</xsl:stylesheet>
