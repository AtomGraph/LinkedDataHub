<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
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
xmlns:fn="http://www.w3.org/2005/xpath-functions"
xmlns:lapp="&lapp;"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:function name="ldh:request-uri" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:location())"/>
    </xsl:function>

    <xsl:function name="ac:uri" as="xs:anyURI?">
        <xsl:sequence select="if (ldh:query-params()?uri) then xs:anyURI(ldh:query-params()?uri) else ()"/>
    </xsl:function>

    <!-- overrides the Web-Client stub; server-side ac:uuid() is the com.atomgraph.client.writer.function.UUID extension function.
         crypto.randomUUID() is the platform's own generator, which retires the hand-written UUID.js the page used to load for this
         alone. It is a secure-context API, and LDH is served over https - on an insecure origin crypto.randomUUID is undefined -->
    <xsl:function name="ac:uuid" as="xs:string">
        <xsl:value-of select="ixsl:call(ixsl:get(ixsl:window(), 'crypto'), 'randomUUID', [])"/>
    </xsl:function>

    <!-- deterministic 32-bit djb2 over the string's codepoints, for identifiers that have to survive a reload -
         the counterpart to ac:uuid() wherever the thing being named is re-derived rather than stored.
         Multiplication and addition only: XPath 3.1 has no bitwise operators, so FNV-1a's XOR is out. The running
         value stays below 2^38, well inside exact double range, so the result is identical under Saxon-HE and
         Saxon-JS however each of them backs xs:integer -->
    <xsl:function name="ldh:hash-code" as="xs:integer">
        <xsl:param name="string" as="xs:string"/>

        <xsl:sequence select="fold-left(string-to-codepoints($string), 5381, function($acc as xs:integer, $codepoint as xs:integer) as xs:integer { ($acc * 33 + $codepoint) mod 4294967296 })"/>
    </xsl:function>

    <!-- ldh:query-params is defined once in imports/default.xsl and works in both contexts via ldh:request-uri -->

    <xsl:function name="ldh:base-uri" as="xs:anyURI">
        <xsl:param name="arg" as="node()"/> <!-- ignored -->

        <xsl:choose>
            <xsl:when test="ac:uri()">
                <xsl:sequence select="ac:document-uri(ac:uri())"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- ignore query params such as ?mode -->
                <xsl:sequence select="ac:absolute-path(ldh:request-uri())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="ldt:base" as="xs:anyURI">
        <xsl:variable name="active-pane" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]" as="element()?"/>
        <xsl:sequence select="if ($active-pane and ixsl:contains($active-pane, 'dataset.base')) then xs:anyURI(ixsl:get($active-pane, 'dataset.base')) else xs:anyURI(lapp:origin(ldh:request-uri()) || '/')"/>
    </xsl:function>

    <xsl:function name="acl:mode" as="xs:anyURI*">
        <xsl:sequence select="(
            if (ixsl:contains(ixsl:window(), 'LinkedDataHub.acl-modes.read')) then xs:anyURI('&acl;Read') else (),
            if (ixsl:contains(ixsl:window(), 'LinkedDataHub.acl-modes.append')) then xs:anyURI('&acl;Append') else (),
            if (ixsl:contains(ixsl:window(), 'LinkedDataHub.acl-modes.write')) then xs:anyURI('&acl;Write') else (),
            if (ixsl:contains(ixsl:window(), 'LinkedDataHub.acl-modes.control')) then xs:anyURI('&acl;Control') else ()
        )"/>
    </xsl:function>

    <xsl:function name="sd:endpoint" as="xs:anyURI">
        <xsl:variable name="active-pane" select="id('tab-content', ixsl:page())/div[contains-token(@class, 'tab-pane')][contains-token(@class, 'active')]" as="element()?"/>
        <xsl:sequence select="if ($active-pane and ixsl:contains($active-pane, 'dataset.endpoint')) then xs:anyURI(ixsl:get($active-pane, 'dataset.endpoint')) else resolve-uri('sparql', ldt:base())"/>
    </xsl:function>

    <xsl:function name="lapp:application" as="xs:anyURI?">
        <xsl:sequence select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.application')) then xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.application')) else ()"/>
    </xsl:function>

    <!-- TimeMap URI extracted from the Link response header by ldh:rdf-document-response; blank when the document is not versioned -->
    <xsl:function name="ldh:timemap" as="xs:anyURI?">
        <xsl:sequence select="if (ixsl:contains(ixsl:window(), 'LinkedDataHub.timemap') and not(ixsl:get(ixsl:window(), 'LinkedDataHub.timemap') = '')) then xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.timemap')) else ()"/>
    </xsl:function>

    <!-- Memento-Datetime is a response header, not available in the client context; ?version= pages render server-side -->
    <xsl:function name="ldh:memento-datetime" as="xs:string?">
        <xsl:sequence select="()"/>
    </xsl:function>

    <xsl:function name="lapp:origin" as="xs:anyURI">
        <xsl:sequence select="lapp:origin(ldt:base())"/>
    </xsl:function>

    <xsl:function name="ldh:query-type" as="xs:string?">
        <xsl:param name="query-string" as="xs:string"/>
        
        <xsl:sequence select="analyze-string($query-string, '[^a-zA-Z]?(SELECT|ASK|DESCRIBE|CONSTRUCT)[^a-zA-Z]', 'i')/fn:match[1]/fn:group[@nr = '1']/string() => upper-case()"/>
    </xsl:function>

    <xsl:function name="ldh:new-object">
        <xsl:sequence select="ixsl:new('Object', [])"/>
    </xsl:function>

    <!-- resolved value of a design token (CSS custom property on the root element), for canvas
         libraries (Google Charts, 3d-force-graph, OpenLayers) that take concrete color strings -->
    <xsl:function name="ldh:css-token" as="xs:string">
        <xsl:param name="name" as="xs:string"/>

        <xsl:sequence select="normalize-space(ixsl:call(ixsl:call(ixsl:window(), 'getComputedStyle', [ ixsl:page()/* ]), 'getPropertyValue', [ $name ]))"/>
    </xsl:function>
    
    <!-- format URLs in DataTable as HTML links. !!! Saxon-JS cannot intercept Google Charts events, therefore set a full proxied URL !!! -->
    <xsl:template match="@rdf:about[starts-with(., 'http://')] | @rdf:about[starts-with(., 'https://')] | @rdf:resource[starts-with(., 'http://')] | @rdf:resource[starts-with(., 'https://')] | srx:uri[starts-with(., 'http://')] | srx:uri[starts-with(., 'https://')]" mode="ac:DataTable">
        <json:string key="v">&lt;a href="<xsl:value-of select="ldh:href(xs:anyURI(.), map{})"/>"&gt;<xsl:value-of select="."/>&lt;/a&gt;</json:string>
    </xsl:template>

    <!-- escape < > in literals so they don't get interpreted as HTML tags -->
    <xsl:template match="rdf:Description/*/text()[../@rdf:datatype = '&xsd;string' or not(../@rdf:datatype)] | srx:literal[@datatype = '&xsd;string' or not(@datatype)] " mode="ac:DataTable">
        <json:string key="v"><xsl:value-of select="replace(replace(., '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/></json:string>
    </xsl:template>
    
    <xsl:function name="ac:rdf-data-table">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="json" as="xs:string">
            <xsl:value-of>
                <xsl:choose>
                    <xsl:when test="$category">
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="properties" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- if no $category specified, show resource URI/ID as category -->
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="resource-ids" select="true()" tunnel="yes"/>
                            <xsl:with-param name="properties" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:value-of>
        </xsl:variable>
        
        <xsl:variable name="json-obj" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $json ])"/>
        <xsl:sequence select="ixsl:new('google.visualization.DataTable', [ $json-obj ])"/>
    </xsl:function>

    <xsl:function name="ac:sparql-results-data-table">
        <xsl:param name="results" as="document-node()"/>
        <xsl:param name="category" as="xs:string?"/>
        <xsl:param name="series" as="xs:string*"/>
        
        <xsl:variable name="json" as="xs:string">
            <xsl:value-of>
                <xsl:apply-templates select="$results" mode="ac:DataTable">
                    <xsl:with-param name="var-names" select="$category, $series" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:value-of>
        </xsl:variable>

        <xsl:variable name="json-obj" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $json ])"/>
        <xsl:sequence select="ixsl:new('google.visualization.DataTable', [ $json-obj ])"/>
    </xsl:function>

    <!-- parses RDF/POST inputs into a sequence of SPARQL.js triple maps (they need to be wrapped into <array key="triples">) -->
    <!-- see https://atomgraph.github.io/RDF-POST/ for the specification -->
    <xsl:function name="ldh:parse-rdf-post" as="element()*">
        <xsl:param name="elements" as="element()*"/>

        <xsl:variable name="inputs" select="$elements[@name = ('rdf', 'sb', 'su', 'pu', 'ob', 'ou', 'ol', 'll', 'lt')]" as="element()*"/>
        <xsl:choose>
            <xsl:when test="$inputs[1]/@name = 'rdf'">
                <xsl:variable name="value-inputs" select="subsequence($inputs, 2)[ixsl:contains(., 'value')]" as="element()*"/> <!-- skip the initial <input name="rdf"/> -->
                <xsl:variable name="value-inputs" select="$value-inputs[@name = 'su' or not(ixsl:get(., 'value') = '')]" as="element()*"/> <!-- filter out empty literal values (empty 'su' values are valid: those are relative subject URIs) -->
                <xsl:variable name="value-inputs" select="$value-inputs[not(@type = 'checkbox') or ixsl:get(., 'checked')]" as="element()*"/> <!-- unchecked checkboxes are not successful controls, as in HTML form submission -->
                <xsl:iterate select="$value-inputs">
                    <xsl:param name="subj-input" select="if ($value-inputs[1]/@name = ('sb', 'su')) then $value-inputs[1] else ()" as="element()?"/>
                    <xsl:param name="pred-input" as="element()?"/>
                    <xsl:param name="skip-to-input" as="element()?"/>
                    <xsl:variable name="next-input" select="subsequence($value-inputs, position() + 1, 1)" as="element()?"/>
                    <xsl:variable name="subj-input" select="if (@name = ('sb', 'su')) then . else $subj-input" as="element()?"/>
                    <xsl:variable name="pred-input" select="if (@name = 'pu') then . else $pred-input" as="element()?"/>

                    <!-- output triple when object is reached and inputs are not being skipped -->
                    <xsl:if test="@name = ('ou', 'ob', 'ol') and (not($skip-to-input) or . is $skip-to-input)">
                        <json:map>
                            <!-- subject -->
                            <xsl:choose>
                                <!-- blank node -->
                                <xsl:when test="$subj-input/@name = 'sb'">
                                    <json:string key="subject">_:<xsl:value-of select="$subj-input/ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                                <!-- URI -->
                                <xsl:when test="$subj-input/@name = 'su'">
                                    <json:string key="subject"><xsl:value-of select="$subj-input/ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                            </xsl:choose>
                            <!-- predicate -->
                            <json:string key="predicate"><xsl:value-of select="$pred-input/ixsl:get(., 'value')"/></json:string>
                            <!-- object -->
                            <xsl:choose>
                                <!-- blank node -->
                                <xsl:when test="@name = 'ob'">
                                    <json:string key="object">_:<xsl:value-of select="ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                                <!-- URI -->
                                <xsl:when test="@name = 'ou'">
                                    <json:string key="object"><xsl:value-of select="ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                                <!-- typed literal -->
                                <xsl:when test="@name = 'ol' and $next-input/@name = 'lt'">
                                    <!-- if the literal is of type rdf:XMLLiteral, wrap its value to make it well-formed XHTML (previously done by the RDFPostCleanupInterceptor) -->
                                    <xsl:variable name="datatype" select="$next-input/ixsl:get(., 'value')" as="xs:anyURI"/>
                                    <xsl:variable name="value" select="if ($datatype = '&rdf;XMLLiteral') then '&lt;div xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;' || ixsl:get(., 'value') || '&lt;/div&gt;' else ixsl:get(., 'value')" as="xs:string"/>
                                    <!-- note: SPARQL.js 2.x does NOT wrap the datatype URI into <> -->
                                    <json:string key="object">&quot;<xsl:value-of select="$value"/>&quot;^^<xsl:value-of select="$datatype"/></json:string>
                                </xsl:when>
                                <!-- typed literal -->
                                <xsl:when test="@name = 'lt' and $next-input/@name = 'ol'">
                                    <!-- if the literal is of type rdf:XMLLiteral, wrap its value to make it well-formed XHTML (previously done by the RDFPostCleanupInterceptor) -->
                                    <xsl:variable name="datatype" select="ixsl:get(., 'value')" as="xs:anyURI"/>
                                    <xsl:variable name="value" select="if ($datatype = '&rdf;XMLLiteral') then '&lt;div xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;' || $next-input/ixsl:get(., 'value') || '&lt;/div&gt;' else $next-input/ixsl:get(., 'value')" as="xs:string"/>
                                    <!-- note: SPARQL.js 2.x does NOT wrap the datatype URI into <> -->
                                    <json:string key="object">&quot;<xsl:value-of select="$value"/>&quot;^^<xsl:value-of select="$datatype"/></json:string>
                                </xsl:when>
                                <!-- language-tagged literal -->
                                <xsl:when test="@name = 'ol' and $next-input/@name = 'll'">
                                    <json:string key="object">&quot;<xsl:value-of select="ixsl:get(., 'value')"/>&quot;@<xsl:value-of select="$next-input/ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                                <!-- language-tagged literal -->
                                <xsl:when test="@name = 'll' and $next-input/@name = 'ol'">
                                    <json:string key="object">&quot;<xsl:value-of select="$next-input/ixsl:get(., 'value')"/>&quot;@<xsl:value-of select="ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                                <!-- plain literal -->
                                <xsl:when test="@name = 'ol'">
                                    <json:string key="object">&quot;<xsl:value-of select="ixsl:get(., 'value')"/>&quot;</json:string>
                                </xsl:when>
                            </xsl:choose>
                        </json:map>
                    </xsl:if>

                    <xsl:next-iteration>
                        <xsl:with-param name="subj-input" select="$subj-input"/>
                        <xsl:with-param name="pred-input" select="$pred-input"/>
                        <xsl:with-param name="skip-to-input" as="element()?">
                          <xsl:choose>
                            <!-- pred is expected, but there is no pu= ahead -->
                            <xsl:when test="@name = ('su', 'sb') and not($next-input/@name = 'pu')">
                              <!-- skip to the next subj -->
                              <xsl:sequence select="(for $input in subsequence($value-inputs, position() + 1) return $input[@name = ('su', 'sb' )])[1]"/>
                            </xsl:when>
                            <!-- obj is expected, but there is no &ob=, &ou=, or &ol= ahead -->
                            <xsl:when test="@name = 'pu' and not($next-input/@name = ('ob', 'ou', 'ol'))">
                              <!-- skip to the next pred or subj, whichever comes first -->
                              <xsl:sequence select="(for $input in subsequence($value-inputs, position() + 1) return $input[@name = ('su', 'sb', 'pu')])[1]"/>
                            </xsl:when>
                            <!-- &lt= or &ll= is seen, but there is no &ol= ahead -->
                            <xsl:when test="(@name = 'ol' and not($next-input/@name = ('ll', 'lt'))) or (@name = ('ll', 'lt') and not($next-input/@name = 'ol'))">
                              <!-- skip to the next non-literal obj, pred or subj, whichever comes first -->
                              <xsl:sequence select="(for $input in subsequence($value-inputs, position() + 1) return $input[@name = ('su', 'sb', 'pu', 'ob', 'ou')])[1]"/>
                            </xsl:when>
                          </xsl:choose>
                        </xsl:with-param>
                    </xsl:next-iteration>
                </xsl:iterate>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Invalid RDF/POST content: must start with &lt;input name="rdf"/&gt;</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- parses RDF/XML resources into SPARQL.js triples -->
    <xsl:function name="ldh:descriptions-to-triples" as="element()*">
        <xsl:param name="descriptions" as="element()*"/> <!-- rdf:Description sequence -->
        
        <xsl:for-each select="$descriptions/*">
            <json:map>
                <!-- subject -->
                <xsl:choose>
                    <!-- blank node -->
                    <xsl:when test="../@rdf:nodeID">
                        <json:string key="subject">_:<xsl:value-of select="../@rdf:nodeID"/></json:string>
                    </xsl:when>
                    <!-- URI -->
                    <xsl:when test="../@rdf:about">
                        <json:string key="subject"><xsl:value-of select="../@rdf:about"/></json:string>
                    </xsl:when>
                </xsl:choose>

                <!-- predicate -->
                <json:string key="predicate"><xsl:value-of select="concat(namespace-uri(), local-name())"/></json:string>

                <!-- object -->
                <xsl:choose>
                    <!-- blank node -->
                    <xsl:when test="@rdf:nodeID">
                        <json:string key="object">_:<xsl:value-of select="@rdf:nodeID"/></json:string>
                    </xsl:when>
                    <!-- URI -->
                    <xsl:when test="@rdf:resource">
                        <json:string key="object"><xsl:value-of select="@rdf:resource"/></json:string>
                    </xsl:when>
                    <!-- typed literal -->
                    <xsl:when test="text() and @rdf:datatype">
                        <json:string key="object">&quot;<xsl:value-of select="text()"/>&quot;^^<xsl:value-of select="@rdf:datatype"/></json:string>
                    </xsl:when>
                    <!-- language-tagged literal -->
                    <xsl:when test="text() and @xml:lang">
                        <json:string key="object">&quot;<xsl:value-of select="text()"/>&quot;@<xsl:value-of select="@xml:lang"/></json:string>
                    </xsl:when>
                    <!-- plain literal -->
                    <xsl:when test="text()">
                        <json:string key="object">&quot;<xsl:value-of select="text()"/>&quot;</json:string>
                    </xsl:when>
                </xsl:choose>
            </json:map>
        </xsl:for-each>
    </xsl:function>
    
    <!-- builds an <$about> ?p ?o triple pattern for the given $about URI -->

    <xsl:function name="ldh:uri-po-pattern" as="element()*">
        <xsl:param name="about" as="xs:anyURI"/>

        <json:map>
            <json:string key="subject"><xsl:sequence select="$about"/></json:string>
            <json:string key="predicate">?p</json:string>
            <json:string key="object">?o</json:string>
        </json:map>
    </xsl:function>
    
    <!-- wraps triple pattern into BGP pattern -->
    
    <xsl:function name="ldh:triples-to-bgp" as="element()">
        <xsl:param name="triples" as="element()*"/>

        <json:map>
            <json:string key="type">bgp</json:string>
            <json:array key="triples">
                <xsl:sequence select="$triples"/>
            </json:array>
        </json:map>
    </xsl:function>
    
    <!-- builds SPARQL update by injecting SPARQL.js triples into the INSERT block -->

    <xsl:function name="ldh:insertdelete-update" as="xs:string">
        <xsl:param name="delete-pattern" as="element()*"/>
        <xsl:param name="insert-pattern" as="element()*"/>
        <xsl:param name="where-pattern" as="element()*"/>

        <xsl:variable name="update-xml" as="element()">
            <json:map>
                <json:string key="type">update</json:string>
                <json:array key="updates">
                    <json:map>
                        <json:string key="updateType">insertdelete</json:string>
                        <json:array key="delete">
                            <xsl:sequence select="$delete-pattern"/>
                        </json:array>
                        <json:array key="insert">
                            <xsl:sequence select="$insert-pattern"/>
                        </json:array>
                        <json:array key="where">
                            <xsl:sequence select="$where-pattern"/>
                        </json:array>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:variable>
        <xsl:variable name="update-json-string" select="xml-to-json($update-xml)" as="xs:string"/>
        <xsl:variable name="update-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $update-json-string ])"/>
        <xsl:sequence select="ixsl:call($sparql-generator, 'stringify', [ $update-json ])"/>
    </xsl:function>
    
    <!-- generic HTTP client promises (SaxonJS 3) -->

    <xsl:function name="ldh:handle-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="ldh:handle-response($context, 'response')"/>
    </xsl:function>

    <xsl:function name="ldh:handle-response" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response-key" as="xs:string"/>

        <xsl:variable name="response" select="$context($response-key)" as="map(*)"/>
        <xsl:variable name="default-retry-after" select="1" as="xs:integer"/>

        <xsl:choose>
            <xsl:when test="$response?status = 429">
                <xsl:variable name="retry-after" select="
                  if (map:contains($response?headers, 'Retry-After'))
                  then xs:integer($response?headers('Retry-After'))
                  else $default-retry-after"/>

                <xsl:sequence select="
                  ixsl:sleep($retry-after * 1000)
                      => ixsl:then(ldh:retry-request($context, ?, $response-key))
                "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:retry-request" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="sleep-result" as="item()?"/>

        <xsl:sequence select="ldh:retry-request($context, $sleep-result, 'response')"/>
    </xsl:function>

    <xsl:function name="ldh:retry-request" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="sleep-result" as="item()?"/>
        <xsl:param name="response-key" as="xs:string"/>

        <xsl:variable name="request" select="$context('request')"/>

        <xsl:sequence select="
          ixsl:http-request($request)
            => ixsl:then(ldh:rethread-response($context, ?, $response-key))
            => ixsl:then(ldh:handle-response(?, $response-key))
        "/>
    </xsl:function>

    <xsl:function name="ldh:rethread-response" as="map(*)" ixsl:updating="no">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response" as="map(*)"/>

        <xsl:sequence select="ldh:rethread-response($context, $response, 'response')"/>
    </xsl:function>

    <xsl:function name="ldh:rethread-response" as="map(*)" ixsl:updating="no">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response" as="map(*)"/>
        <xsl:param name="response-key" as="xs:string"/>

        <xsl:sequence select="map:merge(($context, map{ $response-key: $response }), map{ 'duplicates': 'use-last' })"/>
    </xsl:function>

    <xsl:function name="ldh:http-request-threaded" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="ldh:http-request-threaded($context, 'request', 'response')"/>
    </xsl:function>

    <xsl:function name="ldh:http-request-threaded" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="request-key" as="xs:string"/>
        <xsl:param name="response-key" as="xs:string"/>

        <xsl:sequence select="
          ixsl:http-request($context($request-key))
            => ixsl:then(ldh:rethread-response($context, ?, $response-key))
        "/>
    </xsl:function>

    <!-- Async load/set pair for constructor instantiation — builds the constructor SELECT request from
    context('forClass'); the set fn instantiates the fetched constructor texts onto a single instance and
    stores the result at context('constructed-doc'). forClass is relaxed to xs:anyURI* so EDIT chains
    (which derive forClass from the resource's rdf:types and may legitimately have zero) can include this
    step unconditionally — an empty forClass sends an empty VALUES block, the SELECT returns no rows and
    the instantiated document is empty, which downstream merge/instantiate handle as a no-op. -->
    <xsl:function name="ldh:load-constructed-doc" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="forClass" select="$context('forClass')" as="xs:anyURI*"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('ns', ldt:base()), map{ 'query': ldh:constructor-query($forClass), 'accept': 'application/sparql-results+xml' })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }" as="map(*)"/>
        <xsl:sequence select="map:merge(($context, map{ 'constructed-doc-request': $request }))"/>
    </xsl:function>

    <xsl:function name="ldh:set-constructed-doc" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('constructed-doc-response')" as="map(*)"/>
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                    <xsl:variable name="texts" select="distinct-values(?body//srx:binding[@name = 'text']/srx:literal)" as="xs:string*"/>
                    <xsl:sequence select="map:merge(($context, map{ 'constructed-doc': ldh:construct-instance($texts, $context('forClass')) }))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <!-- Parallel load/set pair runner. $pairs is a single array whose members are 4-element arrays [load-fn, request-key, response-key, set-fn]; load-fn is a pure context-transformer that populates context($request-key). The helper folds every load-fn over $context (collecting all request specs), fans out one http-request → rethread → handle → set per pair via ixsl:all, then merges all per-branch contexts back into one. ixsl:all is fail-fast — first rejected branch propagates through on-failure of the enclosing chain. -->
    <xsl:function name="ldh:fire-load-set-parallel" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="pairs" as="array(*)"/>

        <xsl:variable name="ctx-with-requests" as="map(*)" select="
          array:fold-left($pairs, $context, function($ctx as item()*, $pair as item()*) as item()* { $pair?1($ctx) })
        "/>

        <xsl:variable name="promises" as="array(*)" select="
          array {
            for $pair in $pairs?* return
              ixsl:http-request($ctx-with-requests($pair?2))
                => ixsl:then(ldh:rethread-response($ctx-with-requests, ?, $pair?3))
                => ixsl:then(ldh:handle-response(?, $pair?3))
                => ixsl:then($pair?4)
          }
        "/>

        <xsl:sequence select="
          ixsl:all($promises)
            => ixsl:then(function($results as item()*) as item()* {
                 array:fold-left($results, $ctx-with-requests, function($acc as item()*, $r as item()*) as item()* {
                   map:merge(($acc, $r), map{ 'duplicates': 'use-last' })
                 })
               })
        "/>
    </xsl:function>

    <!-- Raises the busy cursor when an interaction starts async work. Its counterpart is not a matching call at
         every terminal branch but ixsl:finally(ldh:reset-cursor#0) on the chain the work runs in, which settles
         once whatever the outcome: the branch-by-branch resets this replaced were missing from error branches
         (a response that resolved with a 4xx/5xx left the cursor spinning) and duplicated across the success
         ones. Pair every ldh:busy-cursor() with a finally on the promise it precedes. -->
    <xsl:function name="ldh:busy-cursor" as="empty-sequence()" ixsl:updating="yes">
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
    </xsl:function>

    <!-- Promise-chain cleanup callback for ixsl:finally — resets the body cursor. ixsl:finally requires a 0-arg handler and ignores its return value (the original promise outcome flows through to on-failure / on-completion). -->
    <xsl:function name="ldh:reset-cursor" ixsl:updating="yes">
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:function>

    <!-- Composes the seed shape shared by chains whose initial GET is against the edited resource: http-request → rethread → handle → load-edited-resource. After this resolves, context has types/property-uris/object-uris populated and a GET-style type-metadata-request pre-baked, so downstream parallel pairs should use an identity load-fn for type-metadata (otherwise ldh:load-type-metadata would overwrite the request with its POST variant). -->
    <xsl:function name="ldh:fetch-and-load-edited-resource" as="item()*" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>

        <xsl:sequence select="
          ixsl:http-request($context('request'))
            => ixsl:then(ldh:rethread-response($context, ?))
            => ixsl:then(ldh:handle-response#1)
            => ixsl:then(ldh:load-edited-resource#1)
        "/>
    </xsl:function>

    <xsl:function name="ldh:promise-failure" ixsl:updating="yes">
        <xsl:param name="error" as="map(*)"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:if test="$error?code ne 'Q{&ldh;}HTTPError'">
            <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ $error?message ])"/>
        </xsl:if>
    </xsl:function>

    <xsl:function name="ldh:error-response-alert" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)?"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ $response?message ])"/>
    </xsl:function>

    <!-- ERROR UI: one alert builder, one detail builder, and a render function per host (block body, modal form) -->

    <!-- The nodeID of the sentence that explains an HTTP status in the reader's own terms, rather than
         restating the upstream text. The upstream text is still shown, demoted, in the technical detail. -->
    <xsl:function name="ldh:http-error-key" as="xs:string">
        <xsl:param name="status" as="xs:double?"/> <!-- xs:double, not xs:integer: SaxonJS surfaces the response status as a JS number, and integers promote into this but doubles do not promote the other way -->


        <xsl:sequence select="if ($status = 400) then 'http-error-malformed' else if ($status = 401) then 'http-error-unauthorized' else if ($status = 403) then 'http-error-forbidden' else if ($status = 404) then 'http-error-not-found' else if ($status = (502, 503, 504)) then 'http-error-unreachable' else if ($status ge 500) then 'http-error-server' else 'http-error-unknown'"/>
    </xsl:function>

    <!-- The negative alert every failure surface is built from (design system: Core → Status, InlineAlert).
         The headline names what failed, the sentence under it explains why - neither restates the upstream
         text, which belongs in the technical detail. -->
    <xsl:function name="ldh:error-alert" as="element()">
        <xsl:param name="title-key" as="xs:string"/> <!-- translations.rdf nodeID of the headline -->
        <xsl:param name="explanation-key" as="xs:string"/> <!-- nodeID of the sentence under it; ldh:http-error-key() derives one from a status -->
        <xsl:param name="uri" as="xs:anyURI?"/> <!-- what could not be reached, linked under the sentence -->

        <xsl:variable name="translations" select="document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin))" as="document-node()"/>

        <div class="ldhc-alert va-negative" role="alert">
            <span class="ldhc-alert-ic">
                <span class="msi outline" aria-hidden="true">error</span>
            </span>
            <div class="ldhc-alert-body">
                <span class="ldhc-alert-title">
                    <xsl:apply-templates select="key('resources', $title-key, $translations)" mode="ac:label"/>
                </span>
                <span class="ldhc-alert-text">
                    <xsl:apply-templates select="key('resources', $explanation-key, $translations)" mode="ac:label"/>
                </span>
                <!-- the URI takes the alert body's link slot, its own row, so the sentence above it stays a
                     sentence and a long IRI wraps without breaking the prose -->
                <xsl:if test="$uri">
                    <a class="ldh-code" href="{$uri}">
                        <xsl:value-of select="$uri"/>
                    </a>
                </xsl:if>
            </div>
        </div>
    </xsl:function>

    <!-- The upstream text, demoted into a collapsed disclosure: never the first thing read, never withheld from
         whoever needs it. Empty when there is nothing to show, so callers can hand it whatever they have. -->
    <xsl:function name="ldh:error-detail" as="element()?">
        <xsl:param name="detail" as="xs:string?"/>

        <xsl:if test="normalize-space($detail)">
            <details class="ldh-block-detail">
                <summary>
                    <span class="msi" aria-hidden="true">chevron_right</span>
                    <xsl:apply-templates select="key('resources', 'technical-detail', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                </summary>
                <pre>
                    <xsl:value-of select="$detail"/>
                </pre>
            </details>
        </xsl:if>
    </xsl:function>

    <!-- The status line and message a failed response contributes to the technical detail. -->
    <xsl:function name="ldh:response-detail" as="xs:string">
        <xsl:param name="response" as="map(*)?"/>

        <xsl:sequence select="string-join(($response?status ! ('HTTP ' || .), $response?message), '&#xA;')"/>
    </xsl:function>

    <!-- The body a block shows when its content could not be loaded (design system: Components → Block states).
         The card and header around this stay as they are - app.css derives the failure ring from the presence
         of .ldh-block-error. Small hosts that are not a block body (facet popover, result count, parallax rows)
         call ldh:error-alert directly, so they cannot ring the card they happen to sit in. -->
    <xsl:function name="ldh:block-error" as="element()">
        <xsl:param name="title-key" as="xs:string"/>
        <xsl:param name="explanation-key" as="xs:string"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="response" as="map(*)?"/> <!-- the failed response; its status and message make the technical detail -->

        <div class="ldh-block-error">
            <xsl:sequence select="ldh:error-alert($title-key, $explanation-key, $uri)"/>
            <xsl:sequence select="ldh:error-detail(ldh:response-detail($response))"/>
        </div>
    </xsl:function>

    <!-- Replaces a block's content with the failure body. Every block-body error path goes through here: the
         for-each over the container and the replace-content result-document were written out at each of them,
         and $container is a sequence because some callers narrow it (e.g. to the block's div.main) and may
         narrow it to nothing. -->
    <xsl:function name="ldh:render-block-error" as="empty-sequence()" ixsl:updating="yes">
        <xsl:param name="container" as="element()*"/>
        <xsl:param name="title-key" as="xs:string"/>
        <xsl:param name="explanation-key" as="xs:string"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="response" as="map(*)?"/>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:sequence select="ldh:block-error($title-key, $explanation-key, $uri, $response)"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:function>

    <!-- Appends the same alert to a modal form's fieldset, which is where form-level failures report. No
         .ldh-block-error wrapper: a form is not a block body, and the wrapper is what app.css rings a card on. -->
    <xsl:function name="ldh:render-form-error" as="empty-sequence()" ixsl:updating="yes">
        <xsl:param name="form" as="element()?"/>
        <xsl:param name="title-key" as="xs:string"/>
        <xsl:param name="explanation-key" as="xs:string"/>
        <xsl:param name="detail" as="xs:string?"/>

        <xsl:for-each select="$form//fieldset">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:sequence select="ldh:error-alert($title-key, $explanation-key, ())"/>
                <xsl:sequence select="ldh:error-detail($detail)"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:function>

    <!-- target URIs of the Link header entries whose parameters contain $marker (e.g. a rel URI or 'rel=timemap') -->
    <xsl:function name="ldh:link-targets" as="xs:anyURI*">
        <xsl:param name="link-header" as="xs:string?"/>
        <xsl:param name="marker" as="xs:string"/>

        <xsl:sequence select="tokenize($link-header, ',')[contains(., $marker)] ! xs:anyURI(substring-before(substring-after(substring-before(., ';'), '&lt;'), '&gt;'))"/>
    </xsl:function>

</xsl:stylesheet>
