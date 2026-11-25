<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY ldh        "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs       "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY dc         "http://purl.org/dc/elements/1.1/">
    <!ENTITY dct        "http://purl.org/dc/terms/">
    <!ENTITY foaf       "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc       "http://rdfs.org/sioc/ns#">
    <!ENTITY skos       "http://www.w3.org/2004/02/skos/core#">
    <!ENTITY xsd        "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>

    <!-- the properties a facet value's label is looked up from, in preference order -->
    <xsl:param name="ldh:label-properties" as="xs:anyURI*" select="for $uri in ('&rdfs;label', '&dc;title', '&dct;title', '&foaf;name', '&foaf;givenName', '&foaf;familyName', '&sioc;name', '&skos;prefLabel') return xs:anyURI($uri)"/>

    <!-- replace projected variable(s) -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:replace-variables">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map/json:array[@key = 'variables']" mode="ldh:replace-variables" priority="1">
        <xsl:param name="var-names" as="xs:string*" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
        
            <xsl:for-each select="$var-names">
                <xsl:sequence select="ldh:term-node('?' || replace(., '^[?$]', ''))"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <!-- replace LIMIT -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:replace-limit">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:map[@key = 'solutionModifiers']" mode="ldh:replace-limit" priority="1">
        <xsl:param name="limit" as="xs:integer?" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()[not(self::json:map[@key = 'limitOffset'])]" mode="#current"/>
            <json:map key="limitOffset">
                <xsl:apply-templates select="json:map[@key = 'limitOffset']/node()[not(self::json:number[@key = 'limit'])]" mode="#current"/>
                <xsl:if test="$limit">
                    <json:number key="limit"><xsl:value-of select="$limit"/></json:number>
                </xsl:if>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <!-- replace OFFSET -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:replace-offset">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:map[@key = 'solutionModifiers']" mode="ldh:replace-offset" priority="1">
        <xsl:param name="offset" as="xs:integer?" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()[not(self::json:map[@key = 'limitOffset'])]" mode="#current"/>
            <json:map key="limitOffset">
                <xsl:apply-templates select="json:map[@key = 'limitOffset']/node()[not(self::json:number[@key = 'offset'])]" mode="#current"/>
                <xsl:if test="$offset">
                    <json:number key="offset"><xsl:value-of select="$offset"/></json:number>
                </xsl:if>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- The name of a SELECT's first projected variable, without a sigil: a Traqula variable term, or
         the variable term on a bind projection. A view
         lists the resources this variable binds, so an aliased one - (?s AS ?resource), or (IRI(...) AS ?r) - is as
         good as a plain one; reading only the plain form left the name empty and the view's whole render failing.
         SELECT * has no first variable, and gives the empty string, as it always did -->
    <xsl:function name="ldh:first-var-name" as="xs:string">
        <xsl:param name="query" as="element(json:map)"/>
        <xsl:variable name="first" select="$query/json:array[@key = 'variables']/*[1]" as="element()?"/>

        <xsl:sequence select="string(($first/json:string[@key = 'value'], $first/json:map[@key = 'variable']/json:string[@key = 'value'])[1])"/>
    </xsl:function>

    <!-- Construct parser-independent RDF terms in the Traqula AST shape from a SPARQL token used by
         the query rewrites. Parsed terms are already typed objects and are copied unchanged. -->
    <xsl:function name="ldh:term-node" as="element(json:map)">
        <xsl:param name="token" as="xs:string"/>
        <xsl:variable name="quote" select="codepoints-to-string(34)" as="xs:string"/>
        <xsl:variable name="language" select="if (starts-with($token, $quote) and matches($token, $quote || '@[-A-Za-z0-9]+$')) then replace($token, '^.*' || $quote || '@', '') else ''" as="xs:string"/>
        <xsl:variable name="datatype" select="if (starts-with($token, $quote) and contains($token, $quote || '^^')) then replace(substring-after($token, $quote || '^^'), '^&lt;(.*)&gt;$', '$1') else ''" as="xs:string"/>
        <xsl:variable name="suffix" select="if ($language) then '@' || $language else if ($datatype) then '^^' || (if (contains($token, $quote || '^^&lt;')) then '&lt;' || $datatype || '&gt;' else $datatype) else ''" as="xs:string"/>
        <xsl:variable name="lexical" select="if (starts-with($token, $quote)) then substring($token, 2, string-length($token) - 2 - string-length($suffix)) else ''" as="xs:string"/>
        <xsl:variable name="node" as="map(*)" select="
            if (matches($token, '^[?$]')) then map { 'type': 'term', 'subType': 'variable', 'value': substring($token, 2), 'loc': map { 'sourceLocationType': 'autoGenerate' } }
            else if (starts-with($token, '_:')) then map { 'type': 'term', 'subType': 'blankNode', 'value': substring-after($token, '_:'), 'loc': map { 'sourceLocationType': 'autoGenerate' } }
            else if (starts-with($token, $quote)) then map:merge((
                map { 'type': 'term', 'subType': 'literal', 'value': $lexical, 'loc': map { 'sourceLocationType': 'autoGenerate' } },
                if ($language) then map { 'langOrIri': $language }
                else if ($datatype) then map { 'langOrIri': map { 'type': 'term', 'subType': 'namedNode', 'value': $datatype, 'loc': map { 'sourceLocationType': 'autoGenerate' } } }
                else map {}
            ))
            else map { 'type': 'term', 'subType': 'namedNode', 'value': if (starts-with($token, '&lt;') and ends-with($token, '&gt;')) then substring($token, 2, string-length($token) - 2) else $token, 'loc': map { 'sourceLocationType': 'autoGenerate' } }"/>
        <xsl:sequence select="json-to-xml(serialize($node, map { 'method': 'json' }))/json:map"/>
    </xsl:function>


    <xsl:template name="ldh:term-entry">
        <xsl:param name="token" as="xs:string"/>
        <xsl:param name="key" as="xs:string"/>
        <json:map key="{$key}">
            <xsl:copy-of select="ldh:term-node($token)/node()"/>
        </json:map>
    </xsl:template>

    <!-- A suffix that turns each of $stems into a variable name the query does not use: the first of _ldh, _ldh1,
         _ldh2, ... with which no stem collides. A rewrite's own variables have to avoid the query's (a subquery
         exports its projected variables, so a clash would silently join), and they have to come out the same
         every time the same query is rewritten: a random name makes every visitor's query text different, so no
         cache in front of the endpoint can answer one visitor's query with another's result. -->
    <xsl:function name="ldh:fresh-var-suffix" as="xs:string">
        <xsl:param name="query" as="element(json:map)"/>
        <xsl:param name="stems" as="xs:string+"/>

        <xsl:sequence select="ldh:fresh-var-suffix(distinct-values($query//json:map[json:string[@key = 'type'] = 'term'][json:string[@key = 'subType'] = 'variable']/json:string[@key = 'value']), $stems, 0)"/>
    </xsl:function>

    <xsl:function name="ldh:fresh-var-suffix" as="xs:string">
        <xsl:param name="used" as="xs:string*"/>
        <xsl:param name="stems" as="xs:string+"/>
        <xsl:param name="n" as="xs:integer"/>
        <xsl:variable name="suffix" select="'_ldh' || (if ($n = 0) then '' else string($n))" as="xs:string"/>

        <xsl:sequence select="if (some $stem in $stems satisfies ($stem || $suffix) = $used) then ldh:fresh-var-suffix($used, $stems, $n + 1) else $suffix"/>
    </xsl:function>

    <!-- wrap SELECT into DESCRIBE -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:wrap-describe">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map" mode="ldh:wrap-describe" priority="1">
        <json:map>
            <json:string key="type">query</json:string>
            <json:string key="subType">describe</json:string>
            <json:array key="variables">
                <json:map><json:string key="type">wildcard</json:string></json:map>
            </json:array>
            <xsl:copy-of select="json:map[@key = 'datasets']"/>
            <json:map key="where">
                <json:string key="type">pattern</json:string>
                <json:string key="subType">group</json:string>
                <json:array key="patterns">
                    <xsl:apply-templates select="." mode="ldh:strip-from"/>
                </json:array>
            </json:map>
            <json:map key="solutionModifiers"/>
        </json:map>
    </xsl:template>

    <!-- strip the (now hoisted) top-level dataset clause off the nested subquery -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:strip-from">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/json:map/json:map[@key = 'datasets']" mode="ldh:strip-from" priority="1"/>

    <!-- strip ORDER BY -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:strip-order-by">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- removes every sort key: ldh:replace-order-by with no $var-name only drops the first one -->
    <xsl:template match="/json:map/json:map[@key = 'solutionModifiers']/json:map[@key = 'order']" mode="ldh:strip-order-by" priority="1"/>

    <!-- link predicates -->

    <!-- a triple pattern matched both in the default graph and in any named graph -->
    <xsl:template name="ldh:GraphUnionPattern">
        <xsl:param name="subject" as="xs:string"/>
        <xsl:param name="predicate" as="xs:string"/>
        <xsl:param name="object" as="xs:string"/>
        <xsl:param name="graph-var" as="xs:string"/>

        <json:map>
            <json:string key="type">pattern</json:string>
            <json:string key="subType">union</json:string>
            <json:array key="patterns">
                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">bgp</json:string>
                    <json:array key="triples">
                        <json:map>
                            <json:string key="type">triple</json:string>
                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$subject"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$predicate"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$object"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                        </json:map>
                    </json:array>
                </json:map>
                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">graph</json:string>
                    <json:array key="patterns">
                        <json:map>
                            <json:string key="type">pattern</json:string>
                            <json:string key="subType">bgp</json:string>
                            <json:array key="triples">
                                <json:map>
                                    <json:string key="type">triple</json:string>
                                    <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$subject"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                    <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$predicate"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                    <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$object"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                                </json:map>
                            </json:array>
                        </json:map>
                    </json:array>
                    <json:map key="name">
                        <json:string key="type">term</json:string>
                        <json:string key="subType">variable</json:string>
                        <json:string key="value"><xsl:value-of select="substring-after($graph-var, '?')"/></json:string>
                        <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                    </json:map>
                </json:map>
            </json:array>
        </json:map>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:link-predicates">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Turns the view's SELECT into a query for the predicates that link its results to the rest
         of the graph: ?predicate paired with ?inverse, which flags the incoming ones. The SELECT
         becomes a subquery, so discovery covers the whole result set rather than the loaded page;
         the caller strips LIMIT/OFFSET/ORDER off it first.

             SELECT ?predicate ?inverse {
               { SELECT ?predicate (false AS ?inverse) { { <view> } <outgoing> } GROUP BY ?predicate }
               UNION
               { SELECT ?predicate (true AS ?inverse) { { <view> } <incoming> } GROUP BY ?predicate }
             } LIMIT 100

         Each direction joins the view on its own and collapses to its predicates with GROUP BY before
         the UNION. Joining the view once with an outgoing/incoming UNION and deduplicating with a
         top-level DISTINCT returns the same rows, but materialises every joined triple first: on a
         view whose results have millions of incoming triples (Seimas members and their ~4.9M roll-call
         votes) that took 27.7 s, this takes 8.5 s.

         Outgoing objects that are literals, or that are never subjects themselves, are filtered
         out: a pivot onto them would render an empty view. Incoming subjects need no such check -
         each is by construction the subject of the triple that matched.

         Variable names carry a suffix the view's query does not use (ldh:fresh-var-suffix), because a
         subquery exports its projected variables: a view projecting ?predicate would otherwise silently
         join with ours. The wrapper
         deliberately carries no prefixes - with any, the generator abbreviates IRIs and then emits
         the subquery's own prologue inside the group, which is a syntax error. -->
    <xsl:template match="/json:map" mode="ldh:link-predicates" priority="1">
        <xsl:param name="suffix" select="ldh:fresh-var-suffix(., ('predicate', 'inverse', 'object', 'subject'))" as="xs:string" tunnel="yes"/>
        <xsl:param name="limit" select="100" as="xs:integer" tunnel="yes"/>
        <xsl:variable name="select" select="." as="element(json:map)"/>

        <json:map>
            <json:string key="type">query</json:string>
            <json:string key="subType">select</json:string>
            <json:array key="variables">
                <xsl:sequence select="ldh:term-node('?' || 'predicate' || $suffix)"/>
                <xsl:sequence select="ldh:term-node('?' || 'inverse' || $suffix)"/>
            </json:array>
            <xsl:copy-of select="json:map[@key = 'datasets']"/>
            <json:map key="where">
                <json:string key="type">pattern</json:string>
                <json:string key="subType">group</json:string>
                <json:array key="patterns">
                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">union</json:string>
                    <json:array key="patterns">
                        <xsl:for-each select="(false(), true())">
                            <json:map>
                                <json:string key="type">pattern</json:string>
                                <json:string key="subType">group</json:string>
                                <json:array key="patterns">
                                    <xsl:call-template name="ldh:LinkPredicatesSubquery">
                                        <xsl:with-param name="select" select="$select"/>
                                        <xsl:with-param name="suffix" select="$suffix"/>
                                        <xsl:with-param name="inverse" select="."/>
                                    </xsl:call-template>
                                </json:array>
                            </json:map>
                        </xsl:for-each>
                    </json:array>
                </json:map>
                </json:array>
            </json:map>
            <json:map key="solutionModifiers">
                <json:map key="limitOffset">
                    <json:string key="type">solutionModifier</json:string>
                    <json:string key="subType">limitOffset</json:string>
                    <json:number key="limit"><xsl:value-of select="$limit"/></json:number>
                    <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                </json:map>
            </json:map>
        </json:map>
    </xsl:template>

    <!-- one direction of the link-predicate discovery: the view's results joined with their outgoing (or incoming) triples, grouped by predicate -->
    <xsl:template name="ldh:LinkPredicatesSubquery">
        <xsl:param name="select" as="element(json:map)"/>
        <xsl:param name="suffix" as="xs:string"/>
        <xsl:param name="inverse" as="xs:boolean"/>
        <xsl:variable name="focus-var" select="'?' || ldh:first-var-name($select)" as="xs:string"/>
        <xsl:variable name="predicate-var" select="'?predicate' || $suffix" as="xs:string"/>
        <xsl:variable name="object-var" select="'?object' || $suffix" as="xs:string"/>

        <json:map>
            <json:string key="type">query</json:string>
            <json:string key="subType">select</json:string>
            <json:array key="variables">
                <xsl:sequence select="ldh:term-node($predicate-var)"/>
                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">bind</json:string>
                    <json:map key="expression">
                        <json:string key="type">term</json:string>
                        <json:string key="subType">literal</json:string>
                        <json:string key="value"><xsl:value-of select="string($inverse)"/></json:string>
                        <json:map key="langOrIri">
                            <json:string key="type">term</json:string>
                            <json:string key="subType">namedNode</json:string>
                            <json:string key="value">&xsd;boolean</json:string>
                            <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                        </json:map>
                        <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                    </json:map>
                    <json:map key="variable">
                        <json:string key="type">term</json:string>
                        <json:string key="subType">variable</json:string>
                        <json:string key="value">inverse<xsl:value-of select="$suffix"/></json:string>
                        <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                    </json:map>
                    <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                </json:map>
            </json:array>
            <json:map key="where">
                <json:string key="type">pattern</json:string>
                <json:string key="subType">group</json:string>
                <json:array key="patterns">
                <!-- the view's SELECT in its own group: a SubSelect has to be the sole content of its braces -->
                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">group</json:string>
                    <json:array key="patterns">
                        <xsl:apply-templates select="$select" mode="ldh:strip-from"/>
                    </json:array>
                </json:map>

                <xsl:choose>
                    <!-- incoming: what points at the result set -->
                    <xsl:when test="$inverse">
                        <xsl:call-template name="ldh:GraphUnionPattern">
                            <xsl:with-param name="subject" select="'?subject' || $suffix"/>
                            <xsl:with-param name="predicate" select="$predicate-var"/>
                            <xsl:with-param name="object" select="$focus-var"/>
                            <xsl:with-param name="graph-var" select="'?subjectGraph' || $suffix"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- outgoing: the result set's own properties -->
                    <xsl:otherwise>
                        <xsl:call-template name="ldh:GraphUnionPattern">
                            <xsl:with-param name="subject" select="$focus-var"/>
                            <xsl:with-param name="predicate" select="$predicate-var"/>
                            <xsl:with-param name="object" select="$object-var"/>
                            <xsl:with-param name="graph-var" select="'?graph' || $suffix"/>
                        </xsl:call-template>

                            <json:map>
                                <json:string key="type">pattern</json:string>
                                <json:string key="subType">filter</json:string>
                            <json:map key="expression">
                                    <json:string key="type">expression</json:string>
                                    <json:string key="subType">operation</json:string>
                                <json:string key="operator">!</json:string>
                                <json:array key="args">
                                    <json:map>
                                            <json:string key="type">expression</json:string>
                                            <json:string key="subType">operation</json:string>
                                        <json:string key="operator">isliteral</json:string>
                                        <json:array key="args">
                                                <xsl:sequence select="ldh:term-node($object-var)"/>
                                        </json:array>
                                    </json:map>
                                </json:array>
                            </json:map>
                        </json:map>

                            <json:map>
                                <json:string key="type">pattern</json:string>
                                <json:string key="subType">filter</json:string>
                            <json:map key="expression">
                                    <json:string key="type">expression</json:string>
                                    <json:string key="subType">operation</json:string>
                                <json:string key="operator">exists</json:string>
                                <json:array key="args">
                                    <json:map>
                                            <json:string key="type">pattern</json:string>
                                            <json:string key="subType">group</json:string>
                                        <json:array key="patterns">
                                            <xsl:call-template name="ldh:GraphUnionPattern">
                                                <xsl:with-param name="subject" select="$object-var"/>
                                                <xsl:with-param name="predicate" select="'?objectPredicate' || $suffix"/>
                                                <xsl:with-param name="object" select="'?objectObject' || $suffix"/>
                                                <xsl:with-param name="graph-var" select="'?objectGraph' || $suffix"/>
                                            </xsl:call-template>
                                        </json:array>
                                    </json:map>
                                </json:array>
                            </json:map>
                        </json:map>
                    </xsl:otherwise>
                </xsl:choose>
                </json:array>
            </json:map>
            <json:map key="solutionModifiers">
                <json:map key="group">
                    <json:string key="type">solutionModifier</json:string>
                    <json:string key="subType">group</json:string>
                    <json:array key="groupings"><xsl:sequence select="ldh:term-node($predicate-var)"/></json:array>
                    <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                </json:map>
            </json:map>
        </json:map>
    </xsl:template>

    <!-- add parallax step -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:add-parallax-step">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- an expression's alias is unbound in the WHERE the step is appended to (ldh:wrap-subquery) -->
    <xsl:template match="/json:map[json:array[@key = 'variables']/*[1][self::json:map]]" mode="ldh:add-parallax-step" priority="2">
        <xsl:variable name="wrapped" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="." mode="ldh:wrap-subquery"/>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$wrapped/json:map" mode="#current"/>
    </xsl:template>

    <xsl:template match="/json:map" mode="ldh:add-parallax-step" priority="1">
        <!-- use the first ?var from the SELECT -->
        <xsl:param name="var-name" select="ldh:first-var-name(/json:map)" as="xs:string" tunnel="yes"/>
        <xsl:param name="suffix" select="ldh:fresh-var-suffix(., ('subject', 'graph'))" as="xs:string" tunnel="yes"/>
        <xsl:param name="new-var-name" select="'subject' || $suffix" as="xs:string" tunnel="yes"/>
        <xsl:param name="graph-var-name" select="'graph' || $suffix" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current">
                <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
                <xsl:with-param name="new-var-name" select="$new-var-name" tunnel="yes"/>
                <xsl:with-param name="graph-var-name" select="$graph-var-name" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/json:map/json:array[@key = 'variables']" mode="ldh:add-parallax-step" priority="1">
        <xsl:param name="new-var-name" as="xs:string" tunnel="yes"/>

        <xsl:apply-templates select="." mode="ldh:replace-variables">
            <xsl:with-param name="var-names" select="($new-var-name)" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="/json:map/json:map[@key = 'where']/json:array[@key = 'patterns']" mode="ldh:add-parallax-step" priority="1">
        <!-- use the first ?var from the SELECT -->
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="predicate" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="new-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="graph-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="title-predicate" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="title-new-var-name" as="xs:string?" tunnel="yes"/>
        <!-- an inverse step follows the predicate backwards: the new focus is the subject, the current one the object -->
        <xsl:param name="inverse" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:variable name="subject-var-name" select="if ($inverse) then $new-var-name else $var-name" as="xs:string"/>
        <xsl:variable name="object-var-name" select="if ($inverse) then $var-name else $new-var-name" as="xs:string"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">union</json:string>
                <json:array key="patterns">
                    <json:map>
                        <json:string key="type">pattern</json:string>
                        <json:string key="subType">bgp</json:string>
                        <json:array key="triples">
                            <json:map>
                                <json:string key="type">triple</json:string>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $subject-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="string($predicate)"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $object-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                            </json:map>

                            <xsl:if test="$title-new-var-name and $title-predicate"> <!-- TO-DO: support OPTIONAL? -->
                                <json:map>
                                    <json:string key="type">triple</json:string>
                                    <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $new-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                    <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="string($title-predicate)"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                    <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $title-new-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                                </json:map>
                            </xsl:if>
                        </json:array>
                    </json:map>
                    <json:map>
                        <json:string key="type">pattern</json:string>
                        <json:string key="subType">graph</json:string>
                        <json:array key="patterns">
                            <json:map>
                                <json:string key="type">pattern</json:string>
                                <json:string key="subType">bgp</json:string>
                                <json:array key="triples">
                                    <json:map>
                                        <json:string key="type">triple</json:string>
                                        <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $subject-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                        <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="string($predicate)"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                        <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $object-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                                    </json:map>

                                    <xsl:if test="$title-new-var-name and $title-predicate"> <!-- TO-DO: support OPTIONAL? -->
                                        <json:map>
                                            <json:string key="type">triple</json:string>
                                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $new-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="string($title-predicate)"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $title-new-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                                        </json:map>
                                    </xsl:if>
                                </json:array>
                            </json:map>
                        </json:array>
                        <json:map key="name">
                            <json:string key="type">term</json:string>
                            <json:string key="subType">variable</json:string>
                            <json:string key="value"><xsl:value-of select="$graph-var-name"/></json:string>
                            <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                        </json:map>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <!-- change ORDER BY -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:replace-order-by">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:map[@key = 'solutionModifiers'][not(json:map[@key = 'order'])]" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$var-name">
                <json:map key="order">
                    <json:string key="type">solutionModifier</json:string>
                    <json:string key="subType">order</json:string>
                    <json:array key="orderDefs">
                        <json:map>
                            <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $var-name"/><xsl:with-param name="key" select="'expression'"/></xsl:call-template>
                            <json:boolean key="descending">false</json:boolean>
                        </json:map>
                    </json:array>
                    <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                </json:map>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- if a new sort key is present, insert it as the first one -->
    <xsl:template match="json:array[@key = 'orderDefs'][count(json:map) = 1]" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>

        <xsl:if test="$var-name">
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="#current"/>

                <!-- unless the new one is the same as the existing one - in which case skip it -->
                <xsl:if test="not(json:map/json:map[@key = 'expression']/json:string[@key = 'value'] = $var-name)">
                    <json:map>
                        <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $var-name"/><xsl:with-param name="key" select="'expression'"/></xsl:call-template>
                        <json:boolean key="descending">false</json:boolean>
                    </json:map>
                </xsl:if>

                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <!-- if there are two sort keys already, replace the first one with the new one - if it's not empty and not equal to the second one -->
    <xsl:template match="json:array[@key = 'orderDefs'][count(json:map) = 2]/json:map[1]" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>
        
        <xsl:if test="$var-name and not($var-name = following-sibling::json:map/json:map[@key = 'expression']/json:string[@key = 'value'])">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- replace the first one's expression with the new one -->
    <xsl:template match="json:array[@key = 'orderDefs'][count(json:map) = 2]/json:map[1]/json:map[@key = 'expression']" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>

        <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $var-name"/><xsl:with-param name="key" select="'expression'"/></xsl:call-template>
    </xsl:template>
    
    <!-- toggle DESC -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:toggle-desc">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:array[@key = 'orderDefs']/json:map[1]" mode="ldh:toggle-desc" priority="1">
        <xsl:param name="desc" as="xs:boolean?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$desc and not(json:boolean[@key = 'descending'][. = 'true'])">
                <json:boolean key="descending">true</json:boolean>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:array[@key = 'orderDefs']/json:map[1]/json:boolean[@key = 'descending'][. = 'true']" mode="ldh:toggle-desc" priority="1">
        <xsl:param name="desc" as="xs:boolean?" tunnel="yes"/>

        <xsl:if test="$desc">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!--  facet values and COUNTs -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:bgp-value-counts">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- replace query variables with ?varName (COUNT(DISTINCT ?varName) AS ?countVarName) -->
    <xsl:template match="json:map/json:array[@key = 'variables']" mode="ldh:bgp-value-counts" priority="1">
        <xsl:param name="subject-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-sample-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <xsl:sequence select="ldh:term-node('?' || $object-var-name)"/>
            <!-- COUNT() of subjects -->
            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">bind</json:string>
                <json:map key="expression">
                    <json:string key="type">expression</json:string>
                    <json:string key="subType">aggregate</json:string>
                    <json:string key="aggregation">count</json:string>
                    <json:boolean key="distinct">true</json:boolean>
                    <json:array key="expression"><xsl:sequence select="ldh:term-node('?' || $subject-var-name)"/></json:array>
                </json:map>
                <json:map key="variable"><xsl:copy-of select="ldh:term-node('?' || $count-var-name)/node()"/></json:map>
            </json:map>
            <!-- SAMPLE() of ?labels -->
            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">bind</json:string>
                <json:map key="expression">
                    <json:string key="type">expression</json:string>
                    <json:string key="subType">aggregate</json:string>
                    <json:string key="aggregation">sample</json:string>
                    <json:boolean key="distinct">false</json:boolean>
                    <json:array key="expression"><xsl:sequence select="ldh:term-node('?' || $label-var-name)"/></json:array>
                </json:map>
                <json:map key="variable"><xsl:copy-of select="ldh:term-node('?' || $label-sample-var-name)/node()"/></json:map>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- add GROUP BY ?varName and ORDER BY DESC(?varName) after the WHERE -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'query']" mode="ldh:bgp-value-counts" priority="1">
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="descending" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()[not(self::json:map[@key = 'solutionModifiers'])]" mode="#current"/>
            <json:map key="solutionModifiers">
                <xsl:apply-templates select="json:map[@key = 'solutionModifiers']/@* | json:map[@key = 'solutionModifiers']/node()[not(self::json:map[@key = ('group', 'order')])]" mode="#current"/>
                <!-- TO-DO: will fail on queries with existing GROUP BY -->
                <json:map key="group">
                    <json:string key="type">solutionModifier</json:string>
                    <json:string key="subType">group</json:string>
                    <json:array key="groupings"><xsl:sequence select="ldh:term-node('?' || $object-var-name)"/></json:array>
                    <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                </json:map>
                <xsl:if test="not(json:map[@key = 'solutionModifiers']/json:map[@key = 'order'])">
                    <json:map key="order">
                        <json:string key="type">solutionModifier</json:string>
                        <json:string key="subType">order</json:string>
                        <json:array key="orderDefs">
                            <json:map>
                                <json:map key="expression"><xsl:copy-of select="ldh:term-node('?' || $count-var-name)/node()"/></json:map>
                                <json:boolean key="descending"><xsl:value-of select="$descending"/></json:boolean>
                            </json:map>
                        </json:array>
                        <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                    </json:map>
                </xsl:if>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- append OPTIONAL pattern looking up the values' ?label inside the BGP with object var name -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'bgp']/.." mode="ldh:bgp-value-counts" priority="1">
        <xsl:param name="bgp-triples-map" as="element()" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-graph-var-name" select="$label-var-name || 'graph'" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-property-var-name" select="$label-var-name || 'property'" as="xs:string" tunnel="yes"/>
        <!-- the lookup binds the label property to a variable instead of walking an alternative property path:
             Jena evaluates a path whose graph is a variable as a scan of every graph in the store, which took
             ~25s on a container of 830 resources (measured), against ~50ms for the same lookup with the
             predicate bound by VALUES -->
        <xsl:variable name="label-triple" as="element()">
            <json:map>
                <json:string key="type">triple</json:string>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $object-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $label-property-var-name"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $label-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
            </json:map>
        </xsl:variable>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'bgp']/json:array[@key = 'triples']/json:map/json:map[@key = 'object']/json:string[@key = 'subType'] = 'variable' and json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'bgp']/json:array[@key = 'triples']/json:map/json:map[@key = 'object']/json:string[@key = 'value'] = $object-var-name">
                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">optional</json:string>
                    <json:array key="patterns">
                        <json:map>
                            <json:string key="type">pattern</json:string>
                            <json:string key="subType">values</json:string>
                            <json:array key="variables"><xsl:sequence select="ldh:term-node('?' || $label-property-var-name)"/></json:array>
                            <json:array key="values">
                                <xsl:for-each select="$ldh:label-properties">
                                    <json:map>
                                        <json:map key="{$label-property-var-name}">
                                            <json:string key="type">term</json:string>
                                            <json:string key="subType">namedNode</json:string>
                                            <json:string key="value"><xsl:value-of select="."/></json:string>
                                            <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                                        </json:map>
                                    </json:map>
                                </xsl:for-each>
                            </json:array>
                        </json:map>
                        <json:map>
                            <json:string key="type">pattern</json:string>
                            <json:string key="subType">union</json:string>
                            <json:array key="patterns">
                                <json:map>
                                    <json:string key="type">pattern</json:string>
                                    <json:string key="subType">bgp</json:string>
                                    <json:array key="triples">
                                        <xsl:sequence select="$label-triple"/>
                                    </json:array>
                                </json:map>
                                <json:map>
                                    <json:string key="type">pattern</json:string>
                                    <json:string key="subType">graph</json:string>
                                    <json:array key="patterns">
                                        <json:map>
                                            <json:string key="type">pattern</json:string>
                                            <json:string key="subType">bgp</json:string>
                                            <json:array key="triples">
                                                <xsl:sequence select="$label-triple"/>
                                            </json:array>
                                        </json:map>
                                    </json:array>
                                    <json:map key="name">
                                        <json:string key="type">term</json:string>
                                        <json:string key="subType">variable</json:string>
                                        <json:string key="value"><xsl:value-of select="$label-graph-var-name"/></json:string>
                                        <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                                    </json:map>
                                </json:map>
                            </json:array>
                        </json:map>
                    </json:array>
                </json:map>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:map/json:array[@key = 'order']" mode="ldh:bgp-value-counts" priority="1">
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="descending" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>

            <json:map>
                <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
                <json:boolean key="descending"><xsl:value-of select="$descending"/></json:boolean>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <!-- facet FILTERs -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:filter-in">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- append FILTER (?varName IN ()) to WHERE, if it's not present yet, and replace IN() values -->
    <xsl:template match="json:map[@key = 'where']/json:array[@key = 'patterns']" mode="ldh:filter-in" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        <xsl:variable name="var-filter" select="json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'filter'][json:map[@key = 'expression']/json:array[@key = 'args']/json:map[json:string[@key = 'type'] = 'term'][json:string[@key = 'subType'] = 'variable'][json:string[@key = 'value'] = $var-name]][json:map[@key = 'expression']/json:array[@key = 'args']/json:array]" as="element()?"/>
        <xsl:variable name="where" as="element()">
            <xsl:choose>
                <xsl:when test="$var-filter">
                    <xsl:copy-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="#current"/>

                        <!-- append FILTER (?varName IN ()) to WHERE-->
                        <json:map>
                            <json:string key="type">pattern</json:string>
                            <json:string key="subType">filter</json:string>
                            <json:map key="expression">
                                <json:string key="type">expression</json:string>
                                <json:string key="subType">operation</json:string>
                                <json:string key="operator">in</json:string>
                                <json:array key="args">
                                    <xsl:sequence select="ldh:term-node('?' || $var-name)"/>
                                    <json:array>
                                        <!-- values -->
                                    </json:array>
                                </json:array>
                            </json:map>
                        </json:map>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- append value to IN() -->
        <xsl:apply-templates select="$where" mode="ldh:set-filter-in-values">
            <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
            <xsl:with-param name="values" select="$values" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:set-filter-in-values">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'filter']" mode="ldh:set-filter-in-values" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        
        <!-- remove the FILTER ($varName) if there are no values -->
        <xsl:if test="not(json:map[@key = 'expression']/json:array[@key = 'args']/json:map[json:string[@key = 'type'] = 'term'][json:string[@key = 'subType'] = 'variable'][json:string[@key = 'value'] = $var-name] and array:size($values) = 0)">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- replace IN () values for the FILTER with matching variable name -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'filter']/json:map[@key = 'expression']/json:array[@key = 'args']/json:array" mode="ldh:set-filter-in-values" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:choose>
                <!-- replace IN() values if $varName matches -->
                <xsl:when test="../json:map[json:string[@key = 'type'] = 'term'][json:string[@key = 'subType'] = 'variable'][json:string[@key = 'value'] = $var-name]">
                    <xsl:for-each select="1 to array:size($values)">
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:variable name="value" select="array:get($values, $pos)" as="map(xs:string, xs:string)"/>
                        <xsl:sequence select="ldh:term-node(
                            if ($value?type = 'literal')
                            then codepoints-to-string(34) || $value?value || codepoints-to-string(34) || (if ($value?lang) then '@' || $value?lang else if ($value?datatype) then '^^' || $value?datatype else '')
                            else $value?value
                        )"/>
                    </xsl:for-each>
                </xsl:when>
                <!-- otherwise, retain existing values -->
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!-- A SELECT whose first projection is an expression - (?s AS ?resource), (YEAR(NOW()) AS ?year) - binds that
         variable in its projection alone, so a rewrite that projects something else or appends patterns to its WHERE
         sees the variable unbound there: a COUNT counts nothing, and a pattern joined on it matches every triple in the
         store. This keeps the original whole, as a subquery, under a plain SELECT of the first variable, which the
         rewrites then treat like any other. The wrapper carries no prefixes, as the other wrappers here do: with any,
         the generator abbreviates IRIs and emits the subquery's prologue inside the group -->
    <xsl:template match="/json:map" mode="ldh:wrap-subquery">
        <json:map>
            <json:string key="type">query</json:string>
            <json:string key="subType">select</json:string>
            <json:array key="variables">
                <xsl:sequence select="ldh:term-node('?' || ldh:first-var-name(.))"/>
            </json:array>
            <!-- the dataset clause is only legal on the outermost query (see ldh:wrap-describe) -->
            <xsl:copy-of select="json:map[@key = 'datasets']"/>
            <!-- a subquery stands in a group: bare, the generator prints it without braces -->
            <json:map key="where">
                <json:string key="type">pattern</json:string>
                <json:string key="subType">group</json:string>
                <json:array key="patterns">
                    <json:map>
                        <json:string key="type">pattern</json:string>
                        <json:string key="subType">group</json:string>
                        <json:array key="patterns">
                            <xsl:apply-templates select="." mode="ldh:strip-from"/>
                        </json:array>
                    </json:map>
                </json:array>
            </json:map>
            <json:map key="solutionModifiers"/>
        </json:map>
    </xsl:template>

    <!-- result COUNT -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:result-count">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- a SELECT whose first projection is an expression binds its alias only in the projection, which the count
         replaces - COUNT(?alias) over the bare WHERE would count nothing. So the count is taken over the
         subquery's rows (ldh:wrap-subquery) -->
    <xsl:template match="/json:map[json:array[@key = 'variables']/*[1][self::json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'bind']]]" mode="ldh:result-count" priority="2">
        <xsl:variable name="wrapped" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="." mode="ldh:wrap-subquery"/>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$wrapped/json:map" mode="#current"/>
    </xsl:template>

    <!-- replace query variables with (COUNT(DISTINCT *) AS ?count) -->
    <xsl:template match="/json:map/json:array[@key = 'variables']" mode="ldh:result-count" priority="1">
        <xsl:param name="expression-var-name" as="xs:string?" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">bind</json:string>
                <json:map key="expression">
                    <json:string key="type">expression</json:string>
                    <json:string key="subType">aggregate</json:string>
                    <json:string key="aggregation">count</json:string>
                    <json:boolean key="distinct">true</json:boolean>
                    <json:array key="expression">
                        <xsl:choose>
                            <xsl:when test="$expression-var-name">
                                <xsl:sequence select="ldh:term-node('?' || $expression-var-name)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <json:map><json:string key="type">wildcard</json:string></json:map>
                            </xsl:otherwise>
                        </xsl:choose>
                    </json:array>
                </json:map>
                <json:map key="variable"><xsl:copy-of select="ldh:term-node('?' || $count-var-name)/node()"/></json:map>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <!-- container of the projected resource -->

    <!-- Rewrites a view's SELECT into the question "which container would a new solution of this
         projection be stored in?".

         A solution's resource is described in a graph, that graph IS its document, and the document's
         container is a triple the platform asserts on every one of them - so two joins answer it with
         no string operations on URIs and no vocabulary knowledge. Deliberately not via
         foaf:primaryTopic: a document's fragment entities link back to it differently from one
         vocabulary to the next (Northwind's #delivery uses foaf:page), while every document has
         sioc:has_container.

         DISTINCT with LIMIT 2 is the whole result: one row means the destination is determined, two
         mean it is ambiguous, and no row beyond the second carries information. DISTINCT is
         load-bearing rather than tidy - without it two solutions in the same container return two
         rows and read as ambiguity.

         The caller strips LIMIT/OFFSET/ORDER BY first (ldh:replace-limit and friends), the same way
         ldh:ResultCount does, so this asks about the whole result set rather than a page. -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:container-select">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- an expression's alias is unbound in the WHERE the joins are appended to (ldh:wrap-subquery) -->
    <xsl:template match="/json:map[json:array[@key = 'variables']/*[1][self::json:map[json:string[@key = 'type'] = 'pattern'][json:string[@key = 'subType'] = 'bind']]]" mode="ldh:container-select" priority="2">
        <xsl:variable name="wrapped" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="." mode="ldh:wrap-subquery"/>
            </xsl:document>
        </xsl:variable>

        <xsl:apply-templates select="$wrapped/json:map" mode="#current"/>
    </xsl:template>

    <xsl:template match="/json:map" mode="ldh:container-select" priority="1">
        <!-- every helper name is derived here and passed on, so no downstream template has to re-derive it
             from $suffix - a tunnel parameter declared without a default downstream is a required one, and the
             whole rewrite failed outright without it -->
        <xsl:param name="suffix" select="ldh:fresh-var-suffix(., ('container', 'doc', 'p', 'o', 'cg'))" as="xs:string" tunnel="yes"/>
        <xsl:param name="container-var-name" select="'container' || $suffix" as="xs:string" tunnel="yes"/>
        <xsl:param name="doc-var-name" select="'doc' || $suffix" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()[not(self::json:map[@key = 'solutionModifiers'])]" mode="#current">
                <xsl:with-param name="container-var-name" select="$container-var-name" tunnel="yes"/>
                <xsl:with-param name="doc-var-name" select="$doc-var-name" tunnel="yes"/>
                <xsl:with-param name="predicate-var-name" select="'p' || $suffix" tunnel="yes"/>
                <xsl:with-param name="object-var-name" select="'o' || $suffix" tunnel="yes"/>
                <xsl:with-param name="container-graph-var-name" select="'cg' || $suffix" tunnel="yes"/>
            </xsl:apply-templates>

            <!-- DISTINCT makes repeated solutions in the same container unambiguous. -->
            <xsl:if test="not(json:boolean[@key = 'distinct'])">
                <json:boolean key="distinct">true</json:boolean>
            </xsl:if>
            <json:map key="solutionModifiers">
                <xsl:apply-templates select="json:map[@key = 'solutionModifiers']/node()[not(self::json:map[@key = 'limitOffset'])]" mode="#current"/>
                <json:map key="limitOffset">
                    <json:string key="type">solutionModifier</json:string>
                    <json:string key="subType">limitOffset</json:string>
                    <json:number key="limit">2</json:number>
                    <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
                </json:map>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- project the container alone -->
    <xsl:template match="/json:map/json:array[@key = 'variables']" mode="ldh:container-select" priority="1">
        <xsl:param name="container-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>

            <xsl:sequence select="ldh:term-node('?' || $container-var-name)"/>
        </xsl:copy>
    </xsl:template>

    <!-- the two joins, appended to the view's own pattern. Scoped to the outermost where: a nested one
         belongs to a subquery or a group whose scope the focus variable may not even reach -->
    <xsl:template match="/json:map/json:map[@key = 'where']/json:array[@key = 'patterns']" mode="ldh:container-select" priority="1">
        <xsl:param name="focus-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="container-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="doc-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="predicate-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="container-graph-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- the graph the solution is described in, which is its document -->
            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">graph</json:string>
                <json:array key="patterns">
                    <json:map>
                        <json:string key="type">pattern</json:string>
                        <json:string key="subType">bgp</json:string>
                        <json:array key="triples">
                            <json:map>
                                <json:string key="type">triple</json:string>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $focus-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $predicate-var-name"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $object-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                            </json:map>
                        </json:array>
                    </json:map>
                </json:array>
                <json:map key="name"><xsl:copy-of select="ldh:term-node('?' || $doc-var-name)/node()"/></json:map>
            </json:map>

            <!-- that document's container -->
            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">graph</json:string>
                <json:array key="patterns">
                    <json:map>
                        <json:string key="type">pattern</json:string>
                        <json:string key="subType">bgp</json:string>
                        <json:array key="triples">
                            <json:map>
                                <json:string key="type">triple</json:string>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $doc-var-name"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'&sioc;has_container'"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'?' || $container-var-name"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
                            </json:map>
                        </json:array>
                    </json:map>
                </json:array>
                <json:map key="name"><xsl:copy-of select="ldh:term-node('?' || $container-graph-var-name)/node()"/></json:map>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- constructor template -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:add-constructor-triple">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- add a "?this $predicate [ a $object-type ]" pattern to the CONSTRUCT template -->
    <xsl:template match="json:map[@key = 'template']/json:array[@key = 'triples']" mode="ldh:add-constructor-triple" priority="1">
        <xsl:param name="subject" select="'?this'" as="xs:string" tunnel="yes"/>
        <xsl:param name="predicate" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="object-type"  as="xs:anyURI" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <json:map>
                <json:string key="type">triple</json:string>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="$subject"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="string($predicate)"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'_:ctor' || generate-id()"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
            </json:map>
            <json:map>
                <json:string key="type">triple</json:string>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'_:ctor' || generate-id()"/><xsl:with-param name="key" select="'subject'"/></xsl:call-template>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="'&rdf;type'"/><xsl:with-param name="key" select="'predicate'"/></xsl:call-template>
                <xsl:call-template name="ldh:term-entry"><xsl:with-param name="token" select="string($object-type)"/><xsl:with-param name="key" select="'object'"/></xsl:call-template>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <!-- FILTER(regex()) -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:add-regex-filter">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- append FILTER(regex()) to WHERE -->
    <xsl:template match="json:map[@key = 'where']/json:array[@key = 'patterns']" mode="ldh:add-regex-filter" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="pattern" as="xs:string" tunnel="yes"/>
        <xsl:param name="flags" as="xs:string?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">filter</json:string>
                <json:map key="expression">
                    <json:string key="type">expression</json:string>
                    <json:string key="subType">operation</json:string>
                    <json:string key="operator">regex</json:string>
                    <json:array key="args">
                        <xsl:sequence select="ldh:term-node('?' || $var-name)"/>
                        <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $pattern || codepoints-to-string(34))"/>
                        
                        <xsl:if test="$flags">
                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $flags || codepoints-to-string(34))"/>
                        </xsl:if>
                    </json:array>
                </json:map>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- FILTER($var IN ()) -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:add-filter-in">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- append FILTER($var IN ()) to WHERE -->
    <xsl:template match="json:map[@key = 'where']/json:array[@key = 'patterns']" mode="ldh:add-filter-in" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="xs:anyAtomicType*" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

                <json:map>
                    <json:string key="type">pattern</json:string>
                    <json:string key="subType">filter</json:string>
                    <json:map key="expression">
                        <json:string key="type">expression</json:string>
                        <json:string key="subType">operation</json:string>
                        <json:string key="operator">in</json:string>
                        <json:array key="args">
                            <xsl:sequence select="ldh:term-node('?' || $var-name)"/>
                            <json:array>
                                <xsl:for-each select="$values">
                                    <xsl:choose>
                                        <xsl:when test=". instance of xs:anyURI">
                                            <xsl:sequence select="ldh:term-node(string(.))"/>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:string">
                                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || . || codepoints-to-string(34))"/>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:integer">
                                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || . || codepoints-to-string(34) || '^^&xsd;integer')"/>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:float">
                                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || . || codepoints-to-string(34) || '^^&xsd;float')"/>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:boolean">
                                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || . || codepoints-to-string(34) || '^^&xsd;boolean')"/>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:date">
                                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || . || codepoints-to-string(34) || '^^&xsd;date')"/>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:dateTime">
                                            <xsl:sequence select="ldh:term-node(codepoints-to-string(34) || . || codepoints-to-string(34) || '^^&xsd;dateTime')"/>
                                        </xsl:when>
                                        <!-- TO-DO: support more XSD types -->
                                        <xsl:otherwise>
                                            <xsl:message>Value type not recognized</xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </json:array>
                        </json:array>
                    </json:map>
                </json:map>
            </xsl:copy>
    </xsl:template>

    <!-- Append VALUES block to WHERE clause -->

    <xsl:template match="@* | node()" mode="ldh:append-values">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:map[@key = 'where']/json:array[@key = 'patterns']" mode="ldh:append-values" priority="1">
        <xsl:param name="values-map" as="map(xs:string, xs:anyAtomicType)" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- Append VALUES block -->
            <json:map>
                <json:string key="type">pattern</json:string>
                <json:string key="subType">values</json:string>
                <json:array key="variables">
                    <xsl:for-each select="map:keys($values-map)">
                        <xsl:sequence select="ldh:term-node('?' || .)"/>
                    </xsl:for-each>
                </json:array>
                <json:array key="values">
                    <json:map>
                        <xsl:for-each select="map:keys($values-map)">
                            <json:map key="{.}">
                                <xsl:variable name="value" select="map:get($values-map, .)" as="xs:anyAtomicType"/>
                                <xsl:choose>
                                    <xsl:when test="$value instance of xs:anyURI"><xsl:sequence select="ldh:term-node(string($value))"/></xsl:when>
                                    <xsl:when test="$value instance of xs:integer"><xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $value || codepoints-to-string(34) || '^^&xsd;integer')"/></xsl:when>
                                    <xsl:when test="$value instance of xs:boolean"><xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $value || codepoints-to-string(34) || '^^&xsd;boolean')"/></xsl:when>
                                    <xsl:when test="$value instance of xs:date"><xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $value || codepoints-to-string(34) || '^^&xsd;date')"/></xsl:when>
                                    <xsl:when test="$value instance of xs:dateTime"><xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $value || codepoints-to-string(34) || '^^&xsd;dateTime')"/></xsl:when>
                                    <xsl:when test="$value instance of xs:float or $value instance of xs:double"><xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $value || codepoints-to-string(34) || '^^&xsd;double')"/></xsl:when>
                                    <xsl:otherwise><xsl:sequence select="ldh:term-node(codepoints-to-string(34) || $value || codepoints-to-string(34))"/></xsl:otherwise>
                                </xsl:choose>
                            </json:map>
                        </xsl:for-each>
                    </json:map>
                </json:array>
                <json:map key="loc"><json:string key="sourceLocationType">autoGenerate</json:string></json:map>
            </json:map>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
