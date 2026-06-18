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

import org.apache.jena.ontology.OntDocumentManager;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
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
 * Oracle for the ontology-load mechanism used by {@link OntologyFilter}: build an
 * OWL_MEM_RDFS_INF model over a base ontology that owl:imports another, then materialize
 * the inferences into a plain OWL_MEM model that is cached.
 *
 * Pins (a) the owl:imports transitive closure, (b) RDFS inference, and (c) that the
 * materialized model retains inferred triples but carries no reasoner — the three
 * behaviors the {@code GraphRepository}/{@code OntSpecification} migration must reproduce.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyImportsCharacterizationTest
{

    private static final String BASE_URI = "http://example.org/base";
    private static final String IMPORT_URI = "http://example.org/imported";
    private static final String NS = "http://example.org/ns#";

    @Test
    public void testImportClosureRdfsInferenceAndMaterialization()
    {
        OntModelSpec spec = new OntModelSpec(OntModelSpec.OWL_MEM_RDFS_INF);
        OntDocumentManager odm = new OntDocumentManager();
        spec.setDocumentManager(odm);

        // imported ontology: B rdfs:subClassOf A; individual x a B
        Resource a = ResourceFactory.createResource(NS + "A");
        Resource b = ResourceFactory.createResource(NS + "B");
        Resource x = ResourceFactory.createResource(NS + "x");
        Model imported = ModelFactory.createDefaultModel();
        imported.add(imported.createResource(IMPORT_URI), RDF.type, OWL.Ontology);
        imported.add(b, RDFS.subClassOf, a);
        imported.add(x, RDF.type, b);
        odm.addModel(IMPORT_URI, imported);

        // base ontology owl:imports the imported one
        Model base = ModelFactory.createDefaultModel();
        base.add(base.createResource(BASE_URI), RDF.type, OWL.Ontology);
        base.add(base.createResource(BASE_URI), OWL.imports, base.createResource(IMPORT_URI));

        OntModel ontModel = ModelFactory.createOntologyModel(spec, base);

        // (a) transitive import closure includes the imported ontology
        assertTrue(ontModel.listImportedOntologyURIs(true).contains(IMPORT_URI), "import closure should contain the imported ontology URI");
        // imported asserted triple is visible through the union
        assertTrue(ontModel.contains(b, RDFS.subClassOf, a), "imported terms should be visible");
        // (b) RDFS inference: x a A is entailed from (x a B) + (B subClassOf A)
        assertTrue(ontModel.contains(x, RDF.type, a), "RDFS reasoner should infer x a A");

        // (c) materialize into a plain OWL_MEM model (no inference)
        OntModel materialized = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM);
        materialized.add(ontModel);
        // inferred triple is now asserted in the materialized copy
        assertTrue(materialized.contains(x, RDF.type, a), "materialized model retains the inferred triple");
        // and the materialized model carries no reasoner
        assertNull(materialized.getSpecification().getReasonerFactory(), "OWL_MEM materialized model must have no reasoner factory");
        // proof it is plain: a fresh entailment is NOT auto-derived
        Resource c = ResourceFactory.createResource(NS + "C");
        Resource y = ResourceFactory.createResource(NS + "y");
        materialized.add(c, RDFS.subClassOf, b);
        materialized.add(y, RDF.type, c);
        assertFalse(materialized.contains(y, RDF.type, a), "no reasoner: y a A must not be inferred");
    }

}
