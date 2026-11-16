<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY as     "https://www.w3.org/ns/activitystreams#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:as="&as;"
exclude-result-prefixes="#all">

    <!-- This one stylesheet is composed into both the server and the client tree, and it renders and nothing else
         (PackageContract): what the package does - accept messages, send one, reply - is declared in its ontology as
         actions the platform carries out. The inbox lists its messages through its own children view, a message page
         renders its own triples, and the replies to a note come from the ontology's view. What is left is how a
         message reads.

         A note's content is prose someone wrote, not a value to annotate: it renders as paragraphs, split where the
         writer left a blank line, in the property list's value cell (a value leaf, imports/values.xsl), with the cell's
         RDFa attributes as every value cell has them -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/as:content/text()" mode="ac:PropertyListValue">
        <dd>
            <xsl:apply-templates select="." mode="ac:RDFaAttributes"/>

            <xsl:for-each select="tokenize(., '\n\s*\n')[normalize-space()]">
                <p class="ldh-body">
                    <xsl:value-of select="normalize-space(.)"/>
                </p>
            </xsl:for-each>
        </dd>
    </xsl:template>

</xsl:stylesheet>
