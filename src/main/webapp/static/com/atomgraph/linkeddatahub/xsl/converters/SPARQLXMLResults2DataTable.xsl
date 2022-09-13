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
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:srx="&srx;"
xmlns:ac="&ac;"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:json="http://www.w3.org/2005/xpath-functions"
exclude-result-prefixes="#all">

    <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="application/json"/>
    <xsl:strip-space elements="*"/>

    <xsl:key name="binding-by-name" match="srx:binding" use="@name"/> 
    <xsl:variable name="numeric-variables" select="srx:variable[count(key('binding-by-name', @name)) = count(key('binding-by-name', @name)[string(number(srx:literal)) != 'NaN'])]"/> 

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

    <xsl:template match="srx:sparql" mode="ac:DataTable">
        <xsl:param name="var-names" as="xs:string*" tunnel="yes"/>
        <xsl:param name="variables" as="element()*">
            <xsl:choose>
                <xsl:when test="exists($var-names)">
                    <xsl:variable name="current" select="."/>
                    <xsl:for-each select="$var-names">
                        <xsl:sequence select="$current/srx:head/srx:variable[@name = current()]"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="srx:head/srx:variable"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>

        <json:map>
            <json:array key="cols">
                <xsl:apply-templates select="$variables" mode="#current"/>
            </json:array>
            <json:array key="rows">
                <xsl:apply-templates select="srx:results/srx:result" mode="#current">
                    <xsl:with-param name="variables" select="$variables"/>
                </xsl:apply-templates>
            </json:array>
        </json:map>
    </xsl:template>

    <!--  DATA TABLE HEADER -->

    <xsl:template match="srx:variable" mode="ac:DataTable">
        <json:map>
            <json:string key="id"><xsl:value-of select="generate-id()"/></json:string>
            <json:string key="label"><xsl:value-of select="@name"/></json:string>
            <json:string key="type">
                <xsl:variable name="bindings" select="key('binding-by-name', @name)" as="element()*"/>
                <xsl:variable name="binding-count" select="count($bindings)" as="xs:integer"/>
                <xsl:choose>
                    <xsl:when test="count($bindings/srx:uri) = $binding-count">string</xsl:when>
                    <xsl:when test="count($bindings/srx:bnode) = $binding-count">string</xsl:when>
                    <xsl:when test="count($bindings/srx:literal[@datatype = ('&xsd;integer', '&xsd;decimal', '&xsd;double', '&xsd;float')]) = $binding-count">number</xsl:when>
                    <xsl:when test="count($bindings/srx:literal[@datatype = ('&xsd;dateTime', '&xsd;date')]) = $binding-count">date</xsl:when>
                    <xsl:when test="count($bindings/srx:literal[@datatype = ('&xsd;time')]) = $binding-count">timeofday</xsl:when>
                    <xsl:otherwise>string</xsl:otherwise>
                </xsl:choose>
            </json:string>
        </json:map>
    </xsl:template>

    <!--  DATA TABLE ROW -->

    <xsl:template match="srx:result" mode="ac:DataTable">
        <xsl:param name="variables" as="element()*"/>

        <json:map>
            <json:array key="c">
                <xsl:variable name="result" select="."/>
                <xsl:for-each select="$variables">
                    <xsl:choose>
                        <xsl:when test="$result/srx:binding[@name = current()/@name]">
                            <xsl:apply-templates select="$result/srx:binding[@name = current()/@name]" mode="#current"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <json:map>
                                <json:null key="v"/>
                            </json:map>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </json:array>
        </json:map>
    </xsl:template>

    <!--  DATA TABLE CELLS -->

    <xsl:template match="srx:binding" mode="ac:DataTable">
        <json:map>
            <xsl:apply-templates select="*" mode="#current"/>
        </json:map>
    </xsl:template>

    <xsl:template match="srx:literal[@datatype = '&xsd;boolean']" mode="ac:DataTable">
        <json:boolean key="v"><xsl:value-of select="."/></json:boolean>
    </xsl:template>
    
    <xsl:template match="srx:literal[@datatype = '&xsd;integer'] | srx:literal[@datatype = '&xsd;decimal'] | srx:literal[@datatype = '&xsd;double'] | srx:literal[@datatype = '&xsd;float']" mode="ac:DataTable">
        <json:number key="v"><xsl:value-of select="."/></json:number>
    </xsl:template>

    <xsl:template match="srx:literal[@datatype = '&xsd;date']" mode="ac:DataTable">
        <json:string key="v">Date(<xsl:value-of select="year-from-date(.)"/>, <xsl:value-of select="month-from-date(.) - 1"/>, <xsl:value-of select="day-from-date(.)"/>)</json:string>
    </xsl:template>

    <xsl:template match="srx:literal[@datatype = '&xsd;dateTime']" mode="ac:DataTable">
        <json:string key="v">Date(<xsl:value-of select="year-from-dateTime(.)"/>, <xsl:value-of select="month-from-dateTime(.) - 1"/>, <xsl:value-of select="day-from-dateTime(.)"/>, <xsl:value-of select="hours-from-dateTime(.)"/>, <xsl:value-of select="minutes-from-dateTime(.)"/>, <xsl:value-of select="seconds-from-dateTime(.)"/>)</json:string>
    </xsl:template>

    <xsl:template match="srx:literal[@datatype = '&xsd;time']" mode="ac:DataTable">
        <json:array key="v">
            <json:number><xsl:value-of select="substring(., 1, 2)" /></json:number>
            <json:number><xsl:value-of select="substring(., 4, 2)" /></json:number>
            <json:number><xsl:value-of select="substring(., 7, 2)" /></json:number>
            
            <xsl:if test="contains(., '.')">
                <json:number><xsl:value-of select="substring(substring-after(., '.'), 1, 3)" /></json:number>
            </xsl:if>
        </json:array>
    </xsl:template>

    <xsl:template match="srx:literal" mode="ac:DataTable">
        <json:string key="v"><xsl:value-of select="."/></json:string>
    </xsl:template>

    <xsl:template match="srx:uri | srx:bnode" mode="ac:DataTable">
        <json:string key="v"><xsl:value-of select="."/></json:string>
    </xsl:template>

</xsl:stylesheet>