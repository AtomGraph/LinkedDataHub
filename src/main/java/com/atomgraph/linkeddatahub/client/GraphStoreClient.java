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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.filter.auth.IDTokenDelegationFilter;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.client.util.RetryAfterHelper;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.server.security.WebIDSecurityContext;
import java.net.URI;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Graph Store client that supports WebID and OIDC delegation.
 * Sends <code>User-Agent</code> header to impersonate a web browser.
 * Respects <code>Retry-After</code> response headers.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class GraphStoreClient extends com.atomgraph.core.client.GraphStoreClient
{

    private static final Logger log = LoggerFactory.getLogger(GraphStoreClient.class);

    /**
     * <samp>User-Agent</samp> request header value used by this HTTP client.
     */
    public final static String USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:107.0) Gecko/20100101 Firefox/107.0"; // impersonate Firefox

    private URI baseURI;
    private AgentContext agentContext;
    private long defaultDelayMillis;
    private final int maxRetryCount;

    /**
     * Constructs Graph Store Protocol client.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     */
    protected GraphStoreClient(Client client, MediaTypes mediaTypes)
    {
        this(client, mediaTypes, null);
    }
    
    /**
     * Constructs Graph Store Protocol client.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     * @param endpoint endpoint URL (optional)
     */
    protected GraphStoreClient(Client client, MediaTypes mediaTypes, URI endpoint)
    {
        this(client, mediaTypes, endpoint, 5000L, 3);
    }
    
    /**
     * Constructs Graph Store Protocol client.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     * @param endpoint endpoint URL (optional)
     * @param defaultDelayMillis default period the client waits before retrying the request
     * @param maxRetryCount maximum number of request retries
     */
    protected GraphStoreClient(Client client, MediaTypes mediaTypes, URI endpoint, long defaultDelayMillis, int maxRetryCount)
    {
        super(client, mediaTypes, endpoint);
        this.defaultDelayMillis = defaultDelayMillis;
        this.maxRetryCount = maxRetryCount;
    }
    
    /**
     * Factory method that accepts HTTP client, media types, and max retry count.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     * @param endpoint endpoint URL (optional)
     * @param defaultDelayMillis default period the client waits before retrying the request
     * @param maxRetryCount max request retry count
     * @return Graph Store client instance
     */
    public static GraphStoreClient create(Client client, MediaTypes mediaTypes, URI endpoint, long defaultDelayMillis, int maxRetryCount)
    {
        return new GraphStoreClient(client, mediaTypes, endpoint, defaultDelayMillis, maxRetryCount);
    }
   
    /**
     * Factory method that accepts HTTP client and media types.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     * @param endpoint endpoint URL (optional)
     * @return Graph Store client instance
     */
    public static GraphStoreClient create(Client client, MediaTypes mediaTypes, URI endpoint)
    {
        return new GraphStoreClient(client, mediaTypes, endpoint);
    }
    
    /**
     * Factory method that accepts HTTP client and media types.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     * @return Graph Store client instance
     */
    public static GraphStoreClient create(Client client, MediaTypes mediaTypes)
    {
        return new GraphStoreClient(client, mediaTypes);
    }
    
    /**
     * Builder method that delegates the authenticated agent.
     * It uses client request filters.
     * 
     * @param baseURI application's base URI
     * @param agentContext agent's auth context
     * @return client instance
     */
    public GraphStoreClient delegation(URI baseURI, AgentContext agentContext)
    {
        this.baseURI = baseURI;
        this.agentContext = agentContext;
        return this;
    }
    
    /**
     * Creates web target for URI.WebID can be delegated depending on the parameter.
     * 
     * @param uri target URI
     * @return web target
     */
    @Override
    protected WebTarget getWebTarget(URI uri)
    {
        WebTarget webTarget = super.getWebTarget(uri);
        
        if (getAgentContext() != null)
        {
            if (getAgentContext() instanceof WebIDSecurityContext webIDSecurityContext)
            {
                // TO-DO: unify with other usages of WebIDDelegationFilter/IDTokenDelegationFilter
                if (log.isDebugEnabled()) log.debug("Delegating Agent's <{}> access to secretary", webIDSecurityContext.getAgent());
                webTarget.register(new WebIDDelegationFilter(webIDSecurityContext.getAgent()));
            }
            
            if (getAgentContext() instanceof IDTokenSecurityContext iDTokenSecurityContext)
            {
                IDTokenSecurityContext idTokenContext = iDTokenSecurityContext;
                webTarget.register(new IDTokenDelegationFilter(idTokenContext.getAgent(), idTokenContext.getJWTToken(),
                    getBaseURI().getPath(), null));
            }
        }
        
        return webTarget;
    }
    
    @Override
    public Response get(URI uri, jakarta.ws.rs.core.MediaType[] acceptedTypes)
    {
        WebTarget webTarget = getWebTarget(uri);
        return new RetryAfterHelper(getDefaultDelayMillis(), getMaxRetryCount()).invokeWithRetry(() ->
            webTarget.request(acceptedTypes)
                     .header(HttpHeaders.USER_AGENT, getUserAgentHeaderValue())
                     .get());
    }
   
    @Override
    public Response post(URI uri, Entity entity, MediaType[] acceptedTypes)
    {
        WebTarget webTarget = getWebTarget(uri);
        return new RetryAfterHelper(getDefaultDelayMillis(), getMaxRetryCount()).invokeWithRetry(() ->
            webTarget.request(acceptedTypes).post(entity));
    }
    
    @Override
    public Response put(URI uri, Entity entity, MediaType[] acceptedTypes)
    {
        WebTarget webTarget = getWebTarget(uri);
        return new RetryAfterHelper(getDefaultDelayMillis(), getMaxRetryCount()).invokeWithRetry(() ->
            webTarget.request(acceptedTypes).put(entity));
    }
    
    /**
     * Sends a PUT request with RDF model data to the specified URI.
     * 
     * @param uri the target URI
     * @param model the RDF model to send
     * @param headers additional HTTP headers
     * @return the HTTP response
     */
    public Response put(URI uri, Model model, MultivaluedMap<String, Object> headers)
    {
        WebTarget webTarget = getWebTarget(uri);
        return new RetryAfterHelper(getDefaultDelayMillis(), getMaxRetryCount()).invokeWithRetry(() ->
            webTarget.request(getReadableMediaTypes(Model.class)).
                headers(headers).
                put(Entity.entity(model, getDefaultMediaType())));
    }
    
    @Override
    public Response delete(URI uri)
    {
        WebTarget webTarget = getWebTarget(uri);
        return new RetryAfterHelper(getDefaultDelayMillis(), getMaxRetryCount()).invokeWithRetry(() ->
            webTarget.request().delete());
    }

    /**
     * Sends a PATCH request with SPARQL UPDATE to the specified graph URI.
     *
     * @param uri the target graph URI
     * @param updateRequest the SPARQL UPDATE request
     * @return the HTTP response
     */
    public Response patch(URI uri, UpdateRequest updateRequest)
    {
        if (updateRequest == null) throw new IllegalArgumentException("UpdateRequest cannot be null");

        WebTarget webTarget = getWebTarget(uri);
        String updateString = updateRequest.toString();

        return new RetryAfterHelper(getDefaultDelayMillis(), getMaxRetryCount()).invokeWithRetry(() ->
            webTarget.request().method("PATCH", Entity.entity(updateString, "application/sparql-update")));
    }

    /**
     * Returns the application's base URI.
     *
     * @return base URI
     */
    public URI getBaseURI()
    {
        return baseURI;
    }
    
    /**
     * Returns the authenticated agent's context.
     * 
     * @return agent context
     */
    public AgentContext getAgentContext()
    {
        return agentContext;
    }
    
    /**
     * Returns the value of the <code>User-Agent</code> request header.
     * 
     * @return header value
     */
    public String getUserAgentHeaderValue()
    {
        return USER_AGENT;
    }
    
    /**
     * Returns default period the client waits before retrying the request
     * 
     * @return millisecond amount
     */
    public long getDefaultDelayMillis()
    {
        return defaultDelayMillis;
    }
    
    /**
     * Returns the maximum amount of request retries
     * 
     * @return max request retry count
     */
    public int getMaxRetryCount()
    {
        return maxRetryCount;
    }
    
}
