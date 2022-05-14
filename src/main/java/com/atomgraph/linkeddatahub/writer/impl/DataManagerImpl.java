/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.writer.impl;

import org.apache.jena.util.LocationMapper;
import java.net.URI;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import java.util.Map;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Manager for remote RDF dataset access.
 * Documents can be mapped to local copies.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DataManagerImpl extends com.atomgraph.client.util.DataManagerImpl
{
    private static final Logger log = LoggerFactory.getLogger(DataManagerImpl.class);
    
    private final URI rootContextURI;
    private final AgentContext agentContext;

    /**
     * Constructs RDF data manager.
     * 
     * @param mapper location mapper
     * @param modelCache model cache
     * @param ldc Linked Data client
     * @param cacheModelLoads true if loaded RDF models are cached
     * @param preemptiveAuth true if HTTP basic auth is sent preemptively
     * @param resolvingUncached true if uncached URLs are resolved
     * @param rootContextURI the root URI of the JAX-RS application
     * @param agentContext agent context
     */
    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache,
            LinkedDataClient ldc,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI,
            AgentContext agentContext)
    {
        super(mapper, modelCache, ldc, cacheModelLoads, preemptiveAuth, resolvingUncached);
        this.rootContextURI = rootContextURI;
        this.agentContext = agentContext;
    }
    
    @Override
    public boolean resolvingUncached(String filenameOrURI)
    {
        if (super.resolvingUncached(filenameOrURI) && !isMapped(filenameOrURI))
        {
            // always resolve URIs relative to the root Context base URI
            boolean relative = !getRootContextURI().relativize(URI.create(filenameOrURI)).isAbsolute();
            return relative;
        }
        
        return false; // super.resolvingUncached(filenameOrURI); // configured in web.xml
    }

    /**
     * Returns the root URI of the JAX-RS application.
     * 
     * @return root URI
     */
    public URI getRootContextURI()
    {
        return rootContextURI;
    }

    /**
     * Returns the agent context.
     * 
     * @return agent context or null
     */
    public AgentContext getAgentContext()
    {
        return agentContext;
    }
    
}