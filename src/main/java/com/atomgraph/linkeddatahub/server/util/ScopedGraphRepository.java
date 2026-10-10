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

import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.apache.jena.graph.Graph;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.compose.Delta;
import org.apache.jena.ontapi.GraphRepository;
import org.apache.jena.ontapi.utils.Graphs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A graph repository view that reads through a shared backing repository but keeps writes local.
 * <p>
 * Handed to {@code OntModelFactory.createModel(Graph, OntSpecification, GraphRepository)} so that
 * ontapi's union-graph bookkeeping — a {@code UnionGraph} wrapper per ontology in the imports
 * closure, with listeners — lands in this instance's private store instead of the shared repository.
 * The shared repository must keep answering {@code get(uri)} with the raw per-document graph (that is
 * what proxied and direct document GETs serve), and duplicate ontology IDs across applications must
 * not collide in one store. Reads fall through to the backing repository, triggering its
 * SPARQL-first/mapped/HTTP loading and raw caching as usual, so resolving an imports closure through
 * this view populates the shared raw cache as a side effect.
 * <p>
 * ontapi also writes into the graphs of the closure: attaching an import whose header names another
 * ontology than the import URI does (a document imported by its location) adds an {@code owl:imports}
 * of the declared name to the importing graph. Read straight from the shared repository, that write
 * would outlive the closure, and the next closure built over the same cache would resolve both names
 * into two graphs of one name, which ontapi refuses. Backing graphs are therefore handed out wrapped in
 * a {@link Delta} owned by this view, so the writes stay with the closure and the shared graphs keep
 * what their documents say.
 * <p>
 * After model construction, {@link #ids()} equals the set of resolved closure ontology IDs.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ScopedGraphRepository implements GraphRepository
{

    private static final Logger log = LoggerFactory.getLogger(ScopedGraphRepository.class);

    private final GraphRepository backing;
    private final Map<String, Graph> local = new HashMap<>();
    // keyed by backing graph instance, not by ID: a bundled document is one graph shared by every URI of its
    // namespace, and ontapi tells graphs apart by identity, so two wrappers of one graph would be two graphs
    private final Map<Graph, Graph> overlays = new IdentityHashMap<>();

    /**
     * Constructs the view over a shared backing repository.
     *
     * @param backing shared graph repository
     */
    public ScopedGraphRepository(GraphRepository backing)
    {
        this.backing = backing;
    }

    @Override
    public Graph get(String id)
    {
        Graph graph = local.get(id);
        if (graph != null) return graph;

        Graph backed = getBacking().get(id);
        if (backed == null) return null;

        // never closed: closing a Delta closes the graph it wraps
        return overlays.computeIfAbsent(backed, shared ->
        {
            // ontapi files a graph under the name its header declares, so a document that names another ontology
            // than the URI it was resolved by is imported under a second name, which may resolve elsewhere
            Graphs.findOntologyNameNode(shared).filter(Node::isURI).map(Node::getURI).filter(name -> !name.equals(id)).ifPresent(name ->
            {
                if (log.isWarnEnabled()) log.warn("Graph resolved by URI <{}> declares the ontology <{}>", id, name);
            });
            return new Delta(shared);
        });
    }

    @Override
    public Stream<String> ids()
    {
        return List.copyOf(local.keySet()).stream();
    }

    @Override
    public Graph put(String id, Graph graph)
    {
        return local.put(id, graph);
    }

    @Override
    public Graph remove(String id)
    {
        return local.remove(id);
    }

    @Override
    public void clear()
    {
        local.clear();
        overlays.clear();
    }

    @Override
    public boolean contains(String id)
    {
        if (local.containsKey(id) || getBacking().contains(id)) return true;

        // the backing repository's contains() only reports already-cached graphs, but ontapi consults
        // contains() before get() when resolving imports — a false negative for a resolvable id (bundled
        // mapping, SPARQL-first, HTTP) makes ontapi silently substitute an empty ontology graph for the
        // import. Attempt resolution instead: the backing repository loads and caches the graph, and only
        // a genuinely unresolvable id reports absent
        try
        {
            return getBacking().get(id) != null;
        }
        catch (RuntimeException ex)
        {
            return false;
        }
    }

    @Override
    public long count()
    {
        return local.size();
    }

    @Override
    public Stream<Graph> graphs()
    {
        return List.copyOf(local.values()).stream();
    }

    /**
     * Returns the shared backing repository.
     *
     * @return graph repository
     */
    public GraphRepository getBacking()
    {
        return backing;
    }

}
