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

import com.atomgraph.linkeddatahub.client.GitHubClient;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
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
    public void testTimeMap()
    {
        URI graphURI = URI.create("https://localhost:4443/doc/");
        Model model = GraphVersioningService.toTimeMap(graphURI, List.of(
            new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T11:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "Not A URI")));

        Resource timeMap = model.createResource("https://localhost:4443/doc/?timemap");
        Resource memento = model.createResource("https://localhost:4443/doc/?version=sha-2");
        Resource earlier = model.createResource("https://localhost:4443/doc/?version=sha-1");
        assertTrue(model.contains(timeMap, RDF.type, PROV.Collection));
        assertTrue(model.contains(timeMap, PROV.hadMember, memento));
        assertTrue(model.contains(memento, RDF.type, PROV.Entity));
        assertTrue(model.contains(memento, PROV.specializationOf, model.createResource(graphURI.toString())));
        assertEquals("2026-08-17T11:00:00Z", memento.getProperty(PROV.generatedAtTime).getString());
        assertEquals("https://localhost/agent#this", memento.getPropertyResourceValue(DCTerms.creator).getURI());
        // the non-URI author name must not become a creator resource
        assertTrue(earlier.getPropertyResourceValue(DCTerms.creator) == null);
    }

    @Test
    public void testTimeMapRevisionChain()
    {
        URI graphURI = URI.create("https://localhost:4443/doc/");
        Model model = GraphVersioningService.toTimeMap(graphURI, List.of(
            new GitHubClient.CommitInfo("sha-3", Instant.parse("2026-08-17T12:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T11:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this")));

        Resource latest = model.createResource("https://localhost:4443/doc/?version=sha-3");
        Resource middle = model.createResource("https://localhost:4443/doc/?version=sha-2");
        Resource earliest = model.createResource("https://localhost:4443/doc/?version=sha-1");
        // each memento is a revision of the next-older one; the earliest has no predecessor
        assertTrue(model.contains(latest, PROV.wasRevisionOf, middle));
        assertTrue(model.contains(middle, PROV.wasRevisionOf, earliest));
        assertTrue(earliest.getPropertyResourceValue(PROV.wasRevisionOf) == null);
    }

    @Test
    public void testSelectMementoClosestToRequestedDatetime()
    {
        // most recent first, as the commits API returns them
        List<GitHubClient.CommitInfo> commits = List.of(
            new GitHubClient.CommitInfo("sha-3", Instant.parse("2026-08-17T12:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T11:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this"));

        // closest in either direction, not merely the closest preceding
        assertEquals("sha-2", GraphVersioningService.selectMemento(commits, Instant.parse("2026-08-17T11:10:00Z")).get().sha());
        assertEquals("sha-3", GraphVersioningService.selectMemento(commits, Instant.parse("2026-08-17T11:50:00Z")).get().sha());
        // outside the covered interval the nearest end wins
        assertEquals("sha-1", GraphVersioningService.selectMemento(commits, Instant.parse("2020-01-01T00:00:00Z")).get().sha());
        assertEquals("sha-3", GraphVersioningService.selectMemento(commits, Instant.parse("2030-01-01T00:00:00Z")).get().sha());
    }

    @Test
    public void testSelectMementoResolvesTiesTowardsTheMoreRecent()
    {
        List<GitHubClient.CommitInfo> commits = List.of(
            new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T12:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this"));

        assertEquals("sha-2", GraphVersioningService.selectMemento(commits, Instant.parse("2026-08-17T11:00:00Z")).get().sha());
    }

    @Test
    public void testSelectMementoWithoutDatetimeIsMostRecent()
    {
        List<GitHubClient.CommitInfo> commits = List.of(
            new GitHubClient.CommitInfo("sha-2", Instant.parse("2026-08-17T12:00:00Z"), "https://localhost/agent#this"),
            new GitHubClient.CommitInfo("sha-1", Instant.parse("2026-08-17T10:00:00Z"), "https://localhost/agent#this"));

        assertEquals("sha-2", GraphVersioningService.selectMemento(commits, null).get().sha());
        assertTrue(GraphVersioningService.selectMemento(List.of(), null).isEmpty());
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
