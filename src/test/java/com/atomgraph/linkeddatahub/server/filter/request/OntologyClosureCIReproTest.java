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
import org.apache.jena.ontapi.UnionGraph;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Production-shaped regression guard for the imports closure: the end-user ns# ontology as the SPARQL
 * CONSTRUCT returns it (header + imports + unrelated document resources), importing the SPARQL-loaded
 * ldh# vocabulary, whose transitive imports resolve through the real bundled location mappings
 * (dh, spin, sp, foaf, sioc, sd) plus store-seeded stubs for the non-mapped ones (ac, nfo, owl).
 * <p>
 * Pins the fix for ontapi consulting {@code contains()} before {@code get()} during import resolution:
 * a cache-state (rather than resolvability) answer made ontapi silently substitute empty ontology
 * graphs for every bundled-mapped import, stripping SPIN constraints and vocabularies from the closure.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyClosureCIReproTest
{

    private static final String NS = "https://localhost:4443/ns#";
    private static final String LDH = "https://w3id.org/atomgraph/linkeddatahub#";

    @Test
    public void productionShapedClosureContainsAllImports()
    {
        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        // real bundled mappings
        Model mappingModel = ModelFactory.createDefaultModel();
        RDFParser.create().source("location-mapping.ttl").streamManager(repository.getStreamManager()).build().parse(mappingModel);
        repository.processConfig(mappingModel);

        // mimic SPARQL-first load result: the ldh# vocabulary as a store graph
        Model ldh = ModelFactory.createDefaultModel();
        RDFParser.create().source("com/atomgraph/linkeddatahub/ldh.ttl").base(LDH).streamManager(repository.getStreamManager()).build().parse(ldh);
        repository.put(LDH, ldh.getGraph());

        // stub graphs for ldh#'s non-mapped imports (SPARQL/HTTP-loaded in production)
        for (String stub : new String[] {
            "https://w3id.org/atomgraph/client#",
            "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#",
            "http://www.w3.org/2002/07/owl#" })
        {
            Model m = ModelFactory.createDefaultModel();
            m.add(m.createResource(stub), RDF.type, OWL.Ontology);
            repository.put(stub, m.getGraph());
        }

        // ns# base graph as the ontology CONSTRUCT returns it: ontology header + imports + document resource
        Model ns = ModelFactory.createDefaultModel();
        Resource nsOnt = ns.createResource(NS);
        ns.add(nsOnt, RDF.type, OWL.Ontology);
        ns.add(nsOnt, OWL.imports, ns.createResource(LDH));
        Resource doc = ns.createResource("https://admin.localhost:4443/ontologies/namespace/");
        ns.add(doc, RDF.type, ns.createResource("https://www.w3.org/ns/ldt/document-hierarchy#Item"));
        ns.add(doc, ResourceFactory.createProperty("http://purl.org/dc/terms/title"), "Namespace");
        repository.put(NS, ns.getGraph());

        UnionGraph union = OntologyFilter.loadOntology(repository, NS);
        Model closure = ModelFactory.createModelForGraph(union);

        // direct import: ldh.ttl content
        assertTrue(closure.contains(closure.createResource(LDH + "View"), RDF.type, RDFS.Class), "ldh# (direct import) must be in the closure");
        // transitive via ldh#: dh.ttl (bundled mapping)
        assertTrue(closure.contains(closure.createResource("https://www.w3.org/ns/ldt/document-hierarchy#Item"), RDF.type, OWL.Class), "dh# (transitive, bundled) must be in the closure");
        // transitive via ldh#: spin.ttl imported as http://spinrdf.org/spin (no hash)
        assertTrue(closure.contains(closure.createResource("http://spinrdf.org/spin#constraint"), RDF.type, RDF.Property), "spin (transitive, bundled, hashless import URI) must be in the closure");
        // transitive via dh#: sp.ttl imported as http://spinrdf.org/sp#
        assertTrue(closure.contains(closure.createResource("http://spinrdf.org/sp#text"), RDF.type, RDF.Property), "sp# (transitive via dh#, bundled) must be in the closure");
        // transitive via dh#: foaf (bundled)
        assertFalse(closure.listStatements(closure.createResource("http://xmlns.com/foaf/0.1/Agent"), null, (org.apache.jena.rdf.model.RDFNode)null).toList().isEmpty(), "foaf (transitive, bundled) must be in the closure");
    }

    @Test
    public void importedDocumentWithMismatchedOntologyIRIIsInTheClosure()
    {
        // content-addressed uploads: the document URI (uploads/<sha1>) necessarily differs from the
        // ontology IRI the uploaded file declares — both must still land in the closure
        String uploadURI = "https://localhost:4443/uploads/da39a3ee5e6b4b0d3255bfef95601890afd80709";
        String declaredURI = "https://example.org/test#";

        PrefixGraphRepository repository = new PrefixGraphRepository(null);

        Model uploaded = ModelFactory.createDefaultModel();
        Resource declaredOnt = uploaded.createResource(declaredURI);
        uploaded.add(declaredOnt, RDF.type, OWL.Ontology);
        Resource testClass = uploaded.createResource(declaredURI + "TestClass");
        uploaded.add(testClass, RDF.type, OWL.Class);
        uploaded.add(testClass, RDFS.label, "Test Class");
        repository.put(uploadURI, uploaded.getGraph());

        Model ns = ModelFactory.createDefaultModel();
        Resource nsOnt = ns.createResource(NS);
        ns.add(nsOnt, RDF.type, OWL.Ontology);
        ns.add(nsOnt, OWL.imports, ns.createResource(uploadURI));
        repository.put(NS, ns.getGraph());

        UnionGraph union = OntologyFilter.loadOntology(repository, NS);
        Model closure = ModelFactory.createModelForGraph(union);

        assertTrue(closure.contains(testClass, RDFS.label, closure.createLiteral("Test Class")), "content of an import whose declared ontology IRI differs from its document URI must be in the closure");
    }

}
