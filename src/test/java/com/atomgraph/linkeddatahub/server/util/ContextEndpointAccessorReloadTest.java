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

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResourceFactory;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Reading the descriptions back from their persistence: what a replica does to see another's change.
 */
public class ContextEndpointAccessorReloadTest
{

    private static final String END_USER = "urn:linkeddatahub:apps/end-user", ADDED = "urn:linkeddatahub:apps/added";

    private static Dataset with(String... dataspaces)
    {
        Dataset dataset = DatasetFactory.create();
        for (String dataspace : dataspaces)
            dataset.addNamedModel(dataspace, ModelFactory.createDefaultModel().add(ResourceFactory.createResource(dataspace), ResourceFactory.createProperty("http://purl.org/dc/terms/title"), dataspace));
        return dataset;
    }

    /** A persistence whose store another replica changed: it loads what it is given, and records what it is asked to store. */
    private static final class Shared implements ContextPersistence
    {
        Dataset inStore;
        final List<Dataset> persisted = new ArrayList<>();

        Shared(Dataset inStore) { this.inStore = inStore; }

        @Override
        public Dataset load() { return inStore; }

        @Override
        public void persist(Dataset dataset) { persisted.add(dataset); }
    }

    @Test
    public void testReloadServesWhatThePersistenceHoldsNow() throws IOException
    {
        Shared shared = new Shared(with(END_USER));
        ContextEndpointAccessor accessor = new ContextEndpointAccessor(shared.load(), shared);
        assertFalse(accessor.getDataset().containsNamedModel(ADDED));

        shared.inStore = with(END_USER, ADDED); // another replica's change
        Dataset before = accessor.reload();

        assertTrue(accessor.getDataset().containsNamedModel(ADDED), "the change is served after the reload");
        assertFalse(before.containsNamedModel(ADDED), "what was served before is returned, for the caller to compare");
        assertTrue(shared.persisted.isEmpty(), "a reload stores nothing");
    }

    @Test
    public void testReloadNeedsAPersistenceThatLoads()
    {
        List<Dataset> persisted = new ArrayList<>();
        ContextEndpointAccessor accessor = new ContextEndpointAccessor(with(END_USER), persisted::add); // stores only
        assertThrows(UnsupportedOperationException.class, accessor::reload);
        assertSame(accessor.getDataset(), accessor.getDataset());
    }

}
