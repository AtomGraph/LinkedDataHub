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
package com.atomgraph.linkeddatahub.resource.graph;

import org.apache.jena.rdf.model.Model;
import java.net.URI;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.EntityTag;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.Patchable;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.DELETE;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.PATCH;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.UriInfo;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Directly identified named graph resource, based on Graph Store.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends GraphStoreImpl implements Patchable
{

    private static final Logger log = LoggerFactory.getLogger(Item.class);
    
    private final UriInfo uriInfo;
    private final URI uri;
    private final Service service;
    
    @Inject
    public Item(@Context UriInfo uriInfo, @Context Request request, Optional<Service> service, MediaTypes mediaTypes)
    {
        super(request, service, mediaTypes);
        this.uriInfo = uriInfo;
        this.uri = uriInfo.getAbsolutePath();
        this.service = service.get();
    }
    
    @OPTIONS
    public Response options()
    {
        ResponseBuilder rb = Response.ok().
            header(HttpHeaders.ALLOW, HttpMethod.GET).
            header(HttpHeaders.ALLOW, HttpMethod.POST).
            header(HttpHeaders.ALLOW, HttpMethod.PUT).
            header(HttpHeaders.ALLOW, HttpMethod.DELETE);
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Model.class), ",");
        rb.header("Accept-Post", acceptWritable);
        rb.header("Accept-Put", acceptWritable);
        
        return rb.build();
    }
  
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (!getDatasetAccessor().containsModel(getURI().toString()))
        {
            if (log.isDebugEnabled()) log.debug("GET Graph Store named graph with URI: {} not found", getURI());
            throw new NotFoundException("Named graph not found");
        }

        Model model = getDatasetAccessor().getModel(getURI().toString());
        if (log.isDebugEnabled()) log.debug("GET Graph Store named graph with URI: {} found, returning Model of size(): {}", getURI(), model.size());
        return getResponse(model);
    }

    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        boolean existingGraph = getDatasetAccessor().containsModel(getURI().toString());

        // is this implemented correctly? The specification is not very clear.
        if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {} Did it already exist? {}", getURI(), existingGraph);
        getDatasetAccessor().add(getURI().toString(), model);

        if (existingGraph) return Response.ok().build();
        else return Response.created(getURI()).build();
    }

    @PUT
    @Override
    public Response put(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        boolean existingGraph = getDatasetAccessor().containsModel(getURI().toString());
        if (!existingGraph)
        {
            Model existingModel = getDatasetAccessor().getModel(getURI().toString());
            EntityTag entityTag = new EntityTag(Long.toHexString(ModelUtils.hashModel(existingModel)));
            ResponseBuilder rb = getRequest().evaluatePreconditions(entityTag);
            if (rb != null)
            {
                if (log.isDebugEnabled()) log.debug("PUT preconditions were not met for resource: {} with entity tag: {}", this, entityTag);
                return rb.build();
            }
        }
        
        if (log.isDebugEnabled()) log.debug("PUT Model to named graph with URI: {} Did it already exist? {}", getURI(), existingGraph);
        getDatasetAccessor().putModel(getURI().toString(), model);

//        try (Response cr = getService().getSPARQLClient().query(new ParameterizedSparqlString(getSystem().getGraphDocumentQuery().toString(),
//                getQuerySolutionMap(), getUriInfo().getBaseUri().toString()).asQuery(), ResultSet.class,
//                new MultivaluedHashMap()))
//        {
//            ResultSet resultSet = cr.readEntity(ResultSetRewindable.class);
//            if (resultSet.hasNext())
//            {
//                QuerySolution qs = resultSet.next();
//                Resource document = qs.getResource(FOAF.Document.getLocalName());
//                Resource provGraph = qs.getResource("provGraph"); // TO-DO: use some constant instead of a hardcoded string
//                Resource container = qs.getResource(DH.Container.getLocalName());
//
//                if (provGraph != null)
//                {
//                    // add dct:modified on ?doc where { ?doc void:inDataset ?this }
//                    Model provModel = ModelFactory.createDefaultModel();
//                    provModel.addLiteral(document, DCTerms.modified, provModel.createTypedLiteral(GregorianCalendar.getInstance()));
//                    Dataset provDataset = DatasetFactory.create();
//                    provDataset.addNamedModel(provGraph.getURI(), provModel);
//                    getService().getDatasetQuadAccessor().add(provDataset);
//                }
//
//                // attempt to purge ?doc where { ?doc void:inDataset ?this }
//                if (getSystem().isInvalidateCache() && document != null)
//                {
//                    try (Response banResponse = ban(document, container))
//                    {
//                        if (banResponse != null)
//                            if (log.isDebugEnabled()) log.debug("Sent BAN {} request SPARQL service proxy; received status code: {}", document.getURI(), banResponse.getStatus());
//                    }
//                }
//            }
//        }
        
        if (existingGraph) return Response.ok().build();
        else return Response.created(getURI()).build();
    }
    
//    @PUT
//    @Consumes(MediaType.MULTIPART_FORM_DATA)
//    public Response putMultipart(FormDataMultiPart multiPart)
//    {
//        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());
//
//        try
//        {
//            Model model = ResourceBase.parseModel(multiPart);
//            if (log.isDebugEnabled()) log.debug("POSTed Model size: {} Model: {}", model.size(), model);
//
//            // writing files has to go before put() as it changes model (e.g. adds body part media type as dct:format)
//            int count = ResourceBase.processFormDataMultiPart(model, multiPart);
//            if (log.isDebugEnabled()) log.debug("{} Files uploaded from FormDataMultiPart: {} ", count, multiPart);
//
//            Response response = put(model);
//
//            return Response.seeOther(URI.create(getURI())).build();
//        }
//        catch (URISyntaxException ex)
//        {
//            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
//            throw new BadRequestException(ex);
//        }
//        catch (IOException ex)
//        {
//            if (log.isErrorEnabled()) log.error("Error reading multipart request");
//            throw new WebApplicationException(ex);
//        }
//    }
    
    @DELETE
    @Override
    public Response delete(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        // attempt to purge ?doc where { ?doc void:inDataset ?this }
//        if (getSystem().isInvalidateCache())
//        {
//            try (Response cr = getService().getSPARQLClient().
//                query(new ParameterizedSparqlString(getSystem().getGraphDocumentQuery().toString(),
//                    getQuerySolutionMap(), getUriInfo().getBaseUri().toString()).asQuery(), ResultSet.class,
//                    new MultivaluedHashMap()))
//                {
//                ResultSet resultSet = cr.readEntity(ResultSetRewindable.class);
//                if (resultSet.hasNext())
//                {
//                    QuerySolution qs = resultSet.next();
//                    Resource document = qs.getResource(FOAF.Document.getLocalName());
//                    Resource container = qs.getResource(DH.Container.getLocalName());
//
//                    if (document != null)
//                    {
//                        try (Response banResponse = ban(document, container))
//                        {
//                            if (banResponse != null)
//                                if (log.isDebugEnabled()) log.debug("Sent BAN {} request SPARQL service proxy; received status code: {}", document.getURI(), banResponse.getStatus());
//                        }
//                    }
//                }
//            }
//        }
        
        if (!getDatasetAccessor().containsModel(getURI().toString()))
        {
            if (log.isDebugEnabled()) log.debug("DELETE named graph with URI {}: not found", getURI());
            throw new NotFoundException("Named graph not found");
        }
        else
        {
            if (log.isDebugEnabled()) log.debug("DELETE named graph with URI: {}", getURI());
            getDatasetAccessor().deleteModel(getURI().toString());
            return Response.noContent().build(); // TO-DO: NoContentException?
        }
    }
    
    @PATCH
    @Override
    public Response patch(UpdateRequest updateRequest)
    {
        // TO-DO: do a check that the update only uses this named graph
        getService().getEndpointAccessor().update(updateRequest, Collections.<URI>emptyList(), Collections.<URI>emptyList());
        
        return Response.ok().build();
    }
    
    /**
     * Gets a list of media types that a writable for a message body class.
     * 
     * @param clazz message body class, normally <code>Dataset.class</code> or <code>Model.class</code>
     * @return list of media types
     */
    @Override
    public List<MediaType> getWritableMediaTypes(Class clazz)
    {
        // restrict writable MediaTypes to the requested one (usually by RDF export feature)
        if (getUriInfo().getQueryParameters().containsKey(AC.accept.getLocalName())) // TO-DO: move to ResourceFilter?
        {
            String accept = getUriInfo().getQueryParameters().getFirst(AC.accept.getLocalName());
            
            MediaType mediaType = MediaType.valueOf(accept); // parse value
            mediaType = new MediaType(mediaType.getType(), mediaType.getSubtype(), MediaTypes.UTF8_PARAM); // set charset=UTF-8
            return Arrays.asList(mediaType);
        }

        return super.getWritableMediaTypes(clazz);
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public URI getURI()
    {
        return uri;
    }

    public Service getService()
    {
        return service;
    }
    
}