<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
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

    <xsl:function name="ldh:base-uri" as="xs:anyURI">
        <xsl:param name="arg" as="node()"/> <!-- ignored -->

        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'location.href'))"/>
    </xsl:function>
    
    <xsl:function name="ldt:base" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.base'))"/>
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
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))"/>
    </xsl:function>

    <!-- finds the app with the longest matching base URI -->
    <xsl:function name="ldh:match-app" as="element()?">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="apps" as="document-node()"/>
        
        <xsl:sequence select="let $max-length := max($apps//rdf:Description[ldt:base/@rdf:resource[starts-with($uri, .)]]/string-length(ldt:base/@rdf:resource)) return ($apps//rdf:Description[ldt:base/@rdf:resource[starts-with($uri, .)]][string-length(ldt:base/@rdf:resource) eq $max-length])[1]"/>
    </xsl:function>
    
    <xsl:function name="ldh:query-type" as="xs:string?">
        <xsl:param name="query-string" as="xs:string"/>
        
        <xsl:sequence select="analyze-string($query-string, '[^a-zA-Z]?(SELECT|ASK|DESCRIBE|CONSTRUCT)[^a-zA-Z]', 'i')/fn:match[1]/fn:group[@nr = '1']/string() => upper-case()"/>
    </xsl:function>

    <xsl:function name="ldh:new-object">
        <xsl:variable name="js-statement" as="element()">
            <root statement="{{ }}"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:function name="ldh:new" as="item()">
        <xsl:param name="target" as="xs:string"/>
        <xsl:param name="arguments" as="array(*)"/>

        <xsl:sequence select="ixsl:call(ixsl:window(), 'Reflect.construct', [ ixsl:get(ixsl:window(), $target), $arguments ] )"/>
    </xsl:function>

    <!-- format URLs in DataTable as HTML links. !!! Saxon-JS cannot intercept Google Charts events, therefore set a full proxied URL !!! -->
    <xsl:template match="@rdf:about[starts-with(., 'http://')] | @rdf:about[starts-with(., 'https://')] | @rdf:resource[starts-with(., 'http://')] | @rdf:resource[starts-with(., 'https://')] | srx:uri[starts-with(., 'http://')] | srx:uri[starts-with(., 'https://')]" mode="ac:DataTable">
        <json:string key="v">&lt;a href="<xsl:value-of select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, xs:anyURI(.))"/>"&gt;<xsl:value-of select="."/>&lt;/a&gt;</json:string>
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
        
        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.visualization.DataTable(JSON.parse(String.raw`{$json}`))"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
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

        <xsl:variable name="js-statement" as="element()">
            <root statement="new google.visualization.DataTable(JSON.parse(String.raw`{$json}`))"/>
        </xsl:variable>
        <xsl:sequence select="ixsl:eval(string($js-statement/@statement))"/>
    </xsl:function>
    
    <xsl:function name="ldh:parse-html" as="document-node()">
        <xsl:param name="string" as="xs:string"/>
        <xsl:param name="mime-type" as="xs:string"/>
        
        <xsl:sequence select="ixsl:call(ldh:new('DOMParser', []), 'parseFromString', [ $string, $mime-type ])"/>
    </xsl:function>

    <!-- parses RDF/POST inputs into a sequence of SPARQL.js triple maps (they need to be wrapped into <array key="triples">) -->
    <!-- see https://atomgraph.github.io/RDF-POST/ for the specification -->
    <xsl:function name="ldh:parse-rdf-post" as="element()*">
        <xsl:param name="elements" as="element()*"/>

        <xsl:variable name="inputs" select="$elements[@name = ('rdf', 'sb', 'su', 'pu', 'ob', 'ou', 'ol', 'll', 'lt')]" as="element()*"/>
        <xsl:choose>
            <xsl:when test="$inputs[1]/@name = 'rdf'">
                <xsl:variable name="value-inputs" select="subsequence($inputs, 2)[ixsl:contains(., 'value')]" as="element()*"/> <!-- skip the initial <input name="rdf"/> -->
                <xsl:variable name="value-inputs" select="$value-inputs[not(ixsl:get(., 'value') = '')]" as="element()*"/> <!-- filter out empty values -->
                <xsl:iterate select="$value-inputs">
                    <xsl:param name="subj-input" select="if ($value-inputs[1]/@name = ('sb', 'su')) then $value-inputs[1] else ()" as="element()?"/>
                    <xsl:param name="pred-input" as="element()?"/>
                    <xsl:param name="skip-to-input" as="element()?"/>
                    <xsl:variable name="next-input" select="subsequence($value-inputs, position() + 1, 1)" as="element()?"/>
                    <xsl:variable name="subj-input" select="if (@name = ('sb', 'su')) then . else $subj-input" as="element()?"/>
                    <xsl:variable name="pred-input" select="if (@name = 'pu') then . else $pred-input" as="element()?"/>
<xsl:message>ITERATE: @name: <xsl:value-of select="@name"/> ixsl:get(., 'value'): <xsl:value-of select="ixsl:get(., 'value')"/> $skip-to-input/@name: <xsl:value-of select="$skip-to-input/@name"/> $skip-to-input/ixsl:get(., 'value'): <xsl:value-of select="$skip-to-input/ixsl:get(., 'value')"/></xsl:message>
                    <!-- output triple when object is reached and inputs are not being skipped -->
                    <xsl:if test="@name = ('ou', 'ob', 'ol', 'll', 'lt') and (not($skip-to-input) or . is $skip-to-input)">
<xsl:message>OUTPUT @name: <xsl:value-of select="@name"/> ixsl:get(., 'value'): <xsl:value-of select="ixsl:get(., 'value')"/> $skip-to-input/@name: <xsl:value-of select="$skip-to-input/@name"/> $skip-to-input/ixsl:get(., 'value'): <xsl:value-of select="$skip-to-input/ixsl:get(., 'value')"/></xsl:message>

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
                                    <json:string key="object">&quot;<xsl:value-of select="ixsl:get(., 'value')"/>&quot;^^<xsl:value-of select="$next-input/ixsl:get(., 'value')"/></json:string>
                                </xsl:when>
                                <!-- typed literal -->
                                <xsl:when test="@name = 'lt' and $next-input/@name = 'ol'">
                                    <json:string key="object">&quot;<xsl:value-of select="$next-input/ixsl:get(., 'value')"/>&quot;^^<xsl:value-of select="ixsl:get(., 'value')"/></json:string>
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
    
    <!-- parses SPARQL.js triple maps into RDF/XML. Depends on the SPARQL.js serialization used in the ldh:parse-rdf-post function -->
    <xsl:function name="ldh:triples-to-descriptions" as="element()*">
        <xsl:param name="triples" as="element()*"/>
        
        <xsl:for-each-group select="$triples" group-by="json:string[@key = 'subject']">
            <rdf:Description>
                <!-- subject -->
                <xsl:choose>
                    <xsl:when test="starts-with('_:', current-grouping-key())">
                        <xsl:attribute name="rdf:nodeID" select="substring-after(current-grouping-key(), '_:')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="rdf:about" select="current-grouping-key()"/>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:for-each select="current-group()">
                    <!-- split predicate URI into namespace and local name -->
                    <xsl:variable name="namespace" select="xs:anyURI(if (contains(json:string[@key = 'predicate'], '#')) then substring-before(json:string[@key = 'predicate'], '#') || '#' else string-join(tokenize(json:string[@key = 'predicate'], '/')[not(position() = last())], '/') || '/')" as="xs:anyURI"/>
                    <xsl:variable name="local-name" select="substring-after(json:string[@key = 'predicate'], $namespace)" as="xs:string"/>
                    
                    <!-- predicate -->
                    <xsl:element namespace="{$namespace}" name="ns:{$local-name}">
                        <xsl:for-each select="json:string[@key = 'object']">
                            <!-- object -->
                            <xsl:choose>
                                <!-- language-tagged literal -->
                                <xsl:when test="starts-with(., '&quot;') and contains(., '&quot;^^')">
                                    <xsl:attribute name="xml:lang" select="substring-after(., '&quot;^^')"/>
                                    <xsl:sequence select="substring-before(substring-after(., '&quot;'), '&quot;^^')"/>
                                </xsl:when>
                                <!-- typed literal -->
                                <xsl:when test="starts-with(., '&quot;') and contains(., '&quot;@')">
                                    <xsl:attribute name="xml:lang" select="substring-after(., '&quot;@')"/>
                                    <xsl:sequence select="substring-before(substring-after(., '&quot;'), '&quot;@')"/>
                                </xsl:when>
                                <!-- TO-DO: XMLLiteral! -->
                                <!-- plain literal -->
                                <xsl:when test="starts-with(., '&quot;') and ends-with(., '&quot;')">
                                    <xsl:sequence select="substring-before(substring-after(., '&quot;'), '&quot;')"/>
                                </xsl:when>
                                <!-- blank node -->
                                <xsl:when test="starts-with(., '_:')">
                                    <xsl:attribute name="rdf:nodeID" select="substring-after(., '_:')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="rdf:resource" select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:for-each>
            </rdf:Description>
        </xsl:for-each-group>
    </xsl:function>
    
</xsl:stylesheet>