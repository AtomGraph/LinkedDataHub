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
package com.atomgraph.linkeddatahub.client.filter.auth;

import com.atomgraph.linkeddatahub.server.filter.request.auth.WebIDFilter;
import java.io.IOException;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientRequestFilter;
import org.apache.jena.rdf.model.Resource;

/**
 * Client filter that delegates WebID identity.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDDelegationFilter implements ClientRequestFilter
{

    private final Resource agent;
    
    /**
     * Constructs filter from a delegated agent.
     * 
     * @param agent agent resource
     */
    public WebIDDelegationFilter(Resource agent)
    {
        this.agent = agent;
    }
    
    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        cr.getHeaders().add(WebIDFilter.ON_BEHALF_OF, getAgent().getURI());
    }

    /**
     * Returns delegated agent.
     * 
     * @return agent resource
     */
    public Resource getAgent()
    {
        return agent;
    }
    
}
