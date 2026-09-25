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
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.update.UpdateFactory;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Tests for SPARQL access to the platform's configuration.
 *
 * The dataspace URIs are `urn:` on purpose: that is what they are in a deployment, and it is the
 * reason this is reached by query rather than by the Graph Store Protocol.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ContextEndpointAccessorTest
{

    private static final String END_USER = "urn:linkeddatahub:apps/end-user";
    private static final String ADMIN = "urn:linkeddatahub:apps/admin";
    private static final String TITLE = "http://purl.org/dc/terms/title";

    private Dataset dataset;
    private List<Dataset> persisted;
    private ContextEndpointAccessor accessor;

    private static Model describing(String uri, String title)
    {
        Model model = ModelFactory.createDefaultModel();
        model.add(ResourceFactory.createResource(uri), ResourceFactory.createProperty(TITLE), title);

        return model;
    }

    private static String titleOf(Dataset dataset, String dataspaceURI)
    {
        return dataset.getNamedModel(dataspaceURI).
            getProperty(ResourceFactory.createResource(dataspaceURI), ResourceFactory.createProperty(TITLE)).
            getString();
    }

    @BeforeEach
    public void setUp()
    {
        dataset = DatasetFactory.create();
        dataset.addNamedModel(END_USER, describing(END_USER, "End-user"));
        dataset.addNamedModel(ADMIN, describing(ADMIN, "Admin"));

        persisted = new ArrayList<>();
        accessor = new ContextEndpointAccessor(dataset, persisted::add);
    }

    @Test
    public void testSelectReadsTheConfiguration()
    {
        var results = accessor.select(QueryFactory.create(
            "SELECT ?g WHERE { GRAPH ?g { ?s ?p ?o } }"), List.of(), List.of());

        var names = new ArrayList<String>();
        while (results.hasNext()) names.add(results.next().getResource("g").getURI());

        assertTrue(names.contains(END_USER), "the end-user dataspace is not readable");
        assertTrue(names.contains(ADMIN), "the admin dataspace is not readable");
    }

    @Test
    public void testAskReadsTheConfiguration()
    {
        assertTrue(accessor.ask(QueryFactory.create(
            "ASK { GRAPH <" + END_USER + "> { ?s ?p ?o } }"), List.of(), List.of()));
        assertFalse(accessor.ask(QueryFactory.create(
            "ASK { GRAPH <urn:linkeddatahub:apps/nonexistent> { ?s ?p ?o } }"), List.of(), List.of()));
    }

    @Test
    public void testUpdateIsApplied()
    {
        accessor.update(UpdateFactory.create(
            "DELETE { GRAPH <" + END_USER + "> { ?s <" + TITLE + "> ?o } }" +
            "INSERT { GRAPH <" + END_USER + "> { ?s <" + TITLE + "> 'Renamed' } }" +
            "WHERE  { GRAPH <" + END_USER + "> { ?s <" + TITLE + "> ?o } }"), null, null);

        assertEquals("Renamed", titleOf(accessor.getDataset(), END_USER));
    }

    @Test
    public void testUpdateLeavesTheOtherDataspacesAlone()
    {
        accessor.update(UpdateFactory.create(
            "INSERT DATA { GRAPH <" + END_USER + "> { <" + END_USER + "> <urn:p> 'added' } }"), null, null);

        assertEquals("Admin", titleOf(accessor.getDataset(), ADMIN));
    }

    @Test
    public void testUpdateIsPersistedBeforeItIsPublished()
    {
        accessor.update(UpdateFactory.create(
            "INSERT DATA { GRAPH <" + END_USER + "> { <" + END_USER + "> <urn:p> 'added' } }"), null, null);

        assertEquals(1, persisted.size(), "the change was not stored");
        assertSame(accessor.getDataset(), persisted.get(0), "what was stored is not what is being served");
    }

    @Test
    public void testAReaderHoldingTheOldSnapshotIsUnaffected()
    {
        // what a request thread is holding while a write lands, and the whole reason for the copy
        Dataset held = accessor.getDataset();

        accessor.update(UpdateFactory.create(
            "INSERT DATA { GRAPH <" + END_USER + "> { <" + END_USER + "> <urn:p> 'added' } }"), null, null);

        assertNotSame(held, accessor.getDataset(), "the dataset was mutated in place");
        assertFalse(held.getNamedModel(END_USER).contains(
            ResourceFactory.createResource(END_USER), ResourceFactory.createProperty("urn:p")),
            "the update reached a snapshot a reader was already holding");
    }

    @Test
    public void testPutDataspaceReplacesOneDescription() throws IOException
    {
        accessor.putDataspace(END_USER, describing(END_USER, "Replaced"));

        assertEquals("Replaced", titleOf(accessor.getDataset(), END_USER));
        assertEquals("Admin", titleOf(accessor.getDataset(), ADMIN));
    }

    @Test
    public void testPutDataspaceCopiesTheCallersModel() throws IOException
    {
        Model mine = describing(END_USER, "Mine");
        accessor.putDataspace(END_USER, mine);
        mine.removeAll();

        assertEquals("Mine", titleOf(accessor.getDataset(), END_USER),
            "the caller's model is the one being served, so mutating it changes the configuration");
    }

    @Test
    public void testPutDataspacePublishesNothingWhenItCannotBeStored()
    {
        var failing = new ContextEndpointAccessor(dataset, updated -> { throw new IOException("no"); });

        assertThrows(IOException.class, () -> failing.putDataspace(END_USER, describing(END_USER, "Replaced")));
        assertEquals("End-user", titleOf(failing.getDataset(), END_USER),
            "a change that could not be stored is the state the platform is running on");
    }

    @Test
    public void testAccessorWithoutPersistenceStillUpdates()
    {
        var ephemeral = new ContextEndpointAccessor(dataset, null);
        ephemeral.update(UpdateFactory.create(
            "INSERT DATA { GRAPH <" + END_USER + "> { <" + END_USER + "> <urn:p> 'added' } }"), null, null);

        assertTrue(ephemeral.getDataset().getNamedModel(END_USER).contains(
            ResourceFactory.createResource(END_USER), ResourceFactory.createProperty("urn:p")));
    }

    @Test
    public void testNullsAreRefused()
    {
        assertThrows(IllegalArgumentException.class, () -> new ContextEndpointAccessor(null, persisted::add));
        assertThrows(IllegalArgumentException.class, () -> accessor.update(null, null, null));
        assertThrows(IllegalArgumentException.class, () -> accessor.putDataspace(null, ModelFactory.createDefaultModel()));
        assertThrows(IllegalArgumentException.class, () -> accessor.putDataspace(END_USER, null));
    }

}
