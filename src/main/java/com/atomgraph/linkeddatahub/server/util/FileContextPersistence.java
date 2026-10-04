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
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.HashSet;
import java.util.Set;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.graph.Triple;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.sparql.core.Quad;
import org.apache.jena.sparql.modify.request.QuadDataAcc;
import org.apache.jena.sparql.modify.request.UpdateDataDelete;
import org.apache.jena.sparql.modify.request.UpdateDataInsert;
import org.apache.jena.update.UpdateAction;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A deployment that keeps its configuration in files.
 *
 * Two files, because they answer to different people. The CONFIGURED one is written by whoever
 * deploys the platform and is regenerated from their sources on every boot - writing a runtime
 * change into it would be writing into something about to be overwritten, which is how an
 * installed package used to be lost on the next restart. The OVERLAY is written by the platform,
 * lives outside the deployed application, and holds what has been changed since.
 *
 * The overlay is a change: a SPARQL Update of DELETE DATA and INSERT DATA, the
 * statements a runtime change removed from the configuration and the ones it added. Loading
 * applies it to the configuration as it is now. A removal stays removed - uninstalling a package
 * deletes an ldh:import, and the configuration cannot put it back - while a statement the deployer
 * adds to the configuration later takes effect, even in a dataspace that has been changed at
 * runtime. The overlay used to be a copy of each changed dataspace, which replaced its
 * configuration wholesale: the wiring config/system.trig contributes to the same graph froze at
 * the moment of the first runtime change, and graph versioning enabled afterwards never started.
 *
 * What to write is worked out rather than tracked: a SPARQL update may touch any graph it likes,
 * so the overlay is the difference between the configured descriptions and the current ones. That
 * also keeps it small - a deployment that has changed nothing writes nothing.
 *
 * Blank nodes cannot be matched across a restart - SPARQL forbids them in DELETE DATA, and a
 * reload relabels them - so removing a statement that has one is not persisted. Dataspace
 * descriptions do not use them.
 *
 * A copy-style overlay from before ({@code dataspaces.trig} beside the change file) is converted
 * once: each dataspace it carries becomes the difference between it and the configuration. It
 * cannot tell a statement removed at runtime from one added to the configuration after it was
 * written, so the latter is carried over as removed and has to be added again.
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
     * @param overlay where changes made at runtime are kept, as a SPARQL Update, or null for a
     *                deployment with nowhere to keep them - in which case they go back to the
     *                configured file, as they did before there was anywhere better
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
     * changed since applied to it.
     *
     * @return the dataspace descriptions
     */
    public Dataset load()
    {
        Dataset live = copy(configured);
        if (overlay == null) return live;

        if (!overlay.exists())
        {
            File legacy = legacyOverlay();
            if (legacy == null || !legacy.exists()) return live;

            Dataset snapshot = RDFDataMgr.loadDataset(legacy.toURI().toString());
            Dataset converted = copy(configured);
            snapshot.listModelNames().forEachRemaining(name ->
            {
                converted.removeNamedModel(name.getURI());
                converted.addNamedModel(name.getURI(), ModelFactory.createDefaultModel().add(snapshot.getNamedModel(name.getURI())));
            });

            try
            {
                persist(converted);
                if (log.isInfoEnabled()) log.info("Converted the dataspace copies in {} to the changes in {}", legacy, overlay);
            }
            catch (IOException ex)
            {
                if (log.isErrorEnabled()) log.error("Could not convert {} to {}; running on the configuration alone", legacy, overlay, ex);
                return live;
            }
        }

        UpdateRequest changes = read(overlay);
        UpdateAction.execute(changes, live);
        if (log.isInfoEnabled() && !changes.getOperations().isEmpty()) log.info("Applied the runtime changes in {} to the configuration", overlay);

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

        QuadDataAcc removed = new QuadDataAcc();
        QuadDataAcc added = new QuadDataAcc();

        Set<String> names = new HashSet<>();
        configured.listModelNames().forEachRemaining(name -> names.add(name.getURI()));
        updated.listModelNames().forEachRemaining(name -> names.add(name.getURI()));

        for (String uri : names)
        {
            Node graph = NodeFactory.createURI(uri);
            Model before = configured.containsNamedModel(uri) ? configured.getNamedModel(uri) : ModelFactory.createDefaultModel();
            Model after = updated.containsNamedModel(uri) ? updated.getNamedModel(uri) : ModelFactory.createDefaultModel();

            before.difference(after).getGraph().find().forEachRemaining(triple ->
            {
                if (hasBlankNode(triple))
                {
                    if (log.isWarnEnabled()) log.warn("Removal of {} from <{}> is not persisted: it has a blank node", triple, uri);
                }
                else removed.addQuad(Quad.create(graph, triple));
            });
            after.difference(before).getGraph().find().forEachRemaining(triple -> added.addQuad(Quad.create(graph, triple)));
        }

        UpdateRequest changes = new UpdateRequest();
        if (!removed.getQuads().isEmpty()) changes.add(new UpdateDataDelete(removed));
        if (!added.getQuads().isEmpty()) changes.add(new UpdateDataInsert(added));

        if (overlay.getParentFile() != null) overlay.getParentFile().mkdirs();
        File temp = File.createTempFile(overlay.getName(), null, overlay.getParentFile());
        try (Writer out = new OutputStreamWriter(new FileOutputStream(temp), StandardCharsets.UTF_8))
        {
            out.write(changes.toString());
        }
        Files.move(temp.toPath(), overlay.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);

        if (log.isInfoEnabled()) log.info("Wrote {} removed and {} added statement(s) to {}", removed.getQuads().size(), added.getQuads().size(), overlay);
    }

    /**
     * The copy-style overlay this one replaces: the same name, as TriG.
     *
     * @return the legacy overlay file, or null if the overlay has no name to derive it from
     */
    protected File legacyOverlay()
    {
        String name = overlay.getName();
        int dot = name.lastIndexOf('.');
        if (dot <= 0) return null;

        return new File(overlay.getParentFile(), name.substring(0, dot) + ".trig");
    }

    /**
     * Reads the overlay's SPARQL Update.
     *
     * @param file the overlay
     * @return the changes it holds
     */
    protected UpdateRequest read(File file)
    {
        try
        {
            return UpdateFactory.create(Files.readString(file.toPath(), StandardCharsets.UTF_8));
        }
        catch (IOException ex)
        {
            throw new IllegalStateException("Could not read the settings overlay " + file, ex);
        }
    }

    private static boolean hasBlankNode(Triple triple)
    {
        return triple.getSubject().isBlank() || triple.getObject().isBlank();
    }

    /**
     * A dataset holding the same graphs as another, so that changing one leaves the original alone. Each graph is
     * copied into a model of its own, because applying the overlay deletes from it.
     *
     * @param dataset the dataset to copy
     * @return the copy
     */
    protected Dataset copy(Dataset dataset)
    {
        Dataset copy = DatasetFactory.create();
        copy.setDefaultModel(dataset.getDefaultModel());
        dataset.listModelNames().forEachRemaining(name -> copy.addNamedModel(name.getURI(), ModelFactory.createDefaultModel().add(dataset.getNamedModel(name.getURI()))));

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
