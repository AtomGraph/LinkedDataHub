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
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.processor.vocabulary.SIOC;
import java.net.URI;
import java.util.Collections;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
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
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.RDF;
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
    @Inject Optional<Ontology> ontology;

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
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());
        
        // neither default graph nor named graph specified -- obtain named graph URI from the forClass-typed resource
        if (!defaultGraph && graphUri == null)
        {
            Resource forClass = getForClass(getUriInfo());
            Resource doc = getCreatedDocument(model, forClass);
            if (doc == null) throw new BadRequestException("aplt:ForClass typed resource not found in model");

            Resource parent = getParent(doc);
            // bnodes skolemized into URIs based on ldt:path annotations on ontology classes
            getSkolemizer(getUriInfo().getBaseUriBuilder(), UriBuilder.fromUri(parent.getURI())).build(model);
            
            graphUri = URI.create(getCreatedDocument(model, forClass).getURI());
        }
        else
            getSkolemizer(getUriInfo().getBaseUriBuilder(), UriBuilder.fromUri(graphUri)).build(model);
        
        return super.post(model, false, graphUri);
    }

    public Resource getForClass(UriInfo uriInfo)
    {
        if (!getUriInfo().getQueryParameters().containsKey(APLT.forClass.getLocalName()))
            throw new BadRequestException("aplt:ForClass parameter not provided");

        return ResourceFactory.createResource(uriInfo.getQueryParameters().getFirst(APLT.forClass.getLocalName()));
    }
    
//    public URI getGraphURI(Model model)
//    {
//        try
//        {
//            if (!getUriInfo().getQueryParameters().containsKey(APLT.forClass.getLocalName()))
//                throw new BadRequestException("aplt:ForClass parameter not provided");
//
//            URI forClass = new URI(getUriInfo().getQueryParameters().getFirst(APLT.forClass.getLocalName()));
//            Resource instance = getCreatedDocument(model, ResourceFactory.createResource(forClass.toString()));
//            if (instance == null || !instance.isURIResource()) throw new BadRequestException("aplt:ForClass typed resource not found in model");
//            URI graphUri = URI.create(instance.getURI());
//            graphUri = new URI(graphUri.getScheme(), graphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier
//            
//            return graphUri;
//        }
//        catch (URISyntaxException ex)
//        {
//            throw new BadRequestException(ex);
//        }
//    }

    public Skolemizer getSkolemizer(UriBuilder baseUriBuilder, UriBuilder absolutePathBuilder)
    {
        return new Skolemizer(ontology.get(), baseUriBuilder, absolutePathBuilder);
    }
    
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
    
    /**
     * Extracts the individual that is being created from the input RDF graph.
     * 
     * @param model RDF input graph
     * @param forClass RDF class
     * @return RDF resource
     */
    public Resource getCreatedDocument(Model model, Resource forClass)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        
        ResIterator it = model.listSubjectsWithProperty(RDF.type, forClass);
        try
        {
            if (it.hasNext())
            {
                Resource created = it.next();
                
                // handle creation of "things" - they are not documents themselves, so we return the attached document instead
//                if (created.hasProperty(FOAF.isPrimaryTopicOf))
//                    return created.getPropertyResourceValue(FOAF.isPrimaryTopicOf);
//                else
//                    return created;

                return created;
            }
        }
        finally
        {
            it.close();
        }
        
        return null;
    }
    
    public Resource getParent(Resource doc)
    {
        Resource parent = doc.getPropertyResourceValue(SIOC.HAS_PARENT);
        if (parent != null) return parent;
        parent = doc.getPropertyResourceValue(SIOC.HAS_CONTAINER);
        return parent;
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