/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
import com.atomgraph.linkeddatahub.imports.QueryLoader;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.model.impl.DirectGraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.URLValidator;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Map;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.container.ResourceContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.Providers;
import org.apache.jena.atlas.RuntimeIOException;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.Syntax;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that transforms uploaded RDF and then adds it.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Transform
{

    private static final Logger log = LoggerFactory.getLogger(Transform.class);

    private final UriInfo uriInfo;
    private final MediaTypes mediaTypes;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final Optional<AgentContext> agentContext;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;
    private final ResourceContext resourceContext;
    
    /**
     * Constructs endpoint for synchronous RDF data imports.
     * 
     * @param request current request
     * @param uriInfo current URI info
     * @param mediaTypes supported media types
     * @param application current application
     * @param providers JAX-RS providers
     * @param system system application
     * @param agentContext authenticated agent's context
     * @param resourceContext resource context
     */
    @Inject
    public Transform(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, 
            Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system,
            @Context ResourceContext resourceContext)
    {
        this.uriInfo = uriInfo;
        this.mediaTypes = mediaTypes;
        this.application = application;
        this.agentContext = agentContext;
        this.providers = providers;
        this.system = system;
        this.resourceContext = resourceContext;
    }
    
    /**
     * Rejects GET requests on this endpoint.
     *
     * @return never returns normally
     * @throws NotAllowedException always thrown to indicate GET is not supported
     */
    @GET
    public Response get()
    {
        throw new NotAllowedException("GET is not allowed on this endpoint");
    }
    
    /**
     * Transforms RDF data from a remote source using a SPARQL CONSTRUCT query and adds it to a target graph.
     * Validates URIs to prevent SSRF attacks before processing.
     *
     * @param model RDF model containing transformation parameters (dct:source, sd:name, spin:query)
     * @return HTTP response from forwarding the transformed data to the target graph
     * @throws BadRequestException if required parameters are missing or invalid
     */
    @POST
    public Response post(Model model)
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

            Resource queryRes = arg.getPropertyResourceValue(SPIN.query);
            if (queryRes == null) throw new BadRequestException("Transformation query string (spin:query) not provided");

            // LNK-002: Validate URIs to prevent SSRF attacks
            new URLValidator(URI.create(queryRes.getURI())).validate();
            new URLValidator(URI.create(source.getURI())).validate();

            GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
            QueryLoader queryLoader = new QueryLoader(URI.create(queryRes.getURI()), getApplication().getBase().getURI(), Syntax.syntaxARQ, gsc);
            Query query = queryLoader.get();
            if (!query.isConstructType()) throw new BadRequestException("Transformation query is not of CONSTRUCT type");

            Model importModel = gsc.getModel(source.getURI());
            try (QueryExecution qex = QueryExecution.create(query, importModel))
            {
                Model transformModel = qex.execConstruct();
                importModel.add(transformModel); // append transform results
                // forward the stream to the named graph document -- do not directly append triples to graph because the agent might not have access to it
                return forwardPost(Entity.entity(importModel, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE), graph.getURI());
            }
        }
        finally
        {
            it.close();
        }
    }
    
    /**
     * Handles multipart requests with RDF files.
     * 
     * @param multiPart multipart request object
     * @return response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response postMultipart(FormDataMultiPart multiPart)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            DirectGraphStoreImpl graphStore = getResourceContext().getResource(DirectGraphStoreImpl.class);
            
            Model model = graphStore.parseModel(multiPart); // do not skolemize because we don't know the graphUri yet
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            return postFileBodyPart(model, graphStore.getFileNameBodyPartMap(multiPart)); // do not write the uploaded file -- instead append its triples/quads
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
            throw new BadRequestException(ex);
        }
        catch (RuntimeIOException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not read uploaded file as media type: {}", multiPart.getMediaType());
            throw new BadRequestException(ex);
        }
    }
    
    /**
     * Handles uploaded RDF file.
     * 
     * @param model RDF graph
     * @param fileNameBodyPartMap parts of the multipart request
     * @return response response
     */
    public Response postFileBodyPart(Model model, Map<String, FormDataBodyPart> fileNameBodyPartMap)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (fileNameBodyPartMap == null) throw new IllegalArgumentException("Map<String, FormDataBodyPart> cannot be null");
        
        ResIterator resIt = model.listResourcesWithProperty(NFO.fileName);
        try
        {
            if (!resIt.hasNext()) throw new BadRequestException("File body part not found in the multipart request");

            Resource file = resIt.next();
            String fileName = file.getProperty(NFO.fileName).getString();
            FormDataBodyPart bodyPart = fileNameBodyPartMap.get(fileName);

            Resource graph = file.getPropertyResourceValue(SD.name);
            if (graph == null || !graph.isURIResource()) throw new BadRequestException("Graph URI (sd:name) not provided");
            if (!file.hasProperty(DCTerms.format)) throw new BadRequestException("RDF format (dct:format) not provided");
            
            MediaType mediaType = com.atomgraph.linkeddatahub.MediaType.valueOf(file.getPropertyResourceValue(DCTerms.format));
            bodyPart.setMediaType(mediaType);
            Model bodyPartModel =  bodyPart.getValueAs(Model.class);

            Resource queryRes = file.getPropertyResourceValue(SPIN.query);
            if (queryRes == null) throw new BadRequestException("Transformation query string (spin:query) not provided");

            // LNK-002: Validate query URI to prevent SSRF attacks
            new URLValidator(URI.create(queryRes.getURI())).validate();

            GraphStoreClient gsc = GraphStoreClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
            QueryLoader queryLoader = new QueryLoader(URI.create(queryRes.getURI()), getApplication().getBase().getURI(), Syntax.syntaxARQ, gsc);
            Query query = queryLoader.get();
            if (!query.isConstructType()) throw new BadRequestException("Transformation query is not of CONSTRUCT type");

            try (QueryExecution qex = QueryExecution.create(query, bodyPartModel))
            {
                Model transformModel = qex.execConstruct();
                bodyPartModel.add(transformModel); // append transform results
                // forward the model to the named graph document
                return forwardPost(Entity.entity(bodyPartModel, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE), graph.getURI());
            }
        }
        finally
        {
            resIt.close();
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
     * Returns the supported media types.
     *
     * @return media types
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
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
     * Returns the registry of JAX-RS providers.
     *
     * @return JAX-RS providers registry
     */
    public Providers getProviders()
    {
        return providers;
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
    
    /**
     * Returns the JAX-RS resource context.
     *
     * @return resource context
     */
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }

}
