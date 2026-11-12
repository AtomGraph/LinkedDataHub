/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.command.admin.ontologies;

import com.atomgraph.linkeddatahub.rdf.vocabulary.DH;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SIOC;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests what {@link ImportOntology} keeps of a fetched vocabulary.
 */
public class ImportOntologyTest
{

    /** A vocabulary served by a LinkedDataHub document loses the document's containment and keeps everything else. */
    @Test
    public void removesContainmentOfSourceDocument()
    {
        Model vocabulary = ModelFactory.createDefaultModel();
        Resource doc = vocabulary.createResource("https://localhost:4443/ontology/").
            addProperty(RDF.type, DH.Item).
            addProperty(DCTerms.title, "Ontology").
            addProperty(SIOC.has_container, vocabulary.createResource("https://localhost:4443/"));
        Resource container = vocabulary.createResource("https://localhost:4443/vocabularies/").
            addProperty(RDF.type, DH.Container).
            addProperty(SIOC.has_parent, vocabulary.createResource("https://localhost:4443/"));
        Resource ontology = vocabulary.createResource("http://example.org/ontology").
            addProperty(RDF.type, OWL.Ontology);
        Resource owlClass = vocabulary.createResource("http://example.org/ontology#Thing").
            addProperty(RDF.type, OWL.Class).
            addProperty(RDFS.isDefinedBy, ontology);

        ImportOntology.removeContainment(vocabulary);

        assertFalse(vocabulary.contains(null, SIOC.has_container));
        assertFalse(vocabulary.contains(null, SIOC.has_parent));
        assertTrue(vocabulary.contains(doc, RDF.type, DH.Item));
        assertTrue(vocabulary.contains(doc, DCTerms.title));
        assertTrue(vocabulary.contains(container, RDF.type, DH.Container));
        assertTrue(vocabulary.contains(ontology, RDF.type, OWL.Ontology));
        assertTrue(vocabulary.contains(owlClass, RDFS.isDefinedBy, ontology));
    }

}
