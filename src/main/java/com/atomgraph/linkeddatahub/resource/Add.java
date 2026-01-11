/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.StreamingOutput;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS endpoint for adding RDF data.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Add
{

    private static final Logger log = LoggerFactory.getLogger(Add.class);
    
    private final UriInfo uriInfo;
    private final MediaTypes mediaTypes;
    private final Optional<AgentContext> agentContext;
    private final com.atomgraph.linkeddatahub.Application system;
    
    /**
     * Constructs endpoint for synchronous RDF data imports.
     * 
     * @param request current request
     * @param uriInfo current URI info
     * @param mediaTypes supported media types
     * @param application matched application
     * @param ontology matched application's ontology
     * @param service matched application's service
     * @param providers JAX-RS providers
     * @param system system application
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     */
    @Inject
    public Add(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        this.uriInfo = uriInfo;
        this.mediaTypes = mediaTypes;
        this.agentContext = agentContext;
        this.system = system;
    }

    /**
     * Adds RDF data from a remote source to a named graph.
     * Expects a model containing a resource with dct:source (source URI) and sd:name (target graph URI) properties.
     *
     * @param model the RDF model containing the import parameters
     * @param defaultGraph whether to import into the default graph
     * @param graphUri the target graph URI
     * @return JAX-RS response with the imported data
     */
    @POST
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        ResIterator it = model.listSubjectsWithProperty(DCTerms.source);
        try
        {
            if (!it.hasNext()) throw new BadRequestException("Argument resource not provided");
            
            Resource arg = it.next();
            Resource source = arg.getPropertyResourceValue(DCTerms.source);
            if (source == null) throw new BadRequestException("RDF source URI (dct:source) not provided");
            
            Resource graph = arg.getPropertyResourceValue(SD.name);
            if (graph == null || !graph.isURIResource()) throw new BadRequestException("Graph URI (sd:name) not provided");

            GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getMediaTypes()); // TO-DO: inject
            Model importModel = gsc.getModel(source.getURI());
            // forward the stream to the named graph document -- do not directly append triples to graph because the agent might not have access to it
            return forwardPost(Entity.entity(importModel, com.atomgraph.client.MediaType.APPLICATION_NTRIPLES_TYPE), graph.getURI());
        }
        finally
        {
            it.close();
        }
    }
    
    /**
     * Forwards <code>POST</code> request to a graph.
     * 
     * @param entity request entity
     * @param graphURI the graph URI
     * @return JAX-RS response
     */
    protected Response forwardPost(Entity entity, String graphURI)
    {
        GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
            delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
        // forward the stream to the named graph document. Buffer the entity first so that the server response is not returned before the client response completes
        try (Response response = gsc.post(URI.create(graphURI), entity, gsc.getReadableMediaTypes(Model.class)))
        {
            return Response.status(response.getStatus()).
                entity(response.readEntity(Model.class)).
                build();
        }
    }
    
    /**
     * Converts input stream to streaming output.
     * @param is input stream
     * @return streaming output
     */
    public StreamingOutput getStreamingOutput(InputStream is)
    {
        return (OutputStream os) -> {
            is.transferTo(os);
        };
    }

    /**
     * Returns the supported media types.
     *
     * @return media types
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }

    /**
     * Returns the current URI info.
     *
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns the authenticated agent's context.
     *
     * @return optional agent context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }

    /**
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
