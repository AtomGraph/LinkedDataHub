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
package com.atomgraph.linkeddatahub.server.provider;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import org.glassfish.hk2.api.Factory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider of application's service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class ServiceProvider implements Factory<Service> // extends PerRequestTypeInjectableProvider<Context, Service> implements ContextResolver<Service>
{

    private static final Logger log = LoggerFactory.getLogger(ServiceProvider.class);

//    @Context HttpServletRequest httpServletRequest;
    @Context ContainerRequestContext crc;

    
//    private final Integer maxGetRequestSize;
//
//    public ServiceProvider(final Integer maxGetRequestSize)
//    {
//        this.maxGetRequestSize = maxGetRequestSize;
//    }
    
    @Override
    public Service provide()
    {
        return getService(crc);
    }

    @Override
    public void dispose(Service t)
    {
    }
    
    public Service getService(ContainerRequestContext crc) // HttpServletRequest httpServletRequest
    {
        Application app = ((Application)crc.getProperty(LAPP.Application.getURI()));
        
        if (app != null)
        {
            Service service = app.getService();

            // cast to specific implementations
            if (service.canAs(com.atomgraph.linkeddatahub.model.dydra.Service.class)) service = service.as(com.atomgraph.linkeddatahub.model.dydra.Service.class);
            
            return service;
        }
        
        return null;
    }
    
//    public HttpServletRequest getHttpServletRequest()
//    {
//        return httpServletRequest;
//    }
    
//    public Integer getMaxGetRequestSize()
//    {
//        return maxGetRequestSize;
//    }
    
}
