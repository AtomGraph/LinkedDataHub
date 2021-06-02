<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp   "https://w3id.org/atomgraph/linkeddatahub/apps/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:lapp="&lapp;"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:xsd="&xsd;"
xmlns:srx="&srx;"
xmlns:http="&http;"
xmlns:ldt="&ldt;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:foaf="&foaf;"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all"
>

    <xsl:key name="predicates-by-object" match="*[@rdf:about]/* | *[@rdf:nodeID]/*" use="@rdf:resource | @rdf:nodeID"/>
    <xsl:key name="violations-by-root" match="*[@rdf:about] | *[@rdf:nodeID]" use="spin:violationRoot/@rdf:resource | spin:violationRoot/@rdf:nodeID"/>
    <xsl:key name="resources-by-type" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="rdf:type/@rdf:resource"/>

    <xsl:param name="ac:contextUri" as="xs:anyURI?"/>

    <xsl:function name="apl:listSuperClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        
        <xsl:sequence select="apl:listSuperClasses($class, false())"/>
    </xsl:function>
    
    <xsl:function name="apl:listSuperClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        
        <xsl:if test="doc-available(ac:document-uri($class))">
            <xsl:variable name="document" select="document(ac:document-uri($class))" as="document-node()"/>

            <xsl:for-each select="$document">
                <xsl:variable name="superclasses" select="key('resources', $class)/rdfs:subClassOf/@rdf:resource[not(. = $class)]" as="attribute()*"/>
                <xsl:sequence select="$superclasses"/>

                <xsl:if test="not($direct)">
                    <xsl:for-each select="$superclasses">
                        <xsl:sequence select="apl:listSuperClasses(., $direct)"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="apl:ontologyImports" as="attribute()*" cache="yes">
        <xsl:param name="ontology" as="xs:anyURI"/>
        
        <xsl:sequence select="apl:ontologyImports($ontology, false())"/>
    </xsl:function>
    
    <xsl:function name="apl:ontologyImports" as="attribute()*" cache="yes">
        <xsl:param name="ontology" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>

        <xsl:if test="doc-available($ontology)">
            <xsl:variable name="document" select="document($ontology)" as="document-node()"/>
            <xsl:for-each select="$document">
                <xsl:variable name="imports" select="key('resources', $ontology)/owl:imports/@rdf:resource[not(. = $ontology)]" as="attribute()*"/>
                <xsl:sequence select="$imports"/>
                
                <xsl:if test="not($direct)">
                    <xsl:for-each select="$imports">
                        <xsl:sequence select="apl:ontologyImports(., $direct)"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

    <xsl:function name="apl:listSubClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>

        <xsl:sequence select="apl:listSubClasses($class, false(), $ldt:ontology)"/>
    </xsl:function>
    
    <xsl:function name="apl:listSubClasses" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        <xsl:param name="ontology" as="xs:anyURI"/>
        
        <xsl:variable name="ontologies" select="$ontology, apl:ontologyImports($ontology)" as="xs:anyURI*"/>
        <xsl:variable name="ontology-docs" as="document-node()*">
            <xsl:for-each select="$ontologies">
                <xsl:if test="doc-available(.)">
                    <xsl:sequence select="document(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:sequence select="apl:listSubClassesInDocuments($class, $direct, $ontology-docs)"/>
    </xsl:function>
    
    <!-- this is a different, not follow-your-nose Linked Data search as in apl:listSuperClasses() as we don't know the URIs of the documents containing subclasses -->
    <!-- start with the $ldt:ontology document and traverse imported RDF ontologies recursively looking for rdfs:subClassOf triples -->
    <xsl:function name="apl:listSubClassesInDocuments" as="attribute()*" cache="yes">
        <xsl:param name="class" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        <xsl:param name="ontology-docs" as="document-node()*"/>

        <xsl:for-each select="$ontology-docs">
            <xsl:variable name="subclasses" select="key('resources-by-subclass', $class, .)/@rdf:about[not(. = $class)]" as="attribute()*"/>
            <xsl:sequence select="$subclasses"/>

            <xsl:for-each select="$subclasses">
                <xsl:sequence select="apl:listSubClassesInDocuments(., $direct, $ontology-docs)"/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="apl:listSuperTemplates" as="attribute()*" cache="yes">
        <xsl:param name="template" as="xs:anyURI"/>
        
        <xsl:sequence select="apl:listSuperTemplates($template, false())"/>
    </xsl:function>
    
    <xsl:function name="apl:listSuperTemplates" as="attribute()*" cache="yes">
        <xsl:param name="template" as="xs:anyURI"/>
        <xsl:param name="direct" as="xs:boolean"/>
        
        <xsl:if test="doc-available(ac:document-uri($template))">
            <xsl:variable name="document" select="document(ac:document-uri($template))" as="document-node()"/>

            <xsl:for-each select="$document">
                <xsl:variable name="supertemplates" select="key('resources', $template)/ldt:extends/@rdf:resource" as="attribute()*"/>
                <xsl:sequence select="$supertemplates"/>

                <xsl:if test="not($direct)">
                    <xsl:for-each select="$supertemplates">
                        <xsl:sequence select="apl:listSuperTemplates(., $direct)"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
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
    
    <xsl:template match="*[@rdf:nodeID = 'add']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-add')"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'remove']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-remove-property')"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&ac;EditMode']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-edit')"/>
        <xsl:sequence select="ac:label(.)"/>
    </xsl:template>
    
    <xsl:template match="*[@rdf:nodeID = 'copy-uri']" mode="apl:logo">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:attribute name="class" select="concat($class, ' ', 'btn-copy-uri')"/>
    </xsl:template>
    
    <xsl:template match="*" mode="apl:logo" priority="0">
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:if test="$class">
            <xsl:attribute name="class" select="$class"/>
        </xsl:if>
    </xsl:template>
    
    <!-- DEFAULT -->

    <!-- resources with URIs not relative to app base -->
    <xsl:template match="@rdf:resource[starts-with(., $ldt:base)] | srx:uri[starts-with(., $ldt:base)]" priority="2">
        <xsl:next-match>
            <xsl:with-param name="href" select="."/>
        </xsl:next-match>
    </xsl:template>

    <!-- ANCHOR -->
    <!-- TO-DO: move to external.xsl -->

    <!-- add ?uri= indirection on external HTTP(S) links -->
    <xsl:template match="*[starts-with(@rdf:about, 'http://')][not(starts-with(@rdf:about, $ldt:base))] | *[starts-with(@rdf:about, 'https://')][not(starts-with(@rdf:about, $ldt:base))]" mode="xhtml:Anchor">
        <xsl:param name="href" select="ac:build-uri($ldt:base, map{ 'uri': string(@rdf:about) })" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="@rdf:about" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="@rdf:resource[starts-with(., 'http://')][not(starts-with(., $ldt:base))] | @rdf:resource[starts-with(., 'https://')][not(starts-with(., $ldt:base))] | srx:uri[starts-with(., 'http://')][not(starts-with(., $ldt:base))] | srx:uri[starts-with(., 'https://')][not(starts-with(., $ldt:base))]">
        <xsl:param name="href" select="xs:anyURI(ac:build-uri($ldt:base, map{ 'uri': if (contains(., '#')) then substring-before(., '#') else string(.) }) || (if (substring-after(., '#')) then '#' || substring-after(., '#') else ()))" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="title" select="." as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        
        <xsl:next-match>
            <xsl:with-param name="href" select="$href"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:next-match>
    </xsl:template>
    
    <!-- LOOKUP -->
    
    <xsl:template name="bs2:Lookup">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" select="'resource-typeahead typeahead'" as="xs:string?"/>
        <xsl:param name="list-class" select="'resource-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:param name="list-id" select="concat('ul-', $id)" as="xs:string"/>

        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="name" select="'ou'"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="class" select="$class"/>
        </xsl:call-template>
        
        <ul class="{$list-class}" id="{$list-id}" style="display: none;"></ul>
    </xsl:template>

    <!-- TYPE -->
    
    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:TypeControl"/>

    <!-- object -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*/@*" mode="bs2:TypeControl"/>

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
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>URI</xsl:text>
                                </option>
                                <option value="sb">
                                    <xsl:if test="local-name() = 'nodeID'">
                                        <xsl:attribute name="selected">selected</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>Blank node</xsl:text>
                                </option>
                            </select>
                        </span>
                        <div class="controls">
                            <span>
                                <!--
                                <xsl:if test="$auto">
                                    <xsl:attribute name="style">display: none;</xsl:attribute>
                                </xsl:if>
                                -->
                                <!-- hidden inputs in which we store the old values of the visible input -->
                                <input type="hidden" class="old su">
                                    <xsl:attribute name="value">
                                        <xsl:choose>
                                            <xsl:when test="local-name() = 'about'">
                                                <xsl:attribute name="value" select="."/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="resolve-uri(concat('/', ac:uuid()), $ac:uri)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </input>
                                <input type="hidden" class="old sb">
                                    <xsl:attribute name="value">
                                        <xsl:choose>
                                            <xsl:when test="local-name() = 'nodeID'">
                                                <xsl:attribute name="value" select="."/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="generate-id()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </input>
                                <xsl:apply-templates select="." mode="xhtml:Input">
                                    <xsl:with-param name="type" select="$type"/>
                                    <!-- <xsl:with-param name="id" select="$id"/> -->
                                    <xsl:with-param name="class" select="$class"/>
                                    <xsl:with-param name="disabled" select="$disabled"/>
                                </xsl:apply-templates>
                                <xsl:text> </xsl:text>
                            </span>
                            <!--
                            <input type="checkbox" value="auto">
                                <xsl:if test="$auto">
                                    <xsl:attribute name="checked">checked</xsl:attribute>
                                </xsl:if>
                            </input>
                            <span class="help-inline">Auto</span>
                            -->
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
    
    <!-- hide foaf:primaryTopic/foaf:isPrimaryTopicOf if their object resources have properties other than rdf:type -->
    <!--
    <xsl:template match="foaf:primaryTopic[key('resources', (@rdf:resource, @rdf:nodeID))[* except rdf:type]] | foaf:isPrimaryTopicOf[key('resources', (@rdf:resource, @rdf:nodeID))[* except rdf:type]]" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    -->
    
    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:FormControl">
        <xsl:param name="this" select="xs:anyURI(concat(namespace-uri(), local-name()))" as="xs:anyURI"/>
        <xsl:param name="violations" as="element()*"/>
        <xsl:param name="error" select="@rdf:resource = $violations/apl:violationValue or $violations/spin:violationPath/@rdf:resource = $this" as="xs:boolean"/>
        <xsl:param name="label" select="true()" as="xs:boolean"/>
        <xsl:param name="template-doc" as="document-node()?"/>
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="cloneable" select="false()" as="xs:boolean"/>
        <xsl:param name="required" as="xs:boolean">
            <xsl:variable name="types" select="../rdf:type/@rdf:resource" as="xs:anyURI*"/>
            <xsl:choose>
                <xsl:when test="exists($types)">
                    <!-- constraint (sub)classes are in the admin ontology -->
                    <xsl:variable name="constraint-classes" select="(xs:anyURI('&apl;MissingPropertyValue'), apl:listSubClasses(xs:anyURI('&apl;MissingPropertyValue'), false(), resolve-uri('admin/ns#', $ldt:base)))" as="xs:anyURI*"/>
                    <!-- required is true if there are subclasses that have constraints of type that equals constraint classes -->
                    <xsl:sequence select="exists(for $class in ($types, for $type in $types return apl:listSuperClasses($type)[name() = 'rdf:about'])[doc-available(ac:document-uri(.))] return key('resources', $class, document(ac:document-uri($class)))/spin:constraint/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())[rdf:type/@rdf:resource = $constraint-classes and sp:arg1/@rdf:resource = $this])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <xsl:param name="class" select="concat('control-group', if ($error) then ' error' else (), if ($required) then ' required' else ())" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." mode="xhtml:Input">
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:apply-templates>
            <xsl:if test="$label">
                <label class="control-label" for="{$for}" title="{$this}">
                    <xsl:choose use-when="system-property('xsl:product-name') = 'SAXON'">
                        <xsl:when test="doc-available(ac:document-uri(xs:anyURI($this)))">
                            <xsl:choose>
                                <xsl:when test="key('resources', $this, document(ac:document-uri(xs:anyURI($this))))">
                                    <xsl:for-each select="key('resources', $this, document(ac:document-uri(xs:anyURI($this))))">
                                        <xsl:value-of select="ac:label(.)"/> <!-- uppercase first letter -->
                                        
                                        <xsl:if test="ac:description(.)">
                                            <span class="description">
                                                <xsl:value-of select="ac:description(.)"/>
                                            </span>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="local-name()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="local-name()"/>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:value-of use-when="system-property('xsl:product-name') eq 'Saxon-JS'" select="local-name()"/>
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
                        <button type="button" title="Remove this statement">
                            <xsl:apply-templates select="key('resources', 'remove', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                                <xsl:with-param name="class" select="'btn btn-small pull-right'"/>
                            </xsl:apply-templates>
                        </button>
                    </div>
                </xsl:if>

                <xsl:apply-templates select="node() | @rdf:*[local-name() = ('resource', 'nodeID')]" mode="#current">
                    <xsl:with-param name="required" select="$required"/>
                    <xsl:with-param name="template-doc" select="$template-doc"/>
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
        <xsl:param name="template"  as="element()?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="template-doc" as="document-node()?"/>
        <xsl:variable name="resource" select="key('resources', .)"/>
        <xsl:variable name="doc-uri" select="if (starts-with($ldt:base, $ac:contextUri)) then ac:document-uri(.) else ac:build-uri($ldt:base, map{ 'uri': string(ac:document-uri(.)) })" as="xs:anyURI"/>

        <xsl:choose>
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
            <xsl:when test="$type = 'hidden'">
                <xsl:next-match>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="starts-with(., $ldt:base) and doc-available($doc-uri)">
                <xsl:choose>
                    <xsl:when test="key('resources', ., document($doc-uri))">
                        <span>
                            <xsl:for-each select="key('resources', ., document($doc-uri))">
                                <xsl:apply-templates select="." mode="apl:Typeahead"/>
                            </xsl:for-each>
                        </span>

                        <xsl:if test="$template-doc">
                            <xsl:text> </xsl:text>
                            <xsl:variable name="forClass" select="key('resources', key('resources-by-type', ../../rdf:type/@rdf:resource, $template-doc)/*[concat(namespace-uri(), local-name()) = current()/../concat(namespace-uri(), local-name())]/@rdf:nodeID, $template-doc)/rdf:type/@rdf:resource[not(. = '&rdfs;Class')]" as="xs:anyURI?"/>
                            <xsl:if test="$forClass">
                                <!-- forClass input is required by typeahead's FILTER (?Type IN ()) in client.xsl -->
                                <xsl:choose>
                                    <xsl:when test="doc-available(ac:document-uri($forClass))">
                                        <xsl:variable name="subclasses" select="apl:listSubClasses($forClass)" as="attribute()*"/>
                                        <!-- add subclasses as forClass -->
                                        <xsl:for-each select="distinct-values(apl:listSubClasses($forClass))[not(. = $forClass)]">
                                            <input type="hidden" class="forClass" value="{.}"/>
                                        </xsl:for-each>
                                        <!-- bs2:Constructor sets forClass -->
                                        <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                                            <xsl:with-param name="subclasses" select="$subclasses"/>
                                        </xsl:apply-templates>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- $forClass URI cannot be resolved to an RDF document -->
                                        <input type="hidden" class="forClass" value="{$forClass}"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            
                                <xsl:if test="not($type = 'hidden') and $type-label">
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
                
                <xsl:if test="not($type = 'hidden') and $type-label">
                    <span class="help-inline">Resource</span>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- object blank node -->
    <xsl:template match="*[@rdf:about]/*/@rdf:nodeID | *[@rdf:nodeID]/*/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="type" select="'text'" as="xs:string"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="inline" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="template"  as="element()?"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="resource" select="key('resources', .)"/>

        <xsl:choose>
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
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="xhtml:Input">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="class" select="$class"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                </xsl:apply-templates>
                
                <xsl:if test="not($type = 'hidden') and $type-label">
                    <span class="help-inline">Resource</span>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- blank nodes that only have rdf:type xsd:* and no other properties become literal inputs -->
    <!-- TO-DO: expand pattern to handle other XSD datatypes -->
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
        <!-- forClass input is used by typeahead's FILTER (?Type IN ()) in client.xsl -->
        <xsl:choose>
            <xsl:when test="not($forClass = '&rdfs;Resource') and doc-available(ac:document-uri($forClass))">
                <xsl:variable name="subclasses" select="apl:listSubClasses($forClass)" as="attribute()*"/>
                <!-- add subclasses as forClass -->
                <xsl:for-each select="distinct-values($subclasses)[not(. = $forClass)]">
                    <input type="hidden" class="forClass" value="{.}"/>
                </xsl:for-each>
                <!-- bs2:Constructor sets forClass -->
                <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="bs2:Constructor">
                    <xsl:with-param name="subclasses" select="$subclasses"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <input type="hidden" class="forClass" value="{$forClass}"/> <!-- required by ?Type FILTER -->
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="not($type = 'hidden') and $type-label">
            <span class="help-inline">
                <xsl:choose>
                    <xsl:when test="doc-available(ac:document-uri($forClass))">
                        <xsl:choose>
                            <xsl:when test="$forClass = '&rdfs;Resource'">Resource</xsl:when>
                            <xsl:when test="doc-available(ac:document-uri($forClass)) and key('resources', $forClass, document(ac:document-uri($forClass)))">
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
        </xsl:if>
    </xsl:template>
    
    <!-- PROPERTY CONTROL -->
    
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="bs2:PropertyControl">
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="label" select="true()" as="xs:boolean"/>
        <xsl:param name="template" as="element()*"/>
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="for" select="generate-id((node() | @rdf:resource | @rdf:nodeID)[1])" as="xs:string"/>
        <xsl:param name="forClass" as="xs:anyURI*"/>

        <div class="control-group">
            <span class="control-label">
                <select class="input-medium">
                    <!-- group properties by URI - there might be duplicates in the constructor -->
                    <xsl:for-each-group select="$template/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="ac:property-label(.)"/>
                        <xsl:variable name="this" select="xs:anyURI(current-grouping-key())" as="xs:anyURI"/>
                        <xsl:variable name="available" select="doc-available(ac:document-uri($this))" as="xs:boolean"/>
                        <xsl:choose use-when="system-property('xsl:product-name') = 'SAXON'">
                            <xsl:when test="$available and key('resources', $this, document(ac:document-uri($this)))">
                                <xsl:apply-templates select="key('resources', $this, document(ac:document-uri($this)))" mode="xhtml:Option">
                                    <!-- <xsl:with-param name="selected" select="@rdf:about = $this"/> -->
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <option value="{current-grouping-key()}">
                                    <xsl:value-of select="local-name()"/>
                                </option>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:for-each use-when="system-property('xsl:product-name') eq 'Saxon-JS'" select=".">
                            <option value="{current-grouping-key()}">
                                <xsl:value-of select="local-name()"/>
                            </option>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </select>
            </span>

            <div class="controls">
                <!-- $forClass value is used in client.xsl -->
                <xsl:for-each select="$forClass">
                    <input type="hidden" name="forClass" value="."/>
                </xsl:for-each>
                <button type="button" id="button-{generate-id()}" class="btn add-value">
                    <xsl:apply-templates select="key('resources', 'add', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                        <xsl:with-param name="class" select="'btn add-value'"/>
                    </xsl:apply-templates>
                </button>
            </div>
        </div>
    </xsl:template>
    
    <!-- CONSTRUCTOR -->
    
    <xsl:template match="*[@rdf:about]" mode="bs2:Constructor">
        <xsl:param name="id" select="concat('constructor-', generate-id())" as="xs:string?"/>
        <xsl:param name="subclasses" as="attribute()*"/>
        <xsl:param name="with-label" select="false()" as="xs:boolean"/>
        <xsl:variable name="forClass" select="@rdf:about" as="xs:anyURI"/>

        <xsl:if test="doc-available(ac:document-uri($forClass))">
            <!-- this is used for typeahead's FILTER ?Type -->
            <input type="hidden" class="forClass" value="{$forClass}"/>

            <!-- if $forClass subclasses are provided, render a dropdown with multiple constructor choices. Otherwise, only render a single constructor button for $forClass -->
            <xsl:choose>
                <xsl:when test="exists($subclasses)">
                    <div class="btn-group">
                        <button type="button">
                            <xsl:choose>
                                <xsl:when test="$with-label">
                                    <xsl:apply-templates select="." mode="apl:logo">
                                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                    </xsl:apply-templates>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of>
                                        <xsl:apply-templates select="." mode="ac:label"/>
                                    </xsl:value-of>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                                        <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                                    </xsl:apply-templates>
                                </xsl:otherwise>
                            </xsl:choose>
                        </button>
                        <ul class="dropdown-menu">
                            <xsl:variable name="self-and-subclasses" select="key('resources', $forClass, document(ac:document-uri($forClass))), $subclasses/.." as="element()*"/>

                            <!-- apply on the "deepest" subclass of $forClass and its subclasses -->
                            <!-- eliminate matches where a class is a subclass of itself (happens in inferenced ontology models) -->
                            <xsl:for-each-group select="$self-and-subclasses[let $about := @rdf:about return not($about = $self-and-subclasses[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)]" group-by="@rdf:about">
                                <xsl:sort select="ac:label(.)" order="ascending" lang="{$ldt:lang}"/>

                                <!-- won't traverse blank nodes, only URI resources -->
                                <xsl:variable name="action" select="current-group()/rdfs:subClassOf/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())/owl:allValuesFrom/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())/rdfs:subClassOf/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())/owl:hasValue/@rdf:resource" as="xs:anyURI?"/>
                                <li>
                                    <button type="button" class="btn add-constructor" title="{current-grouping-key()}">
                                        <xsl:if test="$id">
                                            <xsl:attribute name="id" select="$id"/>
                                        </xsl:if>
                                        <input type="hidden" class="action" value="{ac:build-uri(if ($action) then $action else $ac:uri, map{ 'forClass': string(current-grouping-key()), 'mode': '&ac;ModalMode' })}"/>

                                        <xsl:value-of>
                                            <xsl:apply-templates select="." mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                </li>
                            </xsl:for-each-group>
                        </ul>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="self" select="key('resources', $forClass, document(ac:document-uri($forClass)))" as="element()*"/>
                    <!-- won't traverse blank nodes, only URI resources -->
                    <xsl:variable name="action" select="$self/rdfs:subClassOf/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())/owl:allValuesFrom/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())/rdfs:subClassOf/@rdf:resource/(if (doc-available(ac:document-uri(.))) then key('resources', ., document(ac:document-uri(.))) else ())/owl:hasValue/@rdf:resource" as="xs:anyURI?"/>
                    <button type="button" title="{@rdf:about}">
                        <xsl:if test="$id">
                            <xsl:attribute name="id" select="$id"/>
                        </xsl:if>

                        <xsl:choose>
                            <xsl:when test="$with-label">
                                <xsl:apply-templates select="." mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn add-constructor'"/>
                                </xsl:apply-templates>

                                <xsl:value-of>
                                    <xsl:apply-templates select="." mode="ac:label"/>
                                </xsl:value-of>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo">
                                    <xsl:with-param name="class" select="'btn add-constructor'"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>

                        <input type="hidden" class="action" value="{ac:build-uri(if ($action) then $action else $ac:uri, map{ 'forClass': string(@rdf:about), 'mode': '&ac;ModalMode' })}"/>
                    </button>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- WYSIWYG editor for XMLLiteral objects -->

    <xsl:template match="*[@rdf:*[local-name() = 'parseType'] = 'Literal']/xhtml:*" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>

        <textarea name="ol" id="{$id}" class="wymeditor">
            <xsl:apply-templates select="xhtml:*" mode="xml-to-string"/>
        </textarea>
        <xsl:call-template name="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
            <xsl:with-param name="name" select="'lt'"/>
            <xsl:with-param name="value" select="'&rdf;XMLLiteral'"/>
        </xsl:call-template>
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
    
    <xsl:template match="*" mode="apl:XHTMLContent" priority="1">
        <xsl:element name="{name()}">
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="@* | node()" mode="apl:XHTMLContent">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>