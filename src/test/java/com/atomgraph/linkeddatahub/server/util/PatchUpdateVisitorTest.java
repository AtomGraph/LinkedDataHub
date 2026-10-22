/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.util;

import jakarta.ws.rs.WebApplicationException;
import org.apache.jena.update.UpdateFactory;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Tests for the check that refuses PATCH updates which cannot apply to a single graph.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class PatchUpdateVisitorTest
{

    private static final String PREFIXES = "PREFIX dct: <http://purl.org/dc/terms/>\n";

    @ParameterizedTest
    @ValueSource(strings =
    {
        "INSERT { GRAPH <http://g> { <http://s> dct:title \"x\" } } WHERE {}",
        "DELETE WHERE { GRAPH <http://g> { <http://s> dct:title ?o } }",
        "DELETE WHERE { GRAPH ?g { <http://s> dct:title ?o } }",
        "DELETE { <http://s> dct:title ?o } WHERE { GRAPH ?g { <http://s> dct:title ?o } }",
        "DELETE { <http://s> dct:title ?o } INSERT { <http://s> dct:title \"new\" } WHERE { OPTIONAL { GRAPH <http://s> { <http://s> dct:title ?o } } }",
        "INSERT { <http://s> dct:title \"new\" } WHERE { FILTER NOT EXISTS { GRAPH <http://s> { <http://s> dct:title ?o } } }",
        "INSERT { <http://s> dct:title \"new\" } WHERE { BIND(EXISTS { GRAPH ?g { ?s ?p ?o } } AS ?b) }",
        "DELETE { <http://s> dct:title ?o } WHERE { { SELECT ?o { GRAPH ?g { <http://s> dct:title ?o } } } }",
        "DELETE { <http://s> dct:title ?o } WHERE { { <http://s> dct:title ?o } UNION { GRAPH ?g { <http://s> dct:title ?o } } }",
        "DELETE { <http://s> dct:title ?o } WHERE { <http://s> dct:title ?o MINUS { GRAPH ?g { <http://s> dct:title ?o } } }"
    })
    public void testGraphIsRefused(String update)
    {
        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> PatchUpdateVisitor.validate(UpdateFactory.create(PREFIXES + update)));
        assertEquals(422, ex.getResponse().getStatus());
        assertEquals("SPARQL update used with PATCH method cannot contain the GRAPH keyword", ex.getMessage());
    }

    @ParameterizedTest
    @ValueSource(strings =
    {
        "WITH <http://g> DELETE { <http://s> dct:title ?o } WHERE { <http://s> dct:title ?o }",
        "DELETE { <http://s> dct:title ?o } USING <http://g> WHERE { <http://s> dct:title ?o }",
        "DELETE { <http://s> dct:title ?o } USING NAMED <http://g> WHERE { <http://s> dct:title ?o }"
    })
    public void testDatasetClauseIsRefused(String update)
    {
        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> PatchUpdateVisitor.validate(UpdateFactory.create(PREFIXES + update)));
        assertEquals(422, ex.getResponse().getStatus());
        assertEquals("SPARQL update used with PATCH method cannot contain WITH, USING or USING NAMED", ex.getMessage());
    }

    @ParameterizedTest
    @ValueSource(strings =
    {
        "INSERT DATA { <http://s> dct:title \"x\" }",
        "LOAD <http://example.org/data>",
        "CLEAR DEFAULT",
        "INSERT { <http://s> dct:title \"x\" } WHERE {} ; DELETE WHERE { <http://s> dct:title ?o }"
    })
    public void testOtherFormsAreRefused(String update)
    {
        WebApplicationException ex = assertThrows(WebApplicationException.class, () -> PatchUpdateVisitor.validate(UpdateFactory.create(PREFIXES + update)));
        assertEquals(422, ex.getResponse().getStatus());
    }

    @ParameterizedTest
    @ValueSource(strings =
    {
        "DELETE WHERE { <http://s> dct:title ?o }",
        "DELETE { <http://s> dct:title ?o } INSERT { <http://s> dct:title \"new\" } WHERE { OPTIONAL { <http://s> dct:title ?o } }",
        "INSERT { <http://s> dct:title \"new\" } WHERE { FILTER NOT EXISTS { <http://s> dct:title ?o } }",
        "INSERT { <http://s> dct:title ?label } WHERE { SERVICE <http://example.org/sparql> { GRAPH ?g { <http://s> dct:title ?label } } }",
        "INSERT { <http://s> dct:title \"x\" } WHERE {}"
    })
    public void testSingleGraphUpdateIsAccepted(String update)
    {
        assertDoesNotThrow(() -> PatchUpdateVisitor.validate(UpdateFactory.create(PREFIXES + update)));
    }

}
