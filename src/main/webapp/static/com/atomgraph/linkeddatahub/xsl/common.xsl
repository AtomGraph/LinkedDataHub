<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
exclude-result-prefixes="#all">

    <!-- the shared LinkedDataHub layer over Web-Client's: the value/property dispatch overrides, the
         resource and block renderers, the vocabulary modules and the document layer - aggregated once
         so both products (layout.xsl SSR, client.xsl CSR) inherit one precedence order instead of two
         hand-kept lists. Import order IS the precedence ladder (XSLT 3.0 §3.10.3): no module may enter
         any closure twice, and additions belong on the right rung here, not in the masters. The
         Web-Client base is imported by the master (internal-layout for SSR, common for CSR), not here:
         which Web-Client flavor applies is the one real product difference. -->

    <xsl:import href="merge-rdfxml.xsl"/>
    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="resource.xsl"/>
    <xsl:import href="imports/ac.xsl"/>
    <xsl:import href="imports/acl.xsl"/>
    <xsl:import href="imports/cert.xsl"/>
    <xsl:import href="imports/ldh.xsl"/>
    <xsl:import href="imports/dct.xsl"/>
    <xsl:import href="imports/nfo.xsl"/>
    <xsl:import href="imports/rdf.xsl"/>
    <xsl:import href="imports/sioc.xsl"/>
    <xsl:import href="imports/sp.xsl"/>
    <xsl:import href="imports/memento.xsl"/>
    <xsl:import href="imports/services/youtube.xsl"/>
    <xsl:import href="document.xsl"/>

</xsl:stylesheet>
