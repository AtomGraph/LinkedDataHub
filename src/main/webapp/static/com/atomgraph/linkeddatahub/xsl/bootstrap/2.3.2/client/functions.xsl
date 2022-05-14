<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
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
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'location.href'))"/>
    </xsl:function>

    <xsl:function name="ldt:base" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.base'))"/>
    </xsl:function>
    
    <xsl:function name="ac:uri" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.uri'))"/>
    </xsl:function>

    <xsl:function name="ac:mode" as="xs:anyURI*">
        <xsl:variable name="href" select="ldh:href()" as="xs:anyURI"/>
        <!-- decode mode URI from the ?mode query param, if it's present -->
        <xsl:sequence select="if (contains($href, '?')) then let $query-params := ldh:parse-query-params(substring-after($href, '?')) return ldh:decode-uri($query-params?mode) else ()"/> <!-- raw URL -->
    </xsl:function>

    <xsl:function name="sd:endpoint" as="xs:anyURI">
        <xsl:sequence select="xs:anyURI(ixsl:get(ixsl:window(), 'LinkedDataHub.endpoint'))"/>
    </xsl:function>
    
    <xsl:function name="ldh:parse-query-params" as="map(xs:string, xs:string*)">
        <xsl:param name="query-string" as="xs:string"/>

        <xsl:sequence select="map:merge(
            for $query in tokenize($query-string, '&amp;')
            return
                let $param := tokenize($query, '=')
                return map:entry(head($param), tail($param))
            ,
            map { 'duplicates': 'combine' }
        )"/>
    </xsl:function>

    <xsl:function name="ldh:decode-uri" as="xs:anyURI">
        <xsl:param name="encoded-uri" as="xs:string"/>

        <xsl:sequence select="xs:anyURI(ixsl:call(ixsl:window(), 'decodeURIComponent', [ $encoded-uri ]))"/>
    </xsl:function>

    <!-- finds the app with the longest matching base URI -->
    <xsl:function name="ldh:match-app" as="element()?">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="apps" as="document-node()"/>
        
        <xsl:sequence select="let $max-length := max($apps//rdf:Description[ldt:base/@rdf:resource[starts-with($uri, .)]]/string-length(ldt:base/@rdf:resource)) return ($apps//rdf:Description[ldt:base/@rdf:resource[starts-with($uri, .)]][string-length(ldt:base/@rdf:resource) eq $max-length])[1]"/>
    </xsl:function>
    
    <xsl:function name="ldh:query-type" as="xs:string">
        <xsl:param name="query-string" as="xs:string"/>
        
        <xsl:sequence select="analyze-string($query-string, '[^a-zA-Z]?(SELECT|ASK|DESCRIBE|CONSTRUCT)[^a-zA-Z]', 'i')/fn:match[1]/fn:group[@nr = '1']/string()"/>
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
    
    <xsl:function name="ac:build-describe" as="xs:string">
        <xsl:param name="select-string" as="xs:string"/> <!-- already with $this value set -->
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean"/>

        <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
        <!-- ignore ORDER BY variable name if it's not present in the query -->
        <xsl:variable name="order-by" select="if (ixsl:call($select-builder, 'isVariable', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', [ $order-by ]) ])) then $order-by else ()" as="xs:string?"/>
        <xsl:variable name="select-builder" select="ac:paginate($select-builder, $limit, $offset, $order-by, $desc)"/>
        <xsl:variable name="describe-builder" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'DescribeBuilder'), 'new', []), 'wherePattern', [ ixsl:call($select-builder, 'build', []) ])"/>
        <xsl:sequence select="ixsl:call($describe-builder, 'toString', [ ])"/>
    </xsl:function>
    
    <!-- accepts and returns SelectBuilder. Use ixsl:call(ac:paginate(...), 'toString', []) to get SPARQL string -->
    <xsl:function name="ac:paginate">
        <xsl:param name="select-builder"/> <!-- as SelectBuilder -->
        <xsl:param name="limit" as="xs:integer?"/>
        <xsl:param name="offset" as="xs:integer?"/>
        <xsl:param name="order-by" as="xs:string?"/>
        <xsl:param name="desc" as="xs:boolean?"/>

        <xsl:choose>
            <xsl:when test="$order-by and exists($desc)">
                <xsl:sequence select="ixsl:call(ixsl:call(ixsl:call($select-builder, 'limit', [ $limit ]), 'offset', [ $offset ]), 'orderBy', [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'ordering',  [ ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'var', [ $order-by ]), $desc ]) ])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:call($select-builder, 'limit', [ $limit ]), 'offset', [ $offset ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- format URLs in DataTable as HTML links -->
    <xsl:template match="@rdf:about[starts-with(., 'http://')] | @rdf:about[starts-with(., 'https://')] | @rdf:resource[starts-with(., 'http://')] | @rdf:resource[starts-with(., 'https://')] | srx:uri[starts-with(., 'http://')] | srx:uri[starts-with(., 'https://')]" mode="ac:DataTable">
        "&lt;a href=\"<xsl:value-of select="."/>\"&gt;<xsl:value-of select="."/>&lt;/a&gt;"
    </xsl:template>

    <!-- in addition to JSON escaping, escape < > in literals so they don't get interpreted as HTML tags -->
    <xsl:template match="srx:literal[@datatype = '&xsd;string' or not(@datatype)]" mode="ac:DataTable">
        "<xsl:value-of select="replace(replace(replace(replace(replace(replace(replace(replace(., '\\', '\\\\'), '&quot;', '\\&quot;'), '/', '\\/'), '&#xA;', '\\n'), '&#xD;', '\\r'), '&#x9;', '\\t'), '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>"
    </xsl:template>

    <!-- in addition to JSON escaping, escape < > in literals so they don't get interpreted as HTML tags -->
    <xsl:template match="rdf:Description/*/text()[../@rdf:datatype = '&xsd;string' or not(../@rdf:datatype)]" mode="ac:DataTable">
        "<xsl:value-of select="replace(replace(replace(replace(replace(replace(replace(replace(., '\\', '\\\\'), '&quot;', '\\&quot;'), '/', '\\/'), '&#xA;', '\\n'), '&#xD;', '\\r'), '&#x9;', '\\t'), '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>"
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
                            <xsl:with-param name="property-uris" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- if no $category specified, show resource URI/ID as category -->
                        <xsl:apply-templates select="$results" mode="ac:DataTable">
                            <xsl:with-param name="resource-ids" select="true()" tunnel="yes"/>
                            <xsl:with-param name="property-uris" select="xs:anyURI($category), for $i in $series return xs:anyURI($i)" tunnel="yes"/>
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
    
</xsl:stylesheet>