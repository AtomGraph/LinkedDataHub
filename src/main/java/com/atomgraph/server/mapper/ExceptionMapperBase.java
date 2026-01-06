/*
 * Copyright 2014 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.server.mapper;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.core.Variant;
import jakarta.ws.rs.ext.Provider;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.util.Link;
import com.atomgraph.server.vocabulary.LDT;
import com.atomgraph.server.vocabulary.HTTP;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;

/**
 * Abstract base class for ExceptionMappers that build responses with exceptions as RDF resources.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
abstract public class ExceptionMapperBase
{

    @Context private Request request;
    @Context private UriInfo uriInfo;
    
    private final MediaTypes mediaTypes;
    
    @Inject
    public ExceptionMapperBase(MediaTypes mediaTypes)
    {
        this.mediaTypes = mediaTypes;
    }

    public Resource toResource(Exception ex, Response.StatusType status, Resource statusResource)
    {
        if (ex == null) throw new IllegalArgumentException("Exception cannot be null");
        if (status == null) throw new IllegalArgumentException("Response.Status cannot be null");

        Resource resource = ModelFactory.createDefaultModel().createResource().
                addProperty(RDF.type, HTTP.Response).
                addLiteral(HTTP.statusCodeValue, status.getStatusCode()).
                addLiteral(HTTP.reasonPhrase, status.getReasonPhrase());

        if (statusResource != null) resource.addProperty(HTTP.sc, statusResource);
        if (ex.getMessage() != null) resource.addLiteral(DCTerms.title, ex.getMessage());
        
        return resource;
    }
    
    // TO-DO: set Link headers in a ContainerResponseFilter instead
    public Response.ResponseBuilder getResponseBuilder(Model model)
    {
        List<Variant> variants = getVariants(Model.class);
        Variant variant = getRequest().selectVariant(variants);
        if (variant == null) variant = new Variant(com.atomgraph.core.MediaType.TEXT_TURTLE_TYPE, (Locale)null, null); // if still not acceptable, default to Turtle

//      // don't use Response class as it can strip the entity by returning 304 Not Modified
//        return new com.atomgraph.core.model.impl.Response(getRequest(),
//                model,
//                null,
//                new EntityTag(Long.toHexString(ModelUtils.hashModel(model))),
//                variant).
//                getResponseBuilder().
//            header(HttpHeaders.LINK, new Link(getUriInfo().getBaseUri(), LDT.base.getURI(), null));

        return Response.ok(). // status will be overriden in the subclasses
            entity(model).
            variant(variant).
            header(HttpHeaders.LINK, new Link(getUriInfo().getBaseUri(), LDT.base.getURI(), null));
    }

    /**
     * Builds a list of acceptable response variants for a certain class.
     * 
     * @param clazz class
     * @return list of variants
     */
    public List<Variant> getVariants(Class clazz)
    {
        return getVariants(getWritableMediaTypes(clazz));
    }
    
    /**
     * Builds a list of acceptable response variants.
     * 
     * @param mediaTypes
     * @return supported variants
     */
    public List<Variant> getVariants(List<MediaType> mediaTypes)
    {
        return com.atomgraph.core.model.impl.Response.getVariants(mediaTypes, getLanguages(), getEncodings());
    }
    
    /**
     * Get writable media types for a certain class.
     * 
     * @param clazz class
     * @return list of media types
     */
    public List<MediaType> getWritableMediaTypes(Class clazz)
    {
        return getMediaTypes().getWritable(clazz);
    }
    
    public List<Locale> getLanguages()
    {
        return new ArrayList<>();
    }

    public List<String> getEncodings()
    {
        return new ArrayList<>();
    }
        
    public Request getRequest()
    {
        return request;
    }
    
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }

    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
}