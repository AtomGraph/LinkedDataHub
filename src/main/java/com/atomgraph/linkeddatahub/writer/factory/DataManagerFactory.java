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
package com.atomgraph.linkeddatahub.writer.factory;

import org.apache.jena.util.FileManager;
import org.apache.jena.util.LocationMapper;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.Provider;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.writer.impl.DataManagerImpl;
import java.net.URI;
import java.util.HashMap;
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
    
    @Override
    public DataManager provide()
    {
        return getDataManager();
    }

    @Override
    public void dispose(DataManager t)
    {
    }
    
    /**
     * Returns RDF data manager.
     * 
     * @return data manager
     */
    public DataManager getDataManager()
    {
        return getDataManager(LocationMapper.get(), getClient(), getMediaTypes(),
                isPreemptiveAuth(), isResolvingUncached(), getSecurityContext(),
                URI.create(getHttpServletRequest().getRequestURL().toString()).resolve(getHttpServletRequest().getContextPath() + "/"));
    }
    
    /**
     * Constructs and returns an RDF data manager instance.
     * 
     * @param mapper location mapper
     * @param client HTTP client
     * @param mediaTypes media type registry
     * @param preemptiveAuth true if HTTP basic auth is sent preemptively
     * @param resolvingUncached true if uncached URLs are resolved
     * @param securityContext JAX-RS security context
     * @param rootContextURI root URI of the JAX-RS application
     * @return data manager
     */
    public DataManager getDataManager(LocationMapper mapper, Client client, MediaTypes mediaTypes,
            boolean preemptiveAuth, boolean resolvingUncached,
            SecurityContext securityContext,
            URI rootContextURI)
    {
        // copy cached models over from the main ontology cache
        DataManager dataManager = new DataManagerImpl(mapper, new HashMap<>(((DataManager)OntDocumentManager.getInstance().getFileManager()).getModelCache()),
            client, mediaTypes,
            true, preemptiveAuth, resolvingUncached,
            rootContextURI, securityContext);
 
        if (log.isTraceEnabled()) log.trace("DataManager LocationMapper: {}", ((FileManager)dataManager).getLocationMapper());
        return dataManager;
    }
    
    /**
     * Returns the registry of readable/writable media types.
     * 
     * @return media type registry
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    /**
     * Returns the HTTP client.
     * 
     * @return client
     */
    public Client getClient()
    {
        return system.getClient();
    }
    
    /**
     * Returns the request URI information.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    /**
     * Returns the JAX-RS security context.
     * 
     * @return security context
     */
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    /**
     * Returns the servlet request.
     * <code>HttpServletRequest</code> is not part of the JAX-RS API.
     * 
     * @return request
     */
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    /**
     * Returns JAX-RS providers.
     * 
     * @return provider registry
     */
    public Providers getProviders()
    {
        return providers;
    }
    
    /**
     * Returns true if HTTP Basic auth credentials are sent preemptively.
     * 
     * @return true if preemptively
     */
    public boolean isPreemptiveAuth()
    {
        return system.isPreemptiveAuth();
    }

    /**
     * Returns true if uncached URLs should be dereferenced by the HTTP client.
     * 
     * @return true if resolved
     */
    public boolean isResolvingUncached()
    {
        return system.isResolvingUncached();
    }
    
}