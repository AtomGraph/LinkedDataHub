<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lsmt   "https://w3id.org/atomgraph/linkeddatahub/admin/sitemap/templates#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY lsm    "https://w3id.org/atomgraph/linkeddatahub/admin/sitemap#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:rdf="&rdf;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:spin="&spin;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:template match="*[rdf:type/@rdf:resource][foaf:isPrimaryTopicOf/@rdf:resource][ldh:listSuperClasses(rdf:type/@rdf:resource) = '&lsm;Ontology']" mode="bs2:Actions">
        <xsl:if test="$acl:Agent//@rdf:about">
            <form class="pull-right" action="{foaf:isPrimaryTopicOf/@rdf:resource[starts-with(., $ldt:base)]}" method="get">
                <input type="hidden" name="clear"/>
                <button class="btn btn-primary" type="submit">Clear</button>
            </form>
        </xsl:if>

        <xsl:next-match/>
    </xsl:template>

    <!-- hide extra class -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&lsm;Class'][not(* except rdf:type)]" mode="bs2:Form" priority="1"/>
    
    <xsl:template match="*[@rdf:about = resolve-uri('sitemap/ontologies/', $ldt:base)] | *[@rdf:about = resolve-uri('model/ontologies/', $ldt:base)]" mode="bs2:Right">
        <xsl:if test="$acl:Agent//@rdf:about">
            <div class="well well-small">
                <h2 class="nav-header">Ontology import</h2>
                
                <xsl:if test="$ac:method = 'POST'">
                    <xsl:choose>
                        <xsl:when test="key('resources-by-type', '&spin;ConstraintViolation')">
                            <div class="alert alert-error">
                                <strong>Import failed</strong>
                            </div>
                        </xsl:when>
                        <xsl:otherwise>
                            <div class="alert alert-success">
                                <p>Ontology imported</p>
                            </div>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                    
                <form action="{@rdf:about}" method="post">
                    <input type="hidden" name="rdf"/>

                    <p>
                        <input type="hidden" name="sb" value="source-arg"/>
                        <input type="hidden" name="pu" value="&rdf;type"/>
                        <input type="hidden" name="ou" value="&lsmt;Source"/>
                        <input type="hidden" name="pu" value="&ldt;paramName"/>
                        <input type="hidden" name="ol" value="source"/>
                        <input type="hidden" name="pu" value="&rdf;value"/>
                            
                        <label for="source-{generate-id()}">Ontology URI</label>
                        <input type="text" name="ou" id="source-{generate-id()}"/>
                    </p>
                    
                    <p>
                        <button class="btn btn-primary" type="submit">Import</button>
                    </p>
                </form>
            </div>
        </xsl:if>
        
        <xsl:next-match/>
    </xsl:template>
    
</xsl:stylesheet>