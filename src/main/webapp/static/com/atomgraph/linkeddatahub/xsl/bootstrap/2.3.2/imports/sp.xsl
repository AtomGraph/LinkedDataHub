<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
]>
<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:sp="&sp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">
    
    <xsl:template match="*[@rdf:about = '&sp;Ask']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'ask-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Select']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'select-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Describe']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'describe-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <xsl:template match="*[@rdf:about = '&sp;Construct']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'construct-query', document('../translations.rdf'))" mode="#current"/>
    </xsl:template>

    <!-- BLOCK MODE -->

    <xsl:template match="*[ixsl:query-params()?mode = '&ac;ContentMode'][sp:text/text()]" mode="bs2:Block" use-when="system-property('xsl:product-name') eq 'SaxonJS'">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI('')" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" select="'sparql-query-form form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/>
        <xsl:param name="textarea-id" select="'id' || ac:uuid()" as="xs:string"/>
        <xsl:param name="mode" as="xs:anyURI*"/>
        <xsl:param name="service" as="xs:anyURI?"/>
        <xsl:param name="endpoint" as="xs:anyURI?"/>
        <xsl:param name="query" select="sp:text" as="xs:string"/>
        
        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset" select="$accept-charset"/>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype" select="$enctype"/>
            </xsl:if>

<!--            <fieldset>-->
                <div class="control-group">
                    <label class="control-label">Service</label> <!-- for="service" -->

                    <div class="controls">
                        <select name="service" class="input-xxlarge input-query-service">
                            <option value="">
                                <xsl:value-of>
                                    <xsl:text>[</xsl:text>
                                    <xsl:apply-templates select="key('resources', 'sparql-service', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                                    <xsl:text>]</xsl:text>
                                </xsl:value-of>
                            </option>
                        </select>
                    </div>
                </div>
                
<!--                <div class="control-group required">
                    <label class="control-label">Title</label>

                    <div class="controls">
                        <input type="text" name="title"/>
                    </div>
                </div>-->
        
                <textarea name="query" class="span12" rows="15">
                    <xsl:if test="$textarea-id">
                        <xsl:attribute name="id" select="$textarea-id"/>
                    </xsl:if>
                    
                    <xsl:value-of select="$query"/>
                </textarea>

                <div class="form-actions">
                    <button type="submit">
                        <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                            <xsl:with-param name="class" select="'btn btn-primary btn-run-query'"/>
                        </xsl:apply-templates>

                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'run', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
<!--                    <button type="button" class="btn btn-primary btn-save btn-save-query">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                    <button type="button" class="btn btn-cancel">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'cancel', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>-->
                </div>
<!--            </fieldset>-->
        </form>
    </xsl:template>
    
    <xsl:template match="sp:text/text() | *[@rdf:*[local-name() = 'nodeID']]/sp:text/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControl">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <textarea name="ol" id="{generate-id()}" class="sp:text" rows="10" style="font-family: monospace;">
            <xsl:if test="self::text()">
                <xsl:value-of select="."/>
            </xsl:if>
        </textarea>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/text() | *[@rdf:*[local-name() = 'nodeID']]/sp:text/@rdf:*[local-name() = 'nodeID'][key('resources', .)[not(* except rdf:type[@rdf:resource = '&xsd;string'])]]" mode="bs2:FormControlTypeLabel">
        <xsl:param name="type" as="xs:string?"/>

        <xsl:if test="not($type = 'hidden')">
            <span class="help-inline">Literal</span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sp:text/@rdf:datatype" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="type" select="'hidden'"/>
        </xsl:next-match>
    </xsl:template>
    
</xsl:stylesheet>