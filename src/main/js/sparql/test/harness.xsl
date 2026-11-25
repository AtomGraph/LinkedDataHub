<?xml version="1.0" encoding="UTF-8"?>
<!-- Runs one rewrite of client/query-transforms.xsl over a query, as the client stylesheets call it: the query is
     Traqula's AST as JSON, the rewrite a mode or a function, and its parameters a JSON object, converted here to the
     types the mode declares. Returns the rewritten AST as JSON, or a function's result as JSON.
     harness.js copies this next to query-transforms.xsl, with its DTD entities expanded, and next to borrowed.xsl,
     which holds the functions it calls from imports/default.xsl, copied from that file as they are. -->
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
xmlns:t="urn:test"
exclude-result-prefixes="#all"
>

    <xsl:include href="query-transforms.xsl"/>
    <xsl:include href="borrowed.xsl"/>

    <xsl:output method="text"/>

    <xsl:param name="op" as="xs:string"/>
    <xsl:param name="query" as="xs:string"/>
    <xsl:param name="params" select="'{}'" as="xs:string"/>

    <xsl:variable name="q" select="json-to-xml($query)" as="document-node()"/>
    <xsl:variable name="p" select="parse-json($params)" as="map(*)"/>

    <!-- a VALUES cell: a string, or {"type": "anyURI" | "integer" | ..., "value": ...} for a typed one -->
    <xsl:function name="t:atomic" as="xs:anyAtomicType">
        <xsl:param name="cell" as="item()"/>

        <xsl:choose>
            <xsl:when test="not($cell instance of map(*))"><xsl:sequence select="$cell"/></xsl:when>
            <xsl:when test="$cell?type = 'anyURI'"><xsl:sequence select="xs:anyURI($cell?value)"/></xsl:when>
            <xsl:when test="$cell?type = 'integer'"><xsl:sequence select="xs:integer($cell?value)"/></xsl:when>
            <xsl:when test="$cell?type = 'boolean'"><xsl:sequence select="xs:boolean($cell?value)"/></xsl:when>
            <xsl:when test="$cell?type = 'date'"><xsl:sequence select="xs:date($cell?value)"/></xsl:when>
            <xsl:when test="$cell?type = 'dateTime'"><xsl:sequence select="xs:dateTime($cell?value)"/></xsl:when>
            <xsl:when test="$cell?type = 'double'"><xsl:sequence select="xs:double($cell?value)"/></xsl:when>
            <xsl:otherwise><xsl:sequence select="error(xs:QName('t:type'), 'unknown VALUES type: ' || $cell?type)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="t:json" as="xs:string">
        <xsl:param name="result" as="item()*"/>

        <xsl:sequence select="serialize(array { $result ! (if (. instance of element()) then parse-json(xml-to-json(.)) else .) }, map { 'method': 'json' })"/>
    </xsl:function>

    <xsl:template name="main">
        <xsl:choose>
            <xsl:when test="starts-with($op, 'fn:')">
                <xsl:value-of select="t:json(t:call(substring-after($op, 'fn:')))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="result" as="document-node()">
                    <xsl:document>
                        <xsl:call-template name="t:apply"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:value-of select="xml-to-json($result)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="t:call" as="item()*">
        <xsl:param name="name" as="xs:string"/>
        <xsl:variable name="query" select="$q/json:map" as="element(json:map)?"/>

        <xsl:choose>
            <xsl:when test="$name = 'first-var-name'"><xsl:sequence select="ldh:first-var-name($query)"/></xsl:when>
            <xsl:when test="$name = 'fresh-var-suffix'"><xsl:sequence select="ldh:fresh-var-suffix($query, array:flatten($p?stems))"/></xsl:when>
            <xsl:when test="$name = 'query-limit'"><xsl:sequence select="ldh:query-limit($query)"/></xsl:when>
            <xsl:when test="$name = 'query-offset'"><xsl:sequence select="ldh:query-offset($query)"/></xsl:when>
            <xsl:when test="$name = 'order-var-name'"><xsl:sequence select="ldh:order-var-name($query, xs:integer($p?pos))"/></xsl:when>
            <xsl:when test="$name = 'order-desc'"><xsl:sequence select="ldh:order-desc($query, xs:integer($p?pos))"/></xsl:when>
            <xsl:when test="$name = 'subject-var-triples'"><xsl:sequence select="ldh:subject-var-triples($query, $p?var-name)"/></xsl:when>
            <xsl:when test="$name = 'is-filter-in'"><xsl:sequence select="$query/json:map[@key = 'where']/json:array[@key = 'patterns']/json:map ! ldh:is-filter-in(., $p?var-name)"/></xsl:when>
            <xsl:when test="$name = 'term-node'"><xsl:sequence select="ldh:term-node($p?token)"/></xsl:when>
            <xsl:otherwise><xsl:sequence select="error(xs:QName('t:op'), 'unknown function: ' || $name)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="t:apply">
        <xsl:choose>
            <xsl:when test="$op = 'replace-variables'">
                <xsl:apply-templates select="$q" mode="ldh:replace-variables">
                    <xsl:with-param name="var-names" select="array:flatten($p?var-names)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'replace-limit'">
                <xsl:apply-templates select="$q" mode="ldh:replace-limit">
                    <xsl:with-param name="limit" select="$p?limit ! xs:integer(.)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'replace-offset'">
                <xsl:apply-templates select="$q" mode="ldh:replace-offset">
                    <xsl:with-param name="offset" select="$p?offset ! xs:integer(.)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'wrap-describe'">
                <xsl:apply-templates select="$q" mode="ldh:wrap-describe"/>
            </xsl:when>
            <xsl:when test="$op = 'strip-from'">
                <xsl:apply-templates select="$q" mode="ldh:strip-from"/>
            </xsl:when>
            <xsl:when test="$op = 'strip-order-by'">
                <xsl:apply-templates select="$q" mode="ldh:strip-order-by"/>
            </xsl:when>
            <xsl:when test="$op = 'link-predicates'">
                <xsl:apply-templates select="$q" mode="ldh:link-predicates"/>
            </xsl:when>
            <xsl:when test="$op = 'add-parallax-step'">
                <xsl:apply-templates select="$q" mode="ldh:add-parallax-step">
                    <xsl:with-param name="predicate" select="xs:anyURI($p?predicate)" tunnel="yes"/>
                    <xsl:with-param name="inverse" select="boolean($p?inverse)" tunnel="yes"/>
                    <xsl:with-param name="title-predicate" select="$p?title-predicate ! xs:anyURI(.)" tunnel="yes"/>
                    <xsl:with-param name="title-new-var-name" select="$p?title-new-var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'replace-order-by'">
                <xsl:apply-templates select="$q" mode="ldh:replace-order-by">
                    <xsl:with-param name="var-name" select="$p?var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'toggle-desc'">
                <xsl:apply-templates select="$q" mode="ldh:toggle-desc">
                    <xsl:with-param name="desc" select="$p?desc" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'bgp-value-counts'">
                <xsl:apply-templates select="$q" mode="ldh:bgp-value-counts">
                    <xsl:with-param name="bgp-triples-map" as="element()" tunnel="yes"><json:map/></xsl:with-param>
                    <xsl:with-param name="subject-var-name" select="$p?subject-var-name" tunnel="yes"/>
                    <xsl:with-param name="object-var-name" select="$p?object-var-name" tunnel="yes"/>
                    <xsl:with-param name="count-var-name" select="$p?count-var-name" tunnel="yes"/>
                    <xsl:with-param name="label-var-name" select="$p?label-var-name" tunnel="yes"/>
                    <xsl:with-param name="label-sample-var-name" select="$p?label-sample-var-name" tunnel="yes"/>
                    <xsl:with-param name="descending" select="($p?descending, true())[1]" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'filter-in'">
                <xsl:apply-templates select="$q" mode="ldh:filter-in">
                    <xsl:with-param name="var-name" select="$p?var-name" tunnel="yes"/>
                    <xsl:with-param name="values" select="$p?values" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'filter-contains'">
                <xsl:apply-templates select="$q" mode="ldh:filter-contains">
                    <xsl:with-param name="var-name" select="$p?var-name" tunnel="yes"/>
                    <xsl:with-param name="text" select="$p?text" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'wrap-subquery'">
                <xsl:apply-templates select="$q" mode="ldh:wrap-subquery"/>
            </xsl:when>
            <xsl:when test="$op = 'result-count'">
                <xsl:apply-templates select="$q" mode="ldh:result-count">
                    <xsl:with-param name="count-var-name" select="$p?count-var-name" tunnel="yes"/>
                    <xsl:with-param name="expression-var-name" select="$p?expression-var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'container-select'">
                <xsl:apply-templates select="$q" mode="ldh:container-select">
                    <xsl:with-param name="focus-var-name" select="$p?focus-var-name" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'add-constructor-triple'">
                <xsl:apply-templates select="$q" mode="ldh:add-constructor-triple">
                    <xsl:with-param name="subject" select="($p?subject, '?this')[1]" tunnel="yes"/>
                    <xsl:with-param name="predicate" select="xs:anyURI($p?predicate)" tunnel="yes"/>
                    <xsl:with-param name="object-type" select="xs:anyURI($p?object-type)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'add-regex-filter'">
                <xsl:apply-templates select="$q" mode="ldh:add-regex-filter">
                    <xsl:with-param name="var-name" select="$p?var-name" tunnel="yes"/>
                    <xsl:with-param name="pattern" select="$p?pattern" tunnel="yes"/>
                    <xsl:with-param name="flags" select="$p?flags" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'add-text-query'">
                <xsl:apply-templates select="$q" mode="ldh:add-text-query">
                    <xsl:with-param name="var-name" select="$p?var-name" tunnel="yes"/>
                    <xsl:with-param name="query" select="$p?query" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$op = 'append-values'">
                <xsl:apply-templates select="$q" mode="ldh:append-values">
                    <xsl:with-param name="values-map" select="array:flatten($p?rows) ! map:merge(map:for-each(., function ($key, $cell) { map { $key: t:atomic($cell) } }))" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(xs:QName('t:op'), 'unknown mode: ' || $op)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
