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
import org.apache.jena.query.Dataset;

/**
 * Where the dataspace descriptions come from and where a change to them is kept: the store behind
 * {@link ContextEndpointAccessor}. The platform keeps them in files ({@link FileContextPersistence}). A deployment
 * that keeps them elsewhere - in a store every replica of the platform reads, over SPARQL and the Graph Store
 * Protocol - supplies its own through a {@link ContextPersistenceProvider}.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public interface ContextPersistence extends ContextEndpointAccessor.Persistence
{

    /**
     * Returns the descriptions the platform runs on.
     *
     * @return the dataspace descriptions
     * @throws IOException if they cannot be read, which stops the platform from starting
     */
    Dataset load() throws IOException;

}
