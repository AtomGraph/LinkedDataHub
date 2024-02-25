<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:variable name="constructor-query" as="xs:string">
        <![CDATA[
            PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX sp:   <http://spinrdf.org/sp#>
            PREFIX spin: <http://spinrdf.org/spin#>

            SELECT  ?constructor ?construct
            WHERE
              { $Type (rdfs:subClassOf)*/spin:constructor  ?constructor .
                ?constructor sp:text ?construct .
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="shape-query" as="xs:string">
        <![CDATA[
            PREFIX  sh:   <http://www.w3.org/ns/shacl#>

            DESCRIBE $Shape ?property
            WHERE
              { $Shape  sh:targetClass  $Type
                OPTIONAL
                  { $Shape  sh:property  ?property }
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="type-graph-query" as="xs:string">
        <![CDATA[
            SELECT DISTINCT  ?graph
            WHERE
              { GRAPH ?graph
                  { $Type  ?p  ?o }
              }
        ]]>
    </xsl:variable>
    <xsl:variable name="constructor-update-string" as="xs:string">
        <![CDATA[
            PREFIX sp: <http://spinrdf.org/sp#>

            DELETE
            {
                $this sp:text ?oldText .
            }
            INSERT
            {
                $this sp:text $text .
            }
            WHERE
            {
                OPTIONAL
                {
                    $this sp:text ?oldText .
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="constructor-insert-string" as="xs:string">
        <![CDATA[
            PREFIX spin: <http://spinrdf.org/spin#>

            INSERT
            {
                $Type spin:constructor $this .
            }
            WHERE
            {
                $Type ?p ?o .
            }
        ]]>
    </xsl:variable>
    
    <!-- TEMPLATES -->

    <xsl:template name="ldh:LoadConstructors">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="type" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:variable name="container" select="." as="element()"/>
        
        <ixsl:set-style name="cursor" select="'progress'" object="."/>

        <xsl:variable name="query-string" select="replace($constructor-query, '$Type', '&lt;' || $type || '&gt;', 'q')" as="xs:string"/>
        <!-- ldh:query-result function does the same synchronously -->
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                <xsl:call-template name="ldh:ConstructorMode">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="type" select="$type"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- render constructor template -->
    <xsl:template name="ldh:ConstructorMode">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="type" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:variable name="constructors" select="?body" as="document-node()"/>
                
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <div class="modal modal-constructor fade in">
                            <form class="form-horizontal constructor-template" about="{$type}">
                                <div class="modal-header">
                                    <button type="button" class="close">&#215;</button>

                                    <h3>
                                        <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': 'DESCRIBE &lt;' || $type || '&gt;', 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                                        <xsl:apply-templates select="key('resources', $type, document(ac:document-uri($request-uri)))" mode="ac:label"/>
                                    </h3>
                                </div>
                                <div class="modal-body">
                                    <xsl:for-each select="$constructors//srx:result">
                                        <xsl:variable name="constructor-uri" select="srx:binding[@name = 'constructor']/srx:uri" as="xs:anyURI"/>
                                        <xsl:variable name="construct-string" select="srx:binding[@name = 'construct']/srx:literal" as="xs:string"/>
                                        <!--<xsl:message>$construct-string: <xsl:value-of select="serialize($construct-string)"/></xsl:message>-->
                                        <xsl:variable name="construct-json" as="item()">
                                            <xsl:variable name="construct-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromString', [ $construct-string ])"/>
                                            <xsl:sequence select="ixsl:call($construct-builder, 'build', [])"/>
                                        </xsl:variable>
                                        <xsl:variable name="construct-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $construct-json ])" as="xs:string"/>
                                        <xsl:variable name="construct-xml" select="json-to-xml($construct-json-string)" as="document-node()"/>

                                        <xsl:call-template name="ldh:ConstructorFieldset">
                                            <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                                            <xsl:with-param name="construct-xml" select="$construct-xml"/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                    
                                    <p>
                                        <button type="button" class="btn btn-primary create-action add-constructor">
                                            <xsl:value-of>
                                                <xsl:apply-templates select="key('resources', 'constructor', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                            </xsl:value-of>
                                        </button>
                                    </p>
                                </div>
                                <div class="form-actions modal-footer">
                                    <button type="button" class="btn btn-primary btn-save">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                    <button type="button" class="btn btn-close">
                                        <xsl:value-of>
                                            <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                        </xsl:value-of>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </xsl:result-document>
                 </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ 'Could not load constructors for class &quot;' || $type || '&quot;' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>

    <xsl:template match="json:array[@key = 'template']/json:map[json:string[@key = 'subject'] = '?this']" mode="bs2:ConstructorTripleForm" priority="1">
        <xsl:param name="class" select="'control-group constructor-triple'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            
            <xsl:apply-templates select="json:string[@key = 'predicate']" mode="ldh:ConstructorTripleFormControl"/>
            
            <xsl:apply-templates select="json:string[@key = 'object']" mode="ldh:ConstructorTripleFormControl"/>
        </div>
    </xsl:template>
    
    <xsl:template match="*" mode="bs2:ConstructorTripleForm"/>
    
    <xsl:template match="json:map/json:string[@key = 'predicate']" mode="ldh:ConstructorTripleFormControl" name="ldh:ConstructorPredicate">
        <xsl:param name="predicate" select="." as="xs:anyURI?"/>

        <label class="control-label">
            <xsl:choose>
                <xsl:when test="$predicate">
                    <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': 'DESCRIBE &lt;' || $predicate || '&gt;', 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                    <xsl:apply-templates select="key('resources', $predicate, document($request-uri))" mode="ldh:Typeahead">
                        <xsl:with-param name="class" select="'btn add-typeahead add-property-typeahead'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>

                    <xsl:call-template name="bs2:Lookup">
                        <xsl:with-param name="forClass" select="xs:anyURI('&rdf;Property')"/>
                        <xsl:with-param name="class" select="'property-typeahead typeahead'"/>
                        <xsl:with-param name="id" select="'input-' || $uuid"/>
                        <xsl:with-param name="list-class" select="'property-typeahead typeahead dropdown-menu'"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

            <!-- used by typeahead to set $Type -->
            <!-- <input type="hidden" class="forClass" value="&rdf;Property" autocomplete="off"/> -->
        </label>
    </xsl:template>
    
    <xsl:template match="json:map/json:string[@key = 'object']" mode="ldh:ConstructorTripleFormControl" name="ldh:ConstructorObject">
        <xsl:param name="object-bnode-id" select="." as="xs:string"/>
        <xsl:param name="object-type" select="../../json:map[json:string[@key = 'subject'] = $object-bnode-id]/json:string[@key = 'object']" as="xs:anyURI?"/>

        <div class="controls">
            <div class="btn-group pull-right">
                <button type="button" class="btn btn-small pull-right btn-remove-property">
                    <xsl:attribute name="title">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'remove-stmt', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </xsl:attribute>
                </button>
            </div>
                    
            <label class="radio">
                <input type="radio" class="object-kind" name="{generate-id()}-object-kind" value="&rdfs;Resource" checked="checked">
                    <xsl:if test="not(starts-with($object-type, '&xsd;'))">
                        <xsl:attribute name="checked" select="'checked'"/>
                    </xsl:if>
                </input>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'resource', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:value-of>
            </label>
            <label class="radio">
                <input type="radio" class="object-kind" name="{generate-id()}-object-kind" value="&rdfs;Literal">
                    <xsl:if test="starts-with($object-type, '&xsd;')">
                        <xsl:attribute name="checked" select="'checked'"/>
                    </xsl:if>
                </input>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', 'literal', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                </xsl:value-of>
            </label>

            <span class="help-inline">
                <xsl:choose>
                    <xsl:when test="starts-with($object-type, '&xsd;')">
                        <xsl:call-template name="ldh:ConstructorLiteralObject">
                            <xsl:with-param name="object-type" select="$object-type"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="ldh:ConstructorResourceObject">
                            <xsl:with-param name="object-type" select="$object-type"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
        </div>
    </xsl:template>
    
    <xsl:template name="ldh:ConstructorFieldset">
        <xsl:param name="constructor-uri" as="xs:anyURI"/>
        <xsl:param name="construct-xml" as="document-node()?"/>

        <fieldset about="{$constructor-uri}">
            <legend>
                <a href="{$constructor-uri}" title="{$constructor-uri}" target="_blank">
                    <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': 'DESCRIBE &lt;' || $constructor-uri || '&gt;', 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                    <xsl:apply-templates select="key('resources', $constructor-uri, document($request-uri))" mode="ac:label"/>
                </a>
            </legend>

            <xsl:apply-templates select="$construct-xml/json:map/json:array[@key = 'template']/json:map" mode="bs2:ConstructorTripleForm">
                <xsl:sort select="json:string[@key = 'predicate']"/>
            </xsl:apply-templates>

            <div class="control-group">
                <label class="control-label">
                    <button type="button" class="btn btn-primary create-action add-triple-template">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', '&rdf;Property', document(ac:document-uri('&rdf;')))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </label>
                <div class="controls"></div>
            </div>
        </fieldset>
    </xsl:template>

    <xsl:template name="ldh:ConstructorLiteralObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>
        
        <select name="ou">
            <option value="&xsd;string">
                <xsl:if test="$object-type = '&xsd;string'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>
                    
                <xsl:text>String</xsl:text>
            </option>
            <option value="&xsd;boolean">
                <xsl:if test="$object-type = '&xsd;boolean'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Boolean</xsl:text>
            </option>
            <option value="&xsd;date">
                <xsl:if test="$object-type = '&xsd;date'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Date</xsl:text>
            </option>
            <option value="&xsd;dateTime">
                <xsl:if test="$object-type = '&xsd;dateTime'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Datetime</xsl:text>
            </option>
            <option value="&xsd;integer">
                <xsl:if test="$object-type = '&xsd;integer'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Integer</xsl:text>
            </option>
            <option value="&xsd;float">
                <xsl:if test="$object-type = '&xsd;float'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Float</xsl:text>
            </option>
            <option value="&xsd;double">
                <xsl:if test="$object-type = '&xsd;double'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Double</xsl:text>
            </option>
            <option value="&xsd;decimal">
                <xsl:if test="$object-type = '&xsd;decimal'">
                    <xsl:attribute name="selected" select="'selected'"/>
                </xsl:if>

                <xsl:text>Decimal</xsl:text>
            </option>
        </select>
    </xsl:template>
    
    <xsl:template name="ldh:ConstructorResourceObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="$object-type">
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': 'DESCRIBE &lt;' || $object-type || '&gt;', 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                <xsl:apply-templates select="key('resources', $object-type, document($request-uri))" mode="ldh:Typeahead">
                    <xsl:with-param name="class" select="'btn add-typeahead add-class-typeahead'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>

                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="forClass" select="xs:anyURI('&rdfs;Class')"/>
                    <xsl:with-param name="class" select="'class-typeahead typeahead'"/>
                    <xsl:with-param name="id" select="'input-' || $uuid"/>
                    <xsl:with-param name="list-class" select="'class-typeahead typeahead dropdown-menu'"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- used by typeahead to set $Type -->
        <!-- <input type="hidden" class="forClass" value="&rdfs;Class" autocomplete="off"/> -->
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
    <!-- open modal form with constructor editing mode -->
    <xsl:template match="button[contains-token(@class, 'btn-edit-constructors')]" mode="ixsl:onclick">"
        <xsl:variable name="type" select="ixsl:get(., 'dataset.resourceType')" as="xs:anyURI"/>

        <xsl:for-each select="ixsl:page()//body">
            <xsl:call-template name="ldh:LoadConstructors">
                <xsl:with-param name="type" select="$type"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <!-- classes and properties are looked up in the <ns> endpoint -->
    <xsl:template match="input[contains-token(@class, 'class-typeahead')] | input[contains-token(@class, 'property-typeahead')]" mode="ixsl:onkeyup" priority="1">
        <xsl:next-match>
            <xsl:with-param name="endpoint" select="resolve-uri('ns', $ldt:base)"/>
            <xsl:with-param name="select-string" select="$select-labelled-string"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'class-typeahead')]/li" mode="ixsl:onmousedown" priority="2">
        <xsl:next-match>
            <xsl:with-param name="typeahead-class" select="'btn add-typeahead add-class-typeahead'"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="ul[contains-token(@class, 'dropdown-menu')][contains-token(@class, 'property-typeahead')]/li" mode="ixsl:onmousedown" priority="2">
        <xsl:next-match>
            <xsl:with-param name="typeahead-class" select="'btn add-typeahead add-property-typeahead'"/>
        </xsl:next-match>
    </xsl:template>

    <!-- special case for class lookups -->
    <xsl:template match="button[contains-token(@class, 'add-class-typeahead')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'class-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'class-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>

    <!-- special case for property lookups -->
    <xsl:template match="button[contains-token(@class, 'add-property-typeahead')]" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'property-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'property-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>

    <!-- toggles object type control depending on the object kind -->
    <xsl:template match="input[@type = 'radio'][contains-token(@class, 'object-kind')]" mode="ixsl:onchange">
        <xsl:variable name="object-kind" select="ixsl:get(., 'value')" as="xs:anyURI"/>
        
        <xsl:for-each select="ancestor::div[contains-token(@class, 'controls')]/span[@class = 'help-inline']">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:if test="$object-kind = '&rdfs;Resource'">
                    <xsl:call-template name="ldh:ConstructorResourceObject"/>
                </xsl:if>
                <xsl:if test="$object-kind = '&rdfs;Literal'">
                    <xsl:call-template name="ldh:ConstructorLiteralObject"/>
                </xsl:if>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- appends new triple template -->
    <xsl:template match="div[contains-token(@class, 'control-group')]//button[contains-token(@class, 'create-action')][contains-token(@class, 'add-triple-template')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'control-group')]" as="element()"/>
        <xsl:variable name="controls" as="node()*">
            <xsl:call-template name="ldh:ConstructorPredicate">
                <xsl:with-param name="predicate" select="()"/>
            </xsl:call-template>
            
            <xsl:call-template name="ldh:ConstructorObject">
                <xsl:with-param name="object-type" select="()"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- move the current row of controls to the bottom of the content list -->
        <xsl:for-each select="$container/..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select="$container"/>
            </xsl:result-document>
        </xsl:for-each>

        <!-- add .constructor-triple to div.control-group -->
        <xsl:for-each select="$container">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'constructor-triple', true() ])[current-date() lt xs:date('2000-01-01')]"/>

            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$controls"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- appends new constructor -->
    <xsl:template match="div[contains-token(@class, 'modal-body')]//button[contains-token(@class, 'create-action')][contains-token(@class, 'add-constructor')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'modal-body')]" as="element()"/>
        <xsl:variable name="button-div" select=".." as="element()"/>
        <xsl:variable name="type" select="ancestor::form/@about" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:variable name="query-string" select="replace($type-graph-query, '$Type', '&lt;' || $type || '&gt;', 'q')" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri(resolve-uri('admin/sparql', $ldt:base), map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, $results-uri)" as="xs:anyURI"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $results-uri, 'headers': map{ 'Accept': 'application/sparql-results+xml' } }">
                <xsl:call-template name="onTypeGraphLoad">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="button-div" select="$button-div"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- save constructor form onclick. Validate it before update updating constructors -->
    <xsl:template match="form[contains-token(@class, 'constructor-template')]//div[contains-token(@class, 'form-actions')]/button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="form" select="ancestor::form" as="element()"/>
        <xsl:variable name="type" select="$form/@about" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:variable name="control-groups" select="$form/descendant::div[contains-token(@class, 'control-group')]" as="element()*"/>

        <xsl:choose>
            <!-- input values missing, throw an error -->
            <xsl:when test="exists($control-groups/descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))])">
                <xsl:sequence select="$control-groups[descendant::input[@name = ('ol', 'ou')][not(ixsl:get(., 'value'))]]/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'error', true() ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- all required values present, proceed to update the constructors -->
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:for-each select="$form//fieldset">
                    <xsl:variable name="container" select="." as="element()"/>
                    <xsl:variable name="constructor-uri" select="@about" as="xs:anyURI"/>
                    <xsl:variable name="construct-xml" as="document-node()">
                        <!-- not all controls might have value, filter to those that have -->
                        <xsl:iterate select="./div[contains-token(@class, 'control-group')][label//input[@name = 'ou']/@value][./div[contains-token(@class, 'controls')]//input[@name = 'ou']/@value or ./div[contains-token(@class, 'controls')]//select[@name = 'ou']]">
                            <xsl:param name="construct-xml" as="document-node()">
                                <xsl:document>
                                    <json:map>
                                        <json:string key="queryType">CONSTRUCT</json:string>
                                        <json:array key="template"/>
                                        <json:array key="where"/>
                                        <json:string key="type">query</json:string>
                                        <json:map key="prefixes"/>
                                    </json:map>
                                </xsl:document>
                            </xsl:param>

                            <xsl:on-completion>
                                <xsl:sequence select="$construct-xml"/>
                            </xsl:on-completion>

                            <xsl:next-iteration>
                                <xsl:with-param name="construct-xml">
                                    <xsl:apply-templates select="$construct-xml" mode="ldh:add-constructor-triple">
                                        <xsl:with-param name="predicate" select="label//input[@name = 'ou']/@value/xs:anyURI(.)" tunnel="yes"/>
                                        <xsl:with-param name="object-type" select="(./div[contains-token(@class, 'controls')]//input[@name = 'ou']/@value/xs:anyURI(.), xs:anyURI(./div[contains-token(@class, 'controls')]//select[@name = 'ou']/ixsl:get(., 'value')))[1]" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:with-param>
                            </xsl:next-iteration>
                        </xsl:iterate>
                    </xsl:variable>
                    <xsl:variable name="construct-json-string" select="xml-to-json($construct-xml)" as="xs:string"/>
                    <xsl:variable name="construct-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $construct-json-string ])"/>
                    <xsl:variable name="construct-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromQuery', [ $construct-json ]), 'toString', [])" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($constructor-update-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$text', '&quot;&quot;&quot;' || $construct-string || '&quot;&quot;&quot;', 'q')" as="xs:string"/>
                    <!-- what if the constructor URI is not relative to the document URI? -->
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:document-uri($constructor-uri))" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="onConstructorUpdate">
                                <xsl:with-param name="container" select="$container"/>
                                <xsl:with-param name="type" select="$type"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <xsl:template name="onConstructorUpdate">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="type" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <xsl:for-each select="$container">
                    <xsl:call-template name="ldh:CloseModal"/>
                </xsl:for-each>
                
                <!-- clear the ontology. TO-DO: only clear after *all* constructors are saved: https://saxonica.plan.io/issues/5596 -->
                <!-- TO-DO: make sure we're in the end-user application -->
                <xsl:variable name="namespace" select="xs:anyURI(if (contains($type, '#')) then substring-before($type, '#') || '#' else string-join(tokenize($type, '/')[not(position() = last())], '/') || '/')" as="xs:anyURI"/>
                <!-- query NS ontology to retrieve the ontology URI from the $type class' rdfs:isDefinedBy value. Fallback to the assumed $type's namespace URI -->
                <xsl:variable name="request-uri" select="ac:build-uri(resolve-uri('ns', $ldt:base), map{ 'query': 'DESCRIBE &lt;' || $type || '&gt;', 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>
                <xsl:variable name="ontology-uri" select="(key('resources', $type, document(ac:document-uri($request-uri)))/rdfs:isDefinedBy/@rdf:resource, $namespace)[1]" as="xs:anyURI"/>
                <xsl:variable name="form-data" select="ldh:new('URLSearchParams', [ ldh:new('FormData', []) ])"/>
                <xsl:sequence select="ixsl:call($form-data, 'append', [ 'uri', $ontology-uri ])[current-date() lt xs:date('2000-01-01')]"/>

                <!-- clear this ontology first, then proceed to clear the namespace ontology -->
                <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': resolve-uri('admin/clear', ldt:base()), 'media-type': 'application/x-www-form-urlencoded', 'body': $form-data, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="ldh:ClearNamespace"/>
                </ixsl:schedule-action>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not update constructor' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onTypeGraphLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="type" as="xs:anyURI"/> <!-- the URI of the class that constructors are attached to -->
        <xsl:param name="button-div" as="element()"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/sparql-results+xml'">
                <xsl:for-each select="?body">
                    <xsl:for-each select="//srx:result">
                        <xsl:variable name="graph" select="srx:binding[@name = 'graph']/srx:uri" as="xs:anyURI"/>
                        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
                        <xsl:variable name="constructor-uri" select="xs:anyURI($graph || '#id' || $uuid)" as="xs:anyURI"/>
                        <xsl:variable name="update-string" select="replace($constructor-insert-string, '$this', '&lt;' || $constructor-uri || '&gt;', 'q')" as="xs:string"/>
                        <xsl:variable name="update-string" select="replace($update-string, '$Type', '&lt;' || $type || '&gt;', 'q')" as="xs:string"/>
                        <!-- what if the constructor URI is not relative to the document URI? -->
                        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path(ldh:base-uri(.)), map{}, ac:document-uri($constructor-uri))" as="xs:anyURI"/>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                                <xsl:call-template name="onConstructorAppend">
                                    <xsl:with-param name="container" select="$container"/>
                                    <xsl:with-param name="button-div" select="$button-div"/>
                                    <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not load ontology graph URI(s)' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onConstructorAppend">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="button-div" as="element()"/>
        <xsl:param name="constructor-uri" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="?status = 200">
                <!-- remove the "Add constructor" button -->
                <xsl:for-each select="$button-div">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
                
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <xsl:call-template name="ldh:ConstructorFieldset">
                            <xsl:with-param name="constructor-uri" select="$constructor-uri"/>
                        </xsl:call-template>
                        
                        <!-- re-append the "Add constructor" button at the bottom of the form -->
                        <xsl:copy-of select="$button-div"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not append constructor' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <xsl:template name="ldh:ClearNamespace">
        <xsl:param name="ontology-uri" select="resolve-uri('ns#', ldt:base())" as="xs:anyURI"/>
        <xsl:variable name="form-data" select="ldh:new('URLSearchParams', [ ldh:new('FormData', []) ])"/>
        <xsl:sequence select="ixsl:call($form-data, 'append', [ 'uri', $ontology-uri ])[current-date() lt xs:date('2000-01-01')]"/>

        <ixsl:schedule-action http-request="map{ 'method': 'POST', 'href': resolve-uri('admin/clear', ldt:base()), 'media-type': 'application/x-www-form-urlencoded', 'body': $form-data, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
            <!-- bogus template call required because of Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5597 -->
            <xsl:call-template name="ldh:NoOp"/>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template name="ldh:NoOp"/>
    
</xsl:stylesheet>