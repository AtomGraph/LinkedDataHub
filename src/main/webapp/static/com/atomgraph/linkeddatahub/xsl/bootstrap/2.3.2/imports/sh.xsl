<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>

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
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY sh     "http://www.w3.org/ns/shacl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:sh="&sh;"
xmlns:ldt="&ldt;"
exclude-result-prefixes="#all">

    <xsl:param name="ldt:lang" select="'en'" as="xs:string"/>

    <xsl:template match="*[$ldt:lang][sh:name[lang($ldt:lang)]/text()]" mode="ac:label" priority="1">
        <xsl:sequence select="sh:name[lang($ldt:lang)]/text()"/>
    </xsl:template>
    
    <xsl:template match="*[sh:name[not(@xml:lang)]/text()]" mode="ac:label">
        <xsl:sequence select="sh:name[not(@xml:lang)]/text()"/>
    </xsl:template>

    <xsl:template match="*[$ldt:lang][sh:description[lang($ldt:lang)]/text()]" mode="ac:description" priority="1">
        <xsl:sequence select="sh:description[lang($ldt:lang)]/text()"/>
    </xsl:template>
    
    <xsl:template match="*[sh:description[not(@xml:lang)]/text()]" mode="ac:description">
        <xsl:sequence select="sh:description[not(@xml:lang)]/text()"/>
    </xsl:template>
    
</xsl:stylesheet>
