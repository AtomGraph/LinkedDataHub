// Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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
