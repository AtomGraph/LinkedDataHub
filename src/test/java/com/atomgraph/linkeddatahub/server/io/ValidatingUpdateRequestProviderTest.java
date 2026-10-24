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
package com.atomgraph.linkeddatahub.server.io;

import com.atomgraph.linkeddatahub.server.exception.URISyntaxViolationException;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import jakarta.ws.rs.BadRequestException;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Tests for the SPARQL update reader that refuses malformed IRIs, in the shape the browser's forms send.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ValidatingUpdateRequestProviderTest
{

    private static final String BASE = "https://localhost:4443/doc/";

    // the update a block's form sends: the resource's description replaced, the typed object among it
    private static String update(String object)
    {
        return "DELETE { <" + BASE + "#this> ?p ?o. }\n" +
            "INSERT {\n" +
            "  <" + BASE + "#this> <http://www.w3.org/2000/01/rdf-schema#seeAlso> <" + object + ">;\n" +
            "    <http://purl.org/dc/terms/title> \"Fixture\".\n" +
            "}\n" +
            "WHERE { <" + BASE + "#this> ?p ?o. }";
    }

    private static UpdateRequest read(String update)
    {
        return new ValidatingUpdateRequestProvider().read(new ByteArrayInputStream(update.getBytes(StandardCharsets.UTF_8)), BASE);
    }

    // one the lexer stops at, and ones it lets through
    @ParameterizedTest
    @ValueSource(strings = { "not a uri", "http://ex.com/<x>", "http://[::1", "%zz" })
    public void testMalformedIRIIsAViolationNamingIt(String iri)
    {
        URISyntaxViolationException ex = assertThrows(URISyntaxViolationException.class, () -> read(update(iri)));
        assertEquals(List.of(iri), List.copyOf(ex.getViolations().keySet()));

        // described as the client reads it: one violation, carrying the value and an explanation
        List<Resource> violations = ex.getModel().listSubjectsWithProperty(RDF.type, LDH.URISyntaxViolation).toList();
        assertEquals(1, violations.size());
        assertEquals(iri, violations.get(0).getProperty(LDH.violationValue).getString());
        assertTrue(violations.get(0).hasProperty(RDFS.label));
    }

    @Test
    public void testOtherSyntaxErrorIsABadRequest()
    {
        assertThrows(BadRequestException.class, () -> read("INSERT DATA { <" + BASE + "#this> <http://ex.com/p> undefined:foo }"));
    }

    @Test
    public void testValidUpdateIsRead()
    {
        UpdateRequest updateRequest = read(update("http://ex.com/ok"));
        assertEquals(1, updateRequest.getOperations().size());
    }

    // a relative reference is a valid IRI, resolved against the request URI as before
    @Test
    public void testRelativeReferenceIsResolved()
    {
        assertTrue(read(update("foo")).toString().contains("<" + BASE + "foo>"));
    }

}
