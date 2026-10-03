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

import com.google.common.util.concurrent.Striped;
import java.net.URI;
import java.util.concurrent.locks.Lock;

/**
 * Locks that serialise the writes to a named graph within this instance.
 * <p>
 * A write to a document is a read-modify-write spread over separate calls to the store: the graph is read,
 * the <code>If-Match</code> precondition is evaluated against what came back, the change is applied in
 * memory and validated, and the whole graph is written back. The store sees independent requests, so the
 * precondition is only as good as the window between the read and the write. Two writers quoting the same
 * entity tag that both read before either has written both pass it, and the second write silently undoes the
 * first - the very lost update the precondition exists to refuse. The Graph Store Protocol has no
 * compare-and-swap, so the check is made atomic here instead: a writer holds the graph's lock from the read
 * to the write, and the writer behind it reads the graph as the first one left it, quotes a tag that no longer
 * matches, and is answered <code>412</code>.
 * <p>
 * The locks are striped rather than one per URI so that the set stays bounded. Two graphs may share a stripe,
 * which serialises writes that did not need serialising, but never lets two writes to the same graph
 * interleave. They are reentrant, since a <code>PATCH</code> that empties a graph completes as a
 * <code>DELETE</code> of it.
 * <p>
 * This serialises the writers that go through this instance. A second instance writing to the same store is not
 * covered, nor is anything that writes to the store directly.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphLocks
{

    /**
     * Number of stripes the graph URIs are spread over.
     */
    public static final int STRIPES = 1024;

    private final Striped<Lock> locks = Striped.lock(STRIPES);

    /**
     * Returns the lock a write to the given graph has to hold from its read of the graph to its write.
     * The same graph URI always yields the same lock.
     * 
     * @param graphURI named graph URI
     * @return reentrant lock for the graph
     */
    public Lock get(URI graphURI)
    {
        if (graphURI == null) throw new IllegalArgumentException("Graph URI cannot be null");

        return locks.get(graphURI);
    }

}
