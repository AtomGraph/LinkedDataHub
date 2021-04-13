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
package com.atomgraph.linkeddatahub.server.factory;

import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.util.Optional;
import javax.ws.rs.container.ContainerRequestContext;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider of LinkedDataHub application.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class ApplicationFactory implements Factory<Optional<Application>>
{
    private static final Logger log = LoggerFactory.getLogger(ApplicationFactory.class);
    
    @Context private ServiceLocator serviceLocator;
    
    @Override
    public Optional<Application> provide()
    {
        return getApplication(getContainerRequestContext());
    }

    @Override
    public void dispose(Optional<Application> instance)
    {
    }
    
    public Optional<Application> getApplication(ContainerRequestContext crc)
    {
        return (Optional<Application>)crc.getProperty(LAPP.Application.getURI());
    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
