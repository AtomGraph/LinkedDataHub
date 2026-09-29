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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.util.jena.PrefixGraphRepository;
import java.net.URI;
import java.util.List;
import org.apache.jena.graph.Graph;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.graph.Triple;
import org.apache.jena.ontapi.UnionGraph;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Characterization tests for {@link OntologyFilter#addDocumentModel}, which caches an imported graph
 * under a SECONDARY key: the fragment-stripped document URI. Pins the dual-key caching behavior
 * retained from the legacy implementation.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyFilterTest
{

    /** An import URI with a fragment is also cached under its fragment-stripped document URI. */
    @Test
    public void testAddDocumentModelCachesUnderStrippedDocumentURI()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);
        String importURI = "http://example.org/onto#";
        String docURI = "http://example.org/onto";

        Graph imported = ModelFactory.createDefaultModel().getGraph();
        repository.put(importURI, imported);

        OntologyFilter.addDocumentModel(repository, importURI);

        assertTrue(repository.isCached(docURI), "import graph should be cached under the document URI");
        assertSame(imported, repository.get(docURI));
    }

    /** If the document URI is mapped to a different location, the secondary cache write is skipped. */
    @Test
    public void testAddDocumentModelSkipsWhenDocumentURIMapped()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);
        String importURI = "http://example.org/mapped#";
        String docURI = "http://example.org/mapped";

        repository.addLocationMapping(docURI, "file:elsewhere.ttl"); // resolve(docURI) != docURI -> skip
        repository.put(importURI, ModelFactory.createDefaultModel().getGraph());

        OntologyFilter.addDocumentModel(repository, importURI);

        assertFalse(repository.isCached(docURI), "mapped document URI should not be cached as a secondary key");
    }

    /**
     * A package descriptor may name the ontology's document (ns/) while the ontology inside is ns/#. The
     * two URIs resolve to two graphs with the same ontology name; importing the declared name keeps the
     * second one out of the closure.
     */
    @Test
    public void testPackageImportUsesDeclaredOntologyIRI()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);
        repository.put(APP, ontology(APP));
        repository.put("http://example.org/pkg/ns/", ontology("http://example.org/pkg/ns/#", LABELLED));
        repository.put("http://example.org/pkg/ns/#", ontology("http://example.org/pkg/ns/#", LABELLED)); // a separate load of the same document

        UnionGraph union = OntologyFilter.loadOntology(repository, APP, List.of(URI.create("http://example.org/pkg/ns/")));

        assertTrue(union.contains(LABELLED), "package ontology should be in the closure");
    }

    /** A package ontology that breaks the closure is left out of it, and the application ontology still loads. */
    @Test
    public void testCollidingPackageFallsBackToApplicationOntology()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);
        Graph app = ontology(APP);
        repository.put(APP, app);
        Graph pkg = ontology("http://example.org/pkg#", LABELLED);
        pkg.add(Triple.create(uri("http://example.org/pkg#"), OWL.imports.asNode(), uri("http://example.org/alias")));
        repository.put("http://example.org/pkg#", pkg);
        repository.put("http://example.org/alias", ontology("http://example.org/pkg#")); // another graph with the package's name

        UnionGraph union = OntologyFilter.loadOntology(repository, APP, List.of(URI.create("http://example.org/pkg#")));

        assertTrue(union.contains(uri(APP), RDF.type.asNode(), OWL.Ontology.asNode()), "application ontology should load");
        assertFalse(union.contains(LABELLED), "the colliding package should be left out");
        assertFalse(app.contains(uri(APP), OWL.imports.asNode(), uri("http://example.org/pkg#")), "the package import should be retracted");
    }

    private static final String APP = "http://example.org/app#";

    private static final Triple LABELLED = Triple.create(uri("http://example.org/pkg/ns/#Thing"), RDFS.label.asNode(), NodeFactory.createLiteralString("Thing"));

    private static Graph ontology(String name, Triple... triples)
    {
        Graph graph = ModelFactory.createDefaultModel().getGraph();
        graph.add(Triple.create(uri(name), RDF.type.asNode(), OWL.Ontology.asNode()));
        for (Triple triple : triples) graph.add(triple);
        return graph;
    }

    private static Node uri(String uri)
    {
        return NodeFactory.createURI(uri);
    }

}
