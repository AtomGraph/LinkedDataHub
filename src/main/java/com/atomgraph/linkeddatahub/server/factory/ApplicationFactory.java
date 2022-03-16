/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS factory for applications.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.model.impl.Dispatcher
 */
@Provider
public class ApplicationFactory implements Factory<com.atomgraph.linkeddatahub.apps.model.Application>
{

    private static final Logger log = LoggerFactory.getLogger(ApplicationFactory.class);
    
    @Context private ServiceLocator serviceLocator;
    
    @Override
    public com.atomgraph.linkeddatahub.apps.model.Application provide()
    {
        return getApplication(getContainerRequestContext());
    }

    @Override
    public void dispose(com.atomgraph.linkeddatahub.apps.model.Application t)
    {
    }
    
    /**
     * Retrieves application from the request context.
     * 
     * @param crc request context
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication(ContainerRequestContext crc)
    {
        return (com.atomgraph.linkeddatahub.apps.model.Application)crc.getProperty(LAPP.Application.getURI());
    }
    
    /**
     * Returns request context.
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }

}
