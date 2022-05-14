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
package com.atomgraph.linkeddatahub.resource.upload;

import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import java.util.List;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import javax.ws.rs.core.Variant;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import java.util.ArrayList;
import java.util.Optional;
import javax.annotation.PostConstruct;
import javax.inject.Inject;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.NotAcceptableException;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves uploaded file data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends GraphStoreImpl
{
    private static final Logger log = LoggerFactory.getLogger(Item.class);
    
    private final Resource resource;
    
    /**
     * Constructs resource.
     * 
     * @param request current request
     * @param uriInfo URI information of the current request
     * @param mediaTypes a registry of readable/writable media types
     * @param application current application
     * @param ontology ontology of the current application
     * @param service SPARQL service of the current application
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     * @param providers JAX-RS provider registry
     * @param system system application
     */
    @Inject
    public Item(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
        this.resource = ModelFactory.createDefaultModel().createResource(uriInfo.getAbsolutePath().toString());
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }

    /**
     * Post-construct resource initialization.
     */
    @PostConstruct
    public void init()
    {
        getResource().getModel().add(describe());
    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        return getResponseBuilder(getResource().getModel(), graphUri).build();
    }
    
    @Override
    public ResponseBuilder getResponseBuilder(Model model, URI graphUri)
    {
        List<Variant> variants = com.atomgraph.core.model.impl.Response.getVariantListBuilder(getWritableMediaTypes(Model.class), getLanguages(), getEncodings()).
            add().build();
        Variant variant = getRequest().selectVariant(variants);
        if (variant == null)
        {
            if (log.isTraceEnabled()) log.trace("Requested Variant {} is not on the list of acceptable Response Variants: {}", variant, variants);
            throw new NotAcceptableException();
        }
        
        // respond with file content if Variant is compatible with the File's MediaType. otherwise, send RDF
        if (getMediaType().isCompatible(variant.getMediaType()))
        {
            URI fileURI = getSystem().getUploadRoot().resolve(getUriInfo().getPath());
            File file = new File(fileURI);

            if (!file.exists()) throw new NotFoundException(new FileNotFoundException("File '" + getUriInfo().getPath() + "' not found"));

            return super.getResponseBuilder(model, graphUri).entity(file).
                    type(variant.getMediaType());
            //header("Content-Disposition", "attachment; filename=\"" + getRequiredProperty(NFO.fileName).getString() + "\"").
        }
        
        return super.getResponseBuilder(model, graphUri);
    }
    
    /**
     * Returns the media type of this file.
     * 
     * @return media type
     */
    public javax.ws.rs.core.MediaType getMediaType()
    {
        Resource format = getResource().getPropertyResourceValue(DCTerms.format);
        if (format == null)
        {
            if (log.isErrorEnabled()) log.error("File '{}' does not have a media type", getResource());
            throw new IllegalStateException("File does not have a media type (dct:format)");
        }
        
        return com.atomgraph.linkeddatahub.MediaType.valueOf(format);
    }
    
    @Override
    public List<javax.ws.rs.core.MediaType> getWritableMediaTypes(Class clazz)
    {
        List<javax.ws.rs.core.MediaType> list = new ArrayList<>();
        list.add(getMediaType());

        return list;
    }
    
    /**
     * Returns file's RDF description using SPARQL query.
     * 
     * @return file's RDF model
     */
    public Model describe()
    {
        // TO-DO: can we avoid hardcoding the query string here?
        return getService().getSPARQLClient().loadModel(QueryFactory.create("DESCRIBE <" + getURI() + ">"));
    }
    
    /**
     * Returns URI of this file.
     * 
     * @return file URI
     */
    public URI getURI()
    {
        return getUriInfo().getAbsolutePath();
    }
    
    /**
     * Returns RDF resource of this file.
     * 
     * @return RDF resource
     */
    public Resource getResource()
    {
        return resource;
    }
    
}