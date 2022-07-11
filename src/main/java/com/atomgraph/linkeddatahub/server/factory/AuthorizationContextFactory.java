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

import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import java.util.Optional;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class AuthorizationContextFactory implements Factory<Optional<AuthorizationContext>>
{

    @Context private ServiceLocator serviceLocator;

    @Override
    public Optional<AuthorizationContext> provide()
    {
        return getAuthorizationContext();
    }

    @Override
    public void dispose(Optional<AuthorizationContext> arg0)
    {
    }
    
    /**
     * Retrieves authorization context from the request context.
     * 
     * @return optional ontology resource
     */
    public Optional<AuthorizationContext> getAuthorizationContext()
    {
        return Optional.ofNullable((AuthorizationContext)getContainerRequestContext().getProperty(AuthorizationContext.class.getCanonicalName()));
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
