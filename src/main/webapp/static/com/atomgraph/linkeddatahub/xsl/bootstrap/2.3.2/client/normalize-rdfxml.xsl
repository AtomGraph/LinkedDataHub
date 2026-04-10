<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
    exclude-result-prefixes="#all"
    version="3.0">

    <!-- Main template - apply three-pass normalization -->
    <xsl:template match="/">
        <xsl:param name="base-uri" select="base-uri(.)" as="xs:anyURI"/>

        <xsl:message>Starting RDF/XML normalization...</xsl:message>
        <xsl:message>Base URI: <xsl:value-of select="$base-uri"/></xsl:message>

        <!-- First pass: normalize RDF/XML to canonical form -->
        <xsl:variable name="normalized-rdf" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="rdf:RDF" mode="ldh:normalize-RDF"/>
            </xsl:document>
        </xsl:variable>

        <xsl:message>First pass (normalize) complete</xsl:message>
        <xsl:message>Normalized RDF has <xsl:value-of select="count($normalized-rdf/rdf:RDF/*)"/> top-level elements</xsl:message>

        <!-- Second pass: flatten all nested rdf:Description to top level -->
        <xsl:variable name="flattened-rdf" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$normalized-rdf/rdf:RDF" mode="ldh:flatten-RDF"/>
            </xsl:document>
        </xsl:variable>

        <xsl:message>Second pass (flatten) complete</xsl:message>
        <xsl:message>Flattened RDF has <xsl:value-of select="count($flattened-rdf/rdf:RDF/rdf:Description)"/> rdf:Description elements</xsl:message>

        <!-- Third pass: resolve relative URIs to absolute URIs -->
        <xsl:variable name="resolved-rdf" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$flattened-rdf/rdf:RDF" mode="ldh:resolve-uris">
                    <xsl:with-param name="base-uri" select="$base-uri" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <xsl:message>Third pass (resolve URIs) complete</xsl:message>

        <xsl:sequence select="$resolved-rdf"/>
    </xsl:template>

    <!-- ========================================
         PASS 1: NORMALIZE RDF/XML SYNTAX
         ======================================== -->

    <!-- Copy rdf:RDF root element -->
    <xsl:template match="rdf:RDF" mode="ldh:normalize-RDF">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Normalize typed nodes (e.g., <foaf:Person>) to rdf:Description with explicit rdf:type -->
    <!-- Also handles rdf:ID attribute -->
    <xsl:template match="rdf:RDF/*[@rdf:about or @rdf:nodeID or @rdf:ID][not(self::rdf:Description)]" mode="ldh:normalize-RDF">
        <rdf:Description>
            <!-- Convert rdf:ID to rdf:about with fragment -->
            <xsl:choose>
                <xsl:when test="@rdf:ID">
                    <xsl:attribute name="rdf:about" select="'#' || @rdf:ID"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="@rdf:about | @rdf:nodeID"/>
                </xsl:otherwise>
            </xsl:choose>

            <rdf:type rdf:resource="{namespace-uri()}{local-name()}"/>

            <!-- Process property attributes -->
            <xsl:for-each select="@*[not(namespace-uri() = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')]">
                <xsl:element name="{name()}" namespace="{namespace-uri()}">
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:for-each>

            <xsl:apply-templates mode="#current"/>
        </rdf:Description>
    </xsl:template>

    <!-- Already-normalized rdf:Description nodes - expand property attributes -->
    <!-- Also handles rdf:ID attribute -->
    <xsl:template match="rdf:Description[@rdf:about or @rdf:nodeID or @rdf:ID]" mode="ldh:normalize-RDF">
        <xsl:copy>
            <!-- Convert rdf:ID to rdf:about with fragment -->
            <xsl:choose>
                <xsl:when test="@rdf:ID">
                    <xsl:attribute name="rdf:about" select="'#' || @rdf:ID"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="@rdf:about | @rdf:nodeID"/>
                </xsl:otherwise>
            </xsl:choose>

            <!-- Process property attributes and convert to elements -->
            <xsl:for-each select="@*[not(namespace-uri() = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')]">
                <xsl:element name="{name()}" namespace="{namespace-uri()}">
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:for-each>

            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Normalize rdf:parseType="Literal" - keep as-is since it's already canonical -->
    <xsl:template match="*[@rdf:parseType = 'Literal']" mode="ldh:normalize-RDF">
        <xsl:copy>
            <xsl:copy-of select="@rdf:parseType"/>
            <!-- Copy the XML content as-is -->
            <xsl:copy-of select="node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Normalize rdf:parseType="Collection" - create RDF list structure -->
    <xsl:template match="*[@rdf:parseType = 'Collection']" mode="ldh:normalize-RDF">
        <xsl:choose>
            <!-- Empty collection -->
            <xsl:when test="not(*)">
                <xsl:copy>
                    <xsl:attribute name="rdf:resource">http://www.w3.org/1999/02/22-rdf-syntax-ns#nil</xsl:attribute>
                </xsl:copy>
            </xsl:when>
            <!-- Non-empty collection - create list structure -->
            <xsl:otherwise>
                <xsl:variable name="list-items" select="*" as="element()*"/>
                <xsl:variable name="first-node-id" select="concat('c', generate-id(), '_1')"/>

                <xsl:copy>
                    <rdf:Description rdf:nodeID="{$first-node-id}">
                        <!-- This will be expanded into the full list structure -->
                        <xsl:call-template name="build-rdf-list">
                            <xsl:with-param name="items" select="$list-items"/>
                            <xsl:with-param name="position" select="1"/>
                            <xsl:with-param name="node-id" select="$first-node-id"/>
                        </xsl:call-template>
                    </rdf:Description>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper template to build RDF list structure -->
    <xsl:template name="build-rdf-list">
        <xsl:param name="items" as="element()*"/>
        <xsl:param name="position" as="xs:integer"/>
        <xsl:param name="node-id" as="xs:string"/>

        <xsl:if test="$position le count($items)">
            <rdf:first>
                <xsl:choose>
                    <!-- Item has rdf:resource attribute -->
                    <xsl:when test="$items[$position]/@rdf:resource">
                        <xsl:attribute name="rdf:resource" select="$items[$position]/@rdf:resource"/>
                    </xsl:when>
                    <!-- Item has rdf:nodeID attribute -->
                    <xsl:when test="$items[$position]/@rdf:nodeID">
                        <xsl:attribute name="rdf:nodeID" select="$items[$position]/@rdf:nodeID"/>
                    </xsl:when>
                    <!-- Item is rdf:Description with rdf:about -->
                    <xsl:when test="$items[$position][self::rdf:Description][@rdf:about]">
                        <xsl:attribute name="rdf:resource" select="$items[$position]/@rdf:about"/>
                    </xsl:when>
                    <!-- Item is rdf:Description with rdf:nodeID -->
                    <xsl:when test="$items[$position][self::rdf:Description][@rdf:nodeID]">
                        <xsl:attribute name="rdf:nodeID" select="$items[$position]/@rdf:nodeID"/>
                    </xsl:when>
                    <!-- Item is rdf:Description with rdf:ID -->
                    <xsl:when test="$items[$position][self::rdf:Description][@rdf:ID]">
                        <xsl:attribute name="rdf:resource" select="'#' || $items[$position]/@rdf:ID"/>
                    </xsl:when>
                    <!-- Nested structure - apply normalization -->
                    <xsl:otherwise>
                        <xsl:apply-templates select="$items[$position]" mode="#current"/>
                    </xsl:otherwise>
                </xsl:choose>
            </rdf:first>

            <xsl:choose>
                <!-- Last item - rest is rdf:nil -->
                <xsl:when test="$position = count($items)">
                    <rdf:rest rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"/>
                </xsl:when>
                <!-- More items - create next list node -->
                <xsl:otherwise>
                    <xsl:variable name="next-node-id" select="concat('c', generate-id(), '_', $position + 1)"/>
                    <rdf:rest>
                        <rdf:Description rdf:nodeID="{$next-node-id}">
                            <xsl:call-template name="build-rdf-list">
                                <xsl:with-param name="items" select="$items"/>
                                <xsl:with-param name="position" select="$position + 1"/>
                                <xsl:with-param name="node-id" select="$next-node-id"/>
                            </xsl:call-template>
                        </rdf:Description>
                    </rdf:rest>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- Normalize rdf:parseType="Resource" - create nested blank node that will be flattened later -->
    <xsl:template match="*[@rdf:parseType = 'Resource']" mode="ldh:normalize-RDF">
        <xsl:variable name="blank-node-id" select="concat('b', generate-id())"/>

        <!-- Create property element with nested blank node rdf:Description -->
        <xsl:element name="{name()}" namespace="{namespace-uri()}">
            <rdf:Description rdf:nodeID="{$blank-node-id}">
                <xsl:apply-templates mode="#current"/>
            </rdf:Description>
        </xsl:element>
    </xsl:template>

    <!-- Copy property elements that have rdf:resource or rdf:nodeID (object references) -->
    <xsl:template match="rdf:Description/*[@rdf:resource or @rdf:nodeID]" mode="ldh:normalize-RDF">
        <xsl:copy>
            <xsl:copy-of select="@rdf:resource | @rdf:nodeID"/>
        </xsl:copy>
    </xsl:template>

    <!-- Handle RDF containers (Bag, Seq, Alt) -->
    <xsl:template match="rdf:Bag | rdf:Seq | rdf:Alt" mode="ldh:normalize-RDF" priority="1">
        <rdf:Description>
            <xsl:copy-of select="@rdf:about | @rdf:nodeID"/>
            <xsl:if test="not(@rdf:about or @rdf:nodeID)">
                <xsl:attribute name="rdf:nodeID" select="concat('b', generate-id())"/>
            </xsl:if>
            <rdf:type rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#{local-name()}"/>
            <xsl:apply-templates mode="#current"/>
        </rdf:Description>
    </xsl:template>

    <!-- Suppress default text node copying for containers -->
    <xsl:template match="rdf:Bag/text() | rdf:Seq/text() | rdf:Alt/text()" mode="ldh:normalize-RDF">
        <!-- Ignore whitespace text nodes in containers -->
        <xsl:if test="normalize-space(.) != ''">
            <xsl:value-of select="."/>
        </xsl:if>
    </xsl:template>

    <!-- Expand rdf:li to rdf:_N based on position -->
    <xsl:template match="rdf:li" mode="ldh:normalize-RDF">
        <xsl:variable name="position" select="count(preceding-sibling::rdf:li) + 1" as="xs:integer"/>
        <xsl:element name="rdf:_{$position}" namespace="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <xsl:copy-of select="@rdf:resource | @rdf:nodeID | @rdf:datatype | @xml:lang"/>
            <xsl:if test="not(@rdf:resource or @rdf:nodeID or @rdf:datatype or @xml:lang)">
                <xsl:value-of select="."/>
            </xsl:if>
            <xsl:if test="*">
                <xsl:apply-templates mode="#current"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <!-- Copy property elements with literal values or datatype -->
    <!-- Preserve xml:lang attribute -->
    <!-- Only match properties with text content, not element children -->
    <xsl:template match="rdf:Description/*[not(@rdf:resource) and not(@rdf:nodeID) and not(@rdf:parseType) and not(*)]" mode="ldh:normalize-RDF">
        <xsl:copy>
            <xsl:copy-of select="@rdf:datatype | @xml:lang"/>
            <xsl:value-of select="."/>
        </xsl:copy>
    </xsl:template>

    <!-- Generic template to handle any property element that doesn't match more specific templates -->
    <!-- This catches property elements from rdf:parseType="Resource" content and rdf:li -->
    <xsl:template match="*[not(self::rdf:RDF) and not(self::rdf:Description) and not(self::rdf:li) and not(self::rdf:Bag) and not(self::rdf:Seq) and not(self::rdf:Alt)]" mode="ldh:normalize-RDF" priority="-1">
        <xsl:choose>
            <!-- Property with rdf:resource or rdf:nodeID -->
            <xsl:when test="@rdf:resource or @rdf:nodeID">
                <xsl:copy>
                    <xsl:copy-of select="@rdf:resource | @rdf:nodeID"/>
                </xsl:copy>
            </xsl:when>
            <!-- Property containing RDF container (Bag, Seq, Alt) -->
            <xsl:when test="rdf:Bag | rdf:Seq | rdf:Alt">
                <xsl:element name="{name()}" namespace="{namespace-uri()}">
                    <xsl:apply-templates select="rdf:Bag | rdf:Seq | rdf:Alt" mode="#current"/>
                </xsl:element>
            </xsl:when>
            <!-- Property with rdf:parseType="Resource" - handle recursively -->
            <xsl:when test="@rdf:parseType = 'Resource'">
                <xsl:variable name="blank-node-id" select="concat('b', generate-id())"/>
                <xsl:element name="{name()}" namespace="{namespace-uri()}">
                    <rdf:Description rdf:nodeID="{$blank-node-id}">
                        <xsl:apply-templates mode="#current"/>
                    </rdf:Description>
                </xsl:element>
            </xsl:when>
            <!-- Property with rdf:parseType="Collection" - handle recursively -->
            <xsl:when test="@rdf:parseType = 'Collection'">
                <xsl:variable name="property-name" select="name()"/>
                <xsl:variable name="property-ns" select="namespace-uri()"/>
                <xsl:element name="{$property-name}" namespace="{$property-ns}">
                    <xsl:choose>
                        <xsl:when test="not(*)">
                            <xsl:attribute name="rdf:resource">http://www.w3.org/1999/02/22-rdf-syntax-ns#nil</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="list-items" select="*" as="element()*"/>
                            <xsl:variable name="first-node-id" select="concat('c', generate-id(), '_1')"/>
                            <rdf:Description rdf:nodeID="{$first-node-id}">
                                <xsl:call-template name="build-rdf-list">
                                    <xsl:with-param name="items" select="$list-items"/>
                                    <xsl:with-param name="position" select="1"/>
                                    <xsl:with-param name="node-id" select="$first-node-id"/>
                                </xsl:call-template>
                            </rdf:Description>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:when>
            <!-- Property with literal value - preserve xml:lang -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@rdf:datatype | @xml:lang"/>
                    <xsl:value-of select="."/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========================================
         PASS 2: FLATTEN NESTED DESCRIPTIONS
         ======================================== -->

    <!-- Collect all rdf:Description elements at any level and make them direct children of rdf:RDF -->
    <xsl:template match="rdf:RDF" mode="ldh:flatten-RDF">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- Process all rdf:Description elements (top-level and nested) -->
            <xsl:apply-templates select=".//rdf:Description" mode="ldh:flatten-description"/>
        </xsl:copy>
    </xsl:template>

    <!-- Copy each rdf:Description, but strip out any nested rdf:Description elements -->
    <xsl:template match="rdf:Description" mode="ldh:flatten-description">
        <xsl:copy>
            <xsl:copy-of select="@rdf:about | @rdf:nodeID"/>
            <!-- Process properties, but stop at nested rdf:Description -->
            <xsl:apply-templates select="*" mode="ldh:flatten-properties"/>
        </xsl:copy>
    </xsl:template>

    <!-- Copy property elements, excluding nested rdf:Description -->
    <xsl:template match="rdf:Description/*" mode="ldh:flatten-properties">
        <xsl:choose>
            <!-- If property contains nested rdf:Description, copy property with nodeID reference from nested element -->
            <xsl:when test="rdf:Description">
                <xsl:copy>
                    <!-- Use the rdf:nodeID from the nested rdf:Description -->
                    <xsl:attribute name="rdf:nodeID" select="rdf:Description/@rdf:nodeID"/>
                </xsl:copy>
            </xsl:when>
            <!-- Otherwise copy the entire property element -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========================================
         PASS 3: RESOLVE RELATIVE URIs
         ======================================== -->

    <!-- Copy rdf:RDF root element -->
    <xsl:template match="rdf:RDF" mode="ldh:resolve-uris">
        <xsl:param name="base-uri" as="xs:anyURI" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Resolve rdf:about attributes if they contain relative URIs -->
    <xsl:template match="rdf:Description[@rdf:about]" mode="ldh:resolve-uris">
        <xsl:param name="base-uri" as="xs:anyURI" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="rdf:about" select="resolve-uri(@rdf:about, $base-uri)"/>
            <xsl:apply-templates select="@* except @rdf:about" mode="#current"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Resolve rdf:resource attributes if they contain relative URIs -->
    <xsl:template match="*[@rdf:resource]" mode="ldh:resolve-uris">
        <xsl:param name="base-uri" as="xs:anyURI" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@* except @rdf:resource"/>
            <xsl:attribute name="rdf:resource" select="resolve-uri(@rdf:resource, $base-uri)"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Copy all other elements as-is -->
    <xsl:template match="*" mode="ldh:resolve-uris">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Copy text nodes -->
    <xsl:template match="text()" mode="ldh:resolve-uris">
        <xsl:copy/>
    </xsl:template>

</xsl:stylesheet>
