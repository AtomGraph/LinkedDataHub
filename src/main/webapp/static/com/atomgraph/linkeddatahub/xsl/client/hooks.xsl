<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>

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
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY lds    "https://w3id.org/atomgraph/linkeddatahub/dataspaces#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:lds="&lds;"
xmlns:sd="&sd;"
exclude-result-prefixes="#all"
>

    <!--
        The browser-only half of the package extension contract (see hooks.xsl for the contract itself
        and the shared open modes). Imported by client.xsl directly, so it may use the client's
        functions freely and needs no product guards.
    -->

    <!-- the children fetch for one tree node, chosen by the domain that owns the tree: the drawer's
         document tree matches its own buttons in client/navigation.xsl, a package's tree matches its
         own. No fallback: a tree whose domain supplies no fetch is not expandable. -->
    <xsl:mode name="ldh:TreeChildrenLoad"/>

    <!-- ldh:RowHook, the factories of deferred work for a rendered row, is not here and not open: a
         factory runs inside ixsl:promise, which is control flow a package does not get (a package has
         no ixsl: at all). The mode and the platform's own rules in it live in client/block.xsl, beside
         the ldh:RenderRow walk that asks it. -->

</xsl:stylesheet>
