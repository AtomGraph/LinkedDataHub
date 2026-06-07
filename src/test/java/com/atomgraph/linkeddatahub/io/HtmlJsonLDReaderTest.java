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
package com.atomgraph.linkeddatahub.io;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.riot.RiotParseException;
import org.apache.jena.riot.system.StreamRDFLib;
import org.apache.jena.sparql.util.Context;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link HtmlJsonLDReader}.
 * Self-contained: every JSON-LD payload embeds its own <code>@context</code>, so the
 * Titanium loader is never asked to fetch a remote vocabulary. The reader is exercised
 * directly (not through {@link RDFParser}) so the test does not mutate the global
 * {@link org.apache.jena.riot.RDFParserRegistry}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class HtmlJsonLDReaderTest
{

    private static final String BASE_URI = "https://example.com/page";
    private static final String EX = "http://example.com/ns#";

    private Model parse(String html)
    {
        Model model = ModelFactory.createDefaultModel();
        new HtmlJsonLDReader().read(
                new ByteArrayInputStream(html.getBytes(StandardCharsets.UTF_8)),
                BASE_URI,
                Lang.JSONLD11,
                StreamRDFLib.graph(model.getGraph()),
                new Context());
        return model;
    }

    @Test
    public void testSingleScriptYieldsTriples()
    {
        String html = """
            <!DOCTYPE html><html><head>
            <script type="application/ld+json">
            {
              "@context": {"ex": "%s", "name": {"@id": "ex:name"}},
              "@id": "ex:alice",
              "@type": "ex:Person",
              "name": "Alice"
            }
            </script>
            </head><body></body></html>
            """.formatted(EX);

        Model model = parse(html);

        assertTrue(model.contains(
                ResourceFactory.createResource(EX + "alice"),
                ResourceFactory.createProperty(EX, "name"),
                "Alice"));
        assertTrue(model.contains(
                ResourceFactory.createResource(EX + "alice"),
                org.apache.jena.vocabulary.RDF.type,
                ResourceFactory.createResource(EX + "Person")));
    }

    @Test
    public void testMultipleScriptsAreMerged()
    {
        String html = """
            <!DOCTYPE html><html><head>
            <script type="application/ld+json">
            {"@context":{"ex":"%s","name":{"@id":"ex:name"}},"@id":"ex:alice","name":"Alice"}
            </script>
            <script type="application/ld+json">
            {"@context":{"ex":"%s","name":{"@id":"ex:name"}},"@id":"ex:bob","name":"Bob"}
            </script>
            </head><body></body></html>
            """.formatted(EX, EX);

        Model model = parse(html);

        assertTrue(model.contains(
                ResourceFactory.createResource(EX + "alice"),
                ResourceFactory.createProperty(EX, "name"),
                "Alice"));
        assertTrue(model.contains(
                ResourceFactory.createResource(EX + "bob"),
                ResourceFactory.createProperty(EX, "name"),
                "Bob"));
    }

    @Test
    public void testMissingScriptThrows()
    {
        String html = "<!DOCTYPE html><html><head><title>no jsonld</title></head><body><p>nothing</p></body></html>";

        assertThrows(RiotParseException.class, () -> parse(html));
    }

    @Test
    public void testOtherScriptTypesIgnored()
    {
        // a non-ld+json <script> must not be picked up; only the ld+json block contributes
        String html = """
            <!DOCTYPE html><html><head>
            <script type="text/javascript">var x = {"@id":"ex:js","name":"JS"};</script>
            <script type="application/ld+json">
            {"@context":{"ex":"%s","name":{"@id":"ex:name"}},"@id":"ex:alice","name":"Alice"}
            </script>
            </head><body></body></html>
            """.formatted(EX);

        Model model = parse(html);

        assertTrue(model.contains(
                ResourceFactory.createResource(EX + "alice"),
                ResourceFactory.createProperty(EX, "name"),
                "Alice"));
        assertFalse(model.contains(
                ResourceFactory.createResource(EX + "js"),
                ResourceFactory.createProperty(EX, "name"),
                "JS"));
    }

    @Test
    public void testSameOutputAsDirectJsonLdParse()
    {
        // the HTML reader must be a transparent wrapper around Jena's JSON-LD11 reader:
        // wrapping the same payload in HTML must yield exactly the same model as parsing the payload directly
        String jsonLd = """
            {
              "@context": {"ex": "%s", "name": {"@id": "ex:name"}},
              "@id": "ex:alice",
              "@type": "ex:Person",
              "name": "Alice"
            }
            """.formatted(EX);
        String html = "<!DOCTYPE html><html><head><script type=\"application/ld+json\">"
                + jsonLd + "</script></head><body></body></html>";

        Model direct = ModelFactory.createDefaultModel();
        RDFParser.create().
                source(new ByteArrayInputStream(jsonLd.getBytes(StandardCharsets.UTF_8))).
                lang(Lang.JSONLD11).
                base(BASE_URI).
                parse(StreamRDFLib.graph(direct.getGraph()));

        Model viaHtml = parse(html);

        assertEquals(direct.size(), viaHtml.size());
        assertTrue(direct.isIsomorphicWith(viaHtml));
    }

}
