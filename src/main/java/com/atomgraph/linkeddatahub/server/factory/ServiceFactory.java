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

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.util.Optional;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider of application's service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class ServiceFactory implements Factory<Optional<Service>>
{

    private static final Logger log = LoggerFactory.getLogger(ServiceFactory.class);

    @Context private ServiceLocator serviceLocator;
    
    @Override
    public Optional<Service> provide()
    {
        return getService(getContainerRequestContext());
    }

    @Override
    public void dispose(Optional<Service> t)
    {
    }
    
    public Optional<Service> getService(ContainerRequestContext crc)
    {
        Optional<Application> app = (Optional<Application>)crc.getProperty(LAPP.Application.getURI());
        
        if (app.isPresent())
        {
            Service service = app.get().getService();

            // cast to specific implementations
            if (service.canAs(com.atomgraph.linkeddatahub.model.dydra.Service.class)) service = service.as(com.atomgraph.linkeddatahub.model.dydra.Service.class);
            
            return Optional.of(service);
        }
        
        return null;
    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }

}
