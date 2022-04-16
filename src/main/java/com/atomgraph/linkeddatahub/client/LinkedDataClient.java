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
import java.net.URI;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.WebTarget;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class LinkedDataClient extends com.atomgraph.core.client.LinkedDataClient
{

    private static final Logger log = LoggerFactory.getLogger(LinkedDataClient.class);

    private URI baseURI;
    private AgentContext agentContext;
    
    protected LinkedDataClient(Client client, MediaTypes mediaTypes)
    {
        super(client, mediaTypes);
    }
    
    public static LinkedDataClient create(Client client, MediaTypes mediaTypes)
    {
        return new LinkedDataClient(client, mediaTypes);
    }
    
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
    public WebTarget getWebTarget(URI uri) // TO-DO: protected
    {
        WebTarget webTarget = super.getWebTarget(uri);
        
        if (getAgentContext() != null)
        {
            // TO-DO: unify with other usages of WebIDDelegationFilter/IDTokenDelegationFilter
            if (log.isDebugEnabled()) log.debug("Delegating Agent's <{}> access to secretary", getAgentContext().getAgent());
            webTarget.register(new WebIDDelegationFilter(getAgentContext().getAgent()));
            
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
    
}
