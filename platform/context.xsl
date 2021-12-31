<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY aplc   "https://w3id.org/atomgraph/linkeddatahub/config#">
    <!ENTITY google "https://w3id.org/atomgraph/linkeddatahub/services/google#">
]>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:a="&a;"
xmlns:ac="&ac;"
xmlns:aplc="&aplc;"
xmlns:google="&google;"
>
  
    <xsl:output method="xml" indent="yes"/>
  
    <xsl:param name="a:cacheModelLoads"/>
    <xsl:param name="ac:stylesheet"/>
    <xsl:param name="ac:cacheStylesheet"/>
    <xsl:param name="ac:resolvingUncached"/>
    <xsl:param name="aplc:baseUri"/>
    <xsl:param name="aplc:proxyScheme"/>
    <xsl:param name="aplc:proxyHost"/>
    <xsl:param name="aplc:proxyPort"/>
    <xsl:param name="aplc:clientKeyStore"/>
    <xsl:param name="aplc:secretaryCertAlias"/>
    <xsl:param name="aplc:clientTrustStore"/>
    <xsl:param name="aplc:clientKeyStorePassword"/>
    <xsl:param name="aplc:clientTrustStorePassword"/>
    <xsl:param name="aplc:uploadRoot"/>
    <xsl:param name="aplc:signUpCertValidity"/>
    <xsl:param name="aplc:contextDataset"/>
    <xsl:param name="aplc:authQuery"/>
    <xsl:param name="aplc:ownerAuthQuery"/>
    <xsl:param name="aplc:maxContentLength"/>
    <xsl:param name="aplc:maxConnPerRoute"/>
    <xsl:param name="aplc:maxTotalConn"/>
    <xsl:param name="aplc:importKeepAlive"/>
    <xsl:param name="aplc:notificationAddress"/>
    <xsl:param name="mail.smtp.host"/>
    <xsl:param name="mail.smtp.port"/>
    <xsl:param name="mail.user"/>
    <xsl:param name="mail.password"/>
    <xsl:param name="google:clientID"/>
    <xsl:param name="google:clientSecret"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="Context">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>

            <xsl:if test="$a:cacheModelLoads">
                <Parameter name="&a;cacheModelLoads" value="{$a:cacheModelLoads}" override="false"/>
            </xsl:if>
            <xsl:if test="$ac:stylesheet">
                <Parameter name="&ac;stylesheet" value="{$ac:stylesheet}" override="false"/>
            </xsl:if>
            <xsl:if test="$ac:cacheStylesheet">
                <Parameter name="&ac;cacheStylesheet" value="{$ac:cacheStylesheet}" override="false"/>
            </xsl:if>
            <xsl:if test="$ac:resolvingUncached">
                <Parameter name="&ac;resolvingUncached" value="{$ac:resolvingUncached}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:baseUri">
                <Parameter name="&aplc;baseUri" value="{$aplc:baseUri}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:proxyScheme">
                <Parameter name="&aplc;proxyScheme" value="{$aplc:proxyScheme}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:proxyHost">
                <Parameter name="&aplc;proxyHost" value="{$aplc:proxyHost}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:proxyPort">
                <Parameter name="&aplc;proxyPort" value="{$aplc:proxyPort}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:clientKeyStore">
                <Parameter name="&aplc;clientKeyStore" value="{$aplc:clientKeyStore}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:secretaryCertAlias">
                <Parameter name="&aplc;secretaryCertAlias" value="{$aplc:secretaryCertAlias}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:clientTrustStore">
                <Parameter name="&aplc;clientTrustStore" value="{$aplc:clientTrustStore}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:clientKeyStorePassword">
                <Parameter name="&aplc;clientKeyStorePassword" value="{$aplc:clientKeyStorePassword}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:clientTrustStorePassword">
                <Parameter name="&aplc;clientTrustStorePassword" value="{$aplc:clientTrustStorePassword}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:uploadRoot">
                <Parameter name="&aplc;uploadRoot" value="{$aplc:uploadRoot}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:signUpCertValidity">
                <Parameter name="&aplc;signUpCertValidity" value="{$aplc:signUpCertValidity}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:contextDataset">
                <Parameter name="&aplc;contextDataset" value="{$aplc:contextDataset}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:authQuery">
                <Parameter name="&aplc;authQuery" value="{$aplc:authQuery}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:ownerAuthQuery">
                <Parameter name="&aplc;ownerAuthQuery" value="{$aplc:ownerAuthQuery}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:maxContentLength">
                <Parameter name="&aplc;maxContentLength" value="{$aplc:maxContentLength}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:maxConnPerRoute">
                <Parameter name="&aplc;maxConnPerRoute" value="{$aplc:maxConnPerRoute}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:maxTotalConn">
                <Parameter name="&aplc;maxTotalConn" value="{$aplc:maxTotalConn}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:importKeepAlive">
                <Parameter name="&aplc;importKeepAlive" value="{$aplc:importKeepAlive}" override="false"/>
            </xsl:if>
            <xsl:if test="$aplc:notificationAddress">
                <Parameter name="&aplc;notificationAddress" value="{$aplc:notificationAddress}" override="false"/>
            </xsl:if>
            <xsl:if test="$mail.smtp.host">
                <Parameter name="mail.smtp.host" value="{$mail.smtp.host}" override="false"/>
            </xsl:if>
            <xsl:if test="$mail.smtp.port">
                <Parameter name="mail.smtp.port" value="{$mail.smtp.port}" override="false"/>
            </xsl:if>
            <xsl:if test="$mail.user">
                <Parameter name="mail.user" value="{$mail.user}" override="false"/>
            </xsl:if>
            <xsl:if test="$mail.password">
                <Parameter name="mail.password" value="{$mail.password}" override="false"/>
            </xsl:if>
            <xsl:if test="$google:clientID">
                <Parameter name="&google;clientID" value="{$google:clientID}" override="false"/>
            </xsl:if>
            <xsl:if test="$google:clientSecret">
                <Parameter name="&google;clientSecret" value="{$google:clientSecret}" override="false"/>
            </xsl:if>

            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- suppress existing parameters -->
    <xsl:template match="Parameter"/>

</xsl:stylesheet>