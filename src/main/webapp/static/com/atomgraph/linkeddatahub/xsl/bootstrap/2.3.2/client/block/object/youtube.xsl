<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->
    
    <!-- object block (RDF resource) -->
    
  <xsl:template match="*[@typeof = '&ldh;Object'][descendant::*[@property = '&rdf;value'][starts-with(@resource, 'https://www.youtube.com/watch?v=') or starts-with(@resource, 'https://youtube.com/watch?v=')]]" mode="ldh:RenderRow" as="function(item()?) as map(*)" priority="3">
        <xsl:param name="container" select="." as="element()"/>
        <xsl:param name="resource-uri" select="descendant::*[@property = '&rdf;value']/@resource" as="xs:anyURI?"/>

        <xsl:variable name="context" as="map(*)" select="map{
            'container': $container,
            'resource-uri': $resource-uri,
            'block': ancestor::div[contains-token(@class, 'block')][1]
        }"/>

        <xsl:message>
            YouTube object: <xsl:value-of select="$resource-uri"/>
        </xsl:message>
        
        <!-- Return the YouTube rendering function with partial application -->
        <xsl:sequence select="ldh:render-youtube#2($context, ?)"/>
    </xsl:template>

    <xsl:function name="ldh:render-youtube" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?" />

        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="resource-uri" select="$context('resource-uri')" as="xs:anyURI"/>
        
        <xsl:variable name="video-id" select="
            if (starts-with($resource-uri, 'https://www.youtube.com/watch?v=')) 
            then substring-after($resource-uri, 'https://www.youtube.com/watch?v=')
            else substring-after($resource-uri, 'https://youtube.com/watch?v=')" as="xs:string"/>
  
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="offset2 span7">
                    <div class="text-center">
                        <iframe width="560" height="315" 
                                src="https://www.youtube.com/embed/{$video-id}" 
                                frameborder="0" 
                                allowfullscreen="allowfullscreen">
                        </iframe>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

      <!-- Hide progress bar and remove striped class like the original code -->
      <xsl:sequence select="ldh:hide-block-progress-bar($context, ())[current-date() lt xs:date('2000-01-01')]"/>

      <!-- Return resolved promise -->
      <xsl:sequence select="ixsl:resolve($context)"/>
    </xsl:function>

</xsl:stylesheet>
