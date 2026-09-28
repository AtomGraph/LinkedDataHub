<?xml version="1.0" encoding="UTF-8"?>
<!-- A package stylesheet that tries to take over the page, used by PATCH-settings-package-containment.sh.

     Three rules, one per outcome the import tiering promises:
       ac:Head          sealed by the platform's own rule: this one must LOSE, whatever its priority
       ldh:ContentBody  sealed the same way: must lose
       ldh:ContentColumn an open mode with no platform rule: must WIN and render the column
       ac:PropertyListValue  an open VALUE mode whose generic rule the platform keeps below the packages
                        (imports/values.xsl): a rule for one property must WIN over it and mark the cell
       ac:FormControl   the same tier on the edit path; the form is rendered in the browser, so this
                        one is for a client-side check, not for the XHTML fetch
     Each leaves a marker the test counts with XPath. -->
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ac="https://w3id.org/atomgraph/client#"
xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:srx="http://www.w3.org/2005/sparql-results#"
xmlns:dct="http://purl.org/dc/terms/"
exclude-result-prefixes="#all"
>

    <xsl:template match="rdf:RDF | srx:sparql" mode="ac:Head" priority="100">
        <head>
            <meta name="containment-probe" content="head"/>
            <title>containment probe</title>
        </head>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="ldh:ContentBody" priority="100">
        <div id="containment-probe-body"/>
    </xsl:template>

    <xsl:template match="rdf:RDF" mode="ldh:ContentColumn">
        <div id="containment-probe-column">column</div>
    </xsl:template>

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/dct:title/text()" mode="ac:PropertyListValue">
        <dd data-containment-probe="title">
            <xsl:value-of select="."/>
        </dd>
    </xsl:template>

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/dct:title" mode="ac:FormControl">
        <input type="hidden" name="containment-probe-control" value="title"/>
        <xsl:next-match/>
    </xsl:template>

</xsl:stylesheet>
