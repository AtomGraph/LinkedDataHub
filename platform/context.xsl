<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY ldhc   "https://w3id.org/atomgraph/linkeddatahub/config#">
    <!ENTITY google "https://w3id.org/atomgraph/linkeddatahub/services/google#">
]>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:a="&a;"
xmlns:ac="&ac;"
xmlns:ldhc="&ldhc;"
xmlns:google="&google;"
>
  
    <xsl:output method="xml" indent="yes"/>
  
    <xsl:param name="a:cacheModelLoads"/>
    <xsl:param name="ac:stylesheet"/>
    <xsl:param name="ac:cacheStylesheet"/>
    <xsl:param name="ac:resolvingUncached"/>
    <xsl:param name="ldhc:baseUri"/>
    <xsl:param name="ldhc:proxyScheme"/>
    <xsl:param name="ldhc:proxyHost"/>
    <xsl:param name="ldhc:proxyPort"/>
    <xsl:param name="ldhc:clientKeyStore"/>
    <xsl:param name="ldhc:secretaryCertAlias"/>
    <xsl:param name="ldhc:clientTrustStore"/>
    <xsl:param name="ldhc:clientKeyStorePassword"/>
    <xsl:param name="ldhc:clientTrustStorePassword"/>
    <xsl:param name="ldhc:uploadRoot"/>
    <xsl:param name="ldhc:signUpCertValidity"/>
    <xsl:param name="ldhc:contextDataset"/>
    <xsl:param name="ldhc:authQuery"/>
    <xsl:param name="ldhc:ownerAuthQuery"/>
    <xsl:param name="ldhc:maxContentLength"/>
    <xsl:param name="ldhc:maxConnPerRoute"/>
    <xsl:param name="ldhc:maxTotalConn"/>
    <xsl:param name="ldhc:importKeepAlive"/>
    <xsl:param name="ldhc:notificationAddress"/>
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
            <xsl:if test="$ldhc:baseUri">
                <Parameter name="&ldhc;baseUri" value="{$ldhc:baseUri}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:proxyScheme">
                <Parameter name="&ldhc;proxyScheme" value="{$ldhc:proxyScheme}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:proxyHost">
                <Parameter name="&ldhc;proxyHost" value="{$ldhc:proxyHost}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:proxyPort">
                <Parameter name="&ldhc;proxyPort" value="{$ldhc:proxyPort}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:clientKeyStore">
                <Parameter name="&ldhc;clientKeyStore" value="{$ldhc:clientKeyStore}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:secretaryCertAlias">
                <Parameter name="&ldhc;secretaryCertAlias" value="{$ldhc:secretaryCertAlias}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:clientTrustStore">
                <Parameter name="&ldhc;clientTrustStore" value="{$ldhc:clientTrustStore}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:clientKeyStorePassword">
                <Parameter name="&ldhc;clientKeyStorePassword" value="{$ldhc:clientKeyStorePassword}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:clientTrustStorePassword">
                <Parameter name="&ldhc;clientTrustStorePassword" value="{$ldhc:clientTrustStorePassword}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:uploadRoot">
                <Parameter name="&ldhc;uploadRoot" value="{$ldhc:uploadRoot}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:signUpCertValidity">
                <Parameter name="&ldhc;signUpCertValidity" value="{$ldhc:signUpCertValidity}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:contextDataset">
                <Parameter name="&ldhc;contextDataset" value="{$ldhc:contextDataset}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:authQuery">
                <Parameter name="&ldhc;authQuery" value="{$ldhc:authQuery}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:ownerAuthQuery">
                <Parameter name="&ldhc;ownerAuthQuery" value="{$ldhc:ownerAuthQuery}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:maxContentLength">
                <Parameter name="&ldhc;maxContentLength" value="{$ldhc:maxContentLength}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:maxConnPerRoute">
                <Parameter name="&ldhc;maxConnPerRoute" value="{$ldhc:maxConnPerRoute}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:maxTotalConn">
                <Parameter name="&ldhc;maxTotalConn" value="{$ldhc:maxTotalConn}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:importKeepAlive">
                <Parameter name="&ldhc;importKeepAlive" value="{$ldhc:importKeepAlive}" override="false"/>
            </xsl:if>
            <xsl:if test="$ldhc:notificationAddress">
                <Parameter name="&ldhc;notificationAddress" value="{$ldhc:notificationAddress}" override="false"/>
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