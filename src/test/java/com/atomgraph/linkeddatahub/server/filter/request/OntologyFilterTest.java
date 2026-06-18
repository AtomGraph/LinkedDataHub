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
import org.apache.jena.graph.Graph;
import org.apache.jena.rdf.model.ModelFactory;
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

}
