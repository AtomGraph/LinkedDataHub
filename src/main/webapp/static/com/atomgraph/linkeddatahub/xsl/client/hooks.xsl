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

    <!-- Which relation a tree follows, answered by the domain that owns the tree as DATA, never as
         work: a rule returns a map of predicates and client/tree.xsl builds and runs the queries.
         Both modes answer with the same shape, the two directions RDF lets a link be asserted in:

             map{ 'parent-properties': xs:anyURI*,    asserted on the child, pointing at its parent
                  'child-properties':  xs:anyURI* }   asserted on the parent, pointing at its children

         (or map{ 'query': xs:string } with a children CONSTRUCT of a shape this module does not
         generate, sent as given). deep-skip: a tree whose domain answers nothing is not expandable,
         or is not climbed.

         ldh:TreeChildrenLoad is applied to a node's disclosure button, so a domain selects the relation
         by matching the tree the button sits in - and by depth, where the relation changes level by
         level (a scheme's top concepts, then a concept's narrower concepts). The drawer's document tree
         matches its own buttons in client/navigation.xsl, a package's tree matches its own.

         ldh:TreeParentsLoad is applied to the ul.ldh-tree itself, once, when the tree asks for a node
         to be revealed (data-tree-reveal): the relation the climb follows up from that node, one hop per
         request, to find the ancestors the descent then opens. -->
    <xsl:mode name="ldh:TreeChildrenLoad" on-no-match="deep-skip"/>
    <xsl:mode name="ldh:TreeParentsLoad" on-no-match="deep-skip"/>

    <!-- ldh:RowHook, the factories of deferred work for a rendered row, is not here and not open: a
         factory runs inside ixsl:promise, which is control flow a package does not get (a package has
         no ixsl: at all). The mode and the platform's own rules in it live in client/block.xsl, beside
         the ldh:RenderRow walk that asks it. -->

</xsl:stylesheet>
