<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2012 Martynas Jusevičius <martynas@atomgraph.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:ac="&ac;"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:json="http://www.w3.org/2005/xpath-functions"
exclude-result-prefixes="xs">

    <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="application/json"/>
    <xsl:strip-space elements="*"/>

    <xsl:key name="resources" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>
    <xsl:key name="properties" match="*[@rdf:about or @rdf:nodeID]/*" use="concat(namespace-uri(), local-name())"/>

    <!-- 
    https://developers.google.com/chart/interactive/docs/reference#dataparam

    {
      "cols": [{id: 'A', label: 'NEW A', type: 'string'},
                     {id: 'B', label: 'B-label', type: 'number'},
                     {id: 'C', label: 'C-label', type: 'date'}
                    ],
      "rows": [{c:[{v: 'a'}, {v: 1.0, f: 'One'}, {v: "Date(2008, 1, 28, 0, 31, 26)", f: '2/28/08 12:31 AM'}]},
                     {c:[{v: 'b'}, {v: 2.0, f: 'Two'}, {v: "Date(2008, 2, 30, 0, 31, 26)", f: '3/30/08 12:31 AM'}]},
                     {c:[{v: 'c'}, {v: 3.0, f: 'Three'}, {v: "Date(2008, 3, 30, 0, 31, 26)", f: '4/30/08 12:31 AM'}]}
                    ]
    }

    -->

    <xsl:template match="/" mode="ac:DataTable">
        <xsl:variable name="json-xml" as="element()">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="xml-to-json($json-xml)"/>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="ac:DataTable">
        <xsl:param name="resource-ids" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="properties" as="xs:anyURI*" tunnel="yes"/>
        <xsl:param name="columns" as="map(xs:string, xs:anyAtomicType)*"> <!-- map that stores calculated ?count (max occurence per resource) for each ?property -->
            <xsl:variable name="current" select="."/>
            <xsl:choose>
                <xsl:when test="exists($properties)">
                    <xsl:for-each select="$properties">
                        <xsl:for-each-group select="key('properties', current(), $current)" group-by="concat(namespace-uri(), local-name())">
                            <xsl:sort select="index-of($properties, concat(namespace-uri(), local-name()))[1]"/>

                            <xsl:map>
                                <xsl:map-entry key="'property'" select="current-grouping-key()"/>

                                <xsl:variable name="max-count-per-resource" select="max(for $resource in $current/* return count($resource/*[concat(namespace-uri(), local-name()) = current-grouping-key()]))" as="xs:integer"/>
                                <xsl:map-entry key="'count'" select="$max-count-per-resource"/>
                            </xsl:map>
                        </xsl:for-each-group>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(), local-name())">
                        <xsl:sort select="concat(namespace-uri(), local-name())"/>

                        <xsl:map>
                            <xsl:map-entry key="'property'" select="current-grouping-key()"/>

                            <xsl:variable name="max-count-per-resource" select="max(for $resource in $current/* return count($resource/*[concat(namespace-uri(), local-name()) = current-grouping-key()]))" as="xs:integer"/>
                            <xsl:map-entry key="'count'" select="$max-count-per-resource"/>
                        </xsl:map>
                    </xsl:for-each-group>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>

        <json:map>
            <json:array key="cols">
                <!-- resource URI/bnode becomes the first column if none is provided explicitly -->
                <xsl:if test="$resource-ids">
                    <json:map>
                        <json:string key="id">
                            <xsl:value-of select="generate-id()"/>
                        </json:string>
                        <json:string key="type">string</json:string>
                    </json:map>
                </xsl:if>

                <xsl:variable name="current" select="."/>
                <xsl:for-each select="$columns">
                    <xsl:variable name="map" select="." as="map(xs:string, xs:anyAtomicType)"/>
                    <xsl:iterate select="1 to $map?count">
                        <xsl:apply-templates select="key('properties', $map?property, $current)[1]" mode="ac:DataTableColumns"/>
                    </xsl:iterate>
                </xsl:for-each>
            </json:array>

            <json:array key="rows">
                <xsl:apply-templates select="*" mode="#current">
                    <xsl:with-param name="columns" select="$columns"/>
                </xsl:apply-templates>
            </json:array>
        </json:map>
    </xsl:template>

    <!--  DATA TABLE HEADER -->
    
    <!-- properties -->

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:DataTableColumns">
        <json:map>
            <json:string key="id"><xsl:value-of select="generate-id()"/></json:string>
            <json:string key="label"><xsl:value-of select="concat(namespace-uri(), local-name())"/></json:string>
            <json:string key="type">
                <xsl:variable name="same-properties" select="key('properties', concat(namespace-uri(), local-name()))" as="element()*"/>
                <xsl:variable name="same-property-count" select="count($same-properties)" as="xs:integer"/>
                <xsl:choose>
                    <xsl:when test="count($same-properties[@rdf:datatype = ('&xsd;integer', '&xsd;decimal', '&xsd;double', '&xsd;float')]) = $same-property-count">number</xsl:when>
                    <xsl:when test="count($same-properties[@rdf:datatype = ('&xsd;dateTime', '&xsd;date')]) = $same-property-count">date</xsl:when>
                    <xsl:when test="count($same-properties[@rdf:datatype = ('&xsd;time')]) = $same-property-count">timeofday</xsl:when>
                    <xsl:otherwise>string</xsl:otherwise>
                </xsl:choose>
            </json:string>
        </json:map>
    </xsl:template>

    <!--  DATA TABLE ROW -->
    
    <!-- subject -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="ac:DataTable">
        <xsl:param name="resource-ids" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="columns" as="map(xs:string, xs:anyAtomicType)*"/>

        <json:map>
            <json:array key="c">
                <!-- resource URI/bnode becomes the first column if none is provided explicitly -->
                <xsl:if test="$resource-ids">
                    <json:map>
                        <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="#current"/>
                    </json:map>
                </xsl:if>

                <xsl:variable name="subject" select="."/>
                <xsl:for-each select="$columns">
                    <xsl:variable name="property" select="xs:anyURI(current()?property)" as="xs:anyURI"/>
                    <xsl:variable name="count" select="current()?count" as="xs:integer"/>

                    <xsl:for-each select="1 to $count">
                        <xsl:choose>
                            <xsl:when test="$subject/*[concat(namespace-uri(), local-name()) = $property][current()]">
                                <xsl:apply-templates select="$subject/*[concat(namespace-uri(), local-name()) = $property][current()]" mode="#current"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <json:map>
                                    <json:null key="v"/>
                                </json:map>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
             </json:array>
        </json:map>
    </xsl:template>

    <!--  DATA TABLE CELLS -->
    
    <!-- properties -->

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="ac:DataTable">
        <json:map>
            <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"/>
        </json:map>
    </xsl:template>

    <xsl:template match="text()[../@rdf:datatype = '&xsd;boolean']" mode="ac:DataTable">
         <json:boolean key="v"><xsl:value-of select="."/></json:boolean>
    </xsl:template>

    <xsl:template match="text()[../@rdf:datatype = '&xsd;integer'] | text()[../@rdf:datatype = '&xsd;decimal'] | text()[../@rdf:datatype = '&xsd;double'] | text()[../@rdf:datatype = '&xsd;float']" mode="ac:DataTable">
         <json:number key="v"><xsl:value-of select="."/></json:number>
    </xsl:template>

    <xsl:template match="text()[../@rdf:datatype = '&xsd;date']" mode="ac:DataTable">
        <json:string key="v">Date(<xsl:value-of select="year-from-date(.)"/>, <xsl:value-of select="month-from-date(.) - 1"/>, <xsl:value-of select="day-from-date(.)"/>)</json:string>
    </xsl:template>

    <xsl:template match="text()[../@rdf:datatype = '&xsd;dateTime']" mode="ac:DataTable">
        <json:string key="v">Date(<xsl:value-of select="year-from-dateTime(.)"/>, <xsl:value-of select="month-from-dateTime(.) - 1"/>, <xsl:value-of select="day-from-dateTime(.)"/>, <xsl:value-of select="hours-from-dateTime(.)"/>, <xsl:value-of select="minutes-from-dateTime(.)"/>, <xsl:value-of select="seconds-from-dateTime(.)"/>)</json:string>
    </xsl:template>

    <xsl:template match="text()[../@rdf:datatype = '&xsd;time']" mode="ac:DataTable">
        <json:array key="v">
            <json:number><xsl:value-of select="substring(., 1, 2)" /></json:number>
            <json:number><xsl:value-of select="substring(., 4, 2)" /></json:number>
            <json:number><xsl:value-of select="substring(., 7, 2)" /></json:number>

            <xsl:if test="contains(., '.')">
                <json:number><xsl:value-of select="substring(substring-after(., '.'), 1, 3)"/></json:number>
            </xsl:if>
         </json:array>
    </xsl:template>

    <xsl:template match="text()" mode="ac:DataTable" priority="-1">
        <json:string key="v"><xsl:value-of select="."/></json:string>
    </xsl:template>

    <xsl:template match="@rdf:*" mode="ac:DataTable">
        <json:string key="v"><xsl:value-of select="."/></json:string>
    </xsl:template>

</xsl:stylesheet>