<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lapp "https://w3id.org/atomgraph/linkeddatahub/apps#">
]>
<!-- a deployment's own entry: imports the stock stylesheet, declares an entity, includes a module of its own -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <xsl:import href="../stock/client.xsl"/>
    <xsl:include href="grid.xsl"/>
    <xsl:template match="*[rdf:type/@rdf:resource = '&lapp;Application']" mode="ac:Grid" xmlns:ac="https://w3id.org/atomgraph/client#"/>
</xsl:stylesheet>
