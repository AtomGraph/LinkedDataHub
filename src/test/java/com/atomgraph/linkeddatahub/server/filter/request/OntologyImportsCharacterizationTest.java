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
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.UnionGraph;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Pins {@link OntologyFilter#loadOntology}: it assembles the owl:imports closure as a union graph
 * (resolved natively by ontapi over a scoped repository view), applies <em>no</em> inference, and
 * leaves the shared repository holding raw per-document graphs — which is what proxied and direct
 * document GETs serve.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyImportsCharacterizationTest
{

    private static final String BASE_URI = "http://example.org/base";
    private static final String IMPORT_URI = "http://example.org/imported";
    private static final String PACKAGE_URI = "http://example.org/package";
    private static final String NS = "http://example.org/ns#";

    @Test
    public void testLoadOntologyResolvesClosureWithoutInference()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        Resource a = ResourceFactory.createResource(NS + "A");
        Resource b = ResourceFactory.createResource(NS + "B");
        Resource x = ResourceFactory.createResource(NS + "x");

        // imported ontology: A declared as owl:Class only; B declared as rdfs:Class only (mimicking third-party vocabs like sp.ttl);
        // B rdfs:subClassOf A; individual x a B
        Model imported = ModelFactory.createDefaultModel();
        imported.add(imported.createResource(IMPORT_URI), RDF.type, OWL.Ontology);
        imported.add(a, RDF.type, OWL.Class);
        imported.add(b, RDF.type, RDFS.Class);
        imported.add(b, RDFS.subClassOf, a);
        imported.add(x, RDF.type, b);
        repository.put(IMPORT_URI, imported.getGraph());

        // base ontology owl:imports the imported one
        Model base = ModelFactory.createDefaultModel();
        Resource baseOnt = base.createResource(BASE_URI);
        base.add(baseOnt, RDF.type, OWL.Ontology);
        base.add(baseOnt, OWL.imports, base.createResource(IMPORT_URI));
        repository.put(BASE_URI, base.getGraph());

        UnionGraph union = OntologyFilter.loadOntology(repository, BASE_URI);
        Model closure = ModelFactory.createModelForGraph(union);

        // (a) imported terms are visible through the closure union
        assertTrue(closure.contains(b, RDFS.subClassOf, a), "imported terms should be visible through the closure union");
        // (b) no inference: neither type propagation nor vacuous rdfs:Resource typing appears
        assertFalse(closure.contains(x, RDF.type, a), "no RDFS type propagation expected in the closure");
        assertFalse(closure.contains(x, RDF.type, RDFS.Resource), "no vacuous rdfs:Resource typing expected in the closure");
        // (c) the shared repository still holds the RAW document graphs — this is what document GETs serve
        assertTrue(ModelFactory.createModelForGraph(repository.get(BASE_URI)).isIsomorphicWith(base), "repository must keep serving the raw base ontology graph");
        assertTrue(ModelFactory.createModelForGraph(repository.get(IMPORT_URI)).isIsomorphicWith(imported), "repository must keep serving the raw imported ontology graph");
        // (d) REGRESSION GUARD: both owl:Class and rdfs:Class-only terms must be recognized as OntClasses by the model
        // wrapped over the union, so GET /ns?forClass=<URI> resolves the class and runs its SPIN constructor.
        // OntologyFilter promotes rdfs:Class subjects to owl:Class in a separate union member so the OWL2 profile
        // (which does not recognize bare rdfs:Class) can find third-party vocab terms like sp:Describe.
        OntModel ontology = OntModelFactory.createModel(union, OntSpecification.OWL2_FULL_MEM);
        assertNotNull(ontology.getOntClass(NS + "A"), "owl:Class term must be recognized as an OntClass under OWL2_FULL_MEM");
        assertNotNull(ontology.getOntClass(NS + "B"), "rdfs:Class-only term must be recognized as an OntClass after promotion");
        // the promotion must not leak into the raw document graphs
        assertFalse(ModelFactory.createModelForGraph(repository.get(IMPORT_URI)).contains(b, RDF.type, OWL.Class), "owl:Class promotion must not be written into the raw document graph");
    }

    @Test
    public void testLoadOntologyToleratesImportCycles()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        String firstURI = "http://example.org/first";
        String secondURI = "http://example.org/second";
        Resource term = ResourceFactory.createResource(NS + "Term");

        Model first = ModelFactory.createDefaultModel();
        Resource firstOnt = first.createResource(firstURI);
        first.add(firstOnt, RDF.type, OWL.Ontology);
        first.add(firstOnt, OWL.imports, first.createResource(secondURI));
        repository.put(firstURI, first.getGraph());

        Model second = ModelFactory.createDefaultModel();
        Resource secondOnt = second.createResource(secondURI);
        second.add(secondOnt, RDF.type, OWL.Ontology);
        second.add(secondOnt, OWL.imports, second.createResource(firstURI));
        second.add(term, RDF.type, OWL.Class);
        repository.put(secondURI, second.getGraph());

        UnionGraph union = OntologyFilter.loadOntology(repository, firstURI);
        assertTrue(ModelFactory.createModelForGraph(union).contains(term, RDF.type, OWL.Class), "cyclic imports must resolve without recursing infinitely");
    }

    /**
     * Pins the package composition: an imported package ontology is declared as an owl:imports of the
     * application ontology and resolved by ontapi as part of the closure — no union sub-graph is grafted.
     */
    @Test
    public void testLoadOntologyDeclaresPackageOntologyAsImport()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        Resource packageTerm = ResourceFactory.createResource(NS + "PackageTerm");

        Model packageOntology = ModelFactory.createDefaultModel();
        packageOntology.add(packageOntology.createResource(PACKAGE_URI), RDF.type, OWL.Ontology);
        packageOntology.add(packageTerm, RDF.type, OWL.Class);
        repository.put(PACKAGE_URI, packageOntology.getGraph());

        Model base = ModelFactory.createDefaultModel();
        Resource baseOnt = base.createResource(BASE_URI);
        base.add(baseOnt, RDF.type, OWL.Ontology);
        repository.put(BASE_URI, base.getGraph());

        UnionGraph union = OntologyFilter.loadOntology(repository, BASE_URI, List.of(URI.create(PACKAGE_URI)));

        assertTrue(ModelFactory.createModelForGraph(union).contains(packageTerm, RDF.type, OWL.Class), "package ontology terms must be visible through the closure union");
        // the declaration is a real owl:imports on the application ontology, so it also shows up in the
        // raw graph that document GETs of the ontology serve
        assertTrue(ModelFactory.createModelForGraph(repository.get(BASE_URI)).contains(baseOnt, OWL.imports, base.createResource(PACKAGE_URI)), "the package ontology must be declared as an owl:imports of the application ontology");
    }

    /**
     * A package ontology brings its own owl:imports closure with it — ontapi resolves those transitively
     * through the same repository, which is what makes declaring the import sufficient.
     */
    @Test
    public void testLoadOntologyResolvesTransitiveImportsOfPackageOntology()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        Resource transitiveTerm = ResourceFactory.createResource(NS + "TransitiveTerm");

        Model transitive = ModelFactory.createDefaultModel();
        transitive.add(transitive.createResource(IMPORT_URI), RDF.type, OWL.Ontology);
        transitive.add(transitiveTerm, RDF.type, OWL.Class);
        repository.put(IMPORT_URI, transitive.getGraph());

        Model packageOntology = ModelFactory.createDefaultModel();
        Resource packageOnt = packageOntology.createResource(PACKAGE_URI);
        packageOntology.add(packageOnt, RDF.type, OWL.Ontology);
        packageOntology.add(packageOnt, OWL.imports, packageOntology.createResource(IMPORT_URI));
        repository.put(PACKAGE_URI, packageOntology.getGraph());

        Model base = ModelFactory.createDefaultModel();
        base.add(base.createResource(BASE_URI), RDF.type, OWL.Ontology);
        repository.put(BASE_URI, base.getGraph());

        UnionGraph union = OntologyFilter.loadOntology(repository, BASE_URI, List.of(URI.create(PACKAGE_URI)));

        assertTrue(ModelFactory.createModelForGraph(union).contains(transitiveTerm, RDF.type, OWL.Class), "a package ontology's own owl:imports must resolve into the closure");
    }

    /**
     * A package whose ontology cannot be resolved is skipped rather than declared: ontapi is constructed
     * with ignoreUnresolvedImports and would otherwise substitute an empty graph silently.
     */
    @Test
    public void testLoadOntologySkipsUnresolvablePackageOntology()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        Resource baseTerm = ResourceFactory.createResource(NS + "BaseTerm");

        Model base = ModelFactory.createDefaultModel();
        Resource baseOnt = base.createResource(BASE_URI);
        base.add(baseOnt, RDF.type, OWL.Ontology);
        base.add(baseTerm, RDF.type, OWL.Class);
        repository.put(BASE_URI, base.getGraph());

        // not in the repository and not dereferenceable — a non-HTTP scheme so the check cannot reach the network
        URI missing = URI.create("urn:example:missing-package-ontology");
        UnionGraph union = OntologyFilter.loadOntology(repository, BASE_URI, List.of(missing));

        assertTrue(ModelFactory.createModelForGraph(union).contains(baseTerm, RDF.type, OWL.Class), "a broken package must not take the application ontology down");
        assertFalse(ModelFactory.createModelForGraph(repository.get(BASE_URI)).contains(baseOnt, OWL.imports, base.createResource(missing.toString())), "an unresolvable package ontology must not be declared as an owl:imports");
    }

}
