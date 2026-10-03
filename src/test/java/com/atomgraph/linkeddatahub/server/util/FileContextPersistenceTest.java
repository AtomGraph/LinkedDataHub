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

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.sparql.modify.request.UpdateData;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Tests for the file-backed configuration: what is configured, what has been changed since, and
 * which of the two a restart runs on.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class FileContextPersistenceTest
{

    private static final String END_USER = "urn:linkeddatahub:apps/end-user";
    private static final String ADMIN = "urn:linkeddatahub:apps/admin";
    private static final String TITLE = "http://purl.org/dc/terms/title";
    private static final String IMPORT = "https://w3id.org/atomgraph/linkeddatahub#import";
    private static final String VERSIONING = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#versioningRepository";

    @TempDir
    private Path dir;

    private Dataset configured;
    private File overlay;

    private static Model describing(String uri, String title)
    {
        Model model = ModelFactory.createDefaultModel();
        model.add(ResourceFactory.createResource(uri), ResourceFactory.createProperty(TITLE), title);

        return model;
    }

    private static String titleOf(Dataset dataset, String uri)
    {
        return dataset.getNamedModel(uri).
            getProperty(ResourceFactory.createResource(uri), ResourceFactory.createProperty(TITLE)).
            getString();
    }

    private static boolean states(Dataset dataset, String uri, String property, String object)
    {
        return dataset.getNamedModel(uri).contains(ResourceFactory.createResource(uri), ResourceFactory.createProperty(property), ResourceFactory.createResource(object));
    }

    private static void state(Dataset dataset, String uri, String property, String object)
    {
        dataset.getNamedModel(uri).add(ResourceFactory.createResource(uri), ResourceFactory.createProperty(property), ResourceFactory.createResource(object));
    }

    private static void unstate(Dataset dataset, String uri, String property, String object)
    {
        dataset.getNamedModel(uri).remove(ResourceFactory.createResource(uri), ResourceFactory.createProperty(property), ResourceFactory.createResource(object));
    }

    private UpdateRequest written() throws IOException
    {
        return UpdateFactory.create(Files.readString(overlay.toPath()));
    }

    @BeforeEach
    public void setUp()
    {
        configured = DatasetFactory.create();
        configured.addNamedModel(END_USER, describing(END_USER, "End-user"));
        configured.addNamedModel(ADMIN, describing(ADMIN, "Admin"));

        overlay = dir.resolve("dataspaces.ru").toFile();
    }

    @Test
    public void testLoadsTheConfigurationWhenNothingHasChanged()
    {
        Dataset live = new FileContextPersistence(configured, overlay, null).load();

        assertEquals("End-user", titleOf(live, END_USER));
        assertEquals("Admin", titleOf(live, ADMIN));
    }

    @Test
    public void testAChangedDataspaceSurvivesAReload() throws IOException
    {
        var persistence = new FileContextPersistence(configured, overlay, null);

        Dataset updated = persistence.load();
        updated.removeNamedModel(END_USER);
        updated.addNamedModel(END_USER, describing(END_USER, "Renamed"));
        persistence.persist(updated);

        // what a restart does: read the configuration again, apply what was changed since
        Dataset reloaded = new FileContextPersistence(configured, overlay, null).load();
        assertEquals("Renamed", titleOf(reloaded, END_USER), "the change did not survive");
        assertEquals("Admin", titleOf(reloaded, ADMIN), "an untouched dataspace stopped following its configuration");
    }

    @Test
    public void testOnlyChangedDataspacesAreWritten() throws IOException
    {
        var persistence = new FileContextPersistence(configured, overlay, null);

        Dataset updated = persistence.load();
        updated.removeNamedModel(END_USER);
        updated.addNamedModel(END_USER, describing(END_USER, "Renamed"));
        persistence.persist(updated);

        var graphs = written().getOperations().stream().
            flatMap(op -> ((UpdateData)op).getQuads().stream()).
            map(quad -> quad.getGraph().getURI()).
            distinct().toList();
        assertEquals(java.util.List.of(END_USER), graphs, "a dataspace nobody changed was written to the overlay");
    }

    @Test
    public void testAnEditedConfigurationStillReachesAnUntouchedDataspace() throws IOException
    {
        var persistence = new FileContextPersistence(configured, overlay, null);
        Dataset updated = persistence.load();
        updated.removeNamedModel(END_USER);
        updated.addNamedModel(END_USER, describing(END_USER, "Renamed"));
        persistence.persist(updated);

        // the deployer edits the configuration of the dataspace they never touched at runtime
        Dataset edited = DatasetFactory.create();
        edited.addNamedModel(END_USER, describing(END_USER, "End-user"));
        edited.addNamedModel(ADMIN, describing(ADMIN, "Admin, renamed in the configuration"));

        Dataset live = new FileContextPersistence(edited, overlay, null).load();
        assertEquals("Admin, renamed in the configuration", titleOf(live, ADMIN), "the edit did not take effect");
        assertEquals("Renamed", titleOf(live, END_USER), "the runtime change lost to the configuration");
    }

    @Test
    public void testPersistingNothingWritesAnEmptyOverlay() throws IOException
    {
        var persistence = new FileContextPersistence(configured, overlay, null);
        persistence.persist(persistence.load());

        assertTrue(overlay.exists());
        assertTrue(written().getOperations().isEmpty(), "an unchanged configuration put something in the overlay");
    }

    @Test
    public void testAStatementAddedToTheConfigurationReachesAChangedDataspace() throws IOException
    {
        var persistence = new FileContextPersistence(configured, overlay, null);
        Dataset updated = persistence.load();
        state(updated, END_USER, IMPORT, "https://packages.example/taxonomy/#this");
        persistence.persist(updated);

        // the deployer enables versioning for the dataspace a package was installed into
        Dataset edited = DatasetFactory.create();
        edited.addNamedModel(END_USER, describing(END_USER, "End-user"));
        edited.addNamedModel(ADMIN, describing(ADMIN, "Admin"));
        state(edited, END_USER, VERSIONING, "urn:linkeddatahub:versioning/end-user");

        Dataset live = new FileContextPersistence(edited, overlay, null).load();
        assertTrue(states(live, END_USER, VERSIONING, "urn:linkeddatahub:versioning/end-user"), "the configuration edit was shadowed by the runtime change");
        assertTrue(states(live, END_USER, IMPORT, "https://packages.example/taxonomy/#this"), "the runtime change was lost");
    }

    @Test
    public void testAStatementRemovedAtRuntimeStaysRemoved() throws IOException
    {
        state(configured, END_USER, IMPORT, "https://packages.example/taxonomy/#this");
        var persistence = new FileContextPersistence(configured, overlay, null);
        Dataset updated = persistence.load();
        unstate(updated, END_USER, IMPORT, "https://packages.example/taxonomy/#this");
        persistence.persist(updated);

        Dataset live = new FileContextPersistence(configured, overlay, null).load();
        assertFalse(states(live, END_USER, IMPORT, "https://packages.example/taxonomy/#this"), "the uninstalled package came back from the configuration");
        assertEquals("End-user", titleOf(live, END_USER));
    }

    @Test
    public void testLoadingLeavesTheConfigurationAlone() throws IOException
    {
        state(configured, END_USER, IMPORT, "https://packages.example/taxonomy/#this");
        var persistence = new FileContextPersistence(configured, overlay, null);
        Dataset updated = persistence.load();
        unstate(updated, END_USER, IMPORT, "https://packages.example/taxonomy/#this");
        persistence.persist(updated);

        new FileContextPersistence(configured, overlay, null).load();
        assertTrue(states(configured, END_USER, IMPORT, "https://packages.example/taxonomy/#this"), "applying the overlay deleted from the configuration itself");
    }

    @Test
    public void testALegacyCopyIsConvertedToChanges() throws IOException
    {
        // what the copy-style overlay held: the whole end-user description, renamed at runtime
        Dataset copy = DatasetFactory.create();
        copy.addNamedModel(END_USER, describing(END_USER, "Renamed"));
        try (var out = new java.io.FileOutputStream(dir.resolve("dataspaces.trig").toFile()))
        {
            RDFDataMgr.write(out, copy, org.apache.jena.riot.Lang.TRIG);
        }

        Dataset live = new FileContextPersistence(configured, overlay, null).load();
        assertEquals("Renamed", titleOf(live, END_USER), "the legacy change was not carried over");
        assertEquals("Admin", titleOf(live, ADMIN));
        assertTrue(overlay.exists(), "the conversion was not written");

        // converted once: the change file decides from now on
        Dataset edited = DatasetFactory.create();
        edited.addNamedModel(END_USER, describing(END_USER, "End-user"));
        edited.addNamedModel(ADMIN, describing(ADMIN, "Admin"));
        state(edited, END_USER, VERSIONING, "urn:linkeddatahub:versioning/end-user");
        assertTrue(states(new FileContextPersistence(edited, overlay, null).load(), END_USER, VERSIONING, "urn:linkeddatahub:versioning/end-user"));
    }

    @Test
    public void testWithoutAnOverlayItWritesTheConfiguredFile() throws IOException
    {
        File configuredFile = dir.resolve("system.nq").toFile();
        var persistence = new FileContextPersistence(configured, null, configuredFile);

        Dataset updated = persistence.load();
        updated.removeNamedModel(END_USER);
        updated.addNamedModel(END_USER, describing(END_USER, "Renamed"));
        persistence.persist(updated);

        assertEquals("Renamed", titleOf(RDFDataMgr.loadDataset(configuredFile.toURI().toString()), END_USER));
    }

    @Test
    public void testWithNowhereToWriteItDoesNotThrow() throws IOException
    {
        new FileContextPersistence(configured, null, null).persist(configured);
    }

    @Test
    public void testAnUnknownFormatIsRefusedRatherThanGuessed()
    {
        var persistence = new FileContextPersistence(configured, null, dir.resolve("system.wat").toFile());

        assertThrows(IOException.class, () -> persistence.persist(configured));
    }

    @Test
    public void testNullConfigurationIsRefused()
    {
        assertThrows(IllegalArgumentException.class, () -> new FileContextPersistence(null, overlay, null));
    }

}
