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

        <xsl:choose>
            <!-- do not proxy $uri via ?uri= if it is relative to the $base -->
            <xsl:when test="$uri and starts-with($uri, $base)">
                <xsl:variable name="absolute-path" select="xs:anyURI(if (contains($uri, '#')) then substring-before($uri, '#') else $uri)" as="xs:anyURI"/>
                <xsl:variable name="fragment" select="if ($fragment) then '#' || $fragment else if (contains($uri, '#')) then substring-after($uri, '#') else ()" as="xs:string?"/>
                <xsl:sequence select="xs:anyURI(ac:build-uri($absolute-path, $query-params) || $fragment)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="fragment" select="if ($fragment) then '#' || $fragment else '#' || encode-for-uri($uri)" as="xs:string?"/>
                <xsl:sequence select="xs:anyURI(ac:build-uri($absolute-path, map:merge((map{ 'uri': string($uri) }, $query-params))) || $fragment)"/>
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
    
    <xsl:function name="ldh:absolute-path" as="xs:anyURI">
        <xsl:param name="href" as="xs:anyURI"/>
        
        <xsl:sequence select="xs:anyURI(if (contains($href, '?')) then substring-before($href, '?') else if (contains($href, '#')) then substring-before($href, '#') else $href)"/>
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

    <xsl:function name="ldh:listSubClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        <xsl:param name="ontology" as="xs:anyURI"/>
        
        <xsl:variable name="ontologies" select="$ontology, ldh:ontologyImports($ontology)" as="xs:anyURI*"/>
        <xsl:variable name="ontology-docs" as="document-node()*">
            <xsl:for-each select="$ontologies">
                <xsl:if test="doc-available(ac:document-uri(.))">
                    <xsl:sequence select="document(ac:document-uri(.))"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:sequence select="ldh:listSubClassesInDocuments($class, $direct, $ontology-docs)"/>
    </xsl:function>
    
    <!-- this is a different, not follow-your-nose Linked Data search as in ldh:listSuperClasses() as we don't know the URIs of the documents containing subclasses -->
    <!-- start with the $ldt:ontology document and traverse imported RDF ontologies recursively looking for rdfs:subClassOf triples -->
    <xsl:function name="ldh:listSubClassesInDocuments" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        <xsl:param name="ontology-docs" as="document-node()*"/>

        <xsl:for-each select="$ontology-docs">
            <xsl:variable name="subclasses" select="key('resources-by-subclass', $class, .)/@rdf:about[not(. = $class)]" as="attribute()*"/>
            <xsl:sequence select="$subclasses"/>

            <xsl:for-each select="$subclasses">
                <xsl:sequence select="ldh:listSubClassesInDocuments(., $direct, $ontology-docs)"/>
            </xsl:for-each>
        </xsl:for-each>
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
            <xsl:when test="$property-metadata/key('resources', $this, .)" use-when="system-property('xsl:product-name') = 'SAXON'" >
                <xsl:apply-templates select="$property-metadata/key('resources', $this, .)" mode="ac:label"/>
            </xsl:when>
            <xsl:when test="doc-available(namespace-uri()) and key('resources', $this, document(namespace-uri()))" use-when="system-property('xsl:product-name') = 'SAXON'" >
                <xsl:apply-templates select="key('resources', $this, document(namespace-uri()))" mode="ac:label"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local-name()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- SET PRIMARY TOPIC -->

    <!-- link document instance to the topic instance using foaf:primaryTopic -->
    <xsl:template match="rdf:Description/foaf:primaryTopic[@rdf:nodeID]" mode="ldh:SetPrimaryTopic" priority="1">
        <xsl:param name="topic-id" as="xs:string?" tunnel="yes"/>
        <xsl:param name="doc-id" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:choose>
                <!-- check subject ID of this resource -->
                <xsl:when test="$topic-id and ../@rdf:nodeID = $doc-id"> <!-- TO-DO: support @rdf:about? -->
                    <!-- overwrite existing value with $topic-id -->
                    <xsl:attribute name="rdf:nodeID" select="$topic-id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- suppress the old foaf:primaryTopic object resource which is not used anymore -->
    <xsl:template match="rdf:Description[@rdf:nodeID]" mode="ldh:SetPrimaryTopic" priority="1">
        <xsl:param name="doc-id" as="xs:string" tunnel="yes"/>

        <!-- check if the bnode ID of this resource equals the foaf:primaryTopic/@rdf:nodeID of the document instance -->
        <xsl:if test="not(@rdf:nodeID = key('resources', $doc-id)/foaf:primaryTopic/@rdf:nodeID)">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:SetPrimaryTopic">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
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
        <xsl:param name="query-string" select="'DESCRIBE &lt;' || . || '&gt;'" as="xs:string"/>
        <xsl:param name="href" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, if ($endpoint) then xs:anyURI($endpoint || '?query=' || encode-for-uri($query-string)) else xs:anyURI(.), encode-for-uri(.))" as="xs:anyURI"/>
        <xsl:param name="id" select="if (starts-with(., ldh:absolute-path(ldh:href()))) then (if (contains(., '#')) then substring-after(., '#') else ()) else encode-for-uri(.)" as="xs:string?"/>
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
        <xsl:param name="href" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, if ($endpoint) then xs:anyURI($endpoint || '?query=' || encode-for-uri($query-string)) else xs:anyURI(.), encode-for-uri(.))" as="xs:anyURI"/>
        <xsl:param name="id" select="if (starts-with(., ldh:absolute-path(ldh:href()))) then (if (contains(., '#')) then substring-after(., '#') else ()) else encode-for-uri(.)" as="xs:string?"/>
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
        <xsl:param name="href" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), map{}, if ($endpoint) then xs:anyURI($endpoint || '?query=' || encode-for-uri($query-string)) else xs:anyURI(.), encode-for-uri(.))" as="xs:anyURI"/>
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

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="value" select="$value"/>
            <xsl:with-param name="autocomplete" select="false()"/>
        </xsl:call-template>
        
        <ul class="{$list-class}" id="{$list-id}" style="display: none;"></ul>
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

    <!-- resource -->
    <xsl:template match="*[*]/@rdf:*[local-name() = ('about', 'nodeID')]" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'subject input-xxlarge'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="auto" select="local-name() = 'nodeID' or starts-with(., $ldt:base)" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="not($type = 'hidden')">
                <!-- <fieldset> -->
                    <div class="control-group">
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
                                <!--
                                <xsl:if test="$auto">
                                    <xsl:attribute name="style" select="'display: none;'"/>
                                </xsl:if>
                                -->
                                <!-- hidden inputs in which we store the old values of the visible input -->
                                <input type="hidden" class="old su">
                                    <xsl:attribute name="value" select="if (local-name() = 'about') then . else resolve-uri(concat('/', ac:uuid()), ac:uri())"/>
                                </input>
                                <input type="hidden" class="old sb">
                                    <xsl:attribute name="value" select="if (local-name() = 'nodeID') then . else generate-id()"/>
                                </input>
                                <xsl:apply-templates select="." mode="xhtml:Input">
                                    <xsl:with-param name="type" select="$type"/>
                                    <!-- <xsl:with-param name="id" select="$id"/> -->
                                    <xsl:with-param name="class" select="$class"/>
                                    <xsl:with-param name="disabled" select="$disabled"/>
                                </xsl:apply-templates>
                                <xsl:text> </xsl:text>
                            </span>
                        </div>
                    </div>
                <!-- </fieldset> -->
                
                <hr/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <!-- <xsl:with-param name="id" select="$id"/> -->
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

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
        <xsl:param name="constraints" as="document-node()*"/>
        <xsl:param name="shapes" as="document-node()*"/>
        <!-- only the first property that has a mandatory constraint is required, the following ones are not -->
        <xsl:param name="required" select="($shapes//rdf:Description[sh:path/@rdf:resource = $this][sh:minCount &gt;= count(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this])]) or ($constraints//srx:binding[@name = 'property'][srx:uri = $this] and not(preceding-sibling::*[concat(namespace-uri(), local-name()) = $this]))" as="xs:boolean"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <xsl:param name="class" select="concat('control-group', if ($error) then ' error' else (), if ($required) then ' required' else ())" as="xs:string?"/>
        
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
                        <button type="button">
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

                <xsl:apply-templates select="node() | @rdf:*[local-name() = ('resource', 'nodeID')]" mode="#current">
                    <xsl:with-param name="required" select="$required"/>
                    <xsl:with-param name="constructor" select="$constructor"/>
                </xsl:apply-templates>
            </div>
            
            <xsl:if test="(@xml:*[local-name() = 'lang'] | @rdf:*[local-name() = 'datatype'])">
                <div class="controls">
                    <xsl:apply-templates select="@xml:*[local-name() = 'lang'] | @rdf:*[local-name() = 'datatype']" mode="#current"/>
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
        <xsl:variable name="resource" select="key('resources', .)"/>
        <xsl:variable name="doc-uri" select="if (starts-with($ldt:base, .)) then xs:anyURI(.) else ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(.)) })" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="$type = 'hidden'">
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- loop if node not visited already -->
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
            <xsl:when test="starts-with(., $ldt:base) and doc-available($doc-uri)">
                <xsl:choose>
                    <xsl:when test="key('resources', ., document(ac:document-uri($doc-uri)))">
                        <span>
                            <xsl:apply-templates select="key('resources', ., document(ac:document-uri($doc-uri)))" mode="ldh:Typeahead"/>
                        </span>

                        <xsl:if test="$constructor">
                            <xsl:text> </xsl:text>
                            <xsl:variable name="forClass" select="distinct-values(key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $constructor)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $constructor)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')])" as="xs:anyURI?"/>
                            <xsl:if test="$forClass">
                                <!-- forClass input is required by typeahead's FILTER ($Type IN ()) in client.xsl -->
                                <xsl:choose>
                                    <xsl:when test="not($forClass = ('&rdfs;Resource', '&rdfs;Literal')) and ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $forClass return '&lt;' || $type || '&gt;', ' ') || ' }')//srx:binding[@name = 'construct']/srx:literal">
                                        <xsl:variable name="subclasses" select="ldh:listSubClasses($forClass, false(), $ldt:ontology)" as="attribute()*"/>
                                        <!-- add subclasses as forClass -->
                                        <xsl:for-each select="distinct-values(ldh:listSubClasses($forClass, false(), $ldt:ontology))[not(. = $forClass)]">
                                            <input type="hidden" class="forClass" value="{.}"/>
                                        </xsl:for-each>
                                        <!-- bs2:Constructor sets forClass -->
                                        <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                                            <xsl:with-param name="modal-form" select="true()"/>
                                            <xsl:with-param name="subclasses" select="$subclasses"/>
                                            <xsl:with-param name="create-graph" select="true()"/>
                                        </xsl:apply-templates>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- $forClass URI cannot be resolved to an RDF document -->
                                        <input type="hidden" class="forClass" value="{$forClass}"/>
                                    </xsl:otherwise>
                                </xsl:choose>

                                <xsl:if test="$type-label">
                                    <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                                        <xsl:with-param name="type" select="$type"/>
                                        <xsl:with-param name="forClass" select="$forClass"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:next-match/>
                    </xsl:otherwise>
                </xsl:choose>
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
                <span>
                    <xsl:apply-templates select="$resource" mode="ldh:Typeahead"/>
                </span>
                
                <xsl:if test="$constructor">
                    <xsl:text> </xsl:text>
                    <xsl:variable name="forClass" select="key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $constructor)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $constructor)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')]" as="xs:anyURI?"/>
                    <xsl:if test="$forClass">
                        <!-- forClass input is required by typeahead's FILTER ($Type IN ()) in client.xsl -->
                        <xsl:choose>
                            <xsl:when test="not($forClass = ('&rdfs;Resource', '&rdfs;Literal')) and ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $forClass return '&lt;' || $type || '&gt;', ' ') || ' }')//srx:binding[@name = 'construct']/srx:literal">
                                <xsl:variable name="subclasses" select="ldh:listSubClasses($forClass, false(), $ldt:ontology)" as="attribute()*"/>
                                <!-- add subclasses as forClass -->
                                <xsl:for-each select="distinct-values(ldh:listSubClasses($forClass, false(), $ldt:ontology))[not(. = $forClass)]">
                                    <input type="hidden" class="forClass" value="{.}"/>
                                </xsl:for-each>
                                <!-- bs2:Constructor sets forClass -->
                                <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                                    <xsl:with-param name="modal-form" select="true()"/>
                                    <xsl:with-param name="subclasses" select="$subclasses"/>
                                    <xsl:with-param name="create-graph" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- $forClass URI cannot be resolved to an RDF document -->
                                <input type="hidden" class="forClass" value="{$forClass}"/>
                            </xsl:otherwise>
                        </xsl:choose>

                        <xsl:if test="$type-label">
                            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel">
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="forClass" select="$forClass"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:if>
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
    <xsl:template match="*[@rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[starts-with(@rdf:resource, '&xsd;')])]]" mode="bs2:FormControl" priority="2">
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
    
    <!-- blank nodes that only have non-XSD rdf:type and no other properties become resource typeaheads -->
    <xsl:template match="*[@rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[not(starts-with(@rdf:resource, '&xsd;'))])]]" mode="bs2:FormControl" priority="1">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="required" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>

        <span>
            <xsl:call-template name="bs2:Lookup">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="class" select="$class"/>
            </xsl:call-template>
        </span>
        <xsl:text> </xsl:text>

        <xsl:variable name="forClass" select="key('resources', .)/rdf:type/@rdf:resource" as="xs:anyURI"/>
        <xsl:variable name="forClass-shapes" select="ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $shape-query || ' VALUES $Type { ' || string-join(for $type in $forClass return '&lt;' || $type || '&gt;', ' ') || ' }')" as="document-node()"/>
        <!-- forClass input is used by typeahead's FILTER ($Type IN ()) in client.xsl -->
        <xsl:choose>
            <!-- SHACL shapes -->
            <xsl:when test="not($forClass = '&rdfs;Resource') and $forClass-shapes//rdf:Description[sh:targetClass/@rdf:resource = $forClass]">
                <xsl:apply-templates select="$forClass-shapes//rdf:Description[sh:targetClass/@rdf:resource = $forClass]" mode="bs2:ShapeConstructor">
                    <xsl:with-param name="modal-form" select="true()"/>
                    <xsl:with-param name="create-graph" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- SPIN constraints -->
            <xsl:when test="not($forClass = '&rdfs;Resource') and ldh:query-result(map{}, resolve-uri('ns', $ldt:base), $constructor-query || ' VALUES $Type { ' || string-join(for $type in $forClass return '&lt;' || $type || '&gt;', ' ') || ' }')//srx:binding[@name = 'construct']/srx:literal">
                <xsl:variable name="subclasses" select="ldh:listSubClasses($forClass, false(), $ldt:ontology)" as="attribute()*"/>
                <!-- add subclasses as forClass -->
                <xsl:for-each select="distinct-values($subclasses)[not(. = $forClass)]">
                    <input type="hidden" class="forClass" value="{.}"/>
                </xsl:for-each>
                <!-- bs2:Constructor sets forClass -->
                <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                    <xsl:with-param name="modal-form" select="true()"/>
                    <xsl:with-param name="subclasses" select="$subclasses"/>
                    <xsl:with-param name="create-graph" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <input type="hidden" class="forClass" value="{$forClass}"/> <!-- required by $Type FILTER -->
            </xsl:otherwise>
        </xsl:choose>

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
            <xsl:apply-templates select="xhtml:*" mode="xml-to-string"/>
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

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;Content']/rdf:value/@rdf:* | *[rdf:type/@rdf:resource = '&ldh;Content']/rdf:value/xhtml:*" mode="bs2:FormControlTypeLabel" priority="1">
        <select class="help-inline content-type">
            <option value="&rdfs;Resource">
                <xsl:if test="self::attribute()">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>
                
                <xsl:text>Resource</xsl:text>
            </option>
            <option value="&rdf;XMLLiteral">
                <xsl:if test="self::xhtml:*">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>
                
                <xsl:text>HTML</xsl:text>
            </option>
        </select>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID]/*/@rdf:nodeID[key('resources', .)[not(* except rdf:type[not(starts-with(@rdf:resource, '&xsd;'))])]]" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:param name="forClass" as="xs:anyURI?"/>

        <xsl:if test="not($type = 'hidden')">
            <xsl:choose>
                <xsl:when test="$forClass">
                    <span class="help-inline">
                        <xsl:choose>
                            <xsl:when test="doc-available(ac:document-uri($forClass))">
                                <xsl:choose>
                                    <xsl:when test="$forClass = '&rdfs;Resource'">Resource</xsl:when>
                                    <xsl:when test="key('resources', $forClass, document(ac:document-uri($forClass)))">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$forClass"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
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

    <!-- structured data for the JSON-LD script tag -->
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:JSON-LDContext"/>
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:JSON-LDPropertyGroup">
        <xsl:param name="suppress" select="true()" as="xs:boolean"/> <!-- by default, suppress JSON-LD output of a property -->
        <xsl:param name="resource" as="element()"/>
        <xsl:param name="grouping-key" as="xs:anyAtomicType?"/>
        <xsl:param name="group" as="item()*"/>
        
        <xsl:if test="not($suppress)">
            <xsl:next-match>
                <xsl:with-param name="resource" select="$resource"/>
                <xsl:with-param name="grouping-key" select="$grouping-key"/>
                <xsl:with-param name="group" select="$group"/>
            </xsl:next-match>
        </xsl:if>
    </xsl:template>
    
    <!-- XHTML CONTENT IDENTITY TRANSFORM -->
    
    <xsl:template match="*" mode="ldh:XHTMLContent" priority="1">
        <xsl:element name="{name()}">
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="@* | node()" mode="ldh:XHTMLContent">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
