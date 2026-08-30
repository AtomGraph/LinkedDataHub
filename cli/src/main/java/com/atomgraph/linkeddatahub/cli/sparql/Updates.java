/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.sparql;

import java.net.URI;
import org.apache.jena.query.ParameterizedSparqlString;

/**
 * SPARQL update templates for the PATCH-based commands. All templates are standard SPARQL 1.1;
 * IRIs are injected via {@link ParameterizedSparqlString} to guarantee correct escaping.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Updates
{

    private Updates() { }

    /**
     * Adds an <code>owl:imports</code> statement to the ontology that is the primary topic
     * of the given document.
     *
     * @param ontologyDoc ontology document URI
     * @param importURI imported ontology URI
     * @return SPARQL update string
     */
    public static String insertOntologyImport(URI ontologyDoc, URI importURI)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString("""
            PREFIX owl:	<http://www.w3.org/2002/07/owl#>
            PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
            INSERT {
              ?ontology owl:imports ?import .
            }
            WHERE {
              ?doc foaf:primaryTopic ?ontology .
            }
            """);
        pss.setIri("doc", ontologyDoc.toString());
        pss.setIri("import", importURI.toString());
        return pss.toString();
    }

    /**
     * Adds a <code>foaf:member</code> statement to the group that is the primary topic
     * of the given document.
     *
     * @param groupDoc group document URI
     * @param agent agent URI
     * @return SPARQL update string
     */
    public static String insertGroupMember(URI groupDoc, URI agent)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString("""
            PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
            INSERT {
              ?group foaf:member ?agent .
            }
            WHERE {
              ?doc foaf:primaryTopic ?group .
            }
            """);
        pss.setIri("doc", groupDoc.toString());
        pss.setIri("agent", agent.toString());
        return pss.toString();
    }

    /**
     * Removes a content block (or all content blocks) from a document, together with the
     * block's own description.
     *
     * @param doc document URI
     * @param block block URI, or null to remove all blocks
     * @return SPARQL update string
     */
    public static String removeBlock(URI doc, URI block)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString("""
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE
            {
                ?doc ?seq ?block .
                ?block ?p ?o .
            }
            WHERE
            {
                ?doc ?seq ?block .
                FILTER(strstarts(str(?seq), concat(str(rdf:), "_")))
                OPTIONAL
                {
                    ?block ?p ?o
                }
            }
            """);
        pss.setIri("doc", doc.toString());
        if (block != null) pss.setIri("block", block.toString());
        return pss.toString();
    }

    /**
     * Makes all end-user application documents publicly readable and allows queries over POST,
     * by extending the built-in public authorization.
     *
     * @param base end-user application base URI
     * @param adminBase admin application base URI
     * @return SPARQL update string
     */
    public static String makePublic(URI base, URI adminBase)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString("""
            PREFIX  acl: <http://www.w3.org/ns/auth/acl#>
            PREFIX  def: <https://w3id.org/atomgraph/linkeddatahub/default#>
            PREFIX  dh:  <https://www.w3.org/ns/ldt/document-hierarchy#>
            PREFIX  nfo: <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>
            PREFIX  foaf: <http://xmlns.com/foaf/0.1/>

            INSERT
            {
              ?public acl:accessToClass def:Root, dh:Container, dh:Item, nfo:FileDataObject ;
                  acl:accessTo ?sparql .

              ?sparqlPost a acl:Authorization ;
                  acl:accessTo ?sparql ;
                  acl:mode acl:Append ;
                  acl:agentClass foaf:Agent, acl:AuthenticatedAgent . # hacky way to allow queries over POST
            }
            WHERE
            {}
            """);
        pss.setIri("public", adminBase + "acl/authorizations/public/#this");
        pss.setIri("sparqlPost", adminBase + "acl/authorizations/public/#sparql-post");
        pss.setIri("sparql", base + "sparql");
        return pss.toString();
    }

}
