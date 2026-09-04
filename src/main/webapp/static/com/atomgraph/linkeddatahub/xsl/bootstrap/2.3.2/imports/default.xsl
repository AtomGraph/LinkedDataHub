<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY java   "http://xml.apache.org/xalan/java/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:lapp="&lapp;"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:xsd="&xsd;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:acl="&acl;"
xmlns:sd="&sd;"
xmlns:ldt="&ldt;"
xmlns:sh="&sh;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:url="&java;java.net.URLDecoder"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
>

    <xsl:key name="predicates-by-object" match="*[@rdf:about]/* | *[@rdf:nodeID]/*" use="@rdf:resource | @rdf:nodeID"/>
    <xsl:key name="violations-by-root" match="*[@rdf:about] | *[@rdf:nodeID]" use="spin:violationRoot/@rdf:resource | spin:violationRoot/@rdf:nodeID"/>
    <xsl:key name="resources-by-type" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="rdf:type/@rdf:resource"/>

    <xsl:param name="ac:contextUri" as="xs:anyURI?"/>

    <xsl:function name="ac:property-label" as="xs:string?">
        <xsl:param name="property" as="element()"/>
        <xsl:param name="property-metadata" as="document-node()"/>

        <xsl:variable name="labels" as="xs:string*">
            <xsl:apply-templates select="$property" mode="ac:property-label">
                <xsl:with-param name="property-metadata" select="$property-metadata"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="upper-case(substring($labels[1], 1, 1)) || substring($labels[1], 2)"/>
    </xsl:function>

    <xsl:function name="ac:object-label" as="xs:string?">
        <xsl:param name="object" as="node()"/>
        <xsl:param name="object-metadata" as="document-node()"/>

        <xsl:variable name="labels" as="xs:string*">
            <xsl:apply-templates select="$object" mode="ac:object-label">
                <xsl:with-param name="object-metadata" select="$object-metadata" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="$labels[1]"/>
    </xsl:function>

    <xsl:template match="@rdf:resource | @rdf:nodeID | srx:uri" mode="ac:object-label" priority="1">
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:variable name="this" select="." as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="key('resources', .)">
                <xsl:apply-templates select="key('resources', .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="$object-metadata!key('resources', $this, .)">
                <!-- <xsl:message>ac:object-label(<xsl:value-of select="."/>) $object-metadata: <xsl:value-of select="serialize($object-metadata)"/></xsl:message> -->
                <xsl:apply-templates select="$object-metadata!key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="ixsl:doc-fetched(ac:document-uri(.)) and key('resources', ., document(ac:document-uri(.)))" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
                <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="doc-available(ac:document-uri(.)) and key('resources', ., document(ac:document-uri(.)))" use-when="system-property('xsl:product-name') = 'SAXON'">
                <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="contains(., '#') and not(ends-with(., '#'))">
                <xsl:sequence select="substring-after(., '#')"/>
            </xsl:when>
            <xsl:when test="string-length(tokenize(., '/')[last()]) &gt; 0">
                <xsl:sequence select="translate(tokenize(., '/')[last()], '_', ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:function name="acl:mode" as="xs:anyURI*" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:variable name="entries" as="xs:string*">
            <xsl:for-each select="$ldh:httpHeaders('Link')">
                <xsl:analyze-string select="." regex="&lt;[^&gt;]+&gt;[^&lt;]*">
                    <xsl:matching-substring>
                        <xsl:sequence select="."/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="for $entry in $entries return if (matches($entry, '^&lt;[^&gt;]+&gt;\s*;.*[;\s]rel\s*=\s*&quot;?[^&quot;\s,;]*acl#mode&quot;?')) then xs:anyURI(replace($entry, '^&lt;([^&gt;]+)&gt;.*$', '$1')) else ()"/>
    </xsl:function>

    <!-- the browser's own language preferences, overriding the Web-Client body that reads the writer-supplied parameter.
         Same normalisation as that one: primary subtags, deduped, 'en' when the browser offers nothing.

         navigator.languages comes back as a sequence of xs:untypedAtomic, so a for clause iterates the tags themselves -
         measured in the browser, where reaching into it with ?* instead reports "Required item type is function(*);
         supplied value is xs:untypedAtomic". Not every JS array converts this way: DataTransfer.types arrives as an XDM
         array and does need flattening, so check the shape rather than assuming either. -->
    <xsl:function name="ac:langs" as="xs:string*" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:variable name="langs" select="distinct-values(for $lang in ixsl:get(ixsl:window(), 'navigator.languages') return tokenize($lang, '-')[1])[not(. = ('', '*'))]" as="xs:string*"/>

        <xsl:sequence select="if (exists($langs)) then $langs else 'en'"/>
    </xsl:function>

    <xsl:function name="ac:uri" as="xs:anyURI?" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:sequence select="$ac:uri"/>
    </xsl:function>

    <!-- TimeMap URI from the Link response header (rel=timemap), present when the document is versioned -->
    <xsl:function name="ldh:timemap" as="xs:anyURI?" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:variable name="entries" as="xs:string*">
            <xsl:for-each select="$ldh:httpHeaders('Link')">
                <xsl:analyze-string select="." regex="&lt;[^&gt;]+&gt;[^&lt;]*">
                    <xsl:matching-substring>
                        <xsl:sequence select="."/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="(for $entry in $entries return if (matches($entry, '^&lt;[^&gt;]+&gt;\s*;.*[;\s]rel\s*=\s*&quot;?timemap&quot;?([;\s]|$)')) then xs:anyURI(replace($entry, '^&lt;([^&gt;]+)&gt;.*$', '$1')) else ())[1]"/>
    </xsl:function>

    <!-- Memento-Datetime response header value, present on ?version= responses -->
    <xsl:function name="ldh:memento-datetime" as="xs:string?" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:sequence select="$ldh:httpHeaders('Memento-Datetime')[1]"/>
    </xsl:function>

    <!-- Strips the leftmost subdomain and returns parent dataspace origin (scheme + host + port) -->
    <xsl:function name="ldh:parent-origin" as="xs:anyURI?">
        <xsl:param name="uri" as="xs:anyURI"/>

        <xsl:variable name="scheme" select="replace($uri, '^(https?://).*$', '$1')" as="xs:string"/>
        <xsl:variable name="host" select="replace($uri, '^https?://([^/:]+).*$', '$1')" as="xs:string"/>
        <xsl:variable name="port" select="if (matches($uri, ':\d+')) then replace($uri, '^https?://[^:]+:(\d+).*$', '$1') else ''" as="xs:string"/>

        <!-- Split host by dots -->
        <xsl:variable name="parts" select="tokenize($host, '\.')" as="xs:string+"/>

        <xsl:choose>
            <!-- If only one part (e.g., "localhost"), return empty - no parent -->
            <xsl:when test="count($parts) = 1">
                <xsl:sequence select="()"/>
            </xsl:when>
            <!-- Strip leftmost subdomain -->
            <xsl:otherwise>
                <xsl:variable name="parent-host" select="string-join(subsequence($parts, 2), '.')" as="xs:string"/>
                <xsl:variable name="parent-origin" select="$scheme || $parent-host || (if ($port != '') then (':' || $port) else '') || '/'" as="xs:string"/>
                <xsl:sequence select="xs:anyURI($parent-origin)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="ldh:request-uri" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:sequence select="$ldh:requestUri"/>
    </xsl:function>
    
    <xsl:function name="ldh:query-params" as="map(xs:string, xs:string*)">
        <!-- ac:document-uri strips the URL's #fragment so it doesn't get glued onto the last query value -->
        <xsl:sequence select="ldh:parse-query-params(substring-after(ac:document-uri(ldh:request-uri()), '?'))"/>
    </xsl:function>

    <!-- representation-selecting query params (unlike display state such as ?mode, these select a different representation of the document URI) - they must survive the RDF re-fetch and every URL rebuild -->
    <xsl:function name="ldh:snapshot-params" as="map(xs:string, xs:string*)">
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>

        <xsl:sequence select="map:merge((if (map:contains($query-params, 'version')) then map{ 'version': $query-params?version } else (), if (map:contains($query-params, 'timemap')) then map{ 'timemap': $query-params?timemap } else ()))"/>
    </xsl:function>
    
    <xsl:function name="ldh:base-uri" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="arg" as="node()"/>
        
        <xsl:sequence select="base-uri($arg)"/>
    </xsl:function>
      
    <xsl:function name="ldt:base" as="xs:anyURI">
        <xsl:sequence select="$ldt:base"/>
    </xsl:function>

    <xsl:function name="sd:endpoint" as="xs:anyURI">
        <xsl:sequence select="resolve-uri('sparql', ldt:base())"/>
    </xsl:function>

    <xsl:function name="lapp:origin" as="xs:anyURI">
        <xsl:param name="uri" as="xs:anyURI"/>
        <!-- no trailing slash -->
        <xsl:sequence select="xs:anyURI(replace($uri, '^(https?://[^/]+).*$', '$1'))"/>
    </xsl:function>

    <xsl:function name="lapp:origin" as="xs:anyURI?" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:sequence select="$lapp:origin"/>
    </xsl:function>

    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="uri" as="xs:anyURI?"/>

        <xsl:sequence select="ldh:href($uri, map{}, ())"/>
    </xsl:function>

    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>
        
        <xsl:sequence select="ldh:href($uri, $query-params, ())"/>
    </xsl:function>
    
    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>
        <xsl:param name="fragment" as="xs:string?"/>

        <xsl:choose>
            <!-- cross-origin URI - wrap in ?uri= on the page origin so the request stays same-origin (carries credentials, then ProxyRequestFilter forwards) -->
            <xsl:when test="$uri and not(starts-with($uri, lapp:origin(ldh:request-uri()) || '/'))">
                <xsl:sequence select="xs:anyURI(ac:build-uri(ac:absolute-path(ldh:request-uri()), map:merge((map{ 'uri': string($uri) }, $query-params))) || (if ($fragment) then ('#' || $fragment) else ()))"/>
            </xsl:when>
            <!-- local URI -->
            <xsl:otherwise>
                <xsl:variable name="parsed-query-params" select="ldh:parse-query-params(substring-after(ac:document-uri($uri), '?'))" as="map(xs:string, xs:string*)"/>
                <xsl:sequence select="xs:anyURI(ac:build-uri(ac:absolute-path($uri), map:merge(($parsed-query-params, $query-params), map{ 'duplicates': 'use-last' } )) || (if ($fragment) then ('#' || $fragment) else ()))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- inverse of ldh:href: given a navigable href, return { doc-uri, query-params, fragment }.
         cross-origin direct: href IS the doc URI (its query is part of the resource identity, no LDH display params).
         local proxied (?uri=...): unwrap the inner URI (keeping its query); outer query minus 'uri' is LDH display params.
         pure local: strip query/fragment off path; outer query is LDH display params. -->
    <xsl:function name="ldh:parse-href" as="map(xs:string, item()?)">
        <xsl:param name="href" as="xs:anyURI"/>

        <xsl:variable name="is-local" select="starts-with($href, lapp:origin(ldh:request-uri()) || '/')" as="xs:boolean"/>
        <xsl:variable name="query-params" select="ldh:parse-query-params(substring-after(ac:document-uri($href), '?'))" as="map(xs:string, xs:string*)"/>
        <xsl:variable name="fragment" select="ac:fragment-id($href)" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="not($is-local)">
                <xsl:sequence select="map{ 'doc-uri': ac:document-uri($href), 'query-params': map{}, 'fragment': $fragment }"/>
            </xsl:when>
            <xsl:when test="map:contains($query-params, 'uri')">
                <xsl:sequence select="map{ 'doc-uri': ac:document-uri(xs:anyURI(map:get($query-params, 'uri'))), 'query-params': map:remove($query-params, 'uri'), 'fragment': $fragment }"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="map{ 'doc-uri': ac:absolute-path($href), 'query-params': $query-params, 'fragment': $fragment }"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:build-query" as="map(xs:string, xs:string*)">
        <xsl:param name="mode" as="xs:anyURI*"/>

        <xsl:sequence select="if (exists($mode)) then map{ 'mode': for $m in $mode return string($m) } else map{}"/>
    </xsl:function>

    <xsl:function name="ldh:query-result" as="document-node()">
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($results-uri, map{})" as="xs:anyURI"/>

        <xsl:sequence select="document($request-uri)"/>
    </xsl:function>

    <xsl:function name="ac:mode" as="xs:anyURI">
        <xsl:param name="doc" as="document-node()"/>
        <xsl:variable name="block-uris" select="key('resources', ac:absolute-path(ldh:base-uri($doc)), $doc)/rdf:*[starts-with(local-name(), '_')]/@rdf:resource" as="xs:anyURI*"/>
        <xsl:variable name="has-content" select="exists($block-uris)" as="xs:boolean"/>
        
        <xsl:choose>
            <xsl:when test="ldh:query-params()?mode">
                <xsl:sequence select="xs:anyURI(ldh:query-params()?mode)"/>
            </xsl:when>
            <xsl:when test="$has-content">
                <xsl:sequence select="xs:anyURI('&ldh;ContentMode')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="xs:anyURI('&ac;ReadMode')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- fetches the spin:constructor query texts for the whole type set (subclass closure, DISTINCT). Shared with the SaxonJS constructor machinery in client/functions.xsl -->
    <xsl:function name="ldh:constructor-query" as="xs:string">
        <xsl:param name="types" as="xs:anyURI*"/>

        <xsl:sequence select="'SELECT DISTINCT ?constructor ?text WHERE { VALUES ?type { ' || string-join(for $type in $types return '&lt;' || $type || '&gt;', ' ') || ' } ?type &lt;http://www.w3.org/2000/01/rdf-schema#subClassOf&gt;* ?class . ?class &lt;http://spinrdf.org/spin#constructor&gt; ?constructor . ?constructor &lt;http://spinrdf.org/sp#text&gt; ?text . }'"/>
    </xsl:function>

    <!-- Parses a SPARQL query string into the parse-tree JSON subset that ldh:construct-instance consumes: a 'template' array of subject/predicate/object term strings in the SPARQL.js 2.x serialization (see ldh:triples-to-descriptions) and a 'where' array whose non-emptiness marks a query that cannot be instantiated as a pure template. Dual-declared so both products parse identically: the SaxonJS declaration wraps the browser's SPARQL.js Parser; under Saxon the registered ParseQuery extension function (Jena QueryFactory) emits the same subset and takes precedence over the standalone-compilation fallback below (override-extension-function="no"). ParseQuery, ldh:triples-to-descriptions and ldh:construct-instance must change in lockstep if SPARQL.js is upgraded to 3.x. -->
    <xsl:function name="ldh:parse-query" as="xs:string" use-when="system-property('xsl:product-name') = 'SaxonJS'">
        <xsl:param name="query" as="xs:string"/>

        <!-- read the parse tree through JSON serialization - SaxonJS does not marshal plain JS arrays for ixsl:get() access -->
        <xsl:sequence select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ ixsl:call($sparql-parser, 'parse', [ $query ]) ])"/>
    </xsl:function>

    <xsl:function name="ldh:parse-query" as="xs:string" override-extension-function="no" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="query" as="xs:string"/>

        <xsl:sequence select="'{}'"/>
    </xsl:function>

    <!-- constructor instantiation: the template mirrors the instance. One SELECT fetches the
    spin:constructor query texts for the whole type set (subclass closure, DISTINCT), and the
    CONSTRUCT templates are expanded onto a single instance — one bnode prototype typed with all
    the classes, value-range markers as sibling Descriptions in the same document. -->

    <!-- rewrites a CONSTRUCT template term: ?this becomes the shared instance label, other blank
    node labels are prefixed per constructor position so markers from different templates cannot collide -->
    <xsl:function name="ldh:instance-term" as="xs:string">
        <xsl:param name="term" as="xs:string"/>
        <xsl:param name="pos" as="xs:integer"/>

        <xsl:sequence select="if ($term = ('?this', '$this')) then '_:instance' else if (starts-with($term, '_:')) then '_:c' || $pos || '_' || substring-after($term, '_:') else $term"/>
    </xsl:function>

    <!-- returns the sorted type set of a pure value-range marker (a blank node carrying only rdf:type),
    or the empty string when the label is not a pure marker -->
    <xsl:function name="ldh:marker-types" as="xs:string">
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="triples" as="element()*"/>

        <xsl:variable name="subject-triples" select="$triples[json:string[@key = 'subject'] = $label]" as="element()*"/>
        <xsl:sequence select="if (starts-with($label, '_:') and exists($subject-triples) and not($subject-triples[not(json:string[@key = 'predicate'] = '&rdf;type')])) then string-join(sort($subject-triples/json:string[@key = 'object']), ' ') else ''"/>
    </xsl:function>

    <!-- parses SPARQL.js 2.x triple maps into RDF/XML. The term serialization is produced by the SPARQL.js Parser in the browser and by the ParseQuery (Jena) extension function server-side — both behind ldh:parse-query — as well as by ldh:parse-rdf-post()/ldh:descriptions-to-triples() in client/functions.xsl; all of them and this function must stay in lockstep -->
    <xsl:function name="ldh:triples-to-descriptions" as="element()*">
        <xsl:param name="triples" as="element()*"/>

        <xsl:for-each-group select="$triples" group-by="json:string[@key = 'subject']">
            <rdf:Description>
                <!-- subject -->
                <xsl:choose>
                    <xsl:when test="starts-with(current-grouping-key(), '_:')">
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
                            <!-- TO-DO: upgrade SPARQL.js to 3.x. We need regex functions in the following logic because quoting/escaping sucks in SPARQL.js 2.x -->
                            <xsl:choose>
                                <!-- XML literal -->
                                <!-- note: SPARQL.js 2.x does NOT wrap the datatype URI into <> -->
                                <xsl:when test="matches(., '^&quot;(.*)&quot;\^\^&rdf;XMLLiteral$', 's')">
                                    <xsl:attribute name="rdf:parseType" select="'Literal'"/>
                                    <!-- XML literal has to be fixed previously, otherwise parse-xml() will fail -->
                                    <xsl:analyze-string select="." regex="^&quot;(.*)&quot;\^\^&rdf;XMLLiteral$" flags="s">
                                        <xsl:matching-substring>
                                            <xsl:sequence select="parse-xml(regex-group(1))"/>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:when>
                                <!-- typed literal -->
                                <!-- note: SPARQL.js 2.x does NOT wrap the datatype URI into <> -->
                                <xsl:when test="matches(., '^&quot;(.*)&quot;\^\^(.*)$', 's')">
                                    <xsl:analyze-string select="." regex="^&quot;(.*)&quot;\^\^(.*)$" flags="s">
                                        <xsl:matching-substring>
                                            <xsl:attribute name="rdf:datatype" select="regex-group(2)"/>

                                            <xsl:sequence select="regex-group(1)"/>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:when>
                                <!-- language-tagged literal -->
                                <xsl:when test="matches(., '^&quot;(.*?)&quot;@(.*)$', 's')">
                                    <xsl:analyze-string select="." regex="^&quot;(.*?)&quot;@(.*)$" flags="s">
                                        <xsl:matching-substring>
                                            <xsl:attribute name="xml:lang" select="regex-group(2)"/>

                                            <xsl:sequence select="regex-group(1)"/>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:when>
                                <!-- plain literal -->
                                <xsl:when test="starts-with(., '&quot;') and ends-with(., '&quot;')">
                                    <xsl:sequence select="substring(., 2, string-length(.) - 2)"/> <!-- trim first and last character -->
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

    <!-- instantiates spin:constructor CONSTRUCT templates onto a single instance typed with $types.
    Constructors must be pure templates: a non-empty WHERE clause cannot be instantiated
    and is skipped with a warning. Properties asserted by several constructors with the same value
    range are collapsed; different ranges on one predicate all survive. -->
    <xsl:function name="ldh:construct-instance" as="document-node()">
        <xsl:param name="texts" as="xs:string*"/>
        <xsl:param name="types" as="xs:anyURI*"/>

        <xsl:variable name="raw-triples" as="element()*">
            <xsl:for-each select="$texts">
                <xsl:variable name="pos" select="position()" as="xs:integer"/>
                <xsl:variable name="query-xml" select="json-to-xml(ldh:parse-query(string(.)))" as="document-node()"/>
                <xsl:choose>
                    <xsl:when test="exists($query-xml/json:map/json:array[@key = 'where']/*)">
                        <xsl:message>Constructor skipped: a non-empty WHERE clause cannot be instantiated: <xsl:value-of select="."/></xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="$query-xml/json:map/json:array[@key = 'template']/json:map">
                            <xsl:variable name="predicate" select="json:string[@key = 'predicate']" as="xs:string"/>
                            <xsl:choose>
                                <xsl:when test="starts-with($predicate, '?') or starts-with($predicate, '$')">
                                    <xsl:message>Constructor template triple skipped: variable predicate <xsl:value-of select="$predicate"/></xsl:message>
                                </xsl:when>
                                <xsl:otherwise>
                                    <json:map>
                                        <json:string key="subject"><xsl:value-of select="ldh:instance-term(json:string[@key = 'subject'], $pos)"/></json:string>
                                        <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                                        <json:string key="object"><xsl:value-of select="ldh:instance-term(json:string[@key = 'object'], $pos)"/></json:string>
                                    </json:map>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <!-- collapse instance properties whose (predicate, marker type set) coincide - the same property
        asserted by several constructors (e.g. dct:title via a superclass and the class's own constructor) -->
        <xsl:variable name="dropped-markers" as="xs:string*">
            <xsl:for-each-group select="$raw-triples[json:string[@key = 'subject'] = '_:instance'][not(ldh:marker-types(json:string[@key = 'object'], $raw-triples) = '')]" group-by="json:string[@key = 'predicate'] || ' ' || ldh:marker-types(json:string[@key = 'object'], $raw-triples)">
                <xsl:sequence select="for $duplicate in subsequence(current-group(), 2) return string($duplicate/json:string[@key = 'object'])"/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="triples" select="$raw-triples[not(json:string[@key = 'subject'] = '_:instance' and json:string[@key = 'object'] = $dropped-markers)][not(json:string[@key = 'subject'] = $dropped-markers)]" as="element()*"/>

        <xsl:variable name="type-triples" as="element()*">
            <xsl:for-each select="$types">
                <json:map>
                    <json:string key="subject">_:instance</json:string>
                    <json:string key="predicate">&rdf;type</json:string>
                    <json:string key="object"><xsl:value-of select="."/></json:string>
                </json:map>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="doc" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <xsl:sequence select="ldh:triples-to-descriptions(($triples, $type-triples))"/>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:sequence select="$doc"/>
    </xsl:function>

    <!-- Pure derivation: produces an instance document from a class-keyed, bnode-prototyped constructor by re-keying the prototype Description (the one whose rdf:type matches $forClass) under the given identity. The input constructor is not modified. Pass $about to mint a URI-identified instance (the document-creation case and the fragment-instance case) or $nodeID to mint a bnode-identified instance with a deterministic label. Implementation reuses the existing mode="ldh:SetResourceID" pass — it's the same identity-rewrite, just exposed as a function so call sites can keep the constructor pure and derive the instance separately. -->
    <xsl:function name="ldh:instantiate-constructor" as="document-node()">
        <xsl:param name="constructor" as="document-node()"/>
        <xsl:param name="forClass" as="xs:anyURI"/>
        <xsl:param name="about" as="xs:anyURI?"/>
        <xsl:param name="nodeID" as="xs:string?"/>

        <xsl:document>
            <xsl:apply-templates select="$constructor" mode="ldh:SetResourceID">
                <xsl:with-param name="forClass" select="$forClass" tunnel="yes"/>
                <xsl:with-param name="about" select="$about" tunnel="yes"/>
                <xsl:with-param name="nodeID" select="$nodeID" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:function>

    <!-- Pure derivation: folds a SHACL-derived constructor and a SPIN-derived constructor into one bnode-prototyped constructor for $forClass. Aligns the SPIN side's prototype bnode label to the SHACL side's (via mode="ldh:RenameBnode"), then groups Descriptions by identity so the two prototypes collapse into one with combined children. Value-range siblings on each side keep their own bnode labels and stay as distinct Descriptions in the merged doc. When the SHACL side has no prototype Description for $forClass (e.g. no NodeShape targets that class), returns the SPIN side unchanged. -->
    <xsl:function name="ldh:merge-constructors" as="document-node()">
        <xsl:param name="shape-constructor" as="document-node()?"/>
        <xsl:param name="spin-constructor" as="document-node()"/>
        <xsl:param name="forClass" as="xs:anyURI"/>

        <!-- Prototype = the Description that (a) carries $forClass as a type and (b) has property assertions beyond rdf:type. The [* except rdf:type] guard excludes pure-typing Descriptions (e.g. <rdf:Description rdf:nodeID="A1"><rdf:type rdf:resource="…/Class"/></rdf:Description> emitted as a range marker on a property). The [1] tiebreaker handles constructors that legitimately ship multiple instances of $forClass (content-block co-shipping, nested templates); the merge keys off whichever prototype we name here, others stay as distinct siblings. -->
        <xsl:variable name="shape-proto-id" select="($shape-constructor/rdf:RDF/*[rdf:type/@rdf:resource = $forClass][* except rdf:type]/@rdf:nodeID/string())[1]" as="xs:string?"/>
        <xsl:variable name="spin-proto-id" select="($spin-constructor/rdf:RDF/*[rdf:type/@rdf:resource = $forClass][* except rdf:type]/@rdf:nodeID/string())[1]" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="empty($shape-proto-id)">
                <xsl:sequence select="$spin-constructor"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="spin-aligned" as="document-node()">
                    <xsl:choose>
                        <xsl:when test="exists($spin-proto-id) and $spin-proto-id != $shape-proto-id">
                            <xsl:document>
                                <xsl:apply-templates select="$spin-constructor" mode="ldh:RenameBnode">
                                    <xsl:with-param name="from" select="$spin-proto-id" tunnel="yes"/>
                                    <xsl:with-param name="to" select="$shape-proto-id" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:document>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$spin-constructor"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:document>
                    <rdf:RDF>
                        <xsl:for-each-group select="$shape-constructor/rdf:RDF/*, $spin-aligned/rdf:RDF/*" group-by="(@rdf:about, @rdf:nodeID)[1]">
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:for-each-group select="current-group()/*" group-by="(@rdf:resource, @rdf:nodeID, node(), @rdf:datatype, @xml:lang)[1]">
                                    <xsl:sequence select="."/>
                                </xsl:for-each-group>
                            </xsl:copy>
                        </xsl:for-each-group>
                    </rdf:RDF>
                </xsl:document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Alpha-renames every @rdf:nodeID equal to $from (in scope as a tunnel param) to $to, identity-copies everything else. Covers both the Description's own @rdf:nodeID (prototype identity) and back-references on property elements (e.g. <foaf:knows rdf:nodeID="X"/>) so RDF graph references stay intact across the rename. -->
    <xsl:template match="@rdf:nodeID" mode="ldh:RenameBnode" priority="1">
        <xsl:param name="from" as="xs:string" tunnel="yes"/>
        <xsl:param name="to" as="xs:string" tunnel="yes"/>

        <xsl:choose>
            <xsl:when test=". = $from">
                <xsl:attribute name="rdf:nodeID" select="$to"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@* | node()" mode="ldh:RenameBnode">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Builds the pure, bnode-prototyped constructor consumed by bs2:FormControl from the two raw inputs the promise chain has fetched: $shapes (SHACL NodeShape RDF) and $constructed-doc (SPIN constructor RDF fetched via the ns SPARQL endpoint). Shared by every flow that ends in bs2:FormControl (ldh:render-row-form for EDIT, ldh:render-row-form-violation for violation re-render, and the Phase 4 modal/app-settings/signup renderers to come) so the merge logic lives in exactly one place. Returns the SPIN side unchanged when shapes are absent (typical for system classes like sp:Describe), returns the merged doc when both sides exist (user-defined classes like skos:Concept with both SPIN defaults and SHACL constraints), or empty if neither side provides input. -->
    <xsl:function name="ldh:build-merged-constructor" as="document-node()?">
        <xsl:param name="shapes" as="document-node()?"/>
        <xsl:param name="constructed-doc" as="document-node()?"/>
        <xsl:param name="forClass" as="xs:anyURI?"/>

        <xsl:variable name="shape-instance-doc" as="document-node()?">
            <xsl:if test="exists($shapes)">
                <xsl:variable name="raw" as="document-node()">
                    <xsl:apply-templates select="$shapes" mode="ldh:Shape"/>
                </xsl:variable>
                <xsl:sequence select="ldh:reserialize($raw)"/>
            </xsl:if>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="exists($constructed-doc) and exists($forClass)">
                <xsl:sequence select="ldh:merge-constructors($shape-instance-doc, $constructed-doc, $forClass)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$constructed-doc"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- reserialize RDF/XML document by moving nested rdf:Descriptions to top-level following Jena's "plain" RDF/XML structure  -->
    <xsl:function name="ldh:reserialize" as="document-node()">
        <xsl:param name="doc" as="document-node()"/>
        
        <xsl:document>
            <xsl:apply-templates select="$doc" mode="ldh:Reserialize"/>
        </xsl:document>
    </xsl:function>
    
    <xsl:template match="rdf:RDF" mode="ldh:Reserialize" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:for-each select="rdf:Description/*/rdf:Description">
                <xsl:copy>
                    <xsl:attribute name="rdf:nodeID" select="generate-id()"/>
                    
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="rdf:Description/*[rdf:Description]" mode="ldh:Reserialize" priority="1">
        <xsl:copy>
            <xsl:attribute name="rdf:nodeID" select="generate-id(rdf:Description)"/>
        </xsl:copy>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:Reserialize">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="ac:value-intersect" as="xs:anyAtomicType*">
        <xsl:param name="arg1" as="xs:anyAtomicType*"/>
        <xsl:param name="arg2" as="xs:anyAtomicType*"/>
        
        <xsl:sequence select="distinct-values($arg1[.=$arg2])"/>
    </xsl:function>

    <xsl:function name="ac:value-except" as="xs:anyAtomicType*">
        <xsl:param name="arg1" as="xs:anyAtomicType*"/>
        <xsl:param name="arg2" as="xs:anyAtomicType*"/>

        <xsl:sequence select="distinct-values($arg1[not(.=$arg2)])"/>
    </xsl:function>

    <!-- caps a key component's length: SaxonJS backs distinct-values() and xsl:for-each-group with a hash trie whose
         insert recurses once per character of the key, so keys over the JS stack limit (~6-7K frames) crash the transform
         ("too much recursion"). Long values keep a prefix and fold the whole string into a length + rolling hash -->
    <xsl:function name="ldh:bounded-key" as="xs:string?">
        <xsl:param name="value" as="xs:string?"/>

        <xsl:sequence select="if (string-length($value) le 1000) then $value else concat(substring($value, 1, 100), '#', string-length($value), '#', fold-left(string-to-codepoints($value), 0, function($hash, $codepoint) { ($hash * 31 + $codepoint) mod 4294967296 }))"/>
    </xsl:function>

    <!-- identity of one triple given its RDF/XML property element, as subject | predicate | object.
         With $normalize-numerics, numeric literals are normalized so lexically different but equal values (1 vs 1.0) compare
         equal across serializations; without it, comparison is exactly lexical (canonical same-writer output makes that safe).
         XMLLiterals are keyed on their serialized content, bounded via ldh:bounded-key() so oversized literals don't overflow
         SaxonJS's per-character key recursion. Blank node labels are serializer-generated, so bnode-involving
         triples never compare equal across two documents -->
    <xsl:function name="ldh:triple-key" as="xs:string">
        <xsl:param name="property" as="element()"/>
        <xsl:param name="normalize-numerics" as="xs:boolean"/>

        <xsl:for-each select="$property">
            <xsl:sequence select="concat(../@rdf:about, '|', ../@rdf:nodeID, '|', namespace-uri(), local-name(), '|', @rdf:resource, @rdf:nodeID, ldh:bounded-key(if (@rdf:parseType = 'Literal') then serialize(node()) else if ($normalize-numerics and text() castable as xs:float) then string(xs:float(text())) else text()), '|', @rdf:datatype, @xml:lang)"/>
        </xsl:for-each>
    </xsl:function>

    <!-- one map entry per triple of a flat RDF/XML document, keyed with ldh:triple-key() -->
    <xsl:function name="ldh:triples-map" as="map(xs:string, element())">
        <xsl:param name="doc" as="document-node()"/>
        <xsl:param name="normalize-numerics" as="xs:boolean"/>

        <xsl:map>
            <xsl:for-each select="$doc/rdf:RDF/rdf:Description/*">
                <xsl:map-entry key="ldh:triple-key(., $normalize-numerics)" select="."/>
            </xsl:for-each>
        </xsl:map>
    </xsl:function>

    <!-- version-diff status of a whole resource description: added/removed when every one of its triples is one-sided, changed when only some are -->
    <xsl:function name="ldh:diff-class" as="xs:string?">
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="added-keys" as="xs:string*"/>
        <xsl:param name="removed-keys" as="xs:string*"/>

        <!-- non-diff renders pass empty key sets - skip the per-triple key serialization entirely -->
        <xsl:variable name="triple-keys" select="if (empty(($added-keys, $removed-keys))) then () else $resource/* ! ldh:triple-key(., false())" as="xs:string*"/>
        <xsl:choose>
            <xsl:when test="exists($triple-keys) and (every $triple-key in $triple-keys satisfies $triple-key = $added-keys)">
                <xsl:sequence select="'diff-added'"/>
            </xsl:when>
            <xsl:when test="exists($triple-keys) and (every $triple-key in $triple-keys satisfies $triple-key = $removed-keys)">
                <xsl:sequence select="'diff-removed'"/>
            </xsl:when>
            <xsl:when test="$triple-keys = ($added-keys, $removed-keys)">
                <xsl:sequence select="'diff-changed'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="ldh:url-decode" as="xs:string" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="encoded-string" as="xs:string"/>
        
        <xsl:sequence select="ixsl:call(ixsl:window(), 'decodeURIComponent', [ $encoded-string ])"/>
    </xsl:function>

    <xsl:function name="ldh:url-decode" as="xs:string" use-when="system-property('xsl:product-name') = 'SAXON'" override-extension-function="no" cache="yes">
        <xsl:param name="encoded-string" as="xs:string"/>
        
        <xsl:message terminate="yes">
            Not implemented -- com.atomgraph.linkeddatahub.writer.function.URLDecode needs to be registered as an extension function
        </xsl:message>
    </xsl:function>

    <xsl:function name="ldh:parse-query-params" as="map(xs:string, xs:string*)">
        <xsl:param name="query-string" as="xs:string"/>

        <xsl:sequence select="map:merge(
            tokenize($query-string, '&amp;')[normalize-space()]
            !
            (let $p := tokenize(., '=')
             return map:entry(
               ldh:url-decode($p[1]),
               if (count($p) &gt; 1)
               then ldh:url-decode(string-join(subsequence($p, 2), '='))
               else ''
             ))
            ,
            map { 'duplicates': 'combine' }
        )"/>
    </xsl:function>
    
    <!-- function stub so that Saxon-EE doesn't complain when compiling SEF -->
    <xsl:function name="ldh:send-request" as="document-node()?" override-extension-function="no" cache="yes">
        <xsl:param name="href" as="xs:anyURI"/>
        <xsl:param name="method" as="xs:string"/>
        <xsl:param name="media-type" as="xs:string?"/>
        <xsl:param name="body" as="item()?"/>
        <xsl:param name="headers" as="map(xs:string, xs:string)"/>
        
        <xsl:message use-when="system-property('xsl:product-name') = 'SAXON'" terminate="yes">
            Not implemented -- com.atomgraph.linkeddatahub.writer.function.SendHTTPRequest needs to be registered as an extension function
        </xsl:message>
    </xsl:function>
    
    <!-- SHARED FUNCTIONS -->

    <!-- TO-DO: move down to Web-Client -->
    <xsl:function name="ac:image" as="attribute()*">
        <xsl:param name="resource" as="element()"/>

        <xsl:variable name="images" as="attribute()*">
            <xsl:apply-templates select="$resource" mode="ac:image"/>
        </xsl:variable>
        <xsl:sequence select="$images"/>
    </xsl:function>
    
    <!-- override makes $property-metadata lookup take precedence over Linked Data -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:property-label">
        <xsl:param name="property-metadata" as="document-node()?"/>
        <xsl:variable name="this" select="concat(namespace-uri(), local-name())"/>
        
        <xsl:choose>
            <xsl:when test="key('resources', $this)">
                <xsl:apply-templates select="key('resources', $this)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="$property-metadata/key('resources', $this, .)">
                <xsl:apply-templates select="$property-metadata/key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="ixsl:doc-fetched(ac:document-uri(namespace-uri())) and key('resources', $this, document(ac:document-uri(namespace-uri())))" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
                <xsl:apply-templates select="key('resources', $this, document(ac:document-uri(namespace-uri())))" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="doc-available(ac:document-uri(namespace-uri())) and key('resources', $this, document(ac:document-uri(namespace-uri())))" use-when="system-property('xsl:product-name') = 'SAXON'">
                <xsl:apply-templates select="key('resources', $this, document(ac:document-uri(namespace-uri())))" mode="ac:label"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local-name()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- SET DOCUMENT URI -->
    
    <!-- resource has to have properties other than rdf:type -->
    <xsl:template match="rdf:Description[@rdf:nodeID][* except rdf:type]" mode="ldh:SetResourceID" priority="1">
        <xsl:param name="forClass" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="about" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="nodeID" as="xs:string?" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="rdf:type/@rdf:resource = $forClass">
                    <xsl:choose>
                        <xsl:when test="$about">
                            <xsl:attribute name="rdf:about" select="$about"/> <!-- suppress @rdf:nodeID -->
                        </xsl:when>
                        <xsl:when test="$nodeID">
                            <xsl:attribute name="rdf:nodeID" select="$nodeID"/>
                        </xsl:when>
                    </xsl:choose>

                    <xsl:apply-templates select="node()" mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:SetResourceID">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- SET PRIMARY TOPIC -->

    <xsl:template match="rdf:Description[@rdf:nodeID]" mode="ldh:SetPrimaryTopic" priority="1">
        <xsl:param name="doc-uri" as="xs:string" tunnel="yes"/>

        <!-- suppress the old foaf:primaryTopic object resource which is not used anymore -->
        <!-- check if the bnode ID of this resource equals the foaf:primaryTopic/@rdf:nodeID of the document instance -->
        <xsl:if test="not(@rdf:nodeID = key('resources', $doc-uri)/foaf:primaryTopic/@rdf:nodeID)">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <!-- link document instance to the topic instance using foaf:primaryTopic -->
    <xsl:template match="rdf:Description/foaf:primaryTopic[@rdf:nodeID]" mode="ldh:SetPrimaryTopic" priority="1">
        <xsl:param name="topic-id" as="xs:string?" tunnel="yes"/>
        <xsl:param name="doc-uri" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:choose>
                <!-- check subject URI of this resource -->
                <xsl:when test="$topic-id and ../@rdf:about = $doc-uri">
                    <!-- overwrite existing value with $topic-id -->
                    <xsl:attribute name="rdf:nodeID" select="$topic-id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:SetPrimaryTopic">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- RDFa overrides -->

    <xsl:template match="@rdf:resource" mode="xhtml:DefinitionDescription">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd property="{$property-uri}" resource="{.}">
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>

    <xsl:template match="@rdf:nodeID" mode="xhtml:DefinitionDescription">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd property="{$property-uri}" resource="_:{.}">
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>

    <xsl:template match="text()[../@xml:lang]" mode="xhtml:DefinitionDescription">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <!-- the value declares its own language rather than inheriting the document's. A property renders every language it
             carries, so the two sit side by side and the document default is wrong for at least one of them: without @lang a
             screen reader reads "Square" with Lithuanian phonetics on an lt page, and "Aikštė" with an English voice on an en
             one. This is WCAG 3.1.2, and it also makes the RDFa faithful - the extracted literal keeps its language tag -->
        <dd property="{$property-uri}" lang="{../@xml:lang}">
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <xsl:apply-templates select="."/>

            <xsl:apply-templates select="../@xml:lang" mode="ac:lang-tag"/>
        </dd>
    </xsl:template>

    <!-- the property list and the table cell both put a value's languages side by side, so the pill that tells them apart
         is written once here and applied from wherever the values are laid out -->
    <xsl:template match="@xml:lang" mode="ac:lang-tag">
        <span class="chip-inline">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <xsl:template match="node()" mode="xhtml:DefinitionDescription">
        <xsl:param name="diff-added-keys" as="xs:string*" tunnel="yes"/>
        <xsl:param name="diff-removed-keys" as="xs:string*" tunnel="yes"/>
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="diff-class" select="ldh:value-diff-class(.., $diff-added-keys, $diff-removed-keys)" as="xs:string?"/>

        <dd property="{$property-uri}">
            <xsl:if test="$diff-class">
                <xsl:attribute name="class" select="$diff-class"/>
            </xsl:if>

            <!-- an untagged literal makes no language claim, so it must not inherit the document's: lang="" is HTML's
                 "unknown", the exact counterpart of RDF's absent tag. Only plain strings get it - a number or a date is not
                 prose, and you do want those read out in the reader's language, so they inherit. XHTML literals are skipped
                 too: they are markup and carry their own lang where it matters -->
            <xsl:if test="self::text() and (not(../@rdf:datatype) or ../@rdf:datatype = '&xsd;string')">
                <xsl:attribute name="lang" select="''"/>
            </xsl:if>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>

    <!-- version-diff status of a single property value -->
    <xsl:function name="ldh:value-diff-class" as="xs:string?">
        <xsl:param name="property" as="element()"/>
        <xsl:param name="added-keys" as="xs:string*"/>
        <xsl:param name="removed-keys" as="xs:string*"/>

        <!-- non-diff renders pass empty key sets - skip the key serialization entirely -->
        <xsl:if test="exists(($added-keys, $removed-keys))">
            <xsl:variable name="triple-key" select="ldh:triple-key($property, false())" as="xs:string"/>
            <xsl:sequence select="if ($triple-key = $added-keys) then 'diff-added' else if ($triple-key = $removed-keys) then 'diff-removed' else ()"/>
        </xsl:if>
    </xsl:function>
    
    <!-- reduces an RDF literal's datatype to the XSD type that processing keys off: the derived types collapse onto the primitive
         that carries their ordering and value space, so consumers switch on a handful of families instead of enumerating XSD.
         'string' is the fallback for datatypes with no ordering of their own - xs:string and its subtypes, xs:anyURI, the binaries,
         the gregorians, QNames - and for untyped values, which are plain literals and therefore strings under RDF 1.1. -->

    <xsl:function name="ldh:datatype-family" as="xs:string">
        <xsl:param name="datatype" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="$datatype = ('&xsd;integer', '&xsd;long', '&xsd;int', '&xsd;short', '&xsd;byte', '&xsd;nonNegativeInteger', '&xsd;positiveInteger', '&xsd;nonPositiveInteger', '&xsd;negativeInteger', '&xsd;unsignedLong', '&xsd;unsignedInt', '&xsd;unsignedShort', '&xsd;unsignedByte')">integer</xsl:when>
            <xsl:when test="$datatype = '&xsd;decimal'">decimal</xsl:when>
            <xsl:when test="$datatype = ('&xsd;double', '&xsd;float')">double</xsl:when>
            <xsl:when test="$datatype = ('&xsd;dateTime', '&xsd;dateTimeStamp')">dateTime</xsl:when>
            <xsl:when test="$datatype = '&xsd;date'">date</xsl:when>
            <xsl:when test="$datatype = '&xsd;time'">time</xsl:when>
            <xsl:when test="$datatype = '&xsd;yearMonthDuration'">yearMonthDuration</xsl:when>
            <xsl:when test="$datatype = '&xsd;dayTimeDuration'">dayTimeDuration</xsl:when>
            <xsl:when test="$datatype = '&xsd;duration'">duration</xsl:when>
            <xsl:when test="$datatype = '&xsd;boolean'">boolean</xsl:when>
            <xsl:otherwise>string</xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- the xs:dateTime value of a date or dateTime literal, or () when it is neither, so the two granularities can be compared
         against each other - xs:date and xs:dateTime are not mutually comparable, and a timestamp property carries either.
         Casting through xs:date rather than appending 'T00:00:00' to the lexical form is what makes a zoned date work: the
         concatenation puts the timezone before the time part, and the result is not a valid xs:dateTime. -->

    <xsl:function name="ldh:date-time" as="xs:dateTime?">
        <xsl:param name="value" as="xs:string?"/>

        <xsl:sequence select="if ($value castable as xs:dateTime) then xs:dateTime($value) else if ($value castable as xs:date) then xs:dateTime(xs:date($value)) else ()"/>
    </xsl:function>

    <!-- DEFAULT -->

    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="concat(namespace-uri(), local-name())" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>

        <span>
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$title">
                <xsl:attribute name="title" select="$title"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <!-- the predicate label declares the language it was negotiated into, the same as a value does. Without it the
                 label inherits the document language, which is the language the page is composed in and not necessarily the
                 one the ontology had: a Lithuanian reader gets Lithuanian predicates inside a document whose chrome, and so
                 whose lang, is English. Resolved through the mode rather than ac:property-label() because the function is
                 declared as xs:string? and drops the winning literal's tag at its own boundary -->
            <xsl:variable name="label" as="item()*">
                <xsl:apply-templates select="." mode="ac:property-label">
                    <xsl:with-param name="property-metadata" select="$property-metadata"/>
                </xsl:apply-templates>
            </xsl:variable>
            <!-- item()*, not node()*: the fallback branches of ac:property-label return computed strings rather than the
                 label node - substring-after($this, '#') for a predicate the ontology does not describe - and binding an
                 atomic value to node()* is XTTE0570 at run time, which compiles clean and fails on a real page -->
            <xsl:variable name="label-node" select="$label[1][. instance of node()]" as="node()?"/>
            <xsl:if test="$label-node/../@xml:lang">
                <xsl:attribute name="lang" select="$label-node/../@xml:lang"/>
            </xsl:if>

            <xsl:choose>
                <xsl:when test="$property-metadata">
                    <xsl:sequence select="ac:property-label(., $property-metadata)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ac:property-label(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>
    
    <!-- ANCHOR -->
    
    <!-- subject resource -->
    <xsl:template match="@rdf:about" mode="xhtml:Anchor">
<!--        <xsl:param name="graph" as="xs:anyURI?" tunnel="yes"/>-->
        <xsl:param name="fragment" select="ac:fragment-id(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri(xs:anyURI(.)), map{}, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class || (if (not(starts-with(., ldt:base()))) then ' external' else())"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="@rdf:about | @rdf:resource" mode="svg:Anchor">
        <xsl:param name="fragment" select="ac:fragment-id(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri(xs:anyURI(.)), map{}, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" select="$fragment" as="xs:string?"/>
        <xsl:param name="label" select="if (parent::rdf:Description) then ac:svg-label(..) else ac:svg-object-label(.)" as="xs:string"/>
        <xsl:param name="title" select="$label" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="label" select="$label"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class || (if (not(starts-with(., ldt:base()))) then ' external' else())"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- DEFAULT -->

    <!-- proxy link URIs if they are external -->
    <xsl:template match="@rdf:resource | srx:uri" priority="2">
        <xsl:param name="fragment" select="ac:fragment-id(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href(ac:document-uri(xs:anyURI(.)), map{}, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>
        
        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class || (if (not(starts-with(., ldt:base()))) then ' external' else())"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- LOOKUP -->
    
    <xsl:template name="bs2:Lookup">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="value" as="xs:string?"/>
        <xsl:param name="list-class" select="'resource-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="list-id" select="concat('ul-', $id)" as="xs:string"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <div class="ldhc-combobox sz-sm is-iri">
            <!-- data-for-class sits on the box, the input's parent, where the lookup handlers read it -->
            <div class="ldhc-cb-box">
                <xsl:if test="exists($forClass)">
                    <xsl:attribute name="data-for-class" select="string-join($forClass, ' ')"/>
                </xsl:if>

                <span class="msi outline sm" aria-hidden="true">search</span>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="value" select="$value"/>
                    <xsl:with-param name="autocomplete" select="false()"/>
                </xsl:call-template>
            </div>

            <div class="ldhc-cb-panel {$list-class}" id="{$list-id}" role="listbox" style="display: none;"></div>
        </div>
    </xsl:template>

    <!-- TYPE -->
    
    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:TypeControl"/>

    <!-- object -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@*" mode="bs2:TypeControl"/>

    <!-- FORM CONTROL -->
    
    <!-- Container/Item subject input: slug-style UI (base URI + editable slug + trailing /). Matches both @rdf:nodeID (initial SPIN-constructed creation: resource is a blank node) and @rdf:about (constraint-violation re-render: response body carries the submitted URI). Same body works for both because $action carries the resource URL in either case. -->
    <xsl:template match="*[rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')]/@rdf:about | *[rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')]/@rdf:nodeID" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'slug subject-slug'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="action" tunnel="yes"/>
        <!-- cut slug segment from form action URL -->
        <xsl:param name="slug" select="substring-before(substring-after($action, ac:absolute-path(ldh:base-uri(.))), '/')" as="xs:string"/>
        <xsl:param name="tools" as="element()*"/>

        <div class="ldh-subject">
            <xsl:if test="$type = 'hidden'">
                <xsl:attribute name="style" select="'display: none'"/>
            </xsl:if>

            <!-- document hierarchy locks the term type to URI; the disabled select keeps the subject-type slot the type-flip handler expects -->
            <span class="ldhc-select-locked sz-sm">
                <span class="msi outline sm" aria-hidden="true">lock</span>
                <span class="lk-val">URI</span>
                <select class="subject-type" disabled="disabled" tabindex="-1">
                    <option value="su" selected="selected">URI</option>
                </select>
            </span>

            <label class="uri-field create">
                <input type="hidden" name="su" value="{$action}"/>
                <span class="msi outline sm" aria-hidden="true">folder</span>
                <span class="parent">
                    <xsl:value-of select="ac:absolute-path(ldh:base-uri(.))"/>
                </span>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="type" select="'text'"/>
                    <!-- <xsl:with-param name="id" select="$id"/> -->
                    <xsl:with-param name="value" select="$slug"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:call-template>
                <span class="trail">/</span>
            </label>

            <div class="ldh-subject-tools">
                <xsl:sequence select="$tools"/>
            </div>
        </div>
    </xsl:template>
    
    <!-- resource -->
    <xsl:template match="*[*]/@rdf:about | *[*]/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="document-uri" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="about" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#id' || ac:uuid())" as="xs:anyURI?"/>
        <xsl:param name="tools" as="element()*"/>

        <div class="ldh-subject">
            <xsl:if test="$type = 'hidden'">
                <xsl:attribute name="style" select="'display: none'"/>
            </xsl:if>

            <input type="hidden" class="old subject-type" value="{if (local-name() = 'about') then 'su' else if (local-name() = 'nodeID') then 'sb' else ()}"/>
            <select class="term-select subject-type">
                <option value="su">
                    <xsl:if test="local-name() = 'about'">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    <xsl:text>URI</xsl:text>
                </option>
                <option value="sb">
                    <xsl:if test="local-name() = 'nodeID'">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    <xsl:text>Blank node</xsl:text>
                </option>
            </select>

            <label class="uri-field">
                <span class="msi outline sm" aria-hidden="true">link</span>
                <!-- hidden inputs in which we store the old values of the visible input -->
                <input type="hidden" class="old su">
                    <xsl:attribute name="value" select="if (local-name() = 'about') then . else $about"/>
                </input>
                <input type="hidden" class="old sb">
                    <xsl:attribute name="value" select="if (local-name() = 'nodeID') then . else generate-id()"/>
                </input>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'text'"/>
                    <!-- <xsl:with-param name="id" select="$id"/> -->
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </label>

            <div class="ldh-subject-tools">
                <xsl:sequence select="$tools"/>
            </div>
        </div>
    </xsl:template>

    <!-- turn off default form controls for rdf:type as we are handling it specially with bs2:TypeControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:FormControl" priority="1"/>

    <!-- translations.rdf key for a violation without an authored message, chosen by what the violation carries -->
    <xsl:function name="ldh:violation-key" as="xs:string">
        <xsl:param name="violation" as="element()"/>

        <xsl:sequence select="if ($violation/spin:violationValue) then 'violation-invalid-value' else 'violation-constraint'"/>
    </xsl:function>

    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:FormControl">
        <xsl:param name="this" select="xs:anyURI(concat(namespace-uri(), local-name()))" as="xs:anyURI"/>
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="error" select="@rdf:resource = $violations/ldh:violationValue or $violations/spin:violationPath/@rdf:resource = $this or $violations/sh:resultPath/@rdf:resource = $this" as="xs:boolean"/>
        <xsl:param name="property-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="label" as="xs:string?">
            <xsl:sequence select="if ($property-metadata) then ac:property-label(., $property-metadata) else ac:property-label(.)"/> <!-- function upper-cases first letter, unlike mode="ac:label" -->
        </xsl:param>
        <xsl:param name="description" as="xs:string?">
            <xsl:for-each select="$property-metadata/key('resources', $this)">
                <xsl:sequence select="ac:description(.)"/> <!-- use function instead of mode="ac:description" as there might be multiple descriptions -->
            </xsl:for-each>
        </xsl:param>
        <xsl:param name="show-label" select="true()" as="xs:boolean"/>
        <xsl:param name="constructor" as="document-node()?"/>
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="cloneable" select="false()" as="xs:boolean"/>
        <xsl:param name="type-constraints" as="element()*"/>
        <xsl:param name="type-shapes" as="element()*"/>
        <!-- only the first property that has a mandatory constraint is required, the following ones are not -->
        <xsl:param name="required" select="($type-shapes[sh:path/@rdf:resource = $this][sh:minCount &gt;= count(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this])]) or ($type-constraints//srx:binding[@name = 'property'][srx:uri = $this] and not(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this]))" as="xs:boolean"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <!-- inline messages for this row's violations, except the missing-mandatory-property kind, where the .is-violation decoration already says everything. The kind is read off the violation's spin:violationSource description (included in the response by the exception mapper) resp. the SHACL constraint component -->
        <xsl:param name="row-violations" select="$violations[spin:violationPath/@rdf:resource = $this or sh:resultPath/@rdf:resource = $this or ldh:violationValue = current()/@rdf:resource][not(key('resources', (spin:violationSource/@rdf:resource, spin:violationSource/@rdf:nodeID))/rdf:type/@rdf:resource = '&ldh;MissingPropertyValue')][not(sh:sourceConstraintComponent/@rdf:resource = '&sh;MinCountConstraintComponent')]" as="element()*"/>
        <xsl:param name="class" select="concat('ldh-prop-group', if ($error or exists($row-violations)) then ' is-violation' else (), if ($required) then ' required' else ())" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Input">
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:apply-templates>
            <xsl:if test="$show-label">
                <div class="label">
                    <span class="lbl-row">
                        <span class="pred" title="{$this}">
                            <xsl:sequence select="$label"/>
                        </span>

                        <xsl:if test="$required">
                            <span class="ldhc-label-aux req">
                                <xsl:attribute name="title">
                                    <xsl:apply-templates select="key('resources', 'required', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:attribute>
                                <xsl:text>*</xsl:text>
                                <span class="ldhc-vh">
                                    <xsl:apply-templates select="key('resources', 'required', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </span>
                            </span>
                        </xsl:if>

                        <xsl:if test="$description">
                            <span class="ldhc-tip-anchor">
                                <button type="button" class="ldhc-toggletip-btn" aria-expanded="false" aria-label="{$label}">
                                    <span class="msi outline sm" aria-hidden="true">info</span>
                                </button>
                                <span class="ldhc-tip sd-bottom va-neutral description" role="status" style="max-width: 260px; display: none">
                                    <xsl:sequence select="$description"/>
                                    <span class="ldhc-tip-tip"></span>
                                </span>
                            </span>
                        </xsl:if>
                    </span>
                </div>
            </xsl:if>

            <div class="ldh-prop-row is-interactive is-last{if ($error or exists($row-violations)) then ' is-violation' else ()}">
                <div class="value val-stack">
                    <div class="val-main">
                        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"> <!-- not @rdf:* because that would apply to @rdf:parseType -->
                            <xsl:with-param name="id" select="$for"/>
                            <xsl:with-param name="required" select="$required"/>
                            <xsl:with-param name="constructor" select="$constructor"/>
                        </xsl:apply-templates>

                        <xsl:if test="@xml:lang or @rdf:datatype">
                            <div class="ldh-annot">
                                <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current"/>
                            </div>
                        </xsl:if>
                    </div>

                    <!-- authored labels/messages render verbatim; unlabeled violations fall back to a localized generic keyed by ldh:violation-key() -->
                    <xsl:if test="exists($row-violations)">
                        <div class="ldh-vmsgs">
                            <xsl:for-each select="$row-violations">
                                <span class="ldhc-help va-negative sz-sm" role="alert">
                                    <span class="msi outline sm" aria-hidden="true">error</span>
                                    <span>
                                        <xsl:choose>
                                            <xsl:when test="sh:resultMessage">
                                                <xsl:value-of select="sh:resultMessage[1]"/>
                                            </xsl:when>
                                            <xsl:when test="rdfs:label">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="." mode="ac:label"/>
                                                </xsl:value-of>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', ldh:violation-key(.), document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </span>
                                </span>
                            </xsl:for-each>
                        </div>
                    </xsl:if>
                </div>

                <div class="row-actions">
                    <xsl:if test="$cloneable">
                        <button type="button" class="ldhc-iconbtn sz-xs in-accent ap-ghost btn-add">
                            <xsl:attribute name="title">
                                <xsl:apply-templates select="key('resources', 'add-stmt', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">add</span>
                        </button>
                    </xsl:if>

                    <xsl:if test="not($required)">
                        <button type="button" tabindex="-1" class="ldhc-iconbtn sz-xs in-destructive ap-ghost btn-remove-property">
                            <xsl:attribute name="title">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'remove-stmt', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:attribute>

                            <span class="msi sm" aria-hidden="true">remove</span>
                        </button>
                    </xsl:if>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- object resource -->
    <xsl:template match="@rdf:resource" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="constructor" as="document-node()?"/>
        <xsl:param name="object-metadata" as="document-node()?" tunnel="yes"/>
        <xsl:param name="forClass" select="if ($constructor) then distinct-values(key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $constructor)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $constructor)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')]) else ()" as="xs:anyURI*"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- object resource exists in the current document -->
            <xsl:when test="key('resources', .)">
                <xsl:apply-templates select="key('resources', .)" mode="ldh:Typeahead">
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:apply-templates>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
            <xsl:when test="exists($object-metadata)">
                <xsl:choose>
                    <xsl:when test="key('resources', ., $object-metadata)">
                        <xsl:apply-templates select="key('resources', ., $object-metadata)" mode="ldh:Typeahead">
                            <xsl:with-param name="forClass" select="$forClass"/>
                        </xsl:apply-templates>

                        <xsl:if test="$type-label">
                            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="forClass" select="$forClass"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="bs2:Lookup">
                            <xsl:with-param name="value" select="."/>
                            <xsl:with-param name="forClass" select="$forClass"/>
                        </xsl:call-template>

                        <xsl:if test="$type-label">
                            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                                <xsl:with-param name="type" select="$type"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="value" select="."/>
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:call-template>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                        <xsl:with-param name="type" select="$type"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@rdf:resource" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <xsl:if test="not($type = 'hidden')">
            <div class="ldh-annot">
                <xsl:choose>
                    <xsl:when test="exists($forClass)">
                        <span class="ldhc-tag sz-sm em-quiet an-term is-resource">
                            <xsl:for-each select="$forClass">
                                <!-- SAXON checks the catalog; SaxonJS only inspects the documentPool to avoid cross-origin fetches that would trigger mixed-content for slash-vocab term URIs (e.g. foaf) -->
                                <xsl:variable name="doc-loaded" select="doc-available(ac:document-uri(.))" as="xs:boolean" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:variable name="doc-loaded" select="ixsl:doc-fetched(ac:document-uri(.))" as="xs:boolean" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>
                                <xsl:choose>
                                    <xsl:when test="$doc-loaded and key('resources', ., document(ac:document-uri(.)))">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="."/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="ldhc-tag sz-sm em-quiet an-term is-resource">
                            <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- object blank node -->
    <xsl:template match="*[@rdf:about]/*/@rdf:nodeID | *[@rdf:nodeID]/*/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="constructor" as="document-node()?"/>
        <xsl:variable name="resource" select="key('resources', .)"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$inline and $resource and not(. = $traversed-ids)">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>

                <xsl:apply-templates select="$resource" mode="#current">
                    <xsl:with-param name="traversed-ids" select="(., $traversed-ids)" tunnel="yes"/>
                </xsl:apply-templates>

                <!-- restore subject context -->
                <xsl:apply-templates select="../../@rdf:about | ../../@rdf:nodeID" mode="#current">
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$resource">
                <xsl:variable name="forClass" select="if ($constructor) then distinct-values(key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $constructor)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $constructor)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')]) else ()" as="xs:anyURI*"/>
                <xsl:apply-templates select="$resource" mode="ldh:Typeahead">
                    <xsl:with-param name="forClass" select="$forClass"/>
                </xsl:apply-templates>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="forClass" select="$forClass"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>

                <xsl:if test="$type-label">
                    <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                        <xsl:with-param name="type" select="$type"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- @rdf:datatype (hidden) -->
    <xsl:template match="@rdf:datatype" mode="bs2:FormControl">
        <xsl:param name="type" select="'hidden'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>

        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- blank nodes that only have rdf:type xsd:* and no other properties become literal inputs -->
    <!-- TO-DO: expand pattern to handle other XSD datatypes -->
    <!-- TO-DO: move to Web-Client -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[starts-with(@rdf:resource, '&xsd;')])]]" mode="bs2:FormControl" priority="2">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:call-template>
        
        <!-- datatype -->
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="key('resources', .)/rdf:type/@rdf:resource"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:variable name="datatype" as="document-node()">
                <xsl:document>
                    <rdf:Description>
                        <xsl:element name="{../name()}" namespace="{../namespace-uri()}">
                            <xsl:attribute name="rdf:datatype" select="key('resources', .)/rdf:type/@rdf:resource"/>
                        </xsl:element>
                    </rdf:Description>
                </xsl:document>
            </xsl:variable>
            
            <xsl:apply-templates select="$datatype//@rdf:datatype">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <!-- special case for owl:NamedIndividual bnode instances which become typeaheads -->
    <xsl:template match="*[@rdf:nodeID]/*/@rdf:nodeID[key('resources', .)/rdf:type/@rdf:resource = '&owl;NamedIndividual']" mode="bs2:FormControl" priority="2">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI"/>

        <xsl:apply-templates select="key('resources', .)" mode="ldh:Typeahead">
            <xsl:with-param name="forClass" select="$forClass"/>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="forClass" select="$forClass"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- blank nodes that only have non-XSD rdf:type and no other properties become resource lookups -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[not(starts-with(@rdf:resource, '&xsd;'))])]]" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI*"/>

        <xsl:call-template name="bs2:Lookup">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="forClass" select="$forClass"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="forClass" select="$forClass"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <!-- RDFa editor for XMLLiteral objects -->

    <xsl:template match="*[@rdf:parseType = 'Literal']/xhtml:*" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="type" select="'textarea'" as="xs:string?"/> <!-- 'textarea' is not a valid <input> type -->
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <div class="rdfa-editor-content">
            <xsl:copy-of select="node()" copy-namespaces="no"/>
        </div>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="'&rdf;XMLLiteral'"/>
        </xsl:call-template>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <!-- FORM CONTROL TYPE LABEL -->

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[not(starts-with(@rdf:resource, '&xsd;'))])]]" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <xsl:if test="not($type = 'hidden')">
            <div class="ldh-annot">
                <xsl:choose>
                    <xsl:when test="exists($forClass)">
                        <span class="ldhc-tag sz-sm em-quiet an-term is-blank">
                            <xsl:for-each select="$forClass">
                                <!-- SAXON checks the catalog; SaxonJS only inspects the documentPool to avoid cross-origin fetches that would trigger mixed-content for slash-vocab term URIs -->
                                <xsl:variable name="doc-loaded" select="doc-available(ac:document-uri(.))" as="xs:boolean" use-when="system-property('xsl:product-name') = 'SAXON'"/>
                                <xsl:variable name="doc-loaded" select="ixsl:doc-fetched(ac:document-uri(.))" as="xs:boolean" use-when="system-property('xsl:product-name') eq 'SaxonJS'"/>
                                <xsl:choose>
                                    <xsl:when test="$doc-loaded">
                                        <xsl:choose>
                                            <xsl:when test=". = '&rdfs;Resource'">
                                                <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                                            </xsl:when>
                                            <xsl:when test="key('resources', ., document(ac:document-uri(.)))">
                                                <xsl:value-of>
                                                    <xsl:apply-templates select="key('resources', ., document(ac:document-uri(.)))" mode="ac:label"/>
                                                </xsl:value-of>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="."/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="ldhc-tag sz-sm em-quiet an-term is-blank">
                            <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- literal term-kind / datatype / language annotations (shadow the Web-Client help-inline emitters) -->

    <xsl:template match="text()" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:choose>
                <xsl:when test="../@rdf:datatype">
                    <xsl:apply-templates select="../@rdf:datatype" mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <div class="ldh-annot">
                        <span class="ldhc-tag sz-sm em-quiet an-term is-literal">
                            <xsl:apply-templates select="key('resources', 'literal', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
                        </span>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template match="@rdf:datatype" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <div class="ldh-annot">
                <span class="ldhc-tag sz-sm em-quiet co-neutral" title="{.}">
                    <xsl:value-of select="if (starts-with(., '&xsd;')) then 'xsd:' || substring-after(., '&xsd;') else ."/>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- language-tagged literal: BCP 47 input in the annotation slot -->
    <xsl:template match="@xml:lang" mode="bs2:FormControl">
        <span class="ldh-lang">
            <xsl:attribute name="title">
                <xsl:apply-templates select="key('resources', 'language-tag', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $lapp:origin)))" mode="ac:label"/>
            </xsl:attribute>

            <span class="msi" aria-hidden="true">language</span>
            <xsl:apply-templates select="." mode="xhtml:Input">
                <xsl:with-param name="type" select="'text'"/>
            </xsl:apply-templates>
        </span>
    </xsl:template>
    
    <!-- real numbers -->
    
    <xsl:template match="text()[../@rdf:datatype = '&xsd;float'] | text()[../@rdf:datatype = '&xsd;double']" mode="xhtml:Input" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ol'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="value" select="format-number(., '#####.00000')"/>
        </xsl:call-template>
        
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="../@rdf:datatype"/>
        </xsl:call-template>
    </xsl:template>

    <!-- datetimes -->
    
    <xsl:template match="text()[../@rdf:datatype = '&xsd;dateTime'][. castable as xs:dateTime][../@rdf:datatype = '&xsd;dateTime']" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'datetime-local'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:apply-templates>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="text()[../@rdf:datatype = '&xsd;dateTime'][. castable as xs:dateTime][../@rdf:datatype = '&xsd;dateTime']" mode="xhtml:Input" priority="1">
        <xsl:param name="type" select="'datetime-local'" as="xs:string"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$type = 'datetime-local'"> <!-- could also be 'hidden' -->
                <span class="ldh-dt-pair">
                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="name" select="'ol'"/>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="class" select="$class"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="value" select="format-dateTime(xs:dateTime(.), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')"/>
                    </xsl:call-template>

                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="type" select="'hidden'"/>
                        <xsl:with-param name="name" select="'lt'"/>
                        <xsl:with-param name="value" select="../@rdf:datatype"/>
                    </xsl:call-template>

                    <xsl:call-template name="xhtml:Input">
                        <xsl:with-param name="class" select="'dt-tz input-timezone'"/>
                        <xsl:with-param name="type" select="'text'"/>
                        <xsl:with-param name="value" select="format-dateTime(xs:dateTime(.), '[Z]')"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:next-match>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- booleans -->

    <xsl:template match="text()[../@rdf:datatype = '&xsd;boolean']" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="value" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <span class="ldhc-select sz-sm">
                <select name="ol">
                    <xsl:if test="$id"><xsl:attribute name="id" select="$id"/></xsl:if>
                    <xsl:if test="$class"><xsl:attribute name="class" select="$class"/></xsl:if>
                    <xsl:if test="$disabled"><xsl:attribute name="disabled" select="'disabled'"/></xsl:if>
                    <option value="true">
                        <xsl:if test=". = 'true'"><xsl:attribute name="selected" select="'selected'"/></xsl:if>
                        <xsl:text>true</xsl:text>
                    </option>
                    <option value="false">
                        <xsl:if test=". = 'false'"><xsl:attribute name="selected" select="'selected'"/></xsl:if>
                        <xsl:text>false</xsl:text>
                    </option>
                </select>
                <span class="msi sm ldhc-select-caret" aria-hidden="true">unfold_more</span>
                </span>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="../@rdf:datatype"/>
        </xsl:call-template>

        <xsl:if test="$type-label and not($type = 'hidden')">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- boolean placeholder via constructor's blank-node form: property → bnode whose only child is rdf:type xsd:boolean -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;boolean'])]]" mode="bs2:FormControl" priority="3">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ol'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                    <xsl:with-param name="id" select="$id"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <span class="ldhc-select sz-sm">
                <select name="ol">
                    <xsl:if test="$id"><xsl:attribute name="id" select="$id"/></xsl:if>
                    <xsl:if test="$class"><xsl:attribute name="class" select="$class"/></xsl:if>
                    <xsl:if test="$disabled"><xsl:attribute name="disabled" select="'disabled'"/></xsl:if>
                    <option value="true">true</option>
                    <option value="false">false</option>
                </select>
                <span class="msi sm ldhc-select-caret" aria-hidden="true">unfold_more</span>
                </span>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="value" select="key('resources', .)/rdf:type/@rdf:resource"/>
        </xsl:call-template>

        <xsl:if test="$type-label and not($type = 'hidden')">
            <xsl:variable name="datatype" as="document-node()">
                <xsl:document>
                    <rdf:Description>
                        <xsl:element name="{../name()}" namespace="{../namespace-uri()}">
                            <xsl:attribute name="rdf:datatype" select="key('resources', .)/rdf:type/@rdf:resource"/>
                        </xsl:element>
                    </rdf:Description>
                </xsl:document>
            </xsl:variable>

            <xsl:apply-templates select="$datatype//@rdf:datatype">
                <xsl:with-param name="type" select="$type"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- XHTML CONTENT IDENTITY TRANSFORM -->

    <xsl:template match="@* | node()" mode="ldh:XHTMLContent">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- resolve relative @href URIs against base in proxy mode -->
    <xsl:template match="@href[not(ac:absolute-path(ldh:base-uri(.)) = ac:absolute-path(ldh:request-uri()))][not(starts-with(., '/')) and not(starts-with(., '#')) and not(contains(., ':'))]" mode="ldh:XHTMLContent" priority="1">
        <xsl:attribute name="{name()}" select="resolve-uri(., ldh:base-uri(.))"/>
    </xsl:template>

    <!-- resolve relative @src URIs against base in proxy mode -->
    <xsl:template match="@src[not(ac:absolute-path(ldh:base-uri(.)) = ac:absolute-path(ldh:request-uri()))][not(starts-with(., '/')) and not(starts-with(., '#')) and not(contains(., ':'))]" mode="ldh:XHTMLContent" priority="1">
        <xsl:attribute name="{name()}" select="resolve-uri(., ldh:base-uri(.))"/>
    </xsl:template>

</xsl:stylesheet>
