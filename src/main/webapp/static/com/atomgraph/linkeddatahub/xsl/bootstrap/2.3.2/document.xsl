<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY http   "http://www.w3.org/2011/http#">
    <!ENTITY sc     "http://www.w3.org/2011/http-statusCodes#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
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
xmlns:apl="&apl;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:http="&http;"
xmlns:acl="&acl;"
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
    
    <xsl:param name="main-doc" select="/" as="document-node()"/>
    <xsl:param name="acl:Agent" as="document-node()?"/>
    <xsl:param name="acl:mode" select="$acl:Agent//*[acl:accessToClass/@rdf:resource = (key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource, key('resources', $ac:uri, $main-doc)/rdf:type/@rdf:resource/apl:listSuperClasses(.))]/acl:mode/@rdf:resource" as="xs:anyURI*"/>

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

    <xsl:template match="rdf:RDF" mode="bs2:ModalForm" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="ac:build-uri($a:graphStore, map{ 'forClass': string($ac:forClass), 'mode': '&ac;ModalMode' })" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/> <!-- TO-DO: override with "multipart/form-data" for File instances -->
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>

        <div class="modal modal-constructor fade in">
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

                <div class="modal-header">
                    <button type="button" class="close">&#215;</button>

                    <!--<xsl:apply-templates select="." mode="bs2:Legend"/>-->
                </div>

                <div class="modal-body">
                    <xsl:apply-templates mode="bs2:Exception"/>

                    <xsl:choose>
                        <xsl:when test="$ac:forClass and not(key('resources-by-type', '&spin;ConstraintViolation'))">
                            <xsl:apply-templates select="ac:construct-doc($ldt:ontology, $ac:forClass, $ldt:base)/rdf:RDF/*" mode="bs2:Form">
                                <xsl:with-param name="inline" select="false()" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="bs2:Form">
                                <xsl:sort select="ac:label(.)"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>

                    <!--<xsl:apply-templates select="." mode="bs2:Create"/>-->
                </div>

                <xsl:apply-templates select="." mode="bs2:FormActions">
                    <xsl:with-param name="modal" select="true()"/>
                    <xsl:with-param name="button-class" select="$button-class"/>
                </xsl:apply-templates>
            </form>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:RDF" mode="bs2:Form" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI(if (not(starts-with($ac:uri, $ac:contextUri))) then ac:build-uri($ldt:base, map { 'uri': string($ac:uri) }) else $ac:uri)" as="xs:anyURI"/>
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/> <!-- TO-DO: override with "multipart/form-data" for File instances -->
        <xsl:param name="button-class" select="'btn btn-primary wymupdate'" as="xs:string?"/>

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
                    <xsl:apply-templates select="*" mode="#current">
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
    
    <!-- FORM ACTIONS -->
    
    <xsl:template match="rdf:RDF" mode="bs2:FormActions">
        <xsl:param name="modal" select="false()" as="xs:boolean"/>
        <xsl:param name="button-class" select="'btn btn-primary'" as="xs:string?"/>
        
        <div class="form-actions {if ($modal) then 'modal-footer' else ''}">
            <button type="submit" class="{$button-class}">
                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="$button-class"/>
                </xsl:apply-templates>
            </button>
            <button type="button" class="btn">
                <xsl:apply-templates select="key('resources', 'close', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
            <button type="reset" class="btn">
                <xsl:apply-templates select="key('resources', 'reset', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn'"/>
                </xsl:apply-templates>
            </button>
        </div>
    </xsl:template>

    <!-- EXCEPTION -->
    
    <xsl:template match="*[http:sc/@rdf:resource = '&sc;Conflict']" mode="bs2:Exception" priority="1">
        <xsl:param name="class" select="'alert alert-error'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document(ac:document-uri('&apl;')))" mode="apl:logo">
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
            <xsl:text> </xsl:text>
            <xsl:value-of>
                <xsl:apply-templates select="key('resources', '&apl;ResourceExistsException', document(ac:document-uri('&apl;')))" mode="ac:label"/>
            </xsl:value-of>
        </div>
    </xsl:template>
    
    <!-- CREATE -->
    
    <xsl:template match="rdf:RDF[$acl:mode = '&acl;Append'][$ldt:ontology]" mode="bs2:Create" priority="1">
        <xsl:param name="class" select="'btn-group'" as="xs:string?"/>

        <div>
            <xsl:if test="$class">
                <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
            </xsl:if>
            
            <button type="button" title="{ac:label(key('resources', 'create-instance-title', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="apl:logo">
                    <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                </xsl:apply-templates>
                <xsl:value-of>
                    <xsl:apply-templates select="key('resources', '&ac;ConstructMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
                </xsl:value-of>
                <xsl:text> </xsl:text>
                <span class="caret"></span>
            </button>

            <xsl:variable name="this" select="@rdf:about"/>
            <ul class="dropdown-menu">
                <xsl:variable name="default-classes" select="key('resources', (resolve-uri('ns/domain/system#GenericService', $ldt:base), resolve-uri('ns/domain/system#DydraService', $ldt:base), resolve-uri('ns/domain/system#Construct', $ldt:base), resolve-uri('ns/domain/system#Describe', $ldt:base), resolve-uri('ns/domain/system#Select', $ldt:base), resolve-uri('ns/domain/system#Ask', $ldt:base), resolve-uri('ns/domain/system#File', $ldt:base), resolve-uri('ns/domain/system#CSVImport', $ldt:base), resolve-uri('ns/domain/system#RDFImport', $ldt:base), resolve-uri('ns/domain/system#GraphChart', $ldt:base), resolve-uri('ns/domain/system#ResultSetChart', $ldt:base)), document(resolve-uri('ns/domain/system', $ldt:base)))" as="element()*"/>
                <xsl:variable name="constructor-list" as="element()*">
                    <xsl:call-template name="bs2:ConstructorList">
                        <xsl:with-param name="ontology" select="$ldt:ontology"/>
                        <xsl:with-param name="visited-classes" select="$default-classes"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:copy-of select="$constructor-list"/>
                
                <xsl:if test="$constructor-list and $default-classes">
                    <li class="divider"></li>
                </xsl:if>

                <!--if the current resource is a Container, show Container and Item constructors--> 
                <xsl:variable name="document-classes" select="key('resources', (resolve-uri('ns/domain/default#Container', $ldt:base), resolve-uri('ns/domain/default#Item', $ldt:base)), document(resolve-uri('ns/domain/default', $ldt:base)))" as="element()*"/>
                <!-- current resource is a container -->
                <xsl:if test="exists($document-classes) and key('resources', $ac:uri)/rdf:type/@rdf:resource = (resolve-uri('ns/domain/default#Root', $ldt:base), resolve-uri('ns/domain/default#Container', $ldt:base))">
                    <xsl:apply-templates select="$document-classes" mode="bs2:ConstructorListItem">
                        <xsl:sort select="ac:label(.)"/>
                    </xsl:apply-templates>

                    <xsl:if test="$default-classes">
                        <li class="divider"></li>
                    </xsl:if>
                </xsl:if>

                <xsl:apply-templates select="$default-classes" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="bs2:Create"/>

    <xsl:template name="bs2:ConstructorList">
        <xsl:param name="ontology" as="xs:anyURI"/>
        <xsl:param name="visited-classes" as="element()*"/>

        <!-- check if ontology document is available -->
        <xsl:if test="doc-available(ac:document-uri($ontology))">
            <xsl:variable name="ont-doc" select="document(ac:document-uri($ontology))" as="document-node()"/>
            <xsl:variable name="constructor-list" as="element()*">
                <xsl:variable name="classes" select="$ont-doc/rdf:RDF/*[@rdf:about][rdfs:isDefinedBy/@rdf:resource = $ontology][spin:constructor or (rdfs:subClassOf and apl:listSuperClasses(@rdf:about)/../../spin:constructor)]" as="element()*"/>
                <!-- eliminate matches where a class is a subclass of itself (happens in inferenced ontology models) -->
                <xsl:apply-templates select="$classes[not(@rdf:about = $visited-classes/@rdf:about)][let $about := @rdf:about return not(@rdf:about = ($classes, $visited-classes)[not(@rdf:about = $about)]/rdfs:subClassOf/@rdf:resource)][not((@rdf:about, apl:listSuperClasses(@rdf:about)) = ('&dh;Document', '&ldt;Parameter'))]" mode="bs2:ConstructorListItem">
                    <xsl:sort select="ac:label(.)"/>
                </xsl:apply-templates>

                <!-- show user-defined classes. Apply to owl:imported ontologies recursively -->
                <xsl:for-each select="key('resources', $ontology, $ont-doc)/owl:imports/@rdf:resource">
                    <xsl:call-template name="bs2:ConstructorList">
                        <xsl:with-param name="ontology" select="."/>
                        <xsl:with-param name="visited-classes" select="($visited-classes, $classes)"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:variable>
            <!-- avoid nesting lists without items (classes) -->
            <xsl:if test="$constructor-list">
                <ul>
                    <xsl:copy-of select="$constructor-list"/>
                </ul>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- OBJECT -->
    
    <xsl:template match="rdf:RDF" mode="bs2:Object">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
</xsl:stylesheet>
