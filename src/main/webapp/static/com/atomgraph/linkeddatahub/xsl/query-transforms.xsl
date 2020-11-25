<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl        "https://w3id.org/atomgraph/linkeddatahub/domain#">
]>
<xsl:stylesheet version="3.0"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:apl="&apl;"
exclude-result-prefixes="#all"
>

    <!-- replace LIMIT -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:replace-limit">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map" mode="apl:replace-limit" priority="1">
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

    <xsl:template match="json:number[@key = 'limit']" mode="apl:replace-limit" priority="1"/>
    
    <!-- replace OFFSET -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:replace-offset">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map" mode="apl:replace-offset" priority="1">
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

    <xsl:template match="json:number[@key = 'offset']" mode="apl:replace-offset" priority="1"/>

    <!-- wrap SELECT into DESCRIBE -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:wrap-describe">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map" mode="apl:wrap-describe" priority="1">
        <json:map>
            <json:string key="queryType">DESCRIBE</json:string>
            <json:array key="variables">
                <json:string>*</json:string>
            </json:array>
            <json:array key="where">
                <xsl:sequence select="."/>
            </json:array>
        </json:map>
    </xsl:template>

    <!-- add parallax step -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:add-parallax-step">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/json:map" mode="apl:add-parallax-step" priority="1">
        <!-- use the first ?var from the SELECT -->
        <xsl:param name="var-name" select="/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string" tunnel="yes"/>
        <xsl:param name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string" tunnel="yes"/>
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

    <xsl:template match="/json:map/json:array[@key = 'variables']" mode="apl:add-parallax-step" priority="1">
        <xsl:param name="new-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
        
            <json:string><xsl:text>?</xsl:text><xsl:value-of select="$new-var-name"/></json:string>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:array[@key = 'where']" mode="apl:add-parallax-step" priority="1">
        <!-- use the first ?var from the SELECT -->
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="predicate" as="xs:anyURI" tunnel="yes"/>
        <xsl:param name="new-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="graph-var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        
            <json:map>
                <json:string key="type">union</json:string>
                <json:array key="patterns">
                    <json:map>
                        <json:string key="type">bgp</json:string>
                        <json:array key="triples">
                            <json:map>
                                <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$var-name"/></json:string>
                                <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                                <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$new-var-name"/></json:string>
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
                                        <json:string key="subject"><xsl:text>?</xsl:text><xsl:value-of select="$var-name"/></json:string>
                                        <json:string key="predicate"><xsl:value-of select="$predicate"/></json:string>
                                        <json:string key="object"><xsl:text>?</xsl:text><xsl:value-of select="$new-var-name"/></json:string>
                                    </json:map>
                                </json:array>
                            </json:map>
                        </json:array>
                        <json:string key="name"><xsl:text>?</xsl:text><xsl:value-of select="$graph-var-name"/></json:string>
                    </json:map>
                </json:array>
            </json:map>
        </xsl:copy>
    </xsl:template>
    
    <!-- reset the OFFSET on parallax because otherwise we can get an empty result -->
    <xsl:template match="/json:map/json:number[@key = 'offset']" mode="apl:add-parallax-step" priority="1"/>

    <!-- change ORDER BY -->

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:replace-order-by">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/json:map[not(json:array[@key = 'order'])]" mode="apl:replace-order-by" priority="1">
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
    <xsl:template match="json:array[@key = 'order'][count(json:map) = 1]" mode="apl:replace-order-by" priority="1">
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
    <xsl:template match="json:array[@key = 'order'][count(json:map) = 2]/json:map[1]" mode="apl:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string?" tunnel="yes"/>
        
        <xsl:if test="$var-name and not('?' || $var-name = following-sibling::json:map/json:string[@key = 'expression'])">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- replace the first one's expression with the new one -->
    <xsl:template match="json:array[@key = 'order'][count(json:map) = 2]/json:map[1]/json:string[@key = 'expression']" mode="apl:replace-order-by" priority="1">
        <xsl:param name="var-name" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:text>?</xsl:text><xsl:value-of select="$var-name"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- toggle DESC -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:toggle-desc">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:array[@key = 'order']/json:map[1]" mode="apl:toggle-desc" priority="1">
        <xsl:param name="desc" as="xs:boolean?" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:if test="$desc and not(json:boolean[@key = 'descending'][. = 'true'])">
                <json:boolean key="descending">true</json:boolean>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:array[@key = 'order']/json:map[1]/json:boolean[@key = 'descending'][. = 'true']" mode="apl:toggle-desc" priority="1">
        <xsl:param name="desc" as="xs:boolean?" tunnel="yes"/>

        <xsl:if test="$desc">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!--  facet values and COUNTs -->
    
    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:bgp-value-counts">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- replace query variables with ?varName (COUNT(DISTINCT ?varName) AS ?countVarName) -->
    <xsl:template match="json:map/json:array[@key = 'variables']" mode="apl:bgp-value-counts" priority="1">
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
    <xsl:template match="json:map[json:string[@key = 'type'] = 'query']" mode="apl:bgp-value-counts" priority="1">
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

    <!-- append OPTIONAL pattern with ?label property paths after the BGP with object var name -->
    <xsl:template match="json:array[@key = 'where']" mode="apl:bgp-value-counts" priority="1">
        <xsl:param name="bgp-triples-map" as="element()" tunnel="yes"/>
        <xsl:param name="object-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-var-name" as="xs:string" tunnel="yes"/>
        <xsl:param name="label-graph-var-name" select="$label-var-name || 'graph'" as="xs:string" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

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
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="json:map/json:array[@key = 'order']" mode="apl:bgp-value-counts" priority="1">
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
    <xsl:template match="@* | node()" mode="apl:filter-in">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- append FILTER (?varName IN ()) to WHERE, if it's not present yet, and replace IN() values -->
    <xsl:template match="json:array[@key = 'where']" mode="apl:filter-in" priority="1">
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
        <xsl:apply-templates select="$where" mode="apl:set-filter-in-values">
            <xsl:with-param name="var-name" select="$var-name" tunnel="yes"/>
            <xsl:with-param name="values" select="$values" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@* | node()" mode="apl:set-filter-in-values">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="json:map[json:string[@key = 'type'] = 'filter']" mode="apl:set-filter-in-values" priority="1">
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
    <xsl:template match="json:map[json:string[@key = 'type'] = 'filter']/json:map[@key = 'expression']/json:array[@key = 'args']/json:array" mode="apl:set-filter-in-values" priority="1">
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
    <xsl:template match="@* | node()" mode="apl:result-count">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- replace query variables with (COUNT(DISTINCT *) AS ?count) -->
    <xsl:template match="json:map/json:array[@key = 'variables']" mode="apl:result-count" priority="1">
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
    
</xsl:stylesheet>