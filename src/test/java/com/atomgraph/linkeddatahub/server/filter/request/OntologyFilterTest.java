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
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Characterization tests for {@link OntologyFilter#addDocumentModel}, which caches an
 * imported ontology model under a SECONDARY key: the fragment-stripped document URI.
 *
 * This pins the current dual-key caching behavior so the migration to the new ontology
 * API ({@code GraphRepository}) can be proven to retain it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyFilterTest
{

    /** An import URI with a fragment is also cached under its fragment-stripped document URI. */
    @Test
    public void testAddDocumentModelCachesUnderStrippedDocumentURI()
    {
        OntDocumentManager odm = new OntDocumentManager();
        String importURI = "http://example.org/onto#";
        String docURI = "http://example.org/onto";

        Model imported = ModelFactory.createDefaultModel();
        imported.createResource(importURI + "Thing");
        odm.addModel(importURI, imported, true);

        // precondition: only the ontology (fragment) URI is known
        assertNotNull(odm.getModel(importURI));

        OntologyFilter.addDocumentModel(odm, importURI);

        // the same model is now retrievable under the fragment-stripped document URI
        assertNotNull(odm.getModel(docURI), "import model should be cached under the document URI");
        assertSame(imported, odm.getModel(docURI));
    }

    /** If the document URI is mapped (mapURI != docURI), the secondary cache write is skipped. */
    @Test
    public void testAddDocumentModelSkipsWhenDocumentURIMapped()
    {
        OntDocumentManager odm = new OntDocumentManager();
        String importURI = "http://example.org/mapped#";
        String docURI = "http://example.org/mapped";

        // map the document URI to a different location -> guard mappedURI.equals(docURI) is false
        odm.getFileManager().getLocationMapper().addAltEntry(docURI, "file:elsewhere.ttl");

        Model imported = ModelFactory.createDefaultModel();
        odm.addModel(importURI, imported, true);

        OntologyFilter.addDocumentModel(odm, importURI);

        // no secondary cache entry created under the document URI
        assertNull(odm.getModel(docURI), "mapped document URI should not be cached as a secondary key");
    }

}
