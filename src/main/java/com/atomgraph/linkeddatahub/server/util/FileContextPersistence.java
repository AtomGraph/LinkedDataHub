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
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A deployment that keeps its configuration in files.
 *
 * Two files, because they answer to different people. The CONFIGURED one is written by whoever
 * deploys the platform and is regenerated from their sources on every boot - writing a runtime
 * change into it would be writing into something about to be overwritten, which is how an
 * installed package used to be lost on the next restart. The OVERLAY is written by the platform,
 * lives outside the deployed application, and holds the dataspaces that have been changed since.
 *
 * A dataspace the overlay carries REPLACES the configured one rather than adding to it, because a
 * runtime change can remove a statement as well as add one: uninstalling a package removes an
 * ldh:import, and a union would put it straight back. So once a dataspace has been changed at
 * runtime its configuration file stops deciding what it says, and deleting the overlay hands that
 * back. Each one says so in the log at startup.
 *
 * Which dataspaces to write is worked out rather than tracked: a SPARQL update may touch any graph
 * it likes, so the overlay is every dataspace whose description now differs from the configured
 * one. That also keeps it small - a deployment that has changed nothing writes nothing.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class FileContextPersistence implements ContextEndpointAccessor.Persistence
{

    private static final Logger log = LoggerFactory.getLogger(FileContextPersistence.class);

    private final Dataset configured;
    private final File overlay;
    private final File configuredFile;

    /**
     * @param configured the configuration as the deployment's files describe it
     * @param overlay where changes made at runtime are kept, or null for a deployment with nowhere
     *                to keep them - in which case they go back to the configured file, as they did
     *                before there was anywhere better
     * @param configuredFile the file the configured dataset was read from
     */
    public FileContextPersistence(Dataset configured, File overlay, File configuredFile)
    {
        if (configured == null) throw new IllegalArgumentException("Configured dataset cannot be null");

        this.configured = configured;
        this.overlay = overlay;
        this.configuredFile = configuredFile;
    }

    /**
     * Returns the configuration to run on: what the deployment configured, with whatever has been
     * changed since applied over it.
     *
     * @return the dataspace descriptions
     */
    public Dataset load()
    {
        Dataset live = copy(configured);
        if (overlay == null || !overlay.exists()) return live;

        Dataset changes = RDFDataMgr.loadDataset(overlay.toURI().toString());
        changes.listModelNames().forEachRemaining(name ->
        {
            live.removeNamedModel(name.getURI());
            live.addNamedModel(name.getURI(), changes.getNamedModel(name.getURI()));

            if (log.isInfoEnabled()) log.info("Dataspace <{}> restored from {}; the configuration for it is not in effect", name.getURI(), overlay);
        });

        return live;
    }

    @Override
    public void persist(Dataset updated) throws IOException
    {
        if (overlay == null)
        {
            if (configuredFile == null) return; // nowhere to write, and the caller was told so at construction
            write(updated, configuredFile);
            return;
        }

        Dataset changes = DatasetFactory.create();
        updated.listModelNames().forEachRemaining(name ->
        {
            String uri = name.getURI();
            if (!configured.containsNamedModel(uri) || !configured.getNamedModel(uri).isIsomorphicWith(updated.getNamedModel(uri)))
                changes.addNamedModel(uri, updated.getNamedModel(uri));
        });

        if (overlay.getParentFile() != null) overlay.getParentFile().mkdirs();
        write(changes, overlay);

        if (log.isInfoEnabled()) log.info("Wrote {} changed dataspace(s) to {}", changes.listModelNames().hasNext() ? "some" : "no", overlay);
    }

    /**
     * A dataset holding the same graphs as another, so that replacing one leaves the original alone.
     *
     * @param dataset the dataset to copy
     * @return the copy
     */
    protected Dataset copy(Dataset dataset)
    {
        Dataset copy = DatasetFactory.create();
        copy.setDefaultModel(dataset.getDefaultModel());
        dataset.listModelNames().forEachRemaining(name -> copy.addNamedModel(name.getURI(), dataset.getNamedModel(name.getURI())));

        return copy;
    }

    /**
     * Writes a dataset to a file, atomically: a temp file in the target's own directory, moved onto
     * it, so a crash mid-write cannot leave a half-written configuration behind.
     *
     * @param dataset what to write
     * @param file where to write it
     * @throws IOException if the format cannot be determined from the name, or the write fails
     */
    protected void write(Dataset dataset, File file) throws IOException
    {
        Lang lang = RDFDataMgr.determineLang(file.getName(), null, null);
        if (lang == null) throw new IOException("Could not determine RDF format from file name: " + file.getName());

        File temp = File.createTempFile(file.getName(), null, file.getParentFile());
        try (OutputStream out = new FileOutputStream(temp))
        {
            RDFDataMgr.write(out, dataset, lang);
        }
        Files.move(temp.toPath(), file.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
    }

}
