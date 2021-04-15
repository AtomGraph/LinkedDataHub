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
package com.atomgraph.linkeddatahub.client.factory;

import com.atomgraph.linkeddatahub.apps.model.Application;
import org.apache.jena.util.FileManager;
import org.apache.jena.util.LocationMapper;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.Provider;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.client.impl.DataManagerImpl;
import java.net.URI;
import java.util.HashMap;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.client.Client;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.OntDocumentManager;
import org.glassfish.hk2.api.Factory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider for <code>DataManager</code>.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.client.util.DataManager
 */
@Provider
public class DataManagerFactory implements Factory<DataManager>
{
    private static final Logger log = LoggerFactory.getLogger(DataManagerFactory.class);

    @Context UriInfo uriInfo;
    @Context SecurityContext securityContext;
    @Context ResourceContext resourceContext;
    @Context HttpServletRequest httpServletRequest;
    @Context Providers providers;
    
    @Inject MediaTypes mediaTypes;
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject javax.inject.Provider<Optional<Application>> application;
    
    @Override
    public DataManager provide()
    {
        return getDataManager();
    }

    @Override
    public void dispose(DataManager t)
    {
    }
    
    public DataManager getDataManager()
    {
        return getDataManager(LocationMapper.get(), getClient(), getMediaTypes(),
                isPreemptiveAuth(), isResolvingUncached(),
                getApplication().get().orElse(null), getSecurityContext(),
                URI.create(getHttpServletRequest().getRequestURL().toString()).resolve(getHttpServletRequest().getContextPath() + "/"));
    }
    
    public DataManager getDataManager(LocationMapper mapper, Client client, MediaTypes mediaTypes,
            boolean preemptiveAuth, boolean resolvingUncached,
            Application application,
            SecurityContext securityContext,
            URI rootContextURI)
    {
        // copy cached models over from the main ontology cache
        DataManager dataManager = new DataManagerImpl(mapper, new HashMap<>(((DataManager)OntDocumentManager.getInstance().getFileManager()).getModelCache()),
            client, mediaTypes,
            true, preemptiveAuth, resolvingUncached,
            rootContextURI, application, securityContext);
 
        if (log.isTraceEnabled()) log.trace("DataManager LocationMapper: {}", ((FileManager)dataManager).getLocationMapper());
        return dataManager;
    }
    
    public javax.inject.Provider<Optional<Application>> getApplication()
    {
        return application;
    }
    
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    public Client getClient()
    {
        return system.getClient();
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
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
        return system.isPreemptiveAuth();
    }

    public boolean isResolvingUncached()
    {
        return system.isResolvingUncached();
    }
    
}