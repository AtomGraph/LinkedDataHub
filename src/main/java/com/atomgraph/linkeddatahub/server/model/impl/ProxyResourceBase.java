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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.client.filter.auth.IDTokenDelegationFilter;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.server.security.WebIDSecurityContext;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.util.FileManager;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that proxies Linked Data documents.
 * It uses an HTTP client to dereference URIs and sends back the client response.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ProxyResourceBase extends com.atomgraph.client.model.impl.ProxyResourceBase
{

    private static final Logger log = LoggerFactory.getLogger(ProxyResourceBase.class);

    private final UriInfo uriInfo;
    private final ContainerRequestContext crc;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final Service service;
    private final DataManager dataManager;
    private final Optional<AgentContext> agentContext;
    private final MediaType[] readableMediaTypes;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs the resource.
     * 
     * @param uriInfo current request URI info
     * @param request current request
     * @param httpHeaders HTTP header info
     * @param mediaTypes registry of readable/writable media types
     * @param application current application
     * @param service application's SPARQL service
     * @param securityContext JAX-RS security context
     * @param crc request context
     * @param system system application
     * @param httpServletRequest servlet request
     * @param dataManager RDFdata manager
     * @param agentContext authenticated agent's context
     * @param providers registry of JAX-RS providers
     * @param dataset optional dataset
     */
    @Inject
    public ProxyResourceBase(@Context UriInfo uriInfo, @Context Request request, @Context HttpHeaders httpHeaders, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Service> service,
            @Context SecurityContext securityContext, @Context ContainerRequestContext crc,
            com.atomgraph.linkeddatahub.Application system, @Context HttpServletRequest httpServletRequest, DataManager dataManager, Optional<AgentContext> agentContext,
            @Context Providers providers, Optional<Dataset> dataset)
    {
        this(uriInfo, request, httpHeaders, mediaTypes, application, service, securityContext, crc,
                uriInfo.getQueryParameters().getFirst(AC.uri.getLocalName()) == null ? 
                    dataset.isEmpty() ? null : dataset.get().getProxied(uriInfo.getAbsolutePath())
                    :
                    URI.create(uriInfo.getQueryParameters().getFirst(AC.uri.getLocalName())),
                uriInfo.getQueryParameters().getFirst(AC.endpoint.getLocalName()) == null ? null : URI.create(uriInfo.getQueryParameters().getFirst(AC.endpoint.getLocalName())),
                uriInfo.getQueryParameters().getFirst(AC.accept.getLocalName()) == null ? null : MediaType.valueOf(uriInfo.getQueryParameters().getFirst(AC.accept.getLocalName())),
                uriInfo.getQueryParameters().getFirst(AC.mode.getLocalName()) == null ? null : URI.create(uriInfo.getQueryParameters().getFirst(AC.mode.getLocalName())),
                system, httpServletRequest, dataManager, agentContext, providers);
    }
    
    /**
     * Constructs the resource.
     * 
     * @param uriInfo current request URI info
     * @param request current request
     * @param httpHeaders HTTP header info
     * @param mediaTypes registry of readable/writable media types
     * @param application current application
     * @param service application's SPARQL service
     * @param securityContext JAX-RS security context
     * @param crc request context
     * @param uri <code>uri</code> URL param
     * @param endpoint <code>endpoint</code> URL param
     * @param accept <code>accept</code> URL param
     * @param mode <code>mode</code> URL param
     * @param system system application
     * @param httpServletRequest servlet request
     * @param dataManager RDFdata manager
     * @param agentContext authenticated agent's context
     * @param providers registry of JAX-RS providers
     */
    protected ProxyResourceBase(@Context UriInfo uriInfo, @Context Request request, @Context HttpHeaders httpHeaders, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Service> service,
            @Context SecurityContext securityContext, @Context ContainerRequestContext crc,
            @QueryParam("uri") URI uri, @QueryParam("endpoint") URI endpoint, @QueryParam("accept") MediaType accept, @QueryParam("mode") URI mode,
            com.atomgraph.linkeddatahub.Application system, @Context HttpServletRequest httpServletRequest, DataManager dataManager, Optional<AgentContext> agentContext,
            @Context Providers providers)
    {
        super(uriInfo, request, httpHeaders, mediaTypes, uri, endpoint, accept, mode, system.getExternalClient(), httpServletRequest);
        this.uriInfo = uriInfo;
        this.application = application;
        this.service = service.get();
        this.crc = crc;
        this.dataManager = dataManager;
        this.agentContext = agentContext;
        this.providers = providers;
        this.system = system;

        List<jakarta.ws.rs.core.MediaType> readableMediaTypesList = new ArrayList<>();
        readableMediaTypesList.addAll(mediaTypes.getReadable(Model.class));
        readableMediaTypesList.addAll(mediaTypes.getReadable(ResultSet.class)); // not in the superclass
        this.readableMediaTypes = readableMediaTypesList.toArray(MediaType[]::new);
        
        if (agentContext.isPresent())
        {
            if (agentContext.get() instanceof WebIDSecurityContext)
                super.getWebTarget().register(new WebIDDelegationFilter(agentContext.get().getAgent()));
            
            if (agentContext.get() instanceof IDTokenSecurityContext iDTokenSecurityContext)
                super.getWebTarget().register(new IDTokenDelegationFilter(agentContext.get().getAgent(),
                    iDTokenSecurityContext.getJWTToken(), uriInfo.getBaseUri().getPath(), null));
        }
    }
    
    /**
     * Gets a request invocation builder for the given target.
     * 
     * @param target web target
     * @return invocation builder
     */
    @Override
    public Invocation.Builder getBuilder(WebTarget target)
    {
        return target.request(getReadableMediaTypes()).
            header(HttpHeaders.USER_AGENT, getUserAgentHeaderValue());
    }
    
    /**
     * Forwards <code>GET</code> request and returns response from remote resource.
     * 
     * @param target target URI
     * @param builder invocation builder
     * @return response
     */
    @Override
    public Response get(WebTarget target, Invocation.Builder builder)
    {
        // check if we have the model in the cache first and if yes, return it from there instead making an HTTP request
        if (((FileManager)getDataManager()).hasCachedModel(target.getUri().toString()) ||
                (getDataManager().isResolvingMapped() && getDataManager().isMapped(target.getUri().toString()))) // read mapped URIs (such as system ontologies) from a file
        {
            if (log.isDebugEnabled()) log.debug("hasCachedModel({}): {}", target.getUri(), ((FileManager)getDataManager()).hasCachedModel(target.getUri().toString()));
            if (log.isDebugEnabled()) log.debug("isMapped({}): {}", target.getUri(), getDataManager().isMapped(target.getUri().toString()));
            return getResponse(getDataManager().loadModel(target.getUri().toString()));
        }

        if (!getSystem().isEnableLinkedDataProxy()) throw new BadRequestException("Linked Data proxy not enabled");

        return super.get(target, builder);
    }
    
    /**
     * Forwards a multipart <code>POST</code> request returns RDF response from remote resource.
     * 
     * @param multiPart form data
     * @return response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response postMultipart(FormDataMultiPart multiPart)
    {
        if (!getSystem().isEnableLinkedDataProxy()) throw new BadRequestException("Linked Data proxy not enabled");
        if (getWebTarget() == null) throw new NotFoundException("Resource URI not supplied"); // cannot throw Exception in constructor: https://github.com/eclipse-ee4j/jersey/issues/4436
        
        try (Response cr = getWebTarget().request().
            accept(getMediaTypes().getReadable(Model.class).toArray(jakarta.ws.rs.core.MediaType[]::new)).
            post(Entity.entity(multiPart, multiPart.getMediaType())))
        {
            if (log.isDebugEnabled()) log.debug("POSTing multipart data to URI: {}", getWebTarget().getUri());
            return getResponse(cr);
        }
    }
    
    /**
     * Forwards a multipart <code>PUT</code> request returns RDF response from remote resource.
     * 
     * @param multiPart form data
     * @return response
     */
    @PUT
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response putMultipart(FormDataMultiPart multiPart)
    {
        if (!getSystem().isEnableLinkedDataProxy()) throw new BadRequestException("Linked Data proxy not enabled");
        if (getWebTarget() == null) throw new NotFoundException("Resource URI not supplied"); // cannot throw Exception in constructor: https://github.com/eclipse-ee4j/jersey/issues/4436
        
        try (Response cr = getWebTarget().request().
                accept(getMediaTypes().getReadable(Model.class).toArray(jakarta.ws.rs.core.MediaType[]::new)).
                put(Entity.entity(multiPart, multiPart.getMediaType())))
        {
            if (log.isDebugEnabled()) log.debug("PUTing multipart data to URI: {}", getWebTarget().getUri());
            return getResponse(cr);
        }
    }
    
    /**
     * Returns a list of supported languages.
     * 
     * @return list of languages
     */
    @Override
    public List<Locale> getLanguages()
    {
        return getSystem().getSupportedLanguages();
    }
    
    /**
     * Returns the current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }
    
    /**
     * Returns the SPARQL service of the current application.
     * 
     * @return service resource
     */
    public Service getService()
    {
        return service;
    }
    
    /**
     * Returns request context.
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return crc;
    }
    
    /**
     * Returns request URI information.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    /**
     * Returns RDF data manager.
     * 
     * @return RDF data manager
     */
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
    /**
     * Returns the context of authenticated agent.
     * 
     * @return agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }
    
    /**
     * Returns readable media types.
     * 
     * @return media types
     */
    @Override
    public MediaType[] getReadableMediaTypes()
    {
        return readableMediaTypes;
    }
    
    /**
     * Returns a registry of JAX-RS providers.
     * 
     * @return provider registry
     */
    public Providers getProviders()
    {
        return providers;
    }
    
    /**
     * Returns the system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    /**
     * Returns the value of the <code>User-Agent</code> request header.
     * 
     * @return header value
     */
    public String getUserAgentHeaderValue()
    {
        return LinkedDataClient.USER_AGENT;
    }
    
}
