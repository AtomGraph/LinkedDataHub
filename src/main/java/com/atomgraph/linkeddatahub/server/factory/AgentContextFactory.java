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
package com.atomgraph.linkeddatahub.server.factory;

import com.atomgraph.linkeddatahub.server.security.AgentContext;
import java.util.Optional;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.ext.Provider;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;

/**
 * JAX-RS factory for agent context.
 * <code>SecurityContext</code> cannot be used outside JAX-RS classes (<samp>Not inside a request scope</samp>).
 * Therefore we need a specialized agent context class.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class AgentContextFactory implements Factory<Optional<AgentContext>>
{

    @Context private ServiceLocator serviceLocator;

    @Override
    public Optional<AgentContext> provide()
    {
        return getAgentContext();
    }

    @Override
    public void dispose(Optional<AgentContext> arg0)
    {
    }
    
    /**
     * Retrieves agent context from the request context.
     * 
     * @return optional ontology resource
     */
    public Optional<AgentContext> getAgentContext()
    {
        return Optional.ofNullable((AgentContext)getContainerRequestContext().getProperty(AgentContext.class.getCanonicalName()));
    }
    
    /**
     * Gets the context of the current request.
     * 
     * @return context of the current request
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
