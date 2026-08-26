<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
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
xmlns:geo="&geo;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:srx="&srx;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:rdfae="https://w3id.org/atomgraph/rdfa-editor#"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:variable name="block-delete-string" as="xs:string">
        <!-- TO-DO: refactor to update the following index properties -->
        <![CDATA[
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE
            {
                $this ?seq $block .
                $block ?p ?o .
            }
            WHERE
            {
                $this ?seq $block .
                FILTER(strstarts(str(?seq), concat(str(rdf:), "_")))
                OPTIONAL
                {
                    $block ?p ?o
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="block-swap-string" as="xs:string">
        <![CDATA[
            PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE {
              $this ?sourceSeq $sourceBlock .
              $this ?targetSeq $targetBlock .
              $this ?seq ?block .
            }
            INSERT {
              $this ?newSourceSeq $sourceBlock .
              $this ?newTargetSeq $targetBlock .
              $this ?newSeq ?block .
            }
            WHERE
              { $this  ?sourceSeq  $sourceBlock
                FILTER(strstarts(str(?sourceSeq), concat(str(rdf:), "_")))
                BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                $this  ?targetSeq  $targetBlock
                FILTER(strstarts(str(?targetSeq), concat(str(rdf:), "_")))
                BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ( ?targetIndex - 1 ), ?targetIndex) AS ?newTargetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ?targetIndex, ( ?targetIndex + 1 )) AS ?newSourceIndex)
                BIND(IRI(concat(str(rdf:), "_", str(?newSourceIndex))) AS ?newSourceSeq)
                BIND(IRI(concat(str(rdf:), "_", str(?newTargetIndex))) AS ?newTargetSeq)
                OPTIONAL
                  { $this  ?sourceSeq  $sourceBlock
                    FILTER(strstarts(str(?sourceSeq), concat(str(rdf:), "_")))
                    BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                    $this  ?targetSeq  $targetBlock
                    FILTER(strstarts(str(?targetSeq), concat(str(rdf:), "_")))
                    BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                    $this  ?seq  ?block
                    FILTER strstarts(str(?seq), str(rdf:_))
                    BIND(xsd:integer(substr(str(?seq), 45)) AS ?index)
                    BIND(( ( ?index > ?sourceIndex ) && ( ?index < ?targetIndex ) ) AS ?isBetweenSourceAndTarget)
                    BIND(( ( ?index < ?sourceIndex ) && ( ?index > ?targetIndex ) ) AS ?isBetweenTargetAndSource)
                    FILTER ( ?isBetweenSourceAndTarget || ?isBetweenTargetAndSource )
                    BIND(( ?index + if(?isBetweenSourceAndTarget, -1, +1) ) AS ?newIndex)
                    BIND(IRI(concat(str(rdf:), "_", str(?newIndex))) AS ?newSeq)
                  }
              }
        ]]>
    </xsl:variable>
    
    <!-- combined forward + inverse view-block lookup; substitutes VALUES ?type { ... } from the resource's rdf:types.
         Besides ?block, binds the inline-creation metadata: attachment ?property, ?inverse direction flag, the ?forClass
         to construct (property range for forward views, domain for inverse ones) and the view's ldh:container/ldh:showWhenEmpty.
         Runs against the /ns ontology union, so ldh:container asserted on a package view from the app's own namespace is visible. -->
    <xsl:variable name="ontology-view-query" as="xs:string">
        <![CDATA[
            PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>

            SELECT DISTINCT ?block ?property ?inverse ?forClass ?container ?showWhenEmpty
            WHERE {
              {
                ?property  ldh:view  ?block .
                  { ?property  rdfs:domain  ?type }
                UNION
                  { ?property  rdfs:subPropertyOf+/rdfs:domain  ?type }
                BIND(false AS ?inverse)
                OPTIONAL {
                    { ?property  rdfs:range  ?forClass }
                  UNION
                    { ?property  rdfs:subPropertyOf+/rdfs:range  ?forClass }
                }
              }
              UNION
              {
                ?property  ldh:inverseView  ?block .
                  { ?property  rdfs:range  ?type }
                UNION
                  { ?property  rdfs:subPropertyOf+/rdfs:range  ?type }
                BIND(true AS ?inverse)
                OPTIONAL {
                    { ?property  rdfs:domain  ?forClass }
                  UNION
                    { ?property  rdfs:subPropertyOf+/rdfs:domain  ?forClass }
                }
              }
              OPTIONAL { ?block  ldh:container  ?container }
              OPTIONAL { ?block  ldh:showWhenEmpty  ?showWhenEmpty }
            }
        ]]>
        <!-- VALUES ?type goes here -->
    </xsl:variable>

    <xsl:key name="element-by-about" match="*[@about]" use="@about"/>

    <!-- TEMPLATES -->

    <!-- identity transform -->
   
    <xsl:template match="@* | node()" mode="ldh:Identity">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- render row -->

    <xsl:template match="*" mode="ldh:RenderRow" as="(function(item()?) as map(*))*">
        <xsl:apply-templates mode="#current"/>

        <!--
            inject ontology-driven view blocks for any Saxon-JS wrapper produced by resource.xsl:
            outer div.block[@about] whose div.span12 child contains the inner typed resource block
            (class='block ldh-block').

            Typed-block wrappers (Object/View/Query/Chart from resource.xsl:463) are excluded
            automatically: the wrapper template no longer matches those types, and even if
            RenderRow visits their resource.xsl:463-produced wrapper, the inner
            [contains-token(@class, 'block')] predicate excludes their inner (class='row-fluid'
            from resource.xsl:518).
        -->
        <xsl:for-each select="self::div[contains-token(@class, 'block')][@about]/div[contains-token(@class, 'span12')]/div[contains-token(@class, 'block')][@typeof]">
            <xsl:variable name="typeof-uris" select="tokenize(@typeof, ' ') ! xs:anyURI(.)" as="xs:anyURI*"/>
            <xsl:variable name="values-clause" select="' VALUES ?type { ' || string-join(for $t in $typeof-uris return '&lt;' || $t || '&gt;', ' ') || ' }'" as="xs:string"/>
            <xsl:variable name="request-uri" select="ldh:href(ac:build-uri(resolve-uri('ns', ldt:base()), map{ 'query': $ontology-view-query || $values-clause }), map{})" as="xs:anyURI"/>
            <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
            <xsl:variable name="context" as="map(*)" select="
                map{
                    'request': $request,
                    'container': ../..,
                    'base-uri': ac:absolute-path(ldh:base-uri(.)),
                    'endpoint': sd:endpoint()
                }"/>
            <xsl:sequence select="ldh:load-block#3($context, ldh:ontology-view-self-thunk#1, ?)"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="text()" mode="ldh:RenderRow" as="(function(item()?) as map(*))*"/>
    
    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- provide a property label which otherwise would default to local-name() client-side (since $property-metadata is not loaded) -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']/rdfs:label | *[rdf:type/@rdf:resource = '&ldh;XHTML']/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']/rdf:value/xhtml:*" mode="bs2:FormControlTypeLabel" priority="1"/>

    <!-- autosave via ixsl:onfocusout replaces the Save button; suppress form-actions for XHTML blocks.
        Non-tunnel params do not survive xsl:next-match, so the caller-passed ones (method='post' from the ADD flow etc.) are re-declared and forwarded — otherwise the ADD form falls back to the default method='patch', whose DELETE/INSERT/WHERE update is a no-op for a resource with no triples yet -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']" mode="bs2:RowForm" priority="1">
        <xsl:param name="about" select="@rdf:about" as="xs:anyURI?"/>
        <xsl:param name="method" select="'patch'" as="xs:string"/>
        <xsl:param name="show-cancel-button" select="true()" as="xs:boolean"/>
        <xsl:next-match>
            <xsl:with-param name="about" select="$about"/>
            <xsl:with-param name="method" select="$method"/>
            <xsl:with-param name="show-cancel-button" select="$show-cancel-button"/>
            <xsl:with-param name="show-form-actions" select="false()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- EVENT LISTENERS -->
    
    <!-- show block controls -->
    
    <xsl:template match="div[contains-token(@class, 'block')][key('elements-by-class', 'row-block-controls', .)][acl:mode() = '&acl;Write']" mode="ixsl:onmousemove"> <!-- TO-DO: better selector -->        
        <!-- there might be multiple .row-block-controls in a block if the main block is followed by blocks rendered from ldh:block -->
        <xsl:variable name="row-block-controls" select="key('elements-by-class', 'row-block-controls', .)[1]" as="element()"/>
        <xsl:variable name="btn-edit" select="key('elements-by-class', 'btn-edit', $row-block-controls)" as="element()?"/>
        
        <xsl:if test="$btn-edit">
            <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')" as="xs:double"/>
            <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')" as="xs:double"/>
            <xsl:variable name="rect" select="ixsl:call(., 'getBoundingClientRect', [])"/>
            <xsl:variable name="offset-x" select="$dom-x - ixsl:get($rect, 'x')" as="xs:double"/>
            <xsl:variable name="offset-y" select="$dom-y - ixsl:get($rect, 'y')" as="xs:double"/>
            <xsl:variable name="width" select="ixsl:get($rect, 'width')" as="xs:double"/>
            <xsl:variable name="offset-x-treshold" select="120" as="xs:double"/>
            <xsl:variable name="offset-y-treshold" select="20" as="xs:double"/>

            <!-- check that the mouse is on the top edge and show the block controls if they're not already shown -->
            <xsl:if test="$offset-x &gt;= $width - $offset-x-treshold and $offset-y &lt;= $offset-y-treshold and ixsl:style($row-block-controls)?z-index = '-1'">
                <ixsl:set-style name="z-index" select="'1'" object="$row-block-controls"/>
                <ixsl:set-style name="display" select="'block'" object="$btn-edit"/>
            </xsl:if>
            <!-- check that the mouse is outside the top edge and hide the block controls if they're not already hidden -->
            <xsl:if test="$offset-x &lt; $width - $offset-x-treshold and $offset-y &gt; $offset-y-treshold and ixsl:style($row-block-controls)?z-index = '1'">
                <ixsl:set-style name="z-index" select="'-1'" object="$row-block-controls"/>
                <ixsl:set-style name="display" select="'none'" object="$btn-edit"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- show drag handle on left edge hover, but not when left sidebar is active -->

    <xsl:template match="div[contains-token(@class, 'block')][key('elements-by-class', 'drag-handle', .)][acl:mode() = '&acl;Write'][not(ixsl:style(ancestor::div[contains-token(@class, 'tab-pane')]/div[contains-token(@class, 'left-sidebar')])?display = 'block')]" mode="ixsl:onmousemove" priority="2">
        <xsl:variable name="uri" select="xs:anyURI(ancestor::div[contains-token(@class, 'document-body')]/@about)" as="xs:anyURI"/>
        <xsl:variable name="contents" select="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
        <xsl:variable name="cache-key" select="'`' || $uri || '`'" as="xs:string"/>
        <!-- cache may not have an entry for the hovered block's document URI (e.g. inactive tab); skip silently to avoid an ixsl:get warning on every mousemove -->
        <xsl:if test="ixsl:contains($contents, $cache-key) and ixsl:contains(ixsl:get($contents, $cache-key), 'results')">
            <xsl:variable name="results" select="ixsl:get(ixsl:get($contents, $cache-key), 'results')" as="document-node()"/>
            <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>

            <xsl:if test="$mode = xs:anyURI('&ldh;ContentMode')">
            <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')" as="xs:double"/>
            <xsl:variable name="rect" select="ixsl:call(., 'getBoundingClientRect', [])"/>
            <xsl:variable name="offset-x" select="$dom-x - ixsl:get($rect, 'x')" as="xs:double"/>
            <xsl:variable name="left-edge-threshold" select="30" as="xs:double"/>

            <xsl:variable name="drag-handle" select="key('elements-by-class', 'drag-handle', .)[1]" as="element()"/>

            <!-- check that the mouse is on the left edge -->
            <xsl:choose>
                <xsl:when test="$offset-x &lt;= $left-edge-threshold and ixsl:style($drag-handle)?display = 'none'">
                    <!-- get both block and span12 rectangles to calculate intersection -->
                    <xsl:variable name="span12" select="$drag-handle/parent::*[contains-token(@class, 'span12')]" as="element()"/>
                    <xsl:variable name="block-rect" select="$rect"/> <!-- block's getBoundingClientRect -->
                    <xsl:variable name="span12-rect" select="ixsl:call($span12, 'getBoundingClientRect', [])"/>

                    <!-- calculate intersection of block and span12 -->
                    <xsl:variable name="left" select="max((ixsl:get($block-rect, 'left'), ixsl:get($span12-rect, 'left')))" as="xs:double"/>
                    <xsl:variable name="top" select="max((ixsl:get($block-rect, 'top'), ixsl:get($span12-rect, 'top')))" as="xs:double"/>
                    <xsl:variable name="right" select="min((ixsl:get($block-rect, 'right'), ixsl:get($span12-rect, 'right')))" as="xs:double"/>
                    <xsl:variable name="bottom" select="min((ixsl:get($block-rect, 'bottom'), ixsl:get($span12-rect, 'bottom')))" as="xs:double"/>
                    <xsl:variable name="visible-height" select="max((0, $bottom - $top))" as="xs:double"/>

                    <!-- only show drag-handle if there's actually visible area -->
                    <xsl:if test="$visible-height > 0">
                        <!-- position drag-handle to cover the visible intersection area -->
                        <ixsl:set-style name="position" select="'fixed'" object="$drag-handle"/>
                        <ixsl:set-style name="left" select="$left || 'px'" object="$drag-handle"/>
                        <ixsl:set-style name="top" select="$top || 'px'" object="$drag-handle"/>
                        <ixsl:set-style name="height" select="$visible-height || 'px'" object="$drag-handle"/>
                        <ixsl:set-style name="z-index" select="'999'" object="$drag-handle"/>
                        <!-- enable draggable on the block when drag-handle is shown -->
                        <ixsl:set-attribute name="draggable" select="'true'" object="."/>
                        <!-- show drag-handle -->
                        <ixsl:set-style name="display" select="'block'" object="$drag-handle"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$offset-x &gt; $left-edge-threshold and ixsl:style($drag-handle)?display = 'block'">
                    <!-- disable draggable on the block when drag-handle is hidden -->
                    <ixsl:set-attribute name="draggable" select="'false'" object="."/>
                    <!-- hide drag-handle when mouse moves away from left edge -->
                    <ixsl:set-style name="display" select="'none'" object="$drag-handle"/>
                </xsl:when>
            </xsl:choose>

            <!-- call the next matching template to preserve existing block controls functionality -->
                <xsl:next-match/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- hide drag handle when mouse leaves block -->
    
    <xsl:template match="div[contains-token(@class, 'block')][key('elements-by-class', 'drag-handle', .)][acl:mode() = '&acl;Write']" mode="ixsl:onmouseout">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element mouse entered -->
        <xsl:variable name="drag-handle" select="key('elements-by-class', 'drag-handle', .)[1]" as="element()"/>
        
        <!-- only hide if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <ixsl:set-style name="display" select="'none'" object="$drag-handle"/>
        </xsl:if>
    </xsl:template>

    <!-- exit/save on click-outside is handled by the ixsl:onfocusout autosave below: the canvas holds
         focus throughout editing (toolbar/breadcrumb/find chrome all preventDefault on mousedown to keep
         it), so any exit click blurs the canvas and fires focusout. A separate onclick handler here would
         double-submit - focusout fires on mousedown, the click on mouseup - and the second PATCH 412s on
         the now-stale If-Match. -->

    <!-- click anywhere on XHTML content to enter edit mode (skip if text is selected) -->

    <xsl:template match="div[@typeof = '&ldh;XHTML'][not(descendant::form)][acl:mode() = '&acl;Write']//div[contains-token(@class, 'main')]" mode="ixsl:onclick">
        <xsl:if test="ixsl:call(ixsl:call(ixsl:window(), 'getSelection', []), 'toString', []) = ''">
            <xsl:variable name="main" select="." as="element()"/>
            <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
            <xsl:variable name="btn-edit" select="($block//button[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))])[1]" as="element()?"/>
            <xsl:if test="$btn-edit">
                <!-- Anchor the caret to the content structure, not pixels: record which content block the
                     click landed in and the char offset within it, re-resolved in the editor DOM after
                     render (ldh:focus-editable) - immune to the read/edit re-render and chrome. -->
                <xsl:variable name="ldh-state" select="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                <xsl:variable name="caret" as="map(*)?" select="rdfae:caret-at-point(xs:double(ixsl:get(ixsl:event(), 'clientX')), xs:double(ixsl:get(ixsl:event(), 'clientY')))"/>
                <!-- the content block: a top-level element of the XHTML content (div.main > content-div > block) -->
                <xsl:variable name="content-block" as="element()?" select="$caret?node/ancestor-or-self::*[parent::*[parent::* is $main]][1]"/>
                <ixsl:set-property name="pendingCaretBlock" select="$content-block ! count(preceding-sibling::*)" object="$ldh-state"/>
                <ixsl:set-property name="pendingCaretOffset" select="$content-block ! ldh:char-offset-before(., $caret?node, $caret?offset)" object="$ldh-state"/>
                <xsl:sequence select="ixsl:call($btn-edit, 'click', [])"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- autosave XMLLiteral when focus leaves the editor region (but not to the toolbar or other editor UI) -->

    <xsl:template match="div[contains-token(@class, 'rdfa-editor-content')]" mode="ixsl:onfocusout">
        <xsl:variable name="self" select="." as="element()"/>
        <xsl:variable name="related" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="item()?"/>
        <xsl:if test="empty($related) or empty($related/ancestor-or-self::*[. is $self or @id = ('edit-toolbar', 'rdfa-editor-breadcrumb') or contains-token(@class, 'rdfa-editor-ui')])">
            <xsl:variable name="form" select="ancestor::form[contains-token(@class, 'form-horizontal')][1]" as="element()?"/>
            <xsl:if test="$form">
                <xsl:sequence select="ixsl:call($form, 'requestSubmit', [])"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- rdfae:inject-chrome (edit.xsl) injects the block drag handle with class="drag-handle" -
         a leftover token from when this file's WYMeditor block handle was ported into the editor.
         In LDH that token collides with bootstrap.css's `.row-fluid.block .drag-handle { display: none }`,
         which hides every chrome handle rendered inside an edited ldh:XHTML document block. Re-inject the
         handle under an editor-specific class so the shared RDFa-Editor code needs no change (and so
         block.xsl's own key('elements-by-class', 'drag-handle') stops miscounting the chrome as an old
         block handle); the two drag gestures below re-match that class. Styling is unaffected - the
         handle is styled off data-role="chrome" in rdfa-editor.css. Keep the body in sync with edit.xsl's
         rdfae:inject-chrome (XSLT overrides the whole named template, so only the class string differs). -->
    <xsl:template name="rdfae:inject-chrome">
        <xsl:param name="block" as="element()"/>
        <xsl:if test="empty($block/*[@data-role = 'chrome'])">
            <xsl:variable name="chrome" as="element()" select="rdfae:element('span')"/>
            <ixsl:set-attribute name="data-role" select="'chrome'" object="$chrome"/>
            <ixsl:set-attribute name="class" select="'rdfa-editor-drag-handle'" object="$chrome"/>
            <ixsl:set-attribute name="contenteditable" select="'false'" object="$chrome"/>
            <ixsl:set-attribute name="title" select="'Drag to reorder'" object="$chrome"/>
            <ixsl:set-property name="textContent" select="'&#x283F;'" object="$chrome"/>
            <xsl:sequence select="ixsl:call($block, 'prepend', [ $chrome ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="span[contains-token(@class, 'rdfa-editor-drag-handle')]" mode="ixsl:onmousedown">
        <xsl:for-each select="rdfae:handle-block(.)">
            <ixsl:set-attribute name="draggable" select="'true'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="span[contains-token(@class, 'rdfa-editor-drag-handle')]" mode="ixsl:onmouseup">
        <xsl:for-each select="rdfae:handle-block(.)">
            <ixsl:remove-attribute name="draggable"/>
        </xsl:for-each>
        <xsl:call-template name="rdfae:disarm-sweep"/>
    </xsl:template>

    <!-- override inline editing form for block types (do nothing if the button is disabled) - prioritize over form.xsl -->

    <xsl:template match="div[following-sibling::div[@typeof = ('&ldh;XHTML', '&ldh;Object')]]//button[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick" priority="1">
        <xsl:param name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <!-- for block types, button.btn-edit is placed in its own div.row-fluid, therefore the next row is the actual container -->
        <xsl:param name="container" select="$block/descendant::div[@typeof][1]" as="element()"/> <!-- other resources can be nested within object -->
        
        <xsl:next-match>
<!--            <xsl:with-param name="container" select="$container"/>-->
        </xsl:next-match>
    </xsl:template>
    
    <!-- append new block form onsubmit (using POST) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;Object')]//form[contains-token(@class, 'form-horizontal')][upper-case(@method) = 'POST']" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:param name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <!-- pre-process form before submitting it: syncs input values, so it must precede ldh:parse-rdf-post -->
        <xsl:apply-templates select="." mode="ldh:FormPreSubmit"/>
        <xsl:variable name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <!-- canonicalize XML in rdf:XMLLiterals -->
        <xsl:variable name="triples" as="element()*">
            <xsl:apply-templates select="$triples" mode="ldh:CanonicalizeXML"/>
        </xsl:variable>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI(.//input[@name = 'su'] => ixsl:get('value'))" as="xs:anyURI"/>
        <xsl:variable name="sequence-number" select="count($block/preceding-sibling::div[@about]) + 1" as="xs:integer"/>
        <xsl:variable name="sequence-property" select="xs:anyURI('&rdf;_' || $sequence-number)" as="xs:anyURI"/>
        <xsl:variable name="sequence-triple" as="element()">
            <json:map>
                <json:string key="subject"><xsl:sequence select="ac:absolute-path(ldh:base-uri(.))"/></json:string>
                <json:string key="predicate"><xsl:sequence select="$sequence-property"/></json:string>
                <json:string key="object"><xsl:sequence select="$block-uri"/></json:string>
            </json:map>
        </xsl:variable>
        
        <xsl:next-match>
            <xsl:with-param name="block" select="$block"/>
            <!-- append $sequence-triple to $request-body that is sent with the HTTP request, but not to $resources which are rendered after the block update (don't want to show it) -->
            <xsl:with-param name="request-body" as="document-node()">
                <xsl:document>
                    <rdf:RDF>
                        <xsl:sequence select="ldh:triples-to-descriptions(($triples, $sequence-triple))"/>
                    </rdf:RDF>
                </xsl:document>
            </xsl:with-param>
        </xsl:next-match>
    </xsl:template>

    <!-- delete block onclick (increased priority to take precedence over form.xsl .btn-remove-resource) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;Object')]//button[contains-token(@class, 'btn-remove-resource')]" mode="ixsl:onclick" priority="3">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>

        <xsl:choose>
            <!-- delete existing block -->
            <xsl:when test="$block/@about">
                <!-- show a confirmation prompt -->
                <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))) ])">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <xsl:variable name="block-uri" select="$block/@about" as="xs:anyURI"/>
                    <xsl:variable name="update-string" select="replace($block-delete-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$block', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ldh:href(ac:absolute-path(ldh:base-uri(.)), map{})" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="onBlockDelete">
                                <xsl:with-param name="block" select="$block"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:when>
            <!-- remove block that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- start dragging block when drag-handle is dragged -->
    
    <xsl:template match="div[contains-token(@class, 'drag-handle')]" mode="ixsl:ondragstart">
        <!-- find the parent block to drag -->
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][1]" as="element()?"/>
        <xsl:for-each select="$block">
            <ixsl:set-property name="dataTransfer.effectAllowed" select="'move'" object="ixsl:event()"/>
            <xsl:variable name="block-uri" select="@about" as="xs:anyURI"/>
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'setData', [ 'text/uri-list', $block-uri ])"/>
            <!-- make it appear like the whole block is being dragged -->
            <xsl:sequence select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'setDragImage', [ ., 0, 0 ])"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- cleanup after drag ends -->
    
    <xsl:template match="div[contains-token(@class, 'drag-handle')]" mode="ixsl:ondragend">
        <!-- hide the drag-handle -->
        <ixsl:set-style name="display" select="'none'" object="."/>
        <!-- disable draggable on the parent block -->
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()?"/>
        <xsl:if test="exists($block)">
            <ixsl:set-attribute name="draggable" select="'false'" object="$block"/>
        </xsl:if>
    </xsl:template>

    <!-- dragging block over other block -->
    <!-- only handle if drag originated from drag-handle (has text/uri-list item) -->
    <!-- these four document-block DnD handlers (ondragover/enter/leave/drop) exclude the RDFa editor
         subtree: the editor renders inside a .content-body > .block, so without the guard this pattern
         also matches every element in .rdfa-editor-content and - having higher import precedence than
         the imported edit.xsl - shadows the editor's own block DnD (edit.xsl), killing its drop marks
         and reorder. Excluding the editor lets those events fall through to the editor's handlers. -->

    <xsl:template match="*[ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][acl:mode() = '&acl;Write']][not(ancestor-or-self::*[contains-token(@class, 'rdfa-editor-content')])]" mode="ixsl:ondragover" priority="1">
        <xsl:variable name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][1]" as="element()"/>
        <xsl:variable name="uri" select="xs:anyURI($block/parent::div/parent::div[contains-token(@class, 'document-body')]/@about)" as="xs:anyURI"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>

        <xsl:if test="$mode = xs:anyURI('&ldh;ContentMode')">
            <xsl:variable name="items" select="ixsl:get(ixsl:get(ixsl:event(), 'dataTransfer'), 'items')"/>
            <xsl:variable name="has-uri-item" select="if (ixsl:get($items, 'length') > 0) then ixsl:get(ixsl:get($items, '0'), 'type') = 'text/uri-list' else false()" as="xs:boolean"/>
            <xsl:if test="$has-uri-item">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
                <ixsl:set-property name="dataTransfer.dropEffect" select="'move'" object="ixsl:event()"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- change the style of blocks when block is dragged over them -->
    <!-- only handle if drag originated from drag-handle (has text/uri-list item) -->

    <xsl:template match="*[ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][acl:mode() = '&acl;Write']][not(ancestor-or-self::*[contains-token(@class, 'rdfa-editor-content')])]" mode="ixsl:ondragenter" priority="1">
        <xsl:variable name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][1]" as="element()"/>
        <xsl:variable name="uri" select="xs:anyURI($block/parent::div/parent::div[contains-token(@class, 'document-body')]/@about)" as="xs:anyURI"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>

        <xsl:if test="$mode = xs:anyURI('&ldh;ContentMode')">
            <xsl:variable name="items" select="ixsl:get(ixsl:get(ixsl:event(), 'dataTransfer'), 'items')"/>
            <xsl:variable name="has-uri-item" select="if (ixsl:get($items, 'length') > 0) then ixsl:get(ixsl:get($items, '0'), 'type') = 'text/uri-list' else false()" as="xs:boolean"/>
            <xsl:if test="$has-uri-item">
                <xsl:sequence select="ixsl:call(ixsl:get($block, 'classList'), 'toggle', [ 'drag-over', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- only handle if drag originated from drag-handle (has text/uri-list item) -->

    <xsl:template match="*[ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][acl:mode() = '&acl;Write']][not(ancestor-or-self::*[contains-token(@class, 'rdfa-editor-content')])]" mode="ixsl:ondragleave" priority="1">
        <xsl:variable name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][1]" as="element()"/>
        <xsl:variable name="uri" select="xs:anyURI($block/parent::div/parent::div[contains-token(@class, 'document-body')]/@about)" as="xs:anyURI"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>

        <xsl:if test="$mode = xs:anyURI('&ldh;ContentMode')">
            <xsl:variable name="items" select="ixsl:get(ixsl:get(ixsl:event(), 'dataTransfer'), 'items')"/>
            <xsl:variable name="has-uri-item" select="if (ixsl:get($items, 'length') > 0) then ixsl:get(ixsl:get($items, '0'), 'type') = 'text/uri-list' else false()" as="xs:boolean"/>
            <xsl:if test="$has-uri-item">
                <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element drag entered (optional) -->

                <!-- only remove class if the related target does not have the block as ancestor (i.e. drag actually left the block) -->
                <xsl:if test="not($related-target/ancestor-or-self::div[. is $block])">
                    <xsl:sequence select="ixsl:call(ixsl:get($block, 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- dropping block over other top-level block -->
    <!-- only handle if drag originated from drag-handle (has text/uri-list item) -->

    <xsl:template match="*[ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][acl:mode() = '&acl;Write']][not(ancestor-or-self::*[contains-token(@class, 'rdfa-editor-content')])]" mode="ixsl:ondrop" priority="1">
        <xsl:variable name="block" select="ancestor-or-self::div[contains-token(@class, 'block')][parent::div[contains-token(@class, 'content-body')]][1]" as="element()"/>
        <xsl:variable name="uri" select="xs:anyURI($block/parent::div/parent::div[contains-token(@class, 'document-body')]/@about)" as="xs:anyURI"/>
        <xsl:variable name="results" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $uri || '`'), 'results')" as="document-node()"/>
        <xsl:variable name="mode" select="ac:mode($results)" as="xs:anyURI"/>

        <xsl:if test="$mode = xs:anyURI('&ldh;ContentMode')">
            <xsl:variable name="items" select="ixsl:get(ixsl:get(ixsl:event(), 'dataTransfer'), 'items')"/>
            <xsl:variable name="has-uri-item" select="if (ixsl:get($items, 'length') > 0) then ixsl:get(ixsl:get($items, '0'), 'type') = 'text/uri-list' else false()" as="xs:boolean"/>
            <xsl:if test="$has-uri-item">
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
                <xsl:variable name="block-uri" select="$block/@about" as="xs:anyURI?"/>
                <xsl:variable name="drop-block-uri" select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'getData', [ 'text/uri-list' ])" as="xs:anyURI"/>

                <xsl:sequence select="ixsl:call(ixsl:get($block, 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>

                <!-- only persist the change if the block is already saved and has an @about -->
                <xsl:if test="$block-uri">
                    <!-- move dropped element after this element, if they're not the same -->
                    <xsl:if test="not($block-uri = $drop-block-uri)">
                        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                        <!-- TO-DO: sketchy workaround to select block-level elements only because we might have duplicate @about values -->
                        <xsl:variable name="drop-block" select="key('element-by-about', $drop-block-uri)[contains-token(@class, 'block')]" as="element()"/>
                        <xsl:sequence select="ixsl:call($block, 'after', [ $drop-block ])"/>
                        <!-- TO-DO: use a VALUES block instead -->
                        <xsl:variable name="update-string" select="replace($block-swap-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$targetBlock', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$sourceBlock', '&lt;' || $drop-block-uri || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="request-uri" select="ldh:href(ac:absolute-path(ldh:base-uri(.)), map{})" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                                <xsl:call-template name="onBlockSwap"/>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- CALLBACKS -->
    
    <xsl:function name="ldh:load-block" ixsl:updating="yes" as="map(*)">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="thunk" as="function(map(*)) as item()*"/>
        <xsl:param name="ignored" as="item()?"/>

        <xsl:sequence select="
            $thunk($context) =>
                ixsl:then(
                    ldh:hide-block-progress-bar(
                        $context,
                        ?
                        )
                    )
          "/>
    </xsl:function>

    <!-- ontology-view block injection: ontology query (?property ldh:view ?block) → per-URI RDF fetch → render via bs2:Row → insert + hydrate -->

    <xsl:function name="ldh:ontology-view-self-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:message>ldh:ontology-view-self-thunk</xsl:message>

        <xsl:sequence select="
            ixsl:resolve($context) =>
                ixsl:then(ldh:ontology-view-query-thunk#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:ontology-view-query-thunk" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:message>ldh:ontology-view-query-thunk</xsl:message>

        <xsl:sequence select="
            ixsl:http-request($context('request')) =>
                ixsl:then(ldh:rethread-response($context, ?)) =>
                ixsl:then(ldh:handle-response#1) =>
                ixsl:then(ldh:ontology-view-fetch-thunk#1)
        "/>
    </xsl:function>

    <!-- handle SPARQL XML response: fan out one HTTP fetch per view URI -->
    <xsl:function name="ldh:ontology-view-fetch-thunk" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>

        <xsl:message>ldh:ontology-view-fetch-thunk</xsl:message>

        <xsl:if test="$response?status = 200 and $response?media-type = 'application/sparql-results+xml'">
            <xsl:variable name="results" select="$response?body" as="document-node()"/>

            <!-- one fetch per view; the first row of each group supplies the inline-creation metadata (multiple ?type/?forClass rows can occur) -->
            <xsl:for-each-group select="$results/srx:sparql/srx:results/srx:result[srx:binding[@name = 'block']/srx:uri]" group-by="srx:binding[@name = 'block']/srx:uri">
                <xsl:variable name="view-uri" select="xs:anyURI(current-grouping-key())" as="xs:anyURI"/>
                <xsl:variable name="view-request-uri" select="ldh:href(ac:document-uri($view-uri), map{})" as="xs:anyURI"/>
                <xsl:variable name="view-request" select="map{ 'method': 'GET', 'href': $view-request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <!-- ?forClass is read from srx:uri only: bnode ranges (e.g. owl:unionOf lists) cannot be constructed -->
                <xsl:variable name="view-metadata" as="map(*)*">
                    <xsl:for-each select="srx:binding[@name = 'property']/srx:uri">
                        <xsl:sequence select="map{ 'view-property': xs:anyURI(.) }"/>
                    </xsl:for-each>
                    <xsl:if test="srx:binding[@name = 'inverse']/srx:literal = 'true'">
                        <xsl:sequence select="map{ 'view-inverse': true() }"/>
                    </xsl:if>
                    <xsl:for-each select="srx:binding[@name = 'forClass']/srx:uri">
                        <xsl:sequence select="map{ 'view-for-class': xs:anyURI(.) }"/>
                    </xsl:for-each>
                    <xsl:for-each select="srx:binding[@name = 'container']/srx:uri">
                        <xsl:sequence select="map{ 'view-container': xs:anyURI(.) }"/>
                    </xsl:for-each>
                    <xsl:for-each select="srx:binding[@name = 'showWhenEmpty']/srx:literal">
                        <xsl:sequence select="map{ 'view-show-when-empty': string(.) }"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="view-context" as="map(*)" select="map:merge(($context, map{ 'request': $view-request, 'view-uri': $view-uri }, $view-metadata))"/>

                <ixsl:promise select="
                    ixsl:http-request($view-request) =>
                        ixsl:then(ldh:rethread-response($view-context, ?)) =>
                        ixsl:then(ldh:handle-response#1) =>
                        ixsl:then(ldh:load-object-metadata#1) =>
                        ixsl:then(ldh:http-request-threaded(?, 'metadata-request', 'metadata-response')) =>
                        ixsl:then(ldh:handle-response(?, 'metadata-response')) =>
                        ixsl:then(ldh:set-object-metadata#1) =>
                        ixsl:then(ldh:http-request-threaded(?, 'ns-metadata-request', 'ns-metadata-response')) =>
                        ixsl:then(ldh:handle-response(?, 'ns-metadata-response')) =>
                        ixsl:then(ldh:set-object-metadata-ns#1) =>
                        ixsl:then(ldh:merge-object-metadata#1) =>
                        ixsl:then(ldh:load-property-metadata#1) =>
                        ixsl:then(ldh:http-request-threaded(?, 'property-metadata-request', 'property-metadata-response')) =>
                        ixsl:then(ldh:handle-response(?, 'property-metadata-response')) =>
                        ixsl:then(ldh:set-property-metadata#1) =>
                        ixsl:then(ldh:ontology-view-render-thunk#1)
                    "
                    on-failure="ldh:promise-failure#1"/>
            </xsl:for-each-group>
        </xsl:if>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- render one view block from its loaded RDF. Creatable views (ldh:container + inferred forClass) first HEAD the container for its acl:mode Link headers, which gate the Create button; the rest insert directly -->
    <xsl:function name="ldh:ontology-view-render-thunk" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:message>ldh:ontology-view-render-thunk</xsl:message>

        <xsl:choose>
            <xsl:when test="map:contains($context, 'view-container') and map:contains($context, 'view-for-class')">
                <xsl:variable name="container-request" select="map{ 'method': 'HEAD', 'href': ldh:href($context('view-container'), map{}), 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
                <xsl:variable name="container-context" select="map:merge(($context, map{ 'container-request': $container-request }))" as="map(*)"/>

                <ixsl:promise select="
                    ixsl:resolve($container-context) =>
                        ixsl:then(ldh:http-request-threaded(?, 'container-request', 'container-response')) =>
                        ixsl:then(ldh:handle-response(?, 'container-response')) =>
                        ixsl:then(ldh:set-container-acl-modes#1) =>
                        ixsl:then(ldh:ontology-view-insert#1)
                    "
                    on-failure="ldh:promise-failure#1"/>

                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:ontology-view-insert($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- extract acl:mode URIs from the container HEAD response's Link headers (emitted by ResponseHeadersFilter, forwarded for remote containers by ProxyRequestFilter); same parsing as ldh:rdf-document-response. A non-200 response yields no modes, which downstream reads as no Create button -->
    <xsl:function name="ldh:set-container-acl-modes" as="map(*)" ixsl:updating="no">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('container-response')" as="map(*)"/>
        <xsl:variable name="acl-mode-links" select="tokenize($response?headers?link, ',')[contains(., '&acl;mode')]" as="xs:string*"/>
        <xsl:variable name="acl-modes" select="for $mode-link in $acl-mode-links return xs:anyURI(substring-before(substring-after(substring-before($mode-link, ';'), '&lt;'), '&gt;'))" as="xs:anyURI*"/>

        <xsl:sequence select="map:merge(($context, map{ 'container-acl-modes': $acl-modes }))"/>
    </xsl:function>

    <!-- append the rendered view block into the wrapper's .span12 alongside the typed resource block, stamp the inline-creation metadata as data-* attributes, hydrate via existing ldh:RenderRow chain -->
    <xsl:function name="ldh:ontology-view-insert" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="span12" select="$container/div[contains-token(@class, 'span12')]" as="element()"/>
        <xsl:variable name="view-uri" select="$context('view-uri')" as="xs:anyURI"/>
        <xsl:variable name="base-uri" select="$context('base-uri')" as="xs:anyURI"/>

        <xsl:message>ldh:ontology-view-insert</xsl:message>

        <xsl:if test="$response?status = 200 and $response?media-type = 'application/rdf+xml'">
            <xsl:variable name="view-rdf" select="$response?body" as="document-node()"/>
            <xsl:variable name="view-resource" select="key('resources', $view-uri, $view-rdf)" as="element()?"/>

            <xsl:if test="$view-resource">
                <xsl:variable name="id" select="'id' || ac:uuid()" as="xs:string"/>
                <xsl:variable name="view-block-html" as="element()">
                    <xsl:apply-templates select="$view-resource" mode="bs2:Row">
                        <xsl:with-param name="about" select="xs:anyURI($base-uri || $id)"/>
                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="property-metadata" select="$context('property-metadata')" tunnel="yes"/>
                        <xsl:with-param name="object-metadata" select="$context('object-metadata')" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:variable>

                <!-- append into the wrapper's .span12 so the new block's ancestor::*[@about][1] is the outer #this with @about ending in #this -->
                <xsl:sequence select="ixsl:call($span12, 'append', [ $view-block-html ])[current-date() lt xs:date('2000-01-01')]"/>

                <!-- hydrate the freshly-injected wrapper via the existing view.xsl:62 RenderRow handler -->
                <xsl:variable name="injected" select="$span12/*[last()]" as="element()?"/>
                <xsl:if test="$injected">
                    <!-- stamp inline-creation metadata before hydration so ldh:RenderViewResults can read it off the wrapper -->
                    <xsl:for-each select="$injected">
                        <xsl:if test="map:contains($context, 'view-property')">
                            <ixsl:set-attribute name="data-property" select="string($context('view-property'))" object="."/>
                        </xsl:if>
                        <xsl:if test="map:contains($context, 'view-inverse')">
                            <ixsl:set-attribute name="data-inverse" select="'true'" object="."/>
                        </xsl:if>
                        <xsl:if test="map:contains($context, 'view-for-class')">
                            <ixsl:set-attribute name="data-for-class" select="string($context('view-for-class'))" object="."/>
                        </xsl:if>
                        <xsl:if test="map:contains($context, 'view-container')">
                            <ixsl:set-attribute name="data-container" select="string($context('view-container'))" object="."/>
                        </xsl:if>
                        <xsl:if test="map:contains($context, 'view-show-when-empty')">
                            <ixsl:set-attribute name="data-show-when-empty" select="string($context('view-show-when-empty'))" object="."/>
                        </xsl:if>
                        <xsl:if test="map:contains($context, 'container-acl-modes')">
                            <ixsl:set-attribute name="data-acl-modes" select="string-join($context('container-acl-modes'), ' ')" object="."/>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:variable name="factories" as="(function(item()?) as item()*)*">
                        <xsl:apply-templates select="$injected" mode="ldh:RenderRow"/>
                    </xsl:variable>
                    <xsl:for-each select="$factories">
                        <xsl:variable name="factory" select="."/>
                        <ixsl:promise select="$factory(())" on-failure="ldh:promise-failure#1"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
        </xsl:if>

        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- object-metadata fetch helpers: shared between view.xsl's view-results chain and client.xsl's document-load chain. Build a metadata-request from the cross-doc object URIs in the response RDF (read from $response-key in context); the chain then fires it via ldh:http-request-threaded(?, 'metadata-request', 'metadata-response') and ldh:set-object-metadata stores the result body under 'object-metadata' for the $object-metadata tunnel consumed by ac:object-label. -->

    <xsl:function name="ldh:load-object-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="ldh:load-object-metadata($context, 'response')"/>
    </xsl:function>

    <xsl:function name="ldh:load-object-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response-key" as="xs:string"/>
        <xsl:variable name="endpoint" select="$context('endpoint')" as="xs:anyURI"/>
        <!-- prefer caller-supplied object-uris in context (form flows compute these from $resource or $body upstream); fall back to extracting from the named response (block flows) -->
        <xsl:variable name="object-uris" as="xs:string*" select="
            if (map:contains($context, 'object-uris')) then $context('object-uris')
            else
                let $response := $context($response-key)
                return if ($response?status = 200 and $response?media-type = 'application/rdf+xml')
                       then distinct-values($response?body/rdf:RDF/rdf:Description/*/@rdf:resource[not(key('resources', .))])
                       else ()"/>
        <xsl:variable name="values" select="' VALUES $this { ' || string-join(for $uri in $object-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
        <xsl:variable name="query-string" select="$object-metadata-query || $values" as="xs:string"/>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:href($endpoint), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <!-- second request resolves labels of object URIs that are ontology terms (rdf:type/class values etc.) from the /ns endpoint, whose graph-free query targets the in-memory ontology default graph; merged with the /sparql result by ldh:merge-object-metadata -->
        <xsl:variable name="ns-query-string" select="$object-metadata-ns-query || $values" as="xs:string"/>
        <xsl:variable name="ns-request" select="map{ 'method': 'POST', 'href': ldh:href(resolve-uri('ns', ldt:base())), 'media-type': 'application/sparql-query', 'body': $ns-query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>

        <xsl:message>ldh:load-object-metadata</xsl:message>

        <!-- always emit both requests so the downstream http-request-threaded steps have keys to read; empty VALUES results in empty responses which set-object-metadata / set-object-metadata-ns store as empty documents and ac:object-label falls through to its fragment fallback -->
        <xsl:sequence select="map:merge(($context, map{ 'metadata-request': $request, 'ns-metadata-request': $ns-request }))"/>
    </xsl:function>

    <xsl:function name="ldh:set-object-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('metadata-response')" as="map(*)"/>

        <xsl:message>ldh:set-object-metadata</xsl:message>

        <!-- view-block chain tracks progress; document-load chain doesn't -->
        <xsl:if test="map:contains($context, 'cache')">
            <xsl:sequence select="ldh:update-progress-counter($context('cache'), $context, 'complete', ())"/>
        </xsl:if>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="object-metadata" select="?body" as="document-node()?"/>
                    <xsl:sequence select="map:merge(($context, map{ 'object-metadata': $object-metadata }))"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- ignore object metadata loading errors - treat as empty metadata -->
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <!-- stores the /ns object-metadata response (labels for object URIs that are ontology terms) under 'object-metadata-ns'; ldh:merge-object-metadata folds it into 'object-metadata'. Error-tolerant: a non-2xx response is treated as empty metadata -->
    <xsl:function name="ldh:set-object-metadata-ns" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('ns-metadata-response')" as="map(*)"/>

        <xsl:message>ldh:set-object-metadata-ns</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="object-metadata-ns" select="?body" as="document-node()?"/>
                    <xsl:sequence select="map:merge(($context, map{ 'object-metadata-ns': $object-metadata-ns }))"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- ignore ontology metadata loading errors - treat as empty metadata -->
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <!-- merges the /sparql ('object-metadata') and /ns ('object-metadata-ns') label documents into a single 'object-metadata' document (via ldh:merge-metadata → ldh:MergeRDF mode) consumed by ac:object-label. use-last because 'object-metadata' already exists in the context -->
    <xsl:function name="ldh:merge-object-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:message>ldh:merge-object-metadata</xsl:message>

        <xsl:variable name="merged" select="ldh:merge-metadata($context('object-metadata'), $context('object-metadata-ns'))" as="document-node()"/>
        <xsl:sequence select="map:merge(($context, map{ 'object-metadata': $merged }), map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <!-- property-metadata fetch helpers: mirror the object-metadata pair above, but DESCRIBE the property URIs (rdfs:label / skos:prefLabel etc. resolved via the application's /ns ontology store) so that ac:property-label can resolve vocabulary labels client-side. Chain wiring: ldh:http-request-threaded(?, 'property-metadata-request', 'property-metadata-response') then ldh:set-property-metadata stores the body under 'property-metadata' for the tunnel consumed by ac:property-label. -->

    <xsl:function name="ldh:load-property-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="ldh:load-property-metadata($context, 'response')"/>
    </xsl:function>

    <xsl:function name="ldh:load-property-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response-key" as="xs:string"/>
        <!-- prefer caller-supplied property-uris in context (form flows compute these from $resource or $body upstream); fall back to extracting from the named response (block flows) -->
        <xsl:variable name="property-uris" as="xs:string*" select="
            if (map:contains($context, 'property-uris')) then $context('property-uris')
            else
                let $response := $context($response-key)
                return if ($response?status = 200 and $response?media-type = 'application/rdf+xml')
                       then distinct-values($response?body/rdf:RDF/rdf:Description/*/concat(namespace-uri(), local-name()))
                       else ()"/>
        <xsl:variable name="query-string" select="$property-metadata-query || ' VALUES $Type { ' || string-join(for $uri in $property-uris return '&lt;' || $uri || '&gt;', ' ') || ' }'" as="xs:string"/>
        <xsl:variable name="request" select="map{ 'method': 'POST', 'href': ldh:href(resolve-uri('ns', ldt:base())), 'media-type': 'application/sparql-query', 'body': $query-string, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>

        <xsl:message>ldh:load-property-metadata</xsl:message>

        <xsl:sequence select="map:merge(($context, map{ 'property-metadata-request': $request }))"/>
    </xsl:function>

    <xsl:function name="ldh:set-property-metadata" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('property-metadata-response')" as="map(*)"/>

        <xsl:message>ldh:set-property-metadata</xsl:message>

        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:variable name="property-metadata" select="?body" as="document-node()?"/>
                    <xsl:sequence select="map:merge(($context, map{ 'property-metadata': $property-metadata }))"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- ignore property metadata loading errors - treat as empty metadata -->
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="ldh:hide-block-progress-bar" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?"/>
              
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        
        <!-- hide the progress bar -->
        <xsl:for-each select="$container/ancestor::div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>

    <!-- Progress tracking with dynamic counters -->

    <xsl:function name="ldh:update-progress-counter" as="empty-sequence()" ixsl:updating="yes">
        <xsl:param name="cache" as="item()"/>
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="action" as="xs:string"/>
        <xsl:param name="value" as="xs:integer?"/>

        <xsl:choose>
            <!-- Initialize with total step count -->
            <xsl:when test="$action = 'init'">
                <xsl:variable name="total-steps" select="if (exists($value)) then $value else 4" as="xs:integer"/>
                <xsl:variable name="step-size" select="100 div $total-steps" as="xs:double"/>

                <ixsl:set-property name="current-progress" select="0" object="$cache"/>
                <ixsl:set-property name="step-size" select="$step-size" object="$cache"/>
                <ixsl:set-property name="completed-steps" select="0" object="$cache"/>
                <ixsl:set-property name="total-steps" select="$total-steps" object="$cache"/>
                <ixsl:set-property name="start-time" select="ixsl:call(ixsl:window(), 'Date.now', [])" object="$cache"/>

                <!-- Display 0% -->
                <xsl:sequence select="ldh:display-progress($cache, $context, 0)"/>
            </xsl:when>

            <!-- Increment progress by one step -->
            <xsl:when test="$action = 'complete'">
                <xsl:variable name="step-size" select="ixsl:get($cache, 'step-size')" as="xs:double"/>
                <xsl:variable name="completed-steps" select="xs:integer(ixsl:get($cache, 'completed-steps')) + 1" as="xs:integer"/>
                <xsl:variable name="total-steps" select="xs:integer(ixsl:get($cache, 'total-steps'))" as="xs:integer"/>
                <xsl:variable name="progress" select="min((($completed-steps * $step-size), 100))" as="xs:double"/>
                <xsl:variable name="elapsed" select="ixsl:call(ixsl:window(), 'Date.now', []) - ixsl:get($cache, 'start-time')" as="xs:double"/>

                <ixsl:set-property name="completed-steps" select="$completed-steps" object="$cache"/>
                <ixsl:set-property name="current-progress" select="$progress" object="$cache"/>

                <xsl:sequence select="ldh:display-progress($cache, $context, $progress)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Helper: Update visual progress bar -->
    <xsl:function name="ldh:display-progress" as="empty-sequence()" ixsl:updating="yes">
        <xsl:param name="cache" as="item()"/>
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="percent" as="xs:double"/>

        <xsl:if test="map:contains($context, 'container')">
            <xsl:variable name="container" select="$context('container')" as="element()"/>

            <xsl:for-each select="$container/ancestor::div[contains-token(@class, 'progress')][contains-token(@class, 'active')][1]">
                <ixsl:set-style name="width" select="$percent || '%'" object=".//div[contains-token(@class, 'bar')]"/>

                <!-- auto-hide when 100% -->
                <xsl:if test="$percent ge 100">
                    <ixsl:set-style name="z-index" select="'-1'" object="./div[contains-token(@class, 'row-block-controls')]"/>

                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

    <!-- block delete -->

    <xsl:template name="onBlockDelete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="block" as="element()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = (200, 204)">
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not delete block' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- block swap (drag & drop) -->
    
    <xsl:template name="onBlockSwap">
        <xsl:context-item as="map(*)" use="required"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:choose>
            <xsl:when test="?status = 204">
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not swap block' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>