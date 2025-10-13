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
import com.atomgraph.core.exception.BadGatewayException;
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
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.client.Entity;
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
import org.glassfish.jersey.message.internal.MessageBodyProviderNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Generic HTTP proxy.
 * It uses an HTTP client to dereference URIs and sends back the client response.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ProxyResourceBase
{

    private static final Logger log = LoggerFactory.getLogger(ProxyResourceBase.class);

    private final UriInfo uriInfo;
    private final Request request;
    private final HttpHeaders httpHeaders;
    private final MediaTypes mediaTypes;
    private final ContainerRequestContext crc;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final Service service;
    private final DataManager dataManager;
    private final Optional<AgentContext> agentContext;
    private final MediaType[] readableMediaTypes;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;
    private final WebTarget webTarget;

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
                uriInfo.getQueryParameters().getFirst(AC.query.getLocalName()) == null ? null : uriInfo.getQueryParameters().getFirst(AC.query.getLocalName()),
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
     * @param uri Linked Data URI
     * @param endpoint SPARQL endpoint URI
     * @param query SPARQL query
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
            @QueryParam("uri") URI uri, @QueryParam("endpoint") URI endpoint, @QueryParam("query") String query, @QueryParam("accept") MediaType accept, @QueryParam("mode") URI mode,
            com.atomgraph.linkeddatahub.Application system, @Context HttpServletRequest httpServletRequest, DataManager dataManager, Optional<AgentContext> agentContext,
            @Context Providers providers)
    {
        this.uriInfo = uriInfo;
        this.request = request;
        this.httpHeaders = httpHeaders;
        this.mediaTypes = mediaTypes;
        this.application = application;
        this.service = service.get();
        this.crc = crc;
        this.dataManager = dataManager;
        this.agentContext = agentContext;
        this.providers = providers;
        this.system = system;

        List<jakarta.ws.rs.core.MediaType> readableMediaTypesList = new ArrayList<>();
        readableMediaTypesList.addAll(mediaTypes.getReadable(Model.class));
        readableMediaTypesList.addAll(mediaTypes.getReadable(ResultSet.class));
        this.readableMediaTypes = readableMediaTypesList.toArray(MediaType[]::new);

        // Create WebTarget - uri is guaranteed to be non-null by Dispatcher
        WebTarget target = system.getExternalClient().target(uri);

        if (agentContext.isPresent())
        {
            if (agentContext.get() instanceof WebIDSecurityContext)
                target.register(new WebIDDelegationFilter(agentContext.get().getAgent()));

            if (agentContext.get() instanceof IDTokenSecurityContext iDTokenSecurityContext)
                target.register(new IDTokenDelegationFilter(agentContext.get().getAgent(),
                    iDTokenSecurityContext.getJWTToken(), uriInfo.getBaseUri().getPath(), null));
        }

        this.webTarget = target;
    }
    
    /**
     * Forwards <code>GET</code> request and returns response from remote resource.
     *
     * @return response
     */
    @GET
    public Response get()
    {
        WebTarget target = getWebTarget();

        // check if we have the model in the cache first and if yes, return it from there instead making an HTTP request
        if (((FileManager)getDataManager()).hasCachedModel(target.getUri().toString()) ||
                (getDataManager().isResolvingMapped() && getDataManager().isMapped(target.getUri().toString()))) // read mapped URIs (such as system ontologies) from a file
        {
            if (log.isDebugEnabled()) log.debug("hasCachedModel({}): {}", target.getUri(), ((FileManager)getDataManager()).hasCachedModel(target.getUri().toString()));
            if (log.isDebugEnabled()) log.debug("isMapped({}): {}", target.getUri(), getDataManager().isMapped(target.getUri().toString()));
            return Response.ok(getDataManager().loadModel(target.getUri().toString())).build();
        }

        if (!getSystem().isEnableLinkedDataProxy()) throw new NotAllowedException("Linked Data proxy not enabled");

        if (log.isDebugEnabled()) log.debug("GETing URI: {}", target.getUri());

        try (Response cr = target.request(getReadableMediaTypes())
                .header(HttpHeaders.USER_AGENT, getUserAgentHeaderValue())
                .get())
        {
            return getResponse(cr);
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.debug("Dereferenced URI {} returned non-RDF media type", target.getUri());
            throw new NotAcceptableException(ex);
        }
        catch (ProcessingException ex)
        {
            if (log.isWarnEnabled()) log.debug("Could not dereference URI: {}", target.getUri());
            throw new BadGatewayException(ex);
        }
    }
    
    /**
     * Forwards POST request and returns response from remote resource.
     *
     * @param entity request entity
     * @return response
     */
    @POST
    public Response post(Object entity)
    {
        if (getWebTarget() == null) throw new NotFoundException("Resource URI not supplied");

        MediaType contentType = getHttpHeaders().getMediaType();
        if (log.isDebugEnabled()) log.debug("POSTing entity with Content-Type {} to URI: {}", contentType, getWebTarget().getUri());

        try (Response cr = getWebTarget().request()
                .accept(getReadableMediaTypes())
                .post(Entity.entity(entity, contentType)))
        {
            return getResponse(cr);
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.debug("Dereferenced URI {} returned non-RDF media type", getWebTarget().getUri());
            throw new NotAcceptableException(ex);
        }
        catch (ProcessingException ex)
        {
            if (log.isWarnEnabled()) log.debug("Could not dereference URI: {}", getWebTarget().getUri());
            throw new BadGatewayException(ex);
        }
    }
    
    /**
     * Forwards PUT request and returns response from remote resource.
     *
     * @param entity request entity
     * @return response
     */
    @PUT
    public Response put(Object entity)
    {
        if (!getSystem().isEnableLinkedDataProxy()) throw new NotAllowedException("Linked Data proxy not enabled");
        if (getWebTarget() == null) throw new NotFoundException("Resource URI not supplied");

        MediaType contentType = getHttpHeaders().getMediaType();
        if (log.isDebugEnabled()) log.debug("PUTing entity with Content-Type {} to URI: {}", contentType, getWebTarget().getUri());

        try (Response cr = getWebTarget().request()
                .accept(getReadableMediaTypes())
                .put(Entity.entity(entity, contentType)))
        {
            return getResponse(cr);
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.debug("Dereferenced URI {} returned non-RDF media type", getWebTarget().getUri());
            throw new NotAcceptableException(ex);
        }
        catch (ProcessingException ex)
        {
            if (log.isWarnEnabled()) log.debug("Could not dereference URI: {}", getWebTarget().getUri());
            throw new BadGatewayException(ex);
        }
    }

    /**
     * Forwards PATCH request and returns response from remote resource.
     *
     * @param entity request entity
     * @return response
     */
    @PATCH
    public Response patch(Object entity)
    {
        if (!getSystem().isEnableLinkedDataProxy()) throw new NotAllowedException("Linked Data proxy not enabled");
        if (getWebTarget() == null) throw new NotFoundException("Resource URI not supplied");

        MediaType contentType = getHttpHeaders().getMediaType();
        if (log.isDebugEnabled()) log.debug("PATCHing entity with Content-Type {} to URI: {}", contentType, getWebTarget().getUri());

        try (Response cr = getWebTarget().request()
                .accept(getReadableMediaTypes())
                .method("PATCH", Entity.entity(entity, contentType)))
        {
            return getResponse(cr);
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.debug("Dereferenced URI {} returned non-RDF media type", getWebTarget().getUri());
            throw new NotAcceptableException(ex);
        }
        catch (ProcessingException ex)
        {
            if (log.isWarnEnabled()) log.debug("Could not dereference URI: {}", getWebTarget().getUri());
            throw new BadGatewayException(ex);
        }
    }

    /**
     * Forwards DELETE request and returns response from remote resource.
     *
     * @return response
     */
    @DELETE
    public Response delete()
    {
        if (!getSystem().isEnableLinkedDataProxy()) throw new NotAllowedException("Linked Data proxy not enabled");
        if (getWebTarget() == null) throw new NotFoundException("Resource URI not supplied");

        if (log.isDebugEnabled()) log.debug("DELETEing URI: {}", getWebTarget().getUri());

        try (Response cr = getWebTarget().request()
                .accept(getReadableMediaTypes())
                .delete())
        {
            return getResponse(cr);
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.debug("Dereferenced URI {} returned non-RDF media type", getWebTarget().getUri());
            throw new NotAcceptableException(ex);
        }
        catch (ProcessingException ex)
        {
            if (log.isWarnEnabled()) log.debug("Could not dereference URI: {}", getWebTarget().getUri());
            throw new BadGatewayException(ex);
        }
    }

    /**
     * Returns response for the given client response.
     * Copies status, entity, and headers from the client response.
     *
     * @param clientResponse JAX-RS client response
     * @return response
     */
    public Response getResponse(Response clientResponse)
    {
        return Response.status(clientResponse.getStatus())
                .entity(clientResponse.getEntity())
                .replaceAll(clientResponse.getHeaders())
                .build();
    }

    /**
     * Returns HTTP headers.
     *
     * @return HTTP headers
     */
    protected HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }

    /**
     * Returns web target.
     *
     * @return web target
     */
    protected WebTarget getWebTarget()
    {
        return webTarget;
    }

    /**
     * Returns media types registry.
     *
     * @return media types
     */
    protected MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }

    /**
     * Returns RDF data manager.
     *
     * @return RDF data manager
     */
    protected DataManager getDataManager()
    {
        return dataManager;
    }

    /**
     * Returns readable media types.
     *
     * @return media types
     */
    protected MediaType[] getReadableMediaTypes()
    {
        return readableMediaTypes;
    }

    /**
     * Returns the system application.
     *
     * @return JAX-RS application
     */
    protected com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns the value of the <code>User-Agent</code> request header.
     *
     * @return header value
     */
    protected String getUserAgentHeaderValue()
    {
        return LinkedDataClient.USER_AGENT;
    }
    
}
