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

import java.net.URI;
import java.nio.charset.StandardCharsets;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests the pure graph-to-file mapping and serialization methods.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphVersioningServiceTest
{

    private static final URI BASE = URI.create("https://localhost:4443/");

    @Test
    public void testContainerPath()
    {
        assertEquals("graphs/data/products.nt", GraphVersioningService.path("graphs", BASE, URI.create("https://localhost:4443/data/products/")));
    }

    @Test
    public void testNestedPath()
    {
        assertEquals("graphs/data/products/one.nt", GraphVersioningService.path("graphs", BASE, URI.create("https://localhost:4443/data/products/one/")));
    }

    @Test
    public void testBasePath()
    {
        assertEquals("graphs/root.nt", GraphVersioningService.path("graphs", BASE, BASE));
    }

    @Test
    public void testSortedNTriplesIsDeterministic()
    {
        Model first = ModelFactory.createDefaultModel();
        first.add(first.createResource("https://localhost:4443/doc/"), RDF.type, first.createResource("https://www.w3.org/ns/ldt/document-hierarchy#Item"));
        first.add(first.createResource("https://localhost:4443/doc/"), DCTerms.title, "Document");
        first.add(first.createResource("https://localhost:4443/doc/"), RDFS.seeAlso, first.createResource("https://localhost:4443/other/"));

        // same statements, inserted in a different order
        Model second = ModelFactory.createDefaultModel();
        second.add(second.createResource("https://localhost:4443/doc/"), RDFS.seeAlso, second.createResource("https://localhost:4443/other/"));
        second.add(second.createResource("https://localhost:4443/doc/"), DCTerms.title, "Document");
        second.add(second.createResource("https://localhost:4443/doc/"), RDF.type, second.createResource("https://www.w3.org/ns/ldt/document-hierarchy#Item"));

        assertArrayEquals(GraphVersioningService.toSortedNTriples(first), GraphVersioningService.toSortedNTriples(second));
    }

    @Test
    public void testSortedNTriplesLinesAreSorted()
    {
        Model model = ModelFactory.createDefaultModel();
        model.add(model.createResource("https://localhost:4443/z/"), DCTerms.title, "Z");
        model.add(model.createResource("https://localhost:4443/a/"), DCTerms.title, "A");

        String[] lines = new String(GraphVersioningService.toSortedNTriples(model), StandardCharsets.UTF_8).split("\n");
        assertEquals(2, lines.length);
        assertTrue(lines[0].compareTo(lines[1]) < 0);
    }

    @Test
    public void testSortedNTriplesRoundTrips()
    {
        Model model = ModelFactory.createDefaultModel();
        model.add(model.createResource("https://localhost:4443/doc/"), DCTerms.title, ResourceFactory.createLangLiteral("multi\nline", "en"));

        Model parsed = ModelFactory.createDefaultModel();
        parsed.read(new java.io.ByteArrayInputStream(GraphVersioningService.toSortedNTriples(model)), null, "N-TRIPLES");

        assertTrue(model.isIsomorphicWith(parsed));
    }

}
