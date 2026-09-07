<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac         "https://w3id.org/atomgraph/client#">
    <!ENTITY ldh        "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY rdf        "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
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
                <json:string><xsl:text>?</xsl:text><xsl:value-of select="."/></json:string>
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
    
    <xsl:template match="/json:map" mode="ldh:replace-limit" priority="1">
        <xsl:param name="limit" as="xs:integer?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$limit">
                <json:number key="limit">
                    <xsl:value-of select="$limit"/>
                </json:number>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:number[@key = 'limit']" mode="ldh:replace-limit" priority="1"/>
    
    <!-- replace OFFSET -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:replace-offset">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map" mode="ldh:replace-offset" priority="1">
        <xsl:param name="offset" as="xs:integer?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$offset">
                <json:number key="offset">
                    <xsl:value-of select="$offset"/>
                </json:number>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:number[@key = 'offset']" mode="ldh:replace-offset" priority="1"/>

    <!-- wrap SELECT into DESCRIBE -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:wrap-describe">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map" mode="ldh:wrap-describe" priority="1">
        <json:map>
            <json:string key="queryType">DESCRIBE</json:string>
            <json:array key="variables">
                <json:string>*</json:string>
            </json:array>
            <!-- Hoist the dataset (FROM / FROM NAMED) clause up to the wrapping DESCRIBE.
                 A dataset clause is only legal on the outermost query, so it cannot remain
                 on the SELECT once that becomes a subquery (otherwise: SPARQL parse error).
                 No-op for queries without a dataset clause, so fully backwards-compatible. -->
            <xsl:copy-of select="json:map[@key = 'from']"/>
            <json:array key="where">
                <xsl:apply-templates select="." mode="ldh:strip-from"/>
            </json:array>
        </json:map>
    </xsl:template>

    <!-- strip the (now hoisted) top-level dataset clause off the nested subquery -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:strip-from">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/json:map/json:map[@key = 'from']" mode="ldh:strip-from" priority="1"/>

    <!-- strip ORDER BY -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:strip-order-by">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- removes every sort key: ldh:replace-order-by with no $var-name only drops the first one -->
    <xsl:template match="/json:map/json:array[@key = 'order']" mode="ldh:strip-order-by" priority="1"/>

    <!-- link predicates -->

    <!-- a triple pattern matched both in the default graph and in any named graph -->
    <xsl:template name="ldh:GraphUnionPattern">
        <xsl:param name="subject" as="xs:string"/>
        <xsl:param name="predicate" as="xs:string"/>
        <xsl:param name="object" as="xs:string"/>
        <xsl:param name="graph-var" as="xs:string"/>

        <json:map>
            <json:string key="type">union</json:string>
            <json:array key="patterns">
                <json:map>
                    <json:string key="type">bgp</json:string>
                    <json:array key="triples">
                        <json:map>
                            <json:string key="subject"><xsl:value-of select="$subject"/></json:string>
                            <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                            <json:string key="object"><xsl:value-of select="$object"/></json:string>
                        </json:map>
                    </json:array>
                </json:map>
                <json:map>
                    <json:string key="type">graph</json:string>
                    <json:array key="patterns">
                        <json:map>
                            <json:string key="type">bgp</json:string>
                            <json:array key="triples">
                                <json:map>
                                    <json:string key="subject"><xsl:value-of select="$subject"/></json:string>
                                    <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                                    <json:string key="object"><xsl:value-of select="$object"/></json:string>
                                </json:map>
                            </json:array>
                        </json:map>
                    </json:array>
                    <json:string key="name"><xsl:value-of select="$graph-var"/></json:string>
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
         becomes a subquery (in its own group - a SubSelect has to be the sole content of its
         braces, and the WHERE has a second member), so discovery covers the whole result set
         rather than the loaded page; the caller strips LIMIT/OFFSET/ORDER off it first.

         Outgoing objects that are literals, or that are never subjects themselves, are filtered
         out: a pivot onto them would render an empty view. Incoming subjects need no such check -
         each is by construction the subject of the triple that matched.

         Variable names carry the caller's UUID because a subquery exports its projected variables:
         a view projecting ?predicate would otherwise silently join with ours. The wrapper
         deliberately carries no prefixes - with any, the generator abbreviates IRIs and then emits
         the subquery's own prologue inside the group, which is a syntax error. -->
    <xsl:template match="/json:map" mode="ldh:link-predicates" priority="1">
        <xsl:param name="uuid" as="xs:string" tunnel="yes"/>
        <xsl:param name="limit" select="100" as="xs:integer" tunnel="yes"/>
        <xsl:variable name="suffix" select="translate($uuid, '-', '_')" as="xs:string"/>
        <xsl:variable name="focus-var" select="string(json:array[@key = 'variables']/json:string[1])" as="xs:string"/>
        <xsl:variable name="predicate-var" select="'?predicate' || $suffix" as="xs:string"/>
        <xsl:variable name="inverse-var" select="'?inverse' || $suffix" as="xs:string"/>
        <xsl:variable name="object-var" select="'?object' || $suffix" as="xs:string"/>
        <xsl:variable name="subject-var" select="'?subject' || $suffix" as="xs:string"/>

        <json:map>
            <json:string key="queryType">SELECT</json:string>
            <json:boolean key="distinct">true</json:boolean>
            <json:array key="variables">
                <json:string><xsl:value-of select="$predicate-var"/></json:string>
                <json:string><xsl:value-of select="$inverse-var"/></json:string>
            </json:array>
            <!-- hoist the dataset clause, which is only legal on the outermost query (see ldh:wrap-describe) -->
            <xsl:copy-of select="json:map[@key = 'from']"/>
            <json:array key="where">
                <json:map>
                    <json:string key="type">group</json:string>
                    <json:array key="patterns">
                        <xsl:apply-templates select="." mode="ldh:strip-from"/>
                    </json:array>
                </json:map>

                <json:map>
                    <json:string key="type">union</json:string>
                    <json:array key="patterns">
                        <!-- outgoing: the result set's own properties -->
                        <json:map>
                            <json:string key="type">group</json:string>
                            <json:array key="patterns">
                                <xsl:call-template name="ldh:GraphUnionPattern">
                                    <xsl:with-param name="subject" select="$focus-var"/>
                                    <xsl:with-param name="predicate" select="$predicate-var"/>
                                    <xsl:with-param name="object" select="$object-var"/>
                                    <xsl:with-param name="graph-var" select="'?graph' || $suffix"/>
                                </xsl:call-template>

                                <json:map>
                                    <json:string key="type">filter</json:string>
                                    <json:map key="expression">
                                        <json:string key="type">operation</json:string>
                                        <json:string key="operator">!</json:string>
                                        <json:array key="args">
                                            <json:map>
                                                <json:string key="type">operation</json:string>
                                                <json:string key="operator">isliteral</json:string>
                                                <json:array key="args">
                                                    <json:string><xsl:value-of select="$object-var"/></json:string>
                                                </json:array>
                                            </json:map>
                                        </json:array>
                                    </json:map>
                                </json:map>

                                <json:map>
                                    <json:string key="type">filter</json:string>
                                    <json:map key="expression">
                                        <json:string key="type">operation</json:string>
                                        <json:string key="operator">exists</json:string>
                                        <json:array key="args">
                                            <json:map>
                                                <json:string key="type">group</json:string>
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

                                <json:map>
                                    <json:string key="type">bind</json:string>
                                    <json:string key="variable"><xsl:value-of select="$inverse-var"/></json:string>
                                    <json:string key="expression">"false"^^&xsd;boolean</json:string>
                                </json:map>
                            </json:array>
                        </json:map>

                        <!-- incoming: what points at the result set -->
                        <json:map>
                            <json:string key="type">group</json:string>
                            <json:array key="patterns">
                                <xsl:call-template name="ldh:GraphUnionPattern">
                                    <xsl:with-param name="subject" select="$subject-var"/>
                                    <xsl:with-param name="predicate" select="$predicate-var"/>
                                    <xsl:with-param name="object" select="$focus-var"/>
                                    <xsl:with-param name="graph-var" select="'?subjectGraph' || $suffix"/>
                                </xsl:call-template>

                                <json:map>
                                    <json:string key="type">bind</json:string>
                                    <json:string key="variable"><xsl:value-of select="$inverse-var"/></json:string>
                                    <json:string key="expression">"true"^^&xsd;boolean</json:string>
                                </json:map>
                            </json:array>
                        </json:map>
                    </json:array>
                </json:map>
            </json:array>
            <json:number key="limit"><xsl:value-of select="$limit"/></json:number>
        </json:map>
    </xsl:template>

    <!-- add parallax step -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:add-parallax-step">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/json:map" mode="ldh:add-parallax-step" priority="1">
        <!-- use the first ?var from the SELECT -->
        <xsl:param name="var-name" select="/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string" tunnel="yes"/>
        <xsl:param name="uuid" select="ac:uuid()" as="xs:string" tunnel="yes"/>
        <xsl:param name="new-var-name" select="'subject' || translate($uuid, '-', '_')" as="xs:string" tunnel="yes"/>
        <xsl:param name="graph-var-name" select="'graph' || translate($uuid, '-', '_')" as="xs:string" tunnel="yes"/>

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
    
    <xsl:template match="json:array[@key = 'where']" mode="ldh:add-parallax-step" priority="1">
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
                <json:string key="type">union</json:string>
                <json:array key="patterns">
                    <json:map>
                        <json:string key="type">bgp</json:string>
                        <json:array key="triples">
                            <json:map>
                                <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$subject-var-name"/></json:string>
                                <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                                <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                            </json:map>

                            <xsl:if test="$title-new-var-name and $title-predicate"> <!-- TO-DO: support OPTIONAL? -->
                                <json:map>
                                    <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$new-var-name"/></json:string>
                                    <json:string key="predicate"><xsl:value-of select="$title-predicate"/></json:string>
                                    <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$title-new-var-name"/></json:string>
                                </json:map>
                            </xsl:if>
                        </json:array>
                    </json:map>
                    <json:map>
                        <json:string key="type">graph</json:string>
                        <json:array key="patterns">
                            <json:map>
                                <json:string key="type">bgp</json:string>
                                <json:array key="triples">
                                    <json:map>
                                        <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$subject-var-name"/></json:string>
                                        <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                                        <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                                    </json:map>

                                    <xsl:if test="$title-new-var-name and $title-predicate"> <!-- TO-DO: support OPTIONAL? -->
                                        <json:map>
                                            <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$new-var-name"/></json:string>
                                            <json:string key="predicate"><xsl:value-of select="$title-predicate"/></json:string>
                                            <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$title-new-var-name"/></json:string>
                                        </json:map>
                                    </xsl:if>
                                </json:array>
                            </json:map>
                        </json:array>
                        <json:string key="name"><xsl:text>?</xsl:text><xsl:value-of select="$graph-var-name"/></json:string>
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
    
    <xsl:template match="/json:map[not(json:array[@key = 'order'])]" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$var-name">
                <json:array key="order">
                    <json:map>
                        <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$var-name"/></json:string>
                    </json:map>
                </json:array>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- if a new sort key is present, insert it as the first one -->
    <xsl:template match="json:array[@key = 'order'][count(json:map) = 1]" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>

        <xsl:if test="$var-name">
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="#current"/>

                <!-- unless the new one is the same as the existing one - in which case skip it -->
                <xsl:if test="not(json:map/json:string[@key = 'expression'] = '?' || $var-name)">
                    <json:map>
                        <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$var-name"/></json:string>
                    </json:map>
                </xsl:if>

                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <!-- if there are two sort keys already, replace the first one with the new one - if it's not empty and not equal to the second one -->
    <xsl:template match="json:array[@key = 'order'][count(json:map) = 2]/json:map[1]" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>
        
        <xsl:if test="$var-name and not('?' || $var-name = following-sibling::json:map/json:string[@key = 'expression'])">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- replace the first one's expression with the new one -->
    <xsl:template match="json:array[@key = 'order'][count(json:map) = 2]/json:map[1]/json:string[@key = 'expression']" mode="ldh:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:text>?</xsl:text><xsl:value-of select="$var-name"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- toggle DESC -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:toggle-desc">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:array[@key = 'order']/json:map[1]" mode="ldh:toggle-desc" priority="1">
        <xsl:param name="desc" as="xs:boolean?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$desc and not(json:boolean[@key = 'descending'][. = 'true'])">
                <json:boolean key="descending">true</json:boolean>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending'][. = 'true']" mode="ldh:toggle-desc" priority="1">
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
            
            <json:string><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
            <!-- COUNT() of subjects -->
            <json:map>
                <json:map key="expression">
                    <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$subject-var-name"/></json:string>
                    <json:string key="type">aggregate</json:string>
                    <json:string key="aggregation">count</json:string>
                    <json:boolean key="distinct">true</json:boolean>
                </json:map>
                <json:string key="variable"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
            </json:map>
            <!-- SAMPLE() of ?labels -->
            <json:map>
                <json:map key="expression">
                    <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$label-var-name"/></json:string>
                    <json:string key="type">aggregate</json:string>
                    <json:string key="aggregation">sample</json:string>
                    <json:boolean key="distinct">false</json:boolean>
                </json:map>
                <json:string key="variable"><xsl:text>?</xsl:text><xsl:value-of select="$label-sample-var-name"/></json:string>
            </json:map>
        </xsl:copy>
    </xsl:template>

    <!-- add GROUP BY ?varName and ORDER BY DESC(?varName) after the WHERE -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'query']" mode="ldh:bgp-value-counts" priority="1">
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="descending" select="true()" as="xs:boolean" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- TO-DO: will fail on queries with existing GROUP BY -->
            <json:array key="group">
                <json:map>
                    <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                </json:map>
            </json:array>
            <!-- create ORDER BY if it doesn't exist -->
            <xsl:if test="not(json:array[@key = 'order'])">
                <json:array key="order">
                    <json:map>
                        <json:string key="expression"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
                        <json:boolean key="descending"><xsl:value-of select="$descending"/></json:boolean>
                    </json:map>
                </json:array>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- append OPTIONAL pattern with ?label property paths inside the BGP with object var name -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'bgp']/.." mode="ldh:bgp-value-counts" priority="1">
        <xsl:param name="bgp-triples-map" as="element()" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-graph-var-name" select="$label-var-name || 'graph'" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="json:map[json:string[@key = 'type'] = 'bgp']/json:array[@key = 'triples']/json:map/json:string[@key = 'object'] = '?' || $object-var-name">
                <json:map>
                    <json:string key="type">optional</json:string>
                    <json:array key="patterns">
                        <json:map>
                            <json:string key="type">union</json:string>
                            <json:array key="patterns">
                                <json:map>
                                    <json:string key="type">bgp</json:string>
                                    <json:array key="triples">
                                        <json:map>
                                            <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                                            <json:map key="predicate">
                                                <json:string key="type">path</json:string>
                                                <json:string key="pathType">|</json:string>
                                                <json:array key="items">
                                                    <json:map>
                                                        <json:string key="type">path</json:string>
                                                        <json:string key="pathType">|</json:string>
                                                        <json:array key="items">
                                                            <json:map>
                                                                <json:string key="type">path</json:string>
                                                                <json:string key="pathType">|</json:string>
                                                                <json:array key="items">
                                                                    <json:map>
                                                                        <json:string key="type">path</json:string>
                                                                        <json:string key="pathType">|</json:string>
                                                                        <json:array key="items">
                                                                            <json:map>
                                                                                <json:string key="type">path</json:string>
                                                                                <json:string key="pathType">|</json:string>
                                                                                <json:array key="items">
                                                                                    <json:map>
                                                                                        <json:string key="type">path</json:string>
                                                                                        <json:string key="pathType">|</json:string>
                                                                                        <json:array key="items">
                                                                                            <json:map>
                                                                                                <json:string key="type">path</json:string>
                                                                                                <json:string key="pathType">|</json:string>
                                                                                                <json:array key="items">
                                                                                                    <json:string>http://www.w3.org/2000/01/rdf-schema#label</json:string>
                                                                                                    <json:string>http://purl.org/dc/elements/1.1/title</json:string>
                                                                                                </json:array>
                                                                                            </json:map>
                                                                                            <json:string>http://purl.org/dc/terms/title</json:string>
                                                                                        </json:array>
                                                                                    </json:map>
                                                                                    <json:string>http://xmlns.com/foaf/0.1/name</json:string>
                                                                                </json:array>
                                                                            </json:map>
                                                                            <json:string>http://xmlns.com/foaf/0.1/givenName</json:string>
                                                                        </json:array>
                                                                    </json:map>
                                                                    <json:string>http://xmlns.com/foaf/0.1/familyName</json:string>
                                                                </json:array>
                                                            </json:map>
                                                            <json:string>http://rdfs.org/sioc/ns#name</json:string>
                                                        </json:array>
                                                    </json:map>
                                                    <json:string>http://www.w3.org/2004/02/skos/core#prefLabel</json:string>
                                                </json:array>
                                            </json:map>
                                            <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$label-var-name"/></json:string>
                                        </json:map>
                                    </json:array>
                                </json:map>
                                <json:map>
                                    <json:string key="type">graph</json:string>
                                    <json:array key="patterns">
                                        <json:map>
                                            <json:string key="type">bgp</json:string>
                                            <json:array key="triples">
                                                <json:map>
                                                    <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$object-var-name"/></json:string>
                                                    <json:map key="predicate">
                                                        <json:string key="type">path</json:string>
                                                        <json:string key="pathType">|</json:string>
                                                        <json:array key="items">
                                                            <json:map>
                                                                <json:string key="type">path</json:string>
                                                                <json:string key="pathType">|</json:string>
                                                                <json:array key="items">
                                                                    <json:map>
                                                                        <json:string key="type">path</json:string>
                                                                        <json:string key="pathType">|</json:string>
                                                                        <json:array key="items">
                                                                            <json:map>
                                                                                <json:string key="type">path</json:string>
                                                                                <json:string key="pathType">|</json:string>
                                                                                <json:array key="items">
                                                                                    <json:map>
                                                                                        <json:string key="type">path</json:string>
                                                                                        <json:string key="pathType">|</json:string>
                                                                                        <json:array key="items">
                                                                                            <json:map>
                                                                                                <json:string key="type">path</json:string>
                                                                                                <json:string key="pathType">|</json:string>
                                                                                                <json:array key="items">
                                                                                                    <json:map>
                                                                                                        <json:string key="type">path</json:string>
                                                                                                        <json:string key="pathType">|</json:string>
                                                                                                        <json:array key="items">
                                                                                                            <json:string>http://www.w3.org/2000/01/rdf-schema#label</json:string>
                                                                                                            <json:string>http://purl.org/dc/elements/1.1/title</json:string>
                                                                                                        </json:array>
                                                                                                    </json:map>
                                                                                                    <json:string>http://purl.org/dc/terms/title</json:string>
                                                                                                </json:array>
                                                                                            </json:map>
                                                                                            <json:string>http://xmlns.com/foaf/0.1/name</json:string>
                                                                                        </json:array>
                                                                                    </json:map>
                                                                                    <json:string>http://xmlns.com/foaf/0.1/givenName</json:string>
                                                                                </json:array>
                                                                            </json:map>
                                                                            <json:string>http://xmlns.com/foaf/0.1/familyName</json:string>
                                                                        </json:array>
                                                                    </json:map>
                                                                    <json:string>http://rdfs.org/sioc/ns#name</json:string>
                                                                </json:array>
                                                            </json:map>
                                                            <json:string>http://www.w3.org/2004/02/skos/core#prefLabel</json:string>
                                                        </json:array>
                                                    </json:map>
                                                    <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$label-var-name"/></json:string>
                                                </json:map>
                                            </json:array>
                                        </json:map>
                                    </json:array>
                                    <json:string key="name"><xsl:text>?</xsl:text><xsl:value-of select="$label-graph-var-name"/></json:string>
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
    <xsl:template match="json:array[@key = 'where']" mode="ldh:filter-in" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        <xsl:variable name="var-filter" select="json:map[json:string[@key = 'type'] = 'filter'][json:map[@key = 'expression']/json:array[@key = 'args']/json:string eq '?' || $var-name]" as="element()?"/>
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
                            <json:string key="type">filter</json:string>
                            <json:map key="expression">
                                <json:string key="type">operation</json:string>
                                <json:string key="operator">in</json:string>
                                <json:array key="args">
                                    <json:string><xsl:text>?</xsl:text><xsl:value-of select="$var-name"/></json:string>
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

    <xsl:template match="json:map[json:string[@key = 'type'] = 'filter']" mode="ldh:set-filter-in-values" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        
        <!-- remove the FILTER ($varName) if there are no values -->
        <xsl:if test="not(json:map[@key = 'expression']/json:array[@key = 'args']/json:string = '?' || $var-name and array:size($values) = 0)">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- replace IN () values for the FILTER with matching variable name -->
    <xsl:template match="json:map[json:string[@key = 'type'] = 'filter']/json:map[@key = 'expression']/json:array[@key = 'args']/json:array" mode="ldh:set-filter-in-values" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="array(map(xs:string, xs:string))" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:choose>
                <!-- replace IN() values if $varName matches -->
                <xsl:when test="../json:string eq '?' || $var-name">
                    <xsl:for-each select="1 to array:size($values)">
                        <xsl:variable name="pos" select="position()"/>
                        
                        <json:string>
                            <xsl:choose>
                                <!-- literal value - wrap in quotes: "literal" -->
                                <xsl:when test="array:get($values, $pos)?type = 'literal'">
                                    <xsl:text>&quot;</xsl:text><xsl:value-of select="array:get($values, $pos)?value"/><xsl:text>&quot;</xsl:text>
                                    <!-- add datatype URI, if any -->
                                    <xsl:if test="array:get($values, $pos)?datatype">
                                        <xsl:text>^^</xsl:text>
                                        <xsl:value-of select="array:get($values, $pos)?datatype"/>
                                    </xsl:if>
                                </xsl:when>
                                <!-- URI value -->
                                <xsl:otherwise>
                                    <xsl:value-of select="array:get($values, $pos)?value"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </json:string>
                    </xsl:for-each>
                </xsl:when>
                <!-- otherwise, retain existing values -->
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!-- result COUNT -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="ldh:result-count">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- replace query variables with (COUNT(DISTINCT *) AS ?count) -->
    <xsl:template match="json:map/json:array[@key = 'variables']" mode="ldh:result-count" priority="1">
        <xsl:param name="expression-var-name" as="xs:string?" tunnel="yes"/>
        <xsl:param name="count-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <json:map>
                <json:map key="expression">
                    <json:string key="expression">
                        <xsl:choose>
                            <xsl:when test="$expression-var-name">
                                <xsl:text>?</xsl:text>
                                <xsl:value-of select="$expression-var-name"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>*</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </json:string>
                    <json:string key="type">aggregate</json:string>
                    <json:string key="aggregation">count</json:string>
                    <json:boolean key="distinct">true</json:boolean>
                </json:map>
                <json:string key="variable"><xsl:text>?</xsl:text><xsl:value-of select="$count-var-name"/></json:string>
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
    <xsl:template match="json:array[@key = 'template']" mode="ldh:add-constructor-triple" priority="1">
        <xsl:param name="subject" select="'?this'" as="xs:string" tunnel="yes"/>
        <xsl:param name="predicate" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="object-type"  as="xs:anyURI" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <json:map>
                <json:string key="subject"><xsl:value-of select="$subject"/></json:string>
                <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                <json:string key="object">_:<xsl:value-of select="generate-id()"/></json:string>
            </json:map>
            <json:map>
                <json:string key="subject">_:<xsl:value-of select="generate-id()"/></json:string>
                <json:string key="predicate">&rdf;type</json:string>
                <json:string key="object"><xsl:value-of select="$object-type"/></json:string>
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
    <xsl:template match="json:array[@key = 'where']" mode="ldh:add-regex-filter" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="pattern" as="xs:string" tunnel="yes"/>
        <xsl:param name="flags" as="xs:string?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <json:map>
                <json:string key="type">filter</json:string>
                <json:map key="expression">
                    <json:string key="type">operation</json:string>
                    <json:string key="operator">regex</json:string>
                    <json:array key="args">
                        <json:string>?<xsl:value-of select="$var-name"/></json:string>
                        <json:string>"<xsl:value-of select="$pattern"/>"</json:string>
                        
                        <xsl:if test="$flags">
                            <json:string>"<xsl:value-of select="$flags"/>"</json:string>
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
    <xsl:template match="json:array[@key = 'where']" mode="ldh:add-filter-in" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="values" as="xs:anyAtomicType*" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

                <json:map>
                    <json:string key="type">filter</json:string>
                    <json:map key="expression">
                        <json:string key="type">operation</json:string>
                        <json:string key="operator">in</json:string>
                        <json:array key="args">
                            <json:string>?<xsl:value-of select="$var-name"/></json:string>
                            <json:array>
                                <xsl:for-each select="$values">
                                    <xsl:choose>
                                        <xsl:when test=". instance of xs:anyURI">
                                            <json:string><xsl:value-of select="."/></json:string>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:string">
                                            <json:string>"<xsl:value-of select="."/>"</json:string>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:integer">
                                            <json:string>"<xsl:value-of select="."/>"^^&xsd;integer</json:string>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:float">
                                            <json:string>"<xsl:value-of select="."/>"^^&xsd;float</json:string>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:boolean">
                                            <json:string>"<xsl:value-of select="."/>"^^&xsd;boolean</json:string>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:date">
                                            <json:string>"<xsl:value-of select="."/>"^^&xsd;date</json:string>
                                        </xsl:when>
                                        <xsl:when test=". instance of xs:dateTime">
                                            <json:string>"<xsl:value-of select="."/>"^^&xsd;dateTime</json:string>
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

    <xsl:template match="json:array[@key = 'where']" mode="ldh:append-values" priority="1">
        <xsl:param name="values-map" as="map(xs:string, xs:anyAtomicType)" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- Append VALUES block -->
            <json:map>
                <json:string key="type">values</json:string>
                <json:array key="values">
                    <json:map>
                        <xsl:for-each select="map:keys($values-map)">
                            <json:string key="{.}">
                                <xsl:value-of select="map:get($values-map, .)"/>
                            </json:string>
                        </xsl:for-each>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>