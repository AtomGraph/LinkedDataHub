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
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Characterization snapshot for the vocabulary holders (representative: {@link DH}).
 *
 * All ~19 vocabulary classes follow the identical pattern — a static OntModel built with
 * {@code ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null)} on which
 * {@code createClass} / {@code createDatatypeProperty} mint typed terms. Phase A swaps the
 * factory to {@code OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM)} and renames
 * {@code createClass}→{@code createOntClass}, {@code createDatatypeProperty}→{@code createDataProperty}.
 *
 * Asserted via the migration-stable {@link Resource} interface: the term URIs and the
 * {@code rdf:type owl:Class} / {@code rdf:type owl:DatatypeProperty} triples they produce
 * must stay identical after the rename.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class VocabularyHolderTest
{

    @Test
    public void testClassTermsHaveStableUriAndType()
    {
        Resource document = DH.Document;
        assertEquals(DH.NS + "Document", document.getURI());
        assertTrue(document.hasProperty(RDF.type, OWL.Class), "DH.Document must be typed owl:Class");

        Resource container = DH.Container;
        assertEquals(DH.NS + "Container", container.getURI());
        assertTrue(container.hasProperty(RDF.type, OWL.Class), "DH.Container must be typed owl:Class");
    }

    @Test
    public void testDatatypePropertyTermHasStableUriAndType()
    {
        Resource slug = DH.slug;
        assertEquals(DH.NS + "slug", slug.getURI());
        assertTrue(slug.hasProperty(RDF.type, OWL.DatatypeProperty), "DH.slug must be typed owl:DatatypeProperty");
    }

}
