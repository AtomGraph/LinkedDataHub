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
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
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
    
    <xsl:function name="ldh:base-uri" as="xs:anyURI" use-when="system-property('xsl:product-name') = 'SAXON'">
        <xsl:param name="arg" as="node()"/>
        
        <xsl:sequence select="base-uri($arg)"/>
    </xsl:function>
    
    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="absolute-path" as="xs:anyURI"/>
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>

        <xsl:sequence select="ldh:href($base, $absolute-path, $query-params, ())"/>
    </xsl:function>
    
    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="absolute-path" as="xs:anyURI"/>
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        
        <xsl:sequence select="ldh:href($base, $absolute-path, $query-params, $uri, ())"/>
    </xsl:function>

    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="absolute-path" as="xs:anyURI"/>
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="fragment" as="xs:string?"/>

        <xsl:sequence select="ldh:href($base, $absolute-path, $query-params, $uri, (), $fragment)"/>
    </xsl:function>
    
    <xsl:function name="ldh:href" as="xs:anyURI">
        <xsl:param name="base" as="xs:anyURI"/>
        <xsl:param name="absolute-path" as="xs:anyURI"/>
        <xsl:param name="query-params" as="map(xs:string, xs:string*)"/>
        <xsl:param name="uri" as="xs:anyURI?"/>
        <xsl:param name="graph" as="xs:anyURI?"/>
        <xsl:param name="fragment" as="xs:string?"/>

        <xsl:choose>
            <!-- do not proxy $uri via ?uri= if it is relative to the $base -->
            <xsl:when test="$uri and starts-with($uri, $base)">
                <xsl:variable name="absolute-path" select="xs:anyURI(if (contains($uri, '#')) then substring-before($uri, '#') else $uri)" as="xs:anyURI"/>
                <xsl:variable name="fragment" select="if ($fragment) then $fragment else if (contains($uri, '#')) then substring-after($uri, '#') else ()" as="xs:string?"/>
                <xsl:sequence select="xs:anyURI(ac:build-uri($absolute-path, $query-params) || (if ($fragment) then ('#' || $fragment) else ()))"/>
            </xsl:when>
            <!-- proxy external URI/graph -->
            <xsl:when test="$uri and $graph">
                <xsl:variable name="fragment" select="if ($fragment) then $fragment else encode-for-uri($uri)" as="xs:string?"/>
                <xsl:sequence select="xs:anyURI(ac:build-uri($absolute-path, map:merge((map{ 'uri': string($uri), 'graph': string($graph) }, $query-params))) || (if ($fragment) then ('#' || $fragment) else ()))"/>
            </xsl:when>
            <!-- proxy external URI -->
            <xsl:when test="$uri">
                <xsl:variable name="fragment" select="if ($fragment) then $fragment else encode-for-uri($uri)" as="xs:string?"/>
                <xsl:sequence select="xs:anyURI(ac:build-uri($absolute-path, map:merge((map{ 'uri': string($uri) }, $query-params))) || (if ($fragment) then ('#' || $fragment) else ()))"/>
            </xsl:when>
            <!-- no URI supplied -->
            <xsl:otherwise>
                <xsl:sequence select="xs:anyURI(ac:build-uri($absolute-path, $query-params) || (if ($fragment) then ('#' || $fragment) else ()))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="ldh:query-params" as="map(xs:string, xs:string*)">
        <xsl:param name="mode" as="xs:anyURI*"/>
        
        <xsl:sequence select="ldh:query-params($mode, ())"/>
    </xsl:function>

    <xsl:function name="ldh:query-params" as="map(xs:string, xs:string*)">
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="forClass" as="xs:anyURI?"/>
        
        <xsl:sequence select="map:merge((if (exists($mode)) then map{ 'mode': for $m in $mode return string($m) } else (), if ($forClass) then map{ 'forClass': string($forClass) } else ()))"/>
    </xsl:function>

    <xsl:function name="ldh:query-result" as="document-node()" cache="yes">
        <xsl:param name="bindings" as="map(xs:string, xs:anyAtomicType)"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="query" as="xs:string"/>
        
        <xsl:variable name="query-string" as="xs:string">
            <xsl:iterate select="map:keys($bindings)">
                <xsl:param name="query" select="$query" as="xs:string"/>
                
                <xsl:on-completion>
                    <xsl:sequence select="$query"/>
                </xsl:on-completion>
                
                <xsl:variable name="key" select="." as="xs:string"/>
                <xsl:variable name="value" select="map:get($bindings, $key)" as="xs:anyAtomicType"/>
                
                <xsl:next-iteration>
                    <!-- wrap into <> if the value is URI, otherwise wrap into "" as a literal -->
                    <xsl:with-param name="query" select="if ($value instance of xs:anyURI) then replace($query, $key, concat('&lt;', $value, '&gt;'), 'q') else replace($query, $key, concat('&quot;', $value, '&quot;'), 'q')"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $ldt:base, map{}, $results-uri)" as="xs:anyURI"/>
        <xsl:sequence select="document($request-uri)"/>
    </xsl:function>

    <!-- function stub so that Saxon-EE doesn't complain when compiling SEF -->
    <xsl:function name="ldh:construct" as="document-node()" override-extension-function="no" cache="yes">
        <xsl:param name="class-constructors" as="map(xs:anyURI, xs:string*)"/>
            
        <xsl:message use-when="system-property('xsl:product-name') = 'SAXON'" terminate="yes">
            Not implemented -- com.atomgraph.linkeddatahub.writer.function.Construct needs to be registered as an extension function
        </xsl:message>
    </xsl:function>
    
    <xsl:function name="ldh:construct-forClass" as="document-node()" cache="yes">
        <xsl:param name="forClass" as="xs:anyURI+"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'forClass': for $class in $forClass return string($class), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, $ldt:base, map{}, $results-uri)" as="xs:anyURI"/>
            
        <xsl:sequence select="document($request-uri)"/>
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
    
    <xsl:function name="ldh:listSuperClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        
        <xsl:sequence select="ldh:listSuperClasses($class, false())"/>
    </xsl:function>
    
    <xsl:function name="ldh:listSuperClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        
        <xsl:if test="doc-available(ac:document-uri($class))">
            <xsl:variable name="document" select="document(ac:document-uri($class))" as="document-node()"/>

            <xsl:for-each select="$document">
                <xsl:variable name="superclasses" select="key('resources', $class)/rdfs:subClassOf/@rdf:resource[not(. = $class)]" as="attribute()*"/>
                <xsl:sequence select="$superclasses"/>

                <xsl:if test="not($direct)">
                    <xsl:for-each select="$superclasses">
                        <xsl:sequence select="ldh:listSuperClasses(., $direct)"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="ldh:ontologyImports" as="attribute()*" cache="yes">
        <xsl:param name="ontology" as="xs:anyURI"/>
        
        <xsl:sequence select="ldh:ontologyImports($ontology, false())"/>
    </xsl:function>
    
    <xsl:function name="ldh:ontologyImports" as="attribute()*" cache="yes">
        <xsl:param name="ontology" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>

        <xsl:if test="doc-available(ac:document-uri($ontology))">
            <xsl:variable name="document" select="document(ac:document-uri($ontology))" as="document-node()"/>
            <xsl:for-each select="$document">
                <xsl:variable name="imports" select="key('resources', $ontology)/owl:imports/@rdf:resource[not(. = $ontology)]" as="attribute()*"/>
                <xsl:sequence select="$imports"/>
                
                <xsl:if test="not($direct)">
                    <xsl:for-each select="$imports">
                        <xsl:sequence select="ldh:ontologyImports(., $direct)"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

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
    
    <!-- function stub so that Saxon-EE doesn't complain when compiling SEF -->
    <xsl:function name="ldh:send-request" as="document-node()?" override-extension-function="no" cache="yes">
        <xsl:param name="href" as="xs:anyURI"/>
        <xsl:param name="method" as="xs:string"/>
        <xsl:param name="media-type" as="xs:string?"/>
        <xsl:param name="body" as="item()?"/>
        <xsl:param name="headers" as="map(xs:string, xs:string)"/>
        
        <xsl:message>
            ldh:send-request !!!!
        </xsl:message>
        
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
            <xsl:when test="doc-available(namespace-uri()) and key('resources', $this, document(namespace-uri()))" use-when="system-property('xsl:product-name') = 'SAXON'">
                <xsl:apply-templates select="key('resources', $this, document(namespace-uri()))" mode="ac:label"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local-name()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- SET DOCUMENT URI -->
    
    <xsl:template match="rdf:Description[@rdf:nodeID]" mode="ldh:SetResourceID" priority="1">
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
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        
        <dd property="{$property-uri}" resource="{.}">
            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>
    
    <xsl:template match="text()[../@xml:lang]" mode="xhtml:DefinitionDescription">
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>

        <dd property="{$property-uri}">
            <span class="label label-info pull-right">
                <xsl:value-of select="../@xml:lang"/>
            </span>

            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>
    
    <xsl:template match="node()" mode="xhtml:DefinitionDescription">
        <xsl:variable name="property-uri" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        
        <dd property="{$property-uri}">
            <xsl:apply-templates select="."/>
        </dd>
    </xsl:template>
    
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
        <xsl:param name="endpoint" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="graph" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="query-string" select="'DESCRIBE &lt;' || . || '&gt;'" as="xs:string"/>
        <xsl:param name="fragment" select="if (starts-with(., $ldt:base)) then (if (contains(., '#')) then substring-after(., '#') else ()) else encode-for-uri(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, if ($endpoint) then xs:anyURI($endpoint || '?query=' || encode-for-uri($query-string)) else xs:anyURI(.), $graph, $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>

        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="@rdf:about | @rdf:resource" mode="svg:Anchor">
        <xsl:param name="endpoint" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="query-string" select="'DESCRIBE &lt;' || . || '&gt;'" as="xs:string"/>
        <xsl:param name="fragment" select="if (starts-with(., $ldt:base)) then (if (contains(., '#')) then substring-after(., '#') else ()) else encode-for-uri(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, if ($endpoint) then xs:anyURI($endpoint || '?query=' || encode-for-uri($query-string)) else xs:anyURI(.), $fragment)" as="xs:anyURI"/>
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
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- DEFAULT -->

    <!-- proxy link URIs if they are external -->
    <xsl:template match="@rdf:resource | srx:uri" priority="2">
        <xsl:param name="endpoint" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="query-string" select="'DESCRIBE &lt;' || . || '&gt;'" as="xs:string"/>
        <xsl:param name="fragment" select="if (starts-with(., $ldt:base)) then (if (contains(., '#')) then substring-after(., '#') else ()) else encode-for-uri(.)" as="xs:string?"/>
        <xsl:param name="href" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, if ($endpoint) then xs:anyURI($endpoint || '?query=' || encode-for-uri($query-string)) else xs:anyURI(.), $fragment)" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="target" as="xs:string?"/>
        
        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="target" select="$target"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- LOOKUP -->
    
    <xsl:template name="bs2:Lookup">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="value" as="xs:string?"/>
        <xsl:param name="list-class" select="'resource-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:param name="list-id" select="concat('ul-', $id)" as="xs:string"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>
        
        <span>
            <xsl:if test="exists($forClass)">
                <xsl:attribute name="data-for-class" select="string-join($forClass, ' ')"/>
            </xsl:if>
            
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="class" select="$class"/>
                <xsl:with-param name="value" select="$value"/>
                <xsl:with-param name="autocomplete" select="false()"/>
            </xsl:call-template>

            <ul class="{$list-class}" id="{$list-id}" style="display: none;"></ul>
        </span>
    </xsl:template>

    <!-- TYPE -->
    
    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:TypeControl"/>

    <!-- object -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@*" mode="bs2:TypeControl"/>

    <!-- PROPERTY LIST -->

    <!-- suppress properties in a language other than $ldt:lang. TO-DO: move to Web-Client? -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*[@xml:lang and not(lang($ldt:lang))]" mode="bs2:PropertyList"/>

    <!-- FORM CONTROL -->
    
    <xsl:template match="*[rdf:type/@rdf:resource = ('&dh;Container', '&dh;Item')]/@rdf:about" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject-slug input-xxlarge'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>

        <div class="control-group">
            <xsl:if test="$type = 'hidden'">
                <xsl:attribute name="style" select="'display: none'"/>
            </xsl:if>
            
            <span class="control-label">
                <select class="subject-type input-medium" disabled="disabled">
                    <option value="su" selected="selected">URI</option>
                </select>
            </span>
            <div class="controls">
                <span class="input-prepend input-append">
                    <input type="hidden" name="su" value="{.}"/>
                    
                    <span class="add-on">
                        <xsl:value-of select="ac:absolute-path(ldh:base-uri(.))"/>
                    </span>
                    
                    <xsl:call-template name="xhtml:Input">
                        <!-- <xsl:with-param name="name" select="'su'"/> -->
                        <xsl:with-param name="type" select="'text'"/>
                        <!-- <xsl:with-param name="id" select="$id"/> -->
                        <xsl:with-param name="value" select="substring-before(substring-after(., ac:absolute-path(ldh:base-uri(.))), '/')"/>
                        <xsl:with-param name="class" select="$class"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                    
                    <span class="add-on">/</span>
                </span>
            </div>

            <hr/>
        </div>
    </xsl:template>
    
    <!-- resource -->
    <xsl:template match="*[*]/@rdf:about | *[*]/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject input-xxlarge'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="document-uri" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="about" select="xs:anyURI(ac:absolute-path(ldh:base-uri(.)) || '#id' || ac:uuid())" as="xs:anyURI?"/>

        <div class="control-group">
            <xsl:if test="$type = 'hidden'">
                <xsl:attribute name="style" select="'display: none'"/>
            </xsl:if>
            
            <span class="control-label">
                <input type="hidden" class="old subject-type" value="{if (local-name() = 'about') then 'su' else if (local-name() = 'nodeID') then 'sb' else ()}"/>
                <select class="subject-type input-medium">
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
            </span>
            <div class="controls">
                <span>
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
                    <xsl:text> </xsl:text>
                </span>
            </div>

            <hr/>
        </div>
    </xsl:template>

    <!-- turn off default form controls for rdf:type as we are handling it specially with bs2:TypeControl -->
    <xsl:template match="rdf:type[@rdf:resource]" mode="bs2:FormControl" priority="1"/>

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
        <xsl:param name="class" select="concat('control-group', if ($error) then ' error' else (), if ($required) then ' required' else ())" as="xs:string?"/>
        <xsl:message>
            $type-constraints: <xsl:copy-of select="serialize($type-constraints)"/>
        </xsl:message>
        <xsl:message>
            $type-shapes: <xsl:copy-of select="serialize($type-shapes)"/>
        </xsl:message>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Input">
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:apply-templates>
            <xsl:if test="$show-label">
                <label class="control-label" for="{$for}" title="{$this}">
                    <xsl:sequence select="$label"/>
                    
                    <xsl:if test="$description">
                        <span class="description">
                            <xsl:sequence select="$description"/>
                        </span>
                    </xsl:if>
                </label>
            </xsl:if>
            
            <xsl:if test="$cloneable">
                <div class="btn-group pull-right">
                    <button type="button" class="btn btn-small pull-right btn-add" title="Add another statement">&#x271a;</button>
                </div>
            </xsl:if>

            <div class="controls">
                <xsl:if test="not($required)">
                    <div class="btn-group pull-right">
                        <button type="button" tabindex="-1">
                            <xsl:attribute name="title">
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', 'remove-stmt', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:attribute>
                            
                            <xsl:apply-templates select="key('resources', 'remove', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn btn-small pull-right'"/>
                            </xsl:apply-templates>
                        </button>
                    </div>
                </xsl:if>

                <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"> <!-- not @rdf:* because that would apply to @rdf:parseType -->
                    <xsl:with-param name="id" select="$for"/>
                    <xsl:with-param name="required" select="$required"/>
                    <xsl:with-param name="constructor" select="$constructor"/>
                </xsl:apply-templates>
            </div>
            
            <xsl:if test="@xml:lang or @rdf:datatype">
                <div class="controls">
                    <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current"/>
                </div>
            </xsl:if>
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
        <xsl:param name="forClass" as="xs:anyURI?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:choose>
                <xsl:when test="$forClass">
                    <span class="help-inline">
                        <xsl:choose>
                            <xsl:when test="doc-available(ac:document-uri($forClass)) and key('resources', $forClass, document(ac:document-uri($forClass)))"> <!-- server-side Saxon has access to the sitemap ontology -->
                                <xsl:value-of>
                                    <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:when>
                            <xsl:otherwise> <!-- client-side Saxon-JS does not have access to the sitemap ontology -->
                                <xsl:value-of select="$forClass"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <span class="help-inline">Resource</span>
                </xsl:otherwise>
            </xsl:choose>
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
                <xsl:variable name="forClass" select="if ($constructor) then distinct-values(key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $constructor)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $constructor)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')]) else ()" as="xs:anyURI?"/>
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
    
    <!-- WYSIWYG editor for XMLLiteral objects -->

    <xsl:template match="*[@rdf:parseType = 'Literal']/xhtml:*" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="type" select="'textarea'" as="xs:string?"/> <!-- 'textarea' is not a valid <input> type -->
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <textarea name="ol" id="{$id}" class="wymeditor">
            <xsl:variable name="xhtml" as="element()*">
                <xsl:copy-of select="xhtml:*" copy-namespaces="no"/>
            </xsl:variable>
            <xsl:value-of select="serialize($xhtml)"/>
        </textarea>
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
            <xsl:choose>
                <xsl:when test="exists($forClass)">
                    <span class="help-inline">
                        <xsl:for-each select="$forClass">
                            <xsl:choose>
                                <xsl:when test="doc-available(ac:document-uri(.))">
                                    <xsl:choose>
                                        <xsl:when test=". = '&rdfs;Resource'">Resource</xsl:when>
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
                    <span class="help-inline">Resource</span>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- real numbers -->
    
    <xsl:template match="text()[../@rdf:datatype = '&xsd;float'] | text()[../@rdf:datatype = '&xsd;double']" priority="1" mode="xhtml:Input">
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

    <!-- XHTML CONTENT IDENTITY TRANSFORM -->

    <xsl:template match="@* | node()" mode="ldh:XHTMLContent">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- rewrite @ids so they don't class with the parent document's when transcluded -->
    <xsl:template match="@id" mode="ldh:XHTMLContent" priority="1">
        <xsl:param name="transclude" select="false()" as="xs:boolean" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="$transclude">
                <xsl:attribute name="{name()}" select="generate-id()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- resolve relative @href URIs against base when transcluding -->
    <xsl:template match="@href[starts-with(., '.')]" mode="ldh:XHTMLContent" priority="1">
        <xsl:param name="transclude" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="base" as="xs:anyURI?" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="$transclude">
                <xsl:attribute name="{name()}" select="resolve-uri(., $base)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
