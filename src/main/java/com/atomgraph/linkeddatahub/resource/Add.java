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
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Map;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.Consumes;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.StreamingOutput;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.MessageBodyReader;
import javax.ws.rs.ext.Providers;
import org.apache.jena.atlas.RuntimeIOException;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS endpoint for adding RDF data.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Add extends GraphStoreImpl // TO-DO: does not need to extend GraphStore is the multipart/form-data is not RDF/POST. Replace with ProxyResourceBase?
{

    private static final Logger log = LoggerFactory.getLogger(Add.class);
    
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
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
    }
    

    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        return super.get(false, getURI());
    }
    
    @POST
    @Override
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

            LinkedDataClient ldc = getSystem().getLinkedDataClient();
            Model importModel = ldc.getModel(source.getURI());
            // forward the stream to the named graph document -- do not directly append triples to graph because the agent might not have access to it
            return forwardPost(Entity.entity(importModel, com.atomgraph.client.MediaType.APPLICATION_NTRIPLES_TYPE), graph.getURI());
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
     * @param defaultGraph true if default graph was specified
     * @param graphUri graph name
     * @return response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Override
    public Response postMultipart(FormDataMultiPart multiPart, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart); // do not skolemize because we don't know the graphUri yet
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            return postFileBodyPart(model, getFileNameBodyPartMap(multiPart)); // do not write the uploaded file -- instead append its triples/quads
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

            try (InputStream is = bodyPart.getValueAs(InputStream.class))
            {
                // forward the stream to the named graph document -- do not directly append triples to graph because the agent might not have access to it
                return forwardPost(Entity.entity(getStreamingOutput(is), mediaType), graph.getURI());
            
            }
            catch (IOException ex)
            {
                throw new BadRequestException(ex);
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
        LinkedDataClient ldc = getSystem().getLinkedDataClient().
            delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
        // forward the stream to the named graph document. Buffer the entity first so that the server response is not returned before the client response completes
        try (Response response = ldc.post(URI.create(graphURI), ldc.getReadableMediaTypes(Model.class), entity))
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
     * Returns URI of this resource.
     * 
     * @return URI
     */
    public URI getURI()
    {
        return getUriInfo().getAbsolutePath();
    }
    
}
