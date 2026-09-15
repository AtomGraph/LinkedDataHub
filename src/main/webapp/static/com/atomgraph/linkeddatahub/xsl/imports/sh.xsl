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
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:sh="&sh;"
exclude-result-prefixes="#all">

    <!-- SHACL is a constraint vocabulary and the validator is this layer's, so the shape labels come
         with it rather than living in Web-Client, which cannot validate anything.

         The move costs the precedence this module used to have. In Web-Client it was imported first
         among the vocabulary modules, deliberately, so that a shape's sh:name lost to every
         data-layer label - dc:title, foaf:name, skos:prefLabel. Nothing in this tree can reproduce
         that: client.xsl imports Web-Client's common.xsl before this one, so every module here
         outranks every vocabulary module there, and import precedence is resolved before priority.
         A resource carrying both sh:name and dc:title therefore now labels as its sh:name. -->

    <xsl:template match="*[sh:name/text()]" mode="ac:label">
        <xsl:sequence select="ac:preferred-lang(sh:name)"/>
    </xsl:template>

    <xsl:template match="*[sh:description/text()]" mode="ac:description">
        <xsl:sequence select="ac:preferred-lang(sh:description)"/>
    </xsl:template>

</xsl:stylesheet>
