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

import com.atomgraph.core.io.ModelProvider;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RiotException;
import org.apache.jena.update.UpdateFactory;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Tests for finding the malformed IRIs of a write, in each shape a write can carry one.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class InvalidIRIsTest
{

    private static final String BASE = "https://localhost:4443/doc/";
    private static final String SEE_ALSO = "http://www.w3.org/2000/01/rdf-schema#seeAlso";

    // malformed by every reading of RFC 3987
    @ParameterizedTest
    @ValueSource(strings = { "not a uri", "http://ex .com/", "http://ex.com/<x>", "http://[::1", "%zz", ":::", "git@github.com:a/b.git" })
    public void testMalformedIsReported(String iri)
    {
        assertTrue(InvalidIRIs.check(iri).isPresent(), iri);
    }

    // valid absolute IRIs, a non-ASCII one among them, and relative references, which are valid until resolved
    @ParameterizedTest
    @ValueSource(strings = { "http://ex.com/ok", "urn:x", "mailto:a@b", "http://ex.com/ą", "http://EX.com/%7e", "foo", "#this", "" })
    public void testValidIsNotReported(String iri)
    {
        assertEquals(Optional.empty(), InvalidIRIs.check(iri), iri);
    }

    // the RDF parsers stop at the first malformed IRI, and name it only in the message
    @ParameterizedTest
    @ValueSource(strings = { "not a uri", "http://ex .com/", "http://ex.com/<x>", "http://[::1", "%zz", ":::", "git@github.com:a/b.git" })
    public void testValueIsReadOffTheParseError(String iri)
    {
        String rdfXml = "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\">" +
            "<rdf:Description rdf:about=\"" + BASE + "#this\"><rdfs:seeAlso rdf:resource=\"" + iri.replace("<", "&lt;").replace(">", "&gt;") + "\"/></rdf:Description></rdf:RDF>";

        RiotException ex = assertThrows(RiotException.class, () -> new ModelProvider().read(ModelFactory.createDefaultModel(),
            new ByteArrayInputStream(rdfXml.getBytes(StandardCharsets.UTF_8)), Lang.RDFXML, BASE));
        assertEquals(Optional.of(iri), InvalidIRIs.fromMessage(ex.getMessage()));
    }

    @Test
    public void testTurtleParseErrorNamesTheValue()
    {
        String turtle = "<#this> <" + SEE_ALSO + "> <http://[::1> .";

        RiotException ex = assertThrows(RiotException.class, () -> new ModelProvider().read(ModelFactory.createDefaultModel(),
            new ByteArrayInputStream(turtle.getBytes(StandardCharsets.UTF_8)), Lang.TURTLE, BASE));
        assertEquals(Optional.of("http://[::1"), InvalidIRIs.fromMessage(ex.getMessage()));
    }

    // a parse error that is not about an IRI names none, and neither does one that names a valid IRI
    @ParameterizedTest
    @ValueSource(strings = { "Unexpected end of file", "<http://ex.com/ok> : not an IRI error" })
    public void testOtherParseErrorNamesNoValue(String message)
    {
        assertEquals(Optional.empty(), InvalidIRIs.fromMessage(message));
    }

    // the SPARQL lexer stops at a space or a '<' and reports the '<' that opens the reference; the reference ends
    // at the first '>' that ends a token, so a '>' inside it does not cut it short
    @ParameterizedTest
    @ValueSource(strings = { "not a uri", "http://ex .com/", "http://ex.com/<x>" })
    public void testValueIsReadOffTheLexerError(String iri)
    {
        for (String update : List.of(
            "INSERT DATA { <" + BASE + "#this> <" + SEE_ALSO + "> <" + iri + "> }",
            "DELETE { <" + BASE + "#this> ?p ?o. }\nINSERT {\n  <" + BASE + "#this> <" + SEE_ALSO + "> <" + iri + ">;\n    <http://purl.org/dc/terms/title> \"x\".\n}\nWHERE { <" + BASE + "#this> ?p ?o. }"))
        {
            QueryParseException ex = assertThrows(QueryParseException.class, () -> UpdateFactory.create(update, BASE));
            assertEquals(Optional.of(iri), InvalidIRIs.atError(update, ex), update);
        }
    }

    @Test
    public void testOtherLexerErrorNamesNoValue()
    {
        String update = "INSERT DATA { <" + BASE + "#this> <" + SEE_ALSO + "> undefined:foo }";

        QueryParseException ex = assertThrows(QueryParseException.class, () -> UpdateFactory.create(update, BASE));
        assertEquals(Optional.empty(), InvalidIRIs.atError(update, ex));
    }

    // the rest pass the lexer as IRI references and would be stored without a check of the parsed update
    @Test
    public void testParsedUpdateIsChecked()
    {
        String update = "DELETE { <" + BASE + "#this> <" + SEE_ALSO + "> <%zz> } " +
            "INSERT { <" + BASE + "#this> <" + SEE_ALSO + "> <http://[::1>, <:::>, <http://ex.com/ok> } WHERE {}";

        Map<String, String> violations = InvalidIRIs.of(UpdateFactory.create(update, BASE));
        assertEquals(List.of("%zz", "http://[::1", ":::"), List.copyOf(violations.keySet()));
    }

    @ParameterizedTest
    @ValueSource(strings =
    {
        "INSERT DATA { <" + BASE + "#this> <" + SEE_ALSO + "> <http://[::1> }",
        "DELETE DATA { <" + BASE + "#this> <" + SEE_ALSO + "> <http://[::1> }",
        "DELETE WHERE { <" + BASE + "#this> <" + SEE_ALSO + "> <http://[::1> }"
    })
    public void testEveryUpdateFormIsChecked(String update)
    {
        assertEquals(List.of("http://[::1"), List.copyOf(InvalidIRIs.of(UpdateFactory.create(update, BASE)).keySet()));
    }

    @Test
    public void testValidUpdateHasNoViolations()
    {
        String update = "INSERT { <" + BASE + "#this> <" + SEE_ALSO + "> <foo>, <http://ex.com/ą> } WHERE { <" + BASE + "#this> ?p ?o }";

        assertTrue(InvalidIRIs.of(UpdateFactory.create(update, BASE)).isEmpty());
    }

}
