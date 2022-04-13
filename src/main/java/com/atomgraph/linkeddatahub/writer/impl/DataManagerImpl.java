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
import com.atomgraph.linkeddatahub.client.filter.auth.IDTokenDelegationFilter;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import java.util.Map;
import java.util.Optional;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.UriInfo;
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
    private final UriInfo uriInfo;
    private final SecurityContext securityContext;
    private final Optional<AgentContext> agentContext;

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
     * @param uriInfo URI information of the current request
     * @param securityContext JAX-RS security context
     * @param agentContext agent context
     */
    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache,
            Client client, MediaTypes mediaTypes,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI, UriInfo uriInfo,
            SecurityContext securityContext, Optional<AgentContext> agentContext)
    {
        super(mapper, modelCache, client, mediaTypes, cacheModelLoads, preemptiveAuth, resolvingUncached);
        this.rootContextURI = rootContextURI;
        this.uriInfo = uriInfo;
        this.securityContext = securityContext;
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
        
        if (delegateWebID)
        {
            // TO-DO: unify with other usages of WebIDDelegationFilter/IDTokenDelegationFilter
            if (getSecurityContext().getUserPrincipal() instanceof Agent agent)
            {
                if (log.isDebugEnabled()) log.debug("Delegating Agent's <{}> access to secretary", agent);
                endpoint.register(new WebIDDelegationFilter(agent));
            }
            
            if (getAgentContext().isPresent() && getAgentContext().get() instanceof IDTokenSecurityContext)
            {
                IDTokenSecurityContext idTokenContext = ((IDTokenSecurityContext)getAgentContext().get());
                endpoint.register(new IDTokenDelegationFilter(idTokenContext.getAgent(), idTokenContext.getJWTToken(),
                    getUriInfo().getBaseUri().getPath(), null));
            }
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
     * Returns the URI information of the current request.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    /**
     * Returns the security context.
     * 
     * @return security context.
     */
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }

    /**
     * Returns the agent context.
     * 
     * @return optional agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }
    
}