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
package com.atomgraph.linkeddatahub.server.security;

import com.atomgraph.linkeddatahub.model.Agent;
import javax.ws.rs.core.SecurityContext;
import java.security.Principal;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Security context for an agent identified by URI.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.model.Agent
 */
public class AgentContext implements SecurityContext
{
    
    private static final Logger log = LoggerFactory.getLogger(AgentContext.class);

    private final Agent agent;
    private final String authScheme;
    
    public AgentContext(String authScheme, Agent agent)
    {
        this.agent = agent;
        this.authScheme = authScheme;
    }
    
    public Agent getAgent()
    {
        return agent;
    }
    
    @Override
    public Principal getUserPrincipal()
    {
        return getAgent();
    }

    @Override
    public boolean isUserInRole(String groupURI)
    {
        return getAgent().getModel().contains(getAgent().getModel().createResource(groupURI), FOAF.member, getAgent());
    }

    @Override
    public boolean isSecure()
    {
        return true;
    }

    @Override
    public String getAuthenticationScheme()
    {
        return authScheme;
    }
    
}
