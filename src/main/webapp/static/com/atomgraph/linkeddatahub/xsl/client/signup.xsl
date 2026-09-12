<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:ldh="&ldh;"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all">

    <!-- the client half of the signup flow: admin/signup.xsl (shared by both products) renders the
         form; the submit interception and its response handling live here so the shared module stays
         free of client machinery -->

    <!-- intercept signup form submit to route the success callback through ldh:signup-form-response -->
    <xsl:template match="form[@id = 'form-signup']" mode="ixsl:onsubmit" priority="3">
        <xsl:next-match>
            <xsl:with-param name="callback" select="ldh:signup-form-response#1"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:function name="ldh:signup-form-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="status" select="$response?status" as="xs:double"/>

        <xsl:choose>
            <xsl:when test="$status = 201 and map:contains($response?headers, 'location')">
                <xsl:for-each select="$response">
                    <xsl:call-template name="ldh:SignUpComplete"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ldh:row-form-response($context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
