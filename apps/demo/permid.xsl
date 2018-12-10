<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY apl    "http://atomgraph.com/ns/platform/domain#">
    <!ENTITY aplt   "http://atomgraph.com/ns/platform/templates#">
    <!ENTITY ac     "http://atomgraph.com/ns/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY pidc   "http://permid.org/ontology/common/">
]>
<xsl:stylesheet version="2.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:aplt="&aplt;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:ldt="&ldt;"
xmlns:dct="&dct;"
xmlns:pidc="&pidc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
xmlns:uuid="java:java.util.UUID"
xmlns:url="java:java.net.URLDecoder"
exclude-result-prefixes="#all">

    <xsl:import href="../../static/com/linkeddatahub/xsl/bootstrap/layout.xsl"/>

    <rdf:Description rdf:nodeID="has-name">
        <dct:title>Name</dct:title>
    </rdf:Description>

    <rdf:Description rdf:nodeID="has-asset-class">
        <dct:title>Asset class</dct:title>
    </rdf:Description>

    <rdf:Description rdf:nodeID="has-instrument-status">
        <dct:title>Status</dct:title>
    </rdf:Description>

    <!-- link to CSS stylesheet -->

    <xsl:template match="rdf:RDF" mode="xhtml:Style">
        <xsl:apply-imports/>

        <link href="{resolve-uri('../uploads/802e46b09118457d6114eb10cec2cad7c661afc', $ldt:base)}" rel="stylesheet" type="text/css"/>
    </xsl:template>

    <!-- hasName as label property -->

    <xsl:template match="pidc:hasName" mode="ac:label">
        <xsl:value-of select="."/>
    </xsl:template>

    <!-- faceted Instrument search -->

    <xsl:template match="rdf:RDF[$ldt:template = resolve-uri('ns/templates#InstrumentContainer', $ldt:base)]" mode="bs2:Filters">
        <xsl:param name="method" select="'get'" as="xs:string"/>
        <xsl:param name="action" select="xs:anyURI($uri)" as="xs:anyURI"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" select="key('resources', key('resources', $rdf:type, $ac:sitemap)/aplt:consumes/@rdf:nodeID, $ac:sitemap)/aplt:mediaType" as="xs:string?"/>
        <xsl:param name="id" as="xs:string?"/>
        <xsl:param name="class" as="xs:string?"/>
        
        <form action="{$action}" method="{$method}">
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

            <xsl:apply-templates select="." mode="bs2:FilterRegex">
                <xsl:with-param name="label-item" select="key('resources', 'has-name', document(''))"/>
                <xsl:with-param name="var-name" select="'hasName'"/>
            </xsl:apply-templates>

            <xsl:apply-templates select="." mode="bs2:FilterIn">
                <xsl:with-param name="label-item" select="key('resources', 'has-asset-class', document(''))"/>
                <xsl:with-param name="var-name" select="'hasAssetClass'"/>
                <xsl:with-param name="items" as="element()*">
                    <rdf:Description rdf:about="https://permid.org/1-300281">
                        <dct:title>Ordinary Shares</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300413">
                        <dct:title>Rights</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302539">
                        <dct:title>Fully Paid Ordinary Shares</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300016">
                        <dct:title>American Depository Receipts</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302043">
                        <dct:title>Units</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300334">
                        <dct:title>Closed-End Funds</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300089">
                        <dct:title>Depository Receipts</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302364">
                        <dct:title>Deferred Shares</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302117">
                        <dct:title>Company Options</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300295">
                        <dct:title>Subscription Rights</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300136">
                        <dct:title>Global Depository Receipts</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302547">
                        <dct:title>Paid Subscription Rights</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302035">
                        <dct:title>Participation Shares</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302543">
                        <dct:title>Thai Non-Voting Depository Receipts</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302542">
                        <dct:title>Argentinian Depository Receipts</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302113">
                        <dct:title>Genussscheine</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302366">
                        <dct:title>Brazilian Depository Receipts</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-300100">
                        <dct:title>Equities</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302106">
                        <dct:title>CHESS Depository Interests</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="https://permid.org/1-302538">
                        <dct:title>Stock Dividends</dct:title>
                    </rdf:Description>
                </xsl:with-param>
            </xsl:apply-templates>
        
            <xsl:apply-templates select="." mode="bs2:FilterIn">
                <xsl:with-param name="label-item" select="key('resources', 'has-instrument-status', document(''))"/>
                <xsl:with-param name="var-name" select="'hasInstrumentStatus'"/>
                <xsl:with-param name="items" as="element()*">
                    <rdf:Description rdf:about="http://permid.org/ontology/financial/instrumentStatusInActive">
                        <dct:title>Inactive</dct:title>
                    </rdf:Description>
                    <rdf:Description rdf:about="http://permid.org/ontology/financial/instrumentStatusActive">
                        <dct:title>Active</dct:title>
                    </rdf:Description>
                </xsl:with-param>
            </xsl:apply-templates>
            
            <div class="form-actions">
                <button type="submit" class="btn" title="{ac:label(key('resources', 'filter-title', document('../../static/com/atomgraph/platform/xsl/bootstrap/2.3.2/translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', 'filter', document('../../static/com/atomgraph/platform/xsl/bootstrap/2.3.2/translations.rdf'))" mode="apl:logo"/>
                </button>
                <xsl:text> </xsl:text>
                <button type="reset" class="btn pull-right" title="{ac:label(key('resources', 'reset-changes-title', document('../../static/com/atomgraph/platform/xsl/bootstrap/2.3.2/translations.rdf')))}">
                    <xsl:apply-templates select="key('resources', 'reset', document('../../static/com/atomgraph/platform/xsl/bootstrap/2.3.2/translations.rdf'))" mode="apl:logo"/>
                </button>
            </div>
        </form>
    </xsl:template>
    
</xsl:stylesheet>