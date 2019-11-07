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

import com.sun.jersey.core.spi.component.ComponentContext;
import com.sun.jersey.spi.inject.Injectable;
import com.sun.jersey.spi.inject.PerRequestTypeInjectableProvider;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.ContextResolver;
import javax.ws.rs.ext.Provider;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import javax.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider of LinkedDataHub application.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class ApplicationProvider extends PerRequestTypeInjectableProvider<Context, Application> implements ContextResolver<Application>
{
    private static final Logger log = LoggerFactory.getLogger(ApplicationProvider.class);

    @Context HttpServletRequest httpServletRequest;
    
    public ApplicationProvider()
    {
        super(Application.class);
    }
    
    @Override
    public Injectable<Application> getInjectable(ComponentContext ic, Context a)
    {
        return new Injectable<Application>()
        {
            @Override
            public Application getValue()
            {
                return getApplication(getHttpServletRequest());
            }
        };
    }

    @Override
    public Application getContext(Class<?> type)
    {
        return getApplication(getHttpServletRequest());
    }
    
    public Application getApplication(HttpServletRequest httpServletRequest)
    {
        return (Application)httpServletRequest.getAttribute(LAPP.Application.getURI());
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
}
