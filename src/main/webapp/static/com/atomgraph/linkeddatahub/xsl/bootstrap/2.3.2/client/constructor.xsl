<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh        "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs       "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd        "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt        "https://www.w3.org/ns/ldt#">
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
xmlns:ldt="&ldt;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->

    <!-- render constructor template -->

    <xsl:template name="ldh:LoadConstructor">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="uri" as="xs:anyURI"/> <!-- document URI -->
        <xsl:param name="acl-modes" as="xs:anyURI*"/>
        <xsl:variable name="constructor-uri" select="@about" as="xs:anyURI"/>
        <xsl:variable name="construct-string" select="input[@name = 'construct-string']/@value" as="xs:string"/>
        <!--<xsl:message>$construct-string: <xsl:value-of select="serialize($construct-string)"/></xsl:message>-->
        <xsl:variable name="construct-json" as="item()">
            <xsl:variable name="construct-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'QueryBuilder'), 'fromString', [ $construct-string ])"/>
            <xsl:sequence select="ixsl:call($construct-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="construct-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $construct-json ])" as="xs:string"/>
        <xsl:variable name="construct-xml" select="json-to-xml($construct-json-string)" as="document-node()"/>
        
        <xsl:result-document href="?." method="ixsl:replace-content">
            <div class="offset2 span7">
                <form class="form-horizontal" about="{$constructor-uri}">
                    <fieldset>
                        <legend>
                            <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': ac:document-uri($constructor-uri), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                            <xsl:apply-templates select="key('resources', $constructor-uri, document($request-uri))" mode="ac:label"/>
                        </legend>
                        
                        <xsl:apply-templates select="$construct-xml/json:map/json:array[@key = 'template']/json:map" mode="bs2:ConstructorTripleForm">
                            <xsl:sort select="json:string[@key = 'predicate']"/>
                        </xsl:apply-templates>

                        <div class="control-group">
                            <label class="control-label">
                                <button type="button" class="btn btn-primary create-action add-triple-template">Triple template</button>
                            </label>
                            <div class="controls"></div>
                        </div>
                    </fieldset>

                    <div class="form-actions">
                        <button type="button" class="btn btn-primary btn-save">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="button" class="btn btn-delete">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'delete', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                        <button type="button" class="btn btn-cancel">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </form>
            </div>
        </xsl:result-document>
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
                    <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': ac:document-uri($predicate), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                    <span>
                        <xsl:apply-templates select="key('resources', $predicate, document($request-uri))" mode="ldh:Typeahead">
                            <xsl:with-param name="class" select="'btn add-typeahead add-property-typeahead'"/>
                        </xsl:apply-templates>
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>

                    <xsl:call-template name="bs2:Lookup">
                        <xsl:with-param name="class" select="'property-typeahead typeahead'"/>
                        <xsl:with-param name="id" select="'input-' || $uuid"/>
                        <xsl:with-param name="list-class" select="'property-typeahead typeahead dropdown-menu'"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

            <!-- used by typeahead to set $Type -->
            <input type="hidden" class="forClass" value="&rdf;Property" autocomplete="off"/>
        </label>
    </xsl:template>
    
    <xsl:template match="json:map/json:string[@key = 'object']" mode="ldh:ConstructorTripleFormControl" name="ldh:ConstructorObject">
        <xsl:param name="object-bnode-id" select="." as="xs:string"/>
        <xsl:param name="object-type" select="../../json:map[json:string[@key = 'subject'] = $object-bnode-id]/json:string[@key = 'object']" as="xs:anyURI?"/>

        <div class="controls">
            <div class="btn-group pull-right">
                <button type="button" class="btn btn-small pull-right btn-remove-property" title="Remove this statement"></button>
            </div>
                    
            <label class="radio">
                <input type="radio" class="object-kind" name="{generate-id()}-object-kind" value="&rdfs;Resource" checked="checked"/>
                <xsl:text>Resource</xsl:text>
            </label>
            <label class="radio">
                <input type="radio" class="object-kind" name="{generate-id()}-object-kind" value="&rdfs;Literal"/>
                <xsl:text>Literal</xsl:text>
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
    
    <xsl:template name="ldh:ConstructorLiteralObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>
        
        <select>
            <option value="&xsd;string">
                <xsl:text>String</xsl:text>
            </option>
            <option value="&xsd;boolean">
                <xsl:text>Boolean</xsl:text>
            </option>
            <option value="&xsd;date">
                <xsl:text>Date</xsl:text>
            </option>
            <option value="&xsd;dateTime">
                <xsl:text>Datetime</xsl:text>
            </option>
            <option value="&xsd;integer">
                <xsl:text>Integer</xsl:text>
            </option>
            <option value="&xsd;float">
                <xsl:text>Float</xsl:text>
            </option>
            <option value="&xsd;double">
                <xsl:text>Double</xsl:text>
            </option>
            <option value="&xsd;decimal">
                <xsl:text>Decimal</xsl:text>
            </option>
        </select>
    </xsl:template>
    
    <xsl:template name="ldh:ConstructorResourceObject">
        <xsl:param name="object-type" as="xs:anyURI?"/>

        <span>
            <xsl:choose>
                <xsl:when test="$object-type">
                    <xsl:variable name="request-uri" select="ac:build-uri($ldt:base, map{ 'uri': ac:document-uri($object-type), 'accept': 'application/rdf+xml' })" as="xs:anyURI"/>

                    <xsl:apply-templates select="key('resources', $object-type, document($request-uri))" mode="ldh:Typeahead">
                        <xsl:with-param name="class" select="'btn add-typeahead add-class-typeahead'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>

                    <xsl:call-template name="bs2:Lookup">
                        <xsl:with-param name="class" select="'class-typeahead typeahead'"/>
                        <xsl:with-param name="id" select="'input-' || $uuid"/>
                        <xsl:with-param name="list-class" select="'class-typeahead typeahead dropdown-menu'"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </span>
        
        <!-- used by typeahead to set $Type -->
        <input type="hidden" class="forClass" value="&rdfs;Class" autocomplete="off"/>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
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
    
    <!-- appends new resource content instance to the content list -->
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
    
    <!-- save constructor form onclick -->
    <xsl:template match="div[contains-token(@class, 'constructor-template')]//div[contains-token(@class, 'form-actions')]/button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="form" select="ancestor::form" as="element()"/>
        <xsl:variable name="construct-xml" as="document-node()">
            <xsl:document>
                <json:map>
                    <json:string key="queryType">CONSTRUCT</json:string>
                    <json:array key="template"/>
                    <json:array key="where"/>
                    <json:string key="type">query</json:string>
                    <json:map key="prefixes"/>
                </json:map>
            </xsl:document>
        </xsl:variable>
        
        <xsl:variable name="construct-xml" as="document-node()">
            <xsl:document>
                <!-- not all controls might have value, filter to those that have -->
                <xsl:iterate select="$form//div[contains-token(@class, 'control-group')][label/input[@name = 'ou']/@value][div[contains-token(@class, 'controls')]//input[@name = 'ou']/@value]">
                    <xsl:param name="construct-xml" select="$construct-xml" as="document-node()"/>
                    <xsl:param name="predicate" as="xs:anyURI?"/>
                    <xsl:param name="object-type" as="xs:anyURI?"/>

                    <xsl:on-completion>
                        <xsl:sequence select="$construct-xml"/>
                    </xsl:on-completion>

                    <xsl:next-iteration>
                        <xsl:with-param name="construct-xml">
                            <xsl:apply-templates select="$construct-xml" mode="ldh:add-constructor-triple">
                                <xsl:with-param name="predicate" select="label/input[@name = 'ou']/@value"/>
                                <xsl:with-param name="object-type" select="div[contains-token(@class, 'controls')]//input[@name = 'ou']/@value"/>
                            </xsl:apply-templates>
                        </xsl:with-param>
                    </xsl:next-iteration>
                </xsl:iterate>
            </xsl:document>
        </xsl:variable>
        
        <xsl:message>
            $construct-xml: <xsl:value-of select="serialize($construct-xml)"/>
        </xsl:message>
    </xsl:template>
    
</xsl:stylesheet>