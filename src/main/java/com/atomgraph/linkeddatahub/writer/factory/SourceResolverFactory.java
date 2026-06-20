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

import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.ext.Provider;
import com.atomgraph.client.util.RDFSourceResolver;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.linkeddatahub.writer.impl.SameSiteSourceResolver;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider for the request-scoped XSLT source resolver.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.client.util.RDFSourceResolver
 */
@Provider
public class SourceResolverFactory implements Factory<RDFSourceResolver>
{
    private static final Logger log = LoggerFactory.getLogger(SourceResolverFactory.class);

    @Context UriInfo uriInfo;
    @Context HttpServletRequest httpServletRequest;
    @Context Providers providers;
    @Context ServiceLocator serviceLocator;

    @Inject com.atomgraph.linkeddatahub.Application system;

    @Override
    public RDFSourceResolver provide()
    {
        // falls back to the global repository if there is no application (e.g. for error responses)
        return getResolver(getApplication());
    }

    @Override
    public void dispose(RDFSourceResolver t)
    {
    }

    /**
     * Returns the request-scoped source resolver, backed by the application's ontology repository
     * (or the global repository) and a delegating Graph Store client.
     *
     * @param appOpt optional end-user application (if empty, the global repository is used)
     * @return source resolver
     */
    public RDFSourceResolver getResolver(Optional<Application> appOpt)
    {
        final PrefixGraphRepository repository;

        if (appOpt.isPresent() && appOpt.get().canAs(EndUserApplication.class))
            repository = getSystem().getRepository(appOpt.get().as(EndUserApplication.class));
        else
            repository = getSystem().getRepository();

        GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
            delegation(getUriInfo().getBaseUri(), getAgentContext());

        return new SameSiteSourceResolver(repository, gsc, getSystem().isResolvingUncached(), getSystem().getBaseURI());
    }

    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
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
     * Returns agent context with additional metadata.
     * @return agent context or null
     */
    public AgentContext getAgentContext()
    {
        return (AgentContext)getContainerRequestContext().getProperty(AgentContext.class.getCanonicalName());
        
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
     * Returns the container request context.
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
    /**
     * Retrieves LDT application from the request context.
     *
     * @return optional LDT application
     */
    public Optional<Application> getApplication()
    {
        return (Optional<Application>)getContainerRequestContext().getProperty(LAPP.Application.getURI());
    }
    
}