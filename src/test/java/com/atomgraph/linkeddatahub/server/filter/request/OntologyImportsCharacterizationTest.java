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

import com.atomgraph.core.util.jena.PrefixGraphRepository;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
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
 * Pins {@link OntologyFilter#loadOntology}: it flattens the owl:imports closure into one graph,
 * applies RDFS inference, and materializes the inferences into the repository cache — without ontapi
 * managing a union-graph hierarchy over the shared repository (which collides on duplicate ontology IDs).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyImportsCharacterizationTest
{

    private static final String BASE_URI = "http://example.org/base";
    private static final String IMPORT_URI = "http://example.org/imported";
    private static final String NS = "http://example.org/ns#";

    @Test
    public void testLoadOntologyFlattensClosureWithMaterializedRDFSInference()
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

        OntologyFilter.loadOntology(repository, BASE_URI);

        Model result = ModelFactory.createModelForGraph(repository.get(BASE_URI));
        // (a) imported terms flattened into the cached graph
        assertTrue(result.contains(b, RDFS.subClassOf, a), "imported terms should be flattened in");
        // (b) RDFS inference materialized as a concrete triple: x a A
        assertTrue(result.contains(x, RDF.type, a), "RDFS-inferred 'x a A' should be materialized in the cached graph");
        // (c) the import is also cached under its (fragment-stripped) document URI
        assertTrue(repository.isCached(IMPORT_URI), "import should remain cached");
        // (d) REGRESSION GUARD: both owl:Class and rdfs:Class-only terms must be recognized as OntClasses by the returned
        // model, so GET /ns?forClass=<URI> resolves the class and runs its SPIN constructor.
        // OntologyFilter promotes all rdfs:Class subjects to owl:Class so OWL2 profiles (which do not recognize bare
        // rdfs:Class) can find third-party vocab terms like sp:Describe.
        OntModel ontology = OntModelFactory.createModel(repository.get(BASE_URI), OntSpecification.OWL2_FULL_MEM);
        assertNotNull(ontology.getOntClass(NS + "A"), "owl:Class term must be recognized as an OntClass under OWL2_FULL_MEM");
        assertNotNull(ontology.getOntClass(NS + "B"), "rdfs:Class-only term must be recognized as an OntClass after promotion");
    }

}
