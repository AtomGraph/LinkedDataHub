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
package com.atomgraph.linkeddatahub.client.provider;

import com.atomgraph.linkeddatahub.apps.model.Application;
import org.apache.jena.util.FileManager;
import org.apache.jena.util.LocationMapper;
import com.sun.jersey.core.spi.component.ComponentContext;
import com.sun.jersey.spi.inject.Injectable;
import com.sun.jersey.spi.inject.PerRequestTypeInjectableProvider;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.ContextResolver;
import javax.ws.rs.ext.Provider;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.DataManager;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.core.ResourceContext;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider for <code>DataManager</code>.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.client.DataManager
 */
@Provider
public class DataManagerProvider extends PerRequestTypeInjectableProvider<Context, DataManager> implements ContextResolver<DataManager>
{
    private static final Logger log = LoggerFactory.getLogger(DataManagerProvider.class);

    private final boolean preemptiveAuth;
    private final boolean resolvingUncached;

    @Context UriInfo uriInfo;
    @Context SecurityContext securityContext;
    @Context ResourceContext resourceContext;
    @Context HttpServletRequest httpServletRequest;
    @Context Providers providers;
    
    public DataManagerProvider(boolean preemptiveAuth, boolean resolvingUncached)
    {
        super(DataManager.class);
        
        this.preemptiveAuth = preemptiveAuth;
        this.resolvingUncached = resolvingUncached;
    }

    @Override
    public Injectable<DataManager> getInjectable(ComponentContext cc, Context a)
    {
        return new Injectable<DataManager>()
        {
            @Override
            public DataManager getValue()
            {
                return getDataManager();
            }
        };
    }

    @Override
    public DataManager getContext(Class<?> type)
    {
        return getDataManager();
    }

    public DataManager getDataManager()
    {
        return getDataManager(LocationMapper.get(), getClient(), getMediaTypes(),
                isPreemptiveAuth(), isResolvingUncached(),
                getApplication(), getSecurityContext(), getResourceContext(), getHttpServletRequest());
    }
    
    public DataManager getDataManager(LocationMapper mapper, Client client, MediaTypes mediaTypes,
            boolean preemptiveAuth, boolean resolvingUncached,
            Application application,
            SecurityContext securityContext, ResourceContext resourceContext, HttpServletRequest httpServletRequest)
    {
        DataManager dataManager = new DataManager(mapper, client, mediaTypes,
                preemptiveAuth, resolvingUncached, application,
                securityContext, resourceContext, httpServletRequest);
        FileManager.setStdLocators(dataManager);
 
        if (log.isTraceEnabled()) log.trace("DataManager LocationMapper: {}", dataManager.getLocationMapper());
        return dataManager;
    }

//    public com.atomgraph.platform.apps.model.Context getContext()
//    {
//        return getProviders().getContextResolver(com.atomgraph.platform.apps.model.Context.class, null).getContext(com.atomgraph.platform.apps.model.Context.class);
//    }
    
    public Application getApplication()
    {
        return getProviders().getContextResolver(Application.class, null).getContext(Application.class);
    }
    
    public MediaTypes getMediaTypes()
    {
        return getProviders().getContextResolver(MediaTypes.class, null).getContext(MediaTypes.class);
    }
    
    public Client getClient()
    {
        return getProviders().getContextResolver(Client.class, null).getContext(Client.class);
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    public Providers getProviders()
    {
        return providers;
    }
    
    public boolean isPreemptiveAuth()
    {
        return preemptiveAuth;
    }

    public boolean isResolvingUncached()
    {
        return resolvingUncached;
    }
    
}