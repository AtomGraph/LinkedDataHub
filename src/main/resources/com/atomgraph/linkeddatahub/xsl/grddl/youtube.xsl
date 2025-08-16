<?xml version="1.0" encoding="UTF-8"?>
<!--
  XSLT 3.0 stylesheet for transforming YouTube oEmbed JSON to RDF/XML
  Implements GRDDL pattern for YouTube video metadata
  
  Copyright 2024 Martynas Jusevičius <martynas@atomgraph.com>
  Licensed under the Apache License, Version 2.0
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:schema="https://schema.org/"
    xmlns:dct="http://purl.org/dc/terms/"
    xpath-default-namespace="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="#all">

    <!-- Parameters -->
    <xsl:param name="json" as="xs:string" required="yes"/>
    <xsl:param name="request-uri" as="xs:string" required="yes"/>
    
    <!-- Output RDF/XML -->
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <!-- Main template - processes JSON document -->
    <xsl:template name="xsl:initial-template">
        <!-- Parse JSON into XML -->
        <xsl:variable name="json-xml" select="fn:json-to-xml($json)"/>
        
        <!-- Generate RDF -->
        <rdf:RDF>
            <xsl:apply-templates select="$json-xml"/>
        </rdf:RDF>
    </xsl:template>
    
    <!-- Root JSON map -->
    <xsl:template match="map">
        <schema:VideoObject rdf:about="{$request-uri}">
            <!-- Original URL -->
            <schema:url rdf:resource="{$request-uri}"/>
            
            <xsl:apply-templates select="*"/>
        </schema:VideoObject>
    </xsl:template>
    
    <!-- Title -->
    <xsl:template match="string[@key='title']">
        <schema:name><xsl:value-of select="."/></schema:name>
        <rdfs:label><xsl:value-of select="."/></rdfs:label>
    </xsl:template>
    
    <!-- Author name -->
    <xsl:template match="string[@key='author_name']">
        <xsl:variable name="author-url" select="../string[@key='author_url']"/>
        <schema:creator>
            <xsl:choose>
                <xsl:when test="$author-url">
                    <schema:Person rdf:about="{$author-url}">
                        <schema:name><xsl:value-of select="."/></schema:name>
                    </schema:Person>
                </xsl:when>
                <xsl:otherwise>
                    <schema:Person>
                        <schema:name><xsl:value-of select="."/></schema:name>
                    </schema:Person>
                </xsl:otherwise>
            </xsl:choose>
        </schema:creator>
    </xsl:template>
    
    <!-- Author URL - handled by author_name template -->
    <xsl:template match="string[@key='author_url']"/>
    
    <!-- Width -->
    <xsl:template match="number[@key='width']">
        <schema:width><xsl:value-of select="."/></schema:width>
    </xsl:template>
    
    <!-- Height -->
    <xsl:template match="number[@key='height']">
        <schema:height><xsl:value-of select="."/></schema:height>
    </xsl:template>
    
    <!-- Thumbnail URL -->
    <xsl:template match="string[@key='thumbnail_url']">
        <schema:thumbnailUrl rdf:resource="{.}"/>
        
        <!-- Create thumbnail ImageObject if dimensions are available -->
        <xsl:variable name="thumb-width" select="../number[@key='thumbnail_width']"/>
        <xsl:variable name="thumb-height" select="../number[@key='thumbnail_height']"/>
        <xsl:if test="$thumb-width and $thumb-height">
            <schema:thumbnail>
                <schema:ImageObject rdf:about="{.}">
                    <schema:width><xsl:value-of select="$thumb-width"/></schema:width>
                    <schema:height><xsl:value-of select="$thumb-height"/></schema:height>
                </schema:ImageObject>
            </schema:thumbnail>
        </xsl:if>
    </xsl:template>
    
    <!-- Thumbnail dimensions - handled by thumbnail_url template -->
    <xsl:template match="number[@key='thumbnail_width' or @key='thumbnail_height']"/>
    
    <!-- Provider name -->
    <xsl:template match="string[@key='provider_name']">
        <xsl:variable name="provider-url" select="../string[@key='provider_url']"/>
        <schema:provider>
            <schema:Organization>
                <schema:name><xsl:value-of select="."/></schema:name>
                <xsl:if test="$provider-url">
                    <schema:url rdf:resource="{$provider-url}"/>
                </xsl:if>
            </schema:Organization>
        </schema:provider>
    </xsl:template>
    
    <!-- Provider URL - handled by provider_name template -->
    <xsl:template match="string[@key='provider_url']"/>
    
    <!-- Type -->
    <xsl:template match="string[@key='type']">
        <dct:type><xsl:value-of select="."/></dct:type>
    </xsl:template>
    
    <!-- HTML embed code -->
    <xsl:template match="string[@key='html']">
        <!-- Extract embed URL from iframe src attribute -->
        <xsl:analyze-string select="." regex='src="([^"]+)"'>
            <xsl:matching-substring>
                <schema:embedUrl rdf:resource="{regex-group(1)}"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <!-- Version -->
    <xsl:template match="string[@key='version']">
        <schema:version><xsl:value-of select="."/></schema:version>
    </xsl:template>
    
    <!-- Default template for unhandled JSON elements -->
    <xsl:template match="*">
        <!-- Ignore unhandled elements -->
    </xsl:template>
    
</xsl:stylesheet>