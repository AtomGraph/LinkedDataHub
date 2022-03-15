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
import javax.ws.rs.core.SecurityContext;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.model.Agent;
import java.util.Map;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.client.WebTarget;
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
    private final String authScheme;
    private final Agent agent;

    /**
     * Constructs RDF data manager.
     * 
     * @param mapper location mapper
     * @param modelCache model cache
     * @param client HTTP client
     * @param mediaTypes media type registry
     * @param cacheModelLoads true if loaded RDF models are cached
     * @param preemptiveAuth true if HTTP basic auth is sent preemptively
     * @param resolvingUncached true if uncached URLs are resolved
     * @param rootContextURI the root URI of the JAX-RS application
     * @param securityContext JAX-RS security context
     */
    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache,
            Client client, MediaTypes mediaTypes,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI,
            SecurityContext securityContext)
    {
        this(mapper, modelCache,
            client, mediaTypes,
            cacheModelLoads, preemptiveAuth, resolvingUncached,
            rootContextURI,
            securityContext != null ? securityContext.getAuthenticationScheme() : null,
            (securityContext != null && securityContext.getUserPrincipal() instanceof Agent) ? (Agent)securityContext.getUserPrincipal() : null);
    }
    
    /**
     * Constructs RDF data manager.
     * 
     * @param mapper location mapper
     * @param modelCache model cache
     * @param client HTTP client
     * @param mediaTypes media type registry
     * @param cacheModelLoads true if loaded RDF models are cached
     * @param preemptiveAuth true if HTTP basic auth is sent preemptively
     * @param resolvingUncached true if uncached URLs are resolved
     * @param rootContextURI the root URI of the JAX-RS application
     * @param authScheme authentication scheme ID
     * @param agent authenticated agent or null
     */
    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache, 
            Client client, MediaTypes mediaTypes,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI,
            String authScheme, Agent agent)
    {
        super(mapper, modelCache, client, mediaTypes, cacheModelLoads, preemptiveAuth, resolvingUncached);
        this.rootContextURI = rootContextURI;
        this.authScheme = authScheme;
        this.agent = agent;
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
     * Returns the client request filter.
     * 
     * @return request filter
     */
    public ClientRequestFilter getClientAuthFilter()
    {
        if (getAgent() != null)
        {
            if (log.isDebugEnabled()) log.debug("Delegating Agent's <{}> access to secretary", getAgent());
            return new WebIDDelegationFilter(getAgent());
        }
            
        return null;
    }
    
    /**
     * Creates web target for URI.
     * 
     * @param uri target URI
     * @return web target
     */
    @Override
    public WebTarget getEndpoint(URI uri)
    {
        return getEndpoint(uri, true);
    }
    
    /**
     * Creates web target for URI.WebID can be delegated depending on the parameter.
     * 
     * @param uri target URI
     * @param delegateWebID delegate if true
     * @return web target
     */
    public WebTarget getEndpoint(URI uri, boolean delegateWebID)
    {
        WebTarget endpoint = super.getEndpoint(uri);
        
        if (delegateWebID) // getBaseURI() != null && !getBaseURI().relativize(uri).isAbsolute()
        {
            ClientRequestFilter filter = getClientAuthFilter();
            if (filter != null) endpoint.register(filter);
        }
        
        return endpoint;
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
     * Returns the authentication scheme.
     * 
     * @return scheme ID.
     */
    public String getAuthScheme()
    {
        return authScheme;
    }
    
    /**
     * Returns the authenticated agent.
     * 
     * @return agent resource or null
     */
    public Agent getAgent()
    {
        return agent;
    }
    
}