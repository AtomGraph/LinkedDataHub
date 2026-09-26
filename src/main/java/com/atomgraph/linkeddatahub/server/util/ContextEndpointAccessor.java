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

import com.atomgraph.core.model.EndpointAccessor;
import com.atomgraph.core.model.impl.dataset.EndpointAccessorImpl;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.update.UpdateAction;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * SPARQL access to the platform's own configuration - the dataspace descriptions it was started with.
 *
 * The descriptions are a dataset of named graphs, one per dataspace, keyed by the dataspace's URI.
 * Reaching them through {@link EndpointAccessor} rather than through a bespoke interface is what
 * makes the same platform able to keep them in a file or in a triplestore: core already ships a
 * remote implementation, so a deployment that moves its configuration into a store swaps the
 * implementation and writes no code. It is also the only shape that fits - the dataspaces are
 * named with `urn:` URIs and are not dereferenceable, so the Graph Store Protocol cannot address
 * them directly, and it has no way to enumerate them at startup either. A query has both.
 *
 * Reads are served from memory. The context model is serialised into the XSLT source of every HTML
 * response, so a read must never leave the process; core's dataset-backed EndpointAccessorImpl does
 * exactly that over whichever snapshot is current.
 *
 * Writes are the half core leaves undone - its local implementation logs the update and discards
 * it, which is honest for a dataset loaded read-only from a file and useless here. This applies it,
 * and does the three things that have to happen together:
 *
 *   · COPY-ON-WRITE. Readers hold live views over the dataset from unsynchronised request threads,
 *     so the update is applied to a copy and the reference swapped once it is complete. A plain
 *     in-memory Dataset is not transactional; a DatasetFactory.createTxnMem() one would let this
 *     be done in place, at the cost of every reader having to run in a transaction.
 *   · PERSISTENCE, before the new state is published rather than after: a write that cannot be
 *     stored must not be the state the platform is running on.
 *   · PUBLICATION, which is a single volatile assignment and therefore atomic for readers.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ContextEndpointAccessor implements EndpointAccessor
{

    private static final Logger log = LoggerFactory.getLogger(ContextEndpointAccessor.class);

    /** Where a changed configuration is written so that it outlives the process. */
    @FunctionalInterface
    public interface Persistence
    {
        /**
         * Stores the configuration as it is after a change.
         *
         * @param dataset every dataspace description after the change
         * @throws IOException if it cannot be stored, which abandons the change
         */
        void persist(Dataset dataset) throws IOException;
    }

    // volatile: replaced copy-on-write while request threads read it unsynchronised
    private volatile Dataset dataset;
    private final Object writeLock = new Object();
    private final Persistence persistence;

    /**
     * Constructs the accessor over the configuration the platform started with.
     *
     * @param dataset the dataspace descriptions
     * @param persistence where a change is written; null for a deployment that keeps none
     */
    public ContextEndpointAccessor(Dataset dataset, Persistence persistence)
    {
        if (dataset == null) throw new IllegalArgumentException("Dataset cannot be null");

        this.dataset = dataset;
        this.persistence = persistence;
    }

    /**
     * Returns the configuration as it currently stands.
     *
     * @return the dataspace descriptions
     */
    public Dataset getDataset()
    {
        return dataset;
    }

    /**
     * Returns a reader over the current snapshot.
     *
     * Core's implementation refuses null graph lists - pass empty ones for "the whole dataset". Taken once per read so that a long-running query
     * sees one state throughout, rather than whatever the reference points at when it next looks.
     *
     * @return accessor over the current dataset
     */
    protected EndpointAccessor getReader()
    {
        return new EndpointAccessorImpl(getDataset());
    }

    @Override
    public Dataset loadDataset(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
    {
        return getReader().loadDataset(query, defaultGraphUris, namedGraphUris);
    }

    @Override
    public Model loadModel(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
    {
        return getReader().loadModel(query, defaultGraphUris, namedGraphUris);
    }

    @Override
    public ResultSetRewindable select(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
    {
        return getReader().select(query, defaultGraphUris, namedGraphUris);
    }

    @Override
    public boolean ask(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris)
    {
        return getReader().ask(query, defaultGraphUris, namedGraphUris);
    }

    /**
     * Applies a SPARQL update to the configuration, stores the result and publishes it.
     *
     * @param updateRequest the update
     * @param usingGraphUris ignored: the configuration is the dataset the update runs against
     * @param usingNamedGraphUris ignored, for the same reason
     */
    @Override
    public void update(UpdateRequest updateRequest, List<URI> usingGraphUris, List<URI> usingNamedGraphUris)
    {
        if (updateRequest == null) throw new IllegalArgumentException("UpdateRequest cannot be null");

        synchronized (writeLock)
        {
            Dataset updated = copy(getDataset());
            UpdateAction.execute(updateRequest, updated);
            publish(updated);
        }
    }

    /**
     * Replaces one dataspace's description, leaving the others as they were.
     *
     * The update above can touch any graph it likes; this is for the caller that has already
     * decided what a single dataspace should say and validated it.
     *
     * @param dataspaceURI the dataspace
     * @param model its description
     * @throws IOException if the change cannot be stored
     */
    public void putDataspace(String dataspaceURI, Model model) throws IOException
    {
        if (dataspaceURI == null) throw new IllegalArgumentException("Dataspace URI cannot be null");
        if (model == null) throw new IllegalArgumentException("Model cannot be null");

        synchronized (writeLock)
        {
            Dataset updated = copy(getDataset());
            updated.removeNamedModel(dataspaceURI);
            // copied, so the caller's reference cannot mutate what has been published
            updated.addNamedModel(dataspaceURI, ModelFactory.createDefaultModel().add(model));
            publishChecked(updated);

            if (log.isInfoEnabled()) log.info("Updated dataspace <{}> in the configuration", dataspaceURI);
        }
    }

    /**
     * A dataset sharing the graphs of another, so that replacing one leaves the rest untouched and
     * readers of the original see nothing change.
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
     * Stores the change and then publishes it, in that order.
     *
     * @param updated the configuration after the change
     * @throws IOException if it cannot be stored, in which case nothing is published
     */
    protected void publishChecked(Dataset updated) throws IOException
    {
        if (persistence != null) persistence.persist(updated);
        this.dataset = updated;
    }

    /**
     * Publishes a change whose persistence failure cannot be reported to the caller, the
     * EndpointAccessor contract having nowhere to put an IOException. The change is applied either
     * way - refusing it would leave the platform running on a configuration its own update was
     * rejected from - and the failure is logged as the error it is.
     *
     * @param updated the configuration after the change
     */
    protected void publish(Dataset updated)
    {
        try
        {
            publishChecked(updated);
        }
        catch (IOException ex)
        {
            this.dataset = updated;
            if (log.isErrorEnabled()) log.error("Configuration was updated but could not be stored; the change will not survive a restart", ex);
        }
    }

}
