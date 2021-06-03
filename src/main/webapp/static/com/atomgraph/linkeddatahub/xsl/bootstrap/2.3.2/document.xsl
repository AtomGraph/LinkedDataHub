<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY void   "http://rdfs.org/ns/void#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:lacl="&lacl;"
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:http="&http;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:geo="&geo;"
xmlns:void="&void;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
exclude-result-prefixes="#all"
extension-element-prefixes="ixsl"
>
    
    <!-- BODY -->
    
    <!-- always show errors (except ConstraintViolations) in block mode -->
    <xsl:template match="rdf:RDF[not(key('resources', $ac:uri))][key('resources-by-type', '&http;Response')][not(key('resources-by-type', '&spin;ConstraintViolation'))]" mode="xhtml:Body" priority="1">
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'span12'" as="xs:string?"/>
        
        <div>
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
        
            <xsl:apply-templates mode="bs2:Block"/>
        </div>
    </xsl:template>

    <!-- RIGHT -->
    
    <!-- suppress most properties of the current document in the right nav, except some basic metadata -->
<!--    <xsl:template match="*[@rdf:about = $ac:uri][dct:created or dct:modified or foaf:maker or acl:owner or foaf:primaryTopic or dh:select]" mode="bs2:Right" priority="1">
        <xsl:variable name="definitions" as="document-node()">
            <xsl:document>
                <dl class="dl-horizontal">
                    <xsl:apply-templates select="dct:created | dct:modified | foaf:maker | acl:owner | foaf:primaryTopic | dh:select" mode="bs2:PropertyList">
                        <xsl:sort select="ac:property-label(.)" order="ascending" lang="{$ldt:lang}"/>
                        <xsl:sort select="if (exists((text(), @rdf:resource, @rdf:nodeID))) then ac:object-label((text(), @rdf:resource, @rdf:nodeID)[1]) else()" order="ascending" lang="{$ldt:lang}"/>
                    </xsl:apply-templates>
                </dl>
            </xsl:document>
        </xsl:variable>

        <xsl:if test="$definitions/*/*">
            <div class="well well-small">
                <xsl:apply-templates select="$definitions" mode="bs2:PropertyListIdentity"/>
            </div>
        </xsl:if>
    </xsl:template>-->
    
    <!-- GRAPH  -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Graph">
        <xsl:apply-templates select="." mode="ac:SVG">
            <xsl:with-param name="width" select="'100%'"/>
            <xsl:with-param name="spring-length" select="150" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- FORM -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Form" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="modal" select="false()" as="xs:boolean" tunnel="yes"/>
        <!-- append client mode parameter (which does not reach the server and therefore is not part of the hypermedia state arguments -->
        <!-- TO-DO: make action a tunnel param? -->
        <xsl:param name="action" select="xs:anyURI(if (not(starts-with($ac:uri, $ac:contextUri))) then ac:build-uri($ldt:base, map { 'uri': string($ac:uri), 'mode': if ($modal) then '&ac;ModalMode' else () }) else if ($modal) then if (contains($ac:uri, '?')) then concat($ac:uri, '&amp;mode=', encode-for-uri('&ac;ModalMode')) else ac:build-uri($ac:uri, map{ 'mode': '&ac;ModalMode' }) else $ac:uri)" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/> <!-- TO-DO: override with "multipart/form-data" for File instances -->

        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset"><xsl:value-of select="$accept-charset"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype"><xsl:value-of select="$enctype"/></xsl:attribute>
            </xsl:if>

            <xsl:comment>This form uses RDF/POST encoding: http://www.lsrn.org/semweb/rdfpost.html</xsl:comment>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'rdf'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>

            <input type="hidden" class="target-id"/>

            <xsl:apply-templates mode="bs2:Exception"/>

            <xsl:choose>
                <xsl:when test="$ac:forClass and not(key('resources-by-type', '&spin;ConstraintViolation'))">
                    <xsl:apply-templates select="ac:construct-doc($ldt:ontology, $ac:forClass, $ldt:base)/rdf:RDF/*" mode="#current">
                        <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current">
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:apply-templates select="." mode="bs2:Create"/>

            <xsl:apply-templates select="." mode="bs2:FormActions">
                <xsl:with-param name="button-class" select="$button-class"/>
            </xsl:apply-templates>
        </form>
    </xsl:template>
    

    <!-- hide constraint violations and HTTP responses in the form - they are displayed as errors on the edited resources -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&spin;ConstraintViolation'] | *[rdf:type/@rdf:resource = '&http;Response']" mode="bs2:Form" priority="2"/>

    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/*" mode="bs2:TypeControl" priority="1"/>
    
    <!-- hide property dropdown -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/*" mode="bs2:PropertyControl" priority="1"/>

    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']" mode="bs2:FormControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="legend" select="false()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- hide Content's rdf:first property -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/rdf:first" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="#current"/>
        
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- hide Content's rdf:rest property and object -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&apl;Content']/rdf:rest" mode="bs2:FormControl" priority="1">
        <xsl:apply-templates select="." mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID" mode="xhtml:Input">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="@xml:lang | @rdf:datatype" mode="#current">
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- LEGEND -->
    
<!--    <xsl:template match="*[rdf:type/@rdf:resource = $ac:forClass][*[not(self::rdf:type)]]" mode="bs2:Legend" priority="1">
        <xsl:param name="forClass" select="$ac:forClass" as="xs:anyURI"/>

        <xsl:choose>
            <xsl:when test="key('resources', $forClass)">
                <xsl:for-each select="key('resources', $forClass)">
                    <legend title="{@rdf:about}">
                        <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of>
                            <xsl:apply-templates select="." mode="ac:label"/>
                        </xsl:value-of>
                    </legend>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <legend title="{$forClass}">
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document('&ac;'))" mode="apl:logo"/>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <xsl:when test="doc-available(ac:document-uri($forClass))">
                            <xsl:apply-templates select="key('resources', $forClass, document(ac:document-uri($forClass)))" mode="ac:label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$forClass"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </legend>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[*][@rdf:about or @rdf:nodeID]" mode="bs2:Legend"/>-->
    
    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document('&apl;'))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document('&apl;'))" mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>
    
    <!-- OBJECT -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
</xsl:stylesheet>
