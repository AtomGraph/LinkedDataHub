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
package com.atomgraph.linkeddatahub.client.filter;

import com.atomgraph.linkeddatahub.model.Agent;
import java.io.IOException;
import javax.inject.Inject;
import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;

/**
 * Client filter that delegates WebID identity.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDDelegationFilter implements ClientRequestFilter
{

    public static final String ON_BEHALF_OF = "On-Behalf-Of";

    @Inject com.atomgraph.linkeddatahub.Application system;
    
    private final Agent agent;
    
    public WebIDDelegationFilter(Agent agent)
    {
        this.agent = agent;
    }
    
    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        if (getAgent() != null) cr.getHeaders().add(ON_BEHALF_OF, getAgent().getURI());
    }

    public Agent getAgent()
    {
        return agent;
    }
    
}
