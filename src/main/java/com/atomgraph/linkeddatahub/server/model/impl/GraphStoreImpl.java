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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import java.net.URI;
import java.util.Collections;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.PATCH;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * LinkedDataHub Graph Store implementation.
 * We need to subclass the Core class because we're injecting a subclass of Service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphStoreImpl extends com.atomgraph.core.model.impl.GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(GraphStoreImpl.class);

    private final UriInfo uriInfo;
    private final Service service;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;

    @Inject
    public GraphStoreImpl(@Context Request request, Optional<Service> service, MediaTypes mediaTypes,
        @Context UriInfo uriInfo, @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, service.get(), mediaTypes);
        this.uriInfo = uriInfo;
        this.service = service.get();
        this.providers = providers;
        this.system = system;
    }
    
//    @POST
//    @Override
//    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
//    {
//        if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());
//        
//        if (model.isEmpty()) return Response.noContent().build();
//        
//        if (defaultGraph)
//        {
//            if (log.isDebugEnabled()) log.debug("POST Model to default graph");
//            getDatasetAccessor().add(model);
//            return Response.ok().build();
//        }
//        else
//        {
//            // TO-DO: push this logic (which supports graphUri == null) down to the superclass
//            final boolean existingGraph;
//            if (graphUri != null) existingGraph = getDatasetAccessor().containsModel(graphUri.toString());
//            else existingGraph = false;
//
//            if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {} Did it already exist? {}", graphUri, existingGraph);
//            getDatasetAccessor().add(graphUri.toString(), model);
//
//            if (existingGraph) return Response.ok().build();
//            else return Response.created(graphUri).build();
//        }
//    }
 
    @PATCH
    public Response patch(UpdateRequest updateRequest)
    {
        // TO-DO: do a check that the update only uses this named graph
        getService().getEndpointAccessor().update(updateRequest, Collections.<URI>emptyList(), Collections.<URI>emptyList());
        
        return Response.ok().build();
    }
    
    /**
     * Overrides <code>OPTIONS</code> HTTP header values.
     * Specifies allowed methods.
     * 
     * @return HTTP response
     */
    @OPTIONS
    public Response options()
    {
        Response.ResponseBuilder rb = Response.ok().
            header(HttpHeaders.ALLOW, HttpMethod.GET).
            header(HttpHeaders.ALLOW, HttpMethod.POST).
            header(HttpHeaders.ALLOW, HttpMethod.PUT).
            header(HttpHeaders.ALLOW, HttpMethod.DELETE);
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Model.class), ",");
        rb.header("Accept-Post", acceptWritable);
        
        return rb.build();
        
    }

    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public Service getService()
    {
        return service;
    }
    
    public Providers getProviders()
    {
        return providers;
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}