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
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.apache.jena.graph.Graph;
import org.apache.jena.ontapi.GraphRepository;

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
 * After model construction, {@link #ids()} equals the set of resolved closure ontology IDs.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ScopedGraphRepository implements GraphRepository
{

    private final GraphRepository backing;
    private final Map<String, Graph> local = new HashMap<>();

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

        return getBacking().get(id);
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
