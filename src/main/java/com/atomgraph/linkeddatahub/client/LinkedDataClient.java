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
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.server.security.WebIDSecurityContext;
import java.net.URI;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Linked Data client that supports WebID and OIDC delegation.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class LinkedDataClient extends com.atomgraph.core.client.LinkedDataClient
{

    private static final Logger log = LoggerFactory.getLogger(LinkedDataClient.class);

    public final static String USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:107.0) Gecko/20100101 Firefox/107.0"; // impersonate Firefox

    private URI baseURI;
    private AgentContext agentContext;
    
    /**
     * Constructs Linked Data client from HTTP client and media types.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     */
    protected LinkedDataClient(Client client, MediaTypes mediaTypes)
    {
        super(client, mediaTypes);
    }
    
    /**
     * Factory method that accepts HTTP client and media types.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of supported readable/writable media types
     * @return Linked Data client instance
     */
    public static LinkedDataClient create(Client client, MediaTypes mediaTypes)
    {
        return new LinkedDataClient(client, mediaTypes);
    }
    
    /**
     * Builder method that delegates the authenticated agent.
     * It uses client request filters.
     * 
     * @param baseURI application's base URI
     * @param agentContext agent's auth context
     * @return client instance
     */
    public LinkedDataClient delegation(URI baseURI, AgentContext agentContext)
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
    
    /**
     * Executes HTTP <code>GET</code> request.
     * Sends <code>User-Agent</code> header to impersonate a web browser.
     * 
     * @param uri request URI
     * @param acceptedTypes accepted media types
     * @return response
     */
    @Override
    public Response get(URI uri, javax.ws.rs.core.MediaType[] acceptedTypes)
    {
        return getWebTarget(uri).request(acceptedTypes).
            header(HttpHeaders.USER_AGENT, getUserAgentHeaderValue()).
            get();
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
    
}
