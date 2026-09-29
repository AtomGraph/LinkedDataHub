/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.vocabulary.LDS;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import net.jodah.expiringmap.ExpirationPolicy;
import net.jodah.expiringmap.ExpiringMap;
import org.apache.jena.graph.Graph;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Ontology graph repository that resolves graphs SPARQL-first: it runs the configured ontology query
 * against the admin endpoint and, only if that returns nothing, falls back to the bundled mappings /
 * HTTP loading of the superclass. Replaces the legacy {@code ModelGetter} plugged into {@code OntModelSpec}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class OntologyRepository extends PrefixGraphRepository
{

    private static final Logger log = LoggerFactory.getLogger(OntologyRepository.class);

    /**
     * Surrogate key carried by every cached ontology response, beside the graph URI of the ontology it holds.
     * Purging it evicts all of them at once, which is what clearing the ontology caches needs: a closure
     * resolves every URI it imports, so evicting only the one a caller named leaves the imports to answer from
     * the proxy. A URN, so it cannot collide with a graph URI in the same key list.
     */
    public static final String ONTOLOGY_XKEY = "urn:linkeddatahub:ontology";

    private final EndUserDataspace app;
    private final com.atomgraph.linkeddatahub.Application system;
    private final Query ontologyQuery;

    /**
     * Constructs the repository for an application.
     *
     * @param app end-user application resource
     * @param system system application
     * @param gsc Graph Store client for HTTP fallback loading
     * @param ontologyQuery SPARQL query that loads ontology terms
     */
    public OntologyRepository(EndUserDataspace app, com.atomgraph.linkeddatahub.Application system, GraphStoreClient gsc, Query ontologyQuery)
    {
        super(gsc);
        this.app = app;
        this.system = system;
        this.ontologyQuery = ontologyQuery;
    }

    /**
     * Backs the dynamically loaded graphs (materialized ontologies and their imports) with a bounded,
     * idle-expiring map instead of an unbounded one. Evicted entries are transparently reloaded — the
     * imports closure is re-materialized by {@code OntologyFilter} on the next cache miss — so this is a
     * memory backstop, not a correctness dependency. Must not reference instance state (called during
     * construction).
     *
     * @return evicting dynamic-graph store
     */
    @Override
    protected Map<String, Graph> createStore()
    {
        return ExpiringMap.builder().
            maxSize(1000).
            expirationPolicy(ExpirationPolicy.ACCESSED). // idle-based: keep actively-used ontologies warm
            expiration(1, TimeUnit.HOURS).
            build();
    }

    @Override
    public Graph get(String uri)
    {
        // Only an already-loaded graph bypasses the query. A bundled mapping does NOT: an application may
        // hold its own graph for the very URI a shipped file is mapped to - an imported vocabulary carrying
        // its annotations, a materialized package ontology - and letting the mapping win there would
        // silently shadow the application's own data with a read-only copy. The store is therefore asked
        // first and the mapping is the fallback. This costs one empty query per bundled vocabulary per
        // repository, not per closure build, because super.get() caches what it loads and isCached() then
        // short-circuits every later call
        if (isCached(uri)) return super.get(uri);

        // attempt to load the ontology from the admin endpoint
        ParameterizedSparqlString ontologyPss = new ParameterizedSparqlString(getOntologyQuery().toString());
        ontologyPss.setIri(LDS.ontology.getLocalName(), uri);

        // Surrogate-key hints for the CONSTRUCT this is about to cache in varnish-admin. The VCL promotes the
        // header verbatim into the response's xkey index, which reads it as a space-separated key list, so this
        // tags the object twice: with the graph URI, which addresses this one ontology, and with the shared key,
        // which addresses every ontology response at once. The shared key is what lets a clear be complete -
        // assembling a closure resolves and caches every URI it imports, each under its own graph URI, and
        // purging only the URI the caller named leaves those imports in the proxy to be read straight back into
        // the closure that was just discarded. Stamped here, where the response is cached, so what a purge
        // covers cannot drift from what the cache actually holds
        MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();
        headers.putSingle("X-Xkey-Promote", uri + " " + ONTOLOGY_XKEY);

        Model model;
        try (Response cr = getSystem().getServiceContext(getDataspace().getAdminDataspace().getService()).getSPARQLClient().
                query(ontologyPss.asQuery(), Model.class, new MultivaluedHashMap<>(), headers))
        {
            model = cr.readEntity(Model.class);
        }

        if (!model.isEmpty())
        {
            Graph graph = model.getGraph();
            put(uri, graph);
            return graph;
        }

        // if the SPARQL result is empty, fall back to bundled mappings / HTTP loading
        return super.get(uri);
    }

    /**
     * Returns the application.
     *
     * @return application resource
     */
    public EndUserDataspace getDataspace()
    {
        return app;
    }

    /**
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns the SPARQL query used to load ontology terms.
     *
     * @return SPARQL query
     */
    public Query getOntologyQuery()
    {
        return ontologyQuery;
    }

}
