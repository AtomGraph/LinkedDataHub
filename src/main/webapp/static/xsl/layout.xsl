<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs">

    <!-- System stylesheet (lowest priority) -->
    <xsl:import href="../com/atomgraph/linkeddatahub/xsl/layout.xsl"/>

    <!-- the package stylesheets the application imports (its ldh:import data) are composed in memory at compile time - not
         here but into the platform layout stylesheet this file imports, at its hooks.xsl marker, so that they outrank the
         open modes' fallbacks and nothing else; this file is never modified -->

</xsl:stylesheet>
